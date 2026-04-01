MARINE PREDATOR ABUNDANCE DATA SOURCES — HAIDA GWAII / HECATE STRAIT
======================================================================
Compiled: 2026-04-01
Context: Extending predator time series from Samhouri, Stier et al. (2017, Nature Ecology & Evolution)

================================================================================
1. HARBOUR SEAL (Phoca vitulina richardii)
================================================================================

DATA DOWNLOADED:
- Harbour_seal_counts_haulout_locs_BCcoast.csv
  Source: DFO Open Government Portal
  URL: https://open.canada.ca/data/en/dataset/be5a4ba8-79dd-4787-bf8a-0d460d25954c
  Coverage: 1966-2019, all BC coast regions including "Haida Gwaii"
  Fields: SubsiteID, Region, Complex, Subarea, Year, Date, Lon, Lat, complex_count
  Regions in data: Strait of Georgia, WCVI, Queen Charlotte Strait,
                   Discovery Passage, Central Mainland Coast, Northern Mainland Coast,
                   Haida Gwaii
  Status: FREELY DOWNLOADABLE CSV
  Contact: Sheena Majewski, Sheena.Majewski@dfo-mpo.gc.ca

- Data_dictionary_HarbourSealCountsHauloutLocsBCCoast.csv (companion)

KEY PUBLICATIONS:
- Olesiuk, P.F. 2010. An assessment of the status of harbour seals (Phoca
  vitulina) in British Columbia. DFO CSAS Research Document 2009/105.
  URL: https://waves-vagues.dfo-mpo.gc.ca/Library/244725.pdf
  (Foundational assessment with time series from 1960s-2008)

- Majewski, S.P. and Ellis, G.M. 2022. Updated assessment of Harbour Seal
  abundance in the Strait of Georgia. DFO CSAS Research Document 2022/060.
  URL: https://www.dfo-mpo.gc.ca/csas-sccs/Publications/ResDocs-DocRech/2022/2022_060-eng.html
  (SOG-specific, ~39,300 seals in 2014)

- DFO 2022. Stock Assessment of Pacific Harbour Seals in Canada in 2019.
  Science Advisory Report 2022/034.
  URL: https://www.dfo-mpo.gc.ca/csas-sccs/Publications/SAR-AS/2022/2022_034-eng.html
  Coast-wide estimate: 85,400 (95% CI: 82,000-88,900) in 2015-2019
  Haida Gwaii PBR: 418 seals (implies regional abundance ~8,000-12,000)
  Key finding: population stable or slightly declining from peak of ~105,000

- Majewski et al. 2022. Stock Assessment of Pacific Harbour Seals (Phoca vitulina
  richardii) in Canada in 2019. DFO CSAS Research Document (full regional data).
  URL: https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41073654.pdf

NOTES:
- The CSV dataset covers individual haulout-level counts with ~1,960 subsites
- Haida Gwaii data extends 1966-2019
- For population-level estimates (not raw counts), need to apply correction
  factors from Olesiuk (2010) or the 2022 stock assessment

================================================================================
2. STELLER SEA LION (Eumetopias jubatus)
================================================================================

DATA DOWNLOADED:
- Steller_Sea_Lion_Summer_counts_from_Haulout_Locations.csv
  Source: DFO Open Government Portal
  URL: https://open.canada.ca/data/en/dataset/0083baf1-8145-4207-a84f-3d85ef2943a5
  Coverage: 1971-2013, all BC coast including "Haida Gwaii" region
  Fields: REGION, SITE, SITE TYPE, LAT, LON, SURVEY YEAR, COUNT NON-PUP,
          COUNT NON-PUP INTERPOLATED, COUNT PUP, COUNT PUP INTERPOLATED,
          COUNT PUP PRE-ROOKERY, COUNT PUP PRE-ROOKERY INTERPOLATED
  Haida Gwaii sites: Anthony Island, Cape St. James Island, Cone Head,
    Garcin Rocks, Joseph Rocks, Joyce Rocks, Langara Island, Marble Island,
    Moresby Islets, North Chads Point, Reef Island, Rose Spit, Skedans Islands,
    South Nangwaii Islands, South Tasu Head, Tatsung Rock
  Status: FREELY DOWNLOADABLE CSV

