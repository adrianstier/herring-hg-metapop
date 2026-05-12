read_int_env <- function(name, default) {
  value <- Sys.getenv(name)
  if (!nzchar(value)) {
    return(as.integer(default))
  }
  parsed <- suppressWarnings(as.integer(value))
  if (is.na(parsed) || parsed <= 0L) {
    stop("Environment variable ", name, " must be a positive integer.")
  }
  parsed
}

read_flag_env <- function(name, default = FALSE) {
  value <- tolower(Sys.getenv(name))
  if (!nzchar(value)) {
    return(default)
  }
  value %in% c("1", "true", "yes", "y")
}

cloud_fit_control <- function(default_chains = 4L,
                              default_iter = 4500L,
                              default_warmup = 2000L,
                              default_cores = default_chains) {
  smoke <- read_flag_env("HERRING_SMOKE", FALSE)

  chains <- read_int_env("STAN_CHAINS", if (smoke) 1L else default_chains)
  iter <- read_int_env("STAN_ITER", if (smoke) 200L else default_iter)
  warmup <- read_int_env("STAN_WARMUP", if (smoke) max(50L, floor(iter / 2L)) else default_warmup)
  cores <- read_int_env("STAN_CORES", if (smoke) 1L else default_cores)
  skip_postfit <- read_flag_env("HERRING_SKIP_POSTFIT", smoke)

  if (warmup >= iter) {
    stop("STAN_WARMUP must be smaller than STAN_ITER.")
  }

  list(
    smoke = smoke,
    chains = chains,
    iter = iter,
    warmup = warmup,
    cores = cores,
    skip_postfit = skip_postfit
  )
}

print_fit_control <- function(fit_control) {
  cat("Stan runtime control:\n")
  cat("  smoke:", fit_control$smoke, "\n")
  cat("  chains:", fit_control$chains, "\n")
  cat("  iter:", fit_control$iter, "\n")
  cat("  warmup:", fit_control$warmup, "\n")
  cat("  cores:", fit_control$cores, "\n")
  cat("  skip_postfit:", fit_control$skip_postfit, "\n\n")
}
