## ==========================================================================
##  02_data_merge.R
##  Build analysis-ready matrices for the hierarchical state-space model,
##  matching the format expected by the legacy JAGS code (Model1_diagonal_equal.R)
##  but extended from 1951-2025.
##
##  Key decisions:
##   - Use DFO spawn index in TONNES (not legacy SHI) for the full 1951-2025
##     period. This avoids unit mismatch between legacy SHI (spatial product)
##     and DFO tonnes. The model uses log(Y), so absolute scale is absorbed
##     by the catchability parameter (log.q).
##   - Drop sections 4 (Cartwright Sound) and 11 (Masset Inlet), same as
##     Stier et al. 2020. Both have no DFO records since 2010 and 1996.
##   - Sections 1 (Tasu) and 12 (Naden Harbour) have no records since 1993
##     and 2005. Flagged but kept — the model handles NA observations.
##   - Catch is zero for all sections 2006-2025 (fishery closed since ~2005).
##   - Survey method index: q_idx = 1 (surface, 1951-1987),
##     2 (mixed, 1988-1992), 3 (dive, 1993+) — based on empirical dive
##     survey proportions in HG data (see Issue M5).
##
##  Fixes applied (v2):
##   - C4: Informative zeros (surveyed but no spawn) are no longer discarded.
##         Three indicator matrices (Y_obs, Y_censored, Y_missing) distinguish
##         positive observations, surveyed zeros, and unsurveyed cells.
##   - M5: q_idx uses 3 levels based on actual dive survey proportions
##         (>50% dive by 1990, but variable through 1992; stable ~70%+ by 1993).
##   - m1: "SHI" renamed to "spawn_index_tonnes" in processed CSV.
##   - M6: SOK (spawn-on-kelp) catch removed from catch matrix — SOK removes
##         eggs, not spawning adults, so it shouldn't go through Pc parameter.
## ==========================================================================

library(tidyverse)

proj_dir  <- here::here()
proc_dir  <- file.path(proj_dir, "Data", "processed")
out_dir   <- proc_dir  # model inputs go here too

## =========================================================================
##  0. FIX m1: Rename SHI -> spawn_index_tonnes in processed CSV
## =========================================================================

spawn_raw <- read_csv(file.path(proc_dir, "HG_Spawn_Survey_1951_2025_all_sections.csv"),
                      show_col_types = FALSE)

if ("SHI" %in% names(spawn_raw)) {
  spawn_raw <- spawn_raw %>% rename(spawn_index_tonnes = SHI)
  write_csv(spawn_raw, file.path(proc_dir, "HG_Spawn_Survey_1951_2025_all_sections.csv"))
  cat("m1 FIX: Renamed 'SHI' -> 'spawn_index_tonnes' in processed spawn CSV.\n")
} else {
  cat("m1: Column already named 'spawn_index_tonnes' — no rename needed.\n")
}

spawn <- spawn_raw

## =========================================================================
##  1. SPAWN INDEX MATRIX (Y) — with informative zeros preserved (C4 fix)
## =========================================================================

# Sections to keep (drop 4 = Cartwright Sound, 11 = Masset Inlet)
keep_sections <- c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)
nSites <- length(keep_sections)

# Section name lookup for column ordering
section_names <- spawn %>%
  filter(section %in% keep_sections) %>%
  distinct(section, section_name) %>%
  arrange(section)

cat("\nSections retained (nSites =", nSites, "):\n")
print(section_names)

# Pivot spawn_index_tonnes to wide: years x sections
spawn_wide <- spawn %>%
  filter(section %in% keep_sections) %>%
  select(year, section, section_name, spawn_index_tonnes) %>%
  pivot_wider(
    id_cols     = year,
    names_from  = section_name,
    values_from = spawn_index_tonnes
  ) %>%
  arrange(year)

# Also pivot totalrecords to wide for the C4 fix
records_wide <- spawn %>%
  filter(section %in% keep_sections) %>%
  select(year, section_name, totalrecords) %>%
  pivot_wider(
    id_cols     = year,
    names_from  = section_name,
    values_from = totalrecords
  ) %>%
  arrange(year)

years   <- spawn_wide$year
nYears  <- length(years)
cat("\nYears:", min(years), "-", max(years), "(nYears =", nYears, ")\n")

# Raw spawn index matrix
Y_raw <- as.matrix(spawn_wide[, -1])
rownames(Y_raw) <- years

# Total records matrix (for distinguishing surveyed zeros from unsurveyed)
R <- as.matrix(records_wide[, -1])
rownames(R) <- years

