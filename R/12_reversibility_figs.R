# ============================================================================
# 12_reversibility_figs.R
# Publication figure builders for the reversibility / hysteresis analysis
# stier-2027-herring-metapopulation
#
# Each function is pure (reads CSVs, returns ggplot object, writes nothing).
# Rendering + companion legends are handled by Code/12_reversibility_figs_render.R
# _targets.R wires each function into a file-format target.
#
# Figure inventory
#   fig_lambda_trajectory()    -- |lambda_max(t)| with post-closure annotation
#   fig_state_dependent_dF()   -- biomass x effective_driver scatter + window sensitivity
#   fig_potential_pre_post()   -- U(x) pre-closure; post-closure "not estimable" panel
#   fig_driver_loop()          -- driver x state non-retracing loop (loop_p=0.002)
#   fig_controls_panel()       -- multi-seed PRIMARY pass-rate + n~70 nonlinearity finding
#
# Style contract
#   theme_pub(9)  from R/00_setup.R  (single source of truth)
#   Okabe-Ito palette: PAL$okabe_ito from R/00_setup.R
#   No minor gridlines (enforced by theme_pub)
#   Legend outside data area (position = "bottom")
#   cairo_pdf export, explicit mm dims (in render script)
#   ASCII-safe labels: no unicode phi / lambda / <= / >=
#     plotmath via expression() OK under cairo_pdf where tested
#
# Claim-safety contract (MANDATORY -- see docs/talk-model-claim-control-sheet.md)
#   NEVER render: "the system tipped", "hysteresis confirmed", "hysteresis refuted",
#                 "proves a fold", "caused by predators"
#   Indeterminate verdicts MUST be labelled as indeterminate
#   Post-closure potential landscape MUST show "not estimable (n~20)" not a fake well
# ============================================================================

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

.rev_okabe <- function() {
  c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
    "#0072B2", "#D55E00", "#CC79A7", "#000000")
}

.rev_theme <- function(base_size = 9) {
  # Use repo theme_pub if available; fall back to a clean equivalent
  if (exists("theme_pub", mode = "function")) {
    theme_pub(base_size = base_size)
  } else {
    ggplot2::theme_minimal(base_size = base_size) +
      ggplot2::theme(
        panel.grid.minor  = ggplot2::element_blank(),
        panel.grid.major  = ggplot2::element_line(color = "grey90", linewidth = 0.3),
        axis.line         = ggplot2::element_line(color = "grey30", linewidth = 0.4),
        axis.ticks        = ggplot2::element_line(color = "grey30", linewidth = 0.3),
        strip.text        = ggplot2::element_text(face = "bold", size = ggplot2::rel(0.9)),
        plot.margin       = ggplot2::margin(10, 10, 10, 10, "mm"),
        legend.position   = "bottom"
      )
  }
}

.diag_path <- function(filename) {
  here::here("Output", "diagnostics", filename)
}

# ---------------------------------------------------------------------------
# Fig 1: |lambda_max(t)| trajectory
# ---------------------------------------------------------------------------

