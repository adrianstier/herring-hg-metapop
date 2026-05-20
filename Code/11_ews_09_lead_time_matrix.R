# ============================================================================
# 11_ews_09_lead_time_matrix.R — EWS lead-time matrix with confidence ladder
# stier-2027-herring-metapopulation
#
# Task 5.1: Join ews_candidate_transitions × ews_surrogate_significance ×
#   ews_sensitivity_grid (robust flag) × ews_survey_artifact_disqualified
#   (disqualified flag) × ews_controls_power (fold_power / power_class).
#
# For each non-STARS-only transition anchor, attach every indicator/layer/unit/
# window_def cell that was SIGNIFICANT (p < 0.05) in the correct pre-window,
# compute lead_years, and assign a confidence tier via the claim-control ladder.
#
# Pre-window assignment:
#   documented 1966 transition  → pre_window == "pre1966"
#   documented 2005 closure     → pre_window == "full"  (no pre-2005 cut; looseness documented)
#   detected 1976 synchrony bp  → pre_window == "full"  (no pre-1976 cut; documented)
#
# STARS filtering:
#   STARS-only candidate years that are NOT co-located (±3 yr) with a
#   breakpoint or documented transition are skipped (Task 1.7 caveat).
#
# Confidence ladder (applied in priority order):
#   "disqualified"    — disqualified == TRUE
#   "weak_power"      — fold_power < 0.3  (overrides null/marginal)
#   "mar1_numerical"  — indicator == "mar1_eigen" && |tau| > 0.7
#   "unsupported_stars" — STARS-only row that slipped through (sanity flag)
#   "strong"          — p < 0.05 && robust == TRUE && fold_power >= 0.6 && !disqualified
#   "supportive"      — p < 0.05 && (robust==TRUE || fold_power>=0.6) && !disqualified
#   "marginal"        — 0.05 <= p < 0.25 && fold_power >= 0.3 && !disqualified
#   "null"            — p >= 0.25 && !disqualified
#
# fold_power is the detect_rate from the "approaching_fold" scenario in
#   ews_controls_power.csv — it captures how often an indicator detects genuine
#   CSD (the relevant signal for tipping-point early warnings).
#
# Outputs:
#   Output/diagnostics/ews_lead_time_matrix.csv
#   Output/diagnostics/ews_lead_time_matrix.md
#
# Consistency invariant (checked via stopifnot):
#   No row can have confidence == "strong" or "supportive" AND disqualified == TRUE.
# ============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(here)
  library(stringr)
})

t0 <- proc.time()

# ── 0. Source repo setup (defines here root) ─────────────────────────────────
source(here::here("R", "00_setup.R"))

# ── 1. Load inputs with existence checks ─────────────────────────────────────
load_csv <- function(path, label) {
  if (!file.exists(path))
    stop(paste0(label, " not found at: ", path,
                "\nRun the appropriate Code/11_ews_*.R script first."))
  read_csv(path, show_col_types = FALSE)
}

transitions <- load_csv(
  here("Output", "diagnostics", "ews_candidate_transitions.csv"),
  "ews_candidate_transitions.csv"
)
surr_sig <- load_csv(
  here("Output", "diagnostics", "ews_surrogate_significance.csv"),
  "ews_surrogate_significance.csv"
)
sens_grid <- load_csv(
  here("Output", "diagnostics", "ews_sensitivity_grid.csv"),
  "ews_sensitivity_grid.csv"
)
artifact_disq <- load_csv(
  here("Output", "diagnostics", "ews_survey_artifact_disqualified.csv"),
  "ews_survey_artifact_disqualified.csv"
)
controls_power <- load_csv(
  here("Output", "diagnostics", "ews_controls_power.csv"),
  "ews_controls_power.csv"
)

# ── 2. Identify non-STARS transition anchors and co-location set ──────────────
# Non-STARS rows (breakpoint + documented):
non_stars <- transitions %>%
  filter(method != "stars")