## --- C4 FIX: Create three indicator matrices ---
## Y_obs:      1 if spawn_index_tonnes > 0 (positive observation)
## Y_censored: 1 if spawn_index_tonnes == 0 AND totalrecords > 0 (surveyed zero)
## Y_missing:  1 if spawn_index_tonnes == 0 AND totalrecords == 0 (not surveyed)
## These sum to 1 for every cell.

Y_obs      <- matrix(0L, nrow = nYears, ncol = nSites)
Y_censored <- matrix(0L, nrow = nYears, ncol = nSites)
Y_missing  <- matrix(0L, nrow = nYears, ncol = nSites)
colnames(Y_obs) <- colnames(Y_censored) <- colnames(Y_missing) <- colnames(Y_raw)
rownames(Y_obs) <- rownames(Y_censored) <- rownames(Y_missing) <- years

for (i in 1:nYears) {
  for (j in 1:nSites) {
    val <- Y_raw[i, j]
    rec <- R[i, j]
    if (!is.na(val) && val > 0) {
      Y_obs[i, j] <- 1L
    } else if (!is.na(rec) && rec > 0) {
      # Surveyed but found zero spawn — informative zero (left-censored)
      Y_censored[i, j] <- 1L
    } else {
      # Not surveyed at all — true missing data
      Y_missing[i, j] <- 1L
    }
  }
}

# Verify partition: every cell assigned to exactly one category
stopifnot(all((Y_obs + Y_censored + Y_missing) == 1))

N_obs      <- sum(Y_obs)
N_censored <- sum(Y_censored)
N_missing  <- sum(Y_missing)
N_total    <- prod(dim(Y_raw))

cat("\n=== C4 FIX: Observation classification ===\n")
cat("  Positive observations (Y_obs):   ", N_obs, " (",
    round(100 * N_obs / N_total, 1), "%)\n")
cat("  Surveyed zeros (Y_censored):     ", N_censored, " (",
    round(100 * N_censored / N_total, 1), "%)\n")
cat("  Unsurveyed / missing (Y_missing):", N_missing, " (",
    round(100 * N_missing / N_total, 1), "%)\n")
cat("  Total cells:                     ", N_total, "\n")

# Build the Y matrix for the model:
#   positive values -> log(spawn_index_tonnes)
#   surveyed zeros  -> sentinel -99 (model uses Y_censored indicator)
#   unsurveyed      -> sentinel -999 (model uses Y_missing indicator)
Y <- Y_raw
Y[Y_obs == 1]      <- log(Y_raw[Y_obs == 1])
Y[Y_censored == 1] <- -99
Y[Y_missing == 1]  <- -999

# Legacy-compatible logSHI: positive -> log, rest -> NA
# (for backward compatibility with code that expects NA for non-observations)
logSHI <- Y_raw
logSHI[Y_raw <= 0 | is.na(Y_raw)] <- NA
logSHI[!is.na(logSHI)] <- log(logSHI[!is.na(logSHI)])
rownames(logSHI) <- years
colnames(logSHI) <- colnames(Y_raw)

cat("\nY matrix dimensions:", nrow(Y), "x", ncol(Y), "\n")
cat("Y sentinels: -99 (surveyed zero) count =", sum(Y == -99),
    ", -999 (unsurveyed) count =", sum(Y == -999), "\n")

## =========================================================================
##  2. PDO COVARIATE
## =========================================================================

pdo <- read_csv(file.path(proc_dir, "pdo_combined_1854_2025.csv"),
                show_col_types = FALSE)

# March-June average (spring PDO), same as legacy
pdo_spring <- pdo %>%
  filter(month %in% 3:6) %>%
  group_by(year) %>%
  summarise(pdo_spring = mean(Value, na.rm = TRUE), .groups = "drop")

# Extract PDO for model years
pdo_model <- pdo_spring %>%
  filter(year >= min(years) & year <= max(years))

# Verify alignment
stopifnot(all(pdo_model$year == years))
pdo_vec <- pdo_model$pdo_spring

cat("\nPDO vector: length", length(pdo_vec), ", years",
    min(pdo_model$year), "-", max(pdo_model$year), "\n")

## =========================================================================
##  3. CATCH MATRIX — with SOK removed (M6 fix)
## =========================================================================

catch <- read_csv(file.path(proc_dir, "herring_catch_local_1950_2024.csv"),
                  show_col_types = FALSE)