- SSL_2016-17_Shapefiles.zip (updated 2016-17 survey — shapefile format)
  Source: DFO Open Government Portal
  URL: https://open.canada.ca/data/en/dataset/af0296fe-54f6-4c72-9e98-bdf55fafe33c
  Coverage: 2016-2017 breeding season surveys
  Contact: Chad.Nordstrom@dfo-mpo.gc.ca
  Status: FREELY DOWNLOADABLE (shapefile, no CSV available)

- SSL_Data_Dictionary.htm, SSL_2016-17_Data_Dictionary.csv (companions)

KEY PUBLICATIONS:
- Majewski, S., Szaniszlo, W., Nordstrom, C.A., Abernethy, R.M., and Tucker, S.
  2024. Abundance and Distribution of Steller Sea Lions (Eumetopias jubatus) in
  British Columbia: Updates from 2016-17 Aerial Surveys.
  DFO CSAS Research Document 2024/047.
  URL: https://publications.gc.ca/site/eng/9.940316/publication.html
  Key data: 6,640 pups + 25,113 non-pups counted in summer 2017
  Note: Possible slowing in pup production growth rate since 2013

- DFO 2021. Trends in Abundance and Distribution of Steller Sea Lions
  (Eumetopias jubatus) in Canada. Science Advisory Report 2021/035.
  URL: https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41003925.pdf

- NOAA 2024. Steller Sea Lion (Eumetopias jubatus): Eastern Stock.
  Stock Assessment Report, revised 5/10/2024.
  URL: https://www.fisheries.noaa.gov/s3/2024-12/2023_SAR_Steller_Sea_Lion_Eastern_Stock.pdf
  Eastern DPS model count: 36,308 (includes BC + SE Alaska + US West Coast)
  Growth rate 1987-2017: 4.25%/yr (95% CI: 3.77-4.72%)
  Note: Population leveling off since 2017; decline in adult female survival
  during 2014-2017 marine heatwave

EXISTING LEGACY DATA IN PROJECT:
- Data/raw/steller-sea-lions/SSL Breeding Season Counts 1971-2013_ACS_Dec15.xlsx
- Data/raw/steller-sea-lions/womble_sigler_ssl_energetics.xlsx
- Data/raw/harbour-seals/HarbourSeal_StellerSeaLionDR_v1.xlsx

NOTES:
- The 1971-2013 CSV and the legacy Excel file likely overlap substantially
- Gap: No openly available site-level CSV data for 2013-2017; the 2016-17
  data is in shapefile format only
- For post-2017 data, would need to contact DFO directly (Sheena Majewski
  or Chad Nordstrom)

================================================================================
3. HUMPBACK WHALE (Megaptera novaeangliae)
================================================================================

DATA DOWNLOADED:
- humpback_whale_NorthPacific_abundance_Cheeseman2024.csv
  Source: Cheeseman et al. 2024, Royal Society Open Science
  Coverage: 2002-2021, North Pacific basin-wide mark-recapture estimates
  Fields: Year, Abundance, SE, CI_lower, CI_upper
  Status: EXTRACTED FROM PUBLICATION TABLE 3
  NOTE: These are ocean-basin-wide estimates, NOT Haida Gwaii-specific.
  Supplementary data + code: https://github.com/tedcheese/RSOS-NPAC-abundance
  Figshare: https://doi.org/10.6084/m9.figshare.c.7075479

- Cetacean_Spatial_Model_Data.zip (contains humpback spatial density models)
  Source: DFO Open Government Portal (Wright, Nichol & Doniol-Valcroze 2021)
  URL: https://open.canada.ca/data/en/dataset/39546277-b33e-4f80-8a2d-3ca1ce5b1401
  Coverage: 2018 PRISMM survey, 3 strata: NorthCoast, Offshore, SalishSea
  BC total: 7,030 humpbacks (95% CI: 5,733-8,620) in Canadian Pacific waters
  Format: Shapefiles with modelled abundance per 25 km^2 grid cell
  Contact: Brianna.Wright@dfo-mpo.gc.ca
  Status: FREELY DOWNLOADABLE

