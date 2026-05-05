## ==========================================================================
##  04_portfolio_analysis.R
##  Portfolio effect, synchrony, and spatial diversity analysis for
##  Haida Gwaii Pacific herring metapopulation (1951-2025).
##
##  Computes observed-data metrics from Stier et al. (2020, Ecosphere),
##  extended to the full 1951-2025 time series:
##    1. Portfolio Effect (PE) — ratio of weighted-mean subpopulation CV
##       to archipelago CV, in rolling 10-year windows
##    2. Synchrony (phi) — Loreau & de Mazancourt (2008) index
##    3. Variance Ratio (VR) — var(sum) / sum(var)
##    4. Site Occupancy — number of sections spawning per year
##    5. Spatial Evenness — Shannon H and Simpson D diversity indices
##
##  This script runs independently of the Stan/JAGS model fitting.
##  It uses the raw observed spawn index (SHI) from the CSV, filtered
##  to the same 11 sections used in the state-space model.
## ==========================================================================

library(tidyverse)

proj_dir <- here::here()
proc_dir <- file.path(proj_dir, "Data", "processed")
fig_dir  <- file.path(proj_dir, "Output", "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

## =========================================================================
##  0. COLOUR PALETTE AND THEME
## =========================================================================

# Okabe-Ito colorblind-safe palette (11 colours for 11 sections)
okabe_ito <- c(
  "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2",
  "#D55E00", "#CC79A7", "#000000", "#999999", "#882255", "#44AA99"
)

theme_set(theme_minimal(base_size = 11))

## =========================================================================
##  1. LOAD AND PREPARE DATA
## =========================================================================

spawn_raw <- read_csv(
  file.path(proc_dir, "HG_Spawn_Survey_1951_2025_all_sections.csv"),
  show_col_types = FALSE
)

# Keep the same 11 sections as the state-space model
# (drop section 4 = Cartwright Sound, section 11 = Masset Inlet)
keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)

spawn <- spawn_raw %>%
  filter(section %in% keep_sections) %>%
  select(year, section, section_name, spawn_index_tonnes) %>%
  arrange(year, section)

site_names <- spawn %>%
  distinct(section, section_name) %>%
  arrange(section) %>%
  pull(section_name)

n_sites <- length(site_names)
years   <- sort(unique(spawn$year))
n_years <- length(years)

cat("Portfolio analysis: ", n_sites, " sections, ",
    min(years), "-", max(years), " (", n_years, " years)\n", sep = "")

# Wide matrix: rows = years, cols = sections (raw SHI, zeros intact)
spawn_wide <- spawn %>%
  pivot_wider(
    id_cols     = year,
    names_from  = section_name,
    values_from = spawn_index_tonnes
  ) %>%
  arrange(year)

spawn_mat <- as.matrix(spawn_wide[, -1])
rownames(spawn_mat) <- spawn_wide$year

cat("Spawn matrix dimensions: ", nrow(spawn_mat), " x ", ncol(spawn_mat), "\n")
cat("Total non-zero observations: ", sum(spawn_mat > 0, na.rm = TRUE),
    " of ", prod(dim(spawn_mat)), "\n")


## =========================================================================
##  2. KEY TIME PERIOD ANNOTATIONS
## =========================================================================

# Used across all time-series plots
key_events <- tibble(

  xintercept = c(2005, 2014, 2016),
  label      = c("Fishery closure", "MHW start", "MHW end"),
  linetype   = c("dashed", "dotted", "dotted")
)

# Helper: add vertical reference lines to a ggplot
add_key_events <- function(p) {
  p +
    geom_vline(xintercept = 2005, linetype = "dashed",
               colour = "grey40", linewidth = 0.4) +
    geom_vline(xintercept = 2014, linetype = "dotted",
               colour = "firebrick", linewidth = 0.4) +
    geom_vline(xintercept = 2016, linetype = "dotted",
               colour = "firebrick", linewidth = 0.4) +
    annotate("text", x = 2005, y = Inf, label = "Fishery\nclosure",
             vjust = 1.5, hjust = 1.1, size = 2.5, colour = "grey40") +
    annotate("rect", xmin = 2014, xmax = 2016,
             ymin = -Inf, ymax = Inf,
             fill = "firebrick", alpha = 0.06)
}


