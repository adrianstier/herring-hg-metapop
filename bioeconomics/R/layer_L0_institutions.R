# Requires: REGIONS from R/schema.R (used as the default `regions` arg, evaluated at call time).
# `regions` is a test escape hatch — Task 10 / production must call with the default REGIONS
# so factor levels match the schema contract and the Task 10 left-join.
build_L0 <- function(years, regions = REGIONS) {
  classify <- function(y) dplyr::case_when(
    y <= 1966 ~ "reduction",
    y %in% 1967:1971 ~ "moratorium",
    y %in% 1972:1997 ~ "roe_openaccess",
    y >= 1998 ~ "roe_ivq_pool"
  )
  tidyr::expand_grid(region = factor(regions, levels = regions), year = years) |>
    dplyr::mutate(
      regime = factor(classify(year),
        levels = c("reduction","moratorium","roe_openaccess","roe_ivq_pool")),
      fishery_open = dplyr::case_when(
        year %in% 1967:1971 ~ FALSE,                              # coastwide moratorium
        region == "HG" & year >= 1999 & year != 2002 ~ FALSE,     # HG closed 1999-2001 & 2003-present (open-ended); 2002 gap year
        TRUE ~ TRUE
      )
    )
}
