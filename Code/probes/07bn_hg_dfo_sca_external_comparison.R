# ============================================================================
# 07bn_hg_dfo_sca_external_comparison.R
# External comparison between the promoted m1_stier_11 biomass trajectory, public
# DFO HG SCA summaries, and HG predator-demand scale.
#
# This is a talk/readiness diagnostic, not a model-comparison likelihood. The
# DFO SCA and the Stier-aligned section model differ in geography, observation
# scale, and state definition, so results are interpreted as scale context.
# ============================================================================

library(tidyverse)
library(here)
library(knitr)
library(patchwork)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
newer_extract_dir <- file.path(diag_dir, "dfo_newer_public_pdf_extract")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

required_files <- c(
  file.path(diag_dir, "m1_stier_11_total_biomass_by_year.csv"),
  file.path(diag_dir, "wcvi_predation_replication_bridge_timeseries.csv"),
  file.path(newer_extract_dir, "dfo_sr_2025_005_table_3_hg_spawn_2015_2024.csv"),
  file.path(newer_extract_dir, "dfo_sr_2025_005_table_15_hg_spawning_biomass_depletion_2015_2024.csv")
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  stop(
    "Missing required inputs. Rerun the public extract and WCVI bridge scripts first: ",
    paste(missing_files, collapse = ", ")
  )
}

fmt <- function(x, digits = 2) {
  format(round(as.numeric(x), digits), nsmall = digits, trim = TRUE)
}

fmt_kt <- function(x, digits = 1) fmt(x, digits)

m1_total <- readr::read_csv(
  file.path(diag_dir, "m1_stier_11_total_biomass_by_year.csv"),
  show_col_types = FALSE
) %>%
  filter(report_set == "all_11") %>%
  transmute(
    year,
    m1_biomass_kt_median = median / 1000,
    m1_biomass_kt_p05 = lo90 / 1000,
    m1_biomass_kt_p95 = hi90 / 1000,
    m1_period = period,
    m1_source = "m1_stier_11 all-11 section biomass"
  )

dfo_biomass <- readr::read_csv(
  file.path(newer_extract_dir, "dfo_sr_2025_005_table_15_hg_spawning_biomass_depletion_2015_2024.csv"),
  show_col_types = FALSE
) %>%
  transmute(
    year,
    dfo_sca_biomass_kt_median = spawning_biomass_kt_median,
    dfo_sca_biomass_kt_p05 = spawning_biomass_kt_p05,
    dfo_sca_biomass_kt_p95 = spawning_biomass_kt_p95,
    dfo_depletion_median = depletion_median,
    dfo_source_document = source_document,
    dfo_source_table = source_table,
    dfo_source_url = source_url
  )

dfo_spawn <- readr::read_csv(
  file.path(newer_extract_dir, "dfo_sr_2025_005_table_3_hg_spawn_2015_2024.csv"),
  show_col_types = FALSE
) %>%
  transmute(
    year,
    dfo_spawn_index_kt = spawn_index_tonnes / 1000,
    dfo_cumshewa_selwyn_prop = cumshewa_selwyn_prop,
    dfo_juan_perez_skincuttle_prop = juan_perez_skincuttle_prop,
    dfo_louscoone_prop = louscoone_prop,
    spawn_source_document = source_document,
    spawn_source_table = source_table,
    spawn_source_url = source_url
  )

pred_ts <- readr::read_csv(
  file.path(diag_dir, "wcvi_predation_replication_bridge_timeseries.csv"),
  show_col_types = FALSE
) %>%
  transmute(
    year,
    predator_consumption_kt = C_total_kt,
    predator_mammals_kt = C_mammals_kt,
    predator_fish_kt = C_fish_kt,
    predator_salmon_kt = C_salmon_kt,
    predator_birds_kt = C_birds_kt,
    predator_removal_rate_m1 = predator_removal_rate,
    fishery_catch_kt = fishery_catch_kt,
    fishery_removal_rate_m1 = fishery_removal_rate
  )

comparison <- dfo_biomass %>%
  left_join(dfo_spawn, by = "year") %>%
  left_join(m1_total, by = "year") %>%
  left_join(pred_ts, by = "year") %>%
  mutate(
    m1_to_dfo_median_ratio = m1_biomass_kt_median / dfo_sca_biomass_kt_median,
    predator_to_dfo_biomass_ratio = predator_consumption_kt / dfo_sca_biomass_kt_median,
    predator_removal_rate_dfo_scale =
      predator_consumption_kt / (predator_consumption_kt + dfo_sca_biomass_kt_median),
    dfo_q_implied_spawn_to_sca = dfo_spawn_index_kt / dfo_sca_biomass_kt_median,
    geography_caveat = "DFO HG SCA major-stock output is an external benchmark; m1_stier_11 fits 11 Stier sections including sparse/sensitivity sections.",
    model_use_status = "external_scale_context_only"
  )