## --- M6 FIX: Remove SOK from spring catch ---
## SOK (spawn-on-kelp) removes eggs, not spawning adults, so it should not
## be modeled through the Pc (proportion caught) parameter.

# Report SOK entries before removal
sok_entries <- catch %>%
  filter(Section %in% keep_sections, SOK > 0) %>%
  select(Year, Section, Name, SOK, CatchJan_Apr)

cat("\n=== M6 FIX: SOK entries removed from catch ===\n")
if (nrow(sok_entries) > 0) {
  cat("  Section-years affected:\n")
  for (r in 1:nrow(sok_entries)) {
    cat("    ", sok_entries$Year[r], " ", sok_entries$Name[r],
        ": SOK =", sok_entries$SOK[r], "t (was",
        sok_entries$CatchJan_Apr[r], "t, now",
        sok_entries$CatchJan_Apr[r] - sok_entries$SOK[r], "t)\n")
  }
  cat("  Total SOK removed:", sum(sok_entries$SOK), "tonnes across",
      nrow(sok_entries), "entries\n")
}

# Subtract SOK from CatchJan_Apr (SOK is included in CatchJan_Apr)
catch <- catch %>%
  mutate(
    SOK = replace_na(SOK, 0),
    CatchJan_Apr_noSOK = pmax(CatchJan_Apr - SOK, 0, na.rm = TRUE)
  )

# Filter to keep sections and use SOK-corrected spring catch
catch_filtered <- catch %>%
  filter(Section %in% keep_sections)

# Pivot to wide: years x sections (use corrected spring catch)
catch_wide <- catch_filtered %>%
  select(Year, Section, Name, CatchJan_Apr_noSOK) %>%
  mutate(CatchJan_Apr_noSOK = replace_na(CatchJan_Apr_noSOK, 0)) %>%
  pivot_wider(
    id_cols     = Year,
    names_from  = Name,
    values_from = CatchJan_Apr_noSOK,
    values_fn   = sum
  ) %>%
  arrange(Year)

# Extend catch to 2025 (all zeros — fishery still closed)
if (max(catch_wide$Year) < max(years)) {
  extra_years <- (max(catch_wide$Year) + 1):max(years)
  extra_rows  <- tibble(Year = extra_years)
  for (nm in names(catch_wide)[-1]) extra_rows[[nm]] <- 0
  catch_wide <- bind_rows(catch_wide, extra_rows)
}

# Extend catch back to 1951 if needed (legacy catch starts 1950)
if (min(catch_wide$Year) > min(years)) {
  extra_years <- min(years):(min(catch_wide$Year) - 1)
  extra_rows  <- tibble(Year = extra_years)
  for (nm in names(catch_wide)[-1]) extra_rows[[nm]] <- 0
  catch_wide <- bind_rows(extra_rows, catch_wide) %>% arrange(Year)
}

# Filter to model years
catch_wide <- catch_wide %>%
  filter(Year >= min(years), Year <= max(years))

# Reorder catch columns to match spawn matrix
catch_by_section <- catch_filtered %>%
  distinct(Section, Name) %>%
  arrange(Section)

# Build catch matrix with same column order as Y
ctab <- matrix(0, nrow = nYears, ncol = nSites)
colnames(ctab) <- colnames(Y)
rownames(ctab) <- years

for (i in seq_along(keep_sections)) {
  sec <- keep_sections[i]
  sec_name_spawn <- section_names$section_name[section_names$section == sec]
  sec_name_catch <- catch_by_section$Name[catch_by_section$Section == sec]

  if (length(sec_name_catch) > 0 && sec_name_catch %in% names(catch_wide)) {
    idx <- match(years, catch_wide$Year)
    vals <- catch_wide[[sec_name_catch]][idx]
    vals[is.na(vals)] <- 0
    ctab[, i] <- vals
  }
}

logcatch <- log(ctab + 1)

cat("\nCatch matrix dimensions:", nrow(ctab), "x", ncol(ctab), "\n")
cat("Non-zero catch entries:", sum(ctab > 0), "of", prod(dim(ctab)), "\n")
if (any(rowSums(ctab) > 0)) {
  cat("Last year with any catch:", max(years[rowSums(ctab) > 0]), "\n")
}

## =========================================================================
##  4. INDEX ARRAYS (for JAGS — which year-site combos have catch > 0)
## =========================================================================

INDEX      <- NULL
INDEX.zero <- NULL

