# ============================================================================
# 07cz_deck_figure_reexport.R — Royal Society deck figure re-export (S6/S8/S9)
# stier-2027-herring-metapopulation
#
# Re-exports the three R-figure slides for the US-UK forum deck so axis labels
# are readable from the back of a lecture theatre and the aspect ratio matches
# the slide canvas (no PowerPoint stretching). Per
# analysis/04_talks/2026-royalsociety/Talk_Materials/deck_design_system.md §5:
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

# ── S8 — realized growth fell across the metapopulation (all 11 sections) ─
# ALL-11 view of the promoted m1_stier_11 baseline (Adrian's call 2026-05-18):
# per-section mean realized growth, historical (1952-1994) -> post (1995-2025),
# from stier2020_updated_companion_growth_change.csv. Tasu Sound & Naden
# Harbour are retained in m1_stier_11 but flagged "sparse sensitivity" (the
# sections Stier 2020 excluded from focal panels) -> drawn grey + dashed and
# label-suffixed, never hidden. Focal-9 decliners = kelp bundle (the
# system-wide ecological signal); Port Louis = the lone focal hold (ink).
# A lambda = 1 replacement line is meaningful here (a couple of post-era
# sections dip just below 1 on this metric). Medians only; claim-safe count
# is post-era median < historical median. Top ~1.85 in kept clear for the
# native PowerPoint title; direct labels, no legend.
try({
  suppressPackageStartupMessages(library(ggrepel))

  cg <- read_csv(file.path(diag_dir,
                 "stier2020_updated_companion_growth_change.csv"),
                 show_col_types = FALSE) %>%
    mutate(
      sparse = grepl("sparse", reporting, ignore.case = TRUE),
      grp    = ifelse(post_growth_median < hist_growth_median, "fell", "held"),
      lab    = sub(" & Gowgaia Bay", "", site_name),
      lab    = ifelse(sparse, paste0(lab, "  (sparse)"), lab)
    )
  n_fell <- sum(cg$grp == "fell"); n_tot <- nrow(cg)

  # long form: one segment per section, hist (x=1) -> post (x=2)
  seg <- bind_rows(
    transmute(cg, site_name, lab, sparse, grp, xpos = 1, gy = hist_growth_median),
    transmute(cg, site_name, lab, sparse, grp, xpos = 2, gy = post_growth_median)
  )
  fell_f <- filter(seg, grp == "fell", !sparse)        # focal-9 decliners
  held_f <- filter(seg, grp == "held", !sparse)        # focal hold(s): Port Louis
  spar   <- filter(seg, sparse)                        # Tasu + Naden
  lab_r  <- filter(seg, xpos == 2)
  lab_r$lab_col <- ifelse(lab_r$sparse, DECK$soft,
                   ifelse(lab_r$grp == "held", DECK$ink, DECK$soft))

  y_lo <- 0.90; y_hi <- 1.245
  y_hdr <- 1.220                                       # period column headers

  p8 <- ggplot(mapping = aes(xpos, gy, group = site_name)) +
    # replacement reference (now informative: some post-era sections < 1)
    annotate("segment", x = 1, xend = 2, y = 1, yend = 1,
             linetype = "dashed", colour = DECK$amber, linewidth = 0.55) +
    annotate("text", x = 0.58, y = 1.0, label = "replacement  (λ = 1)",
             hjust = 0, vjust = -0.55, colour = DECK$amber, size = 5.0) +
    # 8 focal-9 declining sections — cohesive kelp bundle
    geom_line(data = fell_f, colour = DECK$kelp, linewidth = 1.3,
              alpha = 0.78, lineend = "round") +
    geom_point(data = fell_f, colour = DECK$kelp, size = 3.0, alpha = 0.85) +
    # Port Louis — the lone focal hold: bright ink, stands clear
    geom_line(data = held_f, colour = DECK$ink, linewidth = 1.35,
              lineend = "round") +
    geom_point(data = held_f, colour = DECK$ink, size = 3.3) +
    # Tasu Sound & Naden Harbour — sparse-sensitivity: grey, dashed
    geom_line(data = spar, colour = DECK$soft, linewidth = 1.15,
              linetype = "31", alpha = 0.9, lineend = "round") +
    geom_point(data = spar, colour = DECK$soft, size = 2.7,
               alpha = 0.9, shape = 1, stroke = 1.1) +
    # period column headers replace angled x tick labels
    annotate("text", x = 1, y = y_hdr, label = "1952–1994",
             colour = DECK$ink, size = 7.4, fontface = "bold") +
    annotate("text", x = 1, y = y_hdr - 0.020, label = "historical",
             colour = DECK$soft, size = 5.0) +
    annotate("text", x = 2, y = y_hdr, label = "1995–2025",
             colour = DECK$ink, size = 7.4, fontface = "bold") +
    annotate("text", x = 2, y = y_hdr - 0.020, label = "post-1994",
             colour = DECK$soft, size = 5.0) +
    # direct section labels at the recent anchor — ONE repel layer so all
    # 11 names deconflict together (vertical-only, no legend)
    geom_text_repel(
      data = lab_r, aes(label = lab),
      colour = lab_r$lab_col, size = 5.2, hjust = 0,
      direction = "y", xlim = c(2.16, 3.10), ylim = c(0.965, 1.18),
      nudge_x = 0.08, segment.size = 0.25, segment.colour = "#4a4d56",
      box.padding = 0.62, point.padding = 0.22, force = 3.0,
      min.segment.length = 0, max.overlaps = Inf, seed = 8
    ) +
    # the ONE emphasized, claim-safe annotation (lower calm zone)
    annotate("text", x = 0.58, y = 0.952, hjust = 0, vjust = 0,
             label = sprintf("%d of %d sections declined.", n_fell, n_tot),
             colour = DECK$ink, size = 7.0, fontface = "bold") +
    # honest provenance / metric disclosure (claim-control)
    annotate("text", x = 0.58, y = 0.916, hjust = 0, vjust = 0,
             label = "m1_stier_11 per-section mean realized growth, all 11 sections (Tasu Sound & Naden Harbour = sparse sensitivity).",
             colour = DECK$soft, size = 4.4) +
    scale_x_continuous(limits = c(0.55, 3.10), breaks = c(1, 2),
                       expand = expansion(mult = 0)) +
    scale_y_continuous(breaks = c(0.95, 1.05, 1.15),
                       expand = expansion(mult = c(0.02, 0.02))) +
    coord_cartesian(xlim = c(0.55, 3.10), ylim = c(y_lo, y_hi),
                    clip = "off") +
    labs(title = NULL, subtitle = NULL, x = NULL,
         y = "Realized growth rate  (λ)", caption = NULL) +
    theme_lecture(base_size = 22) +
    theme(
      axis.text.x        = element_blank(),
      axis.ticks.x       = element_blank(),
      axis.line.x        = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      panel.grid.major.y = element_line(colour = "#1E2028", linewidth = 0.3),
      axis.title.y       = element_text(colour = DECK$soft, size = rel(0.90)),
      axis.text.y        = element_text(colour = DECK$soft, size = rel(0.84)),
      legend.position    = "none",
      # top ~1.85 in reserved (empty, dark) for the native masthead/title;
      # bottom + sides kept calm. unit = pt (1 in = 72 pt; 540 pt = 7.5 in).
      plot.margin        = margin(t = 150, r = 30, b = 40, l = 46, unit = "pt")
    )
  save_deck(p8, "s08_realized_growth")
}, silent = FALSE)

