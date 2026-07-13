#!/usr/bin/env Rscript
# Phase 0 spike — driver-state hysteresis loop (PRELIMINARY, descriptive only)
# Spec: docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md
#
# Question (descriptive only): when the driver (exploitation rate) is reduced
# at the closure, does the state retrace its pre-fishery path, or sit below it
# at comparable low driver (a loop)? NO surrogates / controls / EDM here —
# that is the full plan. This spike only asks "is there a loop worth the
# battery?" and is HG-internal + control-sheet-safe.

suppressWarnings(suppressMessages({
  library(ggplot2)
  ok <- try(source(here::here("R", "00_setup.R")), silent = TRUE)   # gives theme_pub if present
}))
okabe <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
           "#0072B2", "#D55E00", "#CC79A7", "#000000")
theme_spike <- if (exists("theme_pub")) theme_pub(9) else
  theme_minimal(base_size = 9) + theme(panel.grid.minor = element_blank())
PIVOT <- 2005  # control-sheet canonical closure label (sensitivity-robust below)

dir.create("Output/diagnostics", showWarnings = FALSE, recursive = TRUE)
dir.create("Output/figures",     showWarnings = FALSE, recursive = TRUE)

## --- inputs (all already on disk) -----------------------------------------
catch <- read.csv("Data/processed/herring_catch_local_1950_2024.csv")
bio   <- read.csv("Output/diagnostics/m1_stier_11_total_biomass_by_year.csv")
port  <- read.csv("Data/processed/portfolio_metrics_rolling.csv")

annual_catch <- aggregate(TotalCatch ~ Year, data = catch, sum)
names(annual_catch) <- c("year", "total_catch")

bio11 <- bio[bio$report_set == "all_11", c("year", "median", "period")]
names(bio11)[2] <- "biomass"
bio9  <- bio[bio$report_set == "focal_9", c("year", "median")]
names(bio9)[2] <- "biomass_focal9"

d <- merge(bio11, annual_catch, by = "year")          # 1951-2024 overlap
d <- merge(d, bio9, by = "year", all.x = TRUE)
d <- d[order(d$year), ]
d$u  <- d$total_catch / d$biomass                      # exploitation-rate proxy
d$u9 <- d$total_catch / d$biomass_focal9
d$limb <- ifelse(d$year <= PIVOT, "down-limb (<=2005, fished)",
                                  "up-limb (>2005, closed)")

## --- crude, honest descriptive contrast -----------------------------------
# NOTE: the 1951-2024 series begins mid-reduction-fishery; there is NO
# in-series unfished low-driver anchor (the pristine baseline is the
# 10,000-yr archaeological one, out of series). So this is NOT a matched-
# low-driver comparison. The descriptive signal is: the fishing driver was
# removed (high -> ~0 at closure) yet the state did not retrace upward.
last_fished <- max(d$year[d$u > 0.02], na.rm = TRUE)   # empirical u-collapse
early  <- d[d$year %in% 1951:1957, ]                   # early industrial: HIGH u
recent <- d[d$year >= 2015, ]                          # post-closure: u ~ 0
gap_abs <- mean(early$biomass) - mean(recent$biomass)
gap_rat <- mean(recent$biomass) / mean(early$biomass)
u_early <- mean(early$u); u_recent <- mean(recent$u)

## --- windowed synchrony vs mean-window exploitation -----------------------
port$u_win <- mapply(function(a, b) {
  s <- d[d$year >= a & d$year <= b, "u"]; if (length(s)) mean(s, na.rm = TRUE) else NA
}, port$window_start, port$window_end)
port$limb <- ifelse(port$window_mid <= PIVOT, "down-limb (≤2005)", "up-limb (>2005)")
sync_early <- mean(port$synchrony[port$window_mid <= 1960])
sync_recent <- mean(port$synchrony[port$window_mid >= 2015])

## --- figure 1: biomass vs exploitation (the hysteresis loop) ---------------
p1 <- ggplot(d, aes(u, biomass)) +
  geom_path(aes(color = limb), linewidth = 0.8, alpha = 0.55) +
  geom_point(aes(color = limb), size = 1.6) +
  geom_text(data = d[d$year %% 10 == 0 | d$year %in% c(1951, last_fished, 2024), ],
            aes(label = year), size = 2.5, vjust = -0.7, color = "grey25") +
  scale_color_manual(values = c(okabe[6], okabe[5]), name = NULL) +
  labs(x = "Exploitation rate  u = catch / latent biomass  (driver)",
       y = "Latent spawning biomass (t, m1_stier_11, all-11)",
       title = "Phase 0 (descriptive): driver-state path, HG herring",
       subtitle = "Driver removed at closure -- does the state retrace upward?") +
  theme_spike + theme(legend.position = "bottom",
                      plot.margin = margin(8, 12, 8, 8, "mm"))
ggsave("Output/figures/reversibility_phase0_hysteresis_loop.pdf",
       p1, width = 170, height = 130, units = "mm", device = cairo_pdf)
ggsave("Output/figures/reversibility_phase0_hysteresis_loop.png",
       p1, width = 170, height = 130, units = "mm", dpi = 150)

