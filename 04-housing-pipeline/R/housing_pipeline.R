# Australian dwelling starts and completions, quarterly 1946-2026,
# with dwelling approvals (1960-2026) for the full housing pipeline
# ------------------------------------------------------------------
# Inputs
#   abs_starts_completions.tsv  ABS 8752.0 Building Activity (June 2026 release),
#       Tables 33 and 37: new houses + new other residential dwellings commenced and
#       completed, Australia, quarterly. Total sectors and private sector, original;
#       ABS seasonally adjusted totals where published (starts from Sep qtr 1969,
#       completions from Sep qtr 1984). Starts from Sep qtr 1955, completions from
#       Mar qtr 1955.
#   qb_raw.tsv  Transcribed from the Commonwealth Bureau of Census and Statistics
#       "Quarterly Bulletin of Building Statistics" (Dec issues 1948-1957, scans via
#       ANU Open Research). One row per issue x period (Q = quarter, FY = year to
#       June, CY = calendar year). Columns: starts, completions, under construction.
#       Up to the Dec 1955 issue the bulletins count new HOUSES only (flats were
#       added from 1956, back to 1947-48). The Dec 1957 issue gives calendar-year
#       totals for houses and flats 1948-1957 on the basis the ABS still uses
#       (its quarters for 1956-57 match ABS 8752.0 to within a few dwellings).
#   ../03-building-approvals/output/dwelling_approvals_spliced_monthly.csv  from building_approvals_splice.R
# Outputs
#   housing_pipeline_quarterly.csv, housing_pipeline.png, housing_pipeline_annual.png
#
# Method (1946-1955)
#   1. Indicator: houses commenced / completed each quarter, latest issue that
#      printed the quarter (later issues carry revisions).
#   2. Benchmark to houses-and-flats totals on the current basis with proportional
#      Denton (Denton-Cholette) benchmarking: the ratio of the benchmarked series to
#      the indicator moves as smoothly as possible from quarter to quarter while the
#      quarters add up to each calendar-year total for 1948-1954 (Dec 1957 bulletin).
#      For starts the 1955 benchmark is split: Mar + Jun qtr 1955 = calendar 1955
#      total less the ABS figures for Sep and Dec qtr 1955. Quarters before 1948
#      (Sep qtr 1946 - Dec qtr 1947) have no houses-and-flats benchmark and carry the
#      1948 ratio (about +4% for flats).
#   3. ABS 8752.0 is used unchanged from its first quarter.
#   4. Seasonal adjustment: STL on logs (robust, seasonal window 7) over the full
#      spliced original series; the ABS seasonally adjusted series is used where
#      published, STL before that.
# Run from this analysis folder (the folder that contains R/), e.g.  Rscript R/housing_pipeline.R
#   inputs in data-raw/, outputs written to output/

suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })

qend <- function(s) as.Date(paste0(s, "-01"))          # quarter labelled by its last month

# ---- Inputs --------------------------------------------------------------------------
abs <- read_tsv("data-raw/abs_starts_completions.tsv", col_types = "cdddddd", na = "") |>
  mutate(q = qend(quarter_end))
qb  <- read_tsv("data-raw/qb_raw.tsv", col_types = "ccciiic", na = "")

# ---- 1. Indicator: houses only, latest issue per quarter ----------------------------------
ind <- qb |>
  filter(freq == "Q", grepl("houses only", note)) |>
  mutate(q = qend(period), issue_date = qend(sub("QB", "", issue))) |>
  group_by(q) |> slice_max(issue_date, n = 1, with_ties = FALSE) |> ungroup() |>
  arrange(q) |>
  select(q, issue, starts_houses = starts, completions_houses = completions)
stopifnot(all(diff(ind$q) %in% 89:92))
cat("Houses-only indicator:", format(min(ind$q)), "-", format(max(ind$q)), nrow(ind), "quarters\n")

bench <- qb |> filter(issue == "QB1957-12", freq == "CY") |>
  transmute(year = as.integer(period), starts, completions)

# ---- 2. Proportional Denton benchmarking -------------------------------------------------
# x: indicator; groups: list of integer index vectors; totals: benchmark for each group
denton_prop <- function(x, groups, totals) {
  n <- length(x); k <- length(groups)
  D <- diff(diag(n))                                   # first differences of the ratio
  A <- matrix(0, k, n)
  for (j in seq_len(k)) A[j, groups[[j]]] <- x[groups[[j]]]
  K <- rbind(cbind(2 * crossprod(D), t(A)), cbind(A, matrix(0, k, k)))
  sol <- solve(K, c(rep(0, n), totals))
  r <- sol[1:n]
  list(y = r * x, ratio = r)
}

yr <- as.integer(format(ind$q, "%Y"))

# Starts: indicator to Jun qtr 1955; benchmarks CY1948-54 and H1 1955
s_ind <- filter(ind, q <= as.Date("1955-06-01"))
s_yr  <- as.integer(format(s_ind$q, "%Y"))
abs_s_h2_1955 <- sum(abs$starts_orig[abs$q %in% as.Date(c("1955-09-01", "1955-12-01"))])
g_s <- c(lapply(1948:1955, function(y) which(s_yr == y)))
t_s <- c(bench$starts[bench$year %in% 1948:1954], bench$starts[bench$year == 1955] - abs_s_h2_1955)
d_s <- denton_prop(s_ind$starts_houses, g_s, t_s)

