# ============================================================================
# 07bo_doherty_proxy_parameter_plan.R
# Talk-cycle proxy plan for the Doherty-style HG workflow.
#
# This does not fit a catch-at-age or predator-removal model. It creates a
# transparent, talk-facing ledger that separates HG public biological extracts,
# sibling predator-repo products, WCVI/Doherty proxy assumptions, and unresolved
# acquisition items.
# ============================================================================

library(tidyverse)
library(here)
library(knitr)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

rel_exists <- function(path) {
  if_else(file.exists(file.path(proj_dir, path)), "present", "missing")
}

proxy_plan <- tribble(
  ~data_stream, ~talk_cycle_source, ~proxy_policy, ~missing_for_final_hg, ~acquisition_plan, ~talk_status, ~primary_local_products,
  "Catch/removals",
  "Existing HG DFO catch removals plus public DFO 2025/005 major-stock catch summaries.",
  "Use as HG biomass-model removals and public catch context. Do not call this a complete catch-at-age input bundle.",
  "Exact source/fleet catch input files aligned to the current SCA/SISCAH model and metadata.",
  "Request the machine-readable HG SCA/SISCAH catch input table from DFO; reconcile source/fleet labels against local catch products.",
  "HG context usable now",
  "Data/processed/herring_catch_local_1950_2024.csv; Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_2_major_catch_2015_2024.csv",
  "Catch-at-age / age composition",
  "HG public CSAS 2018/028 Appendix B number-at-age through 2017 plus broad public 2025 IFMP projected age proportions.",
  "For the talk, show this as proof that HG age-composition inputs exist and that a schema can be built. Do not substitute WCVI age composition for HG.",
  "Exact annual 2018-2024 HG age-composition matrices, source/fleet labels, plus-group handling, and effective sample sizes.",
  "Use the DFO request packet for exact current inputs; then build a regional HG catch-at-age scaffold and compare against the biomass model as a cross-check.",
  "partial HG public proxy",
  "Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b15_number_at_age_long.csv; Output/diagnostics/dfo_newer_public_pdf_extract/dfo_ifmp_2024_2025_table_3_1_projected_biomass_age_props.csv",
  "Weight-at-age",
  "HG public CSAS 2018/028 Appendix B weight-at-age through 2017; DFO 2025/005 confirms weight-at-age is used through 2024.",
  "Use as provisional HG historical biological context and schema. Do not treat as a current final model input without DFO metadata.",
  "Exact 2018-2024 annual weight-at-age matrices, imputation rules, and sample-size/source metadata.",
  "Request current machine-readable weight-at-age and preprocessing metadata; back-check extracted public values against DFO input files.",
  "partial HG public proxy",
  "Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b22_weight_at_age_long.csv; Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_1_input_data_windows.csv",
  "Length / size-at-age",
  "HG rebuilding-plan biological captions plus Doherty/WCVI model structure where a size-selectivity placeholder is needed for slides.",
  "Use only as a clearly labelled proxy/scaffold. A WCVI size-at-age or selectivity curve is not an HG estimate.",
  "Machine-readable HG annual length-at-age or biological-sample summaries tied to ageing records.",
  "Extract any tabular rebuilding-plan values if available; otherwise request length-at-age and biological sample files from DFO.",
  "WCVI proxy only",
  "Output/diagnostics/dfo_newer_public_pdf_extract/dfo_hg_rebuilding_plan_biology_caption_catalog.csv; docs/wcvi-predation-replication-bridge.md",
  "Maturity-at-age",
  "Published CSAS 2018/028 assumed maturity schedule.",
  "Use as the published provisional schedule for planning and talk context only.",
  "Confirmation that the same schedule or a revised schedule is used in the current HG SCA/SISCAH inputs.",
  "Ask DFO to include the current maturity schedule and any sex/source-specific revisions in the biological input packet.",
  "partial HG public proxy",
  "Output/diagnostics/dfo_hg_public_extract/dfo_hg_maturity_schedule.csv",
  "Predator annual demand",
  "Sibling `stier-lab/pacific-herring-predators` HG consumption products integrated into this repo.",
  "Usable for biomass-scale predator demand and removal-rate analogues. This is not age-selective natural mortality.",
  "Section-specific exposure for all predator classes and uncertainty propagation rules.",
  "Keep predator abundance/consumption updates in the sibling repo; import versioned products here with source catalog rows.",
  "HG context usable now",
  "Data/processed/predators/hg_predation_pressure_covariates.csv; Output/diagnostics/wcvi_predation_replication_bridge_timeseries.csv",
  "Predator age/size selectivity",
  "Doherty WCVI paper/supplement and HG/BC diet literature as the temporary analogue.",
  "Use only as a clearly labelled WCVI/Doherty proxy in slides. Do not fit or promote an HG predator-removal model from this proxy alone.",
  "Predator-class selectivity-at-age or selectivity-at-size table with source, uncertainty, and HG transferability flags.",
  "Extract Doherty selectivity assumptions into a sourced registry; then review HG diet/size evidence before allowing model use.",
  "WCVI proxy only",
  "docs/wcvi-predation-replication-bridge.md; docs/doherty-style-hg-source-provenance.md",
  "Future predator scenarios",
  "None for current HG fitting; historical HG predator demand only.",
  "Do not show forecast/reference-point output as if it has been run for HG.",
  "Future predator abundance/scenario tables and projection assumptions.",
  "Add only after historical herring biology and selectivity are audited; keep scenario provenance separate from historical fit data.",
  "blocked after talk",
  "docs/doherty-style-hg-replication-status.md"
) %>%
  mutate(
    talk_status = factor(
      talk_status,
      levels = c(
        "HG context usable now",
        "partial HG public proxy",
        "WCVI proxy only",
        "blocked after talk"
      )
    ),
    source_product_status = map_chr(
      str_split(primary_local_products, ";\\s*"),
      ~ paste(paste0(.x, " [", rel_exists(.x), "]"), collapse = "; ")
    ),
    model_use_gate = case_when(
      talk_status == "HG context usable now" ~
        "May be shown as current scale/context output; still not full Doherty predation mortality.",
      talk_status == "partial HG public proxy" ~
        "May be shown as provisional HG public biological input evidence and schema.",
      talk_status == "WCVI proxy only" ~
        "May be shown only as an explicitly labelled analogue/proxy.",
      TRUE ~
        "Do not use as current model output."
    )
  )

