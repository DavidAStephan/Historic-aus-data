# Load the combined series file. Works from a clone of the repository or straight from GitHub.
#
#   source("R/load_aus_series.R")            # or source() the raw GitHub URL of this file
#   cat <- aus_catalogue()                    # what is available
#   u   <- aus_series("unemployment_rate_m")  # one series, long format
#   w   <- aus_series(c("awe_male_a", "cpi_inflation_a", "credit_pct_gdp_a"), wide = TRUE)
#   m   <- aus_series(section = "08-money-credit-rates", frequency = "M")
#
# Each series has one value per period. `date` is a Date at the first day of the period's last
# month (for annual series, June of the year ended June); some quarterly labour-market series are
# dated at the mid-quarter survey month, as the catalogue notes.
# Needs base R only; returns data frames (tibbles if the tibble package is installed).

aus_data_path <- function() {
  local <- c("data", "../data", file.path(dirname(sys.frame(1)$ofile %||% "."), "..", "data"))
  for (p in local) if (file.exists(file.path(p, "aus_historic_series.csv"))) return(p)
  "https://raw.githubusercontent.com/DavidAStephan/Historic-aus-data/main/data"
}
`%||%` <- function(a, b) if (is.null(a)) b else a

aus_catalogue <- function(path = aus_data_path()) {
  read.csv(file.path(path, "series_catalogue.csv"), stringsAsFactors = FALSE)
}

aus_series <- function(series_id = NULL, section = NULL, frequency = NULL, wide = FALSE, path = aus_data_path()) {
  cat_ <- aus_catalogue(path)
  keep <- rep(TRUE, nrow(cat_))
  if (!is.null(series_id)) {
    bad <- setdiff(series_id, cat_$series_id)
    if (length(bad)) stop("Unknown series: ", paste(bad, collapse = ", "), ". See aus_catalogue().")
    keep <- keep & cat_$series_id %in% series_id
  }
  if (!is.null(section)) keep <- keep & cat_$section %in% section
  if (!is.null(frequency)) keep <- keep & cat_$frequency %in% frequency
  ids <- cat_$series_id[keep]
  d <- read.csv(file.path(path, "aus_historic_series.csv"), stringsAsFactors = FALSE)
  d <- d[d$series_id %in% ids, ]
  d$date <- as.Date(paste0(d$date, "-01"))
  d <- merge(d, cat_[keep, c("series_id", "frequency", "unit", "description")], by = "series_id")
  d <- d[order(d$series_id, d$date), ]
  if (wide) {
    d <- reshape(d[c("series_id", "date", "value")], idvar = "date", timevar = "series_id", direction = "wide")
    names(d) <- sub("^value\\.", "", names(d))
    d <- d[order(d$date), ]
  }
  rownames(d) <- NULL
  if (requireNamespace("tibble", quietly = TRUE)) d <- tibble::as_tibble(d)
  d
}