#' Jacobian eigenvalue trajectory with post-closure annotation
#'
#' Shows the time-varying |lambda_max| for biomass_all11 (central estimate)
#' with 80-pct posterior band (lo80/hi80), vertical line at the 2005 closure,
#' and annotation that the post-closure trend has NOT relaxed (honest).
#'
#' @return ggplot object
fig_lambda_trajectory <- function() {
  okabe <- .rev_okabe()
  thm   <- .rev_theme(9)

  raw <- utils::read.csv(.diag_path("reversibility_edm_jacobian_eigen.csv"),
                         stringsAsFactors = FALSE)

  # Central (all11), focal9 band proxy, and lo80/hi80 posterior band
  central <- raw[raw$state == "biomass_all11",     c("year", "lambda_max")]
  lo80    <- raw[raw$state == "biomass_all11_lo80", c("year", "lambda_max")]
  hi80    <- raw[raw$state == "biomass_all11_hi80", c("year", "lambda_max")]

  names(central)[2] <- "lam"
  names(lo80)[2]    <- "lam_lo"
  names(hi80)[2]    <- "lam_hi"

  d <- merge(central, lo80, by = "year", all = TRUE)
  d <- merge(d, hi80,       by = "year", all = TRUE)
  d <- d[order(d$year), ]
  d <- d[!is.na(d$lam), ]

  # Post-closure subset for trend annotation
  post <- d[d$year > 2005, ]
  # Slope direction from linear model
  sl <- if (nrow(post) > 2) {
    coef(lm(lam ~ year, data = post))["year"]
  } else NA_real_

  # Annotation: honest -- failed to relax
  ann_txt <- paste0(
    "Post-closure trend: slope = +",
    formatC(round(sl, 4), format = "f", digits = 4),
    "\n(lambda_max failed to relax, n~20;\nconsistent with slow transient OR persistence)"
  )

  # Annotation y: held at 1.46 (within coord_cartesian ylim 0.70..1.52, well
  # above the current data ceiling 1.39). coord_cartesian warns rather than
  # silently dropping if future data exceeds the cap. Hardcoded here so the
  # annotation does not collide with post-closure data points.
  ann_y <- 1.46

  ggplot(d, aes(x = year)) +
    # 80-pct band
    geom_ribbon(aes(ymin = lam_lo, ymax = lam_hi),
                fill = okabe[2], alpha = 0.18, na.rm = TRUE) +
    # Central line
    geom_line(aes(y = lam), color = okabe[2], linewidth = 0.8, na.rm = TRUE) +
    geom_point(aes(y = lam), color = okabe[2], size = 1.2, na.rm = TRUE) +
    # Reference line at 1.0 (neutral stability)
    geom_hline(yintercept = 1, linetype = "dashed", color = "grey50", linewidth = 0.5) +
    # Closure
    geom_vline(xintercept = 2005, linetype = "dotted", color = "grey30", linewidth = 0.6) +
    # Post-closure annotation -- short text, left-justified inside post-closure region
    annotate("text", x = 2006.5, y = ann_y,
             label = paste0(
               "Post-closure: slope = +",
               formatC(round(sl, 4), format = "f", digits = 4),
               "\n|lambda_max| failed to relax (n~20)"
             ),
             hjust = 0, vjust = 1, size = 2.0, color = "grey20",
             lineheight = 1.1) +
    annotate("text", x = 2004.5, y = 0.74,
             label = "2005\nclosure", hjust = 1, vjust = 0,
             size = 2.1, color = "grey35") +
    # S-map note -- bottom left
    annotate("text", x = min(d$year), y = 0.74,
             label = "S-map: n.s. at n~75 (SECONDARY)",
             hjust = 0, vjust = 0, size = 1.9, color = "grey45", lineheight = 1.1) +
    scale_x_continuous(breaks = seq(1950, 2030, 10), limits = c(1950, 2026)) +
    scale_y_continuous() +
    coord_cartesian(ylim = c(0.70, 1.52)) +
    labs(
      x = "Year",
      y = "|lambda_max(t)|  (Jacobian leading eigenvalue)",
      title = "Jacobian eigenvalue trajectory: HG herring latent biomass",
      subtitle = paste0("Central (m1_stier_11 all_11) + 80-pct posterior band | ",
                        "dashed = 1.0 (neutral); dotted = 2005 closure"),
      caption = paste0(
        "Post-closure trend consistent with slow transient return OR persistence near high-biomass state;\n",
        "mechanism not adjudicable. S-map nonlinearity n.s. at n~75 (underpowered; SECONDARY only).\n",
        "Hysteresis and long_transient verdicts = INDETERMINATE."
      )
    ) +
    thm +
    theme(legend.position = "none",
          plot.margin   = ggplot2::margin(10, 12, 10, 10, "mm"),
          plot.subtitle = element_text(size = rel(0.78)),
          plot.caption  = element_text(size = 6.5, color = "grey40",
                                       hjust = 0, lineheight = 1.2))
}


# ---------------------------------------------------------------------------
# Fig 2: State vs effective driver (dF-style scatter + window sensitivity)
# ---------------------------------------------------------------------------

