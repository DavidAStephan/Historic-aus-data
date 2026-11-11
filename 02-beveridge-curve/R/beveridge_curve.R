# Historical Beveridge curve for Australia, 1966-2026
# -----------------------------------------------------
# Run after seasonal_adjust_and_splice.R.
#
# Inputs
#   job_vacancies_spliced_quarterly.csv  vacancies ('000, SA): CES back-cast to Feb 1979,
#                                        ABS Job Vacancies from May 1979
#   labour_force_quarterly.tsv           unemployment rate (%) and labour force ('000), SA
#     - Aug 1966 - Nov 1977: ABS quarterly Labour Force Survey (one survey in the
#       middle month of each quarter), as published in the ABS historical series
#     - Feb 1978 on: ABS monthly survey, quarterly averages
#     - Both via the OECD's copy of the ABS series on FRED (LRHUTTTTAUQ156S,
#       LFACTTTTAUQ647S); Q3 2026 from the ABS September 2026 release.
#   The ABS presents the 1966-77 and 1978- surveys as one continuous series without
#   a level adjustment, so no splice is applied to the unemployment rate.
# Outputs
#   beveridge_quarterly.csv, beveridge_curve.png, beveridge_timeseries.png
#
# Vacancy rate = vacancies / labour force x 100. (Some studies divide by
# employment + vacancies instead; the difference is small at these vacancy levels.)
# Run from this analysis folder (the folder that contains R/), e.g.  Rscript R/beveridge_curve.R
#   inputs in data-raw/, outputs written to output/

suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })

v  <- read_csv("../01-job-vacancies/output/job_vacancies_spliced_quarterly.csv", show_col_types = FALSE)
lf <- read_tsv("data-raw/labour_force_quarterly.tsv", col_types = "cddc") |>
  mutate(month = as.Date(paste0(quarter_month, "-01"))) |>
  rename(lf_source = source)

bev <- inner_join(lf, rename(v, vacancy_source = source), by = "month") |>
  transmute(
    quarter_month, month,
    unemployment_rate,
    vacancy_rate      = 100 * vacancies_000 / labour_force_000,
    vacancy_rate_low  = 100 * low_000 / labour_force_000,
    vacancy_rate_high = 100 * high_000 / labour_force_000,
    vacancies_000, labour_force_000,
    v_per_u = vacancies_000 / (unemployment_rate / 100 * labour_force_000),
    vacancy_source, lf_source
  ) |>
  mutate(across(c(unemployment_rate, vacancy_rate, vacancy_rate_low, vacancy_rate_high, v_per_u), ~ round(.x, 3)))

write_csv(bev, "output/beveridge_quarterly.csv", na = "")
cat("Quarters:", format(min(bev$month)), "to", format(max(bev$month)), "-",
    sum(!is.na(bev$vacancy_rate)), "with both series\n")

# Era colouring
bev <- bev |>
  mutate(era = cut(as.integer(format(month, "%Y")),
                   breaks = c(1965, 1974, 1983, 1990, 2000, 2008, 2019, 2030),
                   labels = c("1966-74", "1975-83", "1984-90", "1991-2000",
                              "2001-08", "2009-19", "2020-26"), right = TRUE))

era_cols <- c("1966-74" = "#1b9e77", "1975-83" = "#d95f02", "1984-90" = "#7570b3",
              "1991-2000" = "#e7298a", "2001-08" = "#66a61e", "2009-19" = "#a6761d",
              "2020-26" = "#e6ab02")

lab_q <- c("1966-08", "1974-02", "1975-08", "1983-05", "1989-05", "1992-11",
           "2008-05", "2020-05", "2022-05", "2026-08")
labs <- filter(bev, quarter_month %in% lab_q) |>
  mutate(label = format(month, "%b %Y"))

p1 <- ggplot(bev, aes(unemployment_rate, vacancy_rate)) +
  # NA rows (Aug 2008 - Aug 2009, ABS survey suspended) break the path
  geom_path(aes(colour = era, group = 1), linewidth = 0.5, alpha = 0.9, na.rm = TRUE) +
  geom_point(aes(colour = era), size = 1.1, na.rm = TRUE) +
  geom_errorbar(data = filter(bev, grepl("^CES", vacancy_source)),
                aes(ymin = vacancy_rate_low, ymax = vacancy_rate_high, colour = era),
                width = 0, alpha = 0.25) +
  geom_point(data = labs, size = 2.4, shape = 21, fill = "white", colour = "black") +
  geom_text(data = labs, aes(label = label), size = 3, hjust = -0.15, vjust = -0.4) +
  scale_colour_manual(values = era_cols, name = NULL) +
  scale_x_continuous(limits = c(0, 12), breaks = seq(0, 12, 2), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(title = "Australia's Beveridge curve, 1966-2026",
       subtitle = "Quarterly, seasonally adjusted. Vertical bars on pre-1979 points: range of the CES-to-ABS splice.\nNo vacancy data Aug 2008 - Aug 2009 (ABS survey suspended).",
       x = "Unemployment rate (%)", y = "Vacancy rate (% of labour force)",
       caption = paste("Vacancies: CES registered vacancies scaled to ABS level (to Feb 1979), ABS Job Vacancies (from May 1979).",
                       "Unemployment and labour force: ABS Labour Force Survey via OECD/FRED.", sep = "\n")) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot",
        legend.position = "right")
ggsave("output/beveridge_curve.png", p1, width = 10, height = 6.5, dpi = 200, bg = "white")

# Companion time-series chart
ts_long <- bind_rows(
  transmute(bev, month, value = unemployment_rate, series = "Unemployment rate"),
  transmute(bev, month, value = vacancy_rate, series = "Vacancy rate")
)
p2 <- ggplot(ts_long, aes(month, value, colour = series)) +
  geom_line(linewidth = 0.6) +
  scale_colour_manual(values = c("Unemployment rate" = "#c0392b", "Vacancy rate" = "#1f5aa6"), name = NULL) +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y") +
  labs(title = "Unemployment and vacancy rates, 1966-2026", subtitle = "Quarterly, seasonally adjusted, % of labour force",
       x = NULL, y = "%") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.minor = element_blank(), plot.title.position = "plot")
ggsave("output/beveridge_timeseries.png", p2, width = 10, height = 4.5, dpi = 200, bg = "white")