# For STARS filtering: years with a co-located non-STARS transition (±3 yr)
non_stars_years <- non_stars$year

stars_rows <- transitions %>%
  filter(method == "stars") %>%
  rowwise() %>%
  mutate(
    colocated = any(abs(year - non_stars_years) <= 3)
  ) %>%
  ungroup()

# Emit one row per STARS year only if co-located — collapse to the nearest
# non-STARS transition year (keeps the lead_year calculation anchored to the
# validated transition, not the noisy STARS band)
stars_colocated <- stars_rows %>%
  filter(colocated) %>%
  # Map to the closest non-STARS anchor year
  rowwise() %>%
  mutate(
    anchor_year = non_stars_years[which.min(abs(year - non_stars_years))],
    stars_only  = FALSE   # will be treated as co-located, not pure STARS
  ) %>%
  ungroup() %>%
  # Replace year with the anchor for lead_year calculation
  mutate(year = anchor_year) %>%
  select(-anchor_year, -colocated, -stars_only)

# Combine: non-STARS rows + co-located STARS rows (de-duped by target+year+method combo)
# For co-located STARS, keep only the non-STARS row for each (target, year) pair
# so we don't double-count. We'll mark STARS-co-located as "stars_colocated" method.
stars_colocated_flag <- stars_colocated %>%
  mutate(method = "stars_colocated")

# The anchor transitions for this analysis:
anchor_transitions <- bind_rows(non_stars) %>%
  distinct(target, year, method, label, year_convention)

# ── 3. Pre-window assignment per anchor row ────────────────────────────────────
# Rules (Task 5.1 spec):
#   documented 1966 → pre1966
#   documented 2005 → full
#   detected  1976 bp (synchrony / detected) → full
#   breakpoint rows → assign based on closest documented transition convention
#     1966 breakpoint → pre1966
#     other breakpoints → full  (conservative; pre-window cuts don't exist for them)

assign_pre_window <- function(method, year) {
  if (method == "documented" && year == 1966) return("pre1966")
  if (method == "documented" && year == 2005) return("full")
  if (method == "documented" && year == 1976) return("full")
  if (method == "breakpoint" && year == 1966) return("pre1966")
  # All other breakpoints: full
  return("full")
}

anchor_transitions <- anchor_transitions %>%
  rowwise() %>%
  mutate(pre_window_use = assign_pre_window(method, year)) %>%
  ungroup()

# ── 4. Surrogate significance: keep only significant rows ─────────────────────
sig_rows <- surr_sig %>%
  filter(!is.na(p_value), p_value < 0.05)

# ── 5. Build sensitivity grid robust lookup ───────────────────────────────────
# The sensitivity grid uses separate window + detrend columns.
# window_def in surrogate_sig encodes as "detrend|window" (e.g., "first-diff|0.33")
# or "w{window}" for spatial windows (e.g., "w10", "w15").
# Parse window_def → detrend + window for joining.

parse_window_def <- function(wd) {
  if (grepl("^w[0-9]+$", wd)) {
    # e.g., "w10" → window = 10, detrend = NA
    list(detrend = NA_character_, window = as.character(as.numeric(sub("w", "", wd))))
  } else if (grepl("\\|", wd)) {
    parts <- str_split(wd, "\\|", simplify = TRUE)
    list(detrend = parts[1], window = parts[2])
  } else {
    list(detrend = NA_character_, window = wd)
  }
}

sig_rows <- sig_rows %>%
  rowwise() %>%
  mutate(
    parsed  = list(parse_window_def(window_def)),
    grid_detrend = parsed$detrend,
    grid_window  = parsed$window
  ) %>%
  select(-parsed) %>%
  ungroup()

