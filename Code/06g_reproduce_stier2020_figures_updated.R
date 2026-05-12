# ============================================================================
# 06g_reproduce_stier2020_figures_updated.R
#
# Reproduce the six main figures from Stier et al. 2020 using the current
# Haida Gwaii herring time series through 2025 and the most current
# Stier-aligned baseline available locally.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(patchwork)
library(scales)
library(maps)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
raw_dir <- file.path(proj_dir, "Data", "raw")
fig_dir <- file.path(proj_dir, "Output", "figures", "stier2020_updated")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

source(file.path(proj_dir, "R", "00_setup.R"))

load(file.path(data_dir, "jags_model_inputs_v2.RData"))

fit_candidates <- tibble(
  model = c("m1_stier_11", "m1_stier_obs_hier"),
  path = file.path(data_dir, c("m1_stier_11_fit.rds", "m1_stier_obs_hier_fit.rds"))
)

fit_row <- fit_candidates %>% filter(file.exists(path)) %>% slice(1)
if (nrow(fit_row) == 0) {
  stop("No Stier-aligned fit artifact found.")
}

model_name <- fit_row$model
fit <- readRDS(fit_row$path)

years <- jags_data$years
site_names <- jags_data$site_names
n_years <- length(years)
n_sites <- length(site_names)
q_idx_stier <- if_else(years <= 1987, 1L, 2L)

focal_drop <- c("Tasu Sound & Gowgaia Bay", "Naden Harbour")
focal_idx <- which(!site_names %in% focal_drop)
focal_sites <- site_names[focal_idx]

message("Using ", model_name, " for updated Stier 2020 figure reproduction.")

post <- rstan::extract(
  fit,
  pars = c("X", "Z", "delta_raw", "Umu", "pdocoef", "sigma_proc", "log_q", "Pc_logit")
)
n_draws <- length(post$Umu)

X_med <- apply(post$X, c(2, 3), median)
Z_med <- apply(post$Z, c(2, 3), median)
delta_proc <- sweep(post$delta_raw, 1, post$sigma_proc, "*")
delta_med <- apply(delta_proc, c(2, 3), median)

save_both <- function(plot, stem, width = 220, height = 160) {
  pdf_path <- file.path(fig_dir, paste0(stem, ".pdf"))
  png_path <- file.path(fig_dir, paste0(stem, ".png"))
  ggsave(pdf_path, plot, width = width, height = height, units = "mm", device = cairo_pdf)
  ggsave(png_path, plot, width = width, height = height, units = "mm", dpi = 300)
  invisible(c(pdf_path, png_path))
}

theme_stier <- function(base_size = 9) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold"),
      legend.position = "bottom",
      legend.title = element_blank()
    )
}

section_cols <- c(
  "Port Louis" = "#0072B2",
  "Rennell Sound" = "#E69F00",
  "Englefield Bay" = "#009E73",
  "Louscoone Inlet" = "#D55E00",
  "Juan Perez Sound" = "#CC79A7",
  "Skidegate Inlet" = "#56B4E9",
  "Cumshewa Inlet" = "#F0E442",
  "Laskeek Bay" = "#999999",
  "Skincuttle Inlet" = "#000000"
)

summarise_draws <- function(x, probs = c(0.025, 0.05, 0.10, 0.50, 0.90, 0.95, 0.975)) {
  qs <- quantile(x, probs = probs, na.rm = TRUE, names = FALSE)
  tibble(
    lo95 = qs[1],
    lo90 = qs[2],
    lo80 = qs[3],
    median = qs[4],
    hi80 = qs[5],
    hi90 = qs[6],
    hi95 = qs[7]
  )
}

# ============================================================================
# Figure 1: spatio-temporal raw spawn index
# ============================================================================

keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
focal_six <- c(
  "Louscoone Inlet", "Juan Perez Sound", "Rennell Sound",
  "Skidegate Inlet", "Skincuttle Inlet", "Englefield Bay"
)

spawn_all <- read_csv(
  file.path(data_dir, "HG_Spawn_Survey_1951_2025_all_sections.csv"),
  show_col_types = FALSE
) %>%
  filter(section %in% keep_sections) %>%
  mutate(
    section_name = factor(section_name, levels = site_names),
    positive_spawn = spawn_index_tonnes > 0
  )

