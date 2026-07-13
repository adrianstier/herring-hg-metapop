write_outputs <- function() {
  source(here::here("R","schema.R"), local = TRUE)
  source(here::here("R","assemble_backbone.R"), local = TRUE)
  bb <- assemble_backbone()

  # 1. CSV (force-write into data/ even if gitignored)
  dir.create(here::here("data"), showWarnings = FALSE, recursive = TRUE)
  readr::write_csv(bb, here::here("data","herring_bioeconomic_backbone.csv"))

  # 2. Data dictionary from schema
  s <- backbone_schema()
  dd_lines <- c(
    "# Herring Bioeconomic Backbone — Data Dictionary",
    "",
    paste0("Generated: ", format(Sys.time(), tz = "UTC"), " UTC"),
    paste0("Rows: ", nrow(bb), " (", length(levels(bb$region)), " regions × ",
           length(unique(bb$year)), " years)"),
    "",
    "| column | type | unit | layer | required |",
    "|---|---|---|---|---|",
    glue::glue_data(s, "| `{column}` | {type} | {unit} | {layer} | {required} |")
  )
  writeLines(dd_lines, here::here("docs","DATA_DICTIONARY.md"))

  # 3. QA report — anchor reconciliation + coverage
  hg <- dplyr::filter(bb, region == "HG")
  hg_1956 <- sum(hg$catch_total_t[hg$year == 1956], na.rm = TRUE)
  hg_1979_ex_vessel <- bb$roe_value_cad_nominal[bb$region == "HG" & bb$year == 1979]
  sok_1995_lb <- bb$sok_price_cad_lb_nom[bb$region == "HG" & bb$year == 1995]
  l3a_present <- "roe_value_cad_nominal" %in% names(bb) &&
                 any(!is.na(bb$roe_value_cad_nominal))
  l3b_present <- "kazunoko_import_qty_t" %in% names(bb) &&
                 any(!is.na(bb$kazunoko_import_qty_t))
  fx_present  <- "fx_jpy_per_cad" %in% names(bb) &&
                 any(!is.na(bb$fx_jpy_per_cad))
  defl_present <- "roe_value_cad_real2020" %in% names(bb) &&
                  any(!is.na(bb$roe_value_cad_real2020))

  qa_lines <- c(
    "# Backbone QA Report",
    "",
    paste0("Generated: ", format(Sys.time(), tz = "UTC"), " UTC"),
    "",
    "## Shape",
    paste0("- Rows: ", nrow(bb)),
    paste0("- Regions: ", paste(levels(bb$region), collapse = ", ")),
    paste0("- Year range: ", min(bb$year), "–", max(bb$year)),
    "",
    "## Layer coverage",
    paste0("- L0 institutions: present (regime + fishery_open)"),
    paste0("- L1 biology (biomass_t, HG only): ",
           sum(!is.na(bb$biomass_t)), " non-NA rows"),
    paste0("- L2 harvest (catch_total_t, HG only): ",
           sum(!is.na(bb$catch_total_t) & bb$catch_total_t != 0), " non-zero rows"),
    paste0("- L3a digitized value/price: ",
           if (l3a_present) paste0("present (", sum(!is.na(bb$roe_value_cad_nominal)), " rows)")
           else "**ABSENT (Task 6 gated)**"),
    paste0("- L3b kazunoko: ",
           if (l3b_present) "present" else "ABSENT (Comtrade key needed)"),
    paste0("- L3c FX (fx_jpy_per_cad): ",
           if (fx_present) paste0("present (", sum(!is.na(bb$fx_jpy_per_cad)), " rows)")
           else "ABSENT"),
    paste0("- L3c deflator (roe_value_cad_real2020): ",
           if (defl_present) "present" else "ABSENT (FRED key needed)"),
    "",
    "## Anchor reconciliation",
    paste0("- HG 1956 total catch: ", format(round(hg_1956), big.mark = ","),
           " t (Hourston 1980 anchor 77,500; DFO source ~83,653; gap ~8% — methodology)"),
    paste0("- HG 1979 ex-vessel roe (CAD/ton): ",
           if (length(hg_1979_ex_vessel) && !is.na(hg_1979_ex_vessel)) hg_1979_ex_vessel
           else "absent"),
    paste0("- HG 1995 SOK price (CAD/lb): ",
           if (length(sok_1995_lb) && !is.na(sok_1995_lb)) sok_1995_lb else "absent"),
    "",
    "## Known caveats (carry into Lens C/D)",
    "- SOK price 1975 and 2015 rows are nominal midpoints of Rebuilding Plan real-2020$ bands (`$16-31/lb 1970s; $11-14/lb recent`).",
    "- IFMP Fig 9 values are chart-read (±10%), not yet formally digitized.",
    "- HG-specific landed values are not separable in DFO records (PFMA-level reporting).",
    "- 1979 vs 1990s anchors are different baskets (gillnet roe-quality vs fleet-average all-gear) — not strictly comparable on one $/t axis.",
    "- BoC FXJPYCAD ~2017+ only; pre-2017 CAD-JPY needs alternate source (FRED DEXJPUS x DEXCAUS).",
    "- HS 030520 (Japan kazunoko proxy) covers all fish roe — over-broad."
  )
  writeLines(qa_lines, here::here("Output","backbone_qa.md"))

  invisible(list(rows = nrow(bb), dict = "docs/DATA_DICTIONARY.md",
                 qa = "Output/backbone_qa.md",
                 csv = "data/herring_bioeconomic_backbone.csv"))
}
