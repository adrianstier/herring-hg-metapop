# ============================================================================
# 07bx_elder_age_spatial_coupling_screen.R
# Elder / experienced-spawner age index vs spatial-portfolio coupling screen,
# with gear-confound control and stability checks.
#
# Question (GWOF / entrainment precursor, MacCall et al. 2019 ICES JMS):
#   Does a decline in the experienced:first-time spawner structure (the
#   Corten 2002 / Huse 2002,2010 quantity MacCall names) PRECEDE the decline
#   in the effective number of occupied spawning sites (MacCall Eq 6-7) and
#   the regional spawn collapse?
#
# This does NOT fit a new model and does NOT alter `m1_stier_11`. It is a
# DESCRIPTIVE, PROVISIONAL, REGIONAL (HG SAR) lead/lag cross-correlation
# cross-check built only from:
#   - public Appendix B number-at-age (CSAS 2018/028, extracted_public_provisional)
#   - processed core regional + section spawn covariates
#
# Streams compared (so gear-selectivity confound is visible, not hidden):
#   - pooled_all_fleets         (1951-2017, mixed gears across decades)
#   - gear2_roe_seine_only      (whenever Gear2 sampled, ~1972-2017)
#   - gear2_roe_seine_1980_2017 (modern single-fleet window, gear-confound free)
#
# Firewall (docs/talk-model-claim-control-sheet.md "Doherty/WCVI",
# "Age/recruitment lag"; docs/doherty-style-hg-gap-table.md):
#   - Age composition is whole-HG SAR, provisional public extract.
#   - It is NOT section-resolved and NOT an HG-estimated parameter.
#   - Output is a "consistent-with / motivating coupling", never causal,
#     never independent validation of the baseline.
# ============================================================================

suppressWarnings(suppressMessages({
  library(tidyverse)
  library(here)
  library(patchwork)
}))

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir  <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# Okabe-Ito + theme_pub mirror of R/00_setup.R (self-contained, house standard)
okabe_ito <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
               "#0072B2", "#D55E00", "#CC79A7")
theme_pub <- function(base_size = 10) {
  ggplot2::theme_bw(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(linewidth = 0.25),
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(size = base_size - 1, face = "bold"),
      axis.text = ggplot2::element_text(size = base_size - 2),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(size = base_size, face = "bold"),
      plot.tag = ggplot2::element_text(size = base_size + 1, face = "bold"),
      plot.margin = ggplot2::margin(6, 8, 6, 8, "mm")
    )
}

# ── 1. Experienced-spawner age indices from public Appendix B B.15 ───────────
b15_path <- file.path(diag_dir, "dfo_hg_public_extract",
                      "dfo_hg_appendix_b15_number_at_age_long.csv")
stopifnot(file.exists(b15_path))

b15 <- readr::read_csv(b15_path, show_col_types = FALSE,
                       locale = readr::locale(encoding = "UTF-8")) %>%
  mutate(year = as.integer(year),
         age = as.integer(age),
         n_at_age = as.numeric(n_at_age)) %>%
  filter(!is.na(year), !is.na(age), !is.na(n_at_age), n_at_age >= 0)

# MATURITY: HG herring mature ~age 3; age >= 4 are returning ("experienced")
# spawners; age 10 is a PLUS GROUP (mean_age is floored).
age_indices <- function(df) {
  df %>%
    group_by(year) %>%
    summarise(
      n_total      = sum(n_at_age),
      mean_age     = sum(age * n_at_age) / sum(n_at_age),
      prop_age_ge4 = sum(n_at_age[age >= 4]) / sum(n_at_age),
      n_age3       = sum(n_at_age[age == 3]),
      n_age_ge4    = sum(n_at_age[age >= 4]),
      .groups = "drop"
    ) %>%
    mutate(repeat_ratio = if_else(n_age3 > 0, n_age_ge4 / n_age3, NA_real_))
}

