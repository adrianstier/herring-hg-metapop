# ============================================================================
# 08_fit_m5_bc.R — Fit hierarchical M5 BC-wide (adds predator covariates)
# analysis/05_bc_coastwide
#
# Same structure as scripts/07_fit_m3_bc.R but uses M5 .stan and adds
# predator_covs (and N_pred_covs) to the Stan input list.
# ============================================================================

suppressPackageStartupMessages({
  library(rstan)
  library(here)
  library(tidyverse)
})

source(here::here("R", "00_setup.R"))
source(here::here("R", "cloud_fit_control.R"))

rstan_options(auto_write = TRUE)

stan_data <- readRDS(here::here("Data", "processed", "bc_stan_data.rds"))

SUBSET <- Sys.getenv("SUBSET", unset = "HG_WCVI")
orig_codes <- sort(unique(stan_data$section_meta$stock_area))

if (SUBSET != "ALL") {
  keep_codes <- strsplit(SUBSET, "_")[[1]]
  cat("Subsetting to stock areas:", paste(keep_codes, collapse = ", "), "\n")
  keep_idx <- which(stan_data$section_meta$stock_area %in% keep_codes)
  stock_area_remap <- setNames(seq_along(keep_codes), keep_codes)

  stan_data$N_sections <- length(keep_idx)
  stan_data$y <- stan_data$y[keep_idx, , drop = FALSE]
  stan_data$obs_mask <- stan_data$obs_mask[keep_idx, , drop = FALSE]
  stan_data$stock_area_of <- as.integer(
    stock_area_remap[stan_data$section_meta$stock_area[keep_idx]])
  stan_data$N_stock_areas <- length(keep_codes)
  stan_data$section_meta <- stan_data$section_meta[keep_idx, ]

  D_list_full <- list()
  prev_end <- 0L
  for (i in seq_along(stan_data$block_sizes)) {
    sz <- stan_data$block_sizes[i]
    start <- prev_end + 1L
    end <- prev_end + sz * sz
    if (sz > 0) D_list_full[[i]] <- stan_data$D_blocks[start:end]
    else        D_list_full[[i]] <- numeric(0)
    prev_end <- end
  }
  blocks <- list()
  block_sizes_new <- integer()
  for (sa in keep_codes) {
    idx <- match(sa, orig_codes)
    if (is.na(idx)) {
      blocks[[sa]] <- numeric(0)
      block_sizes_new <- c(block_sizes_new, 0L)
    } else {
      blocks[[sa]] <- D_list_full[[idx]]
      block_sizes_new <- c(block_sizes_new,
                           as.integer(sqrt(length(D_list_full[[idx]]))))
    }
  }
  stan_data$D_blocks <- unlist(blocks)
  stan_data$block_sizes <- block_sizes_new
  stan_data$block_starts <- cumsum(c(1L, head(sapply(blocks, length), -1)))
  stan_data$N_D <- length(stan_data$D_blocks)

  # Trim predator covariates to kept stock areas
  keep_sa_idx <- match(keep_codes, orig_codes)
  stan_data$predator_covs <- stan_data$predator_covs[keep_sa_idx, , , drop = FALSE]
  stan_data$stock_area_codes <- keep_codes
}

stan_input <- stan_data[c("N_sections", "N_years", "N_stock_areas",
                          "stock_area_of", "y", "obs_mask",
                          "N_D", "D_blocks", "block_starts", "block_sizes",
                          "predator_covs")]
stan_input$N_pred_covs <- dim(stan_input$predator_covs)[3]

ctrl <- cloud_fit_control()
cat("Sampler config: chains=", ctrl$chains, " iter=", ctrl$iter,
    " warmup=", ctrl$warmup, " cores=", ctrl$cores, "\n")

mod <- stan_model(here::here("analysis", "05_bc_coastwide", "stan",
                             "herring_metapop_bc_m5.stan"))
fit <- sampling(mod, data = stan_input,
                chains = ctrl$chains, iter = ctrl$iter,
                warmup = ctrl$warmup, cores = ctrl$cores,
                refresh = max(50L, ctrl$iter %/% 20L),
                control = list(adapt_delta = 0.95, max_treedepth = 12))

out_dir <- here::here("analysis", "05_bc_coastwide", "output")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
out_name <- if (SUBSET == "ALL") "m5_bc_fit.rds" else
            paste0("m5_bc_subset_", SUBSET, "_fit.rds")
out_path <- file.path(out_dir, out_name)

saveRDS(list(fit = fit, stock_areas = stan_data$stock_area_codes,
             section_meta = stan_data$section_meta),
        out_path)
cat("Wrote fit to", out_path, "\n")