#' Biomass vs effective driver with window-sensitivity annotation
#'
#' Shows the composite effective_driver vs latent biomass, coloured by limb
#' (down = fished, up = post-closure), and a small inset table of window
#' sensitivity showing which reference windows flip the gate.
#'
#' @return ggplot object
fig_state_dependent_dF <- function() {
  okabe <- .rev_okabe()
  thm   <- .rev_theme(9)

  drv  <- utils::read.csv(.diag_path("reversibility_effective_driver.csv"),
                           stringsAsFactors = FALSE)
  axis <- utils::read.csv(.diag_path("reversibility_driver_axis.csv"),
                           stringsAsFactors = FALSE)

  d <- merge(drv, axis[, c("year", "biomass", "limb", "period")], by = "year")
  d <- d[order(d$year), ]

  # Limb label for legend
  d$limb_label <- ifelse(d$limb == "down_limb",
                         "Down-limb (fished, <=2005)",
                         "Up-limb (post-closure, >2005)")

  # Reference lines: roe-era composite median and recent composite median
  med_ref    <-  0.149   # roe era 1972-2004
  med_recent <- -0.155   # recent >=2015

  # Window sensitivity caption
  win_caption <- paste0(
    "Window sensitivity: PRIMARY (roe era 1972-2004) ref=0.149 -> returned=TRUE [REFUTED].\n",
    "Pre-roe anchors (1951-1965, 1951-1972, 1960-1975) flip gate to NOT refuted.\n",
    "Verdict robust to all defensible windows from 1972 onward. Composite-dependent (fishing + predation + PDO)."
  )

  ggplot(d, aes(x = effective_driver, y = biomass / 1000)) +
    # Trajectory path
    geom_path(aes(color = limb_label), linewidth = 0.5, alpha = 0.5) +
    geom_point(aes(color = limb_label), size = 1.4, alpha = 0.8) +
    # Year labels for decade endpoints only -- fewer labels for legibility
    ggrepel::geom_text_repel(
      data = d[d$year %% 10 == 0 | d$year %in% c(1951, 2005, 2024), ],
      aes(label = year), size = 2.1, color = "grey25",
      max.overlaps = 10, segment.size = 0.2, box.padding = 0.2,
      force = 1.5
    ) +
    # Reference lines for the two key composite medians
    geom_vline(xintercept = med_ref,    linetype = "dashed", color = okabe[6],
               linewidth = 0.6, alpha = 0.7) +
    geom_vline(xintercept = med_recent, linetype = "dashed", color = okabe[5],
               linewidth = 0.6, alpha = 0.7) +
    annotate("text", x = med_ref + 0.05, y = max(d$biomass / 1000, na.rm = TRUE),
             label = "roe-era\nref=0.149", hjust = 0, vjust = 1,
             size = 2.2, color = okabe[6]) +
    annotate("text", x = med_recent - 0.05, y = max(d$biomass / 1000, na.rm = TRUE),
             label = "recent\nmed=-0.155", hjust = 1, vjust = 1,
             size = 2.2, color = okabe[5]) +
    scale_color_manual(values = c(okabe[6], okabe[5]), name = NULL) +
    labs(
      x = "Composite effective driver (z-score; fishing + predation + PDO)",
      y = "Latent biomass (kt, m1_stier_11, all_11)",
      title = "State vs composite driver: HG herring",
      subtitle = "unreturned_driver = REFUTED (composite-dependent; roe-era PRIMARY ref=0.149, recent=-0.155)",
      caption = win_caption
    ) +
    thm +
    theme(legend.position = "bottom",
          plot.margin   = ggplot2::margin(10, 12, 10, 10, "mm"),
          plot.subtitle = element_text(size = rel(0.78)),
          plot.caption  = element_text(size = 6.5, color = "grey40",
                                       hjust = 0, lineheight = 1.2))
}


# ---------------------------------------------------------------------------
# Fig 3: Potential landscape (pre only; post = "not estimable")
# ---------------------------------------------------------------------------

