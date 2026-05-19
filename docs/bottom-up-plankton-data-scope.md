# Bottom-Up Plankton / Bloom Data Scope

Generated: 2026-05-18

Purpose: define a safe, practical data path for testing whether Haida Gwaii
herring non-recovery has a Blob / marine-heatwave / bottom-up energy component.
This note is interpretive and data-scoping only; it does not promote a new Stan
branch over `m1_stier_11`.

## Clear Answer

We can test the satellite-bloom version now, and the first result is weak as a
direct explanation. A new 8-day MODIS Aqua chlorophyll product for 51.5-54.5N,
129-133W shows that the 2014-2016 Blob/MHW years had similar or slightly higher
spring Chl-a intensity than adjacent eras, but a later median spring peak:

- pre-Blob satellite years, 2003-2013: median spring Chl-a 2.12 mg m-3; median
  peak DOY 141; median occupied sections 7.
- Blob/MHW years, 2014-2016: median spring Chl-a 2.30 mg m-3; median peak DOY
  157; median occupied sections 4.
- post-Blob satellite years, 2017-2025: median spring Chl-a 2.10 mg m-3; median
  peak DOY 125; median occupied sections 5.

The growth screen does not promote a bloom covariate: all timing/intensity rows
are `weak_screen_only`. Same-year spring Chl-a has a moderate detrended
correlation with `m1_stier_11` latent growth (`r = 0.36`) but essentially no
PDO/fishing/year-adjusted beta (`0.014`). The current answer is therefore:

> The Blob remains a plausible stress window, but the available satellite Chl-a
> screen does not show a clean bottom-up biomass failure that explains adult
> herring non-recovery. The more defensible bottom-up hypothesis is prey-quality
> or secondary-production reshuffling: zooplankton composition, euphausiids,
> lipid-rich Neocalanus / large calanoids, southern copepod intrusion, gelatinous
> plankton, and match-mismatch timing.

## Local Products

New reproducible screen:

- Script: `Code/07bw_bloom_phenology_link_screen.R`
- 8-day regional Chl-a: `Data/processed/chla_haida_gwaii_8day_regional_modis_r2022sq.csv`
- Annual bloom metrics: `Data/processed/bloom_phenology_haida_gwaii_8day_modis_proxy.csv`
- Herring link screen: `Output/diagnostics/bloom_phenology_herring_link_screen.csv`
- Readout: `Output/diagnostics/bloom_phenology_herring_screen.md`
- Figure: `Output/figures/bloom_phenology_herring_screen.pdf`

Data source: NOAA CoastWatch ERDDAP, `erdMH1chla8day_R202SQ`, NASA/GSFC OBPG
MODIS Aqua R2022 science-quality 8-day chlorophyll-a, queried over 51.5-54.5N
and 129-133W.

## Online Data Sources

### 1. DFO BioChem

Best official access path for in-situ biological and chemical data. BioChem is
DFO's archive for discrete bottle data including chlorophyll, nutrients, oxygen,
and plankton tow data including species counts and biomass measurements. Use the
query application after account registration.

Status: official and relevant, but requires registration/email access. This is
the likely route for a reproducible machine-readable extract.

Access:

- Overview: https://www.dfo-mpo.gc.ca/science/data-donnees/biochem/index-eng.html
- Query app: https://inter-j02.dfo-mpo.gc.ca/bcq-bcr/home-accueil
- Contact: `biochem.xent@dfo-mpo.gc.ca`

### 2. DFO Pacific / IOS Zooplankton Database

Best Haida Gwaii biological source. DFO describes this as a Microsoft Access
application holding about 350,000 detailed species records from about 9,500
oceanographic sampling stations across most of the northeast Pacific, 42-65N and
120-180W. Fields include date, mission, position, net type, genus/species,
length, weight, and split fractions.

Status: relevant, but not a simple public CSV. Request a Haida Gwaii / Hecate
Strait extract from DFO/IOS or through BioChem.

Access:

- Overview: https://www.dfo-mpo.gc.ca/science/species-especes/plankton-plancton/basedonnees-zooplankton-database/index-eng.html
- Contact listed there: Moira Galbraith, DFO Institute of Ocean Sciences.

### 3. DFO Offshore Haida Gwaii Overview Extract

A 2025 CSAS research document confirms that DFO has already extracted regional
zooplankton sampling events around Offshore Haida Gwaii Network Zones, west
Haida Gwaii, Dixon Entrance, and Hecate Strait from the DFO Pacific Zooplankton
Database. Key details:

- a Hecate Strait zooplankton time series exists for 2000-present, pieced
  together from various sources;
- the broader OHGNZ vicinity extract covers 1980-2021;
- methods are 236 um mesh bongo nets towed vertically from 250 m or 10 m above
  bottom;