for (i in 1:nrow(logcatch)) {
  pos_cols  <- which(logcatch[i, ] > 0)
  zero_cols <- which(logcatch[i, ] == 0)

  if (length(pos_cols) > 0) {
    INDEX <- rbind(INDEX, data.frame(row = rep(i, length(pos_cols)),
                                     col = pos_cols))
  }
  if (length(zero_cols) > 0) {
    INDEX.zero <- rbind(INDEX.zero, data.frame(row = rep(i, length(zero_cols)),
                                                col = zero_cols))
  }
}

nIndex      <- nrow(INDEX)
nIndex.zero <- nrow(INDEX.zero)

cat("\nnIndex (catch > 0):", nIndex, "\n")
cat("nIndex.zero (catch = 0):", nIndex.zero, "\n")

## =========================================================================
##  5. SURVEY METHOD INDEX (q_idx) — M5 fix: data-driven cutoffs
## =========================================================================

## Empirical dive survey proportions for HG sections:
##   1951-1987: 0% dive (pure surface surveys)
##   1988-1989: ~11-20% dive (transition begins)
##   1990-1992: 68-100% dive (rapid adoption but variable)
##   1993+:     mostly >70% dive (some years dip due to section mix)
##
## Decision: 3-level q_idx
##   1 = surface era  (1951-1989): dive < 50% in all years
##   2 = mixed era    (1990-1992): transition period, 68-100% dive
##   3 = dive era     (1993+):     dive dominant, mostly >70%
##
## Note: post-2005 dive percentages fluctuate because fewer sections are
## surveyed, not because of a method change. The key methodological shift
## happened 1990-1992.

q_idx <- rep(3L, nYears)
q_idx[years <= 1989] <- 1L
q_idx[years >= 1990 & years <= 1992] <- 2L

cat("\n=== M5 FIX: Survey method index (q_idx) ===\n")
cat("  q_idx = 1 (surface, 1951-1989):", sum(q_idx == 1), "years\n")
cat("  q_idx = 2 (mixed,   1990-1992):", sum(q_idx == 2), "years\n")
cat("  q_idx = 3 (dive,    1993-2025):", sum(q_idx == 3), "years\n")

# Report empirical dive percentages for verification
cat("\n  Empirical dive survey % by year (HG sections with data):\n")
dive_by_year <- spawn %>%
  filter(section %in% keep_sections, totalrecords > 0) %>%
  group_by(year) %>%
  summarise(
    n_sections = n(),
    mean_dive_pct = round(mean(dive_survey_pct, na.rm = TRUE), 1),
    .groups = "drop"
  ) %>%
  filter(year >= 1985, year <= 2000)

for (r in 1:nrow(dive_by_year)) {
  cat("    ", dive_by_year$year[r], ": ", dive_by_year$mean_dive_pct[r],
      "% (n =", dive_by_year$n_sections[r], "sections)\n")
}

## =========================================================================
##  6. ENVIRONMENTAL COVARIATES (for extended models)
## =========================================================================

# SST — annual spring mean for model years
sst <- read_csv(file.path(proc_dir, "sst_haida_gwaii_monthly.csv"),
                show_col_types = FALSE)

sst_spring <- sst %>%
  filter(month %in% 3:6) %>%
  group_by(year) %>%
  summarise(
    sst_spring_mean = mean(sst_mean, na.rm = TRUE),
    sst_spring_anom = mean(anom_mean, na.rm = TRUE),
    .groups = "drop"
  )

# Chl-a — spring mean
chla <- read_csv(file.path(proc_dir, "chla_haida_gwaii_annual.csv"),
                 show_col_types = FALSE)

# Merge environmental covariates into one table aligned to model years
env_covariates <- tibble(year = years) %>%
  left_join(pdo_model %>% rename(pdo = pdo_spring), by = "year") %>%
  left_join(sst_spring, by = "year") %>%
  left_join(chla %>% select(year, chla_spring_mean), by = "year")

cat("\nEnvironmental covariates:\n")
cat("  PDO: ", sum(!is.na(env_covariates$pdo)), "/", nYears, "years\n")
cat("  SST: ", sum(!is.na(env_covariates$sst_spring_mean)), "/", nYears, "years\n")
cat("  Chl-a:", sum(!is.na(env_covariates$chla_spring_mean)), "/", nYears, "years\n")

## =========================================================================
##  7. SAVE MODEL INPUTS (v2)
## =========================================================================

