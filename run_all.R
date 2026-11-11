# Rebuild every series in order. Run from the repository root:  Rscript run_all.R
# Needs R >= 4.1 with readr, dplyr and ggplot2.
steps <- list(
  c("01-job-vacancies",      "R/build_ces_vacancies.R"),
  c("01-job-vacancies",      "R/seasonal_adjust_and_splice.R"),
  c("02-beveridge-curve",    "R/beveridge_curve.R"),
  c("02-beveridge-curve",    "R/beveridge_extend_1950.R"),
  c("03-building-approvals", "R/building_approvals_splice.R"),
  c("04-housing-pipeline",   "R/housing_pipeline.R"),
  c("05-housing-per-capita", "R/per_capita.R"),
  c("06-capex",              "R/capex_splice.R"),
  c("07-retail-sales",       "R/retail_splice.R")
)
root <- getwd()
for (s in steps) {
  message("\n==== ", s[1], "/", s[2])
  setwd(file.path(root, s[1]))
  source(s[2], echo = FALSE, local = new.env())
}
setwd(root)
message("\nAll done.")
