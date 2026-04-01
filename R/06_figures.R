# ============================================================================
# 06_figures.R — Publication figures for herring metapopulation analysis
# stier-2027-herring-metapopulation
#
# Each function returns a ggplot object. The save_figure() helper writes
# to Output/figures/ with explicit ggsave dimensions.
#
# All figures use theme_pub() from 00_setup.R.
# Multi-panel layouts use patchwork with plot_layout(guides = "collect").
#
# Colour conventions:
#   - Subpopulations: Okabe-Ito palette (PAL$okabe_ito)
#   - Archipelago aggregate: grey50 with alpha
#   - Diverging: gradient2 with navy/coral endpoints
#   - CIs: light fill with alpha = 0.2
# ============================================================================

# ── Helper: save a figure to Output/figures/ ───────────────────────────────

#' Save a ggplot to Output/figures/ as PDF
#'
#' @param plot A ggplot object
#' @param filename Character, filename (e.g., "fig_spawn_index.pdf")
#' @param width Width in mm (default 170)
#' @param height Height in mm (default 120)
#' @param dpi Resolution (default 300)
#' @return Character path to saved file (for targets format = "file")
save_figure <- function(plot, filename, width = 170, height = 120, dpi = 300) {
  outpath <- here::here("Output", "figures", filename)
  dir.create(dirname(outpath), showWarnings = FALSE, recursive = TRUE)

  ggplot2::ggsave(
    outpath,
    plot   = plot,
    width  = width,
    height = height,
    units  = "mm",
    dpi    = dpi,
    device = grDevices::cairo_pdf
  )

  outpath
}


# ── Fig 1: Spawn index by site ─────────────────────────────────────────────

#' Multi-panel spawn index time series by section
#'
#' Faceted line plot of raw spawn habitat index (SHI) for each
#' subpopulation. Zeros are replaced with NA (no spawning observed).
#'
#' @param spawn_data Tibble from clean_spawn()$long with columns:
#'   year, section, section_name, spawn_index, log_shi
#' @param sections_drop Integer vector of sections to exclude.
#' @return ggplot object
fig_spawn_index <- function(
    spawn_data,
    sections_drop = c(4L, 11L)
) {

  plot_data <- spawn_data |>
    filter(
      !section %in% sections_drop,
      year >= 1950L
    )

  ggplot(plot_data, aes(x = year, y = spawn_index)) +
    geom_line(linewidth = 0.4, colour = PAL$navy) +
    geom_point(size = 0.8, shape = 21, fill = "white", colour = PAL$navy) +
    facet_wrap(~ section_name, scales = "free_y", ncol = 3) +
    scale_x_continuous(
      breaks = seq(1950, 2020, by = 20),
      limits = c(1950, NA)
    ) +
    scale_y_continuous(labels = scales::comma) +
    labs(
      x = "Year",
      y = "Spawn Habitat Index (SHI)"
    ) +
    theme_pub(base_size = 9) +
    theme(
      legend.position = "none",
      strip.text = element_text(size = rel(0.8))
    )
}


# ── Fig 2: Biomass time series (archipelago + subpopulations) ──────────────

#' Scaled estimated biomass (X) from the state-space model
#'
#' Shows individual subpopulation biomass trajectories (coloured) with the
#' archipelago mean (thick grey line) and credible interval ribbon.
#'
#' @param biomass_est Tibble from extract_posteriors()$biomass_estimates with
#'   columns: year, section_name, biomass_median, biomass_lower, biomass_upper,
#'   .width. Uses the .width == 0.9 rows for the 90% CI.
#' @param sections_drop Character vector of section names to exclude.
#' @return ggplot object
fig_biomass_timeseries <- function(
    biomass_est,
    sections_drop = c("Tasu Sound & Gowgaia Bay", "Naden Harbour")
) {

  # Use 90% CI rows and filter out sparse-data sites
  subpop <- biomass_est |>
    filter(
      .width == 0.9,
      !section_name %in% sections_drop
    ) |>
    group_by(section_name) |>
    mutate(biomass_scaled = scale(biomass_median)[, 1]) |>
    ungroup()

  # Archipelago aggregate
  arch <- subpop |>
    group_by(year) |>
    summarise(
      biomass_scaled = mean(biomass_scaled, na.rm = TRUE),
      biomass_min    = min(biomass_scaled, na.rm = TRUE),
      biomass_max    = max(biomass_scaled, na.rm = TRUE),
      .groups = "drop"
    )

  n_sites <- length(unique(subpop$section_name))
  pal <- PAL$okabe_ito[seq_len(min(n_sites, length(PAL$okabe_ito)))]

  ggplot() +
    geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.3) +
    geom_ribbon(
      data = arch,
      aes(x = year, ymin = biomass_min, ymax = biomass_max),
      fill = "grey80", alpha = 0.3
    ) +
    geom_line(
      data = subpop,
      aes(x = year, y = biomass_scaled, colour = section_name,
          linetype = section_name),
      linewidth = 0.5
    ) +
    geom_line(
      data = arch,
      aes(x = year, y = biomass_scaled),
      colour = "grey40", linewidth = 1.5, alpha = 0.7
    ) +
    scale_colour_manual(values = pal) +
    scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
    labs(
      x      = "Year",
      y      = "Scaled Estimated Biomass",
      colour = "Subpopulation",
      linetype = "Subpopulation"
    ) +
    theme_pub(base_size = 10) +
    theme(
      legend.position = "bottom",
      legend.title = element_text(size = rel(0.85))
    ) +
    guides(
      colour   = guide_legend(ncol = 3),
      linetype = guide_legend(ncol = 3)
    )
}