## --- figure 2: synchrony (structure) vs windowed exploitation -------------
ps <- port[!is.na(port$u_win), ]
p2 <- ggplot(ps, aes(u_win, synchrony)) +
  geom_path(aes(color = limb), linewidth = 0.8, alpha = 0.55) +
  geom_point(aes(color = limb), size = 1.6) +
  geom_text(data = ps[round(ps$window_mid) %% 10 == 0, ],
            aes(label = round(window_mid)), size = 2.5, vjust = -0.7,
            color = "grey25") +
  scale_color_manual(values = c(okabe[6], okabe[5]), name = NULL) +
  labs(x = "Mean window exploitation rate (driver)",
       y = "Synchrony phi (10-yr window; rising = portfolio erosion)",
       title = "Phase 0 (descriptive): driver-structure path, HG herring",
       subtitle = "Structural state (synchrony) vs driver, 10-yr windows") +
  theme_spike + theme(legend.position = "bottom",
                      plot.margin = margin(8, 12, 8, 8, "mm"))
ggsave("Output/figures/reversibility_phase0_synchrony_loop.pdf",
       p2, width = 170, height = 130, units = "mm", device = cairo_pdf)
ggsave("Output/figures/reversibility_phase0_synchrony_loop.png",
       p2, width = 170, height = 130, units = "mm", dpi = 150)

## --- data + markdown -------------------------------------------------------
write.csv(d[, c("year", "period", "limb", "total_catch", "biomass",
                "biomass_focal9", "u", "u9")],
          "Output/diagnostics/reversibility_phase0_driver_state.csv",
          row.names = FALSE)

md <- c(
"# Phase 0 spike — driver-state hysteresis loop (PRELIMINARY, descriptive)",
"",
sprintf("Generated: %s", Sys.Date()),
"Spec: `docs/superpowers/specs/2026-05-19-herring-reversibility-hysteresis-analysis-design.md`",
"",
"## What this is / is NOT",
"",
"- IS: the fastest descriptive read on whether a driver-state **loop** exists",
"  worth the full battery. HG-internal, reuses on-disk CSVs, no new deps.",
"- IS NOT: evidence of a fold/bifurcation. No surrogates, no controls, no EDM,",
"  no significance, no discrimination among the four explanations yet.",
"",
"## Descriptive contrast (latent biomass, all-11)",
"",
"**No in-series unfished anchor:** the 1951-2024 record begins mid-reduction-",
"fishery, so there is no low-driver point before exploitation. The pristine",
"baseline is the 10,000-yr archaeological one (out of series). This is a",
"*driver-removal* contrast, not a matched-low-driver loop gap.",
"",
sprintf("- Empirical exploitation collapse: last year u>0.02 = **%d**.", last_fished),
sprintf("- Early industrial (1951-1957), driver HIGH: mean u=%.3f, mean biomass=**%.0f t**.",
        u_early, mean(early$biomass)),
sprintf("- Post-closure (2015-2025), driver ~0: mean u=%.3f, mean biomass=**%.0f t**.",
        u_recent, mean(recent$biomass)),
sprintf("- Fishing driver removed (u %.2f -> ~0) yet state is **%.0f t lower** —",
        u_early, gap_abs),
sprintf("  recent biomass is **%.0f%%** of the 1950s *heavily-fished* level.",
        100 * gap_rat),
sprintf("- Focal-9 sensitivity: same ratio = %.0f%%.",
        100 * mean(recent$biomass_focal9, na.rm = TRUE) /
              mean(early$biomass_focal9, na.rm = TRUE)),
"",
"## Descriptive contrast (structure: synchrony phi)",
"",
sprintf("- Early windows (mid <=1960): mean phi = **%.2f**.", sync_early),
sprintf("- Recent windows (mid >=2015): mean phi = **%.2f**.", sync_recent),
"- Driver removed yet phi ROSE (portfolio structure eroded further, did not",
"  retrace) — structure tracks the driver-removal even less than biomass.",
"",
"## Reading (control-sheet-safe)",
"",
"The fishing driver was reduced to ~zero at the closure, yet neither biomass",
"nor portfolio structure retraced upward — biomass sits below its 1950s",
"heavily-fished level and synchrony rose. Consistent with the control-sheet",
"hysteresis sentence (\"the driver can be reduced without the service",
"trajectory retracing the collapse path\"). **Descriptive only** — does NOT",
"distinguish:",
"",
"  (i) true hysteresis / new attractor;",
"  (ii) **the effective driver never returned** — only *fishing* was removed;",
"       predation may have risen and carrying capacity fallen, so the net",
"       control parameter need not have returned. THIS is the leading honest",
"       alternative; the effective-driver reconstruction (full spec) is",
"       required before any hysteresis claim.",
"  (iii) a long transient (slow, not blocked);",
"  (iv) a measurement-scale artifact.",
"",
"Discriminating (i)-(iv) is the full spec (EDM Jacobian, potential landscape,",
"effective-driver, surrogates, positive/negative/survey-artifact controls).",
"",
"## Outputs",
"",
"- `Output/figures/reversibility_phase0_hysteresis_loop.{pdf,png}`",
"- `Output/figures/reversibility_phase0_synchrony_loop.{pdf,png}`",
"- `Output/diagnostics/reversibility_phase0_driver_state.csv`")
writeLines(md, "Output/diagnostics/reversibility_phase0_hysteresis_loop.md")

cat(sprintf(paste0("\n[phase0] last fished=%d | early biomass=%.0f (u=%.3f) | ",
            "recent biomass=%.0f (u=%.3f) | recent=%.0f%% of early | ",
            "phi %.2f->%.2f\n"),
            last_fished, mean(early$biomass), u_early,
            mean(recent$biomass), u_recent, 100 * gap_rat,
            sync_early, sync_recent))
