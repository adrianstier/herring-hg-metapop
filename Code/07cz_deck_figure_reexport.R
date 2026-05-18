# ============================================================================
# 07cz_deck_figure_reexport.R — Royal Society deck figure re-export (S6/S8/S9)
# stier-2027-herring-metapopulation
#
# Re-exports the three R-figure slides for the US-UK forum deck so axis labels
# are readable from the back of a lecture theatre and the aspect ratio matches
# the slide canvas (no PowerPoint stretching). Per
# talk-usuk-forum-2026/Talk_Materials/deck_design_system.md §5:
#   - theme_lecture() (dark, base_size >= 18) — projection-legible
#   - canvas 13.333 x 7.5 in @ 288 dpi = 3840 x 2160 px (16:9, zero stretch)
#   - series colours = the deck track-colour contract (not ggplot defaults)
#   - title/subtitle/caption baked into the PNG (no live fonts on venue PC)
#   - claim/number guardrails (claim-control sheet / numbers_provenance.md)
#
# Rebuilds from CACHED tidy data where available (no Stan reload):
#   S8  <- Output/diagnostics/stier2020_updated_fig5_growth_periods.csv
#   S6  <- Output/diagnostics/stier2020_updated_fig3_pdo_effect.csv
#   S9  <- Data/processed/HG_Spawn_Survey_1951_2025_all_sections.csv
#          (synchrony recomputed with the exact Code/04 canonical method)
#
# Output: Output/figures/lecture/deck/{s06_climate_pdo,s08_realized_growth,
#         s09_synchrony}.png
# ============================================================================

proj_dir <- here::here()
source(file.path(proj_dir, "R", "00_setup.R"))

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(ggplot2)
  library(stringr)
})
wsub <- function(s) str_wrap(s, width = 76)   # subtitle wrap
wcap <- function(s) str_wrap(s, width = 118)  # caption wrap

outdir <- file.path(proj_dir, "Output", "figures", "lecture", "deck")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
diag_dir <- file.path(proj_dir, "Output", "diagnostics")

# Deck track-colour contract (dark-mode variants — match the HTML slides)
DECK <- list(
  rust = "#d9714f", marine = "#6e9bc4", kelp = "#8aa074",
  plum = "#b685a8", amber = "#cfa055", ink = "#f0eee9", soft = "#a8a59f"
)

# Full-slide 16:9 export: 13.333 x 7.5 in @ 288 dpi = 3840 x 2160 px
save_deck <- function(p, stem) {
  path <- file.path(outdir, paste0(stem, ".png"))
  ggsave(path, p, width = 13.333, height = 7.5, units = "in",
         dpi = 288, bg = PAL$dark_bg)
  cat("  saved:", path, "\n")
  invisible(path)
}

# Shared deck title/caption styling on top of theme_lecture
deck_titles <- theme(
  plot.title    = element_text(color = DECK$ink, size = rel(1.45),
                               face = "bold", margin = margin(b = 4)),
  plot.subtitle = element_text(color = DECK$soft, size = rel(0.95),
                               margin = margin(b = 14)),
  plot.caption  = element_text(color = DECK$soft, size = rel(0.62),
                               hjust = 0, margin = margin(t = 16)),
  plot.margin   = margin(34, 44, 26, 40)
)

# ── S8 — realized population growth collapsed, cove by cove ──────────────────
try({
  g <- read_csv(file.path(diag_dir, "stier2020_updated_fig5_growth_periods.csv"),
                show_col_types = FALSE)
  g$period <- factor(g$period, levels = unique(g$period[order(g$period)]))
  p8 <- ggplot(g, aes(period, median, group = section_name)) +
    geom_hline(yintercept = 1, linetype = "dashed",
               colour = DECK$amber, linewidth = 0.6) +
    geom_line(colour = DECK$kelp, linewidth = 0.9, alpha = 0.55) +
    geom_point(colour = DECK$kelp, size = 2.4, alpha = 0.8) +
    scale_x_discrete(expand = expansion(add = c(0.45, 0.45))) +
    labs(
      title = "Population growth collapsed — cove by cove",
      subtitle = wsub("Realized growth rate by spawning section, historical vs recent (each line = one cove; amber dashed = λ 1, no growth)"),
      x = NULL, y = "Realized growth rate  (λ)",
      caption = wcap("Source: m1_stier_11 refit, Stier-aligned baseline (Output/figures/stier2020_updated/fig5). Structural, system-wide decline invisible at the management scale.")
    ) +
    theme_lecture(base_size = 22) + deck_titles +
    theme(axis.text.x = element_text(angle = 12, hjust = 1))
  save_deck(p8, "s08_realized_growth")
}, silent = FALSE)

# ── S6 — ocean productivity: a first-order driver (climate / PDO) ────────────
try({
  d <- read_csv(file.path(diag_dir, "stier2020_updated_fig3_pdo_effect.csv"),
                show_col_types = FALSE)
  p6 <- ggplot(d, aes(year, median)) +
    geom_hline(yintercept = 0, colour = DECK$soft, linewidth = 0.4) +
    geom_ribbon(aes(ymin = lo95, ymax = hi95), fill = DECK$marine, alpha = 0.18) +
    geom_ribbon(aes(ymin = q25, ymax = q75), fill = DECK$marine, alpha = 0.34) +
    geom_line(colour = DECK$marine, linewidth = 1.1) +
    labs(
      title = "Ocean productivity is a first-order driver",
      subtitle = wsub("Posterior PDO effect on subpopulation growth (median, 50% & 95% CI) — climate necessary, not sufficient"),
      x = NULL, y = "PDO effect on growth",
      caption = wcap("Source: m1_stier_11 (Output/figures/stier2020_updated/fig3). Climate is a driver, not the whole answer; no predator coefficient is promoted for Haida Gwaii (claim-control sheet).")
    ) +
    theme_lecture(base_size = 22) + deck_titles
  save_deck(p6, "s06_climate_pdo")
}, silent = FALSE)

