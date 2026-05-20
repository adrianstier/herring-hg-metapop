# to_real(x, value_col, defl): convert a nominal value column to constant 2020
# dollars by joining a deflator table `defl` (must have columns `year`,
# `cpi_ca_2020base`, where 2020 == 100). Returns `x` plus a new `v_real` column;
# the original `value_col` is retained, `cpi_ca_2020base` is dropped.
# CONTRACT: for any `year` in `x` that has no matching row in `defl`, `v_real`
# is NA (you cannot deflate without a deflator). Given the BoC/FRED short-coverage
# reality (see layer_L3c FX COVERAGE CAVEAT), expect NA `v_real` outside the
# deflator's year span — this is intentional, not a bug. (Flag for Task 11 QA.)
# ASSUMES: x has no existing 'v_real' column (it is overwritten); defl$year is unique (enforced via stopifnot).
to_real <- function(x, value_col, defl) {
  stopifnot(!anyDuplicated(defl$year))   # fanout guard: dup years in defl would silently double rows (FRED revision vintages do occur)
  dplyr::left_join(x, defl[, c("year","cpi_ca_2020base")], by = "year") |>
    dplyr::mutate(v_real = .data[[value_col]] / (cpi_ca_2020base / 100)) |>
    dplyr::select(-cpi_ca_2020base)
}
