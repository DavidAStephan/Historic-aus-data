# Seasonally adjust the CES vacancy series and splice it onto the ABS
# Job Vacancies series (cat. 6354.0, seasonally adjusted, 1979-)
# --------------------------------------------------------------------
# Run after build_ces_vacancies.R (needs ces_vacancies_monthly.csv).
#
# Inputs
#   ces_vacancies_monthly.csv  CES unfilled vacancies, original, monthly 1965-12 to 1979-05
#   abs_current_sa.tsv         ABS job vacancies SA ('000), quarterly May 1979 - Aug 2026
#   abs_overlap.tsv            bridge: ABS surveys as first published (1974-1980) and
#                              the current ABS original series for May 1979 - Nov 1980
#   ces_1979_80_points.tsv     CES unfilled vacancies Jul 1979 - Jul 1980 reported in the
#                              Canberra Times (via Trove), used for the direct overlap
# Outputs
#   ces_vacancies_sa_monthly.csv     CES original + seasonally adjusted, monthly
#   job_vacancies_spliced_quarterly.csv  spliced SA series 1966-2026 ('000) with range
#   job_vacancies_spliced.png
#
# Method
# 1. Seasonal adjustment: STL (Cleveland et al. 1990) on log vacancies, robust
#    fitting, seasonal window 7 (similar to an X-11 3x5 seasonal filter).
#    Checked against the seasonally adjusted totals the bulletins themselves printed.
#    If you have the 'seasonal' package (X-13ARIMA-SEATS), set USE_X13 <- TRUE to
#    compare.
# 2. Splice. Main method: direct overlap of CES unfilled vacancies with the current
#    ABS series (original figures, same months: May, Aug, Nov 1979 and May 1980).
#    Cross-check: a two-link chain through the earlier ABS surveys, using ratios of
#    original (unadjusted) figures for the same months, so seasonality cancels:
#    a. CES -> ABS surveys as first published (March 1975 - May 1978 overlap).
#       The ABS ran annual March surveys from 1974 and quarterly surveys May 1977 -
#       May 1978, with a reference date at month end, like the CES count.
#    b. ABS first-published -> current ABS series (May 1979 - Nov 1980 overlap).
#       The current series has since been re-benchmarked about 18% higher.
#    Back-cast = CES SA x direct ratio. The chained version is kept as a column.
#    The range uses the lowest and highest single-date ratios from either method,
#    because the CES share of all vacancies moves with the cycle.
# The CES series runs to May 1979, so it overlaps the current ABS series directly
# in May 1979; that single-point ratio is reported as a check on the two-link chain.
# Run from this analysis folder (the folder that contains R/), e.g.  Rscript R/seasonal_adjust_and_splice.R
#   inputs in data-raw/, outputs written to output/

suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })
USE_X13 <- FALSE

ces <- read_csv("output/ces_vacancies_monthly.csv", show_col_types = FALSE) |>
  filter(month >= as.Date("1965-12-01")) |>
  arrange(month)
stopifnot(all(diff(ces$month) %in% 28:31))   # contiguous monthly

# ---- 1. Seasonal adjustment -------------------------------------------------
y <- ts(log(ces$vacancies), start = c(1965, 12), frequency = 12)
fit <- stl(y, s.window = 7, robust = TRUE)
ces$vacancies_sa <- round(exp(y - fit$time.series[, "seasonal"]))
ces$seasonal_factor <- round(exp(fit$time.series[, "seasonal"]), 3)

if (USE_X13 && requireNamespace("seasonal", quietly = TRUE)) {
  m <- seasonal::seas(ts(ces$vacancies, start = c(1965, 12), frequency = 12),
                      x11 = "", regression.aictest = NULL)
  ces$vacancies_sa_x13 <- round(as.numeric(seasonal::final(m)))
}