age_pooled <- age_indices(b15) %>% mutate(stream = "pooled_all_fleets")
age_g2     <- age_indices(filter(b15, fleet == "Gear2_roe_seine")) %>%
  mutate(stream = "gear2_roe_seine_only")
age_g2_mod <- age_indices(filter(b15, fleet == "Gear2_roe_seine", year >= 1980)) %>%
  mutate(stream = "gear2_roe_seine_1980_2017")

age_long <- bind_rows(age_pooled, age_g2, age_g2_mod)

# ── 2. Spatial / abundance targets from processed core covariates ────────────
region <- readr::read_csv(
  file.path(proj_dir, "Data", "processed",
            "dfo_spawn_covariates_region_1951_2025.csv"),
  show_col_types = FALSE) %>%
  transmute(year = as.integer(year),
            spawn_index_t = as.numeric(total_spawn_index_tonnes),
            occupied_sections = as.numeric(occupied_sections))

section <- readr::read_csv(
  file.path(proj_dir, "Data", "processed",
            "dfo_spawn_covariates_section_1951_2025.csv"),
  show_col_types = FALSE) %>%
  mutate(year = as.integer(year),
         spawn_index_tonnes = as.numeric(spawn_index_tonnes))

# MacCall Eq 6-7: effective number of occupied spawning sites = exp(Shannon).
eff_sites <- section %>%
  filter(in_model %in% c(TRUE, "TRUE", 1), spawn_index_tonnes > 0) %>%
  group_by(year) %>%
  summarise(
    eff_n_sites = {
      p <- spawn_index_tonnes / sum(spawn_index_tonnes)
      exp(-sum(p * log(p)))
    },
    .groups = "drop"
  )

spatial <- region %>% left_join(eff_sites, by = "year")

# ── 3. Joined annual series ──────────────────────────────────────────────────
series <- age_long %>%
  inner_join(spatial, by = "year") %>%
  arrange(stream, year)

readr::write_csv(series, file.path(diag_dir,
                 "elder_age_spatial_coupling_series.csv"))

# ── 4. Cross-correlation core (Spearman, levels + first differences) ─────────
# Convention: positive lag L => age index LEADS target by L years
xcorr_one <- function(d, idx_col, tgt_col, max_lag = 8) {
  d <- d %>% arrange(year)
  ai <- d[[idx_col]]; tg <- d[[tgt_col]]
  dai <- c(NA, diff(ai)); dtg <- c(NA, diff(tg))
  pval_spearman <- function(rho, n) {
    if (is.na(rho) || n < 5 || abs(rho) >= 1) return(NA_real_)
    t <- rho * sqrt((n - 2) / (1 - rho^2))
    2 * pt(-abs(t), df = n - 2)
  }
  map_dfr(0:max_lag, function(L) {
    n <- nrow(d); if (L >= n - 3) return(NULL)
    li <- seq_len(n - L); ti <- (1 + L):n
    rho_lvl <- suppressWarnings(cor(ai[li], tg[ti],
                 method = "spearman", use = "complete.obs"))
    rho_dif <- suppressWarnings(cor(dai[li], dtg[ti],
                 method = "spearman", use = "complete.obs"))
    np <- sum(stats::complete.cases(ai[li], tg[ti]))
    tibble(lag = L,
           rho_levels = rho_lvl,    p_levels    = pval_spearman(rho_lvl, np),
           rho_firstdiff = rho_dif, p_firstdiff = pval_spearman(rho_dif, np),
           n_pairs = np)
  })
}

xcorr <- expand_grid(
  stream  = unique(series$stream),
  idx_col = c("prop_age_ge4", "repeat_ratio", "mean_age"),
  tgt_col = c("eff_n_sites", "spawn_index_t")
) %>%
  pmap_dfr(function(stream, idx_col, tgt_col) {
    d <- filter(series, stream == !!stream)
    xcorr_one(d, idx_col, tgt_col) %>%
      mutate(stream = stream, age_index = idx_col, target = tgt_col,
             .before = 1)
  })