## =========================================================================
##  3. PLOT 1 — TIME SERIES OF SPAWN INDEX BY SECTION (FACETED)
## =========================================================================

spawn_long <- spawn %>%
  mutate(section_name = factor(section_name, levels = site_names))

p_ts <- ggplot(spawn_long, aes(x = year, y = spawn_index_tonnes)) +
  geom_line(colour = "grey50", linewidth = 0.3) +
  geom_point(aes(colour = spawn_index_tonnes > 0), size = 0.6, show.legend = FALSE) +
  scale_colour_manual(values = c("TRUE" = "#0072B2", "FALSE" = "grey80")) +
  facet_wrap(~ section_name, scales = "free_y", ncol = 3) +
  geom_vline(xintercept = 2005, linetype = "dashed",
             colour = "grey40", linewidth = 0.3) +
  geom_vline(xintercept = 2014, linetype = "dotted",
             colour = "firebrick", linewidth = 0.3) +
  geom_vline(xintercept = 2016, linetype = "dotted",
             colour = "firebrick", linewidth = 0.3) +
  scale_x_continuous(breaks = seq(1950, 2025, by = 15)) +
  labs(x = "Year", y = "Spawn Index (tonnes)",
       title = "Haida Gwaii herring spawn index by section (1951-2025)") +
  theme(
    strip.text      = element_text(size = 7),
    axis.text        = element_text(size = 6),
    plot.title       = element_text(size = 10, face = "bold"),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(fig_dir, "spawn_timeseries_by_section.pdf"),
       p_ts, width = 220, height = 200, units = "mm", dpi = 300)
ggsave(file.path(fig_dir, "spawn_timeseries_by_section.png"),
       p_ts, width = 220, height = 200, units = "mm", dpi = 300)

cat("Plot 1 saved: spawn_timeseries_by_section\n")


## =========================================================================
##  4. SITE OCCUPANCY
## =========================================================================

occupancy <- spawn %>%
  group_by(year) %>%
  summarise(
    n_occupied   = sum(spawn_index_tonnes > 0, na.rm = TRUE),
    n_total      = n(),
    prop_occupied = n_occupied / n_total,
    .groups      = "drop"
  )

p_occ <- ggplot(occupancy, aes(x = year, y = n_occupied)) +
  geom_line(linewidth = 0.6, colour = "#0072B2") +
  geom_point(size = 1, colour = "#0072B2") +
  geom_hline(yintercept = n_sites, linetype = "dashed",
             colour = "grey60", linewidth = 0.3) +
  scale_y_continuous(limits = c(0, n_sites + 0.5),
                     breaks = seq(0, n_sites, by = 2)) +
  scale_x_continuous(breaks = seq(1950, 2025, by = 10)) +
  labs(x = "Year",
       y = "Number of sections with spawning",
       title = "Site occupancy (out of 11 sections)")

p_occ <- add_key_events(p_occ) +
  theme(panel.grid.minor = element_blank())

ggsave(file.path(fig_dir, "site_occupancy.pdf"),
       p_occ, width = 170, height = 100, units = "mm", dpi = 300)
ggsave(file.path(fig_dir, "site_occupancy.png"),
       p_occ, width = 170, height = 100, units = "mm", dpi = 300)

cat("Plot 2 saved: site_occupancy\n")


## =========================================================================
##  5. SPATIAL EVENNESS (SHANNON H AND SIMPSON D)
## =========================================================================

