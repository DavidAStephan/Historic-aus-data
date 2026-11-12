# Monthly unemployment rate for Australia, 1950 - 2026
# Run from 09-unemployment/:  Rscript R/unemployment_monthly.R
#
# The ABS Labour Force Survey is monthly only from Feb 1978 and quarterly from 1964/1966.
# Before that, the monthly path comes from administrative counts:
#   - persons registered as unemployed with the Commonwealth Employment Service (CES), monthly
#     from Dec 1961 (and every June from 1950);
#   - persons receiving unemployment benefit (Department of Social Services), monthly from 1952.
# These are seasonally adjusted and then scaled to the survey benchmarks (quarterly LFS,
# OECD's copy of the 1964-66 survey, and the RBA's financial-year estimates before 1964).
suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })

mi  <- function(p) { y <- as.integer(substr(p, 1, 4)); m <- as.integer(substr(p, 6, 7)); y * 12L + m - 1L }
lab <- function(i) sprintf("%d-%02d", i %/% 12L, i %% 12L + 1L)
dt  <- function(i) as.Date(sprintf("%d-%02d-15", i %/% 12L, i %% 12L + 1L))
# CES figures are for the Friday nearest the end of the month: a date in the first week
# belongs to the previous month
mon_of <- function(d) {
  out <- d
  full <- nchar(d) == 10
  y <- as.integer(substr(d[full], 1, 4)); m <- as.integer(substr(d[full], 6, 7)); dd <- as.integer(substr(d[full], 9, 10))
  m <- m - (dd <= 7); y <- y - (m == 0); m[m == 0] <- 12L
  out[full] <- sprintf("%d-%02d", y, m)
  out
}
issue_date <- function(k) {           # EU1963-10, ME1955-12, MB-style keys and 02's "1969-10to12"
  s <- gsub("[^0-9-]", "", sub("to.*$", "", k))
  s <- sub("^-", "", s)
  y <- as.integer(substr(s, 1, 4)); m <- suppressWarnings(as.integer(substr(s, 6, 7)))
  y * 12L + ifelse(is.na(m), 12L, m) - 1L
}

# ---- 0. Inputs -----------------------------------------------------------------------------
raw <- read_csv("data-raw/ces_benefit_raw.csv", col_types = cols(.default = "c")) |>
  mutate(value = as.numeric(value), t = mi(month), d = issue_date(issue))
r02 <- bind_rows(
  read_tsv("../02-beveridge-curve/data-raw/ces_registered_raw.tsv", col_types = cols(.default = "c")) |> mutate(series = "ces_registered"),
  read_tsv("../02-beveridge-curve/data-raw/ces_registered_revdef.tsv", col_types = cols(.default = "c")) |> mutate(series = "ces_registered_rev")) |>
  transmute(series, date_label, month = mon_of(date_label), value = as.numeric(registered_persons), issue = paste0("EU", issue),
            page, t = mi(month), d = issue_date(issue))
op8 <- read_tsv("../02-beveridge-curve/data-raw/rba_op8_historical.tsv", show_col_types = FALSE)
oecd <- read_tsv("../02-beveridge-curve/data-raw/oecd_lfs_1964_66.tsv", show_col_types = FALSE) |> mutate(t = mi(quarter_month))
lfq <- read_tsv("../02-beveridge-curve/data-raw/labour_force_quarterly.tsv", show_col_types = FALSE) |> mutate(t = mi(quarter_month))
lfm <- read_csv("data-raw/lfs_monthly_sa_fred.csv", show_col_types = FALSE) |> mutate(t = mi(month))

allraw <- bind_rows(raw |> select(series, t, value, issue, d), r02 |> select(series, t, value, issue, d))
latest <- function(s) allraw |> filter(series == s) |> group_by(t) |> slice_max(d, n = 1, with_ties = FALSE) |> ungroup()
ces_old <- latest("ces_registered"); ces_rev <- latest("ces_registered_rev"); ben <- latest("benefit")
ces_sa_printed <- bind_rows(latest("ces_registered_sa") |> mutate(def = "old"), latest("ces_registered_rev_sa") |> mutate(def = "rev"))
# repeated transcriptions should agree
dups <- allraw |> filter(series %in% c("ces_registered", "benefit")) |> group_by(series, t) |> filter(n() > 1) |>
  summarise(range = max(value) - min(value), .groups = "drop")
cat(sprintf("Repeated transcriptions: %d months; %d differ (largest %s)\n", nrow(dups), sum(dups$range > 0),
            if (any(dups$range > 0)) max(dups$range) else "-"))