- the report notes 133 comparable samples near the offshore Haida Gwaii network
  zones, with poor within-zone temporal resolution but usable broad-region
  pooling;
- broad-region counts include 65 west Haida Gwaii and 71 Dixon Entrance unique
  sampling events;
- the report already summarizes spring biomass maxima and warm-period copepod
  composition changes.

Status: very relevant evidence that data exist. The report is not enough for
modeling because the plotted/grouped values are not a machine-readable annual
covariate.

Source PDF:
https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41311681.pdf

### 4. OBIS / GBIF DFO IOS Line P Subset

Directly downloadable, but spatially weak for this question. OBIS exposes a
DFO Pacific IOS zooplankton subset for Ocean Station Papa / Line P, including
2,050 events and 30,681 occurrences in the OBIS API metadata. It is offshore
at about 50N, 145W and mostly 1965-1980, so it is useful for methods and
historical northeast Pacific context, not as a Haida Gwaii herring covariate.

Access:

- OBIS: https://obis.org/dataset/1ad423c7-dba3-426f-b814-f0808413a708
- Archive: https://ipt.iobis.org/obiscanada/archive.do?r=obis_dfo_ios_plankton_linep

### 5. DFO Line P Physical / Chemical Data

Direct annual zip downloads exist for Line P 1956-2007, with CTD and chemistry
data. Present sampling includes chlorophyll, HPLC pigment concentrations, and
vertical bongo net hauls, but the Line P location is offshore and south of Haida
Gwaii. Treat it as lower-trophic context, not the primary HG covariate.

Access:

- Program: https://www.dfo-mpo.gc.ca/science/data-donnees/line-p/index-eng.html
- Downloads: https://www.dfo-mpo.gc.ca/science/data-donnees/line-p/data-eng.html

### 6. Hakai Zooplankton

Hakai has a zooplankton abundance/biomass dataset for northern Strait of Georgia
and Central Coast stations, with samples biweekly/monthly since 2015 or every
4-6 weeks since 2012 depending on location. It is not Haida Gwaii, and the
catalog currently says data will be public after paper publication; until then,
request access/collaboration.

Access:

- https://catalogue.hakai.org/dataset/ca-cioos_39a83551-ab8e-45be-a564-cece4b229371

## Data Request Specification

Request machine-readable data for 1980-present where possible, with a priority
window of 2000-2025 and explicit flags for 2014-2016 and 2020-2021. Spatial
extracts should include:

- Hecate Strait / `Kandaliiɢwii` time series;
- Dixon Entrance / `Siigee`;
- west coast Haida Gwaii / `Duu Guusd Daawxuusda`;
- if possible, polygons or nearest assignments to the 11 modeled herring
  sections, but do not force section-level covariates if sampling is too sparse.

Required fields:

- event/sample ID, cruise/mission, station, date/time, latitude, longitude;
- gear, mesh size, tow type, max tow depth, bottom depth, volume filtered if
  available, processing/lab flags;
- total zooplankton biomass in consistent units, ideally dry weight per area or
  volume;
- abundance and biomass by taxon/group, life stage, and size class where
  available;
- at minimum: euphausiids, large calanoid copepods, Neocalanus spp. / subarctic
  lipid-rich copepods, small/medium calanoids, southern-affinity copepods,
  chaetognaths, pteropods, gelatinous plankton, salps;
- sample split fractions and taxa/biomass conversion metadata.

## Model Logic

Do not start with a full Stan branch. Sequence:

1. Build a DFO/Hakai/OBIS lower-trophic data registry and map sample coverage
   against the 11 herring sections and broad HG regions.
2. Aggregate first at broad-region annual/seasonal scale: winter, spring
   spawning/larval window, summer. Do not infer annual values for unsampled
   years without strong justification.
3. Run the same cheap screen used for satellite Chl-a: Spearman, detrended
   correlation, and PDO/fishing/year-adjusted beta against `m1_stier_11` latent
   growth and occupied sections.
4. If a bottom-up metric survives, add a post-data-start active-only annual
   process covariate on the `m1_stier_11` observation layer. Missing pre-data
   years should be inactive, not interpolated.
5. Prefer recruitment/age-2 or juvenile-survival interpretation if DFO
   biological inputs become available; adult biomass growth is a blunt proxy for
   bottom-up larval/juvenile energy pathways.

Talk-safe wording:

> Satellite Chl-a lets us ask whether the Blob years were simply low-bloom
> years; they were not. The stronger unresolved bottom-up question is whether
> prey quality and secondary production shifted: copepod guilds, euphausiids,
> gelatinous plankton, and timing relative to herring larvae. DFO appears to have
> the right zooplankton records for broad Haida Gwaii / Hecate Strait tests, but
> we need a machine-readable extract before treating it as model evidence.