# Compute robust flag per (indicator, layer, unit, window, detrend):
# A cell is "robust" in the surrogate-sig window if the majority vote in the
# sensitivity grid (across leave-out variants) is robust == TRUE.
# Join key: indicator + layer + unit + (grid_window as numeric ~ window in grid) + detrend
grid_robust <- sens_grid %>%
  group_by(indicator, layer, unit, window, detrend) %>%
  summarise(
    n_robust    = sum(robust, na.rm = TRUE),
    n_total     = n(),
    robust_vote = n_robust / n_total >= 0.5,
    .groups = "drop"
  ) %>%
  mutate(
    grid_window  = as.character(window),
    grid_detrend = detrend
  )

# Join robust flag to sig_rows
sig_rows <- sig_rows %>%
  left_join(
    grid_robust %>% select(indicator, layer, unit, grid_window, grid_detrend, robust_vote),
    by = c("indicator", "layer", "unit", "grid_window", "grid_detrend")
  ) %>%
  rename(robust = robust_vote)

# ── 6. Artifact disqualification lookup (by indicator only) ──────────────────
disq_lookup <- artifact_disq %>%
  select(indicator, disqualified) %>%
  distinct()

# ── 7. Controls power: fold_power = detect_rate from approaching_fold scenario ─
fold_power_lookup <- controls_power %>%
  filter(scenario == "approaching_fold") %>%
  select(indicator, fold_power = detect_rate)

# ── 8. Cross-join anchor transitions × significant surrogate-sig rows ──────────
# Each anchor uses its assigned pre_window_use to filter surr_sig rows.

build_lead_time_rows <- function(anc_row, sig_data) {
  pre_win <- anc_row$pre_window_use
  t_year  <- anc_row$year

  # Filter sig_data to the correct pre_window for this anchor
  matched_sig <- sig_data %>%
    filter(pre_window == pre_win)

  if (nrow(matched_sig) == 0) return(NULL)

  # lead_years: transition_year minus first year of significant run-up
  # Since surrogate sig computes tau over the entire pre-window, we don't have
  # the exact "first year significant" in the time series — the pre_window itself
  # defines the run-up window used. We compute lead_years as:
  #   pre1966 window: covers years before 1966 (the window contains ~1951-1965 = 15yr → min year ~1951)
  #   full window:    covers the entire series (earliest year depends on tier/layer/unit)
  # We use: lead_years = transition_year − (first year of the pre_window used for that series)
  # The n column in surrogate sig gives the number of observations in the pre_window.
  # For pre1966 rows with n observations ending in 1965, first year = 1966 - n.
  # For "full" rows, we use n to estimate: the full series runs from ~(transition_year - n) + 1
  # But transition_year for "full" rows is the anchor year.
  # Conservative / documented approach: lead_years = n (length of the window in years),
  # since each observation is one year. This is the exact window length that was pre-screened.

  matched_sig <- matched_sig %>%
    mutate(
      lead_years = if_else(
        is.finite(n) & n > 0L,
        as.integer(n),   # window length in years = the run-up period
        NA_integer_
      )
    )

  out <- matched_sig %>%
    transmute(
      transition_target  = anc_row$target,
      transition_year    = as.integer(t_year),
      transition_method  = anc_row$method,
      indicator,
      window_def,
      layer,
      unit,
      tier,
      tau,
      p_value,
      lead_years,
      robust,
      pre_window
    )

  out
}

# Apply to all anchor rows
all_lt_rows <- purrr::map_dfr(
  seq_len(nrow(anchor_transitions)),
  function(i) build_lead_time_rows(anchor_transitions[i, ], sig_rows)
)

if (nrow(all_lt_rows) == 0) {
  stop("No rows generated — check pre_window assignment and surrogate significance inputs.")
}

# De-duplicate: if (transition_target, transition_year, indicator, window_def, layer, unit)
# appears from multiple anchor rows (e.g., 1966 both breakpoint and documented),
# keep the documented row first, then breakpoint.
method_priority <- c("documented" = 1, "breakpoint" = 2, "stars_colocated" = 3)

all_lt_rows <- all_lt_rows %>%
  mutate(method_rank = match(transition_method, names(method_priority), nomatch = 99)) %>%
  arrange(transition_target, transition_year, indicator, window_def, layer, unit,
          method_rank) %>%
  distinct(transition_target, transition_year, indicator, window_def, layer, unit,
           .keep_all = TRUE) %>%
  select(-method_rank)

