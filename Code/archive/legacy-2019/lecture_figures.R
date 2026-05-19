# ============================================================================
# Lecture Figures for EEMB 142C Week 1 Wednesday: Herring in the Anthropocene
# Generates slide-optimized figures from Stier et al. 2020 Ecosphere model output
# Output: 3840x2160 PNG (16:9, 4K) with dark background for projected slides
# ============================================================================

library(ggplot2)
library(reshape2)
library(tidyr)
library(gdata)
library(Hmisc)
library(coda)
library(cowplot)
library(here)
library(scales)
library(ggpubr)

# ── Output directory ──
outdir <- here("..", "assets", "lecture-figures")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# Also copy to the 4-fisheries assets location
fishdir <- here("..", "..", "..", "4-fisheries", "assets", "wednesday")

# ── Dark lecture theme ──
# Matches EEMB 142C slide design system: dark bg, cream text, teal/coral accents
theme_lecture <- function(base_size = 18) {
  theme_minimal(base_size = base_size, base_family = "Helvetica") +
    theme(
      plot.background = element_rect(fill = "#0F1117", color = NA),
      panel.background = element_rect(fill = "#0F1117", color = NA),
      panel.grid.major = element_line(color = "#1E2028", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      axis.text = element_text(color = "#9A9485", size = rel(0.85)),
      axis.title = element_text(color = "#C8C2B6", size = rel(0.95)),
      axis.line = element_line(color = "#333333", linewidth = 0.4),
      strip.text = element_text(color = "#E8E2D6", size = rel(0.9), face = "bold",
                                margin = margin(b = 8)),
      strip.background = element_rect(fill = "#151820", color = NA),
      plot.title = element_text(color = "#F5F0E8", size = rel(1.2), face = "bold",
                                margin = margin(b = 10)),
      plot.subtitle = element_text(color = "#9A9485", size = rel(0.8),
                                   margin = margin(b = 15)),
      plot.caption = element_text(color = "#555555", size = rel(0.6), hjust = 0),
      legend.background = element_rect(fill = "#0F1117", color = NA),
      legend.text = element_text(color = "#C8C2B6", size = rel(0.8)),
      legend.title = element_text(color = "#E8E2D6", size = rel(0.85)),
      legend.key = element_rect(fill = "#0F1117", color = NA),
      plot.margin = margin(20, 25, 15, 20)
    )
}

# ── Color palette ──
col_teal     <- "#4ECDC4"
col_coral    <- "#D4544A"
col_sand     <- "#E8A87C"
col_gold     <- "#F7B731"
col_cream    <- "#E8E2D6"
col_muted    <- "#9A9485"
col_ocean    <- "#0A2E4A"

# ── Figure dimensions (16:9 for slides) ──
fig_w <- 13.33   # inches (3840px / 288dpi ≈ 13.33in at 288dpi → 3840px)
fig_h <- 7.5     # inches (2160px / 288dpi ≈ 7.5in)
fig_dpi <- 288   # → exactly 3840 x 2160 px


# ============================================================================
# LOAD DATA
# ============================================================================

# Model output (201 MB)
model_path <- "/Users/adrianstier/Library/CloudStorage/GoogleDrive-astier@ucsb.edu/My Drive/Stier Lab/People/Adrian Stier/Projects/Completed/Herring_Haida_Gwaii/Code/diag_equal_design_c_noUsig_2q_pcnorm2.RData"
load(model_path)

createMcmcList <- function(model) {
  McmcArray <- as.array(model$BUGSoutput$sims.array)
  McmcList <- vector("list", length = dim(McmcArray)[2])
  for (i in seq_along(McmcList)) McmcList[[i]] <- as.mcmc(McmcArray[, i, ])
  mcmc.list(McmcList)
}

myList <- createMcmcList(model)

# Time and sites
years <- seq(1950, 2015)
nYears <- length(years)
nSites <- 11
n.chains <- 4; n.burnin <- 500000; n.thin <- 500; n.iter <- 1000000
runL <- n.chains * (n.iter - n.burnin) / n.thin

# PDO
pdo <- read.csv(here("data", "pdo.csv"))
pdosummer <- subset(pdo, month %in% c(3, 4, 5, 6))
pdoxb <- c(tapply(pdosummer$Value, list(pdosummer$year), mean))
pdo2 <- pdoxb[97:162]  # 1940-2015
pdo3 <- pdo2[11:76]    # 1950-2015
names(pdo3) <- years

# Spawn Index
x <- read.csv(here("data", "HG_Spawn_Survey_1940_2015.csv"))
x <- x[c(1, 3, 13, 14, 15, 16)]
x$presabs <- ifelse(x$SHI > 0, 1, 0)
x2 <- x[, c(1, 2, 4)]
w <- reshape(x2, timevar = "section_name", idvar = c("year"), direction = "wide")[, -1]
w[w == 0] <- NA
Y <- as.matrix(w)
Y <- Y[-c(1:10), -c(4, 7)]
Y <- log(Y)
logSHI <- Y

# Catch
cc <- read.csv(here("data", "herring_catch_local2015.csv"))
cc$presabs <- ifelse(cc$TotalCatch > 0, 1, 0)
cc <- drop.levels(subset(cc, Section %in% c(1, 2, 3, 5, 6, 12, 21, 22, 23, 24, 25)))
ctab <- data.frame(tapply(cc$CatchJan_Apr, list(cc$Year, cc$Name), sum))
ctab2 <- ctab[, c(11, 7, 8, 2, 5, 6, 3, 9, 1, 4, 10)]
colnames(Y) <- colnames(ctab2)
ctab2 <- as.matrix(ctab2)
logcatch <- log(ctab2 + 1)


# ============================================================================
# FIGURE 1: FISHING RATE — ARCHIPELAGO VS SUBPOPULATION (KEY FIGURE)
# Slide S14 in revised outline
# ============================================================================

tpc <- model$BUGSoutput$mean$Pc

INDEX <- NULL
for (i in 1:nrow(logcatch)) {
  if (length(logcatch[i, ][logcatch[i, ] > 0]) > 0) {
    temp <- data.frame(row = rep(i, length(which(logcatch[i, ] > 0))),
                       col = which(logcatch[i, ] > 0))
    INDEX <- rbind(INDEX, temp)
  }
}

emat <- matrix(0, nrow = nYears, ncol = nSites)
for (i in 1:nrow(INDEX)) {
  emat[INDEX[i, 1], INDEX[i, 2]] <- tpc[i]
}

colnames(emat) <- colnames(Y)
pc_tab <- melt(emat)
colnames(pc_tab) <- c("year2", "section", "pc")
pc_tab$year <- seq(1950, 2015, 1)

# Archipelago mean (including zeros)
arch <- data.frame(tapply(pc_tab$pc, list(pc_tab$year), mean))
arch$year <- as.numeric(rownames(arch))
names(arch) <- c("pc", "year")

# Subpopulation mean (only where fishing occurred)
pc_tab2 <- subset(pc_tab, pc > 0)
sec <- data.frame(tapply(pc_tab2$pc, list(pc_tab2$year), mean))
sec$year <- as.numeric(rownames(sec))
names(sec) <- c("pc", "year")

fish <- merge(arch, sec, by = "year", all = TRUE)
colnames(fish) <- c("year", "Archipelago-wide", "Subpopulation (where fished)")
fish[is.na(fish)] <- 0
fish2 <- melt(fish, id.vars = "year")
colnames(fish2) <- c("year", "Scale", "Proportion Caught")

p_fishing <- ggplot(fish2, aes(x = year, y = `Proportion Caught`, color = Scale, linetype = Scale)) +
  geom_hline(yintercept = 0.20, color = col_coral, linewidth = 0.6, alpha = 0.5) +
  annotate("text", x = 1952, y = 0.22, label = "20% harvest threshold",
           color = col_coral, size = 4.5, hjust = 0, alpha = 0.7) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2, alpha = 0.8) +
  scale_color_manual(values = c("Archipelago-wide" = col_teal,
                                "Subpopulation (where fished)" = col_coral)) +
  scale_linetype_manual(values = c("Archipelago-wide" = "solid",
                                   "Subpopulation (where fished)" = "solid")) +
  scale_y_continuous(limits = c(0, 0.70), breaks = seq(0, 0.6, 0.2),
                     labels = percent_format(accuracy = 1)) +
  scale_x_continuous(breaks = seq(1950, 2015, 10)) +
  labs(
    title = "The Scale Mismatch: Fishing Rate by Spatial Scale",
    subtitle = "Haida Gwaii Pacific herring, 1950–2015  |  Stier et al. 2020, Ecosphere",
    y = "Proportion of Biomass Caught",
    x = NULL,
    color = NULL, linetype = NULL
  ) +
  theme_lecture(base_size = 18) +
  theme(
    legend.position = c(0.75, 0.90),
    legend.direction = "horizontal"
  )

