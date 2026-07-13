# L3c: CAD–JPY exchange rate (Bank of Canada Valet) + Canada CPI deflator (FRED)
#
# FX COVERAGE CAVEAT: Bank of Canada Valet `FXJPYCAD` only spans ~2017-present
# (BoC changed FX publication in 2017). This loader requests full history but
# BoC will return only what it has. CAD-JPY for the roe era (~1972-2006) requires
# an alternate pre-2017 source (e.g. FRED DEXJPUS x DEXCAUS derivation, or OECD)
# — a deferred upgrade-track acquisition task. Until then the FX series is
# short-coverage; Task 9/10 must NOT assume full-range FX. (Flag for Task 11 QA.)
#
# FX SERIES ORIENTATION NOTE:
#   Bank of Canada series FXJPYCAD is described as "daily value of the Japanese
#   yen expressed in Canadian dollars, for 1 unit of Japanese yen" — i.e., raw
#   values are CAD per 1 JPY (~0.0107–0.0130). The *label* "JPY/CAD" in the BoC
#   metadata is misleading.  We need fx_jpy_per_cad (JPY per 1 CAD, historically
#   ~80–130). We resolve this data-driven: compute the annual-mean series, and if
#   its median is < 1 (indicating CAD-per-JPY units), invert it.  This keeps the
#   code correct even if BoC ever publishes the inverted series directly.
#
# CACHE CONTRACT:
#   If data-raw/fx/boc_fxjpycad.csv or data-raw/fx/fred_cpi_ca.csv already
#   exist, they are read directly (no network call).  On a successful live fetch,
#   each CSV is written to that path and data-raw/fx/MANIFEST.sha256 is updated.
#
# INTEGRITY CONTRACT:
#   Failures raise a precise stop() distinguishing: no network egress, missing
#   FRED_API_KEY, missing package, or unexpected response structure.
#   No data is fabricated.  The test skips (not fails) when data are unavailable.

# ---------------------------------------------------------------------------
# build_fx() — Bank of Canada Valet, series FXJPYCAD
# Returns tibble: year (integer), fx_jpy_per_cad (double, JPY per CAD)
# ---------------------------------------------------------------------------

build_fx <- function(
    cache = here::here("data-raw", "fx", "boc_fxjpycad.csv")) {

  if (file.exists(cache)) {
    # Cache hit — read directly
    # Integrity: MANIFEST is write-once at fetch time; manually re-verify with .write_manifest() if provenance is in question.
    raw_tbl <- readr::read_csv(cache, show_col_types = FALSE)
    return(.summarise_fx(raw_tbl))
  }

  # -- Live fetch from BoC Valet API ----------------------------------------
  url <- "https://www.bankofcanada.ca/valet/observations/FXJPYCAD/csv?start_date=1970-01-01"

  raw_text <- tryCatch(
    readLines(url, warn = FALSE),
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("network|connect|resolve|timeout|internet|cannot open|could not",
                msg, ignore.case = TRUE)) {
        stop(
          "BoC FX live fetch failed: no network egress. ",
          "The environment cannot reach bankofcanada.ca. ",
          "Provide a pre-downloaded CSV at: ", cache,
          ". Original error: ", msg
        )
      }
      stop("BoC FX live fetch failed (other error). Original error: ", msg)
    }
  )

  # -- Locate the data section programmatically -----------------------------
  # Find the header row that starts "\"date\"" or contains the series id,
  # which always appears directly under the "OBSERVATIONS" sentinel line.
  obs_idx <- which(grepl('^"?OBSERVATIONS"?$', trimws(raw_text)))
  if (length(obs_idx) == 0) {
    stop(
      "BoC FX parse failed: could not find the OBSERVATIONS block in the ",
      "Valet CSV. The API response structure may have changed. ",
      "URL fetched: ", url, ". First 15 lines:\n",
      paste(raw_text[seq_len(min(15, length(raw_text)))], collapse = "\n")
    )
  }

  # Header row is immediately after OBSERVATIONS sentinel
  header_idx <- obs_idx[1] + 1
  if (header_idx > length(raw_text)) {
    stop(
      "BoC FX parse failed: OBSERVATIONS block found but no header row follows. ",
      "Response may be truncated."
    )
  }

  # Parse from header row onward using readr
  data_text <- paste(raw_text[header_idx:length(raw_text)], collapse = "\n")
  raw_tbl <- tryCatch(
    readr::read_csv(I(data_text), show_col_types = FALSE, name_repair = "minimal"),
    error = function(e) {
      stop(
        "BoC FX parse failed: could not parse the data section as CSV. ",
        "Original error: ", conditionMessage(e)
      )
    }
  )

  # Verify expected columns
  if (ncol(raw_tbl) < 2) {
    stop(
      "BoC FX parse failed: expected >= 2 columns after header, got ",
      ncol(raw_tbl), ". Columns found: ", paste(names(raw_tbl), collapse = ", ")
    )
  }

  # Rename: first col = date, second col = raw rate
  names(raw_tbl)[1:2] <- c("date", "raw_rate")

  # Remove any rows where raw_rate is non-numeric (e.g. bank holidays marked "Bank holiday")
  raw_tbl <- raw_tbl |>
    dplyr::mutate(raw_rate = suppressWarnings(as.double(raw_rate))) |>
    dplyr::filter(!is.na(raw_rate))

  if (nrow(raw_tbl) == 0) {
    stop(
      "BoC FX parse failed: no numeric rows remain after filtering. ",
      "Check that FXJPYCAD observations are present in the Valet response."
    )
  }

  # -- Write cache and update manifest --------------------------------------
  dir.create(dirname(cache), showWarnings = FALSE, recursive = TRUE)
  readr::write_csv(raw_tbl, cache)
  .write_manifest(cache)

  .summarise_fx(raw_tbl)
}

