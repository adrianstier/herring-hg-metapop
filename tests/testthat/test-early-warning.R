test_that("EWS dependencies are installed", {
  for (pkg in c("earlywarnings", "spatialwarnings", "MARSS",
                "posterior", "Kendall", "strucchange", "zoo")) {
    expect_true(requireNamespace(pkg, quietly = TRUE),
                info = paste("missing package:", pkg))
  }
})