ggsave(file.path(outdir, "slide_fishing_rate_scale_mismatch.png"),
       plot = p_fishing, width = fig_w, height = fig_h, dpi = fig_dpi, bg = "#0F1117")

cat("Saved: slide_fishing_rate_scale_mismatch.png\n")


# ============================================================================
# FIGURE 2: SUBPOPULATION BIOMASS TIMESERIES (PORTFOLIO EFFECT)
# Slide S15 in revised outline — show 6 key subpopulations
# ============================================================================

s1 <- subset(x, year > 1949)
is.na(s1$SHI) <- !s1$SHI
s2 <- subset(s1, section_name %in% c("Louscoone Inlet", "Juan Perez Sound",
                                      "Rennell Sound", "Skidegate Inlet",
                                      "Skincuttle Inlet", "Englefield Bay"))

# Clean up names for display
s2$section_name <- gsub("\\.", " ", s2$section_name)

p_substocks <- ggplot(s2, aes(x = year, y = SHI)) +
  geom_area(fill = col_teal, alpha = 0.15) +
  geom_line(color = col_teal, linewidth = 0.8) +
  geom_point(color = col_teal, size = 1, alpha = 0.6) +
  facet_wrap(~section_name, scales = "free_y", ncol = 3) +
  scale_x_continuous(breaks = seq(1950, 2010, 20)) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "The Portfolio Effect: Individual Subpopulation Trajectories",
    subtitle = "Haida Gwaii herring spawn index by inlet, 1950–2015  |  Stier et al. 2020, Ecosphere",
    y = "Spawn Index",
    x = NULL
  ) +
  theme_lecture(base_size = 16) +
  theme(
    panel.spacing = unit(1.2, "lines")
  )