# Internal: summarise a raw (date, raw_rate) tibble → annual fx_jpy_per_cad
.summarise_fx <- function(raw_tbl) {
  # Ensure columns are named consistently after cache read
  if (!"raw_rate" %in% names(raw_tbl)) {
    # Cache was written with renamed cols; col 2 is raw_rate
    names(raw_tbl)[2] <- "raw_rate"
  }

  series <- raw_tbl |>
    dplyr::mutate(
      raw_rate = suppressWarnings(as.double(raw_rate)),
      year     = as.integer(format(as.Date(date), "%Y"))
    ) |>
    dplyr::filter(!is.na(raw_rate)) |>
    dplyr::group_by(year) |>
    dplyr::summarise(raw_rate = mean(raw_rate, na.rm = TRUE), .groups = "drop")

  # -- Data-driven orientation ------------------------------------------
  # If median < 1, values are CAD-per-JPY → invert to get JPY-per-CAD.
  # If median is already in tens–hundreds, use as-is.
  med <- stats::median(series$raw_rate, na.rm = TRUE)
  if (med < 1) {
    # BoC FXJPYCAD reports CAD per 1 JPY (~0.01); invert to get JPY per 1 CAD
    series$raw_rate <- 1 / series$raw_rate
  }
  # (If median >= 1 the series is already JPY/CAD — no inversion needed)

  out <- dplyr::rename(series, fx_jpy_per_cad = raw_rate)
  attr(out, "fx_year_range") <- range(out$year)
  out
}

# ---------------------------------------------------------------------------
# build_deflator() — FRED series CPALCY01CAA661N (Canada CPI, annual)
# Returns tibble: year (integer), cpi_ca (double), cpi_ca_2020base (double)
# ---------------------------------------------------------------------------

