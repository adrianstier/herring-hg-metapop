# Where Cleary / DFO SR 2025/005 plugs into the talk

Source: **DFO CSAS Science Response 2025/005**, *Procedures for Pacific Herring
(Clupea pallasii) in BC: Status in 2024 and Forecast for 2025* (Cleary et al.).
PDF: `analysis/04_talks/2026-royalsociety/Reference_Papers/Cleary_DFO_SR2025-005_PacificHerringStatus2024.pdf`;
WAVES `https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf`;
extracted tables: `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_*.csv`.
All numbers below are quoted from those tables/text - **no estimation**; cite
the table number on the slide.

> **Model caveat (honesty - applies wherever this is used):** SR 2025/005 is a
> **single-stock SCA for the aggregate HG Major SAR**, *not* the
> 11-subpopulation metapopulation model (`m1_stier_11`). It **corroborates**
> the depletion / non-recovery / spatial-concentration story from an
> independent DFO model; do **not** present the two as the same model or as a
> likelihood/validation comparison. Keep `m1_stier_11` numbers and Cleary
> numbers separately attributed.

## Plug-points by slide

**S5 - The clean industrial tipping point.** Cleary p.9 (HG): *"Estimated
spawning biomass historic lows occurred in the late 1960s predicated by high
catches."* DFO's own words confirm the 1960s reduction-fishery collapse.
Provenance: SR 2025/005 Haida Gwaii results, p.9; Table 1 (catch input
windows: roe 1972-2024, other fisheries 1951-2024).

**S6 - Closure is not recovery (DFO-sourced version of the core claim).**
Cleary p.9: stock recovered after the 1960s, then *"below-average recruitment
since then ... estimates negative productivity, has brought biomass back down to
the LRP. The effective harvest rate Ut has been at or near zero ..."* + **Table 2:
HG total catch = 0 t every year 2015-2024.** This is the talk's hysteresis /
"removing the stressor does not equal recovery" thesis stated by DFO itself. Strong for the
expert audience. (SPINE ecological track corroboration too.)

**S7 / S8 - Portfolio comes apart / where the losses live.** **Table 3 (HG
spawn index + sub-stock proportions, 2015-2024):** Juan Perez-Skincuttle holds
**85-98%** of HG spawn most years (0.94 in 2015 ... 0.91 in 2024); Cumshewa-
Selwyn small; **Louscoone about 0** every year (0 in 8/10 yrs; 0.016 in 2019;
0.007 in 2024). Independent **DFO-sourced** confirmation that HG spawn is
collapsed into one sub-area and historic bays (Louscoone) are effectively
empty - pairs with the `m1_stier_11` portfolio result (cite both, separately).
Spawn index is volatile (1,584 t in 2023 to 11,732 t in 2024) - use to show
instability, not recovery.

**S9 - What can and cannot explain it (mechanism triage).** **Table 7 (HG SCA
key parameters):** natural mortality **M median about 0.45** (0.26-0.71);
steepness h about 0.80; R0 about 208 M. **Table 11:** age-2 recruitment fell from a
2018 peak (median about 449 M) to about 35 M (2020) and about 86 M (2024). DFO attributes
persistence to **low recruitment / negative productivity**, not ongoing
fishing - consistent with the talk's "closure didn't fix it; the system is
productivity-limited" and the non-identifiability framing (high M, no single
promoted driver). Use M about 0.45 as a citable "natural mortality is high" anchor
for the predator-demand context (S10) without claiming a predator coefficient.

**S17 - The negative control (Strait of Georgia).** **Table 2:** SoG landed
catch **about 4,672-25,279 t/yr across 2015-2024** (actively, sustainably fished)
while **HG = 0 t** and below the LRP. Conservation objective (p.5): *maintain
SB >= LRP with >=75% probability*; SoG/WCVI MPs meet it, HG does not. Exact
DFO source for "this is not all herring everywhere."

**S18 - Zero, and still below the line (the close - keystone number).**
**Table 19 (HG reference points + 2025 projection, assuming no catch):**
- LRP = 0.3 x SB0; SB0 median **21.5 kt**; LRP 0.3SB0 median **6.45 kt**.
- SB2024 median **6.42 kt**; depletion SB2024/SB0 median **0.295** - at the LRP.
- **P(SB2024 < LRP) median about 0.52.**
- 2025 projection (no fishing): SB2025 median **7.56 kt**; **P(SB2025 < LRP) =
  0.378, or 37.8%**, and **P(SB2025 < 0.75 x SB_Prod) = 0.95**.
This **confirms the plan's "37.8% below LRP under no fishing"** with exact
provenance (SR 2025/005 Table 19), and adds the sharper line: even with zero
catch, **95% probability still below the productivity-based reference**. This
is the strongest single close number and it is DFO's, not ours.

**SPINE / S2 / S20.** The DFO ecological-state arc (late-1960s low to recovery
to persistent low / at-LRP since ~2000, near-zero harvest) independently
corroborates `build1_spine.html`'s ecological track shape. Add as a one-line
"DFO's own assessment says the same" reinforcement, separately attributed.

## Net

Cleary gives the talk a **DFO-sourced spine** for the non-recovery/closure
argument (S6), a hard **keystone close number** (S18: 37.8% / 95%), an
independent **spatial-concentration** confirmation (S7/S8: Juan
Perez-Skincuttle 85-98%, Louscoone about 0), a negative-control contrast (S17:
SoG fished vs HG zero), and a citable **M about 0.45** for the mechanism slide.
Everywhere: label as SR 2025/005 (aggregate SCA), kept distinct from
`m1_stier_11`.
