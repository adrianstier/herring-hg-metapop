# ============================================================================
# 07bq_salmon_recruitment_context_screen.R
# Treat salmon predator demand as recruitment/juvenile context, not adult SSB M.
# ============================================================================

library(tidyverse)
library(here)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
pred_dir <- file.path(proj_dir, "Data", "processed", "predators")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

find_predator_repo <- function() {
  candidates <- c(
    Sys.getenv("PREDATOR_REPO_PATH"),
    "/Users/adrianstier/pacific-herring-predators",
    file.path(dirname(proj_dir), "pacific-herring-predators")
  )
  candidates <- candidates[nzchar(candidates)]
  candidates[file.exists(file.path(
    candidates,
    "data",
    "processed",
    "consumption_budget",
    "HG_consumption_by_species_year_AUDITED.csv"
  ))][1]
}

z <- function(x) {
  if (sum(is.finite(x)) < 2L || sd(x, na.rm = TRUE) == 0) {
    return(rep(NA_real_, length(x)))
  }
  as.numeric((x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE))
}

safe_cor <- function(x, y, method = "spearman") {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 5L || sd(x[ok]) == 0 || sd(y[ok]) == 0) {
    return(NA_real_)
  }
  suppressWarnings(cor(x[ok], y[ok], method = method))
}

predator_repo <- find_predator_repo()
if (is.na(predator_repo) || !nzchar(predator_repo)) {
  stop("Predator repo not found. Set PREDATOR_REPO_PATH to /Users/adrianstier/pacific-herring-predators.")
}

pred_cov <- read_csv(
  file.path(pred_dir, "hg_predation_pressure_covariates.csv"),
  show_col_types = FALSE
) %>%
  transmute(
    year,
    salmon_demand_kt = C_salmon_kt,
    salmon_demand_log_z = z(log1p(C_salmon_kt))
  )

bridge_screen <- read_csv(
  file.path(diag_dir, "wcvi_predator_demand_residual_screen.csv"),
  show_col_types = FALSE
) %>%
  filter(label == "Salmon predator demand", lag_label == "lag_1") %>%
  select(
    label,
    grain,
    lag_label,
    n,
    spearman_rho,
    detrended_r,
    adjusted_beta,
    adjusted_p,
    post_2005_rho,
    gate
  )

species_salmon <- read_csv(
  file.path(
    predator_repo,
    "data",
    "processed",
    "consumption_budget",
    "HG_consumption_by_species_year_AUDITED.csv"
  ),
  show_col_types = FALSE
) %>%
  filter(group == "salmon") %>%
  group_by(species, year) %>%
  summarise(C_year_tonnes = sum(C_year_tonnes, na.rm = TRUE), .groups = "drop")

