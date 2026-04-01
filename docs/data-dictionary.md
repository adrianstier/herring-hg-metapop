# Data Dictionary

Variables across all data sources for the Haida Gwaii herring metapopulation analysis.

---

## 1. Spawn Index Data

**Source:** DFO Pacific Herring Spawn Index (2025 release)
**Raw file:** `Data/raw/dfo-spawn/Pacific_herring_spawn_index_data_2025_EN.csv`
**Legacy file:** `Data/raw/legacy-2019/HG_Spawn_Survey_1940_2015.csv`
**Processed file:** `Data/processed/HG_Spawn_Survey_1951_2025_all_sections.csv`
**Coverage:** 1951--2025, 13 DFO statistical sections

| Variable | Type | Units | Description |
|----------|------|-------|-------------|
| `year` | integer | — | Calendar year of spawn survey |
| `section` | integer | — | Legacy section identifier (1--6, 11--12, 21--25). Sections 4 (Cartwright Sound) and 11 (Masset Inlet) are dropped in analysis due to sparse data. |
| `section_name` | character | — | Human-readable section name (e.g., "Skidegate Inlet", "Juan Perez Sound") |
| `totalrecords` | integer | count | Number of spawn survey location records aggregated for that section-year. Zero if no spawning observed. |
| `SHI` | numeric | tonnes | Spawn Habitat Index. Sum of Surface + Macrocystis + Understory egg deposition estimates across all locations in the section-year. Zero indicates no spawning detected. |
| `total_length` | numeric | m | Total linear extent of spawn observed across all locations in the section-year |
| `mean_width` | numeric | m | Mean width of spawn deposits across locations |
| `spawn_date_xbar` | numeric | day-of-year | Mean spawn start date (Julian day) across locations |
| `spawn_date_sd` | numeric | days | Standard deviation of spawn start dates |
| `spawn_date_min` | numeric | day-of-year | Earliest spawn start date (Julian day) |
| `spawn_date_max` | numeric | day-of-year | Latest spawn start date (Julian day) |
| `dive_survey_pct` | numeric | % (0--100) | Percentage of location records using dive survey method (vs. surface survey). Transition from surface to dive surveys occurred ~1988. |
| `latitude` | numeric | decimal degrees N | Mean latitude of spawn locations |
| `longitude` | numeric | decimal degrees E | Mean longitude of spawn locations (negative = west) |

**Notes:**
- SHI = 0 means no spawning was detected; these are real biological zeros, not missing data.
- The model uses `log(SHI)`, so zeros become missing (NA) in the log-transformed observation matrix.
- 11 sections retained for analysis after dropping sections 4 and 11.
- Survey method transition year: 1988 (surface to SCUBA dive surveys). The model estimates separate catchability coefficients (q) for each method.

### Section Mapping

| Legacy Section | DFO Section | Name | DFO Region | Retained |
|:-:|:-:|---|:-:|:-:|
| 1 | 001 | Tasu Sound & Gowgaia Bay | A2W | Yes* |
| 2 | 002 | Port Louis | A2W | Yes |
| 3 | 003 | Rennell Sound | A2W | Yes |
| 4 | 004 | Cartwright Sound | A2W | **Dropped** |
| 5 | 005 | Englefield Bay | A2W | Yes |
| 6 | 006 | Louscoone Inlet | HG | Yes |
| 11 | 011 | Masset Inlet | NA | **Dropped** |
| 12 | 012 | Naden Harbour | NA | Yes* |
| 21 | 021 | Juan Perez Sound | HG | Yes |
| 22 | 022 | Skidegate Inlet | NA | Yes |
| 23 | 023 | Cumshewa Inlet | HG | Yes |
| 24 | 024 | Laskeek Bay | HG | Yes |
| 25 | 025 | Skincuttle Inlet | HG | Yes |

*Tasu Sound and Naden Harbour are retained in the model but excluded from portfolio/synchrony calculations due to sparse or uncertain data.

---

## 2. Catch Data

**Source:** DFO Pacific Herring commercial catch records
**Raw files:** `Data/raw/legacy-2019/herring_catch_local2015.csv`, `Data/raw/dfo-catch/herring_catch_local2024.csv`
**Processed file:** `Data/processed/herring_catch_local_1950_2024.csv`
**Coverage:** 1950--2024, 13 sections (matching spawn data)

