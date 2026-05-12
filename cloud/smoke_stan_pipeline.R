library(rstan)
library(posterior)
library(here)

rstan_options(auto_write = TRUE)

read_int_env <- function(name, default) {
  value <- Sys.getenv(name)
  if (!nzchar(value)) {
    return(default)
  }
  as.integer(value)
}

job_id <- Sys.getenv("JOB_ID", unset = "cloud_pipeline_smoke")
chains <- read_int_env("STAN_CHAINS", 1L)
iter <- read_int_env("STAN_ITER", 80L)
warmup <- read_int_env("STAN_WARMUP", 40L)
cores <- read_int_env("STAN_CORES", chains)

out_dir <- here("Output", "cloud_smoke")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

stan_file <- here("inst", "stan", "cloud_pipeline_smoke.stan")
stan_data <- list(
  N = 8L,
  y = c(-0.7, -0.3, -0.1, 0.0, 0.2, 0.5, 0.8, 1.0)
)

cat("cloud_pipeline_smoke_start\n")
cat("job_id=", job_id, "\n", sep = "")
cat("stan_file=", stan_file, "\n", sep = "")
cat("chains=", chains, "\n", sep = "")
cat("iter=", iter, "\n", sep = "")
cat("warmup=", warmup, "\n", sep = "")
cat("cores=", cores, "\n", sep = "")

fit <- stan(
  file = stan_file,
  data = stan_data,
  chains = chains,
  iter = iter,
  warmup = warmup,
  cores = cores,
  refresh = max(1L, floor(iter / 4L)),
  seed = 20260510,
  control = list(adapt_delta = 0.8, max_treedepth = 8)
)

summary_df <- as_draws_df(fit) |>
  summarize_draws() |>
  as.data.frame()

summary_file <- file.path(out_dir, paste0(job_id, "_summary.csv"))
fit_file <- file.path(out_dir, paste0(job_id, "_fit.rds"))

write.csv(summary_df, summary_file, row.names = FALSE)
saveRDS(fit, fit_file)

cat("cloud_pipeline_smoke_complete\n")
cat("summary_file=", summary_file, "\n", sep = "")
cat("fit_file=", fit_file, "\n", sep = "")