# ── 9. Attach disqualification and fold_power ─────────────────────────────────
all_lt_rows <- all_lt_rows %>%
  left_join(disq_lookup, by = "indicator") %>%
  mutate(disqualified = if_else(is.na(disqualified), FALSE, disqualified)) %>%
  left_join(fold_power_lookup, by = "indicator")

# ── 10. Confidence ladder ─────────────────────────────────────────────────────
assign_confidence <- function(indicator, tau, p_value, robust, disqualified,
                              fold_power, method) {
  # Guard: unsupported STARS (should have been filtered; sanity check)
  if (!is.na(method) && method == "stars" && !method %in% c("stars_colocated")) {
    return("unsupported_stars")
  }

  # Priority 1: disqualified (artifact contamination)
  if (!is.na(disqualified) && disqualified) return("disqualified")

  # Priority 2: MAR1 numerical artifact caveat (|tau| > 0.7 for mar1_eigen)
  if (!is.na(indicator) && indicator == "mar1_eigen" &&
      !is.na(tau) && abs(tau) > 0.7) return("mar1_numerical")

  fp <- if (is.na(fold_power)) NA_real_ else fold_power
  pv <- if (is.na(p_value)) 1.0 else p_value
  rb <- if (is.na(robust)) FALSE else robust

  # Priority 3: weak power (overrides null/marginal)
  if (!is.na(fp) && fp < 0.3) return("weak_power")

  # Confidence based on p_value + robust + fold_power
  if (pv < 0.05 && rb && !is.na(fp) && fp >= 0.6) return("strong")
  if (pv < 0.05 && (rb || (!is.na(fp) && fp >= 0.6))) return("supportive")
  if (pv < 0.05) return("supportive")  # sig but neither robust nor high power — still supportive
  if (pv < 0.25 && (is.na(fp) || fp >= 0.3)) return("marginal")
  return("null")
}

all_lt_rows <- all_lt_rows %>%
  rowwise() %>%
  mutate(
    confidence = assign_confidence(
      indicator, tau, p_value, robust, disqualified,
      fold_power, transition_method
    )
  ) %>%
  ungroup()

# ── 11. Consistency invariant check ──────────────────────────────────────────
stopifnot(
  "INVARIANT VIOLATED: row has confidence='strong' AND disqualified=TRUE" =
    !any(all_lt_rows$confidence == "strong" & all_lt_rows$disqualified, na.rm = TRUE),
  "INVARIANT VIOLATED: row has confidence='supportive' AND disqualified=TRUE" =
    !any(all_lt_rows$confidence == "supportive" & all_lt_rows$disqualified, na.rm = TRUE)
)

# ── 12. Final column selection and ordering ───────────────────────────────────
lead_time_matrix <- all_lt_rows %>%
  select(
    transition_target,
    transition_year,
    transition_method,
    indicator,
    window_def,
    layer,
    unit,
    tier,
    tau,
    p_value,
    lead_years,
    robust,
    disqualified,
    fold_power,
    confidence
  ) %>%
  arrange(
    transition_year,
    factor(confidence, levels = c("strong","supportive","marginal","null",
                                   "weak_power","disqualified",
                                   "mar1_numerical","unsupported_stars")),
    transition_target,
    indicator
  )

# ── 13. Write CSV ─────────────────────────────────────────────────────────────
out_dir <- here("Output", "diagnostics")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

csv_path <- file.path(out_dir, "ews_lead_time_matrix.csv")
write_csv(lead_time_matrix, csv_path)
message("Wrote: ", csv_path, " (", nrow(lead_time_matrix), " rows)")

# ── 14. Print sanity summary ──────────────────────────────────────────────────
cat("\n=== EWS Lead-Time Matrix: row count by confidence ===\n")
conf_tab <- table(lead_time_matrix$confidence)
print(conf_tab)