write_csv(proxy_plan, file.path(diag_dir, "doherty_proxy_parameter_plan.csv"))

status_counts <- proxy_plan %>%
  count(talk_status, name = "n") %>%
  arrange(talk_status)

talk_wording <- c(
  "We can show a Doherty-style HG bridge now, but it is a proxy bridge rather than a completed HG catch-at-age predator-removal model.",
  "The herring biology side is anchored in HG public DFO sources where possible: public age composition and weight-at-age through 2017, plus public DFO summaries through 2024.",
  "Where HG inputs are missing for the talk, WCVI/Doherty values are only analogues for model structure or predator selectivity, not HG-estimated parameters.",
  "All promoted population results still come from `m1_stier_11`; predator-demand screens are held ecological context."
)

lines <- c(
  "# Doherty-Style Proxy Parameter Plan",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Talk-Cycle Rule",
  "",
  paste0("- ", talk_wording),
  "",
  "## Status Counts",
  "",
  knitr::kable(status_counts, format = "pipe"),
  "",
  "## Proxy Ledger",
  "",
  knitr::kable(
    proxy_plan %>%
      mutate(talk_status = as.character(talk_status)) %>%
      select(
        data_stream,
        talk_status,
        talk_cycle_source,
        proxy_policy,
        missing_for_final_hg,
        acquisition_plan,
        model_use_gate
      ),
    format = "pipe"
  ),
  "",
  "## Local Product Check",
  "",
  knitr::kable(
    proxy_plan %>%
      mutate(talk_status = as.character(talk_status)) %>%
      select(data_stream, primary_local_products, source_product_status),
    format = "pipe"
  ),
  "",
  "## Talk Output To Show Now",
  "",
  "- `Output/diagnostics/hg_dfo_sca_external_comparison.md` and `Output/figures/hg_dfo_sca_external_comparison.pdf`: scale bridge among promoted `m1_stier_11`, public DFO HG SCA summaries, and HG predator demand.",
  "- `Output/diagnostics/wcvi_predation_replication_bridge.md` and `Output/figures/wcvi_predation_replication_bridge.pdf`: WCVI-style predator-demand analogue against the promoted HG biomass baseline.",
  "- `Output/diagnostics/doherty_proxy_parameter_plan.md` and `Output/figures/doherty_proxy_parameter_plan.pdf`: this explicit proxy/source/status slide support.",
  "",
  "## Acquisition Plan After The Talk",
  "",
  "1. Send or use `docs/dfo-hg-biological-input-request-packet.md` to get exact machine-readable HG SCA/SISCAH catch, age, weight, length, maturity, and metadata inputs.",
  "2. Convert the public 1951-2017 HG age and weight extracts into a provisional regional catch-at-age bundle with explicit plus-group, source/fleet, and effective-sample-size flags.",
  "3. Extract Doherty WCVI predator selectivity assumptions into a sourced registry with transferability flags before any model use.",
  "4. Join the exact HG biological inputs to the sibling predator-repo demand/exposure products only after source fields and metadata pass QC.",
  "5. Build and smoke-test a separate regional HG catch-at-age scaffold; keep it separate from the 11-section `m1_stier_11` biomass model until the diagnostics justify integration.",
  "",
  "## Non-Negotiable Caveat",
  "",
  "This output is suitable for a talk slide about progress and planned replication. It is not evidence that a full Doherty-style HG catch-at-age predator-removal analysis has been fitted."
)

