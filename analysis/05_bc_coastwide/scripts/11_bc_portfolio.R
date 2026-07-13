# ============================================================================
# 11_bc_portfolio.R — Coastwide portfolio metrics per stock area
# analysis/05_bc_coastwide
#
# Reuses R/11_early_warning.R synchrony/spatial functions where applicable.
# Output: phi (Loreau-de Mazancourt synchrony), CV-ratio (portfolio effect
# magnitude), occupancy fraction (sections active in given year).
# ============================================================================

suppressPackageStartupMessages({
  library(rstan)
  library(here)
  library(tidyverse)
})

source(here::here("R", "00_setup.R"))
source(here::here("R", "11_early_warning.R"))

obj <- readRDS(here::here("analysis", "05_bc_coastwide", "output", "m1_bc_fit.rds"))
fit <- obj$fit
section_meta <- obj$section_meta
stock_areas <- obj$stock_areas

z_draws <- rstan::extract(fit, "z")$z       # iter × sec × year
z_mean  <- apply(z_draws, c(2, 3), mean)     # sec × year

results <- list()
for (sa in stock_areas) {
  sec_idx <- which(section_meta$stock_area == sa)
  if (length(sec_idx) < 2L) next
  Z <- t(z_mean[sec_idx, , drop = FALSE])    # year × sec for ews fns

  phi <- ews_synchrony_phi(Z)
  cv_section <- apply(Z, 2, function(x) sd(x, na.rm = TRUE) / mean(x, na.rm = TRUE))
  cv_aggregate <- sd(rowMeans(Z), na.rm = TRUE) / mean(rowMeans(Z), na.rm = TRUE)
  cv_ratio <- mean(cv_section, na.rm = TRUE) / cv_aggregate
  occ <- mean(exp(z_mean[sec_idx, , drop = FALSE]) > 1, na.rm = TRUE)

  results[[length(results) + 1]] <- tibble(
    stock_area = sa,
    metric = c("phi_synchrony", "cv_ratio", "occupancy_fraction"),
    value = c(phi, cv_ratio, occ))
}
out <- bind_rows(results)
write_csv(out, here::here("Output", "diagnostics", "bc_portfolio_metrics.csv"))

writeLines(c("# BC portfolio metrics by stock area",
             "",
             paste("Generated:", format(Sys.time())),
             "",
             knitr::kable(out |> pivot_wider(names_from = metric,
                                              values_from = value))),
           here::here("Output", "diagnostics", "bc_portfolio_metrics.md"))
cat("Wrote BC portfolio metrics.\n")