# Check against the seasonally adjusted totals printed in the bulletins
printed_sa <- tribble(
  ~month,        ~printed_sa, ~issue,
  "1970-03-01",  56557, "Dec 1970 Table 16",
  "1970-04-01",  57293, "Dec 1970 Table 16",
  "1970-05-01",  53471, "Dec 1970 Table 16",
  "1970-06-01",  50801, "Dec 1970 Table 16",
  "1970-07-01",  49401, "Dec 1970 Table 16",
  "1970-08-01",  47183, "Dec 1970 Table 16",
  "1970-09-01",  47725, "Dec 1970 Table 16",
  "1970-10-01",  46816, "Dec 1970 Table 16",
  "1970-11-01",  49842, "Dec 1970 Table 16",
  "1970-12-01",  47295, "Dec 1970 Table 16",
  "1971-01-01",  51281, "Dec 1970 Table 16",
  # ABS The Labour Force, May 1979, Table 25 (seasonally adjusted totals)
  "1978-04-01",  20788, "LF May 1979 Table 25",
  "1978-05-01",  20789, "LF May 1979 Table 25",
  "1978-06-01",  21512, "LF May 1979 Table 25",
  "1978-07-01",  22189, "LF May 1979 Table 25",
  "1978-08-01",  20576, "LF May 1979 Table 25",
  "1978-09-01",  20717, "LF May 1979 Table 25",
  "1978-10-01",  20809, "LF May 1979 Table 25",
  "1978-11-01",  18429, "LF May 1979 Table 25",
  "1978-12-01",  16835, "LF May 1979 Table 25",
  "1979-01-01",  19033, "LF May 1979 Table 25",
  "1979-02-01",  21151, "LF May 1979 Table 25",
  "1979-03-01",  22263, "LF May 1979 Table 25",
  "1979-04-01",  19951, "LF May 1979 Table 25",
  "1979-05-01",  20853, "LF May 1979 Table 25"
) |> mutate(month = as.Date(month))
chk <- inner_join(printed_sa, select(ces, month, vacancies, vacancies_sa), by = "month") |>
  mutate(pct_diff = round(100 * (vacancies_sa / printed_sa - 1), 1))
cat("STL vs ABS-printed seasonally adjusted totals:\n"); print(chk, n = Inf)
print(chk |> group_by(issue) |> summarise(mean_abs_pct_diff = round(mean(abs(pct_diff)), 1), max_abs = max(abs(pct_diff))))

write_csv(select(ces, month, vacancies, vacancies_sa, seasonal_factor,
                 any_of("vacancies_sa_x13")),
          "output/ces_vacancies_sa_monthly.csv")

# ---- 2. Splice -------------------------------------------------------------------
ov  <- read_tsv("data-raw/abs_overlap.tsv", col_types = "cddc") |>
  mutate(month = as.Date(paste0(quarter_month, "-01")))
abs <- read_tsv("data-raw/abs_current_sa.tsv", col_types = "cdc") |>
  mutate(month = as.Date(paste0(quarter_month, "-01")))

link_a <- ov |>
  inner_join(select(ces, month, ces = vacancies), by = "month") |>
  mutate(ratio = 1000 * abs_firstprint_000 / ces)
link_b <- ov |>
  filter(!is.na(abs_current_orig_000)) |>
  mutate(ratio = abs_current_orig_000 / abs_firstprint_000)

gmean <- function(x) exp(mean(log(x)))
a <- gmean(link_a$ratio); b <- gmean(link_b$ratio)
cat("Link a: ABS survey (first published) / CES, same month\n")
print(select(link_a, quarter_month, abs_firstprint_000, ces, ratio) |> mutate(ratio = round(ratio, 2)))
cat("\nLink b: current ABS series / first-published ABS, same quarter\n")
print(select(link_b, quarter_month, abs_firstprint_000, abs_current_orig_000, ratio) |> mutate(ratio = round(ratio, 3)))
chain <- a * b
cat(sprintf("\nTwo-link chain: a = %.3f (range %.2f-%.2f), b = %.3f; chained CES scale factor = %.2f\n",
            a, min(link_a$ratio), max(link_a$ratio), b, chain))

# Direct overlap: CES unfilled vacancies vs the current ABS series (original), same month.
# May 1979 comes from the monthly CES file; later months from newspaper reports of the
# department's figures (ces_1979_80_points.tsv).
pts <- read_tsv("data-raw/ces_1979_80_points.tsv", col_types = "cdcc") |>
  mutate(month = as.Date(paste0(month, "-01"))) |>
  select(month, ces = ces_unfilled)