# ---- 1. CES registered unemployed, monthly, Jan 1952 - Jan 1978 ------------------------------
T0 <- mi("1952-01"); T1 <- mi("1978-01")
m <- tibble(t = T0:T1) |>
  left_join(ces_old |> select(t, ces_old = value), by = "t") |>
  left_join(ces_rev |> select(t, ces_rev = value), by = "t") |>
  left_join(ben |> select(t, benefit = value), by = "t")
# June CES before the monthly series: exact figures where printed (1957-61), else RBA OP8 ('000)
jun_op8 <- op8 |> filter(year <= 1956) |> transmute(t = mi(sprintf("%d-06", year)), ces_jun = ces_registered_june_000 * 1000)
m <- m |> left_join(jun_op8, by = "t") |> mutate(ces_old = coalesce(ces_old, ces_jun)) |> select(-ces_jun)
# July 1973: the Department of Labour narrowed the definition (excluding people already in
# work and seeking a change of job, etc.). Jul 1973 - Jan 1974 were published on both bases.
ov <- m |> filter(!is.na(ces_old), !is.na(ces_rev))
k73 <- exp(mean(log(ov$ces_rev / ov$ces_old)))
cat(sprintf("CES definition change Jul 1973: revised / old = %.3f over %d months\n", k73, nrow(ov)))
m <- m |> mutate(ces = if_else(t >= mi("1973-07"), ces_rev, ces_old * k73))
# Before the monthly CES series (and in its gaps), CES = benefit x (CES / benefit), with the ratio
# interpolated (in logs) between months where both were published
both <- m |> filter(!is.na(ces), !is.na(benefit))
m$ratio <- exp(approx(both$t, log(both$ces / both$benefit), xout = m$t, rule = 2)$y)
m <- m |> mutate(ces_est = case_when(!is.na(ces) ~ ces, !is.na(benefit) ~ benefit * ratio, TRUE ~ NA_real_),
                 ces_source = case_when(!is.na(ces) & t >= mi("1973-07") ~ "CES registered (revised definition)",
                                        !is.na(ces) ~ "CES registered",
                                        !is.na(benefit) ~ "Unemployment benefit x CES/benefit ratio",
                                        TRUE ~ "Interpolated"))
k <- !is.na(m$ces_est)
m$ces_est[!k] <- exp(approx(m$t[k], log(m$ces_est[k]), xout = m$t[!k])$y)
cat(sprintf("Indicator months: CES %d, from benefit %d, interpolated %d\n", sum(m$ces_source %in% c("CES registered", "CES registered (revised definition)")),
            sum(m$ces_source == "Unemployment benefit x CES/benefit ratio"), sum(m$ces_source == "Interpolated")))

# ---- 2. Seasonal adjustment (STL on logs) --------------------------------------------------
# Done separately for the three sources, whose seasonal patterns differ: benefit-based (to Nov
# 1961), CES old definition (Dec 1961 - Jun 1973) and CES revised definition (Jul 1973 - Jan
# 1978, too short for a moving seasonal, so a fixed one)
y <- ts(log(m$ces_est), start = c(1952, 1), frequency = 12)
st <- stl(y, s.window = 13, robust = TRUE)            # full-period fit, used for the 1950-51 June factor
seg <- cut(m$t, c(-Inf, mi("1961-11"), mi("1973-06"), Inf), labels = FALSE)
m$seas <- NA_real_
for (g in 1:3) {
  i <- which(seg == g)
  yi <- ts(log(m$ces_est[i]), start = c(m$t[i[1]] %/% 12L, m$t[i[1]] %% 12L + 1L), frequency = 12)
  fit <- stl(yi, s.window = if (g == 3) "periodic" else 13, robust = TRUE)
  m$seas[i] <- as.numeric(fit$time.series[, "seasonal"])
}
m$ces_sa <- exp(log(m$ces_est) - m$seas)
# 1950-51: only the June CES counts exist (RBA OP8). They are seasonally adjusted with the
# average June factor of 1952-56 and joined to Jan 1952 by log-linear interpolation (no
# monthly information)
jfac <- mean(st$time.series[, "seasonal"][cycle(y) == 6][1:5])
pre <- jun_op8 |> filter(t < T0) |> mutate(sa = ces_jun / exp(jfac))
m0 <- tibble(t = mi("1950-01"):(T0 - 1L)) |>
  mutate(ces_sa = exp(approx(c(pre$t, T0), log(c(pre$sa, m$ces_sa[1])), xout = t, rule = 2)$y),
         ces_est = NA_real_, ces_source = "Interpolated between June counts (RBA OP8)")