KEY PUBLICATIONS:
- Cheeseman, T. et al. 2024. Bellwethers of change: population modelling of
  North Pacific humpback whales from 2002 through 2021 reveals shift from
  recovery to climate response. Royal Society Open Science 11(2):231462.
  URL: https://royalsocietypublishing.org/rsos/article/11/2/231462
  PubMed: https://pubmed.ncbi.nlm.nih.gov/28812672/
  Key data: Peak 33,488 in 2012; declined 20% to 26,662 by 2021
  Growth phase 2002-2013: ~5.9%/yr; Decline 2014-2021: ~-3.0%/yr

- Wright, B.M., Nichol, L.M., and Doniol-Valcroze, T. 2021. Spatial density
  models of cetaceans in the Canadian Pacific estimated from 2018 ship-based
  surveys. DFO publication.
  (PRISMM survey — first comprehensive abundance estimate for BC waters)

- Barlow, J. et al. 2011. Humpback whale abundance in the North Pacific
  estimated by photographic capture-recapture. Marine Mammal Science 27(4).
  SPLASH baseline: 21,063 whales in 2004-2006

- COSEWIC 2022. Humpback Whale (Megaptera novaeangliae kuzira): Assessment
  and Status Report.
  URL: https://www.canada.ca/en/environment-climate-change/services/species-risk-public-registry/cosewic-assessments-status-reports/humpback-whale-2022.html

ADDITIONAL DATA SOURCES (not downloaded, require request or extraction):
- BC Cetacean Sightings Network / Ocean Wise Sightings Network (wildwhales.org)
  25,000+ sighting records available as downloadable CSV
  Effort-corrected indices possible but raw sighting data (not abundance)
  URL: https://wildwhales.org/

- Happynook/North Coast Cetacean Society (bcwhales.org)
  Photo-ID and sighting data for northern BC humpbacks
  URL: https://bcwhales.org/humpback-whales/

- Acoustic monitoring at Haida Gwaii (Gwaii Haanas)
  SG̱ang Gwaay (2009-2011), Gowgaia Slope (2017-2019), Ramsay Island (2018-2019)
  Ref: Wright et al. 2022, Scientific Reports
  URL: https://www.nature.com/articles/s41598-022-22069-4

NOTES:
- No Haida Gwaii-specific humpback whale population time series exists
- Best approach: Use basin-wide Cheeseman et al. estimates as proxy for
  regional humpback pressure, supplemented by PRISMM spatial density data
  to estimate proportion in Hecate Strait / Haida Gwaii waters
- The Cheeseman et al. GitHub repo may have feeding-area-specific estimates
  (SE Alaska / Northern BC feeding area had 572-1,471 IDs per season)

================================================================================
SUMMARY: DATA GAPS AND RECOMMENDED NEXT STEPS
================================================================================

WHAT WE HAVE:
[x] Harbour seal haul-out counts, Haida Gwaii, 1966-2019 (CSV, site-level)
[x] Steller sea lion breeding counts, Haida Gwaii, 1971-2013 (CSV, site-level)
[x] Steller sea lion 2016-17 counts (shapefile format)
[x] Humpback whale North Pacific abundance, 2002-2021 (basin-wide, from paper)
[x] Humpback whale BC spatial density, 2018 single snapshot (shapefile)

WHAT WE NEED:
[ ] Steller sea lion counts 2017-present for Haida Gwaii — contact DFO
[ ] Harbour seal data post-2019 — contact Sheena Majewski
[ ] Humpback whale feeding-area-specific estimates from Cheeseman GitHub
[ ] Reconcile harbour seal raw counts with population estimates using
    correction factors from Olesiuk (2010) / SAR 2022/034

RECOMMENDED DATA REQUESTS:
1. Email Sheena.Majewski@dfo-mpo.gc.ca for:
   - Updated harbour seal counts post-2019
   - Updated Steller sea lion site-level counts post-2017
   - Regional harbour seal abundance estimates for Haida Gwaii

2. Email Chad.Nordstrom@dfo-mpo.gc.ca for:
   - 2016-17 SSL data in tabular (CSV) format

3. Email Brianna.Wright@dfo-mpo.gc.ca for:
   - Any updated cetacean survey data post-2018 PRISMM

4. Check Cheeseman et al. GitHub for feeding-area stratified estimates:
   https://github.com/tedcheese/RSOS-NPAC-abundance

5. Download BC Cetacean Sightings Network data from wildwhales.org
   (sighting indices, not abundance, but useful for relative trends)