pts <- bind_rows(filter(select(ces, month, ces = vacancies), month == as.Date("1979-05-01")), pts)
direct <- ov |>
  filter(!is.na(abs_current_orig_000)) |>
  inner_join(pts, by = "month") |>
  mutate(ratio = 1000 * abs_current_orig_000 / ces)
cat("\nDirect overlap: current ABS series / CES, same month\n")
print(select(direct, quarter_month, abs_current_orig_000, ces, ratio) |> mutate(ratio = round(ratio, 2)))
scale <- gmean(direct$ratio)
cat(sprintf("Direct scale factor (geometric mean) = %.2f; chained factor = %.2f (%.1f%% higher)\n\n",
            scale, chain, 100 * (chain / scale - 1)))

# Range: lowest and highest single-date ratios from either method
all_ratios <- c(link_a$ratio * b, direct$ratio)
lo <- min(all_ratios); hi <- max(all_ratios)
cat(sprintf("Range used for the band: %.2f-%.2f\n\n", lo, hi))

# Back-cast at the ABS quarter months (Feb, May, Aug, Nov)
q_months <- c(2, 5, 8, 11)
backcast <- ces |>
  filter(as.integer(format(month, "%m")) %in% q_months, month < as.Date("1979-05-01")) |>
  transmute(month,
            vacancies_000 = vacancies_sa * scale / 1000,
            vacancies_chain_000 = vacancies_sa * chain / 1000,
            low_000  = vacancies_sa * lo / 1000,
            high_000 = vacancies_sa * hi / 1000,
            source = "CES (seasonally adjusted, scaled to ABS level)")

spliced <- bind_rows(
  backcast,
  abs |> transmute(month, vacancies_000, low_000 = vacancies_000, high_000 = vacancies_000,
                   source = if_else(is.na(vacancies_000), "ABS (survey suspended)", "ABS 6354.0"))
) |>
  arrange(month) |>
  mutate(across(ends_with("_000"), ~ round(.x, 1)))

stopifnot(!any(duplicated(spliced$month)))
write_csv(spliced, "output/job_vacancies_spliced_quarterly.csv", na = "")
cat("Spliced quarterly series:", format(min(spliced$month)), "to", format(max(spliced$month)),
    "-", sum(!is.na(spliced$vacancies_000)), "quarters with data\n")

# ---- Chart -------------------------------------------------------------------------
bc <- filter(spliced, grepl("^CES", source))
ab <- filter(spliced, grepl("^ABS", source))   # keep the suspended quarters as NA so the line breaks
p <- ggplot() +
  geom_ribbon(data = bc, aes(month, ymin = low_000, ymax = high_000), fill = "#9db7d9", alpha = 0.5) +
  geom_line(data = bc, aes(month, vacancies_000, colour = "CES back-cast (scaled)"), linewidth = 0.6) +
  geom_line(data = ab, aes(month, vacancies_000, colour = "ABS Job Vacancies"), linewidth = 0.6) +
  scale_colour_manual(values = c("CES back-cast (scaled)" = "#1f5aa6", "ABS Job Vacancies" = "#c0392b"),
                      breaks = c("CES back-cast (scaled)", "ABS Job Vacancies"), name = NULL) +
  scale_y_log10(breaks = c(25, 50, 100, 200, 400)) +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y") +
  labs(title = "Australian job vacancies, 1966-2026 (spliced)",
       subtitle = "Seasonally adjusted, '000, log scale. Shading: range of single-date CES-to-ABS ratios (1974-80).\nGap: Aug 2008-Aug 2009 (ABS survey suspended).",
       x = NULL, y = "Vacancies ('000, log scale)",
       caption = "Sources: CES vacancies (ABS bulletins; Canberra Times via Trove); ABS Job Vacancies 6354.0; ABS surveys 1974-80 as first published.") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.minor = element_blank(), plot.title.position = "plot")
ggsave("output/job_vacancies_spliced.png", p, width = 10, height = 5.2, dpi = 200, bg = "white")