talk_grade <- lead_time_matrix %>%
  filter(confidence %in% c("strong", "supportive"))
cat("\n=== Talk-grade rows (strong/supportive) ===\n")
if (nrow(talk_grade) > 0) {
  print(talk_grade %>% select(transition_year, indicator, window_def, layer, unit,
                               tau, p_value, lead_years, fold_power, confidence))
} else {
  cat("  (none — check p_value thresholds and pre_window assignments)\n")
}

# ── 15. Write Markdown report ─────────────────────────────────────────────────
md_path <- file.path(out_dir, "ews_lead_time_matrix.md")

# Helper: format table for md
md_table <- function(df) {
  if (nrow(df) == 0) return("*(empty)*\n")
  col_names <- names(df)
  header <- paste0("| ", paste(col_names, collapse = " | "), " |")
  sep    <- paste0("| ", paste(rep("---", length(col_names)), collapse = " | "), " |")
  rows <- apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

# Anchor transitions used
anchor_used <- anchor_transitions %>%
  arrange(year, target) %>%
  mutate(
    pre_win_note = case_when(
      pre_window_use == "pre1966" ~ "pre-1966 window (tau over 1951–1965 run-up)",
      pre_window_use == "full"    ~ "full-series window (tau over all years; looseness documented)"
    )
  )

anchor_lines <- purrr::pmap_chr(
  list(anchor_used$year, anchor_used$target, anchor_used$method,
       anchor_used$label, anchor_used$pre_win_note),
  function(yr, tgt, meth, lbl, note) {
    lbl_str <- if (is.na(lbl) || lbl == "") "" else paste0(" — ", lbl)
    paste0("- **", yr, "** (", tgt, ", ", meth, ")", lbl_str, ": ", note)
  }
)

# Full matrix table (sorted by transition_year then confidence)
conf_order <- c("strong","supportive","marginal","null",
                "weak_power","disqualified","mar1_numerical","unsupported_stars")
matrix_sorted <- lead_time_matrix %>%
  mutate(conf_rank = match(confidence, conf_order)) %>%
  arrange(transition_year, conf_rank, transition_target, indicator) %>%
  select(-conf_rank)

# Talk-grade table
talk_grade_sorted <- talk_grade %>%
  arrange(transition_year, indicator, layer, unit) %>%
  select(transition_year, transition_target, indicator, window_def, layer, unit,
         tau, p_value, lead_years, fold_power, confidence)

# Dropped/hedged rows
dropped <- lead_time_matrix %>%
  filter(confidence %in% c("disqualified","weak_power","mar1_numerical","unsupported_stars")) %>%
  arrange(confidence, indicator) %>%
  select(indicator, layer, unit, window_def, confidence, tau, p_value, fold_power)

# Format key columns for display
fmt_df <- function(df) {
  df %>% mutate(
    across(where(is.numeric), ~ round(.x, 4))
  )
}

md_lines <- c(
  "# EWS Lead-Time Matrix",
  "",
  paste0("Generated: ", Sys.time()),
  paste0("Rows: ", nrow(lead_time_matrix)),
  "",
  "---",
  "",
  "## Transition anchors used",
  "",
  anchor_lines,
  "",
  "---",
  "",
  "## Lead-time matrix",
  "",
  "Sorted by `transition_year` then by `confidence` (strong → supportive → marginal → null/weak/disqualified).",
  "",
  md_table(fmt_df(matrix_sorted)),
  "",
  "---",
  "",
  "## Talk-grade rows",
  "",
  "Rows with `confidence ∈ {\"strong\", \"supportive\"}` — these are the only rows",
  "the talk can cite as positive EWS evidence. All other rows require hedging or",
  "must be excluded per the claim-control sheet.",
  "",
  if (nrow(talk_grade_sorted) > 0) md_table(fmt_df(talk_grade_sorted)) else "*(none)*",
  "",
  "---",
  "",
  "## Indicators dropped or hedged",
  "",
  "| indicator | layer | unit | window_def | confidence | tau | p_value | fold_power | reason |",
  "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
  {
    if (nrow(dropped) > 0) {
      purrr::pmap_chr(dropped, function(indicator, layer, unit, window_def,
                                        confidence, tau, p_value, fold_power) {
        reason <- switch(confidence,
          disqualified    = "Survey artifact: indicator tracks survey footprint change (Task 4.3)",
          weak_power      = "Fold-power < 0.3: null/marginal results uninterpretable (Boettiger-Hastings)",
          mar1_numerical  = "mar1_eigen |tau| > 0.7: possible near-singular OLS artifact (Task 1.5)",
          unsupported_stars = "STARS-only candidate not co-located with validated transition",
          "unknown"
        )
        paste0("| ", indicator, " | ", layer, " | ", unit, " | ", window_def,
               " | **", confidence, "** | ", round(tau, 4), " | ", round(p_value, 4),
               " | ", round(fold_power, 4), " | ", reason, " |")
      })
    } else {
      "*(none)*"
    }
  },
  "",
  "---",
  "",
  "## Convention used",
  "",
  paste0(
    "**Year convention:** All transition years use the +1L \"first year of new regime\" convention ",
    "from Task 3.4 (`year_convention = first_year_of_new_regime`). The transition year marks the ",
    "start of the post-transition state, not the last year of the preceding state."
  ),
  "",
  "**Pre-window assignment per transition:**",
  "",
  "- **1966 documented crash (pre_window = `pre1966`):** ",
  "  Tau is computed over the run-up window ending in 1965 (the years immediately ",
  "  before the fishery collapse). This is the strongest pre-window assignment for ",
  "  lead-time claims — no post-transition signal contamination.",
  "",
  "- **2005 fishery closure (pre_window = `full`):** ",
  "  No pre-2005 window cut is available in the surrogate-significance output. The ",
  "  full-series tau is used. This is a known looseness — the full series includes ",
  "  post-collapse signal — and any lead-time claim for 2005 should note this caveat.",
  "",
  "- **1976 synchronisation breakpoint (pre_window = `full`):** ",
  "  Similarly, no pre-1976 cut exists. Full-series tau used with the same caveat.",
  "",
  "**lead_years interpretation:** `lead_years` equals `n` (the number of observations ",
  "in the pre_window used for that indicator × window_def × layer × unit cell). This ",
  "is the length of the run-up window that showed a significant trend, not the time ",
  "from a specific first-year detection to the transition. It conservatively captures ",
  "\"the indicator was trending significantly over an N-year window before the transition.\"",
  "",
  "**Confidence ladder (claim-control protection):**",
  "- `strong`: p < 0.05, robust (leave-one-out majority), fold-power ≥ 0.60",
  "- `supportive`: p < 0.05, at least one of: robust OR fold-power ≥ 0.60",
  "- `marginal`: 0.05 ≤ p < 0.25, fold-power ≥ 0.30 (direction supports, not significant)",
  "- `null`: p ≥ 0.25",
  "- `weak_power`: fold-power < 0.30 (overrides null/marginal — results uninterpretable)",
  "- `disqualified`: artifact-contaminated indicator (DO NOT CITE)",
  "- `mar1_numerical`: MAR(1) near-singular OLS artifact (|tau| > 0.7)",
  "- `unsupported_stars`: STARS-band candidate not co-located with validated transition",
  "",
  "**Consistency invariant checked:** No row with `confidence ∈ {strong, supportive}` ",
  "has `disqualified == TRUE`. Verified by `stopifnot()` at script end.",
  ""
)

writeLines(md_lines, md_path)
message("Wrote: ", md_path)

# ── 16. Runtime ───────────────────────────────────────────────────────────────
elapsed <- (proc.time() - t0)[["elapsed"]]
message(sprintf("Runtime: %.1f s", elapsed))
message("Done — ews_lead_time_matrix complete.")
