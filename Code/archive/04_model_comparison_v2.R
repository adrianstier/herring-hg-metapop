# ============================================================================
# 04_model_comparison_v2.R — Compare v2 models using LOOIC
# stier-2027-herring-metapopulation
# ============================================================================

library(loo)
library(tidyverse)
library(here)

out_dir <- here("Output", "posteriors")

cat("\n", strrep("=", 60), "\n")
cat(" MODEL COMPARISON (v2)\n")
cat(strrep("=", 60), "\n\n")

# Load LOO objects
loo_files <- list.files(out_dir, pattern = "loo_.*_v2.rds", full.names = TRUE)
model_names <- gsub("loo_|_v2.rds", "", basename(loo_files))

loos <- list()
for (i in seq_along(loo_files)) {
  loos[[model_names[i]]] <- readRDS(loo_files[i])
}

if (length(loos) < 2) {
  cat("Waiting for more models to finish...\n")
  # Try to load M1 v2 if it exists (might be in Data/processed)
  m1_loo_path <- here("Data/processed/m1_v2_loo.rds") # Check if it was saved here
  if (file.exists(m1_loo_path)) {
     loos[["m1"]] <- readRDS(m1_loo_path)
  }
}

if (length(loos) >= 2) {
  comp <- loo_compare(loos)
  print(comp)

  # Save comparison table
  write.csv(as.data.frame(comp), here("Output", "model_comparison_v2.csv"))
  cat("\nComparison saved to Output/model_comparison_v2.csv\n")
} else {
  cat("Only", length(loos), "models available. Need at least 2 for comparison.\n")
  print(names(loos))
}