evenness <- spawn %>%
  filter(spawn_index_tonnes > 0) %>%
  group_by(year) %>%
  mutate(
    total_spawn = sum(spawn_index_tonnes, na.rm = TRUE),
    p_i       = spawn_index_tonnes / total_spawn
  ) %>%
  summarise(
    shannon_H = -sum(p_i * log(p_i), na.rm = TRUE),
    simpson_D = 1 - sum(p_i^2, na.rm = TRUE),
    n_sites_active = n(),
    .groups = "drop"
  ) %>%
  # Effective number of species (exp of Shannon) for intuitive interpretation

  mutate(effective_n = exp(shannon_H))


p_even <- evenness %>%
  pivot_longer(cols = c(shannon_H, simpson_D),
               names_to = "metric", values_to = "value") %>%
  mutate(metric = recode(metric,
                         "shannon_H" = "Shannon H",
                         "simpson_D" = "Simpson D (1 - sum(p^2))")) %>%
  ggplot(aes(x = year, y = value)) +
  geom_line(linewidth = 0.6, colour = "#009E73") +
  geom_point(size = 0.8, colour = "#009E73") +
  facet_wrap(~ metric, ncol = 1, scales = "free_y") +
  scale_x_continuous(breaks = seq(1950, 2025, by = 10)) +
  labs(x = "Year", y = "Diversity index value",
       title = "Spatial evenness of herring spawn across sections")