ggsave(file.path(outdir, "slide_substock_timeseries_portfolio.png"),
       plot = p_substocks, width = fig_w, height = fig_h, dpi = fig_dpi, bg = "#0F1117")

cat("Saved: slide_substock_timeseries_portfolio.png\n")


# ============================================================================
# FIGURE 3: ESTIMATED BIOMASS WITH CREDIBLE INTERVALS (selected substocks)
# Shows model-estimated biomass with uncertainty — more polished than raw data
# ============================================================================

edf1 <- melt(model$BUGSoutput$sims.array[, , colnames(myList[[1]])[
  which(colnames(myList[[1]]) == "X[1,1]"):which(colnames(myList[[1]]) == "X[66,11]")]])
names(edf1) <- c("num", "chain", "response", "value")

edf1$group <- factor(sort(rep(seq(1:nSites), runL)))
edf1$year2 <- sort(rep(1950:2015, runL * nSites))
edf1$year <- sort(rep(seq(1:nYears), runL * nSites))
edf1$section <- sort(rep(colnames(Y), nYears * runL))

tsmed <- tapply(edf1$value, list(edf1$response), median)
tsupper <- melt(tapply(edf1$value, list(edf1$response), quantile, probs = c(0.95)))
tslower <- melt(tapply(edf1$value, list(edf1$response), quantile, probs = c(0.05)))

xdat <- data.frame(median = exp(tsmed), upper = exp(tsupper[, 2]), lower = exp(tslower[, 2]))
xdat$year <- rep(1950:2015, nSites)

