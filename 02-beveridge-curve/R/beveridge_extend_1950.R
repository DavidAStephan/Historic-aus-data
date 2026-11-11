# Extend the Beveridge curve back to 1950/51
# -------------------------------------------
# Run after beveridge_curve.R.
#
# Inputs
#   rba_op8_historical.tsv     RBA Occasional Paper No. 8 (1997), tables 4.3, 4.14, 4.15:
#                              - CES unfilled vacancies, end of June, '000 (1950-1995)
#                              - LFS-consistent unemployment rate and labour force,
#                                financial-year averages 1949/50-1963/64, August from 1964
#   oecd_lfs_1964_66.tsv       quarterly unemployed and labour force (SA), Feb 1964 - Aug 1966
#   ces_vacancies_monthly.csv  exact June CES vacancies 1962-1966 from the bulletins
#   ces_vacancies_sa_monthly.csv  STL seasonal factors (June factor used for pre-1966 Junes)
#   job_vacancies_spliced_quarterly.csv  gives the CES-to-ABS scale factor
#   beveridge_quarterly.csv    the Aug 1966 - Aug 2026 curve
# Outputs
#   beveridge_extended.csv, beveridge_curve_1950_2026.png
#
# Method
# Vacancies (pre-1966): CES June vacancies, seasonally adjusted with the average June
#   factor from the 1965-79 STL fit, scaled to the ABS level with the same direct
#   CES-to-ABS factor as the 1966-79 back-cast. For a financial year ending June t,
#   the vacancy level is the mean of the adjusted Junes t-1 and t, so it lines up with
#   the RBA's financial-year-average unemployment rate.
# Unemployment (pre-Aug 1966): the RBA/old survey basis runs below the current ABS
#   series. At August 1966 the old basis gave 1.4% (RBA OP8 Table 4.15 note e) and the
#   current ABS series gives 1.8%, so pre-Aug-1966 rates are multiplied by 1.8/1.4.
#   Rounding of those two published figures gives a plausible range of 1.21-1.37.
# Run from this analysis folder (the folder that contains R/), e.g.  Rscript R/beveridge_extend_1950.R
#   inputs in data-raw/, outputs written to output/

suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })

rba  <- read_tsv("data-raw/rba_op8_historical.tsv", show_col_types = FALSE)
oecd <- read_tsv("data-raw/oecd_lfs_1964_66.tsv", show_col_types = FALSE) |>
  mutate(month = as.Date(paste0(quarter_month, "-01")))
ces  <- read_csv("../01-job-vacancies/output/ces_vacancies_monthly.csv", show_col_types = FALSE)
sa   <- read_csv("../01-job-vacancies/output/ces_vacancies_sa_monthly.csv", show_col_types = FALSE)
spl  <- read_csv("../01-job-vacancies/output/job_vacancies_spliced_quarterly.csv", show_col_types = FALSE)
bev  <- read_csv("output/beveridge_quarterly.csv", show_col_types = FALSE)

# CES-to-ABS scale factor used in the 1966-79 back-cast
scale <- inner_join(spl, sa, by = "month") |>
  filter(grepl("^CES", source)) |>
  summarise(k = median(1000 * vacancies_000 / vacancies_sa)) |> pull(k)
k_lo <- min(1000 * spl$low_000 / sa$vacancies_sa[match(spl$month, sa$month)], na.rm = TRUE)
k_hi <- max(1000 * spl$high_000 / sa$vacancies_sa[match(spl$month, sa$month)], na.rm = TRUE)

june_sf <- sa |> filter(format(month, "%m") == "06") |> summarise(f = mean(seasonal_factor)) |> pull(f)

# Unemployment-basis adjustment at August 1966
k_u <- 1.8 / 1.4; k_u_lo <- 1.75 / 1.45; k_u_hi <- 1.85 / 1.35
cat(sprintf("Vacancy scale %.3f (range %.2f-%.2f); June seasonal factor %.3f; unemployment basis factor %.3f (%.2f-%.2f)\n",
            scale, k_lo, k_hi, june_sf, k_u, k_u_lo, k_u_hi))

# Cross-check: RBA June figures (rounded '000) against exact bulletin Junes 1962-66
exact_june <- ces |> filter(format(month, "%m") == "06", month <= as.Date("1966-06-01")) |>
  transmute(year = as.integer(format(month, "%Y")), exact = vacancies)
