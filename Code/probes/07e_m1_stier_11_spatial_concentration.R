# ============================================================================
# 07e_m1_stier_11_spatial_concentration.R
# Annual posterior concentration/effective-section diagnostics.
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
post <- rstan::extract(fit, pars = "X")

years <- jags_data$years
site_names <- jags_data$site_names
focal_drop <- c("Tasu Sound & Gowgaia Bay", "Naden Harbour")
focal_idx <- which(!site_names %in% focal_drop)

summarise_draws <- function(x, prefix) {
  tibble(
    !!paste0(prefix, "_median") := median(x, na.rm = TRUE),
    !!paste0(prefix, "_lo90") := quantile(x, 0.05, na.rm = TRUE),
    !!paste0(prefix, "_hi90") := quantile(x, 0.95, na.rm = TRUE)
  )
}

concentration_for <- function(site_idx, report_set) {
  map_dfr(seq_along(years), function(t) {
    biomass <- exp(post$X[, t, site_idx, drop = FALSE])
    biomass <- matrix(biomass, nrow = dim(post$X)[1])
    shares <- biomass / rowSums(biomass)

    top1 <- apply(shares, 1, max)
    top3 <- apply(shares, 1, function(x) sum(sort(x, decreasing = TRUE)[seq_len(min(3, length(x)))]))
    simpson_eff_n <- 1 / rowSums(shares^2)
    entropy_eff_n <- exp(-rowSums(ifelse(shares > 0, shares * log(shares), 0)))

    bind_cols(
      tibble(year = years[t], report_set = report_set),
      summarise_draws(top1, "top1_share"),
      summarise_draws(top3, "top3_share"),
      summarise_draws(simpson_eff_n, "simpson_effective_sections"),
      summarise_draws(entropy_eff_n, "entropy_effective_sections")
    )
  })
}

concentration_df <- bind_rows(
  concentration_for(seq_along(site_names), "all_11"),
  concentration_for(focal_idx, "focal_9")
) %>%
  mutate(report_set = factor(report_set, levels = c("all_11", "focal_9")))

recent_summary <- concentration_df %>%
  filter(year >= 2017) %>%
  group_by(report_set) %>%
  summarise(
    top3_share = median(top3_share_median, na.rm = TRUE),
    simpson_effective_sections = median(simpson_effective_sections_median, na.rm = TRUE),
    entropy_effective_sections = median(entropy_effective_sections_median, na.rm = TRUE),
    .groups = "drop"
  )

cols <- c(all_11 = "#176B87", focal_9 = "#4F7F52")

p_eff <- ggplot(concentration_df, aes(x = year, colour = report_set, fill = report_set)) +
  geom_ribbon(
    aes(ymin = simpson_effective_sections_lo90, ymax = simpson_effective_sections_hi90),
    alpha = 0.12,
    colour = NA
  ) +
  geom_line(aes(y = simpson_effective_sections_median), linewidth = 0.7) +
  scale_colour_manual(values = cols, labels = c(all_11 = "All 11", focal_9 = "9 focal")) +
  scale_fill_manual(values = cols, labels = c(all_11 = "All 11", focal_9 = "9 focal")) +
  labs(
    x = NULL,
    y = "Effective sections",
    title = "Effective number of biomass-bearing sections",
    subtitle = "Simpson effective N from posterior biomass shares."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom", legend.title = element_blank())

p_top3 <- ggplot(concentration_df, aes(x = year, colour = report_set, fill = report_set)) +
  geom_ribbon(aes(ymin = top3_share_lo90, ymax = top3_share_hi90), alpha = 0.12, colour = NA) +
  geom_line(aes(y = top3_share_median), linewidth = 0.7) +
  scale_y_continuous(labels = label_percent(accuracy = 1), limits = c(0, 1)) +
  scale_colour_manual(values = cols, labels = c(all_11 = "All 11", focal_9 = "9 focal")) +
  scale_fill_manual(values = cols, labels = c(all_11 = "All 11", focal_9 = "9 focal")) +
  labs(
    x = "Year",
    y = "Top-3 biomass share",
    title = "How concentrated is biomass in the largest sections?",
    subtitle = "High values mean the archipelago total is carried by only a few sections."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom", legend.title = element_blank())

p <- p_eff / p_top3 +
  plot_annotation(
    title = "M1 Stier 11 spatial concentration diagnostic",
    subtitle = "Biomass recovery should be interpreted alongside effective section diversity."
  )

ggsave(
  file.path(fig_dir, "m1_stier_11_spatial_concentration.pdf"),
  p,
  width = 220,
  height = 170,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "m1_stier_11_spatial_concentration.png"),
  p,
  width = 220,
  height = 170,
  units = "mm",
  dpi = 300
)

write_csv(concentration_df, file.path(diag_dir, "m1_stier_11_spatial_concentration.csv"))
write_csv(recent_summary, file.path(diag_dir, "m1_stier_11_recent_spatial_concentration.csv"))

fmt <- function(x, digits = 2) {
  format(round(x, digits), trim = TRUE, big.mark = ",")
}

lines <- c(
  "# M1 Stier 11 Spatial Concentration",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Recent Closure Period",
  "",
  paste0(
    "- ",
    recent_summary$report_set,
    ": top-3 share = ",
    percent(recent_summary$top3_share, accuracy = 1),
    "; Simpson effective sections = ",
    fmt(recent_summary$simpson_effective_sections, 2),
    "; entropy effective sections = ",
    fmt(recent_summary$entropy_effective_sections, 2)
  ),
  "",
  "## Interpretation",
  "",
  "- Recent biomass is concentrated in a few sections even when total biomass rises.",
  "- This supports reporting portfolio state alongside biomass state.",
  "- The result reinforces the need for section-specific process structure before regional predator covariates.",
  "",
  "## Outputs",
  "",
  "- `Output/figures/m1_stier_11_spatial_concentration.pdf`",
  "- `Output/diagnostics/m1_stier_11_spatial_concentration.csv`",
  "- `Output/diagnostics/m1_stier_11_recent_spatial_concentration.csv`"
)

writeLines(lines, file.path(diag_dir, "m1_stier_11_spatial_concentration.md"))

cat("Saved spatial concentration diagnostics:\n")
cat("  Output/diagnostics/m1_stier_11_spatial_concentration.md\n")
cat("  Output/figures/m1_stier_11_spatial_concentration.pdf\n")