# ── S6 — ocean productivity vs ocean state (climate / PDO) ───────────────────
# Source `median` = beta * PDO on the LOG-growth scale (verified: beta is the
# constant median/pdo = -0.0529). Exponentiate to the PDO-attributable
# multiplicative growth factor exp(beta*PDO). Over the observed PDO range
# (+1.545 warmest 2015 -> -2.6225 coldest 2023) this factor runs ~0.92x (warm)
# to ~1.15x (cold) = a ~1.25x swing. NOT 3x — magnitude is the real model
# number, no fabricated bracket (claim-control sheet / numbers_provenance.md).
try({
  d <- read_csv(file.path(diag_dir, "stier2020_updated_fig3_pdo_effect.csv"),
                show_col_types = FALSE) %>%
    arrange(pdo) %>%
    mutate(prod      = exp(median),
           prod_lo50 = exp(q25),  prod_hi50 = exp(q75),
           prod_lo95 = exp(lo95), prod_hi95 = exp(hi95))

  cold  <- d[which.min(d$pdo), ]          # coldest / most negative PDO = most productive
  warm  <- d[which.max(d$pdo), ]          # warmest / most positive PDO
  f_cold <- cold$prod;  f_warm <- warm$prod
  ratio  <- f_cold / f_warm
  pct_c  <- round((f_cold - 1) * 100)
  pct_w  <- round((f_warm - 1) * 100)
  x_brk  <- max(d$pdo) + 0.18              # bracket sits just right of the data

  lab_cold <- sprintf("cool · productive ocean\n×%.2f  (%+d%% growth)",
                       f_cold, pct_c)
  lab_warm <- sprintf("warm ocean   ×%.2f  (%d%%)", f_warm, pct_w)
  lab_swing <- sprintf("≈%.2f×\nclimate swing", ratio)

  p6 <- ggplot(d, aes(pdo, prod)) +
    geom_hline(yintercept = 1, linetype = "dashed",
               colour = DECK$soft, linewidth = 0.5) +
    annotate("text", x = min(d$pdo), y = 1, label = "no PDO effect (×1.0)",
             hjust = 0, vjust = -0.6, colour = DECK$soft, size = 4.6) +
    geom_ribbon(aes(ymin = prod_lo95, ymax = prod_hi95),
                fill = DECK$marine, alpha = 0.10) +
    geom_ribbon(aes(ymin = prod_lo50, ymax = prod_hi50),
                fill = DECK$marine, alpha = 0.30) +
    geom_line(colour = DECK$ink, linewidth = 1.8) +
    geom_rug(sides = "b", colour = DECK$soft, alpha = 0.35) +
    # tie the swing bracket to the two realized endpoints
    annotate("segment", x = cold$pdo, xend = x_brk, y = f_cold, yend = f_cold,
             colour = DECK$soft, linewidth = 0.35, linetype = "dotted") +
    annotate("segment", x = warm$pdo, xend = x_brk, y = f_warm, yend = f_warm,
             colour = DECK$soft, linewidth = 0.35, linetype = "dotted") +
    annotate("segment", x = x_brk, xend = x_brk, y = f_warm, yend = f_cold,
             colour = DECK$amber, linewidth = 1.0,
             arrow = arrow(ends = "both", length = unit(0.20, "cm"),
                           type = "closed")) +
    annotate("text", x = x_brk, y = (f_warm + f_cold) / 2, label = lab_swing,
             hjust = 1.15, colour = DECK$amber, size = 6.4, fontface = "bold",
             lineheight = 0.92) +
    # realized endpoints
    geom_point(data = rbind(cold, warm), colour = DECK$ink, size = 3.2) +
    annotate("text", x = cold$pdo, y = f_cold, label = lab_cold,
             hjust = 0, vjust = -0.55, colour = DECK$ink, size = 5.4,
             lineheight = 0.92) +
    annotate("text", x = warm$pdo, y = f_warm, label = lab_warm,
             hjust = 1, vjust = 1.7, colour = DECK$ink, size = 5.4) +
    scale_x_continuous(breaks = seq(-3, 2, 1),
                       expand = expansion(mult = c(0.04, 0.13))) +
    coord_cartesian(ylim = c(0.86, 1.26)) +
    labs(
      title = NULL, subtitle = NULL,
      x = "PDO index   ( ← cooler, more productive      warmer → )",
      y = "Productivity  (PDO-attributable growth factor)",
      caption = NULL
    ) +
    theme_lecture(base_size = 22) + deck_titles
  save_deck(p6, "s06_climate_pdo")
}, silent = FALSE)