arch_spawn <- spawn_all %>%
  group_by(year) %>%
  summarise(total_spawn = sum(spawn_index_tonnes, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    long_median = median(total_spawn[total_spawn > 0], na.rm = TRUE),
    above_median = total_spawn >= long_median
  )

dfo_raw <- read_csv(
  file.path(raw_dir, "dfo-spawn", "Pacific_herring_spawn_index_data_2025_EN.csv"),
  show_col_types = FALSE
) %>%
  mutate(
    dfo_section = str_pad(as.character(Section), width = 3, pad = "0"),
    SHI = replace_na(Surface, 0) + replace_na(Macrocystis, 0) + replace_na(Understory, 0)
  )

section_lookup <- tibble(
  dfo_section = sprintf("%03d", c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)),
  section = keep_sections,
  section_name = site_names
)

map_points <- dfo_raw %>%
  inner_join(section_lookup, by = "dfo_section") %>%
  filter(is.finite(Longitude), is.finite(Latitude), SHI > 0)

centroids <- map_points %>%
  group_by(section, section_name) %>%
  summarise(
    lon = mean(Longitude, na.rm = TRUE),
    lat = mean(Latitude, na.rm = TRUE),
    .groups = "drop"
  )

canada_map <- map_data("world", region = "Canada")

p1a <- ggplot(arch_spawn, aes(x = year, y = total_spawn)) +
  geom_hline(aes(yintercept = long_median), colour = "grey55", linewidth = 0.35) +
  geom_line(colour = "grey35", linewidth = 0.45) +
  geom_point(aes(fill = above_median), shape = 21, size = 1.8, colour = "grey25") +
  scale_fill_manual(values = c(`TRUE` = "black", `FALSE` = "grey75")) +
  scale_y_continuous(labels = label_comma()) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = NULL,
    y = "Archipelago spawn index",
    title = "A. Archipelago cumulative spawn index",
    subtitle = "DFO tonnes-scale spawn index, 1951-2025; horizontal line is positive-year median."
  ) +
  theme_stier(9) +
  theme(legend.position = "none")

p1b <- ggplot() +
  geom_polygon(
    data = canada_map,
    aes(x = long, y = lat, group = group),
    fill = "grey92",
    colour = "white",
    linewidth = 0.15
  ) +
  geom_point(
    data = map_points,
    aes(x = Longitude, y = Latitude),
    colour = "#D55E00",
    alpha = 0.25,
    size = 0.45
  ) +
  geom_label(
    data = centroids,
    aes(x = lon, y = lat, label = section),
    size = 2.2,
    linewidth = 0.12,
    fill = "white"
  ) +
  coord_quickmap(xlim = c(-134.2, -130.6), ylim = c(51.5, 54.5), expand = FALSE) +
  labs(x = NULL, y = NULL, title = "B. Spawn-record locations and section IDs") +
  theme_void(base_size = 9) +
  theme(plot.title = element_text(face = "bold"))

p1_focal <- spawn_all %>%
  filter(as.character(section_name) %in% focal_six) %>%
  mutate(section_name = factor(as.character(section_name), levels = focal_six)) %>%
  ggplot(aes(x = year, y = na_if(spawn_index_tonnes, 0))) +
  geom_line(colour = "#0072B2", linewidth = 0.35, na.rm = TRUE) +
  geom_point(shape = 21, fill = "white", colour = "#0072B2", size = 0.8, na.rm = TRUE) +
  facet_wrap(vars(section_name), scales = "free_y", ncol = 3) +
  scale_y_continuous(labels = label_comma()) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 20)) +
  labs(
    x = "Year",
    y = "Spawn index",
    title = "C-H. Six focal section time series"
  ) +
  theme_stier(8) +
  theme(strip.text = element_text(size = 7.5), legend.position = "none")

p_fig1 <- (p1a | p1b) / p1_focal +
  plot_layout(heights = c(0.9, 1.25)) +
  plot_annotation(
    title = "Updated Stier Fig. 1: Spatio-temporal variation in Haida Gwaii herring spawn",
    subtitle = paste0("Updated with DFO 2025 release; fit context = ", model_name, ".")
  )