secvec <- colnames(Y)
sec_col <- c()
for (i in 1:11) sec_col <- c(sec_col, rep(secvec[i], 66))
xdat$section <- sec_col

# Clean names
xdat$section <- gsub("\\.", " ", xdat$section)

# Select 6 key substocks for legibility
key_sites <- c("Louscoone Inlet", "Juan Perez Sound", "Skidegate Inlet",
               "Skincuttle Inlet", "Englefield Bay", "Rennell Sound")
xdat_sub <- subset(xdat, section %in% key_sites)

p_biomass <- ggplot(xdat_sub, aes(x = year, y = median)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = col_teal, alpha = 0.2) +
  geom_line(color = col_teal, linewidth = 0.8) +
  facet_wrap(~section, scales = "free_y", ncol = 3) +
  scale_x_continuous(breaks = seq(1950, 2010, 20)) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Estimated Subpopulation Biomass with 90% Credible Intervals",
    subtitle = "Bayesian state-space model  |  Stier et al. 2020, Ecosphere",
    y = "Estimated Biomass",
    x = NULL,
    caption = "Shaded: 5th–95th percentile posterior credible interval"
  ) +
  theme_lecture(base_size = 16) +
  theme(panel.spacing = unit(1.2, "lines"))

ggsave(file.path(outdir, "slide_estimated_biomass_CI.png"),
       plot = p_biomass, width = fig_w, height = fig_h, dpi = fig_dpi, bg = "#0F1117")

cat("Saved: slide_estimated_biomass_CI.png\n")


# ============================================================================
# FIGURE 4: PDO EFFECT ON HERRING POPULATION GROWTH
# Slide S13 — climate forcing component
# ============================================================================

pdocoef <- as.vector(model$BUGSoutput$sims.array[, , "pdocoef"])
pdocoef <- pdocoef[!is.na(pdocoef)]
pdo_matrix <- pdocoef %*% t(pdo3)
pdodf <- t(apply(pdo_matrix, 2, quantile, probs = c(0.025, 0.05, 0.25, 0.5, 0.75, 0.95, 0.975), na.rm = TRUE))
colnames(pdodf) <- c("x.025", "x.05", "x.25", "Median", "x.75", "x.95", "x.975")
pdodf2 <- data.frame(year = as.numeric(names(pdo3)), pdodf)
pdodf2$regime <- ifelse(pdodf2$Median > 0, "Warm (bad for herring)", "Cool (good for herring)")

p_pdo <- ggplot(pdodf2, aes(x = year, y = Median)) +
  geom_hline(yintercept = 0, color = "#444444", linewidth = 0.5) +
  geom_ribbon(aes(ymin = x.05, ymax = x.95), fill = col_muted, alpha = 0.15) +
  geom_ribbon(aes(ymin = x.25, ymax = x.75), fill = col_muted, alpha = 0.25) +
  geom_line(color = col_cream, linewidth = 0.5, linetype = "dashed") +
  geom_point(aes(color = regime), size = 2.5) +
  scale_color_manual(values = c("Warm (bad for herring)" = col_coral,
                                "Cool (good for herring)" = col_teal)) +
  scale_x_continuous(breaks = seq(1950, 2015, 10)) +
  labs(
    title = "Climate Forcing: PDO Effect on Herring Population Growth",
    subtitle = "Warm regimes reduce herring productivity  |  Stier et al. 2020, Ecosphere",
    y = "PDO Effect on Growth Rate",
    x = NULL,
    color = NULL,
    caption = "Shaded: 50% and 90% posterior credible intervals"
  ) +
  theme_lecture(base_size = 18) +
  theme(
    legend.position = c(0.80, 0.90),
    legend.direction = "vertical"
  )

ggsave(file.path(outdir, "slide_pdo_climate_effect.png"),
       plot = p_pdo, width = fig_w, height = fig_h, dpi = fig_dpi, bg = "#0F1117")

cat("Saved: slide_pdo_climate_effect.png\n")


# ============================================================================
# FIGURE 5: FISHING RATE BY SUBPOPULATION (faceted)
# Shows the heterogeneity in fishing pressure — some inlets hit 65%
# ============================================================================