p_even <- add_key_events(p_even) +
  theme(panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold"))

ggsave(file.path(fig_dir, "spatial_evenness.pdf"),
       p_even, width = 170, height = 140, units = "mm", dpi = 300)
ggsave(file.path(fig_dir, "spatial_evenness.png"),
       p_even, width = 170, height = 140, units = "mm", dpi = 300)

cat("Plot 3 saved: spatial_evenness\n")


## =========================================================================
##  6. ROLLING WINDOW FUNCTIONS
## =========================================================================

window_size <- 10  # 10-year rolling windows, same as Stier et al. 2020

#' Portfolio Effect: CV_single / CV_portfolio
#' @param mat Matrix (years x sites) of raw spawn index. Zeros are included
#'   in the portfolio sum but excluded from individual-site CV calculation
#'   (sites with all-zero values in the window are dropped).
compute_pe <- function(mat) {
  # Portfolio (archipelago) CV
  total <- rowSums(mat, na.rm = TRUE)
  cv_portfolio <- sd(total) / mean(total)


  # Weighted average of individual site CVs
  # Weight = mean biomass of each site / total mean biomass
  site_means <- colMeans(mat, na.rm = TRUE)
  site_sds   <- apply(mat, 2, sd, na.rm = TRUE)
  site_cvs   <- ifelse(site_means > 0, site_sds / site_means, NA)

  # Weights proportional to mean biomass
  weights    <- site_means / sum(site_means, na.rm = TRUE)

  # Weighted average CV (excluding sites with zero mean)
  valid      <- !is.na(site_cvs) & site_means > 0
  if (sum(valid) < 2) return(NA_real_)

  cv_single  <- sum(weights[valid] * site_cvs[valid]) / sum(weights[valid])

  pe <- cv_single / cv_portfolio
  return(pe)
}


#' Loreau & de Mazancourt (2008) synchrony index
#' phi = var(sum_j X_j) / (sum_j SD(X_j))^2
#' Only uses sites with variance > 0 in the window.
compute_synchrony <- function(mat) {
  # Remove sites with zero variance (all same value or all zero)
  site_sds <- apply(mat, 2, sd, na.rm = TRUE)
  active   <- which(site_sds > 0)

  if (length(active) < 2) return(NA_real_)

  mat_active <- mat[, active, drop = FALSE]
  var_sum    <- var(rowSums(mat_active, na.rm = TRUE))
  sum_sd     <- sum(apply(mat_active, 2, sd, na.rm = TRUE))

  phi <- var_sum / (sum_sd^2)
  return(phi)
}


#' Variance Ratio: var(sum) / sum(var)
compute_vr <- function(mat) {
  site_vars <- apply(mat, 2, var, na.rm = TRUE)
  active    <- which(site_vars > 0)

  if (length(active) < 2) return(NA_real_)

  mat_active <- mat[, active, drop = FALSE]
  var_sum    <- var(rowSums(mat_active, na.rm = TRUE))
  sum_var    <- sum(apply(mat_active, 2, var, na.rm = TRUE))

  vr <- var_sum / sum_var
  return(vr)
}


## =========================================================================
##  7. COMPUTE ROLLING WINDOW METRICS
## =========================================================================

# Number of windows
n_windows <- n_years - window_size + 1

rolling_results <- tibble(
  window_start = integer(n_windows),
  window_end   = integer(n_windows),
  window_mid   = numeric(n_windows),
  pe           = numeric(n_windows),
  synchrony    = numeric(n_windows),
  vr           = numeric(n_windows),
  n_active     = integer(n_windows)
)

for (w in 1:n_windows) {
  yr_start <- years[w]
  yr_end   <- years[w + window_size - 1]
  yr_mid   <- (yr_start + yr_end) / 2

  # Extract window
  idx <- which(years >= yr_start & years <= yr_end)
  window_mat <- spawn_mat[idx, , drop = FALSE]

  # Count active sites in this window (at least 1 non-zero observation)
  n_active <- sum(colSums(window_mat > 0, na.rm = TRUE) > 0)

  rolling_results$window_start[w] <- yr_start
  rolling_results$window_end[w]   <- yr_end
  rolling_results$window_mid[w]   <- yr_mid
  rolling_results$pe[w]           <- compute_pe(window_mat)
  rolling_results$synchrony[w]    <- compute_synchrony(window_mat)
  rolling_results$vr[w]           <- compute_vr(window_mat)
  rolling_results$n_active[w]     <- n_active
}

cat("\nRolling window summary (", window_size, "-year windows):\n", sep = "")
cat("  Windows computed: ", n_windows, "\n")
cat("  PE range:         ", round(range(rolling_results$pe, na.rm = TRUE), 2), "\n")
cat("  Synchrony range:  ", round(range(rolling_results$synchrony, na.rm = TRUE), 3), "\n")
cat("  VR range:         ", round(range(rolling_results$vr, na.rm = TRUE), 2), "\n")


## =========================================================================
##  8. PLOT 4 — PORTFOLIO EFFECT OVER TIME
## =========================================================================

p_pe <- ggplot(rolling_results, aes(x = window_mid, y = pe)) +
  geom_line(linewidth = 0.7, colour = "#D55E00") +
  geom_point(size = 1, colour = "#D55E00") +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey50") +
  annotate("text", x = min(years) + 2, y = 1.05,
           label = "PE = 1 (no portfolio benefit)",
           hjust = 0, size = 2.8, colour = "grey50") +
  scale_x_continuous(breaks = seq(1950, 2025, by = 10)) +
  labs(x = paste0("Centre of ", window_size, "-year window"),
       y = "Portfolio Effect (CV_single / CV_portfolio)",
       title = "Portfolio effect over time (10-year rolling windows)")

p_pe <- add_key_events(p_pe) +
  theme(panel.grid.minor = element_blank())

ggsave(file.path(fig_dir, "portfolio_effect.pdf"),
       p_pe, width = 170, height = 100, units = "mm", dpi = 300)
ggsave(file.path(fig_dir, "portfolio_effect.png"),
       p_pe, width = 170, height = 100, units = "mm", dpi = 300)

cat("Plot 4 saved: portfolio_effect\n")


## =========================================================================
##  9. PLOT 5 — SYNCHRONY OVER TIME
## =========================================================================

p_sync <- ggplot(rolling_results, aes(x = window_mid, y = synchrony)) +
  geom_line(linewidth = 0.7, colour = "#CC79A7") +
  geom_point(size = 1, colour = "#CC79A7") +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey50") +
  geom_hline(yintercept = 1 / n_sites, linetype = "dotted", colour = "grey50") +
  annotate("text", x = max(years) - 3, y = 1,
           label = "Perfect synchrony", vjust = -0.5,
           hjust = 1, size = 2.8, colour = "grey50") +
  annotate("text", x = max(years) - 3, y = 1 / n_sites,
           label = paste0("Max asynchrony (1/", n_sites, ")"),
           vjust = 1.5, hjust = 1, size = 2.8, colour = "grey50") +
  scale_x_continuous(breaks = seq(1950, 2025, by = 10)) +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = paste0("Centre of ", window_size, "-year window"),
       y = expression(paste("Synchrony  ", phi,
                            " (Loreau & de Mazancourt 2008)")),
       title = "Subpopulation synchrony over time (10-year rolling windows)")

