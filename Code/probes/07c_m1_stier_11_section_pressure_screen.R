# ============================================================================
# 07c_m1_stier_11_section_pressure_screen.R
# Section-level decline, fishing pressure, and spatial heterogeneity screen.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(patchwork)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "jags_model_inputs_v2.RData"))
fit <- readRDS(file.path(data_dir, "m1_stier_11_fit.rds"))

post <- rstan::extract(fit, pars = c("Z", "Pc_logit"))

years <- jags_data$years
site_names <- jags_data$site_names
n_draws <- dim(post$Z)[1]
n_years <- length(years)
n_sites <- length(site_names)

period_for_year <- function(year) {
  case_when(
    year <= 1965 ~ "1951-1965 early industrial",
    year <= 1971 ~ "1966-1971 late reduction",
    year <= 2004 ~ "1972-2004 roe fishery",
    year <= 2013 ~ "2005-2013 closure",
    year <= 2016 ~ "2014-2016 marine heatwave",
    TRUE ~ "2017-2025 recent closure"
  )
}

period_levels <- c(
  "1951-1965 early industrial",
  "1966-1971 late reduction",
  "1972-2004 roe fishery",
  "2005-2013 closure",
  "2014-2016 marine heatwave",
  "2017-2025 recent closure"
)

period_df <- tibble(
  year_index = seq_along(years),
  year = years,
  period = factor(period_for_year(year), levels = period_levels)
)

observed_catch_df <- tibble(
  year_index = jags_data$INDEX[, 1],
  site = jags_data$INDEX[, 2],
  observed_catch_tonnes = exp(jags_data$ctab[jags_data$INDEX])
) %>%
  mutate(
    year = years[year_index],
    site_name = site_names[site],
    period = factor(period_for_year(year), levels = period_levels)
  )

removed_draws <- array(0, dim = c(n_draws, n_years, n_sites))

for (k in seq_len(jags_data$nIndex)) {
  t <- jags_data$INDEX[k, 1]
  j <- jags_data$INDEX[k, 2]
  pc <- plogis(post$Pc_logit[, k])
  removed_draws[, t, j] <- removed_draws[, t, j] + exp(post$Z[, t, j]) * pc
}

section_year_pressure <- map_dfr(seq_len(n_years), function(t) {
  map_dfr(seq_len(n_sites), function(j) {
    z_draws <- exp(post$Z[, t, j])
    removed <- removed_draws[, t, j]
    tibble(
      year = years[t],
      site = j,
      site_name = site_names[j],
      removed_median = median(removed, na.rm = TRUE),
      removed_lo90 = quantile(removed, 0.05, na.rm = TRUE),
      removed_hi90 = quantile(removed, 0.95, na.rm = TRUE),
      fishing_fraction_median = median(removed / pmax(z_draws, 1e-12), na.rm = TRUE),
      fishing_fraction_lo90 = quantile(removed / pmax(z_draws, 1e-12), 0.05, na.rm = TRUE),
      fishing_fraction_hi90 = quantile(removed / pmax(z_draws, 1e-12), 0.95, na.rm = TRUE)
    )
  })
}) %>%
  left_join(period_df %>% select(year, period), by = "year")

section_pressure <- section_year_pressure %>%
  group_by(site, site_name) %>%
  summarise(
    cumulative_removed_median = sum(removed_median, na.rm = TRUE),
    mean_fishing_fraction_1951_2004 = mean(
      fishing_fraction_median[year <= 2004],
      na.rm = TRUE
    ),
    mean_fishing_fraction_roe = mean(
      fishing_fraction_median[period == "1972-2004 roe fishery"],
      na.rm = TRUE
    ),
    max_fishing_fraction = max(fishing_fraction_median, na.rm = TRUE),
    .groups = "drop"
  )

observed_section_catch <- observed_catch_df %>%
  group_by(site, site_name) %>%
  summarise(
    observed_catch_1951_2004 = sum(observed_catch_tonnes[year <= 2004], na.rm = TRUE),
    observed_catch_roe = sum(observed_catch_tonnes[period == "1972-2004 roe fishery"], na.rm = TRUE),
    max_observed_catch = max(observed_catch_tonnes, na.rm = TRUE),
    n_catch_years = n_distinct(year),
    .groups = "drop"
  )

section_change <- read_csv(
  file.path(diag_dir, "m1_stier_11_section_recent_change.csv"),
  show_col_types = FALSE
)

section_screen <- section_change %>%
  left_join(section_pressure, by = c("site", "site_name")) %>%
  left_join(observed_section_catch, by = c("site", "site_name")) %>%
  mutate(
    observed_catch_1951_2004 = replace_na(observed_catch_1951_2004, 0),
    observed_catch_roe = replace_na(observed_catch_roe, 0),
    max_observed_catch = replace_na(max_observed_catch, 0),
    n_catch_years = replace_na(n_catch_years, 0),
    early_biomass = `1951-1965 early industrial`,
    recent_biomass = `2017-2025 recent closure`
  )

section_cor_vars <- c(
  "early_biomass",
  "observed_catch_1951_2004",
  "observed_catch_roe",
  "cumulative_removed_median",
  "mean_fishing_fraction_1951_2004",
  "mean_fishing_fraction_roe",
  "max_fishing_fraction",
  "n_catch_years"
)