# Save as RData for the JAGS/Stan model
jags_data <- list(
  # Observation matrices
  Y           = Y,          # log(spawn) for positive, -99 for surveyed zero, -999 for unsurveyed
  logSHI      = logSHI,     # legacy-compatible: log(spawn) for positive, NA otherwise
  Y_obs       = Y_obs,      # indicator: positive observation
  Y_censored  = Y_censored, # indicator: surveyed zero (informative)
  Y_missing   = Y_missing,  # indicator: unsurveyed (true NA)
  N_obs       = N_obs,      # count of positive observations
  N_censored  = N_censored, # count of surveyed zeros
  # Dimensions
  nYears      = nYears,
  nSites      = nSites,
  # Covariates
  pdo         = pdo_vec,
  # Catch (SOK removed)
  ctab        = logcatch,
  INDEX       = as.matrix(INDEX),
  INDEX.zero  = as.matrix(INDEX.zero),
  nIndex      = nIndex,
  nIndex.zero = nIndex.zero,
  # Survey method
  q_idx       = q_idx,
  # Metadata
  years       = years,
  site_names  = colnames(Y)
)

save(jags_data, file = file.path(out_dir, "jags_model_inputs_v2.RData"))
cat("\nSaved: jags_model_inputs_v2.RData\n")

# Also save environmental covariates separately
write_csv(env_covariates, file.path(out_dir, "environmental_covariates.csv"))

# Save catch matrix as CSV for inspection
write_csv(
  as_tibble(ctab) %>% mutate(year = years, .before = 1),
  file.path(out_dir, "catch_matrix.csv")
)

## =========================================================================
##  8. DIAGNOSTIC SUMMARY
## =========================================================================

cat("\n")
cat("===================================================\n")
cat("  MODEL INPUT SUMMARY (v2)\n")
cat("===================================================\n")
cat("  Years:       ", min(years), "-", max(years), "(n =", nYears, ")\n")
cat("  Sites:       ", nSites, "(dropped sections 4, 11)\n")
cat("  Site names:  ", paste(colnames(Y), collapse = ", "), "\n")
cat("\n  --- Observation classification (C4 fix) ---\n")
cat("  Positive obs (Y_obs):    ", N_obs, "/", N_total,
    "(", round(100 * N_obs / N_total, 1), "%)\n")
cat("  Surveyed zeros (Y_cens): ", N_censored, "/", N_total,
    "(", round(100 * N_censored / N_total, 1), "%) — informative\n")
cat("  Unsurveyed (Y_miss):     ", N_missing, "/", N_total,
    "(", round(100 * N_missing / N_total, 1), "%) — true NA\n")
cat("\n  --- Catch (M6 fix: SOK removed) ---\n")
cat("  Catch > 0:   ", nIndex, "entries\n")
if (any(rowSums(ctab) > 0)) {
  cat("  Last year:   ", max(years[rowSums(ctab) > 0]), "\n")
}
cat("  SOK removed: ", sum(sok_entries$SOK), "tonnes across",
    nrow(sok_entries), "section-years\n")
cat("\n  --- Survey method (M5 fix) ---\n")
cat("  q_idx = 1 (surface): 1951-1989 (", sum(q_idx == 1), "years)\n")
cat("  q_idx = 2 (mixed):   1990-1992 (", sum(q_idx == 2), "years)\n")
cat("  q_idx = 3 (dive):    1993-2025 (", sum(q_idx == 3), "years)\n")
cat("\n  --- Column rename (m1 fix) ---\n")
cat("  'SHI' -> 'spawn_index_tonnes' in processed CSV\n")
cat("\n  --- Environment ---\n")
cat("  PDO:          full coverage\n")
cat("  SST:         ", sum(!is.na(env_covariates$sst_spring_mean)), "years\n")
cat("  Chl-a:       ", sum(!is.na(env_covariates$chla_spring_mean)), "years\n")
cat("  Saved to:    ", out_dir, "\n")
cat("===================================================\n")

cat("\n=== Spawn data availability by section (2016-2025) ===\n")
recent <- spawn %>%
  filter(section %in% keep_sections, year >= 2016) %>%
  group_by(section, section_name) %>%
  summarise(
    years_with_spawn = sum(spawn_index_tonnes > 0),
    total_spawn_tonnes = sum(spawn_index_tonnes, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(section)

print(as.data.frame(recent), row.names = FALSE)

cat("\n=== Surveyed zeros by section (C4 detail) ===\n")
censored_detail <- spawn %>%
  filter(section %in% keep_sections, spawn_index_tonnes == 0, totalrecords > 0) %>%
  select(year, section, section_name, totalrecords) %>%
  arrange(year, section)

print(as.data.frame(censored_detail), row.names = FALSE)