summary_tbl <- comparison %>%
  summarise(
    years = paste0(min(year), "-", max(year)),
    n_years = n(),
    mean_m1_biomass_kt = mean(m1_biomass_kt_median, na.rm = TRUE),
    mean_dfo_sca_biomass_kt = mean(dfo_sca_biomass_kt_median, na.rm = TRUE),
    median_m1_to_dfo_ratio = median(m1_to_dfo_median_ratio, na.rm = TRUE),
    mean_predator_consumption_kt = mean(predator_consumption_kt, na.rm = TRUE),
    median_predator_to_dfo_biomass_ratio =
      median(predator_to_dfo_biomass_ratio, na.rm = TRUE),
    median_predator_removal_rate_m1 =
      median(predator_removal_rate_m1, na.rm = TRUE),
    median_predator_removal_rate_dfo_scale =
      median(predator_removal_rate_dfo_scale, na.rm = TRUE),
    mean_dfo_spawn_index_kt = mean(dfo_spawn_index_kt, na.rm = TRUE),
    median_dfo_depletion = median(dfo_depletion_median, na.rm = TRUE),
    max_juan_perez_skincuttle_prop =
      max(dfo_juan_perez_skincuttle_prop, na.rm = TRUE),
    min_louscoone_prop = min(dfo_louscoone_prop, na.rm = TRUE),
    source_note = "DFO values from CSAS Science Response 2025/005 Tables 3 and 15; m1_stier_11 values from promoted baseline diagnostics; predator demand from sibling predator repo via WCVI bridge."
  )

write_csv(comparison, file.path(diag_dir, "hg_dfo_sca_external_comparison_timeseries.csv"))
write_csv(summary_tbl, file.path(diag_dir, "hg_dfo_sca_external_comparison_summary.csv"))

