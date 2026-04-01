DFO Herring Catch Data for Haida Gwaii (2016-2024)
==================================================
Compiled: 2026-04-01

SUMMARY
-------
The commercial herring fishery at Haida Gwaii has been closed since ~2002-2005.
No commercial roe herring, food & bait, special use, or spawn-on-kelp (SOK)
fisheries have operated at Haida Gwaii during 2016-2024.

The ONLY permitted harvest is Food, Social, and Ceremonial (FSC) by First Nations.
The 2024/2025 Expected Use Table (IFMP Appendix 4) allocates 150 short tons
(~136 metric tonnes) for FSC at Haida Gwaii with a harvest option of 0 for
all commercial fisheries.

The harvest recommendation from DFO Science for the HG SAR is 0 tonnes
(CSAS Science Response 2025/005), as the stock has been in a low biomass,
low productivity state since 2000 and is below the Limit Reference Point.

A rebuilding plan for Haida Gwaii herring was approved in April 2024.


DATA FILES IN THIS DIRECTORY
-----------------------------

1. herring_catch_local2024.csv
   - Extension of the legacy catch data (herring_catch_local2015.csv) for 2016-2024
   - Same column structure: Year, Num_Record, TotalCatch, CatchJan_Apr, CatchMay_Aug,
     CatchSep_Dec, Gillnet, Seine, Trawl, SOK, Section, Name, Latitude, Longitude
   - All catch fields are NA because:
     (a) Commercial catch is zero (fishery closed)
     (b) FSC catch data is not publicly available at the section level
   - Sections match the spawn survey sections used in legacy data

2. Haida_Gwaii_roe_catch.csv
   - Downloaded from Open Government Portal (open.canada.ca)
   - Source: https://open.canada.ca/data/en/dataset/71c25df1-0577-43f7-b9f8-95cc321e7cbc
   - DFO Herring Roe Fishery Catch Data for Haida Gwaii SAR
   - Covers 1972-2002 (last roe fishery year at HG)
   - Columns: Season, Year, Month, Stock Assessment Region, Statistical Area,
     Section, Gear, Catch (metric tonnes)
   - Note: "WP" values indicate withheld for privacy (< 3 parties fished)

3. harvest-sok-hg.csv
   - Downloaded from pbs-assess/herringsr GitHub repo
   - Spawn-on-kelp (SOK) harvest data for Haida Gwaii, 1951-2025
   - All values are 0 except 1989 (85,214 lbs harvest, 278 tonnes biomass)
   - Confirms no SOK harvest at HG during 2016-2024

4. Data_Dictionary_HerringRoe.docx
   - Official data dictionary for the roe catch data from Open Government Portal

5. input-data.csv
   - Metadata from herringsr describing the data sources used in the
     iSCAM stock assessment model (catch, biological, abundance data)


FSC (FOOD, SOCIAL, CEREMONIAL) HARVEST DATA
--------------------------------------------
FSC harvest data for Haida Gwaii is NOT publicly available in a downloadable
format. Key facts from the IFMP and CSAS documents:

- FSC harvest has priority after conservation (Fisheries Act)
- The Haida Nation harvests herring for food under communal licences
- Annual FSC allocation at HG: ~150 short tons (~136 metric tonnes)
- Actual FSC catch amounts are managed by DFO Aboriginal Programs but
  are not published in open data portals
- To obtain actual FSC catch data, a formal data request to DFO is required

Contact for data requests:
  Patrick Fairweather, Fisheries Resource Manager - Haida Gwaii
  Phone: (250) 559-0039
  (From IFMP 2024/2025, page 8)

  Or: DFO Aboriginal Programs Directorate
  David Lau, Director
  Phone: (236) 330-3815

  Or: Jaclyn Cleary, Head, Herring Dynamics Program
  Phone: (250) 756-7321


CATCH DATA IN THE iSCAM STOCK ASSESSMENT MODEL
-----------------------------------------------
The DFO stock assessment uses a statistical catch-age model (iSCAM/SCA)
fitted to four data sources: commercial catch landings, spawn survey index,
age composition, and weight-at-age data.

Catch in the model has three gear categories:
  1 = "Other" (includes pre-roe-fishery catches from 1951+, and potentially FSC)
  2 = "RoeSN" (roe seine, from 1972+)
  3 = "RoeGN" (roe gillnet, from 1972+)

For Haida Gwaii 2005-2024, roe seine and roe gillnet catches are 0.
The "Other" category may include small FSC catches, but these are typically
very small relative to the biomass and are entered as near-zero in the model.

The herringsr R package (github.com/pbs-assess/herringsr) builds the CSAS
Science Response document and accesses catch data from internal DFO databases
via the herringutils package (github.com/pbs-assess/herringutils).


SOURCES
-------
1. Open Government Portal - Herring Roe Fishery Catch Data
   https://open.canada.ca/data/en/dataset/71c25df1-0577-43f7-b9f8-95cc321e7cbc

2. Pacific Herring 2024/2025 IFMP
   https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41274672.pdf

3. CSAS Science Response 2025/005
   https://www.dfo-mpo.gc.ca/csas-sccs/Publications/ScR-RS/2025/2025_005-eng.pdf

4. Haida Gwaii Pacific Herring Rebuilding Plan (April 2024)
   https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41284161.pdf

5. pbs-assess/herringsr (GitHub)
   https://github.com/pbs-assess/herringsr

6. Pacific Herring IFMP web page (2025-2026 plan)
   https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/herring-hareng-ifmp-pgip-sm-eng.html


RECOMMENDATION FOR YOUR ANALYSIS
---------------------------------
For the metapopulation model (Stier et al. 2020 extension), the simplest
defensible approach for 2016-2024 catch is:

  Option A: Set all catch to 0 for all sections, all years 2016-2024.
  Justification: Commercial fishery closed. FSC harvest (~136 t/yr for the
  entire SAR) is negligible relative to the spawning biomass (median SB2024
  = 6,415 short tons = ~5,820 t) and well below the level that would
  materially affect population dynamics in the model.

  Option B: Set total catch to a small constant (e.g., 136 t/yr distributed
  proportionally among sections with spawn, or all to section 22/Skidegate
  which is the primary FSC harvest location). This is more realistic but
  requires assumptions about section-level FSC distribution.

  Option C: Request actual FSC catch data from DFO (contact info above).
  This is the gold standard but may take weeks/months.

For most ecological analyses, Option A is sufficient and well-supported by
the evidence that total removals are near-zero at HG since 2005.