writeLines(lines, file.path(diag_dir, "doherty_proxy_parameter_plan.md"))

plot_dat <- proxy_plan %>%
  mutate(
    data_stream = fct_rev(fct_inorder(data_stream)),
    label = str_wrap(as.character(talk_status), width = 18)
  )

status_palette <- c(
  "HG context usable now" = "#176B87",
  "partial HG public proxy" = "#758E4F",
  "WCVI proxy only" = "#B76E45",
  "blocked after talk" = "#8C2F39"
)

proxy_plot <- ggplot(plot_dat, aes(x = 1, y = data_stream, fill = talk_status)) +
  geom_tile(width = 0.9, height = 0.75, colour = "white", linewidth = 0.6) +
  geom_text(aes(label = label), size = 3.3, lineheight = 0.95, colour = "white") +
  scale_fill_manual(values = status_palette, drop = FALSE) +
  scale_x_continuous(NULL, breaks = NULL, limits = c(0.5, 1.5)) +
  labs(
    y = NULL,
    fill = NULL,
    title = "Doherty-style HG inputs: what is real, proxy, or blocked",
    subtitle = "HG public sources anchor herring biology where possible; WCVI/Doherty values are talk-cycle analogues only."
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    legend.position = "bottom",
    plot.title.position = "plot",
    axis.text.y = element_text(size = 10),
    plot.margin = margin(10, 12, 10, 12)
  )

ggsave(
  file.path(fig_dir, "doherty_proxy_parameter_plan.pdf"),
  proxy_plot,
  width = 10,
  height = 5.8
)
ggsave(
  file.path(fig_dir, "doherty_proxy_parameter_plan.png"),
  proxy_plot,
  width = 10,
  height = 5.8,
  dpi = 300
)

cat("Saved Doherty proxy parameter plan:\n")
cat("  Output/diagnostics/doherty_proxy_parameter_plan.md\n")
cat("  Output/diagnostics/doherty_proxy_parameter_plan.csv\n")
cat("  Output/figures/doherty_proxy_parameter_plan.pdf\n")
cat("  Output/figures/doherty_proxy_parameter_plan.png\n")