#' Pre-closure potential landscape + honest "post-closure not estimable" panel
#'
#' Left panel: U(x) for the pre-closure era (n=55 usable observations).
#' Right panel: Explicit "not estimable at n~20" message -- no fake well.
#'
#' @return patchwork ggplot object
fig_potential_pre_post <- function() {
  okabe <- .rev_okabe()
  thm   <- .rev_theme(9)

  raw <- utils::read.csv(.diag_path("reversibility_potential_landscape_pre_post.csv"),
                          stringsAsFactors = FALSE)

  pre  <- raw[!is.na(raw$U) & raw$era == "pre_closure_<=2005", ]
  pre  <- pre[order(pre$x), ]

  # Panel A: pre-closure U(x)
  pa <- ggplot(pre, aes(x = x / 1000, y = U)) +
    geom_line(color = okabe[1], linewidth = 1) +
    geom_point(data = pre[pre$is_minimum, ],
               aes(x = x / 1000, y = U),
               color = okabe[6], size = 3, shape = 18) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60", linewidth = 0.4) +
    annotate("text", x = pre$x[pre$is_minimum] / 1000,
             y = pre$U[pre$is_minimum] - 0.4,
             label = paste0("min at ~",
                            round(pre$x[pre$is_minimum] / 1000, 0), " kt"),
             size = 2.4, color = okabe[6], hjust = 0.5) +
    labs(
      x = "Latent biomass (kt)",
      y = "U(x)  (potential)",
      title = "A  Pre-closure potential landscape",
      subtitle = "1951-2005 (n=55 obs); single shallow well"
    ) +
    thm +
    theme(legend.position = "none",
          plot.subtitle = element_text(size = rel(0.78)))

  # Panel B: honest "not estimable" panel
  pb <- ggplot() +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf,
             fill = "grey96") +
    annotate("text", x = 0.5, y = 0.88,
             label = "Post-closure (>2005)",
             size = 3.0, fontface = "bold", color = "grey30", hjust = 0.5) +
    annotate("text", x = 0.5, y = 0.73,
             label = "NOT ESTIMABLE",
             size = 4.0, fontface = "bold", color = okabe[6], hjust = 0.5) +
    annotate("text", x = 0.5, y = 0.55,
             label = paste0("n ~ 20 observations post-closure;\n",
                            "potential_landscape() returned degenerate contract.\n",
                            "This is INDETERMINATE, not evidence against\n",
                            "an alternative attractor. (See synthesis.)"),
             size = 2.3, color = "grey25", hjust = 0.5, vjust = 1,
             lineheight = 1.3) +
    annotate("text", x = 0.5, y = 0.12,
             label = "hysteresis verdict = INDETERMINATE\nlong_transient verdict = INDETERMINATE",
             size = 2.2, color = "grey40", hjust = 0.5, lineheight = 1.2) +
    xlim(0, 1) + ylim(0, 1) +
    labs(
      title = "B  Post-closure potential landscape",
      subtitle = "2006-2025 (n~20 obs) -- not estimable"
    ) +
    thm +
    theme(
      axis.text  = element_blank(),
      axis.ticks = element_blank(),
      axis.line  = element_blank(),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      plot.subtitle = element_text(size = rel(0.78))
    )

  # Assemble: equal widths
  pa + pb +
    patchwork::plot_layout(ncol = 2, widths = c(1, 1)) +
    patchwork::plot_annotation(
      caption = paste0(
        "Left: genuine pre-closure estimate.\n",
        "Right: post-closure is not estimable at n~20 ",
        "(underpowered, degenerate contract); this is not a confident absence of a second well."
      ),
      theme = thm + theme(plot.caption = element_text(size = 7, color = "grey40",
                                                       hjust = 0, lineheight = 1.2))
    )
}


# ---------------------------------------------------------------------------
# Fig 4: Driver-state non-retracing loop
# ---------------------------------------------------------------------------

