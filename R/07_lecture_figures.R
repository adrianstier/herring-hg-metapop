# ============================================================================
# 07_lecture_figures.R — Lecture-ready figures (dark background, 4K)
# stier-2027-herring-metapopulation
#
# Produces dark-background figures using theme_lecture() from 00_setup.R
# for use in EEMB 142C / EEMB 242 slide decks.
#
# All figures output at 4K resolution (3840 x 2160 px at 288 dpi).
# ============================================================================

# Reader note:
# These helpers intentionally mirror the publication figures but with a
# presentation-specific visual style. They should accept the same maintained
# posterior summaries so collaborators do not have to learn a second data
# contract just to build lecture slides.


# ── Helper: save a lecture figure at 4K ─────────────────────────────────────

#' Save a ggplot as a 4K PNG for lecture slides
#'
#' Outputs 3840 x 2160 px (16:9) at 288 dpi with a transparent-free dark
#' background. Saves to Output/figures/lecture/.
#'
#' @param plot A ggplot object (should use theme_lecture())
#' @param filename Character, filename (e.g., "lecture_biomass.png")
#' @param width Width in inches (default 13.33 = 3840 / 288)
#' @param height Height in inches (default 7.5 = 2160 / 288)
#' @param dpi Resolution (default 288 for 4K at these dimensions)
#' @return Character path to saved file (invisible)
save_lecture_figure <- function(plot, filename,
                                width = 3840 / 288,
                                height = 2160 / 288,
                                dpi = 288) {
  outdir <- here::here("Output", "figures", "lecture")
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
  outpath <- file.path(outdir, filename)

  ggplot2::ggsave(
    outpath,
    plot   = plot,
    width  = width,
    height = height,
    dpi    = dpi,
    bg     = PAL$dark_bg
  )

  cat("Lecture figure saved:", outpath, "\n")
  invisible(outpath)
}


# ── Lecture Fig: Biomass time series ─────────────────────────────────────────

#' Dark-background biomass time series for lecture slides
#'
#' Same data as fig_biomass_timeseries() but styled with theme_lecture()
#' and the teal/coral/sand palette on dark background.
#'
#' @param biomass_est Tibble from extract_posteriors()$biomass
#' @param sections_drop Character vector of site names to exclude
#' @return ggplot object
fig_lecture_biomass <- function(
    biomass_est,
    sections_drop = c("Tasu Sound & Gowgaia Bay", "Naden Harbour")
) {
  site_col <- if ("site" %in% names(biomass_est)) {
    "site"
  } else if ("section_name" %in% names(biomass_est)) {
    "section_name"
  } else {
    cli::cli_abort("biomass_est must contain either `site` or `section_name`.")
  }

  subpop <- biomass_est |>
    filter(
      .width == 0.9,
      !.data[[site_col]] %in% sections_drop
    ) |>
    mutate(site = .data[[site_col]]) |>
    group_by(site) |>
    mutate(biomass_scaled = scale(biomass)[, 1]) |>
    ungroup()

  arch <- subpop |>
    group_by(year) |>
    summarise(
      biomass_scaled = mean(biomass_scaled, na.rm = TRUE),
      .groups = "drop"
    )

  n_sites <- length(unique(subpop$site))
  pal <- PAL$okabe_ito[seq_len(min(n_sites, length(PAL$okabe_ito)))]

  ggplot() +
    geom_hline(yintercept = 0, colour = "#333333", linewidth = 0.3) +
    geom_line(
      data = subpop,
      aes(x = year, y = biomass_scaled, colour = site),
      linewidth = 0.6, alpha = 0.7
    ) +
    geom_line(
      data = arch,
      aes(x = year, y = biomass_scaled),
      colour = PAL$warm_white, linewidth = 1.8, alpha = 0.8
    ) +
    scale_colour_manual(values = pal) +
    scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
    labs(
      title    = "Herring Subpopulation Biomass",
      subtitle = "Haida Gwaii archipelago, 1950\u20132024",
      x        = "Year",
      y        = "Scaled Estimated Biomass",
      colour   = NULL
    ) +
    theme_lecture(base_size = 18) +
    guides(colour = guide_legend(ncol = 3))
}


# ── Lecture Fig: Fishing rates ───────────────────────────────────────────────

