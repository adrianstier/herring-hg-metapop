# L3b: Japan kazunoko (herring roe) imports via UN Comtrade
#
# HS CODE NOTE: 030520 = "Fish, dried, salted or in brine; smoked fish; flours, meals and
# pellets of fish, fit for human consumption" -> in practice this 6-digit code is the
# standard proxy for fish ROE (salted/dried), including herring kazunoko.
# DOCUMENTED V1 OVER-BROAD PROXY: HS 030520 captures all fish roe, not herring roe
# exclusively. No herring-specific HS code exists at the 6-digit level. Flag for
# Task 11 QA / DATA_DICTIONARY: quantify non-herring fraction if disaggregated data
# become available.
#
# NO REGION KEY: Japan national series; joins to backbone at year level in Task 10.
#
# DATA INTEGRITY CONTRACT: If neither a local cache nor a live API pull is possible,
# build_L3b() stops with a precise error message. The test skips (not fails) in that
# case. No data is fabricated.
#
# CURRENCY: UN Comtrade trade values are USD (not JPY, not CAD). This layer
# returns kazunoko_import_val_usd as-is. Task 10 must convert USD -> JPY/CAD
# using an FX series before any revenue arithmetic. (Flag for Task 11 QA.)

`%||%` <- function(a, b) if (!is.null(a)) a else b

build_L3b <- function(
    cache = here::here("data-raw", "trade", "comtrade_jpn_030520.csv")) {

  if (file.exists(cache)) {
    raw <- readr::read_csv(cache, show_col_types = FALSE)
  } else {
    dir.create(dirname(cache), showWarnings = FALSE, recursive = TRUE)

    # --- API key handling (modern comtradr >= 0.4 requires a primary key) ---
    api_key <- Sys.getenv("COMTRADE_PRIMARY_KEY")
    if (nchar(api_key) == 0) api_key <- Sys.getenv("COMTRADE_API_KEY")

    if (nchar(api_key) == 0) {
      stop(
        "Comtrade live pull failed: missing API key. ",
        "Set env var COMTRADE_PRIMARY_KEY (or COMTRADE_API_KEY) to a valid ",
        "UN Comtrade primary subscription key before calling build_L3b(). ",
        "Free keys available at https://comtradeplus.un.org/. ",
        "Alternatively, place a pre-downloaded CSV at: ", cache
      )
    }

    if (!requireNamespace("comtradr", quietly = TRUE)) {
      stop(
        "Comtrade live pull failed: 'comtradr' package is not installed. ",
        "Run renv::install('comtradr') inside the project, or place a ",
        "pre-downloaded CSV at: ", cache
      )
    }

    tryCatch(
      comtradr::set_primary_comtrade_key(api_key),
      error = function(e) {
        stop(
          "Comtrade live pull failed: could not set API key via ",
          "comtradr::set_primary_comtrade_key(). ",
          "Check that COMTRADE_PRIMARY_KEY is a valid key. ",
          "Original error: ", conditionMessage(e)
        )
      }
    )

    raw <- tryCatch(
      comtradr::ct_get_data(
        reporter        = "JPN",
        flow_direction  = "import",
        commodity_code  = "030520",
        start_date      = 1988,
        end_date        = 2020
      ),
      error = function(e) {
        msg <- conditionMessage(e)
        if (grepl("401|403|unauthori|forbidden|api.?key|token", msg,
                  ignore.case = TRUE)) {
          stop(
            "Comtrade live pull failed: invalid or expired API key ",
            "(HTTP 401/403). ",
            "Renew your key at https://comtradeplus.un.org/ and set ",
            "COMTRADE_PRIMARY_KEY. Original error: ", msg
          )
        } else if (grepl("network|connect|resolve|timeout|internet",
                         msg, ignore.case = TRUE)) {
          stop(
            "Comtrade live pull failed: no network egress. ",
            "The environment does not have outbound internet access to ",
            "comtradeplus.un.org. Provide a pre-downloaded CSV at: ",
            cache, ". Original error: ", msg
          )
        } else {
          stop(
            "Comtrade live pull failed (other error). ",
            "Original error: ", msg
          )
        }
      }
    )

    readr::write_csv(raw, cache)

    # Write sha256 manifest alongside the CSV
    manifest_path <- file.path(dirname(cache), "MANIFEST.sha256")
    sha <- tryCatch(
      tools::md5sum(cache),   # Fallback: MD5 (shasum unavailable) — content is MD5, not a true SHA-256.
      error = function(e) NA_character_
    )
    # Prefer shasum system tool for true SHA-256 if available
    sha256 <- tryCatch({
      res <- system2("shasum", c("-a", "256", cache),
                     stdout = TRUE, stderr = FALSE)
      sub(" .*", "", res[1])
    }, error = function(e) as.character(sha))
    writeLines(paste(sha256, basename(cache)), manifest_path)
  }

  # --- Normalise column names and reshape ---
  clean <- janitor::clean_names(raw)

  # comtradr column names differ between package versions; handle both
  year_col  <- clean[["ref_year"]]  %||% clean[["period"]]
  qty_col   <- clean[["net_wgt"]]   %||% clean[["netweight"]]
  val_col   <- clean[["primary_value"]] %||% clean[["trade_value"]]

  # If column resolution still fails, try direct name lookup
  if (is.null(year_col)) {
    yname <- intersect(names(clean), c("ref_year", "period", "year"))[1]
    if (!is.na(yname)) year_col <- clean[[yname]]
  }
  if (is.null(qty_col)) {
    qname <- intersect(names(clean), c("net_wgt", "netweight", "qty"))[1]
    if (!is.na(qname)) qty_col <- clean[[qname]]
  }
  if (is.null(val_col)) {
    vname <- intersect(names(clean), c("primary_value", "trade_value",
                                       "cifvalue", "fobvalue"))[1]
    if (!is.na(vname)) val_col <- clean[[vname]]
  }

  if (is.null(year_col)) {
    stop(
      "NEEDS_CONTEXT: build_L3b() could not detect a year column in the ",
      "Comtrade CSV. Available columns: ", paste(names(clean), collapse = ", ")
    )
  }
  if (is.null(qty_col)) stop("NEEDS_CONTEXT: could not resolve a net-weight/quantity column in Comtrade response. Columns: ", paste(names(clean), collapse=", "))
  if (is.null(val_col)) stop("NEEDS_CONTEXT: could not resolve a trade-value column in Comtrade response. Columns: ", paste(names(clean), collapse=", "))

  dplyr::tibble(
    year                    = as.integer(year_col),
    kazunoko_import_qty_t   = suppressWarnings(as.double(qty_col)) / 1000,
    kazunoko_import_val_usd = suppressWarnings(as.double(val_col))
  ) |>
    dplyr::filter(!is.na(year)) |>
    dplyr::group_by(year) |>
    dplyr::summarise(
      dplyr::across(everything(), \(x) sum(x, na.rm = TRUE)),
      .groups = "drop"
    )
}
