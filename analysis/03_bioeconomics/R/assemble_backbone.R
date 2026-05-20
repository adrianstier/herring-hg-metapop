# assemble_backbone(): Integrate all available layers into the unified panel.
#
# Layer availability:
#   L0  (institutions) — always present
#   L1  (biology)      — always present
#   L2  (harvest)      — always present
#   L3a (digitized roe/sok values) — gated (Task 6 not yet built); graceful skip
#   L3b (kazunoko Comtrade)        — optional; fails without COMTRADE_KEY
#   L3c (FX + deflator)            — optional; fails without FRED key
#
# When a layer is unavailable its columns are absent (NA after left_join or
# simply not added) — this is correct: schema$required == FALSE for all L3 cols.

assemble_backbone <- function() {
  source(here::here("R", "schema.R"),              local = TRUE)
  source(here::here("R", "layer_L0_institutions.R"), local = TRUE)
  source(here::here("R", "layer_L1_biology.R"),      local = TRUE)
  source(here::here("R", "layer_L2_harvest.R"),      local = TRUE)
  source(here::here("R", "deflate.R"),               local = TRUE)

  # --- Required layers ---
  L0 <- build_L0(1950:2026)
  L1 <- build_L1()
  L2 <- build_L2()

  # --- L3a: digitized roe/sok anchor values (Task 6, gated) ---
  L3a <- tryCatch({
    source(here::here("R", "layer_L3a_digitized.R"), local = TRUE)
    raw <- build_L3a()
    tidyr::pivot_wider(raw, names_from = var, values_from = value) |>
      dplyr::mutate(region = factor(
        dplyr::recode(region, coastwide = "SoG"),
        levels = REGIONS
      ))
  }, error = function(e) {
    tibble::tibble(region = factor(character(), levels = REGIONS),
                   year   = integer())
  })

  # --- L3b: kazunoko Comtrade (optional, broadcasts across regions by year) ---
  L3b <- tryCatch({
    source(here::here("R", "layer_L3b_kazunoko.R"), local = TRUE)
    build_L3b()
  }, error = function(e) {
    tibble::tibble(year = integer())
  })

  # --- L3c: FX rates and CPI deflator (both optional) ---
  fx <- tryCatch({
    source(here::here("R", "layer_L3c_fx_deflators.R"), local = TRUE)
    build_fx()
  }, error = function(e) {
    tibble::tibble(year = integer())
  })

  defl <- tryCatch({
    # build_fx may already have sourced layer_L3c; source again safely via local=TRUE
    source(here::here("R", "layer_L3c_fx_deflators.R"), local = TRUE)
    build_deflator()
  }, error = function(e) {
    tibble::tibble(year = integer(), cpi_ca_2020base = double())
  })

  # --- Assemble: always-present layers ---
  bb <- L0 |>
    dplyr::left_join(L1, by = c("region", "year")) |>
    dplyr::left_join(L2, by = c("region", "year"))

  # --- Optional L3a join (skip when empty) ---
  if (nrow(L3a) > 0) {
    bb <- dplyr::left_join(bb, L3a, by = c("region", "year"))
  } else {
    # Ensure roe_value_cad_nominal column exists so deflation block below is consistent
    if (!"roe_value_cad_nominal" %in% names(bb)) {
      bb$roe_value_cad_nominal <- NA_real_
    }
  }

  # Ensure roe_value_cad_nominal exists regardless of L3a availability
  if (!"roe_value_cad_nominal" %in% names(bb)) {
    bb$roe_value_cad_nominal <- NA_real_
  }

  # --- Optional L3b join (broadcast by year across all regions) ---
  if (nrow(L3b) > 0 && "year" %in% names(L3b)) {
    bb <- dplyr::left_join(bb, L3b, by = "year")
  }

  # --- Optional FX join (broadcast by year) ---
  if (nrow(fx) > 0 && "year" %in% names(fx) && "fx_jpy_per_cad" %in% names(fx)) {
    bb <- dplyr::left_join(bb, dplyr::select(fx, year, fx_jpy_per_cad), by = "year")
  }

  # --- Deflate roe values to real 2020 CAD ---
  if ("roe_value_cad_nominal" %in% names(bb) &&
      nrow(defl) > 0 && "cpi_ca_2020base" %in% names(defl)) {
    r <- to_real(
      dplyr::select(bb, year, roe_value_cad_nominal),
      "roe_value_cad_nominal",
      defl
    )
    bb$roe_value_cad_real2020 <- r$v_real
  } else {
    bb$roe_value_cad_real2020 <- NA_real_
  }

  bb
}
