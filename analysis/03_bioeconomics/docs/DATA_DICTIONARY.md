# Herring Bioeconomic Backbone — Data Dictionary

Generated: 2026-05-19 22:39:34 UTC
Rows: 385 (5 regions × 77 years)

| column | type | unit | layer | required |
|---|---|---|---|---|
| `region` | factor | SAR | key | TRUE |
| `year` | integer | calendar yr | key | TRUE |
| `regime` | factor | regime | L0 | TRUE |
| `fishery_open` | logical | 0/1 | L0 | TRUE |
| `biomass_t` | double | tonnes | L1 | FALSE |
| `recruitment` | double | count | L1 | FALSE |
| `exploitation_rate` | double | fraction | L1 | FALSE |
| `catch_total_t` | double | tonnes | L2 | FALSE |
| `catch_roe_t` | double | tonnes | L2 | FALSE |
| `catch_sok_t` | double | tonnes | L2 | FALSE |
| `roe_value_cad_nominal` | double | CAD | L3 | FALSE |
| `roe_value_cad_real2020` | double | CAD2020 | L3 | FALSE |
| `sok_price_cad_lb_nom` | double | CAD/lb | L3 | FALSE |
| `kazunoko_import_qty_t` | double | tonnes | L3 | FALSE |
| `kazunoko_import_val_usd` | double | USD | L3 | FALSE |
| `fx_jpy_per_cad` | double | JPY/CAD | L3 | FALSE |