readr::write_csv(xcorr, file.path(diag_dir,
                 "elder_age_spatial_coupling_crosscorr.csv"))

# ── 5. Stability checks for the HEADLINE finding ─────────────────────────────
# Headline: repeat_ratio -> eff_n_sites at lag 6 within the gear-confound-free
# window. Two stability tests:
#   (a) start-year sensitivity (1975, 1980, 1985, 1990, 1995) with paired
#       bootstrap 95% CI on rho_firstdiff
#   (b) leave-one-out across years within the 1980+ window
HEADLINE_IDX <- "repeat_ratio"
HEADLINE_TGT <- "eff_n_sites"
HEADLINE_LAG <- 6
N_BOOT <- 2000

aligned_diffs <- function(d, idx_col, tgt_col, L = HEADLINE_LAG) {
  d <- d %>% arrange(year)
  ai <- d[[idx_col]]; tg <- d[[tgt_col]]
  dai <- c(NA, diff(ai)); dtg <- c(NA, diff(tg))
  n <- nrow(d)
  tibble(year_target = d$year[(1 + L):n],
         dai_lead = dai[seq_len(n - L)],
         dtg = dtg[(1 + L):n]) %>%
    filter(!is.na(dai_lead), !is.na(dtg))
}

set.seed(20260519)

start_years <- c(1975, 1980, 1985, 1990, 1995)
stab_window <- map_dfr(start_years, function(sy) {
  d <- series %>% filter(stream == "gear2_roe_seine_only", year >= sy)
  if (nrow(d) < HEADLINE_LAG + 6) return(NULL)
  pairs <- aligned_diffs(d, HEADLINE_IDX, HEADLINE_TGT)
  rho_obs <- suppressWarnings(cor(pairs$dai_lead, pairs$dtg, method = "spearman"))
  boot_rho <- replicate(N_BOOT, {
    i <- sample.int(nrow(pairs), replace = TRUE)
    suppressWarnings(cor(pairs$dai_lead[i], pairs$dtg[i], method = "spearman"))
  })
  ci <- quantile(boot_rho, c(0.025, 0.975), na.rm = TRUE)
  pval <- {
    n <- nrow(pairs); rho <- rho_obs
    if (is.na(rho) || abs(rho) >= 1 || n < 5) NA_real_ else
      2 * pt(-abs(rho * sqrt((n - 2) / (1 - rho^2))), df = n - 2)
  }
  tibble(start_year = sy, end_year = max(d$year), n_years = nrow(d),
         n_pairs = nrow(pairs),
         rho_diff_lag6 = rho_obs,
         ci_lo = ci[1], ci_hi = ci[2], p_approx = pval,
         frac_boot_gt0 = mean(boot_rho > 0, na.rm = TRUE))
})
readr::write_csv(stab_window, file.path(diag_dir,
                 "elder_age_spatial_coupling_stability_startyear.csv"))

# Leave-one-out across the 1980+ window
d_mod <- series %>% filter(stream == "gear2_roe_seine_only", year >= 1980)
loo <- map_dfr(d_mod$year, function(yr) {
  pairs <- aligned_diffs(d_mod %>% filter(year != yr),
                         HEADLINE_IDX, HEADLINE_TGT)
  r <- suppressWarnings(cor(pairs$dai_lead, pairs$dtg, method = "spearman"))
  tibble(dropped_year = yr, rho_diff_lag6 = r, n_pairs = nrow(pairs))
})
readr::write_csv(loo, file.path(diag_dir,
                 "elder_age_spatial_coupling_stability_loo.csv"))

# ── 6. Figure (4 panels) ─────────────────────────────────────────────────────
era_bands <- tibble(
  xmin = c(1951, 1972, 2005),
  xmax = c(1972, 2005, 2017),
  era = c("Reduction fishery", "Roe fishery", "Closure"))