save_both(p_fig1, "fig1_spatiotemporal_spawn_updated", width = 230, height = 210)

# ============================================================================
# Figure 2: scaled biomass and cross-correlations
# ============================================================================

x_scaled <- scale(X_med[, focal_idx, drop = FALSE])
colnames(x_scaled) <- focal_sites

x_scaled_long <- as_tibble(x_scaled, .name_repair = "minimal") %>%
  mutate(year = years) %>%
  pivot_longer(-year, names_to = "section_name", values_to = "scaled_log_biomass")

arch_scaled <- x_scaled_long %>%
  group_by(year) %>%
  summarise(
    mean_scaled = mean(scaled_log_biomass, na.rm = TRUE),
    min_scaled = min(scaled_log_biomass, na.rm = TRUE),
    max_scaled = max(scaled_log_biomass, na.rm = TRUE),
    .groups = "drop"
  )

cor_mat <- cor(X_med[, focal_idx, drop = FALSE], method = "spearman")
colnames(cor_mat) <- focal_sites
rownames(cor_mat) <- focal_sites
cor_vals <- cor_mat[upper.tri(cor_mat)]

cor_df <- as.data.frame(as.table(cor_mat)) %>%
  as_tibble() %>%
  rename(site_a = Var1, site_b = Var2, correlation = Freq) %>%
  mutate(
    site_a = factor(site_a, levels = focal_sites),
    site_b = factor(site_b, levels = rev(focal_sites)),
    show = as.integer(site_a) < (length(focal_sites) - as.integer(site_b) + 1),
    correlation = if_else(show, correlation, NA_real_)
  )

p2a <- ggplot() +
  geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.3) +
  geom_line(
    data = x_scaled_long,
    aes(x = year, y = scaled_log_biomass, colour = section_name, linetype = section_name),
    linewidth = 0.45,
    alpha = 0.82
  ) +
  geom_line(
    data = arch_scaled,
    aes(x = year, y = mean_scaled),
    colour = "grey25",
    linewidth = 1.25,
    alpha = 0.8
  ) +
  scale_colour_manual(values = section_cols[focal_sites]) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = NULL,
    y = "Scaled estimated log biomass",
    title = "A. Scaled biomass trajectories"
  ) +
  theme_stier(9) +
  guides(colour = guide_legend(ncol = 3), linetype = guide_legend(ncol = 3))

p2b <- tibble(correlation = cor_vals) %>%
  ggplot(aes(x = correlation)) +
  geom_histogram(binwidth = 0.1, boundary = 0, fill = "grey75", colour = "grey25") +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey35") +
  scale_x_continuous(limits = c(-1, 1)) +
  labs(
    x = "Pairwise Spearman correlation",
    y = "Frequency",
    title = "B. Similarity distribution"
  ) +
  theme_stier(8)

p2c <- ggplot(cor_df, aes(x = site_a, y = site_b, fill = correlation)) +
  geom_tile(colour = "white", linewidth = 0.3) +
  scale_fill_gradient2(low = "#0072B2", mid = "white", high = "#D55E00", limits = c(-1, 1), na.value = "grey95") +
  labs(x = NULL, y = NULL, title = "C. Pairwise correlation matrix") +
  theme_stier(8) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "right")

p_fig2 <- p2a / (p2b | p2c) +
  plot_layout(heights = c(1.1, 1)) +
  plot_annotation(
    title = "Updated Stier Fig. 2: Scaled biomass dynamics and pairwise similarity",
    subtitle = "Focal 9 sections; Tasu and Naden retained in the model but excluded to match Stier focal reporting."
  )

save_both(p_fig2, "fig2_scaled_biomass_correlation_updated", width = 230, height = 220)

# ============================================================================
# Figure 3: intrinsic growth and PDO effects
# ============================================================================

umu_summary <- summarise_draws(post$Umu)