# ── Fig 3: Fishing rates — subpopulation vs. archipelago ───────────────────

#' Proportion biomass caught (Pc) at subpopulation vs. archipelago scale
#'
#' KEY FIGURE from Stier et al. 2020. Shows that archipelago-level fishing
#' pressure was buffered by spatial averaging, while individual subpopulations
#' experienced higher fishing rates.
#'
#' Two lines:
#'   - Solid: archipelago mean Pc (averaging across all sites including zeros)
#'   - Dashed: mean Pc across only sites where fishing occurred
#'
#' @param fishing_est Tibble from extract_posteriors()$fishing_estimates with
#'   columns: year, section_name, pc_median, .lower, .upper.
#' @return ggplot object
fig_fishing_rates <- function(fishing_est) {

  # Archipelago-level: mean across all sites (including zero-catch sites)
  arch <- fishing_est |>
    group_by(year) |>
    summarise(
      pc = mean(pc_median, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(scale = "Archipelago")

  # Subpopulation-level: mean across only fished sites
  subpop <- fishing_est |>
    filter(pc_median > 0) |>
    group_by(year) |>
    summarise(
      pc = mean(pc_median, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(scale = "Subpopulation (fished only)")

  fish_combined <- bind_rows(arch, subpop)

  ggplot(fish_combined, aes(x = year, y = pc,
                            colour = scale, linetype = scale)) +
    geom_line(linewidth = 0.7) +
    scale_colour_manual(
      values = c("Archipelago" = PAL$navy,
                 "Subpopulation (fished only)" = PAL$coral)
    ) +
    scale_linetype_manual(
      values = c("Archipelago" = "solid",
                 "Subpopulation (fished only)" = "dashed")
    ) +
    scale_y_continuous(
      limits = c(0, 1),
      breaks = seq(0, 1, by = 0.2),
      labels = scales::percent_format(accuracy = 1)
    ) +
    scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
    labs(
      x      = "Year",
      y      = "Proportion Biomass Caught",
      colour = NULL,
      linetype = NULL
    ) +
    theme_pub(base_size = 10) +
    theme(legend.position = "bottom")
}


# ── Fig 4: Moving-window synchrony ────────────────────────────────────────

#' Moving-window pairwise cross-correlation of subpopulation biomass
#'
#' Shows how spatial synchrony among subpopulations has changed over time.
#' Increasing synchrony = eroding portfolio, higher regional extinction risk.
#'
#' @param sync_metrics Tibble from compute_synchrony() with columns:
#'   window_start, window_mid, mean_pairwise_cor, sd_pairwise_cor
#' @return ggplot object
fig_synchrony <- function(sync_metrics) {

  ggplot(sync_metrics, aes(x = window_mid, y = mean_pairwise_cor)) +
    geom_ribbon(
      aes(ymin = mean_pairwise_cor - sd_pairwise_cor,
          ymax = mean_pairwise_cor + sd_pairwise_cor),
      fill = PAL$teal, alpha = 0.2
    ) +
    geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.3) +
    geom_line(colour = PAL$navy, linewidth = 0.7) +
    scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
    scale_y_continuous(limits = c(-0.5, 1)) +
    labs(
      x = "Year (midpoint of 10-year window)",
      y = "Mean Pairwise Spearman Correlation"
    ) +
    theme_pub(base_size = 10)
}


# ── Fig 5: Portfolio effect ────────────────────────────────────────────────

#' Portfolio effect (CV ratio and synchrony index) over time
#'
#' Two-panel figure:
#'   A) CV ratio (subpop / archipelago) — higher = stronger portfolio buffering
#'   B) Loreau & de Mazancourt synchrony — lower = more asynchronous (better)
#'
#' @param portfolio_metrics Tibble from compute_portfolio() with columns:
#'   window_start, window_mid, cv_ratio, synchrony_lm
#' @return ggplot object (patchwork)
fig_portfolio <- function(portfolio_metrics) {

  p_cv <- ggplot(portfolio_metrics, aes(x = window_mid, y = cv_ratio)) +
    geom_line(colour = PAL$navy, linewidth = 0.7) +
    geom_hline(yintercept = 1, colour = "grey70", linetype = "dashed",
               linewidth = 0.3) +
    scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
    labs(
      x = NULL,
      y = "CV Ratio\n(Subpopulation / Archipelago)"
    ) +
    theme_pub(base_size = 9) +
    theme(axis.text.x = element_blank(), axis.title.x = element_blank())

  p_sync <- ggplot(portfolio_metrics, aes(x = window_mid, y = synchrony_lm)) +
    geom_line(colour = PAL$coral, linewidth = 0.7) +
    scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
    scale_y_continuous(limits = c(0, 1)) +
    labs(
      x = "Year (midpoint of 10-year window)",
      y = "Synchrony Index\n(Loreau & de Mazancourt)"
    ) +
    theme_pub(base_size = 9)

  # NOTE: plot_layout(axes = "collect") requires patchwork >= 1.2.0.
  # Earlier versions will error. Check with packageVersion("patchwork").
  p_cv / p_sync +
    patchwork::plot_annotation(tag_levels = "A") +
    patchwork::plot_layout(axes = "collect")
}


# ── Fig 6: Predator effects ───────────────────────────────────────────────

#' Predator abundance time series for Haida Gwaii region
#'
#' Three-panel figure showing abundance trends for key herring predators:
#'   A) Humpback whale (North Pacific basin-wide, Cheeseman et al. 2024)
#'   B) Steller sea lion (Haida Gwaii haulout counts)
#'   C) Harbour seal (Haida Gwaii haul-out counts)
#'
#' When predator covariate posteriors are available from the model (v2),
#' this function can be extended to show posterior densities of covariate
#' effects.
#'
#' @param predators_clean Wide tibble from clean_predators() with columns:
#'   year, ssl_count, seal_count, whale_abundance.
#' @return ggplot object (patchwork)
fig_predator_effects <- function(predators_clean) {

  # Pivot to long format for faceted plotting
  pred_long <- predators_clean |>
    pivot_longer(
      cols      = c(ssl_count, seal_count, whale_abundance),
      names_to  = "species_var",
      values_to = "abundance"
    ) |>
    filter(!is.na(abundance)) |>
    mutate(
      species = case_match(
        species_var,
        "ssl_count"        ~ "Steller sea lion",
        "seal_count"       ~ "Harbour seal",
        "whale_abundance"  ~ "Humpback whale"
      ),
      species = factor(species, levels = c(
        "Humpback whale", "Steller sea lion", "Harbour seal"
      ))
    )

  # Define species-specific aesthetics
  species_colours <- c(
    "Humpback whale"   = PAL$navy,
    "Steller sea lion" = PAL$teal,
    "Harbour seal"     = PAL$coral
  )

  # Helper to build one panel
  make_panel <- function(sp, show_x = FALSE) {
    sp_data <- pred_long |> filter(species == sp)

    p <- ggplot(sp_data, aes(x = year, y = abundance)) +
      geom_line(colour = species_colours[[sp]], linewidth = 0.7) +
      geom_point(colour = species_colours[[sp]], size = 1.2) +
      scale_x_continuous(breaks = seq(1970, 2020, by = 10)) +
      scale_y_continuous(labels = scales::comma) +
      labs(
        y     = sp,
        x     = if (show_x) "Year" else NULL,
        title = NULL
      ) +
      theme_pub(base_size = 9)

    if (!show_x) {
      p <- p + theme(
        axis.text.x  = element_blank(),
        axis.title.x = element_blank()
      )
    }

    p
  }

  species_list <- levels(pred_long$species)

  # Build panels — x-axis labels only on bottom panel
  panels <- purrr::imap(species_list, function(sp, i) {
    make_panel(sp, show_x = (i == length(species_list)))
  })

  patchwork::wrap_plots(panels, ncol = 1) +
    patchwork::plot_annotation(tag_levels = "A")
}
