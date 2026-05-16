library(here)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

md_files <- c(
  "README.md",
  "AGENTS.md",
  "CLAUDE.md",
  "REVIEW_NOTES.md",
  list.files(file.path(proj_dir, "docs"), pattern = "\\.md$", recursive = TRUE, full.names = FALSE),
  file.path(
    "Output",
    "diagnostics",
    list.files(file.path(proj_dir, "Output", "diagnostics"), pattern = "\\.md$", full.names = FALSE)
  )
)

md_files <- unique(md_files[file.exists(file.path(proj_dir, md_files))])
md_files <- setdiff(md_files, file.path("Output", "diagnostics", "document_reference_check.md"))

path_prefix <- paste(
  c(
    "AGENTS\\.md",
    "CLAUDE\\.md",
    "README\\.md",
    "REVIEW_NOTES\\.md",
    "SESSION_LOG_[0-9]+\\.md",
    "Code/",
    "R/",
    "docs/",
    "inst/stan/",
    "Output/",
    "Data/",
    "\\.\\./pacific-herring-predators/",
    "cloud/"
  ),
  collapse = "|"
)

extract_matches <- function(text, pattern) {
  matches <- gregexpr(pattern, text, perl = TRUE)
  values <- regmatches(text, matches)[[1]]
  if (length(values) == 1 && values[1] == "") {
    character()
  } else {
    values
  }
}

extract_references <- function(path) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")

  backtick_values <- extract_matches(text, "`[^`]+`")
  backtick_values <- gsub("^`|`$", "", backtick_values)

  link_values <- extract_matches(text, "\\[[^\\]]+\\]\\(([^)]+)\\)")
  link_values <- sub("^.*\\]\\(", "", link_values)
  link_values <- sub("\\)$", "", link_values)

  values <- unique(c(backtick_values, link_values))
  values <- values[!grepl("^(https?:|mailto:|app:|#)", values)]
  values <- gsub("^<|>$", "", values)
  values <- gsub("^file://", "", values)
  values <- gsub(":\\d+$", "", values)
  values <- gsub("[[:space:]]+$", "", values)

  absolute_prefix <- paste0("^", gsub("([.|()\\^{}+$*?\\[\\]\\\\])", "\\\\\\1", proj_dir), "/")
  values <- sub(absolute_prefix, "", values)
  values <- vapply(
    values,
    function(value) {
      first_token <- strsplit(value, "[[:space:]]+")[[1]][1]
      if (grepl(paste0("^(", path_prefix, ")"), first_token)) {
        first_token
      } else {
        value
      }
    },
    character(1)
  )

  values <- values[grepl(paste0("^(", path_prefix, ")"), values)]
  values <- values[!grepl("[<>]", values)]

  if (!length(values)) {
    return(data.frame(source = character(), reference = character(), stringsAsFactors = FALSE))
  }

  data.frame(
    source = sub(paste0("^", proj_dir, "/"), "", path),
    reference = values,
    stringsAsFactors = FALSE
  )
}

refs <- do.call(
  rbind,
  lapply(file.path(proj_dir, md_files), extract_references)
)

if (is.null(refs) || nrow(refs) == 0) {
  refs <- data.frame(source = character(), reference = character(), stringsAsFactors = FALSE)
}

check_exists <- function(reference) {
  if (grepl("[*?\\[]", reference)) {
    return(length(Sys.glob(file.path(proj_dir, reference))) > 0)
  }
  file.exists(file.path(proj_dir, reference))
}

refs$exists <- vapply(refs$reference, check_exists, logical(1))
known_planned_missing <- c("Code/03_fit_m6_timevarying.R")
refs$known_planned_missing <- refs$reference %in% known_planned_missing
refs <- refs[order(refs$exists, refs$source, refs$reference), ]

csv_path <- file.path(diag_dir, "document_reference_check.csv")
write.csv(refs, csv_path, row.names = FALSE)

missing <- refs[!refs$exists & !refs$known_planned_missing, , drop = FALSE]
planned_missing <- refs[!refs$exists & refs$known_planned_missing, , drop = FALSE]
md_path <- file.path(diag_dir, "document_reference_check.md")

lines <- c(
  "# Document Reference Check",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  paste0("- Markdown files scanned: ", length(md_files), "."),
  paste0("- Local project references checked: ", nrow(refs), "."),
  paste0("- Missing references: ", nrow(missing), "."),
  paste0("- Known planned-missing references: ", nrow(planned_missing), "."),
  "",
  "## Missing References",
  ""
)

if (nrow(missing) == 0) {
  lines <- c(lines, "- None.")
} else {
  rows <- apply(
    missing,
    1,
    function(row) paste0("- `", row[["reference"]], "` referenced from `", row[["source"]], "`.")
  )
  lines <- c(lines, rows)
}

lines <- c(lines, "", "## Known Planned-Missing References", "")

if (nrow(planned_missing) == 0) {
  lines <- c(lines, "- None.")
} else {
  rows <- apply(
    planned_missing,
    1,
    function(row) paste0("- `", row[["reference"]], "` referenced from `", row[["source"]], "`.")
  )
  lines <- c(lines, rows)
}

writeLines(lines, md_path)

cat("Wrote ", csv_path, "\n", sep = "")
cat("Wrote ", md_path, "\n", sep = "")
cat("Missing references: ", nrow(missing), "\n", sep = "")
cat("Known planned-missing references: ", nrow(planned_missing), "\n", sep = "")