recent_species <- species_salmon %>%
  filter(year >= 2015, year <= 2024) %>%
  group_by(species) %>%
  summarise(
    mean_consumption_t = mean(C_year_tonnes, na.rm = TRUE),
    median_consumption_t = median(C_year_tonnes, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(share = mean_consumption_t / sum(mean_consumption_t, na.rm = TRUE)) %>%
  arrange(desc(mean_consumption_t))

recruitment_path <- file.path(
  diag_dir,
  "dfo_newer_public_pdf_extract",
  "dfo_sr_2025_005_table_11_hg_recruitment_2015_2024.csv"
)

recruitment_screen <- if (file.exists(recruitment_path)) {
  recruitment <- read_csv(recruitment_path, show_col_types = FALSE) %>%
    transmute(
      recruitment_year = year,
      recruitment_millions_median,
      response_evidence_class = "public_sca_model_output",
      response_model_use_status = "sca_output_context_only"
    )

  crossing(
    tibble(lag_label = c("same_year", "lag_1", "lag_2"), lag_n = c(0L, 1L, 2L))
  ) %>%
    pmap_dfr(function(lag_label, lag_n) {
      dat <- pred_cov %>%
        mutate(recruitment_year = year + lag_n) %>%
        inner_join(recruitment, by = "recruitment_year") %>%
        filter(is.finite(salmon_demand_log_z), is.finite(recruitment_millions_median))

      tibble(
        response = "public_DFO_HG_SCA_age2_recruitment_2015_2024",
        response_evidence_class = "public_sca_model_output",
        response_model_use_status = "sca_output_context_only",
        lag_label,
        lag_n,
        n = nrow(dat),
        spearman_rho = safe_cor(dat$salmon_demand_log_z, dat$recruitment_millions_median, "spearman"),
        pearson_r = safe_cor(dat$salmon_demand_log_z, dat$recruitment_millions_median, "pearson"),
        gate = "sca_output_context_only",
        independence_note = "DFO 2025/005 Table 11 is SCA model-estimated age-2 recruitment, not an independent juvenile survey or raw biological input."
      )
    })
} else {
  tibble(
    response = "public_DFO_HG_SCA_age2_recruitment_2015_2024",
    response_evidence_class = character(),
    response_model_use_status = character(),
    lag_label = character(),
    lag_n = integer(),
    n = integer(),
    spearman_rho = double(),
    pearson_r = double(),
    gate = character(),
    independence_note = character()
  )
}

write_csv(
  bridge_screen,
  file.path(diag_dir, "salmon_adult_growth_bridge_gate.csv")
)
write_csv(
  recent_species,
  file.path(diag_dir, "salmon_recent_species_contributions.csv")
)
write_csv(
  recruitment_screen,
  file.path(diag_dir, "salmon_recruitment_context_screen.csv")
)

p <- species_salmon %>%
  filter(year >= 1951, year <= 2025) %>%
  ggplot(aes(x = year, y = C_year_tonnes / 1000, colour = species)) +
  geom_line(linewidth = 0.55, alpha = 0.9) +
  labs(
    x = NULL,
    y = "HG salmon herring consumption (kt/yr)",
    colour = NULL,
    title = "Salmon demand is recruitment context, not adult SSB mortality",
    subtitle = "Keep salmon out of adult biomass predator branches unless age/recruitment structure is added."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

ggsave(
  file.path(fig_dir, "salmon_recruitment_context_screen.pdf"),
  p,
  width = 190,
  height = 115,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "salmon_recruitment_context_screen.png"),
  p,
  width = 190,
  height = 115,
  units = "mm",
  dpi = 300
)

bridge_line <- if (nrow(bridge_screen) > 0) {
  paste0(
    "- Adult-growth bridge gate: lag-1 salmon demand has n `",
    bridge_screen$n[[1]],
    "`, Spearman rho `",
    number(bridge_screen$spearman_rho[[1]], accuracy = 0.01),
    "`, detrended r `",
    number(bridge_screen$detrended_r[[1]], accuracy = 0.01),
    "`, adjusted beta `",
    number(bridge_screen$adjusted_beta[[1]], accuracy = 0.01),
    "`, gate `",
    bridge_screen$gate[[1]],
    "`."
  )
} else {
  "- Adult-growth bridge gate was unavailable; rerun `Code/07bj_wcvi_predation_replication_bridge.R`."
}

recruitment_lines <- if (nrow(recruitment_screen) > 0) {
  recruitment_screen %>%
    mutate(line = paste0(
      "- SCA-output recruitment context `", lag_label, "`: n `", n,
      "`, Spearman rho `", number(spearman_rho, accuracy = 0.01),
      "`, gate `", gate, "`."
    )) %>%
    pull(line)
} else {
  "- Public recruitment context unavailable; rerun newer DFO public PDF extraction first."
}

species_lines <- recent_species %>%
  mutate(line = paste0(
    "- ", species, ": ",
    number(mean_consumption_t, accuracy = 1),
    " t/yr recent mean (",
    percent(share, accuracy = 1),
    ")."
  )) %>%
  pull(line)

lines <- c(
  "# Salmon Recruitment Context Screen",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Read",
  "",
  "- Salmon demand is the only current predator-demand row that looks follow-up-worthy in the bridge gate, but it is not an adult SSB mortality mechanism.",
  "- Treat salmon as juvenile-herring / recruitment context unless the model gains recruitment or age structure.",
  "- The public DFO 2025/005 age-2 recruitment check is SCA model-output context only; it is not an independent juvenile survey or raw recruitment observation.",
  "- Do not submit a salmon adult-biomass Stan branch from the current screen.",
  bridge_line,
  "",
  "## Source Files",
  "",
  "- Herring-side predator covariates: `Data/processed/predators/hg_predation_pressure_covariates.csv`.",
  "- WCVI bridge gate: `Output/diagnostics/wcvi_predator_demand_residual_screen.csv`.",
  paste0(
    "- Predator repo salmon species consumption: `",
    file.path(predator_repo, "data", "processed", "consumption_budget", "HG_consumption_by_species_year_AUDITED.csv"),
    "`."
  ),
  paste0(
    "- Public DFO SCA recruitment-output extract: `",
    recruitment_path,
    "`",
    if (file.exists(recruitment_path)) "." else " (missing in this run)."
  ),
  "",
  "## Recent Salmon Species Contributions",
  "",
  species_lines,
  "",
  "## Public Recruitment Context",
  "",
  recruitment_lines,
  "",
  "## Outputs",
  "",
  "- `Output/diagnostics/salmon_adult_growth_bridge_gate.csv`",
  "- `Output/diagnostics/salmon_recent_species_contributions.csv`",
  "- `Output/diagnostics/salmon_recruitment_context_screen.csv`",
  "- `Output/figures/salmon_recruitment_context_screen.pdf`"
)

writeLines(lines, file.path(diag_dir, "salmon_recruitment_context_screen.md"))

cat("Saved salmon recruitment-context screen:\n")
cat("  Output/diagnostics/salmon_recruitment_context_screen.md\n")
cat("  Output/figures/salmon_recruitment_context_screen.pdf\n")
