# ============================================================================
# 09_diagnostics.R — MCMC + posterior-predictive + LOO across M1/M3/M5
# analysis/05_bc_coastwide
# ============================================================================

suppressPackageStartupMessages({
  library(rstan)
  library(loo)
  library(posterior)
  library(here)
  library(tidyverse)
})

source(here::here("R", "00_setup.R"))

models <- c(m1_bc = "m1_bc_fit.rds",
            m3_bc = "m3_bc_fit.rds",
            m5_bc = "m5_bc_fit.rds")

mcmc_lines <- c("# BC-coastwide MCMC diagnostics",
                "",
                paste("Generated:", format(Sys.time())),
                "")
loo_rows <- list()

for (m in names(models)) {
  path <- here::here("analysis", "05_bc_coastwide", "output", models[[m]])
  if (!file.exists(path)) {
    mcmc_lines <- c(mcmc_lines, sprintf("## %s — MISSING (%s)", m, path))
    next
  }
  obj <- readRDS(path)
  fit <- obj$fit

  summ <- summary(fit, pars = c("r_area", "sigma_area", "sigma_obs"))$summary
  bad_rhat <- sum(summ[, "Rhat"] > 1.01, na.rm = TRUE)
  low_ess  <- sum(summ[, "n_eff"] < 400,  na.rm = TRUE)
  divs <- sum(get_divergent_iterations(fit))

  mcmc_lines <- c(mcmc_lines,
                  sprintf("## %s", m),
                  sprintf("- bad Rhat (>1.01): %d", bad_rhat),
                  sprintf("- low ESS (<400):   %d", low_ess),
                  sprintf("- divergent transitions: %d", divs),
                  "")

  loo_res <- tryCatch(
    loo::loo(fit, save_psis = FALSE),
    error = function(e) NULL
  )
  if (!is.null(loo_res)) {
    loo_rows[[m]] <- tibble(
      model = m,
      elpd_loo = loo_res$estimates["elpd_loo", "Estimate"],
      se_elpd_loo = loo_res$estimates["elpd_loo", "SE"])
  }
}

dir.create(here::here("Output", "diagnostics"), showWarnings = FALSE, recursive = TRUE)
writeLines(mcmc_lines,
           here::here("Output", "diagnostics",
                      "bc_coastwide_mcmc_diagnostics.md"))

if (length(loo_rows) > 0) {
  loo_tab <- bind_rows(loo_rows)
  write_csv(loo_tab,
            here::here("Output", "diagnostics", "bc_coastwide_loo_table.csv"))
} else {
  write_csv(tibble(model = names(models),
                   elpd_loo = NA_real_,
                   se_elpd_loo = NA_real_),
            here::here("Output", "diagnostics", "bc_coastwide_loo_table.csv"))
}

cat("Wrote diagnostics + LOO outputs.\n")