# ── S7 — the two scales: archipelago management vs cove biology ──────────────
# Real data: stier2020_updated_fig4_fishing.csv (updated Stier et al. 2020
# method — catch matrix extended to 2025; scale-mismatch result, NOT an
# m1_stier_11 output). Two scales: "Archipelago-wide" (the managed/observed
# rate) vs "Fished sections only" (what fish in fished coves experience).
# HCR benchmark drawn ONLY over years in force: DFO cut-off + 20% harvest-rate
# rule for Major SARs 1983-2017, then 10% (Minor SAR dropped to 10% after
# 1994; harvest policy reviewed 2017). Cut-off (0.25*SB0 ~5.4 kt biomass
# floor) is a biomass reference — it lives on the biomass slide, not this
# F axis — described in the slide-7 speaker note (build_pptx_native.js).
try({
  d4 <- read_csv(file.path(diag_dir, "stier2020_updated_fig4_fishing.csv"),
                 show_col_types = FALSE)
  arch <- d4 %>% filter(scale == "Archipelago-wide")       %>% arrange(year)
  fish <- d4 %>% filter(scale == "Fished sections only")   %>% arrange(year)
  gap  <- d4 %>% select(year, scale, median) %>%
    pivot_wider(names_from = scale, values_from = median) %>%
    rename(arch_m = `Archipelago-wide`, fish_m = `Fished sections only`) %>%
    arrange(year) %>%
    mutate(g_lo = pmin(arch_m, fish_m), g_hi = pmax(arch_m, fish_m))

  arch_long_med <- round(median(arch$median) * 100)         # ~3 %
  fish_peak_med <- round(max(fish$median)   * 100)           # ~51 %
  fish_peak_hi  <- round(max(fish$hi95)     * 100)           # ~70 %
  yrs_over_fish <- sum(fish$median > 0.20)                   # 22
  yrs_over_arch <- sum(arch$median > 0.20)                   # 1

  callout <- sprintf(paste0(
    "Managed at ~%d%% archipelago-wide.\n",
    "Fished coves reached ~%d%% (up to ~%d%%).\n",
    "20%% HCR exceeded at the cove scale\n",
    "%d of %d years — once archipelago-wide."),
    arch_long_med, fish_peak_med, fish_peak_hi,
    yrs_over_fish, nrow(fish))

  p7 <- ggplot() +
    # the mismatch made visible: shaded gap between the two median lines
    geom_ribbon(data = gap, aes(year, ymin = g_lo, ymax = g_hi),
                fill = DECK$rust, alpha = 0.10) +
    # uncertainty
    geom_ribbon(data = arch, aes(year, ymin = lo95, ymax = hi95),
                fill = DECK$marine, alpha = 0.16) +
    geom_ribbon(data = fish, aes(year, ymin = lo95, ymax = hi95),
                fill = DECK$rust, alpha = 0.14) +
    geom_ribbon(data = fish, aes(year, ymin = lo80, ymax = hi80),
                fill = DECK$rust, alpha = 0.22) +
    # DFO HCR benchmark — only over years in force
    annotate("segment", x = 1983, xend = 2017, y = 0.20, yend = 0.20,
             colour = DECK$amber, linetype = "dashed", linewidth = 0.9) +
    annotate("segment", x = 2017, xend = 2017, y = 0.20, yend = 0.10,
             colour = DECK$amber, linetype = "dotted", linewidth = 0.5) +
    annotate("segment", x = 2017, xend = 2025, y = 0.10, yend = 0.10,
             colour = DECK$amber, linetype = "dashed", linewidth = 0.9) +
    annotate("text", x = 2003, y = 0.225, label = "DFO 20% harvest-rate HCR (1983–2017)",
             hjust = 0, vjust = -0.55, colour = DECK$amber, size = 4.8) +
    annotate("text", x = 2025, y = 0.10, label = "→ 10% (post-2017)",
             hjust = 1, vjust = -0.4, colour = DECK$amber, size = 4.4) +
    # median trajectories
    geom_line(data = arch, aes(year, median),
              colour = DECK$marine, linewidth = 1.6) +
    geom_line(data = fish, aes(year, median),
              colour = DECK$rust, linewidth = 1.9) +
    # direct series labels (2 groups -> no legend)
    annotate("text", x = 1973, y = 0.52,
             label = "Fished sections only\n(what fished coves experience)",
             hjust = 0, colour = DECK$rust, size = 5.6, lineheight = 0.92,
             fontface = "bold") +
    annotate("text", x = 1957, y = 0.175,
             label = "Archipelago-wide (the managed rate)",
             hjust = 0, colour = DECK$marine, size = 5.4, fontface = "bold") +
    # data-derived headline callout (clear upper-right whitespace)
    annotate("text", x = 2025, y = 0.76, label = callout,
             hjust = 1, vjust = 1, colour = DECK$ink, size = 5.4,
             fontface = "bold", lineheight = 0.95) +
    # provenance tag
    annotate("text", x = 1951, y = -0.135,
             label = "Updated Stier et al. 2020 method; catch matrix to 2025 — scale-mismatch result, not m1_stier_11.",
             hjust = 0, colour = DECK$soft, size = 3.7) +
    scale_x_continuous(breaks = seq(1950, 2020, 10),
                       expand = expansion(mult = c(0.02, 0.03))) +
    scale_y_continuous(labels = scales::label_percent(accuracy = 1),
                       breaks = seq(0, 0.7, 0.1)) +
    coord_cartesian(ylim = c(0, 0.78), clip = "off") +
    labs(title = NULL, subtitle = NULL,
         x = NULL, y = "Proportion biomass caught  (F)", caption = NULL) +
    theme_lecture(base_size = 22) + deck_titles +
    theme(plot.margin = margin(34, 44, 72, 40))
  save_deck(p7, "s07_two_scales")
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
               colour = DECK$soft, linewidth = 0.7) +
    annotate("text", x = 1994, y = 0.60,
             label = "roe fishery closed 1994", hjust = 1.05, vjust = 0,
             colour = DECK$soft, size = 4.6) +
    geom_line(colour = DECK$plum, linewidth = 1.4) +
    geom_point(colour = DECK$plum, size = 2.2) +
    labs(
      title = NULL,
      subtitle = NULL,
      x = NULL, y = "Synchrony  (φ)",
      caption = NULL
    ) +
    theme_lecture(base_size = 22) + deck_titles
  save_deck(p9, "s09_synchrony")
}, silent = FALSE)