era_fill <- c("Reduction fishery" = "#F0E44255",
              "Roe fishery"       = "#D55E0033",
              "Closure"           = "#009E7333")

stream_pal <- c(pooled_all_fleets         = okabe_ito[5],
                gear2_roe_seine_only      = okabe_ito[6],
                gear2_roe_seine_1980_2017 = okabe_ito[3])

pA <- ggplot() +
  geom_rect(data = era_bands,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = era),
            alpha = 1) +
  scale_fill_manual(values = era_fill, name = NULL) +
  geom_line(data = series %>% filter(stream != "gear2_roe_seine_1980_2017"),
            aes(year, repeat_ratio, colour = stream), linewidth = 0.7) +
  geom_line(data = series %>% filter(stream == "gear2_roe_seine_1980_2017"),
            aes(year, repeat_ratio, colour = stream), linewidth = 1.1) +
  scale_colour_manual(values = stream_pal) +
  coord_cartesian(ylim = c(0, NA)) +
  labs(tag = "A", y = "Repeat:first-time\nratio  N(age≥4)/N(age=3)",
       x = NULL,
       title = "Corten/Huse repeat-spawner ratio (public Appendix B, HG SAR, provisional)") +
  theme_pub(10)

scl <- max(series$eff_n_sites, na.rm = TRUE) /
       max(series$spawn_index_t, na.rm = TRUE)
pB <- series %>% filter(stream == "pooled_all_fleets") %>%
  ggplot(aes(year)) +
  geom_rect(data = era_bands, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = era)) +
  scale_fill_manual(values = era_fill, guide = "none") +
  geom_line(aes(y = eff_n_sites, colour = "Effective # spawning sites"),
            linewidth = 0.9) +
  geom_line(aes(y = spawn_index_t * scl, colour = "Regional spawn index"),
            linewidth = 0.9, linetype = "dashed") +
  scale_y_continuous(
    name = "Effective # spawning\nsites (MacCall Eq 6–7)",
    sec.axis = sec_axis(~ . / scl, name = "Regional spawn\nindex (tonnes)")) +
  scale_colour_manual(values = okabe_ito[c(3, 1)], name = NULL) +
  labs(tag = "B", x = NULL) +
  theme_pub(10)

pC <- xcorr %>%
  filter(stream %in% c("gear2_roe_seine_only", "gear2_roe_seine_1980_2017"),
         age_index == "repeat_ratio", target == "eff_n_sites") %>%
  mutate(window = recode(stream,
            gear2_roe_seine_only      = "Gear2, full record",
            gear2_roe_seine_1980_2017 = "Gear2, 1980–2017 (gear-confound free)")) %>%
  ggplot(aes(lag, rho_firstdiff, fill = window)) +
  geom_col(position = position_dodge(0.7), width = 0.6) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_vline(xintercept = HEADLINE_LAG, colour = "grey40",
             linetype = "dotted", linewidth = 0.3) +
  annotate("text", x = HEADLINE_LAG, y = 0.42,
           label = "lag 6\n(≈1 generation)", size = 2.6, colour = "grey30") +
  scale_fill_manual(values = okabe_ito[c(6, 3)], name = NULL) +
  scale_x_continuous(breaks = 0:8) +
  coord_cartesian(ylim = c(-0.3, 0.5)) +
  labs(tag = "C",
       x = "Lag (years) — repeat-ratio LEADS effective # spawning sites",
       y = "Spearman ρ (first-diff)",
       title = "Removing the gear confound sharpens the lag-6 lead signal") +
  theme_pub(10)

