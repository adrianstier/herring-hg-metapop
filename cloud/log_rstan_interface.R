cat("r_version=", paste(R.version$major, R.version$minor, sep = "."), "\n", sep = "")
cat("platform=", R.version$platform, "\n", sep = "")

for (pkg in c("rstan", "StanHeaders", "Rcpp", "RcppEigen")) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(pkg, "_version=", as.character(utils::packageVersion(pkg)), "\n", sep = "")
  } else {
    cat(pkg, "_version=not_installed\n", sep = "")
  }
}

makevars <- Sys.getenv("R_MAKEVARS_USER")
cat("R_MAKEVARS_USER=", makevars, "\n", sep = "")
if (nzchar(makevars) && file.exists(makevars)) {
  cat("makevars_begin\n")
  cat(readLines(makevars), sep = "\n")
  cat("\nmakevars_end\n")
}

job_script <- Sys.getenv("JOB_SCRIPT")
stan_file <- Sys.getenv("HERRING_STAN_PREFLIGHT_FILE")

if (!nzchar(stan_file) && nzchar(job_script) && file.exists(job_script)) {
  script_text <- paste(readLines(job_script, warn = FALSE), collapse = "\n")
  stan_matches <- regmatches(
    script_text,
    gregexpr("herring_metapop_[A-Za-z0-9_]+\\.stan", script_text)
  )[[1]]
  if (length(stan_matches) > 0) {
    stan_file <- file.path("inst", "stan", stan_matches[[1]])
  }
}

if (nzchar(stan_file) && file.exists(stan_file)) {
  cat("stan_preflight_file=", stan_file, "\n", sep = "")
  syntax_ok <- tryCatch(
    {
      rstan::stanc(file = stan_file)
      TRUE
    },
    error = function(e) {
      cat("stan_syntax_error=", conditionMessage(e), "\n", sep = "")
      FALSE
    }
  )
  cat("stan_syntax_ok=", syntax_ok, "\n", sep = "")

  if (identical(Sys.getenv("HERRING_R_STAN_PREFLIGHT_COMPILE"), "1") && syntax_ok) {
    compile_ok <- tryCatch(
      {
        rstan::stan_model(file = stan_file)
        TRUE
      },
      error = function(e) {
        cat("stan_compile_error=", conditionMessage(e), "\n", sep = "")
        FALSE
      }
    )
    cat("stan_compile_ok=", compile_ok, "\n", sep = "")
  }
} else {
  cat("stan_preflight_file=not_detected\n")
}
