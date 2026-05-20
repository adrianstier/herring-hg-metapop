# ============================================================================
# 07ay_biomass_uncertainty_decomposition.R
# Explain why the current all-11 biomass interval is so wide.
# ============================================================================

library(tidyverse)
library(here)
library(rstan)
library(patchwork)
library(scales)

proj_dir <- here::here()
data_dir <- file.path(proj_dir, "Data", "processed")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "jags_model_inputs_v2.RData"))

model_name <- "m1_stier_11"
fit_path <- file.path(data_dir, paste0(model_name, "_fit.rds"))
if (!file.exists(fit_path)) {
  stop("Promoted baseline fit not found: ", fit_path)
}

fit <- readRDS(fit_path)
post <- rstan::extract(fit, pars = "X")

years <- jags_data$years
site_names <- jags_data$site_names
current_year <- max(years)
current_t <- which(years == current_year)
focal_drop <- c("Tasu Sound & Gowgaia Bay", "Naden Harbour")
focal_idx <- which(!site_names %in% focal_drop)
all_idx <- seq_along(site_names)

x_current <- exp(post$X[, current_t, all_idx, drop = FALSE][, 1, ])
colnames(x_current) <- site_names

total_all <- rowSums(x_current)
total_focal <- rowSums(x_current[, focal_idx, drop = FALSE])
tail_threshold <- quantile(total_all, 0.95, na.rm = TRUE)
tail_draw <- total_all >= tail_threshold

summarise_draws <- function(x) {
  tibble(
    mean = mean(x, na.rm = TRUE),
    median = median(x, na.rm = TRUE),
    lo80 = quantile(x, 0.10, na.rm = TRUE),
    hi80 = quantile(x, 0.90, na.rm = TRUE),
    lo90 = quantile(x, 0.05, na.rm = TRUE),
    hi90 = quantile(x, 0.95, na.rm = TRUE),
    lo95 = quantile(x, 0.025, na.rm = TRUE),
    hi95 = quantile(x, 0.975, na.rm = TRUE)
  )
}

total_summary <- bind_rows(
  summarise_draws(total_all) %>%
    mutate(section_set = "all 11 sections"),
  summarise_draws(total_focal) %>%
    mutate(section_set = "Stier focal 9")
) %>%
  mutate(
    year = current_year,
    model = model_name,
    tail_threshold_95_all11 = as.numeric(tail_threshold),
    .before = 1
  )

section_summary <- map_dfr(seq_along(site_names), function(j) {
  section_draws <- x_current[, j]
  section_share <- section_draws / total_all
  summarise_draws(section_draws) %>%
    mutate(
      year = current_year,
      model = model_name,
      site = j,
      site_name = site_names[j],
      section_set = if_else(j %in% focal_idx, "Stier focal 9", "fit-only sensitivity"),
      median_share_all_draws = median(section_share, na.rm = TRUE),
      mean_share_top5_tail = mean(section_share[tail_draw], na.rm = TRUE),
      p_gt_100k_t = mean(section_draws > 100000, na.rm = TRUE),
      p_gt_500k_t = mean(section_draws > 500000, na.rm = TRUE),
      .before = 1
    )
}) %>%
  arrange(desc(mean_share_top5_tail))

tail_contrib <- section_summary %>%
  transmute(
    site,
    site_name,
    section_set,
    median_t = median,
    hi90_t = hi90,
    hi95_t = hi95,
    median_share_all_draws,
    mean_share_top5_tail,
    p_gt_100k_t,
    p_gt_500k_t
  ) %>%
  arrange(desc(mean_share_top5_tail))

draw_df <- tibble(
  draw = seq_along(total_all),
  `all 11 sections` = total_all,
  `Stier focal 9` = total_focal
) %>%
  pivot_longer(-draw, names_to = "section_set", values_to = "biomass")

section_plot_df <- section_summary %>%
  mutate(site_name = fct_reorder(site_name, median))