# ── S9 — the portfolio eroded (synchrony; canonical Code/04 method) ──────────
try({
  spawn_raw <- read_csv(
    file.path(proj_dir, "Data", "processed",
              "HG_Spawn_Survey_1951_2025_all_sections.csv"),
    show_col_types = FALSE)
  keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
  spawn <- spawn_raw %>%
    filter(section %in% keep_sections) %>%
    select(year, section, section_name, spawn_index_tonnes) %>%
    arrange(year, section)
  years <- sort(unique(spawn$year)); n_years <- length(years)
  spawn_wide <- spawn %>%
    pivot_wider(id_cols = year, names_from = section_name,
                values_from = spawn_index_tonnes) %>%
    arrange(year)
  spawn_mat <- as.matrix(spawn_wide[, -1]); rownames(spawn_mat) <- spawn_wide$year

  compute_synchrony <- function(mat) {           # verbatim from Code/04
    site_sds <- apply(mat, 2, sd, na.rm = TRUE)
    active   <- which(site_sds > 0)
    if (length(active) < 2) return(NA_real_)
    ma <- mat[, active, drop = FALSE]
    var(rowSums(ma, na.rm = TRUE)) / (sum(apply(ma, 2, sd, na.rm = TRUE))^2)
  }
  window_size <- 10
  n_windows <- n_years - window_size + 1
  roll <- data.frame(window_mid = numeric(n_windows),
                      synchrony = numeric(n_windows))
  for (w in seq_len(n_windows)) {
    ys <- years[w]; ye <- years[w + window_size - 1]
    idx <- which(years >= ys & years <= ye)
    roll$window_mid[w] <- (ys + ye) / 2
    roll$synchrony[w]  <- compute_synchrony(spawn_mat[idx, , drop = FALSE])
  }
  write_csv(roll, file.path(diag_dir, "deck_s09_synchrony_rolling.csv"))

  p9 <- ggplot(roll, aes(window_mid, synchrony)) +
    geom_vline(xintercept = 1994, linetype = "dashed",
               colour = DECK$soft, linewidth = 0.4) +
    annotate("text", x = 1994, y = max(roll$synchrony, na.rm = TRUE),
             label = "roe fishery closed 1994", hjust = 1.05, vjust = 1,
             colour = DECK$soft, size = 4.2) +
    geom_line(colour = DECK$plum, linewidth = 1.4) +
    geom_point(colour = DECK$plum, size = 2.2) +
    labs(
      title = "The portfolio eroded",
      subtitle = wsub("Subpopulation synchrony, 10-yr rolling windows (Loreau & de Mazancourt index)"),
      x = NULL, y = "Synchrony  (φ)",
      caption = wcap("Method = Code/04 (canonical). The >60% rise since the mid-1990s is a Stier et al. 2020 published result; current m1_stier_11 synchrony = 0.63 all-11 / 0.70 focal-9. The early-warning-signal reading is a PROPOSAL, not a tested result (claim-control sheet).")
    ) +
    theme_lecture(base_size = 22) + deck_titles
  save_deck(p9, "s09_synchrony")
}, silent = FALSE)

# ── S5 — REAL m1_stier_11 estimated total biomass, 1951–2025 ─────────────────
try({
  bm <- read_csv(file.path(diag_dir, "m1_stier_11_total_biomass_by_year.csv"),
                 show_col_types = FALSE) %>%
    filter(report_set == "focal_9") %>% arrange(year)
  ytop <- max(bm$median, na.rm = TRUE) * 1.32
  closures <- data.frame(year = c(1968, 1994),
                         lab = c("reduction fishery\nclosed ~1968",
                                 "roe fishery\nclosed 1994"))
  p5 <- ggplot(bm, aes(year, median)) +
    geom_vline(data = closures, aes(xintercept = year), linetype = "dashed",
               colour = DECK$soft, linewidth = 0.45) +
    geom_text(data = closures, aes(x = year, y = ytop, label = lab),
              hjust = 1.06, vjust = 1.05, colour = DECK$soft, size = 4.2,
              lineheight = 0.9, inherit.aes = FALSE) +
    geom_ribbon(aes(ymin = lo80, ymax = hi80), fill = DECK$rust, alpha = 0.20) +
    geom_line(colour = DECK$rust, linewidth = 1.6) +
    scale_y_continuous(labels = scales::label_comma()) +
    coord_cartesian(ylim = c(0, ytop)) +
    labs(
      title = "Two collapses, two outcomes",
      subtitle = NULL,
      x = NULL, y = "Estimated biomass (tonnes)",
      caption = wcap("Real model output (m1_stier_11, focal-9 reporting; median, 80% CI). The mid-century reduction-fishery collapse rebounded within ~5 years; the post-1990s roe-fishery state has not recovered.")
    ) +
    theme_lecture(base_size = 22) + deck_titles
  save_deck(p5, "s05_biomass_timeline")
}, silent = FALSE)

cat("Deck figure re-export complete ->", outdir, "\n")