#' Biomass x exploitation-rate non-retracing loop (the hysteresis-geometry figure)
#'
#' The down-limb (fished) and up-limb (post-closure) paths in driver x state
#' space form a significant non-retracing loop (loop_p = 0.002 against the
#' survey-artifact null). Labels are claim-safe: no "hysteresis confirmed".
#'
#' @return ggplot object
fig_driver_loop <- function() {
  okabe <- .rev_okabe()
  thm   <- .rev_theme(9)

  axis <- utils::read.csv(.diag_path("reversibility_driver_axis.csv"),
                           stringsAsFactors = FALSE)
  loop <- utils::read.csv(.diag_path("reversibility_driver_state_hysteresis_loop.csv"),
                           stringsAsFactors = FALSE)

  d <- axis[, c("year", "u", "biomass", "limb", "period")]
  d <- d[order(d$year), ]

  # Limb display labels
  d$limb_label <- ifelse(d$limb == "down_limb",
                         "Down-limb: fished (1951-2005)",
                         "Up-limb: post-closure (2006-2024)")

  # Loop p-value and signed area from the u x biomass_all11 row
  lp <- loop[loop$driver == "u" & loop$state == "biomass_all11", ]
  loop_p    <- if (nrow(lp) > 0) round(lp$loop_null_p[1], 4) else NA
  loop_area <- if (nrow(lp) > 0) round(lp$signed_area[1] / 1e3, 1) else NA

  sig_label <- paste0(
    "Non-retracing loop geometry\n",
    "loop_p = ", loop_p, " (500-replicate survey-artifact null)\n",
    "Signed area = ", loop_area, " (u x biomass, kt units)\n",
    "Mechanism NOT adjudicable (hysteresis vs slow transient\n",
    "vs composite-driver residual)"
  )

  # Decade labels
  label_yrs <- d[d$year %% 10 == 0 | d$year %in% c(1951, 2005, 2024), ]

  ggplot(d, aes(x = u, y = biomass / 1000)) +
    # Faint period band
    geom_path(aes(color = limb_label), linewidth = 1.0, alpha = 0.65) +
    geom_point(aes(color = limb_label, shape = limb_label), size = 1.6) +
    ggrepel::geom_text_repel(
      data = label_yrs,
      aes(label = year), size = 2.1, color = "grey25",
      max.overlaps = 15, segment.size = 0.2, box.padding = 0.15
    ) +
    # Loop p annotation -- place in lower-right (sparse data region)
    annotate("text", x = max(d$u, na.rm = TRUE) * 0.97,
             y = min(d$biomass / 1000, na.rm = TRUE) + 5,
             label = sig_label,
             hjust = 1, vjust = 0, size = 2.1, color = "grey20",
             lineheight = 1.15) +
    scale_color_manual(values = c(okabe[6], okabe[5]), name = NULL) +
    scale_shape_manual(values = c(16, 17), name = NULL) +
    labs(
      x = "Exploitation rate  u = catch / latent biomass  (fishing driver)",
      y = "Latent spawning biomass (kt, m1_stier_11, all_11)",
      title = "Driver-state path: HG herring 1951-2024",
      subtitle = paste0(
        "Non-retracing loop significant vs survey-artifact null (loop_p=0.002); ",
        "mechanism indeterminate"
      )
    ) +
    thm +
    theme(legend.position = "bottom",
          plot.margin   = ggplot2::margin(10, 12, 10, 10, "mm"),
          plot.subtitle = element_text(size = rel(0.78)))
}


# ---------------------------------------------------------------------------
# Fig 5: Controls panel
# ---------------------------------------------------------------------------

