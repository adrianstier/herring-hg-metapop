#!/usr/bin/env Rscript
# 12_reversibility_figs_render.R
# Render the 5 reversibility publication figures and companion legends.
# Called by Code/run_reversibility_suite.sh (last step).
# Also callable standalone: Rscript Code/12_reversibility_figs_render.R
#
# Output
#   Output/figures/reversibility_lambda_trajectory.{pdf,png}
#   Output/figures/reversibility_state_df.{pdf,png}
#   Output/figures/reversibility_potential.{pdf,png}
#   Output/figures/reversibility_driver_loop.{pdf,png}
#   Output/figures/reversibility_controls.{pdf,png}
#   Output/figures/legends/reversibility_*.md  (companion legend files)

suppressWarnings(suppressMessages({
  library(ggplot2)
  library(patchwork)
  library(ggrepel)
  library(here)
}))

# Source project setup (gives theme_pub, PAL)
source(here::here("R", "00_setup.R"))
# Source figure builders
source(here::here("R", "12_reversibility_figs.R"))

dir.create(here::here("Output", "figures"),          showWarnings = FALSE, recursive = TRUE)
dir.create(here::here("Output", "figures", "legends"), showWarnings = FALSE, recursive = TRUE)
dir.create(here::here("Output", "diagnostics"),       showWarnings = FALSE, recursive = TRUE)

# ── Helper: render one figure (PDF + PNG) ─────────────────────────────────
render_fig <- function(plot_obj, stem, width_mm, height_mm, dpi = 300) {
  pdf_path <- here::here("Output", "figures", paste0(stem, ".pdf"))
  png_path <- here::here("Output", "figures", paste0(stem, ".png"))

  ggplot2::ggsave(
    pdf_path, plot = plot_obj,
    width = width_mm, height = height_mm, units = "mm",
    dpi = dpi, device = grDevices::cairo_pdf
  )
  ggplot2::ggsave(
    png_path, plot = plot_obj,
    width = width_mm, height = height_mm, units = "mm",
    dpi = dpi
  )
  cat(sprintf("[render] %s  (%d x %d mm)\n", stem, width_mm, height_mm))
  invisible(list(pdf = pdf_path, png = png_path))
}

# ── Helper: write companion legend ─────────────────────────────────────────
write_legend <- function(stem, title, body) {
  path <- here::here("Output", "figures", "legends",
                     paste0(stem, "_legend.md"))
  txt <- paste0(
    "# Figure legend: ", stem, "\n\n",
    "**Title:** ", title, "\n\n",
    body, "\n"
  )
  writeLines(txt, path)
  cat(sprintf("[legend] %s\n", basename(path)))
  invisible(path)
}

# ============================================================================
# Figure 1: Lambda trajectory
# ============================================================================
cat("\n--- Fig 1: Lambda trajectory ---\n")
p1 <- fig_lambda_trajectory()
render_fig(p1, "reversibility_lambda_trajectory", width_mm = 170, height_mm = 120)

write_legend(
  "reversibility_lambda_trajectory",
  "Jacobian leading eigenvalue trajectory for HG herring latent biomass (1951-2025)",
  paste0(
    "Time-varying |lambda_max(t)| estimated by S-map (EDM) applied to ",
    "the m1_stier_11 all_11 latent biomass series. Central estimate (blue line) ",
    "with 80-percent posterior band (shaded) derived from the lo80/hi80 ",
    "biomass credible interval series. Dashed horizontal line at 1.0 marks ",
    "the neutral stability threshold. Dotted vertical line marks the 2005 ",
    "moratorium closure. Post-closure annotation: lambda_max failed to relax ",
    "(slope = +0.0136, n~20 post-closure observations); this is consistent with ",
    "a slow transient return and with persistence near a high-biomass state -- ",
    "mechanism is not adjudicable. S-map nonlinearity (S-map theta test) is ",
    "non-significant at n~75 (nl_p = 0.261, SECONDARY; underpowered in this regime). ",
    "Hysteresis and long_transient verdicts are INDETERMINATE."
  )
)

# ============================================================================
# Figure 2: State vs effective driver
# ============================================================================
cat("\n--- Fig 2: State vs effective driver ---\n")
p2 <- fig_state_dependent_dF()
render_fig(p2, "reversibility_state_df", width_mm = 170, height_mm = 140)

write_legend(
  "reversibility_state_df",
  "Latent biomass vs composite effective driver: HG herring 1951-2024",
  paste0(
    "Scatter / trajectory plot of m1_stier_11 all_11 latent biomass (kt) against ",
    "the composite effective driver (z-scored sum of fishing exploitation rate u, ",
    "predation pressure index, and PDO spring index). Orange = down-limb (fished, ",
    "<=2005); blue = up-limb (post-closure, >2005). Dashed vertical lines mark ",
    "the roe-era reference composite median (0.149, orange) and the recent (>=2015) ",
    "composite median (-0.155, blue). The recent median is below the roe-era reference, ",
    "so the gate effective_driver_returned = TRUE, refuting the unreturned_driver ",
    "explanation. CAVEAT: this verdict depends on the composite reconstruction ",
    "(fishing + predation + PDO) and on the reference window (roe era 1972-2004). ",
    "Window sensitivity is shown in the annotation: 5 of 8 candidate windows return ",
    "the same verdict; 3 pre-roe anchors flip it. The predation component is ",
    "context-only provenance (not model-validated); the PDO component represents ",
    "climate variability. unreturned_driver = REFUTED (composite-dependent)."
  )
)