# ── S10 — the predators came back (HG predator demand + pressure) ────────────
# Firewall-safe: reads the LOCALLY-IMPORTED predator products
# (Data/processed/predators/, written by Code/02c_integrate_hg_predator_repo
# _products.R), never the sibling repo path. Two panels:
#   A  HG herring eaten by predator group 1910–2024 (marine mammals the hero
#      band — recovered from whaling/sealing; orders-of-magnitude rise)
#   B  predator demand as % of HG spawn (100% = demand equals annual spawn)
# Claim-control sheet: this is a LARGE ECOLOGICAL PRESSURE, NOT a fitted /
# promoted m1_stier_11 predator coefficient — baked into the on-figure note.
# 2025 is a partial year in the import (fish only) -> series capped at 2024.
try({
  pred_dir <- file.path(proj_dir, "Data", "processed", "predators")

  grp_lab <- c(mammals = "Marine mammals", fish = "Fish",
               salmon = "Salmon", birds = "Birds (egg)")
  grp_col <- c("Marine mammals" = DECK$marine, "Fish" = DECK$kelp,
               "Salmon" = DECK$amber, "Birds (egg)" = DECK$plum)
  # stack bottom -> top: mammals (hero) at the base
  grp_ord <- c("Marine mammals", "Fish", "Salmon", "Birds (egg)")

  # complete the GROUP dimension within native years only (pre-1950 data is
  # 5-yearly; full_seq would fill census gaps with 0 and create a sawtooth).
  cg <- read_csv(file.path(pred_dir, "hg_predator_consumption_by_group_year.csv"),
                 show_col_types = FALSE) %>%
    filter(year <= 2024) %>%
    mutate(group = factor(grp_lab[group], levels = grp_ord)) %>%
    tidyr::complete(year, group, fill = list(C_kt = 0)) %>%
    arrange(year, group)

  m1910 <- round(sum(cg$C_kt[cg$year == 1910]), 1)        # ~17.5 kt, mammals only
  cmax  <- cg %>% group_by(year) %>% summarise(t = sum(C_kt), .groups = "drop")
  ypk   <- round(max(cmax$t))

  pA <- ggplot(cg, aes(year, C_kt, fill = group)) +
    geom_area(position = "stack", alpha = 0.92, colour = NA) +
    annotate("segment", x = 1910, xend = 1910, y = m1910, yend = m1910 + 4.5,
             colour = DECK$soft, linewidth = 0.4) +
    annotate("text", x = 1912, y = m1910 + 4.8,
             label = sprintf("pre-whaling baseline\n≈ %.1f kt · yr⁻¹ (mammals)", m1910),
             hjust = 0, vjust = 0, colour = DECK$soft, size = 4.6,
             lineheight = 0.92) +
    scale_fill_manual(values = grp_col, breaks = grp_ord, name = NULL) +
    scale_x_continuous(breaks = seq(1910, 2020, 20),
                       expand = expansion(mult = c(0.01, 0.02))) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.16))) +
    labs(title = NULL, subtitle = NULL,
         x = NULL, y = "Herring eaten  (kt · yr⁻¹)", caption = NULL) +
    theme_lecture(base_size = 22) + deck_titles +
    theme(legend.position = "top",
          legend.text = element_text(color = DECK$ink, size = rel(0.92)),
          legend.key.size = unit(0.9, "lines"),
          axis.text.x = element_blank(),
          axis.title.y = element_text(margin = margin(r = 12)),
          plot.margin = margin(30, 44, 26, 70))

  pr <- read_csv(file.path(pred_dir, "hg_predation_pressure_index_audited.csv"),
                 show_col_types = FALSE) %>%
    mutate(pressure_pct = suppressWarnings(as.numeric(pressure_pct))) %>%
    filter(!is.na(pressure_pct), year <= 2024)
  pr_recent <- round(mean(pr$pressure_pct[pr$year >= 2015]))

  pB <- ggplot(pr, aes(year, pressure_pct)) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0, ymax = 100,
             fill = DECK$soft, alpha = 0.07) +
    geom_area(fill = DECK$rust, alpha = 0.22) +
    geom_hline(yintercept = 100, linetype = "dashed",
               colour = DECK$amber, linewidth = 0.7) +
    annotate("text", x = 1951, y = 100,
             label = "predator demand = annual spawn  (100%)",
             hjust = 0, vjust = -0.6, colour = DECK$amber, size = 4.4) +
    geom_line(colour = DECK$rust, linewidth = 1.5) +
    geom_point(colour = DECK$rust, size = 1.9) +
    annotate("text", x = 1951, y = max(pr$pressure_pct) * 0.97,
             label = sprintf("2015–24 mean ≈ %d%% of spawn", pr_recent),
             hjust = 0, vjust = 1, colour = DECK$ink, size = 4.8,
             fontface = "bold") +
    scale_x_continuous(breaks = seq(1910, 2020, 20),
                       expand = expansion(mult = c(0.01, 0.02))) +
    scale_y_continuous(labels = scales::label_percent(scale = 1, accuracy = 1),
                       expand = expansion(mult = c(0.02, 0.10))) +
    coord_cartesian(xlim = range(cg$year), clip = "off") +
    labs(title = NULL, subtitle = NULL,
         x = NULL, y = "% of spawn", caption = NULL) +
    theme_lecture(base_size = 22) + deck_titles +
    theme(axis.title.y = element_text(margin = margin(r = 12)),
          plot.margin = margin(22, 44, 22, 70))

  p10 <- patchwork::wrap_plots(pA, pB, ncol = 1, heights = c(1.62, 1)) +
    patchwork::plot_annotation(
      tag_levels = "A",
      caption = paste0(
        "Audited HG predator herring demand — Stier Lab predator synthesis (24 spp).\n",
        "A large ecological pressure, NOT a fitted or promoted m1_stier_11 predator coefficient."),
      theme = theme(
        plot.background = element_rect(fill = PAL$dark_bg, color = NA),
        plot.tag = element_text(color = DECK$soft, size = 16, face = "bold"),
        plot.caption = element_text(color = DECK$soft, size = 15, hjust = 0,
                                    lineheight = 1.05,
                                    margin = margin(t = 4, l = 70, b = 2))))
  save_deck(p10, "s10_predators_returned")
}, silent = FALSE)