p_sections <- ggplot(section_plot_df, aes(y = site_name, colour = section_set)) +
  geom_errorbar(aes(xmin = lo90, xmax = hi90), width = 0.18, linewidth = 0.55) +
  geom_errorbar(aes(xmin = lo80, xmax = hi80), width = 0.32, linewidth = 1.0) +
  geom_point(aes(x = median), size = 1.9) +
  scale_x_log10(labels = label_comma()) +
  scale_colour_manual(values = c("Stier focal 9" = "#0072B2", "fit-only sensitivity" = "#D55E00")) +
  labs(
    x = paste0(current_year, " post-fishing biomass"),
    y = NULL,
    colour = NULL,
    title = "Current biomass uncertainty by section",
    subtitle = "Thick bars are 80% intervals; thin bars are 90% intervals."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_tail <- tail_contrib %>%
  mutate(site_name = fct_reorder(site_name, mean_share_top5_tail)) %>%
  ggplot(aes(x = mean_share_top5_tail, y = site_name, fill = section_set)) +
  geom_col(width = 0.72) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  scale_fill_manual(values = c("Stier focal 9" = "#0072B2", "fit-only sensitivity" = "#D55E00")) +
  labs(
    x = "Mean share of total biomass among top 5% all-11 draws",
    y = NULL,
    fill = NULL,
    title = "Which sections create the upper tail?",
    subtitle = "Shares are computed only in posterior draws where all-11 biomass is above its 95th percentile."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p_total <- ggplot(draw_df, aes(x = biomass, fill = section_set, colour = section_set)) +
  geom_density(alpha = 0.18, linewidth = 0.7) +
  geom_vline(
    data = total_summary,
    aes(xintercept = median, colour = section_set),
    linewidth = 0.5
  ) +
  scale_x_log10(labels = label_comma()) +
  scale_fill_manual(values = c("all 11 sections" = "#009E73", "Stier focal 9" = "#0072B2")) +
  scale_colour_manual(values = c("all 11 sections" = "#009E73", "Stier focal 9" = "#0072B2")) +
  labs(
    x = paste0(current_year, " total post-fishing biomass"),
    y = "Posterior density",
    fill = NULL,
    colour = NULL,
    title = "All-11 versus focal-9 current biomass",
    subtitle = "Vertical lines are medians; the all-11 upper tail is driven by sparse fit-only sections."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

p <- (p_sections | p_tail) / p_total +
  plot_annotation(
    title = "Current Biomass Uncertainty Decomposition",
    subtitle = "Promoted baseline m1_stier_11; biomass is latent model-scale tonnes, not an official assessment estimate."
  )

ggsave(
  file.path(fig_dir, "current_biomass_uncertainty_decomposition.pdf"),
  p,
  width = 250, height = 190, units = "mm", device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "current_biomass_uncertainty_decomposition.png"),
  p,
  width = 250, height = 190, units = "mm", dpi = 300
)

write_csv(total_summary, file.path(diag_dir, "current_biomass_uncertainty_total_summary.csv"))
write_csv(section_summary, file.path(diag_dir, "current_biomass_uncertainty_by_section.csv"))
write_csv(tail_contrib, file.path(diag_dir, "current_biomass_uncertainty_tail_contributions.csv"))

fmt <- function(x, accuracy = 1) {
  number(x, accuracy = accuracy, big.mark = ",")
}

top_tail <- tail_contrib %>%
  slice_head(n = 5)

sensitivity_tail_share <- tail_contrib %>%
  filter(section_set == "fit-only sensitivity") %>%
  summarise(value = sum(mean_share_top5_tail, na.rm = TRUE)) %>%
  pull(value)

lines <- c(
  "# Current Biomass Uncertainty Decomposition",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Read",
  "",
  paste0(
    "- The ", current_year, " all-11 median is `",
    fmt(total_summary$median[total_summary$section_set == "all 11 sections"]),
    " t`, but the upper interval is inflated by sparse fit-only sections."
  ),
  paste0(
    "- The Stier focal-9 median is `",
    fmt(total_summary$median[total_summary$section_set == "Stier focal 9"]),
    " t`, with a much narrower 90% interval (`",
    fmt(total_summary$lo90[total_summary$section_set == "Stier focal 9"]),
    "`-`",
    fmt(total_summary$hi90[total_summary$section_set == "Stier focal 9"]),
    " t`)."
  ),
  paste0(
    "- Fit-only sensitivity sections account for `",
    percent(sensitivity_tail_share, accuracy = 1),
    "` of biomass in the top 5% of all-11 posterior draws."
  ),
  "",
  "## Top Upper-Tail Contributors",
  "",
  knitr::kable(
    top_tail %>%
      transmute(
        section = site_name,
        section_set,
        median_t = round(median_t),
        hi90_t = round(hi90_t),
        top5_tail_share = percent(mean_share_top5_tail, accuracy = 1),
        p_gt_100k_t = percent(p_gt_100k_t, accuracy = 0.1)
      ),
    format = "pipe"
  ),
  "",
  "## Interpretation",
  "",
  "- The median biomass estimate is not the same problem as the upper-tail uncertainty.",
  "- For talks, present all-11 biomass as the model-scale full-archipelago estimate, then immediately show the focal-9 sensitivity and tail decomposition.",
  "- Do not use the all-11 90% upper interval as a headline abundance claim; it is dominated by sparse sections that are retained for model completeness.",
  "",
  "## Files",
  "",
  "- `Output/figures/current_biomass_uncertainty_decomposition.pdf`",
  "- `Output/diagnostics/current_biomass_uncertainty_total_summary.csv`",
  "- `Output/diagnostics/current_biomass_uncertainty_by_section.csv`",
  "- `Output/diagnostics/current_biomass_uncertainty_tail_contributions.csv`"
)

writeLines(lines, file.path(diag_dir, "current_biomass_uncertainty_decomposition.md"))
cat(paste(lines, collapse = "\n"))
cat("\n")