pdo_effect <- sapply(seq_along(years), function(t) post$pdocoef * jags_data$pdo[t])
pdo_effect_df <- as_tibble(
  t(apply(pdo_effect, 2, quantile, probs = c(0.025, 0.25, 0.5, 0.75, 0.975))),
  .name_repair = "minimal"
) %>%
  set_names(c("lo95", "q25", "median", "q75", "hi95")) %>%
  mutate(
    year = years,
    pdo = jags_data$pdo,
    regime = if_else(median > 0, "positive PDO effect", "negative PDO effect")
  )

p3a <- ggplot(umu_summary, aes(x = "Intrinsic growth", y = median, ymin = lo95, ymax = hi95)) +
  geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.35) +
  geom_pointrange(linewidth = 0.55) +
  scale_y_continuous(limits = c(min(-0.12, umu_summary$lo95), max(0.12, umu_summary$hi95))) +
  labs(x = NULL, y = "Population growth rate", title = "A. Archipelago average growth") +
  theme_stier(9) +
  theme(axis.text.x = element_blank(), legend.position = "none")

p3b <- ggplot(pdo_effect_df, aes(x = "PDO effect", y = median)) +
  geom_boxplot(width = 0.28, outlier.shape = NA, fill = "grey86", colour = "grey35") +
  geom_jitter(aes(colour = regime), width = 0.09, height = 0, size = 1.35, alpha = 0.85) +
  geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.35) +
  scale_colour_manual(values = c("negative PDO effect" = "#0072B2", "positive PDO effect" = "#D55E00")) +
  labs(x = NULL, y = expression(pi[PDO] * PDO[t]), title = "B. Annual PDO contribution") +
  theme_stier(9) +
  theme(axis.text.x = element_blank())

p3c <- ggplot(pdo_effect_df, aes(x = year, y = median)) +
  geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.35) +
  geom_ribbon(aes(ymin = lo95, ymax = hi95), fill = "grey70", alpha = 0.18) +
  geom_line(linewidth = 0.55, colour = "grey30") +
  geom_point(aes(colour = regime), size = 1.2) +
  scale_colour_manual(values = c("negative PDO effect" = "#0072B2", "positive PDO effect" = "#D55E00")) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(x = "Year", y = expression(pi[PDO] * PDO[t]), title = "C. PDO effect through time") +
  theme_stier(9)

p_fig3 <- (p3a | p3b) / p3c +
  plot_annotation(
    title = "Updated Stier Fig. 3: Average population growth and PDO effect",
    subtitle = "Posterior summaries from the promoted Stier-aligned baseline."
  )

save_both(p_fig3, "fig3_growth_pdo_updated", width = 220, height = 180)

# ============================================================================
# Figure 4: fishing impacts
# ============================================================================

Pc_draws <- array(0, dim = c(n_draws, n_years, n_sites))
for (k in seq_len(jags_data$nIndex)) {
  Pc_draws[, jags_data$INDEX[k, 1], jags_data$INDEX[k, 2]] <- plogis(post$Pc_logit[, k])
}

catch_positive <- jags_data$ctab > 0

pc_mean_for_sites <- function(t, idx) {
  vals <- Pc_draws[, t, idx, drop = FALSE]
  if (length(idx) == 1L) {
    return(as.numeric(vals[, 1, 1]))
  }
  rowMeans(matrix(vals[, 1, ], nrow = n_draws))
}

fishing_year <- map_dfr(seq_len(n_years), function(t) {
  fished_focal <- focal_idx[catch_positive[t, focal_idx]]
  arch_draws <- pc_mean_for_sites(t, focal_idx)
  subpop_draws <- if (length(fished_focal) == 0) {
    rep(0, n_draws)
  } else {
    pc_mean_for_sites(t, fished_focal)
  }

  bind_rows(
    summarise_draws(arch_draws) %>% mutate(year = years[t], scale = "Archipelago-wide"),
    summarise_draws(subpop_draws) %>% mutate(year = years[t], scale = "Fished sections only")
  ) %>%
    mutate(
      prop_focal_fished = mean(catch_positive[t, focal_idx]),
      n_focal_fished = length(fished_focal)
    )
})