# ── S5 — REAL m1_stier_11 estimated total biomass, 1951–2025 ─────────────────
try({
  bm <- read_csv(file.path(diag_dir, "m1_stier_11_total_biomass_by_year.csv"),
                 show_col_types = FALSE) %>%
    filter(report_set == "focal_9") %>% arrange(year)
  ytop <- max(bm$median, na.rm = TRUE) * 1.32
  # labels staggered off the data ceiling into low-data zones (no collision):
  # 1968 sits left of its line in the open post-peak gap; 1994 upper-right
  # where post-closure biomass is low.
  closures <- data.frame(year = c(1968, 1994),
                         y   = c(ytop * 0.80, ytop * 0.93),
                         hj  = c(-0.07, 1.06),
                         lab = c("reduction fishery\nclosed ~1968",
                                 "roe fishery\nclosed 1994"))
  p5 <- ggplot(bm, aes(year, median)) +
    geom_vline(data = closures, aes(xintercept = year), linetype = "dashed",
               colour = DECK$soft, linewidth = 0.7) +
    geom_text(data = closures, aes(x = year, y = y, label = lab, hjust = hj),
              vjust = 1, colour = DECK$soft, size = 4.2,
              lineheight = 0.9, inherit.aes = FALSE) +
    geom_ribbon(aes(ymin = lo80, ymax = hi80), fill = DECK$rust, alpha = 0.14) +
    geom_line(colour = DECK$rust, linewidth = 1.6) +
    scale_y_continuous(labels = scales::label_comma()) +
    coord_cartesian(ylim = c(0, ytop)) +
    labs(
      title = NULL,
      subtitle = NULL,
      x = NULL, y = "Estimated biomass (tonnes)",
      caption = NULL
    ) +
    theme_lecture(base_size = 22) + deck_titles +
    theme(axis.title.y = element_text(margin = margin(r = 12)),
          plot.margin  = margin(34, 44, 26, 64))
  save_deck(p5, "s05_biomass_timeline")
}, silent = FALSE)