chk <- inner_join(select(rba, year, rba_000 = ces_vacancies_june_000), exact_june, by = "year")
cat("RBA vs bulletin June vacancies:\n"); print(chk)
stopifnot(all(abs(chk$rba_000 - chk$exact / 1000) < 0.6))

# June CES vacancies, best available (exact where transcribed), seasonally adjusted
june <- rba |>
  filter(year <= 1966) |>
  left_join(exact_june, by = "year") |>
  transmute(year, ces_june = coalesce(exact, 1000 * ces_vacancies_june_000),
            ces_june_sa = ces_june / june_sf)

# Financial-year points 1950/51 - 1963/64
fy <- rba |>
  filter(year >= 1951, year <= 1964) |>
  left_join(transmute(june, year, v_t = ces_june_sa), by = "year") |>
  left_join(transmute(june, year = year + 1, v_tm1 = ces_june_sa), by = "year") |>
  transmute(
    period = sprintf("%d/%02d", year - 1, year %% 100),
    month  = as.Date(sprintf("%d-01-01", year)),          # plotted at the middle of the year
    unemployment_rate      = lfs_unemp_rate_annual * k_u,
    unemployment_rate_low  = lfs_unemp_rate_annual * k_u_lo,
    unemployment_rate_high = lfs_unemp_rate_annual * k_u_hi,
    ces_vacancies_sa = (v_t + v_tm1) / 2,
    labour_force_000 = lfs_labour_force_000,
    vacancy_rate      = 100 * ces_vacancies_sa * scale / 1000 / labour_force_000,
    vacancy_rate_low  = 100 * ces_vacancies_sa * k_lo / 1000 / labour_force_000,
    vacancy_rate_high = 100 * ces_vacancies_sa * k_hi / 1000 / labour_force_000,
    frequency = "financial-year average",
    source = "RBA OP8 (unemployment, labour force, CES June vacancies); bulletins for June 1962-64"
  )

# Quarterly points Feb 1964 - May 1966 (old survey basis, adjusted); vacancies only
# where a CES figure exists: June 1964 and June 1965 stand in for May; Feb/May 1966 from the spliced series
q_v <- bind_rows(
  tibble(month = as.Date(c("1964-05-01", "1965-05-01")),
         ces_vacancies_sa = june$ces_june_sa[match(c(1964, 1965), june$year)],
         vsrc = "CES June (seasonally adjusted) used for May"),
  spl |> filter(month %in% as.Date(c("1966-02-01", "1966-05-01"))) |>
    transmute(month, ces_vacancies_sa = 1000 * vacancies_000 / scale, vsrc = "spliced CES series")
)
q <- oecd |>
  filter(month < as.Date("1966-08-01")) |>
  inner_join(q_v, by = "month") |>
  transmute(
    period = format(month, "%b %Y"), month,
    unemployment_rate      = 100 * unemployed / labour_force * k_u,
    unemployment_rate_low  = 100 * unemployed / labour_force * k_u_lo,
    unemployment_rate_high = 100 * unemployed / labour_force * k_u_hi,
    ces_vacancies_sa,
    labour_force_000 = labour_force / 1000,
    vacancy_rate      = 100 * ces_vacancies_sa * scale / 1000 / labour_force_000,
    vacancy_rate_low  = 100 * ces_vacancies_sa * k_lo / 1000 / labour_force_000,
    vacancy_rate_high = 100 * ces_vacancies_sa * k_hi / 1000 / labour_force_000,
    frequency = "quarterly (pre-1966 survey basis, adjusted)",
    source = paste("OECD/FRED unemployment and labour force;", vsrc)
  )

modern <- bev |>
  transmute(period = format(month, "%b %Y"), month, unemployment_rate,
            unemployment_rate_low = unemployment_rate, unemployment_rate_high = unemployment_rate,
            labour_force_000, vacancy_rate, vacancy_rate_low, vacancy_rate_high,
            frequency = "quarterly", source = paste("Vacancies:", vacancy_source, "| Unemployment: ABS LFS"))

ext <- bind_rows(fy, q, modern) |>
  arrange(month) |>
  mutate(across(where(is.double) & !matches("labour_force|ces_vac"), ~ round(.x, 3)))
write_csv(ext, "output/beveridge_extended.csv", na = "")

cat("\nPre-1966 points:\n")
print(select(filter(ext, month < as.Date("1966-08-01")), period, unemployment_rate, vacancy_rate), n = Inf)