p4a <- fishing_year %>%
  distinct(year, prop_focal_fished, n_focal_fished) %>%
  ggplot(aes(x = year, y = prop_focal_fished)) +
  geom_col(fill = "grey70", colour = "grey45", linewidth = 0.15) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = NULL,
    y = "Focal sections fished",
    title = "A. Spatial coverage of fishing"
  ) +
  theme_stier(9)

p4b <- ggplot(fishing_year, aes(x = year, y = median, colour = scale, fill = scale, linetype = scale)) +
  geom_ribbon(aes(ymin = lo95, ymax = hi95), alpha = 0.13, colour = NA) +
  geom_hline(yintercept = 0.20, colour = "grey35", linetype = "dashed", linewidth = 0.35) +
  geom_line(linewidth = 0.7) +
  scale_colour_manual(values = c("Archipelago-wide" = "#0072B2", "Fished sections only" = "#D55E00")) +
  scale_fill_manual(values = c("Archipelago-wide" = "#0072B2", "Fished sections only" = "#D55E00")) +
  scale_linetype_manual(values = c("Archipelago-wide" = "solid", "Fished sections only" = "dashed")) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, max(0.7, fishing_year$hi95, na.rm = TRUE))) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = "Year",
    y = "Proportion of biomass caught",
    title = "B. Archipelago vs local fishing impact",
    subtitle = "Dashed horizontal line is 20%."
  ) +
  theme_stier(9)

p_fig4 <- p4a / p4b +
  plot_layout(heights = c(0.75, 1.2)) +
  plot_annotation(
    title = "Updated Stier Fig. 4: Fishing impacts through time",
    subtitle = "Focal 9 sections; catch includes updated SOK correction and 2025 zero extension."
  )

save_both(p_fig4, "fig4_fishing_impacts_updated", width = 220, height = 170)

# ============================================================================
# Figure 5: realized population growth by section, historical vs post-1994
# ============================================================================

linear_growth <- delta_proc
for (t in seq_len(n_years - 1)) {
  transition_effect <- post$Umu + post$pdocoef * jags_data$pdo[t]
  linear_growth[, t, ] <- sweep(linear_growth[, t, ], 1, transition_effect, "+")
}
realized_growth <- exp(linear_growth)
transition_years <- years[-1]

period_defs <- tibble(
  period = c("1952-1994 historical", "1995-2025 post-1994"),
  lo = c(1952, 1995),
  hi = c(1994, 2025)
)

growth_period <- map_dfr(focal_idx, function(j) {
  map_dfr(seq_len(nrow(period_defs)), function(i) {
    idx <- which(transition_years >= period_defs$lo[i] & transition_years <= period_defs$hi[i])
    draw_means <- apply(realized_growth[, idx, j, drop = FALSE], 1, mean, na.rm = TRUE)
    summarise_draws(draw_means) %>%
      mutate(
        site = j,
        section_name = site_names[j],
        period = period_defs$period[i],
        .before = 1
      )
  })
}) %>%
  mutate(
    period = factor(period, levels = period_defs$period),
    section_name = factor(section_name, levels = focal_sites)
  )

p_fig5 <- ggplot(growth_period, aes(x = period, y = median, group = section_name, colour = section_name, linetype = section_name)) +
  geom_hline(yintercept = 1, colour = "grey60", linewidth = 0.35) +
  geom_line(linewidth = 0.65) +
  geom_point(size = 1.7) +
  geom_errorbar(aes(ymin = lo90, ymax = hi90), width = 0.06, linewidth = 0.35, alpha = 0.65) +
  scale_colour_manual(values = section_cols[focal_sites]) +
  labs(
    x = NULL,
    y = expression("Realized growth " * exp(U + pi[PDO] * PDO[t] + delta[s*t])),
    title = "Updated Stier Fig. 5: Section-specific realized growth",
    subtitle = "Historical period updated to 1952-1994; post-closure comparison extended to 2025."
  ) +
  theme_stier(9) +
  guides(colour = guide_legend(ncol = 3), linetype = guide_legend(ncol = 3))

save_both(p_fig5, "fig5_realized_growth_updated", width = 210, height = 150)

# ============================================================================
# Figure 6: process variability and portfolio metrics
# ============================================================================

