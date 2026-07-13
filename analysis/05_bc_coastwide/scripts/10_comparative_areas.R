# ============================================================================
# 10_comparative_areas.R — Recovery-curve comparison across stock areas
# analysis/05_bc_coastwide
#
# For each stock area, anchor at the closure year (or 1990 for SoG which
# never closed) and compute the posterior-mean section-averaged biomass
# trajectory in 5-year post-event bins.
# ============================================================================

suppressPackageStartupMessages({
  library(rstan)
  library(here)
  library(tidyverse)
})

source(here::here("R", "00_setup.R"))

obj <- readRDS(here::here("analysis", "05_bc_coastwide", "output", "m1_bc_fit.rds"))
fit <- obj$fit
section_meta <- obj$section_meta
stock_areas <- obj$stock_areas

z_draws <- rstan::extract(fit, "z")$z      # iterations × sections × years
z_mean  <- apply(z_draws, c(2, 3), mean)    # sections × years

events <- read_csv(here::here("Data", "processed", "bc_fishery_events.csv"),
                   show_col_types = FALSE) |>
  group_by(stock_area) |>
  summarise(anchor_year = ifelse(all(is.na(event_year)), 1990L,
                                  min(event_year, na.rm = TRUE)),
            .groups = "drop")

YEARS_idx <- seq_along(YEARS)
results <- list()
for (sa in stock_areas) {
  anchor <- events |> filter(stock_area == sa) |> pull(anchor_year)
  if (length(anchor) == 0) anchor <- 1990L
  sec_idx <- which(section_meta$stock_area == sa)
  if (length(sec_idx) == 0) next

  for (yp in seq(0, 20, by = 5)) {
    yr <- anchor + yp
    if (yr < min(YEARS) || yr > max(YEARS)) next
    yi <- match(yr, YEARS)
    val <- mean(z_mean[sec_idx, yi])
    results[[length(results) + 1]] <- tibble(
      stock_area = sa,
      years_post_event = yp,
      recovery_metric_name = "mean_log_biomass",
      recovery_metric_value = val)
  }
}
out <- bind_rows(results)
write_csv(out, here::here("Output", "diagnostics", "bc_comparative_areas.csv"))

md <- c("# BC comparative-areas recovery",
        "",
        paste("Generated:", format(Sys.time())),
        "",
        knitr::kable(out |> pivot_wider(names_from = years_post_event,
                                        values_from = recovery_metric_value)))
writeLines(md, here::here("Output", "diagnostics", "bc_comparative_areas.md"))
cat("Wrote comparative-areas outputs.\n")