m <- bind_rows(m0, m)
# check against the seasonally adjusted figures the bulletins printed (1963-75)
chk <- ces_sa_printed |> inner_join(m |> select(t, ces_sa, ces_est), by = "t") |>
  mutate(ours = if_else(def == "old" & t >= mi("1973-07"), NA_real_, if_else(def == "old" & t < mi("1973-07"), ces_sa / k73, ces_sa)),
         ours = if_else(def == "rev" & t < mi("1973-07"), ces_sa, ours)) |> filter(!is.na(ours))
cat(sprintf("Our SA vs printed SA (%d months): mean abs diff %.1f%%\n", nrow(chk), 100 * mean(abs(chk$ours / chk$value - 1))))

# ---- 3. Survey benchmarks (unemployed persons, '000, current LFS basis, SA) -----------------
old_basis <- 1.8 / 1.4    # Aug 1966: 1.4% on the pre-1966 basis vs 1.8% on the current ABS basis (see 02)
fy <- op8 |> filter(year %in% 1950:1963) |>
  transmute(t_mid = mi(sprintf("%d-12", year - 1)), t_from = mi(sprintf("%d-07", year - 1)), t_to = mi(sprintf("%d-06", year)),
            u = lfs_unemp_rate_annual * old_basis * lfs_labour_force_000 / 100, lf = lfs_labour_force_000, kind = "RBA financial-year average x 1.29")
q1 <- oecd |> filter(t < mi("1966-08")) |> transmute(t_mid = t, t_from = t, t_to = t, u = unemployed / 1000 * old_basis,
                                                     lf = labour_force / 1000, kind = "OECD quarterly (1964-66 survey) x 1.29")
q2 <- lfq |> filter(t >= mi("1966-08"), t <= mi("1977-11")) |>
  transmute(t_mid = t, t_from = t, t_to = t, u = unemployment_rate * labour_force_000 / 100, lf = labour_force_000, kind = "ABS quarterly LFS")
q3 <- lfq |> filter(t == mi("1978-02")) |> transmute(t_mid = t, t_from = t, t_to = t, u = unemployment_rate * labour_force_000 / 100,
                                                    lf = labour_force_000, kind = "ABS LFS, Feb 1978 (first monthly survey)")
bm <- bind_rows(fy, q1, q2, q3)
# the CES series transcribed ends in Jan 1978: carry its SA level one month forward so the
# Dec 1977 - Jan 1978 months are interpolated towards the Feb 1978 survey
m <- bind_rows(m, tibble(t = mi("1978-02"), ces_sa = m$ces_sa[m$t == mi("1978-01")], ces_source = "Carried forward"))
# (FY 1949/50 is averaged over the months available, Jan - Jun 1950)
bm$ind <- mapply(function(a, b) mean(m$ces_sa[m$t >= a & m$t <= b]) / 1000, bm$t_from, bm$t_to)
bm <- bm |> mutate(k = u / ind)
# the scale factor is interpolated (in logs) between benchmarks; for the financial-year
# averages it is solved iteratively so that the monthly estimates average to the benchmark
kk <- log(bm$k)
for (it in 1:50) {
  sc <- exp(approx(bm$t_mid, kk, xout = m$t, rule = 2)$y)
  est <- mapply(function(a, b) mean((m$ces_sa * sc)[m$t >= a & m$t <= b]) / 1000, bm$t_from, bm$t_to)
  kk <- kk + log(bm$u / est)
}
bm$k <- exp(kk)
m$scale <- exp(approx(bm$t_mid, log(bm$k), xout = m$t, rule = 2)$y)
m$lf <- exp(approx(bm$t_mid, log(bm$lf), xout = m$t, rule = 2)$y)
m <- m |> mutate(unemployed = ces_sa / 1000 * scale, urate = 100 * unemployed / lf)
# financial-year benchmarks are averages: check the monthly series reproduces them
fychk <- fy |> rowwise() |> mutate(est = mean(m$unemployed[m$t >= t_from & m$t <= t_to])) |> ungroup()
cat(sprintf("Financial-year benchmarks reproduced within %.1f%% (mean abs)\n", 100 * mean(abs(fychk$est / fychk$u - 1))))
cat("Survey unemployed / CES registered (SA) at the benchmarks:\n")
print(bm |> mutate(when = lab(t_mid), k = round(k, 2)) |> select(when, kind, k) |> as.data.frame() |> head(40), row.names = FALSE)