plot_biomass <- comparison %>%
  select(
    year,
    m1_biomass_kt_median,
    m1_biomass_kt_p05,
    m1_biomass_kt_p95,
    dfo_sca_biomass_kt_median,
    dfo_sca_biomass_kt_p05,
    dfo_sca_biomass_kt_p95
  ) %>%
  ggplot(aes(x = year)) +
  geom_ribbon(
    aes(ymin = m1_biomass_kt_p05, ymax = m1_biomass_kt_p95),
    fill = "#176B87",
    alpha = 0.15
  ) +
  geom_line(aes(y = m1_biomass_kt_median, colour = "m1_stier_11 all-11"), linewidth = 0.75) +
  geom_ribbon(
    aes(ymin = dfo_sca_biomass_kt_p05, ymax = dfo_sca_biomass_kt_p95),
    fill = "#7A3B2E",
    alpha = 0.18
  ) +
  geom_line(aes(y = dfo_sca_biomass_kt_median, colour = "DFO HG SCA"), linewidth = 0.75) +
  scale_y_log10(labels = label_number(accuracy = 1)) +
  scale_colour_manual(values = c(
    "m1_stier_11 all-11" = "#176B87",
    "DFO HG SCA" = "#7A3B2E"
  )) +
  labs(
    x = NULL,
    y = "Biomass scale (kt, log10)",
    colour = NULL,
    title = "External biomass benchmark",
    subtitle = "Not a likelihood comparison: different model state, geography, and observation scale."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

plot_removal <- comparison %>%
  select(year, predator_removal_rate_m1, predator_removal_rate_dfo_scale) %>%
  pivot_longer(
    -year,
    names_to = "scale",
    values_to = "rate"
  ) %>%
  mutate(
    scale = recode(
      scale,
      predator_removal_rate_m1 = "Against m1_stier_11 biomass",
      predator_removal_rate_dfo_scale = "Against DFO SCA biomass"
    )
  ) %>%
  ggplot(aes(x = year, y = rate, colour = scale)) +
  geom_line(linewidth = 0.75) +
  geom_point(size = 1.8) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_colour_manual(values = c(
    "Against m1_stier_11 biomass" = "#176B87",
    "Against DFO SCA biomass" = "#7A3B2E"
  )) +
  labs(
    x = NULL,
    y = "Predator consumption analogue",
    colour = NULL,
    title = "Predator demand is large under either scale",
    subtitle = "This is scale context, not an age-selective predation-mortality estimate."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

plot_spawn <- comparison %>%
  select(
    year,
    dfo_cumshewa_selwyn_prop,
    dfo_juan_perez_skincuttle_prop,
    dfo_louscoone_prop
  ) %>%
  pivot_longer(
    -year,
    names_to = "substock",
    values_to = "prop"
  ) %>%
  mutate(
    substock = recode(
      substock,
      dfo_cumshewa_selwyn_prop = "Cumshewa/Selwyn",
      dfo_juan_perez_skincuttle_prop = "Juan Perez/Skincuttle",
      dfo_louscoone_prop = "Louscoone"
    )
  ) %>%
  ggplot(aes(x = year, y = prop, fill = substock)) +
  geom_col(width = 0.78) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_fill_manual(values = c(
    "Cumshewa/Selwyn" = "#C47F2A",
    "Juan Perez/Skincuttle" = "#176B87",
    "Louscoone" = "#7A3B2E"
  )) +
  labs(
    x = NULL,
    y = "Share of HG spawn index",
    fill = NULL,
    title = "Public DFO summaries also show recent spatial concentration"
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

combined_plot <- plot_biomass / (plot_removal | plot_spawn) +
  plot_annotation(
    title = "Haida Gwaii External Assessment Context",
    subtitle = "Promoted Stier-aligned section model, public DFO SCA summaries, and predator-demand scale."
  )

ggsave(
  file.path(fig_dir, "hg_dfo_sca_external_comparison.pdf"),
  combined_plot,
  width = 260,
  height = 230,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "hg_dfo_sca_external_comparison.png"),
  combined_plot,
  width = 260,
  height = 230,
  units = "mm",
  dpi = 300
)

lines <- c(
  "# HG DFO SCA External Comparison",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This diagnostic compares the promoted `m1_stier_11` biomass trajectory with public DFO HG SCA summaries and HG predator demand. It is scale context for the talk, not a model-likelihood comparison.",
  "",
  "## Source Provenance",
  "",
  "- `m1_stier_11`: `Output/diagnostics/m1_stier_11_total_biomass_by_year.csv`.",
  "- DFO SCA biomass/depletion: DFO CSAS Science Response 2025/005 Table 15, extracted by `Code/02f_extract_newer_dfo_public_pdfs.R`.",
  "- DFO HG spawn/sub-stock proportions: DFO CSAS Science Response 2025/005 Table 3, extracted by `Code/02f_extract_newer_dfo_public_pdfs.R`.",
  "- Predator demand: sibling predator repo products integrated by `Code/02c_integrate_hg_predator_repo_products.R` and summarized by `Code/07bj_wcvi_predation_replication_bridge.R`.",
  "- Canonical source map: `docs/doherty-style-hg-source-provenance.md`.",
  "",
  "## Talk Read",
  "",
  paste0("- Over ", summary_tbl$years, ", mean `m1_stier_11` all-11 biomass is `", fmt_kt(summary_tbl$mean_m1_biomass_kt, 1), "` kt, while mean public DFO HG SCA spawning biomass is `", fmt_kt(summary_tbl$mean_dfo_sca_biomass_kt, 1), "` kt."),
  paste0("- The median m1/DFO biomass-scale ratio is `", fmt(summary_tbl$median_m1_to_dfo_ratio, 1), "x`; this should be reported as scale/geography context, not as a validation residual."),
  paste0("- Mean HG predator demand is `", fmt_kt(summary_tbl$mean_predator_consumption_kt, 1), "` kt/yr."),
  paste0("- The median predator-consumption analogue is `", percent(summary_tbl$median_predator_removal_rate_m1, accuracy = 1), "` against `m1_stier_11` biomass and `", percent(summary_tbl$median_predator_removal_rate_dfo_scale, accuracy = 1), "` against public DFO SCA spawning biomass."),
  paste0("- Public DFO Table 3 shows Juan Perez/Skincuttle reaches `", percent(summary_tbl$max_juan_perez_skincuttle_prop, accuracy = 1), "` of HG spawn-index share in 2015-2024, while Louscoone is as low as `", percent(summary_tbl$min_louscoone_prop, accuracy = 1), "`."),
  "",
  "## Interpretation Guardrails",
  "",
  "- DFO HG SCA outputs and `m1_stier_11` do not have identical geography or state definitions, so compare qualitative scale and direction rather than raw likelihood fit.",
  "- Predator demand is ecologically large under either biomass scale, but current data still lack age/size selectivity and exact current catch-at-age inputs.",
  "- This supports the Doherty-style data-acquisition path and predator-scale discussion; it does not promote a predator-effect model.",
  "",
  "## Outputs",
  "",
  "- `Output/diagnostics/hg_dfo_sca_external_comparison_timeseries.csv`",
  "- `Output/diagnostics/hg_dfo_sca_external_comparison_summary.csv`",
  "- `Output/diagnostics/hg_dfo_sca_external_comparison.md`",
  "- `Output/figures/hg_dfo_sca_external_comparison.pdf`"
)

writeLines(lines, file.path(diag_dir, "hg_dfo_sca_external_comparison.md"))

cat("Saved HG DFO SCA external comparison:\n")
cat("  Output/diagnostics/hg_dfo_sca_external_comparison.md\n")
cat("  Output/figures/hg_dfo_sca_external_comparison.pdf\n")