cor_tbl <- map_dfr(section_cor_vars, function(var) {
  dat <- section_screen %>%
    transmute(
      log_recent_to_early,
      predictor = .data[[var]]
    ) %>%
    filter(is.finite(log_recent_to_early), is.finite(predictor))

  if (nrow(dat) < 6 || sd(dat$predictor) == 0) {
    return(tibble(predictor = var, n = nrow(dat), spearman_rho = NA_real_, pearson_r = NA_real_))
  }

  tibble(
    predictor = var,
    n = nrow(dat),
    spearman_rho = unname(suppressWarnings(cor(dat$log_recent_to_early, dat$predictor, method = "spearman"))),
    pearson_r = unname(suppressWarnings(cor(dat$log_recent_to_early, dat$predictor, method = "pearson")))
  )
}) %>%
  arrange(desc(abs(spearman_rho)))

section_cols <- c(focal_9 = "#176B87", dropped_from_focal = "#C47F2C")

p_catch <- ggplot(section_screen, aes(x = observed_catch_1951_2004, y = recent_to_early_ratio)) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey45") +
  geom_point(aes(size = early_biomass, colour = focal_status), alpha = 0.86) +
  geom_text(
    aes(label = site_name),
    nudge_y = 0.08,
    size = 2.5,
    check_overlap = TRUE
  ) +
  scale_x_log10(labels = label_comma()) +
  scale_y_log10(labels = label_number(accuracy = 0.01)) +
  scale_size_continuous(labels = label_comma(), range = c(2, 8)) +
  scale_colour_manual(values = section_cols) +
  labs(
    x = "Observed catch through 2004",
    y = "Recent / early posterior biomass",
    size = "Early biomass",
    colour = NULL,
    title = "Historical catch does not fully explain section winners and losers",
    subtitle = "Values below 1 declined relative to 1951-1965; values above 1 increased."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_fraction <- section_screen %>%
  mutate(site_name = fct_reorder(site_name, recent_to_early_ratio)) %>%
  ggplot(aes(x = recent_to_early_ratio, y = site_name, fill = mean_fishing_fraction_roe)) +
  geom_col(width = 0.72) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey45") +
  scale_x_log10(labels = label_number(accuracy = 0.01)) +
  scale_fill_viridis_c(labels = label_percent(accuracy = 1)) +
  labs(
    x = "Recent / early posterior biomass",
    y = NULL,
    fill = "Mean roe-era fishing fraction",
    title = "Declines are spatially concentrated",
    subtitle = "Skidegate, Louscoone, Cumshewa, and Laskeek remain the strongest declines."
  ) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p <- p_catch / p_fraction +
  plot_annotation(
    title = "Section-level pressure and recovery screen",
    subtitle = "Fishing pressure matters, but section heterogeneity remains the central pattern to model next."
  )

ggsave(
  file.path(fig_dir, "m1_stier_11_section_pressure_screen.pdf"),
  p,
  width = 220,
  height = 190,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_section_pressure_screen.png"),
  p,
  width = 220,
  height = 190,
  units = "mm",
  dpi = 300
)

write_csv(section_year_pressure, file.path(diag_dir, "m1_stier_11_section_year_fishing_pressure.csv"))
write_csv(section_screen, file.path(diag_dir, "m1_stier_11_section_pressure_screen.csv"))
write_csv(cor_tbl, file.path(diag_dir, "m1_stier_11_section_pressure_correlations.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

decliners <- section_screen %>% arrange(log_recent_to_early) %>% slice_head(n = 5)
increasers <- section_screen %>% arrange(desc(log_recent_to_early)) %>% slice_head(n = 5)
top_cor <- cor_tbl %>% slice_head(n = 5)

lines <- c(
  "# M1 Stier 11 Section Pressure Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Purpose",
  "",
  "This screen asks whether section-level change since the early industrial period is explained by historical catch pressure, or whether the next Stan branch needs explicit section heterogeneity.",
  "",
  "## Largest Declines",
  "",
  paste0(
    "- ",
    decliners$site_name,
    ": recent / early = ",
    fmt(decliners$recent_to_early_ratio, 2),
    "; observed catch through 2004 = ",
    fmt(decliners$observed_catch_1951_2004, 0)
  ),
  "",
  "## Largest Increases",
  "",
  paste0(
    "- ",
    increasers$site_name,
    ": recent / early = ",
    fmt(increasers$recent_to_early_ratio, 2),
    "; observed catch through 2004 = ",
    fmt(increasers$observed_catch_1951_2004, 0)
  ),
  "",
  "## Cross-Section Associations With Recent / Early Change",
  "",
  paste0(
    "- ",
    top_cor$predictor,
    ": Spearman rho = ",
    fmt(top_cor$spearman_rho, 2),
    " (n=",
    top_cor$n,
    ")"
  ),
  "",
  "## Interpretation",
  "",
  "- The strongest pattern is not a single archipelago-wide decline; it is redistribution among sections.",
  "- Historical fishing pressure alone is too coarse to explain the winners and losers across 11 sections.",
  "- The next process model should allow section-specific productivity or process variance before adding a regional predator term.",
  "- Tasu and Naden remain important sensitivity points because they are retained in the 11-section model but excluded from Stier-style focal reporting.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_section_pressure_screen.pdf`",
  "- `Output/diagnostics/m1_stier_11_section_pressure_screen.csv`",
  "- `Output/diagnostics/m1_stier_11_section_pressure_correlations.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_section_pressure_screen.md"))

cat("Saved section pressure diagnostics:\n")
cat("  Output/diagnostics/m1_stier_11_section_pressure_screen.md\n")
cat("  Output/figures/m1_stier_11_section_pressure_screen.pdf\n")