| Variable | Type | Units | Description |
|----------|------|-------|-------------|
| `Year` | integer | — | Calendar year |
| `Num_Record` | integer | count | Number of catch records reported |
| `TotalCatch` | numeric | tonnes | Total commercial catch across all gear types |
| `CatchJan_Apr` | numeric | tonnes | Catch during January--April (spring roe fishery season). Used in the model for estimating proportion caught (Pc). |
| `CatchMay_Aug` | numeric | tonnes | Catch during May--August |
| `CatchSep_Dec` | numeric | tonnes | Catch during September--December |
| `Gillnet` | numeric | tonnes | Catch by gillnet gear |
| `Seine` | numeric | tonnes | Catch by seine gear |
| `Trawl` | numeric | tonnes | Catch by trawl gear |
| `SOK` | numeric | tonnes | Spawn-on-kelp (k'aaw) harvest |
| `Section` | integer | — | Legacy section identifier (matches spawn data) |
| `Name` | character | — | Section name |
| `Latitude` | numeric | decimal degrees N | Section centroid latitude |
| `Longitude` | numeric | decimal degrees E | Section centroid longitude |

**Notes:**
- The Haida Gwaii herring roe fishery was closed in 2005 and has remained closed through 2024. Post-2005 catch values are zero or NA for commercial categories.
- `CatchJan_Apr` (spring catch) is the primary variable used in the model to compute fishing mortality.
- Food, social, and ceremonial (FSC) harvest data may not be fully captured.
- SOK (spawn-on-kelp, k'aaw) is an egg harvest (non-lethal to adults); Shelton et al. (2014) showed it falls in the "safe zone" for population impact.

---

## 3. PDO (Pacific Decadal Oscillation)

**Source:** NOAA JISAO (Joint Institute for the Study of the Atmosphere and Ocean)
**Raw files:** `Data/raw/legacy-2019/pdo.csv`, `Data/raw/environmental/pdo_2015_2025.csv`
**Processed file:** `Data/processed/pdo_combined_1854_2025.csv`
**Coverage:** 1854--2025, monthly

| Variable | Type | Units | Description |
|----------|------|-------|-------------|
| `Value` | numeric | unitless index | Monthly PDO index value. Positive = warm phase (El Nino-like), negative = cool phase (La Nina-like). |
| `year` | integer | — | Calendar year |
| `month` | integer | — | Calendar month (1--12) |

**Notes:**
- The model uses the spring average (March--June, months 3--6) PDO index as the environmental covariate.
- Positive PDO values are associated with reduced herring productivity at Haida Gwaii.
- The 2014--2016 "blob" marine heatwave appears as strongly positive PDO values.

---

## 4. SST (Sea Surface Temperature)

**Source:** NOAA OISST (Optimum Interpolation Sea Surface Temperature)
**Raw files:** `Data/raw/environmental/oisst_haida_gwaii_*.csv`
**Processed file:** `Data/processed/sst_haida_gwaii_monthly.csv`
**Coverage:** 2014--2025, monthly (Haida Gwaii region spatial average)

| Variable | Type | Units | Description |
|----------|------|-------|-------------|
| `year` | integer | — | Calendar year |
| `month` | integer | — | Calendar month (1--12) |
| `sst_mean` | numeric | degrees C | Regional mean SST averaged across OISST grid cells in the Haida Gwaii bounding box |
| `sst_anom_mean` | numeric | degrees C | Regional mean SST anomaly (departure from 1971--2000 climatology) |
| `n_cells` | integer | count | Number of grid cells included in the spatial average |

**Notes:**
- Coverage begins in 2014; earlier SST data would need to come from other sources.
- The marine heatwave ("blob") period (2014--2016) is clearly visible as sustained positive anomalies.
- SST anomaly is computed relative to NOAA's 1971--2000 climatological baseline.

---

## 5. Chlorophyll-a

### MODIS (Aqua)

**Source:** NASA MODIS Aqua Level 3 satellite ocean color
**Raw file:** `Data/raw/environmental/modis_chla_monthly_haida_gwaii_2003_2022.csv`
**Coverage:** 2003--2022, monthly, Haida Gwaii region

| Variable | Type | Units | Description |
|----------|------|-------|-------------|
| `time` | datetime (UTC) | — | Timestamp of monthly composite |
| `latitude` | numeric | degrees N | Grid cell latitude |
| `longitude` | numeric | degrees E | Grid cell longitude |
| `chlorophyll` | numeric | mg m^-3 | Chlorophyll-a concentration. NaN in winter months due to low light. |

### VIIRS (SNPP)

**Source:** NASA VIIRS SNPP Level 3 satellite ocean color
**Raw file:** `Data/raw/environmental/viirs_chla_monthly_haida_gwaii_2012_2026.csv`
**Coverage:** 2012--2026, monthly, Haida Gwaii region

| Variable | Type | Units | Description |
|----------|------|-------|-------------|
| `time` | datetime (UTC) | — | Timestamp of monthly composite |
| `altitude` | numeric | m | Altitude (always 0.0 for surface) |
| `latitude` | numeric | degrees N | Grid cell latitude |
| `longitude` | numeric | degrees E | Grid cell longitude |
| `chlor_a` | numeric | mg m^-3 | Chlorophyll-a concentration. NaN in winter months. |

**Notes:**
- MODIS and VIIRS overlap 2012--2022; cross-calibration may be needed.
- High-latitude winter months have extensive NaN values due to insufficient light for satellite retrieval.
- Chlorophyll-a is a proxy for primary productivity and food availability for herring.

---

## 6. Steller Sea Lion (Eumetopias jubatus)

**Source:** DFO Open Government Portal
**Raw file:** `Data/raw/predators/Steller_Sea_Lion_Summer_counts_from_Haulout_Locations.csv`
**Coverage:** 1971--2013, BC coast including Haida Gwaii haulout sites

| Variable | Type | Units | Description |
|----------|------|-------|-------------|
| `REGION` | character | — | BC coast region (e.g., "Haida Gwaii", "WCVI") |
| `SITE` | character | — | Haulout or rookery site name |
| `SITE TYPE` | character | — | "Y" for breeding site, blank for haulout only |
| `LATITUDE` | numeric | decimal degrees N | Site latitude |
| `LONGITUDE` | numeric | decimal degrees E | Site longitude |
| `SURVEY YEAR` | integer | — | Year of aerial or ground survey |
| `COUNT NON-PUP` | integer | count | Non-pup count (adults + juveniles) at haulout |
| `COUNT NON-PUP INTERPOLATED/EXTRAPOLATED` | integer | count | Interpolated/extrapolated non-pup count for years without direct survey |
| `COUNT PUP` | integer | count | Pup count at breeding colonies |
| `COUNT PUP INTERPOLATED/EXTRAPOLATED` | integer | count | Interpolated/extrapolated pup count |
| `COUNT PUP PRE-ROOKERY` | integer | count | Pre-rookery pup count |
| `COUNT PUP PRE-ROOKERY INTERPOLATED/EXTRAPOLATED` | integer | count | Interpolated/extrapolated pre-rookery pup count |

**Notes:**
- Filter to REGION == "Haida Gwaii" for analysis.
- Haida Gwaii sites include: Anthony Island, Cape St. James, Cone Head, Garcin Rocks, Joseph Rocks, Joyce Rocks, Langara Island, Marble Island, Moresby Islets, and others.
- Additional 2016--2017 data exists in shapefile format only (`SSL_2016-17_Shapefiles.zip`).
- Eastern DPS growth rate 1987--2017: ~4.25%/yr (NOAA 2024).
- Legacy Excel data: `Data/raw/steller-sea-lions/SSL Breeding Season Counts 1971-2013_ACS_Dec15.xlsx`

---

## 7. Harbour Seal (Phoca vitulina richardii)

**Source:** DFO Open Government Portal
**Raw file:** `Data/raw/predators/Harbour_seal_counts_haulout_locs_BCcoast.csv`
**Coverage:** 1966--2019, BC coast (filter to Haida Gwaii)

| Variable | Type | Units | Description |
|----------|------|-------|-------------|
| `SubsiteID` | character | — | Unique haulout subsite identifier (e.g., "H0001") |
| `FirstDocumented` | integer | — | Year the subsite was first documented |
| `Region` | character | — | BC coast region; filter to "Haida Gwaii" |
| `Complex` | character | — | Haulout complex name (group of nearby sites) |
| `Subarea` | character | — | Subarea within region |
| `Year` | integer | — | Survey year |
| `Date` | date | — | Survey date |
| `Longitude` | numeric | decimal degrees E | Site longitude |
| `Latitude` | numeric | decimal degrees N | Site latitude |
| `complex_count` | integer | count | Number of seals counted at the haulout complex |

**Notes:**
- Raw counts require correction factors to estimate population abundance (see Olesiuk 2010).
- Coast-wide estimate: ~85,400 (95% CI: 82,000--88,900) in 2015--2019 (DFO 2022).
- Haida Gwaii PBR (Potential Biological Removal): 418 seals, implying regional abundance ~8,000--12,000.
- Population may be stable or slightly declining from peak of ~105,000 coast-wide.

---

## 8. Humpback Whale (Megaptera novaeangliae)

**Source:** Cheeseman et al. 2024, Royal Society Open Science
**Raw file:** `Data/raw/predators/humpback_whale_NorthPacific_abundance_Cheeseman2024.csv`
**Coverage:** 2002--2021, North Pacific basin-wide mark-recapture estimates

| Variable | Type | Units | Description |
|----------|------|-------|-------------|
| `Year` | integer | — | Calendar year |
| `Abundance` | integer | count | Estimated basin-wide North Pacific humpback whale abundance from mark-recapture |
| `SE` | numeric | count | Standard error of abundance estimate |
| `CI_lower` | numeric | count | Lower 95% confidence interval |
| `CI_upper` | numeric | count | Upper 95% confidence interval |
| `Source` | character | — | Citation (all from Cheeseman et al. 2024) |

**Notes:**
- These are basin-wide estimates, not Haida Gwaii-specific. Used as a proxy for regional humpback pressure.
- Key trajectory: growth phase 2002--2013 (~5.9%/yr), peak ~33,488 in 2012, decline 2014--2021 (~-3.0%/yr) to ~26,662.
- DFO PRISMM survey (2018) estimated 7,030 humpbacks in Canadian Pacific waters.
- No Haida Gwaii-specific population time series exists.

---

## Model Variables (Derived)

Variables estimated by the state-space model (Stan) and stored in posterior draws.

| Variable | Dimensions | Scale | Description |
|----------|-----------|-------|-------------|
| `Z[t,j]` | N_years x N_sites | log | Pre-fishing latent log spawn biomass at time t, site j |
| `X[t,j]` | N_years x N_sites | log | Post-fishing latent log spawn biomass (Z adjusted for catch) |
| `U` | scalar | log | Global mean population growth rate (shared across sites) |
| `pdocoef` | scalar | log | Effect of spring PDO on population growth rate |
| `Pc[k]` | N_catch | probability (0--1) | Proportion of biomass caught for each (year, site) with catch > 0 |
| `Pc_mat[t,j]` | N_years x N_sites | probability (0--1) | Full matrix of catch proportions (0 where no catch) |
| `sigma` | scalar | log | Process error standard deviation (diagonal and equal) |
| `sigma_obs` | scalar | log | Observation error standard deviation |
| `log_q[1]` | scalar | log | Log catchability for surface surveys (1950--1987) |
| `log_q[2]` | scalar | log | Log catchability for dive surveys (1988--present) |
| `delta[t,j]` | N_years x N_sites | log | Site-specific process error deviations |

---

## Year Ranges and Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `YEAR_START` | 1950 | First year of analysis |
| `YEAR_END_LEGACY` | 2015 | Last year of Stier et al. 2020 dataset |
| `YEAR_END_UPDATED` | 2024 | Last year of updated dataset |
| `N_SITES` | 11 | Number of sections retained (13 total minus 2 dropped) |
| `SURVEY_TRANSITION_YEAR` | 1988 | Year of transition from surface to dive surveys |
| `PDO_MONTHS` | 3, 4, 5, 6 | Months used for spring PDO average (March--June) |
| `SECTIONS_DROP` | 4, 11 | Sections excluded (Cartwright Sound, Masset Inlet) |