# Completions: indicator to Dec qtr 1954; benchmarks CY1948-54 (ABS from Mar qtr 1955)
c_ind <- filter(ind, q <= as.Date("1954-12-01"))
c_yr  <- as.integer(format(c_ind$q, "%Y"))
g_c <- lapply(1948:1954, function(y) which(c_yr == y))
t_c <- bench$completions[bench$year %in% 1948:1954]
d_c <- denton_prop(c_ind$completions_houses, g_c, t_c)

cat(sprintf("Benchmark ratio (houses+flats / houses): starts %.3f-%.3f, completions %.3f-%.3f\n",
            min(d_s$ratio), max(d_s$ratio), min(d_c$ratio), max(d_c$ratio)))
# Checks: benchmarks reproduced, ABS calendar 1955 completions vs bulletin
for (j in seq_along(g_s)) stopifnot(abs(sum(d_s$y[g_s[[j]]]) - t_s[j]) < 0.5)
for (j in seq_along(g_c)) stopifnot(abs(sum(d_c$y[g_c[[j]]]) - t_c[j]) < 0.5)
cat("ABS CY1955 completions", sum(abs$completions_orig[format(abs$q, "%Y") == "1955"]),
    "vs Dec 1957 bulletin", bench$completions[bench$year == 1955], "\n")
cat("ABS CY1956 starts", sum(abs$starts_orig[format(abs$q, "%Y") == "1956"]),
    "vs bulletin", bench$starts[bench$year == 1956], "; completions",
    sum(abs$completions_orig[format(abs$q, "%Y") == "1956"]), "vs", bench$completions[bench$year == 1956], "\n")

# ---- 3. Splice ------------------------------------------------------------------------
hist <- full_join(
  tibble(q = s_ind$q, starts_orig = d_s$y, starts_ratio = d_s$ratio),
  tibble(q = c_ind$q, completions_orig = d_c$y, completions_ratio = d_c$ratio), by = "q")
pipe <- abs |>
  select(q, starts_orig, completions_orig, starts_private_orig, completions_private_orig,
         starts_sa_abs = starts_sa, completions_sa_abs = completions_sa) |>
  full_join(hist, by = "q", suffix = c("", ".h")) |>
  mutate(starts_source = if_else(!is.na(starts_orig), "ABS 8752.0", if_else(!is.na(starts_orig.h), "Bulletins (benchmarked)", NA_character_)),
         completions_source = if_else(!is.na(completions_orig), "ABS 8752.0", if_else(!is.na(completions_orig.h), "Bulletins (benchmarked)", NA_character_)),
         starts_orig = coalesce(starts_orig, starts_orig.h),
         completions_orig = coalesce(completions_orig, completions_orig.h)) |>
  select(-ends_with(".h")) |>
  arrange(q)
stopifnot(!any(duplicated(pipe$q)), all(diff(pipe$q) %in% 89:92))

# ---- 4. Seasonal adjustment ----------------------------------------------------------
stl_q <- function(x, q) {
  ok <- !is.na(x); xs <- x[ok]; q0 <- q[ok][1]
  y <- ts(log(xs), start = c(as.integer(format(q0, "%Y")), (as.integer(format(q0, "%m")) %/% 3)), frequency = 4)
  f <- stl(y, s.window = 7, robust = TRUE)
  out <- rep(NA_real_, length(x)); out[ok] <- exp(y - f$time.series[, "seasonal"]); out
}
pipe <- pipe |>
  mutate(starts_sa_stl = stl_q(starts_orig, q),
         completions_sa_stl = stl_q(completions_orig, q),
         starts_sa = coalesce(starts_sa_abs, starts_sa_stl),
         completions_sa = coalesce(completions_sa_abs, completions_sa_stl))

seam <- function(v, abs_col, stl_col) {
  first <- min(pipe$q[!is.na(pipe[[abs_col]])])
  d <- pipe |> filter(q >= first, q < first + 365 * 3)
  cat(sprintf("%s: ABS SA from %s; STL vs ABS over first 3 years: mean abs diff %.1f%%\n", v,
              format(first, "%b %Y"), mean(abs(100 * (d[[stl_col]] / d[[abs_col]] - 1)))))
}
seam("Starts", "starts_sa_abs", "starts_sa_stl")
seam("Completions", "completions_sa_abs", "completions_sa_stl")

# ---- Approvals to quarters ---------------------------------------------------------------
apv <- read_csv("../03-building-approvals/output/dwelling_approvals_spliced_monthly.csv", show_col_types = FALSE) |>
  mutate(m = qend(month), q = as.Date(sprintf("%s-%02d-01", format(m, "%Y"), 3 * ceiling(as.integer(format(m, "%m")) / 3)))) |>
  group_by(q) |>
  summarise(n = n(), approvals_orig = sum(total_orig), approvals_sa = sum(total_sa), .groups = "drop") |>
  filter(n == 3) |> select(-n)