# ============================================================================
# Figure 3: Potential landscape (pre + "not estimable" post)
# ============================================================================
cat("\n--- Fig 3: Potential landscape ---\n")
p3 <- fig_potential_pre_post()
render_fig(p3, "reversibility_potential", width_mm = 183, height_mm = 120)

write_legend(
  "reversibility_potential",
  "Potential landscape U(x): pre-closure (estimated) and post-closure (not estimable)",
  paste0(
    "Left panel (A): Empirical potential landscape U(x) estimated from the m1_stier_11 ",
    "all_11 latent biomass series for the pre-closure era (1951-2005, n=55 obs). ",
    "A single shallow potential well is visible near ~23 kt. Orange diamond marks ",
    "the minimum. Right panel (B): Post-closure era (>2005, n~20 obs) is NOT ESTIMABLE -- ",
    "the potential_landscape() estimator returned its degenerate contract (NA) due to ",
    "insufficient post-closure observations. This indeterminate result should NOT be ",
    "interpreted as evidence against a second potential well. The absence of a second-well ",
    "estimate is a measurement gap, not a negative finding. Both hysteresis and ",
    "long_transient verdicts depend on the new_potential_well criterion, which is ",
    "NA; both verdicts are therefore INDETERMINATE via the any-NA short-circuit in ",
    "discrimination_table(). No confident hysteresis-or-no-hysteresis claim is warranted."
  )
)

# ============================================================================
# Figure 4: Driver-state non-retracing loop
# ============================================================================
cat("\n--- Fig 4: Driver-state loop ---\n")
p4 <- fig_driver_loop()
render_fig(p4, "reversibility_driver_loop", width_mm = 170, height_mm = 140)

write_legend(
  "reversibility_driver_loop",
  "Driver x state non-retracing loop: HG herring 1951-2024 (loop_p = 0.002)",
  paste0(
    "Exploitation rate u (= catch / latent biomass, y-axis as driver) versus ",
    "m1_stier_11 all_11 latent spawning biomass (kt, y-axis as state). ",
    "Orange = down-limb (fished, 1951-2005); blue = up-limb (post-closure, ",
    "2006-2024). The path does not retrace: at comparable low driver values ",
    "post-closure, the state sits below its pre-collapse trajectory. The signed ",
    "loop area is statistically distinguishable from the survey-artifact null ",
    "(loop_null_p = 0.002; 500-replicate permutation test, q=[0.6,1.0]). ",
    "This non-retracing geometry is CONSISTENT WITH hysteresis but does not ",
    "prove a fold bifurcation. Alternative explanations (slow transient recovery, ",
    "composite-driver residual, age-structure lag) are not excluded. ",
    "Mechanism is NOT adjudicable from this test alone. ",
    "hysteresis verdict = INDETERMINATE."
  )
)

# ============================================================================
# Figure 5: Controls panel
# ============================================================================
cat("\n--- Fig 5: Controls panel ---\n")
p5 <- fig_controls_panel()
render_fig(p5, "reversibility_controls", width_mm = 183, height_mm = 130)

write_legend(
  "reversibility_controls",
  "Controls calibration: PRIMARY eigenvalue trend and S-map nonlinearity",
  paste0(
    "Panel A (PRIMARY control): Bar chart of the pre-closure lambda_max trend slope ",
    "across 12 random seeds. The PRIMARY gate is lambda_trend > 0 (positive eigenvalue ",
    "trend consistent with critical slowing down approaching a fold). 9/12 seeds pass ",
    "(75 percent pass rate). The canonical seed 20260519 (green bar) passes (slope = +0.002). ",
    "Seeds 2, 7, and 99 fail. Non-zero exit (status=1) fires if the canonical-seed PRIMARY ",
    "fails; the gate passed for this analysis run. ",
    "Panel B (SECONDARY, not a gate): S-map nonlinearity p-values for four state series at ",
    "n~75. All four are non-significant (nl_p range: 0.044-1.0). The biomass_all11_lo80 ",
    "marginal result (p=0.044) is the only near-threshold entry. This non-significance is ",
    "consistent with a documented power limit in slow-passage, slow-transition regimes at ",
    "n~70; it is a genuine measurement, not a refutation of nonlinearity. ",
    "The S-map theta test is reported as SECONDARY and never used as a hard pass/fail gate."
  )
)

cat("\n=== All 5 figures rendered. ===\n")

# Remove stray Rplots.pdf if created
invisible(file.remove(list.files(".", pattern = "^Rplots.*\\.pdf$", full.names = TRUE)))