#' Multi-seed PRIMARY pass-rate and n~70 nonlinearity finding
#'
#' Two panels:
#'   A. Bar chart of per-seed PRIMARY pass/fail (lambda_trend > 0 gate)
#'      Shows 9/12 seeds pass; canonical seed is flagged.
#'   B. S-map nonlinearity summary: nl_p for each state at n~75;
#'      annotates that all four primary states are non-significant,
#'      consistent with documented power limit.
#'
#' @return patchwork ggplot object
fig_controls_panel <- function() {
  okabe <- .rev_okabe()
  thm   <- .rev_theme(9)

  # --- Panel A: per-seed pass/fail ------------------------------------------
  # MAINTENANCE NOTE: seed_df is transcribed from Output/diagnostics/reversibility_controls.md.
  # If Script 07's seed list or canonical seed changes, this data frame MUST be updated
  # manually. Known debt: Script 07 should emit reversibility_controls.csv for
  # programmatic read; deferred post-merge (see Phase 9 final-review M-2).
  seed_df <- data.frame(
    seed      = c(20260519, 1, 2, 3, 4, 5, 7, 11, 21, 42, 99, 123),
    canonical = c(TRUE, rep(FALSE, 11)),
    pass      = c(TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, FALSE, TRUE),
    lam_trend = c(0.0020, 0.0015, -0.0003, 0.0004, 0.0033, 0.0033,
                  NA,     0.0016,  0.0009,  0.0005, -0.0118,  0.0020),
    stringsAsFactors = FALSE
  )
  seed_df$pass_label   <- ifelse(seed_df$pass, "PASS", "FAIL")
  seed_df$seed_str     <- as.character(seed_df$seed)
  seed_df$seed_str     <- factor(seed_df$seed_str,
                                 levels = as.character(seed_df$seed))
  seed_df$fill_col     <- ifelse(seed_df$pass,
                                 ifelse(seed_df$canonical, okabe[3], okabe[2]),
                                 okabe[6])

  pass_rate <- sum(seed_df$pass) / nrow(seed_df)

  # Compute y limits for Panel A
  pa_ymax <- max(seed_df$lam_trend, na.rm = TRUE) * 1.5
  pa_ymin <- min(seed_df$lam_trend, na.rm = TRUE) * 1.2

  # Label only FAIL bars to reduce clutter; PASS implied by non-orange color
  fail_df <- seed_df[!seed_df$pass, ]

  pa <- ggplot(seed_df, aes(x = seed_str, y = ifelse(is.na(lam_trend), 0, lam_trend),
                             fill = fill_col)) +
    geom_col(width = 0.7) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.5) +
    # Label only FAIL bars (below zero line)
    geom_text(data = fail_df,
              aes(x = seed_str, label = "FAIL",
                  y = ifelse(is.na(lam_trend), -0.0012, lam_trend - 0.0012)),
              size = 2.0, color = okabe[6], vjust = 1, fontface = "bold") +
    scale_fill_identity() +
    scale_x_discrete(guide = guide_axis(angle = 45)) +
    scale_y_continuous(limits = c(pa_ymin, pa_ymax)) +
    labs(
      x = "Seed",
      y = "lambda_max trend slope  (pre-closure)",
      title = "A  PRIMARY control: lambda_max trend",
      subtitle = sprintf("%d/%d seeds pass (%d%%); green = canonical seed 20260519 (PASS)",
                         sum(seed_df$pass), nrow(seed_df),
                         round(pass_rate * 100))
    ) +
    thm +
    theme(legend.position = "none",
          plot.subtitle = element_text(size = rel(0.78)))

  # --- Panel B: S-map nonlinearity ------------------------------------------
  nl <- utils::read.csv(.diag_path("reversibility_edm_nonlinearity.csv"),
                         stringsAsFactors = FALSE)
  nl$sig_label <- ifelse(nl$nonlinear_sig, "sig. (p<0.05)", "n.s.")
  nl$state_short <- c("all_11", "focal_9", "lo80", "hi80")[
    match(nl$state, c("biomass_all11", "biomass_focal9",
                      "biomass_all11_lo80", "biomass_all11_hi80"))
  ]
  # For any unmatched keep original
  nl$state_short[is.na(nl$state_short)] <- nl$state[is.na(nl$state_short)]
  nl$fill_col <- ifelse(nl$nonlinear_sig, okabe[1], "grey75")
  # Order states for readability
  nl$state_short <- factor(nl$state_short,
                           levels = c("all_11", "focal_9", "lo80", "hi80"))

  pb <- ggplot(nl, aes(x = state_short, y = nl_p, fill = fill_col)) +
    geom_col(width = 0.55) +
    geom_hline(yintercept = 0.05, linetype = "dashed",
               color = okabe[6], linewidth = 0.6) +
    geom_text(aes(label = paste0("p=", round(nl_p, 3))),
              vjust = -0.4, size = 2.1, color = "grey20") +
    geom_text(aes(label = sig_label),
              vjust = -1.8, size = 1.9, color = "grey35") +
    annotate("text", x = 0.55, y = 0.07,
             label = "p=0.05", color = okabe[6],
             size = 1.9, hjust = 0, vjust = 0) +
    annotate("text", x = 2.5, y = 0.75,
             label = paste0("n.s. at n~75: genuine\nmeasurement (power\nlimit; SECONDARY only)"),
             hjust = 0.5, vjust = 1, size = 2.0, color = "grey30", lineheight = 1.2) +
    scale_fill_identity() +
    scale_y_continuous(limits = c(0, 1.1), breaks = seq(0, 1, 0.25)) +
    labs(
      x = "State series",
      y = "S-map nonlinearity p-value",
      title = "B  S-map nonlinearity (SECONDARY)",
      subtitle = "n~75; power-limited in slow-passage regime"
    ) +
    thm +
    theme(legend.position = "none",
          plot.subtitle = element_text(size = rel(0.78)))

  pa + pb +
    patchwork::plot_layout(ncol = 2, widths = c(1.1, 0.9)) +
    patchwork::plot_annotation(
      caption = paste0(
        "A: PRIMARY gate for controls -- canonical seed (20260519) passes.\n",
        "B: S-map nonlinearity is non-significant at n~75; ",
        "annotated as a known power limit (SECONDARY; never used as a hard gate)."
      ),
      theme = thm + theme(plot.caption = element_text(size = 7, color = "grey40",
                                                       hjust = 0, lineheight = 1.2))
    )
}
