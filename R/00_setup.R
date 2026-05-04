# ============================================================================
# 00_setup.R — Constants, packages, and configuration
# stier-2027-herring-metapopulation
#
# Single source of truth for all site definitions, year ranges, paths,
# and package loading. Source this at the top of every script.
# ============================================================================

# Reader note:
# This file defines the fixed dimensions and names that every maintained file
# assumes. If an object elsewhere has unexpected rows, columns, or site labels,
# come back here before debugging downstream code.

# ── Packages ──
library(tidyverse)
library(here)
library(janitor)

# ── Year ranges ──
YEAR_START       <- 1951L
YEAR_END_LEGACY  <- 2015L
YEAR_END_UPDATED <- 2025L
YEAR_END         <- YEAR_END_UPDATED
YEARS            <- seq(YEAR_START, YEAR_END)
N_YEARS          <- length(YEARS)

# ── Site definitions ──
# 13 DFO statistical sections at Haida Gwaii
# Sections 4 (Cartwright Sound) and 11 (Masset Inlet) are dropped
# due to sparse/unreliable spawn survey data
SECTIONS_ALL <- tibble(
  section = c(1, 2, 3, 4, 5, 6, 11, 12, 21, 22, 23, 24, 25),
  section_name = c(
    "Tasu Sound & Gowgaia Bay", "Port Louis", "Rennell Sound",
    "Cartwright Sound", "Englefield Bay", "Louscoone Inlet",
    "Masset Inlet", "Naden Harbour", "Juan Perez Sound",
    "Skidegate Inlet", "Cumshewa Inlet", "Laskeek Bay", "Skincuttle Inlet"
  )
)

SECTIONS_DROP <- c(4L, 11L)
SECTIONS_KEEP <- SECTIONS_ALL |> filter(!section %in% SECTIONS_DROP) |> pull(section)
SITE_NAMES    <- SECTIONS_ALL |> filter(!section %in% SECTIONS_DROP) |> pull(section_name)
N_SITES       <- length(SECTIONS_KEEP)

# ── Survey method transition ──
# Surface era: 1951-1989
# Mixed transition era: 1990-1992
# SCUBA/dive era: 1993-present
SURVEY_MIXED_START_YEAR <- 1990L
SURVEY_DIVE_START_YEAR <- 1993L
SURVEY_TRANSITION_YEAR <- SURVEY_MIXED_START_YEAR # backward-compatible alias

# ── PDO months for spring average ──
PDO_MONTHS <- c(3L, 4L, 5L, 6L)  # March-June

# ── Paths ──
PATH_RAW_LEGACY   <- here("Data", "raw", "legacy-2019")
PATH_RAW_DFO      <- here("Data", "raw", "dfo-spawn")
PATH_RAW_CATCH    <- here("Data", "raw", "dfo-catch")
PATH_RAW_ENV      <- here("Data", "raw", "environmental")
PATH_RAW_PRED     <- here("Data", "raw", "predators")
PATH_RAW_SSL      <- here("Data", "raw", "steller-sea-lions")
PATH_RAW_SEAL     <- here("Data", "raw", "harbour-seals")
PATH_PROCESSED    <- here("Data", "processed")
PATH_OUTPUT       <- here("Output")
PATH_FIGURES      <- here("Output", "figures")

# Create output directories if needed
walk(c(PATH_PROCESSED, PATH_FIGURES, here("Output", "posteriors"),
       here("Output", "tables")),
     \(p) dir.create(p, showWarnings = FALSE, recursive = TRUE))

# ── Color palette (publication + lecture) ──
PAL <- list(
  teal      = "#4ECDC4",
  coral     = "#C45A3C",
  sand      = "#E8A87C",
  gold      = "#F7B731",
  navy      = "#0A2E4A",
  dark_bg   = "#0F1117",
  warm_white = "#FAF9F6",
  # Okabe-Ito colorblind-safe
  okabe_ito = c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
                "#0072B2", "#D55E00", "#CC79A7", "#000000")
)

# ── Shared ggplot2 theme (publication) ──
theme_pub <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "Helvetica") +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
      axis.line = element_line(color = "grey30", linewidth = 0.4),
      axis.ticks = element_line(color = "grey30", linewidth = 0.3),
      strip.text = element_text(face = "bold", size = rel(0.9)),
      plot.title = element_text(face = "bold", size = rel(1.1)),
      plot.margin = margin(10, 10, 10, 10, "mm"),
      legend.position = "bottom"
    )
}

# ── Dark lecture theme ──
theme_lecture <- function(base_size = 18) {
  theme_minimal(base_size = base_size, base_family = "Helvetica") +
    theme(
      plot.background = element_rect(fill = PAL$dark_bg, color = NA),
      panel.background = element_rect(fill = PAL$dark_bg, color = NA),
      panel.grid.major = element_line(color = "#1E2028", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      axis.text = element_text(color = "#9A9485", size = rel(0.85)),
      axis.title = element_text(color = "#C8C2B6", size = rel(0.95)),
      axis.line = element_line(color = "#333333", linewidth = 0.4),
      strip.text = element_text(color = "#E8E2D6", size = rel(0.9), face = "bold"),
      strip.background = element_rect(fill = "#151820", color = NA),
      plot.title = element_text(color = "#F5F0E8", size = rel(1.2), face = "bold"),
      plot.subtitle = element_text(color = "#B0A898", size = rel(0.85)),
      legend.text = element_text(color = "#B0A898"),
      legend.title = element_text(color = "#C8C2B6"),
      legend.position = "bottom"
    )
}

cat("Setup loaded:", N_SITES, "sites,", N_YEARS, "years (",
    YEAR_START, "-", YEAR_END, ")\n")