# ── DFO — Cleary SR 2025/005 spawning biomass vs LRP (REAL extracted data) ───
try({
  ex <- file.path(proj_dir, "Output", "diagnostics",
                   "dfo_newer_public_pdf_extract")
  t15 <- read_csv(file.path(ex,
    "dfo_sr_2025_005_table_15_hg_spawning_biomass_depletion_2015_2024.csv"),
    show_col_types = FALSE) %>%
    transmute(year, med = spawning_biomass_kt_median,
              lo = spawning_biomass_kt_p05, hi = spawning_biomass_kt_p95)
  t19 <- read_csv(file.path(ex,
    "dfo_sr_2025_005_table_19_hg_reference_points.csv"),
    show_col_types = FALSE)
  gv <- function(rp) t19$median[t19$reference_point == rp][1]
  LRP <- gv("0.3SB 0"); SB0 <- gv("SB 0")
  sb25 <- t19$median[t19$reference_point == "SB 2025"][1]
  sb25lo <- t19$p05[t19$reference_point == "SB 2025"][1]
  sb25hi <- t19$p95[t19$reference_point == "SB 2025"][1]
  proj <- data.frame(year = 2025, med = sb25, lo = sb25lo, hi = sb25hi)

  pdfo <- ggplot(t15, aes(year, med)) +
    geom_hline(yintercept = SB0, linetype = "dotted",
               colour = DECK$soft, linewidth = 0.4) +
    annotate("text", x = 2015, y = SB0, label = paste0("unfished SB0 ≈ ", round(SB0, 1), " kt"),
             hjust = 0, vjust = -0.5, colour = DECK$soft, size = 4) +
    geom_hline(yintercept = LRP, linetype = "dashed",
               colour = DECK$amber, linewidth = 0.7) +
    annotate("text", x = 2015, y = LRP, label = paste0("Limit Reference Point = 0.3·SB0 ≈ ", round(LRP, 2), " kt"),
             hjust = 0, vjust = 1.5, colour = DECK$amber, size = 4.2) +
    geom_ribbon(aes(ymin = lo, ymax = hi), fill = DECK$marine, alpha = 0.20) +
    geom_line(colour = DECK$marine, linewidth = 1.6) +
    geom_point(colour = DECK$marine, size = 2.4) +
    geom_point(data = proj, colour = DECK$rust, size = 3.4) +
    geom_errorbar(data = proj, aes(ymin = lo, ymax = hi), width = 0.3,
                  colour = DECK$rust, linewidth = 0.9) +
    annotate("text", x = 2025, y = sb25hi,
             label = "2025 forecast,\nno fishing", hjust = 1.1, vjust = 0,
             colour = DECK$rust, size = 4, lineheight = 0.9) +
    scale_x_continuous(breaks = seq(2015, 2025, 2)) +
    labs(
      title = NULL,
      subtitle = NULL, x = NULL, y = "Spawning biomass (kt)",
      caption = NULL
    ) +
    theme_lecture(base_size = 22) + deck_titles
  save_deck(pdfo, "s_dfo_spawning_biomass")
}, silent = FALSE)