# ---- 5. Join with the monthly LFS from Feb 1978 --------------------------------------------
out <- bind_rows(
  m |> filter(t < mi("1978-02")) |> transmute(t, urate, lf, unemployed, ces_registered = ces_est, ces_registered_sa = ces_sa,
                                              unemployment_benefit = benefit, indicator = ces_source,
                                              method = if_else(t < T0, "June CES counts interpolated, scaled to RBA financial-year averages",
                                                               "Administrative indicator (SA), scaled to survey benchmarks")),
  lfm |> filter(t >= mi("1978-02")) |> transmute(t, urate = urate_sa, lf = labour_force_sa_000, unemployed = unemployed_sa_000,
                                                method = "ABS Labour Force Survey, monthly, SA")) |> arrange(t)
dir.create("output", showWarnings = FALSE)
write_csv(out |> transmute(month = lab(t), unemployment_rate = round(urate, 2), unemployed_000 = round(unemployed, 1),
                           labour_force_000 = round(lf, 1), method, indicator, ces_registered = round(ces_registered),
                           ces_registered_sa = round(ces_registered_sa), unemployment_benefit),
          "output/unemployment_rate_monthly.csv", na = "")
write_csv(bm |> transmute(month = lab(t_mid), from = lab(t_from), to = lab(t_to), benchmark = kind, unemployed_000 = round(u, 1),
                          labour_force_000 = lf, ces_sa_000 = round(ind, 1), ratio = round(k, 3)),
          "output/unemployment_benchmarks.csv", na = "")
# annual (calendar-year) and financial-year averages
ann <- out |> mutate(year = t %/% 12L) |> group_by(year) |> filter(n() == 12) |> summarise(urate = mean(urate))
cat("Calendar-year averages, selected:\n"); print(ann |> filter(year %in% c(1951:1954, 1960:1962, 1974:1976, 1982, 1983, 1992, 1993)) |>
                                                     mutate(urate = round(urate, 1)) |> as.data.frame(), row.names = FALSE)

# ---- 6. Charts -----------------------------------------------------------------------------
pal <- c("#1f4e79", "#c0504d", "#7f7f7f", "#4f9a3f")
th <- theme_minimal(base_size = 11) + theme(legend.position = "bottom", panel.grid.minor = element_blank(),
                                            plot.title.position = "plot")
pd <- out |> mutate(seg = case_when(t < T0 ~ "Interpolated (1950-51)", t < mi("1978-02") ~ "Built from CES and benefit counts (1952-78)",
                                    TRUE ~ "ABS Labour Force Survey (from Feb 1978)"))
pd$seg <- factor(pd$seg, c("Interpolated (1950-51)", "Built from CES and benefit counts (1952-78)", "ABS Labour Force Survey (from Feb 1978)"))
bpts <- bm |> mutate(rate = 100 * u / lf) |> filter(t_mid < mi("1978-02"))
p1 <- ggplot(pd, aes(dt(t), urate)) + geom_line(aes(colour = seg), linewidth = 0.5) +
  geom_point(data = bpts, aes(dt(t_mid), rate), shape = 21, size = 1.3, colour = "black", fill = "white") +
  scale_colour_manual(values = c(pal[3], pal[2], pal[1]), name = NULL) +
  labs(title = "Unemployment rate, Australia, monthly 1950 - 2026 (per cent, seasonally adjusted)",
       subtitle = "Before Feb 1978: CES registered unemployed and benefit recipients, seasonally adjusted, scaled to survey benchmarks (dots)",
       x = NULL, y = NULL, caption = "Sources: CBCS Monthly Bulletin of Employment Statistics, Employment and Unemployment (ANU Open Research); ABS LFS; RBA OP8; OECD") + th
ggsave("output/unemployment_rate_monthly.png", p1, width = 9.5, height = 5.2, dpi = 150, bg = "white")

pz <- pd |> filter(t >= mi("1950-01"), t <= mi("1980-12"))
p2 <- ggplot(pz, aes(dt(t), urate)) + geom_line(aes(colour = seg), linewidth = 0.55) +
  geom_point(data = bpts, aes(dt(t_mid), rate), shape = 21, size = 1.6, colour = "black", fill = "white") +
  scale_colour_manual(values = c(pal[3], pal[2], pal[1]), name = NULL) +
  labs(title = "Unemployment rate, 1950 - 1980 (per cent, seasonally adjusted)",
       subtitle = "Monthly estimates (lines) and the survey benchmarks they are scaled to (dots)", x = NULL, y = NULL) + th
ggsave("output/unemployment_rate_1950_1980.png", p2, width = 9, height = 5, dpi = 150, bg = "white")
cat("Done.\n")