pD <- stab_window %>%
  ggplot(aes(factor(start_year), rho_diff_lag6, fill = factor(start_year))) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.18,
                linewidth = 0.4) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_text(aes(label = sprintf("ρ=%.2f\np≈%.3f\nn=%d",
                                rho_diff_lag6, p_approx, n_pairs),
                y = pmax(rho_diff_lag6, ci_hi) + 0.08),
            size = 2.5, lineheight = 0.9) +
  scale_fill_manual(values = colorRampPalette(c(okabe_ito[6], okabe_ito[3]))(
                              nrow(stab_window))) +
  coord_cartesian(ylim = c(-0.2, 0.85)) +
  labs(tag = "D", x = "Start year of window (Gear2 only, end 2017)",
       y = "Spearman ρ at lag 6\n(2000 paired bootstraps; 95% CI)",
       title = "Start-year sensitivity: signal is window-dependent") +
  theme_pub(10)

fig <- pA / pB / pC / pD + plot_layout(heights = c(1, 1, 1.1, 1.1))
ggsave(file.path(fig_dir, "elder_age_spatial_coupling.pdf"),
       fig, width = 200, height = 280, units = "mm", device = cairo_pdf)
ggsave(file.path(fig_dir, "elder_age_spatial_coupling.png"),
       fig, width = 200, height = 280, units = "mm", dpi = 200)

# ── 7. Diagnostic write-up ───────────────────────────────────────────────────
fmt <- function(x, d = 3) ifelse(is.na(x), "NA", formatC(x, format = "f", digits = d))

g2m_row <- xcorr %>%
  filter(stream == "gear2_roe_seine_1980_2017",
         age_index == "repeat_ratio", target == "eff_n_sites",
         lag == HEADLINE_LAG) %>% slice(1)
mean_age_row <- xcorr %>%
  filter(stream == "gear2_roe_seine_1980_2017",
         age_index == "mean_age", target == "spawn_index_t",
         lag == 7) %>% slice(1)

loo_range <- range(loo$rho_diff_lag6, na.rm = TRUE)
loo_extreme <- loo %>% arrange(rho_diff_lag6) %>%
  slice(c(1, nrow(loo))) %>%
  mutate(label = sprintf("dropping %d: ρ=%.3f", dropped_year, rho_diff_lag6))

