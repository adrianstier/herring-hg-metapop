backbone_schema <- function() {
  # Note: sok_price_cad_lb_nom is nominal only (no deflated counterpart) and is
  # priced per POUND while catch_* columns are in TONNES — Task 11 revenue
  # computations must convert (1 tonne = 2204.62 lb).
  tibble::tribble(
    ~column,                  ~type,     ~unit,         ~layer, ~required,
    "region",                 "factor",  "SAR",         "key",  TRUE,
    "year",                   "integer", "calendar yr", "key",  TRUE,
    "regime",                 "factor",  "regime",      "L0",   TRUE,
    "fishery_open",           "logical", "0/1",         "L0",   TRUE,
    "biomass_t",              "double",  "tonnes",      "L1",   FALSE,
    "recruitment",            "double",  "count",       "L1",   FALSE,
    "exploitation_rate",      "double",  "fraction",    "L1",   FALSE,
    "catch_total_t",          "double",  "tonnes",      "L2",   FALSE,
    "catch_roe_t",            "double",  "tonnes",      "L2",   FALSE,
    "catch_sok_t",            "double",  "tonnes",      "L2",   FALSE,
    "roe_value_cad_nominal",  "double",  "CAD",         "L3",   FALSE,
    "roe_value_cad_real2020", "double",  "CAD2020",     "L3",   FALSE,
    "sok_price_cad_lb_nom",   "double",  "CAD/lb",      "L3",   FALSE,
    "kazunoko_import_qty_t",  "double",  "tonnes",      "L3",   FALSE,
    "kazunoko_import_val_usd","double",  "USD",         "L3",   FALSE,
    "fx_jpy_per_cad",         "double",  "JPY/CAD",     "L3",   FALSE
  )
}

# REGIONS order follows the DFO Pacific herring five major stock-assessment
# regions as used in the metapopulation analysis (Stier et al. 2020 Ecosphere) —
# NOT strict geographic north->south. Downstream factor levels MUST use this
# exact order so they stay consistent with the imported biology layer.
REGIONS <- c("HG","PRD","CC","SoG","WCVI")  # 5 BC stock assessment regions