#' Dark-background fishing rate comparison for lecture slides
#'
#' KEY FIGURE: archipelago vs. subpopulation fishing pressure.
#'
#' @param fishing_est Tibble from extract_posteriors()$fishing_rate
#' @return ggplot object
fig_lecture_fishing_rates <- function(fishing_est) {
  fishing_col <- if ("fishing_rate" %in% names(fishing_est)) {
    "fishing_rate"
  } else if ("pc_median" %in% names(fishing_est)) {
    "pc_median"
  } else {
    cli::cli_abort("fishing_est must contain either `fishing_rate` or `pc_median`.")
  }

  arch <- fishing_est |>
    group_by(year) |>
    summarise(pc = mean(.data[[fishing_col]], na.rm = TRUE), .groups = "drop") |>
    mutate(scale = "Archipelago")

  subpop <- fishing_est |>
    filter(.data[[fishing_col]] > 0) |>
    group_by(year) |>
    summarise(pc = mean(.data[[fishing_col]], na.rm = TRUE), .groups = "drop") |>
    mutate(scale = "Subpopulation (fished only)")

  fish_combined <- bind_rows(arch, subpop)

  ggplot(fish_combined, aes(x = year, y = pc,
                            colour = scale, linetype = scale)) +
    geom_line(linewidth = 1.0) +
    scale_colour_manual(
      values = c("Archipelago"                  = PAL$teal,
                 "Subpopulation (fished only)"   = PAL$coral)
    ) +
    scale_linetype_manual(
      values = c("Archipelago"                  = "solid",
                 "Subpopulation (fished only)"   = "dashed")
    ) +
    scale_y_continuous(
      limits = c(0, 1),
      breaks = seq(0, 1, by = 0.2),
      labels = scales::percent_format(accuracy = 1)
    ) +
    scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
    labs(
      title    = "Fishing Pressure: Archipelago vs. Subpopulation",
      subtitle = "Proportion of biomass caught per year",
      x        = "Year",
      y        = "Proportion Biomass Caught",
      colour   = NULL,
      linetype = NULL
    ) +
    theme_lecture(base_size = 18)
}


# ── Lecture Fig: Portfolio synchrony ─────────────────────────────────────────

#' Dark-background moving-window synchrony for lecture slides
#'
#' @param sync_metrics Tibble from compute_synchrony()
#' @param portfolio_metrics Tibble from compute_portfolio() (optional,
#'   if provided, shows CV ratio on a second panel)
#' @return ggplot object
fig_lecture_portfolio <- function(sync_metrics, portfolio_metrics = NULL) {

  p_sync <- ggplot(sync_metrics, aes(x = window_mid, y = mean_pairwise_cor)) +
    geom_ribbon(
      aes(ymin = mean_pairwise_cor - sd_pairwise_cor,
          ymax = mean_pairwise_cor + sd_pairwise_cor),
      fill = PAL$teal, alpha = 0.15
    ) +
    geom_hline(yintercept = 0, colour = "#333333", linewidth = 0.3) +
    geom_line(colour = PAL$teal, linewidth = 1.0) +
    scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
    scale_y_continuous(limits = c(-0.5, 1)) +
    labs(
      title = "Spatial Synchrony Among Subpopulations",
      subtitle = "10-year moving window, pairwise Spearman correlation",
      x     = "Year (window midpoint)",
      y     = "Mean Pairwise Correlation"
    ) +
    theme_lecture(base_size = 18)

  if (!is.null(portfolio_metrics)) {
    p_cv <- ggplot(portfolio_metrics, aes(x = window_mid, y = cv_ratio)) +
      geom_hline(yintercept = 1, colour = "#555555", linetype = "dashed",
                 linewidth = 0.4) +
      geom_line(colour = PAL$gold, linewidth = 1.0) +
      scale_x_continuous(breaks = seq(1950, 2020, by = 10)) +
      labs(
        title = "Portfolio Effect (CV Ratio)",
        x     = NULL,
        y     = "CV Ratio"
      ) +
      theme_lecture(base_size = 18) +
      theme(axis.text.x = element_blank(), axis.title.x = element_blank())

    p_cv / p_sync +
      patchwork::plot_annotation(
        tag_levels = "A",
        theme = theme(
          plot.tag = element_text(colour = PAL$warm_white, size = 20, face = "bold")
        )
      )
  } else {
    p_sync
  }
}