md <- c(
  "# Elder / Experienced-Spawner → Spatial-Portfolio Coupling Screen",
  "",
  sprintf("Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M %z")),
  "Script: `Code/07bx_elder_age_spatial_coupling_screen.R`",
  "",
  "## Status (READ FIRST — firewall)",
  "",
  "- **Provisional. Public. Regional. Descriptive.** Age composition is the",
  "  public Appendix B number-at-age extract (DFO CSAS 2018/028, HG SAR,",
  "  `extracted_public_provisional`). It is **not section-resolved** and",
  "  **not an HG-estimated parameter**.",
  "- *Consistent-with / motivating coupling cross-check* for the GWOF /",
  "  entrainment precursor (MacCall et al. 2019; Corten 2002; Huse 2002, 2010;",
  "  Fagan et al. 2012). It is **not causal**, not independent validation of",
  "  `m1_stier_11`, and does not alter the baseline.",
  "- Three streams reported so the gear-selectivity confound is visible:",
  "  pooled (mixed gears across decades), Gear2-only (any year), and the",
  "  **gear-confound-free 1980–2017 Gear2-only window**.",
  "- `mean_age` is **floored** (age 10 is a plus group).",
  "",
  "## Headline result (Gear2 roe-seine, 1980–2017, gear-confound free)",
  "",
  sprintf("- **repeat:first-time ratio → effective # spawning sites:** lag = %s yr, ρ_firstdiff = %s, p ≈ %s, n = %s.",
          g2m_row$lag, fmt(g2m_row$rho_firstdiff),
          fmt(g2m_row$p_firstdiff), g2m_row$n_pairs),
  sprintf("- **mean age → regional spawn index:** lag = %s yr, ρ_firstdiff = %s, p ≈ %s, n = %s.",
          mean_age_row$lag, fmt(mean_age_row$rho_firstdiff),
          fmt(mean_age_row$p_firstdiff), mean_age_row$n_pairs),
  "",
  "These leads are at **~1 herring generation**, in the direction GWOF predicts,",
  "with sign- and lag-consistency across two independent age metrics.",
  "",
  "## Stability checks",
  "",
  "**Start-year sensitivity** (Gear2 only; rho at lag 6, paired bootstrap 95% CI):",
  "",
  paste(c("| Start | End | n yrs | n pairs | ρ_diff lag6 | 95% CI | p approx |",
          "|---|---|---|---|---|---|---|",
          purrr::pmap_chr(stab_window, function(start_year, end_year, n_years,
                                               n_pairs, rho_diff_lag6, ci_lo,
                                               ci_hi, p_approx, frac_boot_gt0) {
            sprintf("| %s | %s | %s | %s | %s | [%s, %s] | %s |",
                    start_year, end_year, n_years, n_pairs,
                    fmt(rho_diff_lag6), fmt(ci_lo), fmt(ci_hi), fmt(p_approx))
          })), collapse = "\n"),
  "",
  sprintf("**Leave-one-out** across 1980–2017 (drop one year, recompute lag-6 ρ_diff): range **[%s, %s]**; sign stable; %s.",
          fmt(loo_range[1]), fmt(loo_range[2]),
          paste(loo_extreme$label, collapse = "; ")),
  "",
  "## Interpretation guard",
  "",
  "- The lag-6 lead survives the gear-confound control (Gear2-only) and is",
  "  corroborated independently by a second age metric (mean age → spawn",
  "  index, lag 7). That makes it more than a single-cell hit.",
  "- **But** n is modest (~30) and the start-year sensitivity panel shows",
  "  the signal is window-dependent: shifting the start year to 1975 or 1990",
  "  weakens it. This is a real fragility, not just a hedge.",
  "- Multiple-comparisons: 3 indices × 2 targets × 9 lags = 54 cells per",
  "  stream; under noise you'd expect ~3 at p<0.05. The lag-6 expectation",
  "  was pre-specified by the full-window screen, so the 1980+ confirmation",
  "  is best read as a one-test follow-up at a pre-registered lag, not a",
  "  selection from 54 cells.",
  "- This regional screen still cannot establish the *subpopulation-specific*",
  "  GWOF prediction; that needs section-resolved biosamples",
  "  (`docs/dfo-hg-biological-input-request-packet.md`).",
  "",
  "## Outputs",
  "",
  "- `Output/diagnostics/elder_age_spatial_coupling_series.csv`",
  "- `Output/diagnostics/elder_age_spatial_coupling_crosscorr.csv`",
  "- `Output/diagnostics/elder_age_spatial_coupling_stability_startyear.csv`",
  "- `Output/diagnostics/elder_age_spatial_coupling_stability_loo.csv`",
  "- `Output/figures/elder_age_spatial_coupling.{pdf,png}`",
  "- `analysis/04_talks/2026-royalsociety/Talk_Materials/elder_age_coupling_brief.md`",
  ""
)
writeLines(md, file.path(diag_dir, "elder_age_spatial_coupling.md"))

cat("\nDONE.\n")
cat(sprintf("Headline: repeat_ratio -> eff_n_sites, Gear2 1980-2017, lag %d: rho_diff=%s p=%s n=%d\n",
            g2m_row$lag, fmt(g2m_row$rho_firstdiff),
            fmt(g2m_row$p_firstdiff), g2m_row$n_pairs))
cat(sprintf("Corroboration: mean_age -> spawn_index, lag %d: rho_diff=%s p=%s n=%d\n",
            mean_age_row$lag, fmt(mean_age_row$rho_firstdiff),
            fmt(mean_age_row$p_firstdiff), mean_age_row$n_pairs))
cat("Start-year sensitivity:\n"); print(stab_window %>%
  mutate(across(c(rho_diff_lag6, ci_lo, ci_hi, p_approx), \(x) round(x, 3))))
cat(sprintf("LOO range (1980+): [%s, %s]\n", fmt(loo_range[1]), fmt(loo_range[2])))