build_deflator <- function(
    cache = here::here("data-raw", "fx", "fred_cpi_ca.csv")) {

  if (file.exists(cache)) {
    # Integrity: MANIFEST is write-once at fetch time; manually re-verify with .write_manifest() if provenance is in question.
    tbl <- readr::read_csv(cache, show_col_types = FALSE)
    return(.rebase_cpi(tbl))
  }

  # -- FRED API key check ---------------------------------------------------
  api_key <- Sys.getenv("FRED_API_KEY")
  if (nchar(api_key) == 0) {
    stop(
      "FRED live fetch failed: missing API key. ",
      "Set env var FRED_API_KEY to a valid FRED API key before calling ",
      "build_deflator(). Free keys at https://fred.stlouisfed.org/docs/api/api_key.html. ",
      "Alternatively, place a pre-downloaded CSV at: ", cache
    )
  }

  # -- fredr package check --------------------------------------------------
  if (!requireNamespace("fredr", quietly = TRUE)) {
    stop(
      "FRED live fetch failed: 'fredr' package is not installed. ",
      "Run renv::install('fredr') inside the project, or place a ",
      "pre-downloaded CSV at: ", cache
    )
  }

  # -- Set key and fetch ----------------------------------------------------
  tryCatch(
    fredr::fredr_set_key(api_key),
    error = function(e) {
      stop(
        "FRED live fetch failed: could not set API key via fredr::fredr_set_key(). ",
        "Original error: ", conditionMessage(e)
      )
    }
  )

  raw <- tryCatch(
    fredr::fredr("CPALCY01CAA661N"),
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("401|403|unauthori|forbidden|api.?key|invalid key|bad api",
                msg, ignore.case = TRUE)) {
        stop(
          "FRED live fetch failed: invalid or rejected API key. ",
          "Check FRED_API_KEY is a valid 32-character alphanumeric string. ",
          "Original error: ", msg
        )
      } else if (grepl("network|connect|resolve|timeout|internet|cannot reach",
                       msg, ignore.case = TRUE)) {
        stop(
          "FRED live fetch failed: no network egress. ",
          "The environment cannot reach api.stlouisfed.org. ",
          "Provide a pre-downloaded CSV at: ", cache,
          ". Original error: ", msg
        )
      } else {
        stop(
          "FRED live fetch failed (other error). Original error: ", msg
        )
      }
    }
  )

  # Validate expected structure
  if (!all(c("date", "value") %in% names(raw))) {
    stop(
      "FRED response parse failed: expected columns 'date' and 'value', got: ",
      paste(names(raw), collapse = ", ")
    )
  }

  tbl <- dplyr::transmute(
    raw,
    year   = as.integer(format(date, "%Y")),
    cpi_ca = value
  ) |> dplyr::filter(!is.na(cpi_ca))

  if (nrow(tbl) == 0) {
    stop("FRED response is empty: no observations returned for CPALCY01CAA661N.")
  }

  # Check 2020 is present (needed for base rebase)
  if (!2020L %in% tbl$year) {
    stop(
      "FRED CPI data missing year 2020 — cannot compute 2020-base index. ",
      "Year range in response: ", min(tbl$year), "–", max(tbl$year)
    )
  }

  # -- Write cache and update manifest --------------------------------------
  dir.create(dirname(cache), showWarnings = FALSE, recursive = TRUE)
  readr::write_csv(tbl, cache)
  .write_manifest(cache)

  .rebase_cpi(tbl)
}

# Internal: add cpi_ca_2020base column
.rebase_cpi <- function(tbl) {
  base_val <- tbl$cpi_ca[tbl$year == 2020]
  if (length(base_val) > 1L) base_val <- base_val[1L]   # guard: dup 2020 rows (FRED revisions) -> R>=4.4 errors on if(length>1)
  if (length(base_val) == 0 || is.na(base_val)) {
    stop("CPI rebase failed: year 2020 not found in the CPI series.")
  }
  dplyr::mutate(tbl, cpi_ca_2020base = 100 * cpi_ca / base_val)
}

# ---------------------------------------------------------------------------
# Internal helper: write/update MANIFEST.sha256 in the same directory
# ---------------------------------------------------------------------------
.write_manifest <- function(file_path) {
  manifest_path <- file.path(dirname(file_path), "MANIFEST.sha256")

  sha256 <- tryCatch({
    res <- system2("shasum", c("-a", "256", file_path),
                   stdout = TRUE, stderr = FALSE)
    sub(" .*", "", res[1])
  }, error = function(e) {
    # Fallback to MD5 if shasum unavailable
    as.character(tools::md5sum(file_path))
  })

  # Append or update the entry for this file
  entry <- paste(sha256, basename(file_path))
  existing <- if (file.exists(manifest_path)) readLines(manifest_path) else character(0)
  other <- existing[!grepl(paste0("\\s", basename(file_path), "$"), existing)]
  writeLines(c(other, entry), manifest_path)
}