p_sync <- add_key_events(p_sync) +
  theme(panel.grid.minor = element_blank())

ggsave(file.path(fig_dir, "synchrony.pdf"),
       p_sync, width = 170, height = 100, units = "mm", dpi = 300)
ggsave(file.path(fig_dir, "synchrony.png"),
       p_sync, width = 170, height = 100, units = "mm", dpi = 300)

cat("Plot 5 saved: synchrony\n")


## =========================================================================
##  10. PLOT 6 — VARIANCE RATIO OVER TIME
## =========================================================================

p_vr <- ggplot(rolling_results, aes(x = window_mid, y = vr)) +
  geom_line(linewidth = 0.7, colour = "#56B4E9") +
  geom_point(size = 1, colour = "#56B4E9") +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey50") +
  annotate("text", x = min(years) + 2, y = 1.05,
           label = "VR = 1 (independent fluctuations)",
           hjust = 0, size = 2.8, colour = "grey50") +
  scale_x_continuous(breaks = seq(1950, 2025, by = 10)) +
  labs(x = paste0("Centre of ", window_size, "-year window"),
       y = "Variance Ratio  var(sum) / sum(var)",
       title = "Variance ratio over time (10-year rolling windows)")

p_vr <- add_key_events(p_vr) +
  theme(panel.grid.minor = element_blank())

ggsave(file.path(fig_dir, "variance_ratio.pdf"),
       p_vr, width = 170, height = 100, units = "mm", dpi = 300)
ggsave(file.path(fig_dir, "variance_ratio.png"),
       p_vr, width = 170, height = 100, units = "mm", dpi = 300)

cat("Plot 6 saved: variance_ratio\n")


## =========================================================================
##  11. COMBINED SUMMARY PLOT
## =========================================================================

# Combine PE, synchrony, VR, occupancy, evenness into one multi-panel figure
rolling_long <- rolling_results %>%
  select(window_mid, pe, synchrony, vr) %>%
  pivot_longer(cols = c(pe, synchrony, vr),
               names_to = "metric", values_to = "value") %>%
  mutate(metric = factor(metric,
                         levels = c("pe", "synchrony", "vr"),
                         labels = c("Portfolio Effect (CV ratio)",
                                    "Synchrony (phi)",
                                    "Variance Ratio")))

p_combined <- ggplot(rolling_long, aes(x = window_mid, y = value)) +
  geom_line(aes(colour = metric), linewidth = 0.6, show.legend = FALSE) +
  geom_point(aes(colour = metric), size = 0.8, show.legend = FALSE) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey60",
             linewidth = 0.3) +
  facet_wrap(~ metric, ncol = 1, scales = "free_y") +
  scale_colour_manual(values = c("#D55E00", "#CC79A7", "#56B4E9")) +
  geom_vline(xintercept = 2005, linetype = "dashed",
             colour = "grey40", linewidth = 0.3) +
  geom_vline(xintercept = 2014, linetype = "dotted",
             colour = "firebrick", linewidth = 0.3) +
  geom_vline(xintercept = 2016, linetype = "dotted",
             colour = "firebrick", linewidth = 0.3) +
  annotate("rect", xmin = 2014, xmax = 2016,
           ymin = -Inf, ymax = Inf,
           fill = "firebrick", alpha = 0.06) +
  scale_x_continuous(breaks = seq(1950, 2025, by = 10)) +
  labs(x = paste0("Centre of ", window_size, "-year window"),
       y = "Metric value",
       title = "Portfolio metrics over time (10-year rolling windows)") +
  theme(
    panel.grid.minor = element_blank(),
    strip.text       = element_text(face = "bold", size = 9)
  )