delta_long <- as_tibble(delta_med[, focal_idx, drop = FALSE], .name_repair = "minimal") %>%
  set_names(focal_sites) %>%
  mutate(year = transition_years) %>%
  pivot_longer(-year, names_to = "section_name", values_to = "delta")

delta_mean <- delta_long %>%
  group_by(year) %>%
  summarise(mean_delta = mean(delta, na.rm = TRUE), .groups = "drop")

lm_synchrony <- function(mat) {
  mat <- as.matrix(mat)
  valid_cols <- apply(mat, 2, function(x) sum(is.finite(x) & x > 0) >= 3)
  mat <- mat[, valid_cols, drop = FALSE]
  if (ncol(mat) < 2) return(NA_real_)
  total <- rowSums(mat, na.rm = TRUE)
  denom <- sum(apply(mat, 2, sd, na.rm = TRUE))^2
  if (!is.finite(denom) || denom <= 0) return(NA_real_)
  var(total, na.rm = TRUE) / denom
}

pairwise_spearman_mean <- function(mat) {
  mat <- as.matrix(mat)
  if (ncol(mat) < 2) return(NA_real_)
  pairs <- combn(seq_len(ncol(mat)), 2)
  vals <- apply(pairs, 2, function(idx) {
    x <- mat[, idx[1]]
    y <- mat[, idx[2]]
    ok <- is.finite(x) & is.finite(y)
    if (sum(ok) < 4) return(NA_real_)
    cor(x[ok], y[ok], method = "spearman")
  })
  mean(vals, na.rm = TRUE)
}

biomass_focal <- exp(X_med[, focal_idx, drop = FALSE])
growth_med <- apply(realized_growth[, , focal_idx, drop = FALSE], c(2, 3), median)

window <- 11L
portfolio_metrics <- map_dfr(seq_len(nrow(biomass_focal) - window + 1L), function(i) {
  idx_b <- i:(i + window - 1L)
  yrs <- years[idx_b]
  b <- biomass_focal[idx_b, , drop = FALSE]

  sub_cv <- apply(b, 2, function(x) sd(x, na.rm = TRUE) / mean(x, na.rm = TRUE))
  arch_cv <- sd(rowSums(b, na.rm = TRUE), na.rm = TRUE) / mean(rowSums(b, na.rm = TRUE), na.rm = TRUE)

  idx_g <- which(transition_years >= min(yrs) & transition_years <= max(yrs))
  g <- growth_med[idx_g, , drop = FALSE]

  tibble(
    window_start = min(yrs),
    window_end = max(yrs),
    window_mid = mean(yrs),
    growth_correlation = pairwise_spearman_mean(g),
    asynchrony = 1 - lm_synchrony(b),
    portfolio_effect = mean(sub_cv, na.rm = TRUE) / arch_cv
  )
})

p6a <- ggplot() +
  geom_hline(yintercept = 0, colour = "grey65", linewidth = 0.35) +
  geom_line(
    data = delta_long,
    aes(x = year, y = delta, colour = section_name, linetype = section_name),
    linewidth = 0.35,
    alpha = 0.68
  ) +
  geom_line(data = delta_mean, aes(x = year, y = mean_delta), colour = "grey20", linewidth = 1.05) +
  scale_colour_manual(values = section_cols[focal_sites]) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(
    x = NULL,
    y = expression(delta),
    title = "A. Process variability"
  ) +
  theme_stier(8) +
  guides(colour = guide_legend(ncol = 3), linetype = guide_legend(ncol = 3))

p6b <- ggplot(portfolio_metrics, aes(x = window_mid, y = growth_correlation)) +
  geom_hline(yintercept = 0, colour = "grey65", linewidth = 0.35) +
  geom_line(colour = "#0072B2", linewidth = 0.75) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(x = "Window midpoint", y = "Mean pairwise correlation", title = "B. Realized-growth synchrony") +
  theme_stier(8)

p6c <- ggplot(portfolio_metrics, aes(x = window_mid, y = asynchrony)) +
  geom_line(colour = "#009E73", linewidth = 0.75) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "Window midpoint", y = "Asynchrony index", title = "C. Asynchrony") +
  theme_stier(8)