# ---- Chart -------------------------------------------------------------------
ext <- ext |>
  mutate(era = case_when(
    month < as.Date("1966-08-01") ~ "1950/51-1966",
    month <= as.Date("1974-12-31") ~ "1966-74",
    month <= as.Date("1983-12-31") ~ "1975-83",
    month <= as.Date("1990-12-31") ~ "1984-90",
    month <= as.Date("2000-12-31") ~ "1991-2000",
    month <= as.Date("2008-12-31") ~ "2001-08",
    month <= as.Date("2019-12-31") ~ "2009-19",
    TRUE ~ "2020-26"),
    era = factor(era, levels = c("1950/51-1966", "1966-74", "1975-83", "1984-90",
                                 "1991-2000", "2001-08", "2009-19", "2020-26")))
cols <- c("1950/51-1966" = "#5b5b5b", "1966-74" = "#1b9e77", "1975-83" = "#d95f02",
          "1984-90" = "#7570b3", "1991-2000" = "#e7298a", "2001-08" = "#66a61e",
          "2009-19" = "#a6761d", "2020-26" = "#e6ab02")

lab <- ext |> filter(period %in% c("1950/51", "1951/52", "1952/53", "1955/56", "1960/61",
                                    "1961/62", "Feb 1974", "May 1983", "Nov 1992", "May 2022", "Aug 2026"))

pre <- filter(ext, month < as.Date("1966-08-01"))
p <- ggplot(ext, aes(unemployment_rate, vacancy_rate)) +
  geom_path(aes(colour = era, group = 1), linewidth = 0.5, na.rm = TRUE) +
  geom_errorbar(data = pre, aes(ymin = vacancy_rate_low, ymax = vacancy_rate_high, colour = era),
                width = 0, alpha = 0.3) +
  geom_errorbarh(data = pre, aes(xmin = unemployment_rate_low, xmax = unemployment_rate_high, colour = era),
                 height = 0, alpha = 0.3) +
  geom_point(aes(colour = era, shape = frequency == "financial-year average"), size = 1.4, na.rm = TRUE) +
  geom_point(data = lab, size = 2.4, shape = 21, fill = "white", colour = "black") +
  geom_text(data = lab, aes(label = period), size = 3, hjust = -0.15, vjust = -0.45) +
  scale_colour_manual(values = cols, name = NULL) +
  scale_shape_manual(values = c(`TRUE` = 15, `FALSE` = 16), guide = "none") +
  scale_x_continuous(limits = c(0, 12), breaks = seq(0, 12, 2), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(title = "Australia's Beveridge curve, 1950/51-2026",
       subtitle = paste("Squares: financial-year averages 1950/51-1963/64. Circles: quarterly, seasonally adjusted.",
                        "Bars on pre-1966 points: range of the vacancy and unemployment splices.", sep = "\n"),
       x = "Unemployment rate (%)", y = "Vacancy rate (% of labour force)",
       caption = paste("Pre-1966: RBA Occasional Paper No. 8 (CES vacancies, LFS-consistent unemployment), scaled to current ABS levels.",
                       "1966-79: CES registered vacancies scaled to ABS level. From 1979: ABS Job Vacancies and Labour Force.", sep = "\n")) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot")
ggsave("output/beveridge_curve_1950_2026.png", p, width = 10, height = 6.8, dpi = 200, bg = "white")

# ---- Second chart: excluding the 1950/51 and 1951/52 boom years --------------
ext2 <- filter(ext, !period %in% c("1950/51", "1951/52"))
pre2 <- filter(ext2, month < as.Date("1966-08-01"))
lab2 <- filter(lab, !period %in% c("1950/51", "1951/52")) |>
  bind_rows(filter(ext2, period %in% c("1952/53", "1953/54")) |> anti_join(lab, by = "period"))
p2 <- p %+% ext2 +
  labs(title = "Australia's Beveridge curve, 1952/53-2026",
       subtitle = paste("Excludes 1950/51 and 1951/52 (Korean War boom), which sit far above the rest.",
                        "Squares: financial-year averages 1952/53-1963/64. Circles: quarterly, seasonally adjusted.", sep = "\n"))
p2 <- p2 + scale_colour_manual(values = cols, name = NULL, labels = function(x) sub("1950/51-1966", "1952/53-1966", x))
p2$layers[[2]]$data <- pre2
p2$layers[[3]]$data <- pre2
p2$layers[[5]]$data <- lab2
p2$layers[[6]]$data <- lab2
ggsave("output/beveridge_curve_1952_2026.png", p2, width = 10, height = 6.8, dpi = 200, bg = "white")