ggsave(file.path(fig_dir, "portfolio_metrics_combined.pdf"),
       p_combined, width = 170, height = 180, units = "mm", dpi = 300)
ggsave(file.path(fig_dir, "portfolio_metrics_combined.png"),
       p_combined, width = 170, height = 180, units = "mm", dpi = 300)

cat("Plot 7 saved: portfolio_metrics_combined\n")


## =========================================================================
##  12. SAVE ALL COMPUTED METRICS TO CSV
## =========================================================================

# A. Rolling window metrics
write_csv(rolling_results,
          file.path(proc_dir, "portfolio_metrics_rolling.csv"))

# B. Annual metrics (occupancy, evenness)
annual_metrics <- occupancy %>%
  left_join(evenness, by = "year")

write_csv(annual_metrics,
          file.path(proc_dir, "portfolio_metrics_annual.csv"))

# C. Combined long-form CSV for convenience
# (merge rolling and annual by closest year)
portfolio_all <- rolling_results %>%
  rename(year = window_mid) %>%
  left_join(
    annual_metrics %>% mutate(year = as.numeric(year)),
    by = "year",
    suffix = c("_rolling", "_annual")
  )

write_csv(portfolio_all,
          file.path(proc_dir, "portfolio_metrics.csv"))

cat("\nMetrics saved to Data/processed/:\n")
cat("  portfolio_metrics_rolling.csv  (rolling window PE, synchrony, VR)\n")
cat("  portfolio_metrics_annual.csv   (annual occupancy, Shannon, Simpson)\n")
cat("  portfolio_metrics.csv          (combined)\n")


## =========================================================================
##  13. DIAGNOSTIC SUMMARY
## =========================================================================

cat("\n")
cat("===================================================\n")
cat("  PORTFOLIO ANALYSIS SUMMARY\n")
cat("===================================================\n")
cat("  Data: Observed spawn index (tonnes) (raw, not model estimates)\n")
cat("  Sections: ", n_sites, " (same as state-space model)\n")
cat("  Years: ", min(years), "-", max(years), "\n")
cat("  Rolling window: ", window_size, " years\n\n")

cat("  --- Full-period summary ---\n")
# Full-period PE
total <- rowSums(spawn_mat, na.rm = TRUE)
cv_arch <- sd(total) / mean(total)
site_means <- colMeans(spawn_mat, na.rm = TRUE)
site_sds   <- apply(spawn_mat, 2, sd, na.rm = TRUE)
site_cvs   <- ifelse(site_means > 0, site_sds / site_means, NA)
cat("  Archipelago CV:       ", round(cv_arch, 3), "\n")
cat("  Mean subpop CV:       ", round(mean(site_cvs, na.rm = TRUE), 3), "\n")
cat("  Full-period PE:       ", round(compute_pe(spawn_mat), 3), "\n")
cat("  Full-period synchrony:", round(compute_synchrony(spawn_mat), 3), "\n")
cat("  Full-period VR:       ", round(compute_vr(spawn_mat), 3), "\n\n")

cat("  --- Occupancy ---\n")
cat("  Min occupied sections:", min(occupancy$n_occupied), "\n")
cat("  Max occupied sections:", max(occupancy$n_occupied), "\n")
cat("  Mean occupied:        ", round(mean(occupancy$n_occupied), 1), "\n")
cat("  Years with all 11:   ",
    sum(occupancy$n_occupied == n_sites), "\n\n")

cat("  --- Evenness ---\n")
cat("  Shannon H range:     ",
    round(range(evenness$shannon_H, na.rm = TRUE), 2), "\n")
cat("  Simpson D range:     ",
    round(range(evenness$simpson_D, na.rm = TRUE), 2), "\n")
cat("===================================================\n")