p6d <- ggplot(portfolio_metrics, aes(x = window_mid, y = portfolio_effect)) +
  geom_hline(yintercept = 1, colour = "grey65", linetype = "dashed", linewidth = 0.35) +
  geom_line(colour = "#D55E00", linewidth = 0.75) +
  scale_x_continuous(breaks = seq(1950, 2030, by = 10)) +
  labs(x = "Window midpoint", y = "Subpopulation CV / archipelago CV", title = "D. Portfolio effect") +
  theme_stier(8)

p_fig6 <- p6a / (p6b | p6c | p6d) +
  plot_layout(heights = c(1.15, 0.85)) +
  plot_annotation(
    title = "Updated Stier Fig. 6: Process variability, synchrony, and portfolio effect",
    subtitle = "Focal 9 sections, 11-year moving windows; process deviations use sigma_proc * delta_raw."
  )

save_both(p_fig6, "fig6_process_portfolio_updated", width = 245, height = 190)

# ============================================================================
# Diagnostics and index
# ============================================================================

write_csv(arch_spawn, file.path(diag_dir, "stier2020_updated_fig1_arch_spawn.csv"))
write_csv(
  tibble(pairwise_correlation = cor_vals),
  file.path(diag_dir, "stier2020_updated_fig2_pairwise_correlations.csv")
)
write_csv(pdo_effect_df, file.path(diag_dir, "stier2020_updated_fig3_pdo_effect.csv"))
write_csv(fishing_year, file.path(diag_dir, "stier2020_updated_fig4_fishing.csv"))
write_csv(growth_period, file.path(diag_dir, "stier2020_updated_fig5_growth_periods.csv"))
write_csv(portfolio_metrics, file.path(diag_dir, "stier2020_updated_fig6_portfolio_metrics.csv"))

figure_index <- c(
  "# Updated Stier et al. 2020 Figure Reproductions",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste0("Model artifact: `", model_name, "`."),
  "",
  "These figures reproduce the six main figures from Stier et al. 2020 with the current Haida Gwaii time series through 2025.",
  "",
  "## Figures",
  "",
  "- Fig. 1: `Output/figures/stier2020_updated/fig1_spatiotemporal_spawn_updated.pdf`",
  "- Fig. 2: `Output/figures/stier2020_updated/fig2_scaled_biomass_correlation_updated.pdf`",
  "- Fig. 3: `Output/figures/stier2020_updated/fig3_growth_pdo_updated.pdf`",
  "- Fig. 4: `Output/figures/stier2020_updated/fig4_fishing_impacts_updated.pdf`",
  "- Fig. 5: `Output/figures/stier2020_updated/fig5_realized_growth_updated.pdf`",
  "- Fig. 6: `Output/figures/stier2020_updated/fig6_process_portfolio_updated.pdf`",
  "",
  "## Important Updates Relative To The Original Paper",
  "",
  "- The raw spawn series uses the 2025 DFO tonnes-scale spawn-index release.",
  "- The fit-based panels use the promoted Stier-aligned `m1_stier_11` baseline when available.",
  "- Zero spawn records remain ambiguous and are not treated as confirmed biological absences in the fitted model.",
  "- Tasu and Naden are retained in the 11-section model but excluded from focal portfolio panels to match the original Stier focal-9 reporting.",
  "- Fishing calculations use the current catch matrix with spawn-on-kelp removed from adult catch and zero catch extended to 2025.",
  "",
  "## Source Figure Mapping",
  "",
  "- Original Fig. 1: raw spatial and temporal spawn index.",
  "- Original Fig. 2: scaled estimated biomass and pairwise cross-correlations.",
  "- Original Fig. 3: average population growth and PDO effect.",
  "- Original Fig. 4: spatial coverage and intensity of fishing.",
  "- Original Fig. 5: historical vs post-closure realized growth.",
  "- Original Fig. 6: process variability, synchrony, asynchrony, and portfolio effect."
)

writeLines(figure_index, file.path(diag_dir, "stier2020_updated_figure_index.md"))
cat(paste(figure_index, collapse = "\n"))