# ── DFO full series 1951–2024 — DIGITIZED from SR 2025/005 Fig 8(d) ──────────
# Overwrites s_dfo_spawning_biomass (later write wins) with the full-length
# traced SB line + exact Table 19 reference points / 2025 forecast.
try({
  dg <- read_csv(file.path(diag_dir,
        "dfo_sr2025005_fig8d_SB_digitized_1951_2024.csv"),
        show_col_types = FALSE) %>%
    transmute(year, sb = suppressWarnings(as.numeric(sb_kt_digitized))) %>%
    filter(!is.na(sb), sb >= 0, sb <= 62)        # >62 = catch-bar pixels, not the SB line
  ex <- file.path(diag_dir, "dfo_newer_public_pdf_extract")
  t19 <- read_csv(file.path(ex,
        "dfo_sr_2025_005_table_19_hg_reference_points.csv"),
        show_col_types = FALSE)
  gv <- function(rp) t19$median[t19$reference_point == rp][1]
  LRP <- gv("0.3SB 0"); SB0 <- gv("SB 0")
  s25 <- t19$median[t19$reference_point == "SB 2025"][1]
  s25lo <- t19$p05[t19$reference_point == "SB 2025"][1]
  s25hi <- t19$p95[t19$reference_point == "SB 2025"][1]
  proj <- data.frame(year = 2025, sb = s25, lo = s25lo, hi = s25hi)
  pD <- ggplot(dg, aes(year, sb)) +
    geom_hline(yintercept = SB0, linetype = "dotted",
               colour = DECK$soft, linewidth = 0.6) +
    annotate("text", x = 2000, y = SB0, label = paste0("unfished SB0 ≈ ", round(SB0,1), " kt"),
             hjust = 0, vjust = -0.6, colour = DECK$soft, size = 4) +
    geom_hline(yintercept = LRP, linetype = "dashed",
               colour = DECK$amber, linewidth = 0.9) +
    annotate("text", x = 1951, y = LRP, label = paste0("Limit Reference Point ≈ ", round(LRP,2), " kt"),
             hjust = 0, vjust = -0.9, colour = DECK$amber, size = 4.2) +
    geom_line(colour = DECK$marine, linewidth = 1.5) +
    geom_point(data = proj, aes(year, sb), colour = DECK$rust, size = 3.4) +
    geom_errorbar(data = proj, aes(year, ymin = lo, ymax = hi), width = 1.2,
                  colour = DECK$rust, linewidth = 0.9, inherit.aes = FALSE) +
    annotate("text", x = 2024.5, y = s25hi, label = "2025 forecast,\nno fishing",
             hjust = 1.15, vjust = 0, colour = DECK$rust, size = 4, lineheight = 0.9) +
    scale_x_continuous(breaks = seq(1950, 2020, 10)) +
    labs(title = NULL,
         subtitle = NULL, x = NULL, y = "Spawning biomass (kt)",
         caption = "Digitized from DFO SR 2025/005 Fig 8(d); reference points & 2025 forecast = Table 19 (exact).") +
    theme_lecture(base_size = 22) + deck_titles +
    theme(plot.caption = element_text(color = DECK$soft, size = rel(0.6), hjust = 0))
  save_deck(pD, "s_dfo_spawning_biomass")
}, silent = FALSE)

cat("Deck figure re-export complete ->", outdir, "\n")
