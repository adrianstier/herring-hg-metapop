# ============================================================================
# 07au_current_biomass_estimate.R
# Current biomass estimates from the promoted Stier-aligned baseline.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "jags_model_inputs_v2.RData"))

model_name <- "m1_stier_11"
fit_path <- file.path(data_dir, paste0(model_name, "_fit.rds"))
if (!file.exists(fit_path)) {
  stop("Promoted baseline fit not found: ", fit_path)
}

fit <- readRDS(fit_path)
post <- rstan::extract(fit, pars = c("X", "Z", "log_q"))

years <- jags_data$years
site_names <- jags_data$site_names
current_year <- max(years)
current_t <- which(years == current_year)

focal_drop <- c("Tasu Sound & Gowgaia Bay", "Naden Harbour")
focal_idx <- which(!site_names %in% focal_drop)
all_idx <- seq_along(site_names)

summarise_draws <- function(x) {
  tibble(
    mean = mean(x, na.rm = TRUE),
    median = median(x, na.rm = TRUE),
    lo80 = quantile(x, 0.10, na.rm = TRUE),
    hi80 = quantile(x, 0.90, na.rm = TRUE),
    lo90 = quantile(x, 0.05, na.rm = TRUE),
    hi90 = quantile(x, 0.95, na.rm = TRUE),
    lo95 = quantile(x, 0.025, na.rm = TRUE),
    hi95 = quantile(x, 0.975, na.rm = TRUE)
  )
}

total_summary <- bind_rows(
  summarise_draws(rowSums(exp(post$X[, current_t, all_idx, drop = FALSE][, 1, ]))) %>%
    mutate(year = current_year, model = model_name, state = "post-fishing", section_set = "all 11 sections"),
  summarise_draws(rowSums(exp(post$Z[, current_t, all_idx, drop = FALSE][, 1, ]))) %>%
    mutate(year = current_year, model = model_name, state = "pre-fishing", section_set = "all 11 sections"),
  summarise_draws(rowSums(exp(post$X[, current_t, focal_idx, drop = FALSE][, 1, ]))) %>%
    mutate(year = current_year, model = model_name, state = "post-fishing", section_set = "Stier focal 9"),
  summarise_draws(rowSums(exp(post$Z[, current_t, focal_idx, drop = FALSE][, 1, ]))) %>%
    mutate(year = current_year, model = model_name, state = "pre-fishing", section_set = "Stier focal 9")
) %>%
  select(year, model, state, section_set, everything())

section_summary <- map_dfr(all_idx, function(j) {
  summarise_draws(exp(post$X[, current_t, j])) %>%
    mutate(
      year = current_year,
      model = model_name,
      site = j,
      site_name = site_names[j],
      section_set = if_else(j %in% focal_idx, "Stier focal 9", "fit-only sensitivity"),
      .before = 1
    )
}) %>%
  arrange(desc(median))

observed_current <- tibble(
  year = current_year,
  surveyed_sections = sum((jags_data$Y_obs[current_t, ] + jags_data$Y_censored[current_t, ]) == 1L),
  positive_sections = sum(jags_data$Y_obs[current_t, ] == 1L),
  observed_positive_spawn_index_tonnes = sum(exp(jags_data$Y[current_t, jags_data$Y_obs[current_t, ] == 1L]), na.rm = TRUE),
  catch_tonnes = sum(jags_data$ctab[current_t, ], na.rm = TRUE)
)

q_summary <- map_dfr(seq_len(ncol(post$log_q)), function(i) {
  summarise_draws(exp(post$log_q[, i])) %>%
    mutate(
      model = model_name,
      q_index = i,
      survey_era = c("surface era <= 1987", "SCUBA/dive era >= 1988")[i],
      .before = 1
    )
})

write_csv(total_summary, file.path(diag_dir, "current_biomass_estimate_total.csv"))
write_csv(section_summary, file.path(diag_dir, "current_biomass_estimate_by_section.csv"))
write_csv(observed_current, file.path(diag_dir, "current_biomass_observed_context.csv"))
write_csv(q_summary, file.path(diag_dir, "current_biomass_q_context.csv"))

fmt <- function(x, accuracy = 1) {
  number(x, accuracy = accuracy, big.mark = ",")
}

all_post <- total_summary %>%
  filter(state == "post-fishing", section_set == "all 11 sections") %>%
  slice(1)
focal_post <- total_summary %>%
  filter(state == "post-fishing", section_set == "Stier focal 9") %>%
  slice(1)
top_sections <- section_summary %>%
  slice_head(n = 5)

lines <- c(
  "# Current Biomass Estimate",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Model",
  "",
  paste0("- Promoted baseline: `", model_name, "`."),
  "- Zero spawn records are treated as ambiguous/missing, following the current Stier-aligned baseline.",
  "- Biomass is the model-estimated latent biomass on the DFO tonnes-scale state-space model, not an official DFO stock-assessment biomass estimate.",
  "",
  "## Current-Year Estimate",
  "",
  paste0(
    "- ", current_year, " all-11 post-fishing biomass median: `",
    fmt(all_post$median), " t` (80% interval `", fmt(all_post$lo80), "`-`",
    fmt(all_post$hi80), " t`; 90% interval `", fmt(all_post$lo90), "`-`",
    fmt(all_post$hi90), " t`)."
  ),
  paste0(
    "- ", current_year, " Stier focal-9 post-fishing biomass median: `",
    fmt(focal_post$median), " t` (80% interval `", fmt(focal_post$lo80), "`-`",
    fmt(focal_post$hi80), " t`; 90% interval `", fmt(focal_post$lo90), "`-`",
    fmt(focal_post$hi90), " t`)."
  ),
  paste0(
    "- Observed positive spawn-index total in ", current_year, ": `",
    fmt(observed_current$observed_positive_spawn_index_tonnes), " t` across `",
    observed_current$positive_sections, "` positive sections and `",
    observed_current$surveyed_sections, "` surveyed sections."
  ),
  "",
  "## Largest Section Medians",
  "",
  knitr::kable(
    top_sections %>%
      transmute(
        section = site_name,
        median_t = round(median),
        lo80_t = round(lo80),
        hi80_t = round(hi80),
        section_set
      ),
    format = "pipe"
  ),
  "",
  "## Caveats",
  "",
  "- The all-11 estimate is wider than the focal-9 estimate because Tasu and Naden are sparse-data sensitivity sections.",
  "- The estimate is anchored by the proportional spawn-index and catch observation equations; do not compare it as if it were a direct census.",
  "- Use `Output/diagnostics/model_branch_status_table.md` for the current model-selection decision before citing this number.",
  "",
  "## Files",
  "",
  "- `Output/diagnostics/current_biomass_estimate_total.csv`",
  "- `Output/diagnostics/current_biomass_estimate_by_section.csv`",
  "- `Output/diagnostics/current_biomass_observed_context.csv`",
  "- `Output/diagnostics/current_biomass_q_context.csv`"
)

writeLines(lines, file.path(diag_dir, "current_biomass_estimate.md"))
cat(paste(lines, collapse = "\n"))