Catch.dummy <- logcatch
Catch.dummy[Catch.dummy > 0] <- 1

fa <- model$BUGSoutput$sims.array[, , colnames(myList[[1]])[
  which(colnames(myList[[1]]) == "Pc[1]"):which(colnames(myList[[1]]) == "Pc[156]")]]
edf_f <- melt(fa)
names(edf_f) <- c("iter", "chain", "response", "value")

pcmed   <- tapply(edf_f$value, list(edf_f$response), median)
pcupper <- tapply(edf_f$value, list(edf_f$response), quantile, probs = 0.95)
pclower <- tapply(edf_f$value, list(edf_f$response), quantile, probs = 0.05)

medINDEX   <- Catch.dummy
upperINDEX <- Catch.dummy
lowerINDEX <- Catch.dummy

for (i in 1:nrow(INDEX)) {
  medINDEX[INDEX[i, 1], INDEX[i, 2]]   <- pcmed[i]
  upperINDEX[INDEX[i, 1], INDEX[i, 2]] <- pcupper[i]
  lowerINDEX[INDEX[i, 1], INDEX[i, 2]] <- pclower[i]
}

fdf <- data.frame(
  melt(medINDEX),
  upper = melt(upperINDEX)$value,
  lower = melt(lowerINDEX)$value
)
names(fdf)[1:3] <- c("year", "site", "median")
fdf$site <- gsub("\\.", " ", fdf$site)

# Only show where fishing happened
fdf_pos <- subset(fdf, median > 0)

# Select key sites
fdf_key <- subset(fdf_pos, site %in% key_sites)

p_fishing_sub <- ggplot(fdf_key, aes(x = year, y = median)) +
  geom_hline(yintercept = 0.20, color = col_coral, linewidth = 0.4, alpha = 0.4, linetype = "dashed") +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.8, color = col_teal, alpha = 0.4) +
  geom_point(color = col_teal, size = 1.5) +
  geom_line(color = col_teal, linewidth = 0.6, alpha = 0.7) +
  facet_wrap(~site, ncol = 3) +
  scale_y_continuous(limits = c(0, 0.8), breaks = seq(0, 0.8, 0.2),
                     labels = percent_format(accuracy = 1)) +
  scale_x_continuous(breaks = seq(1950, 2010, 20)) +
  labs(
    title = "Fishing Pressure by Subpopulation",
    subtitle = "Some inlets experienced >60% harvest while archipelago average was ~15%  |  Stier et al. 2020",
    y = "Proportion Caught",
    x = NULL,
    caption = "Error bars: 5th–95th percentile posterior CI  |  Dashed line: 20% harvest threshold"
  ) +
  theme_lecture(base_size = 16) +
  theme(
    panel.spacing = unit(1.2, "lines"),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave(file.path(outdir, "slide_fishing_rate_by_subpop.png"),
       plot = p_fishing_sub, width = fig_w, height = fig_h, dpi = fig_dpi, bg = "#0F1117")

cat("Saved: slide_fishing_rate_by_subpop.png\n")


# ============================================================================
# Copy key figures to fisheries assets folder
# ============================================================================

files_to_copy <- c(
  "slide_fishing_rate_scale_mismatch.png",
  "slide_substock_timeseries_portfolio.png",
  "slide_estimated_biomass_CI.png",
  "slide_pdo_climate_effect.png",
  "slide_fishing_rate_by_subpop.png"
)

# Copy to 04-political-failure and 03-collapse-data as appropriate
for (f in files_to_copy) {
  src <- file.path(outdir, f)
  if (grepl("fishing_rate", f)) {
    dest_dir <- file.path(fishdir, "04-political-failure")
  } else {
    dest_dir <- file.path(fishdir, "03-collapse-data")
  }
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  file.copy(src, file.path(dest_dir, f), overwrite = TRUE)
  cat("Copied:", f, "->", dest_dir, "\n")
}

cat("\n=== All lecture figures generated ===\n")
cat("Output directory:", outdir, "\n")
cat("Figures: 3840x2160 px (16:9, 4K) with dark lecture theme\n")