pipe <- left_join(pipe, apv, by = "q")

out <- pipe |>
  transmute(quarter = paste0(format(q, "%Y"), "-Q", as.integer(format(q, "%m")) / 3),
            quarter_end_month = format(q, "%Y-%m"),
            approvals_orig = round(approvals_orig), approvals_sa = round(approvals_sa),
            starts_orig = round(starts_orig), starts_sa = round(starts_sa),
            completions_orig = round(completions_orig), completions_sa = round(completions_sa),
            starts_private_orig, completions_private_orig,
            starts_source, completions_source,
            starts_sa_method = case_when(!is.na(starts_sa_abs) ~ "ABS published", !is.na(starts_sa) ~ "STL (this study)"),
            completions_sa_method = case_when(!is.na(completions_sa_abs) ~ "ABS published", !is.na(completions_sa) ~ "STL (this study)"),
            houses_to_houses_flats_ratio_starts = round(starts_ratio, 4),
            houses_to_houses_flats_ratio_completions = round(completions_ratio, 4))
write_csv(out, "output/housing_pipeline_quarterly.csv", na = "")
cat("Wrote", nrow(out), "quarters:", out$quarter[1], "to", out$quarter[nrow(out)], "\n")

ann <- pipe |>
  mutate(year = as.integer(format(q, "%Y"))) |>
  group_by(year) |>
  summarise(nq_s = sum(!is.na(starts_orig)), nq_c = sum(!is.na(completions_orig)), nq_a = sum(!is.na(approvals_orig)),
            starts = sum(starts_orig), completions = sum(completions_orig), approvals = sum(approvals_orig), .groups = "drop") |>
  mutate(starts = if_else(nq_s == 4, starts, NA_real_), completions = if_else(nq_c == 4, completions, NA_real_),
         approvals = if_else(nq_a == 4, approvals, NA_real_))
cat("Peak calendar years for starts:\n"); print(slice_max(ann, starts, n = 6) |> select(year, starts, completions, approvals))

# ---- Charts --------------------------------------------------------------------------
cols <- c("Approvals" = "#7f9cc9", "Starts" = "#c0392b", "Completions" = "#1b7f5a")
long <- bind_rows(
  transmute(pipe, q, series = "Approvals", value = approvals_sa),
  transmute(pipe, q, series = "Starts", value = starts_sa),
  transmute(pipe, q, series = "Completions", value = completions_sa)
) |> filter(!is.na(value)) |> mutate(series = factor(series, levels = names(cols)))

p <- ggplot(long, aes(q, value / 1000, colour = series)) +
  annotate("rect", xmin = min(pipe$q), xmax = as.Date("1955-06-01"), ymin = -Inf, ymax = Inf, fill = "grey92") +
  annotate("text", x = as.Date("1950-09-01"), y = 66, label = "Bulletins,\nbenchmarked", size = 2.9, colour = "grey40") +
  geom_line(linewidth = 0.55) +
  scale_colour_manual(values = cols, name = NULL) +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y", expand = expansion(mult = 0.01)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.04))) +
  labs(title = "Australia's housing pipeline, 1946-2026",
       subtitle = "New dwellings per quarter, '000, seasonally adjusted. Approvals from 1960.",
       x = NULL, y = "Dwellings ('000 per quarter)",
       caption = paste("Sources: ABS 8752.0 Building Activity (starts from Sep qtr 1955, completions from Mar qtr 1955); CBCS Quarterly Bulletin of Building Statistics 1948-57",
                       "(scans via ANU Open Research), benchmarked to houses and flats; approvals spliced from ABS 8731.0 and earlier bulletins. Seasonal adjustment: ABS where published, STL before.", sep = "\n")) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.minor = element_blank(), plot.title.position = "plot",
        plot.caption = element_text(hjust = 0, size = 7.5, colour = "grey35"))
ggsave("output/housing_pipeline.png", p, width = 11, height = 5.6, dpi = 200, bg = "white")

al <- bind_rows(
  transmute(ann, year, series = "Approvals", value = approvals),
  transmute(ann, year, series = "Starts", value = starts),
  transmute(ann, year, series = "Completions", value = completions)
) |> filter(!is.na(value), year <= 2025) |> mutate(series = factor(series, levels = names(cols)))
p2 <- ggplot(al, aes(year, value / 1000, colour = series)) +
  geom_line(linewidth = 0.7) + geom_point(size = 0.9) +
  scale_colour_manual(values = cols, name = NULL) +
  scale_x_continuous(breaks = seq(1945, 2025, 5), expand = expansion(mult = 0.01)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.04))) +
  labs(title = "New dwellings per calendar year, 1947-2025", subtitle = "'000, original (unadjusted) series",
       x = NULL, y = "Dwellings ('000 per year)") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.minor = element_blank(), plot.title.position = "plot")
ggsave("output/housing_pipeline_annual.png", p2, width = 10, height = 4.8, dpi = 200, bg = "white")
