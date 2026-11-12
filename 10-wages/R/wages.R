# Wages, earnings and real wages, Australia, 1949-50 to 2025-26 (years ended June)
# Run from 10-wages/:  Rscript R/wages.R
suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })

mi  <- function(p) { y <- as.integer(substr(p, 1, 4)); m <- as.integer(substr(p, 6, 7)); y * 12L + m - 1L }
fyend <- function(i) { y <- i %/% 12L; m <- i %% 12L + 1L; y + (m >= 7) }

# ---- 0. Inputs -----------------------------------------------------------------------------
op8 <- read_csv("data-raw/op8_4_17_wages_annual.csv", show_col_types = FALSE)
svy <- read_csv("data-raw/op8_4_18_awe_survey.csv", show_col_types = FALSE)
awe <- read_csv("data-raw/abs_6302_awe_original.csv", show_col_types = FALSE) |> mutate(t = mi(month))
wpi <- read_csv("data-raw/abs_6345_wpi_sa.csv", show_col_types = FALSE) |> mutate(t = mi(quarter_end))
cpi <- read_tsv("../08-money-credit-rates/data-raw/rba_g1_cpi_quarterly.tsv", col_types = "cd") |> mutate(t = mi(quarter_end))
une <- read_csv("../09-unemployment/output/unemployment_rate_monthly.csv", show_col_types = FALSE) |> mutate(t = mi(month))

# OP8 prints "1958/59" twice; the first is 1957/58 (the year column here is set by position)
stopifnot(all(diff(op8$year_ended_june) == 1))

# ---- 1. Average weekly earnings, males -------------------------------------------------------
# OP8 (ABS splice): earnings per employed male unit to 1980/81, male AWE from the quarterly
# survey from 1981/82. ABS 6302.0 male total earnings (original), May and November from Nov
# 1994: a financial year is the average of November and the following May.
awe_fy <- awe |> mutate(fy = fyend(t)) |> group_by(fy) |> filter(n() == 2) |>
  summarise(awe_male_abs = mean(awe_male_total), awe_persons_abs = mean(awe_persons_total), .groups = "drop")
ov <- op8 |> inner_join(awe_fy, by = c("year_ended_june" = "fy"))
k_awe <- exp(mean(log(ov$awe_male_abs / ov$awe_male)))
cat(sprintf("Male AWE: ABS 6302.0 / OP8 over %s: %s; link %.4f\n", paste(ov$year_ended_june, collapse = ", "),
            paste(round(ov$awe_male_abs / ov$awe_male, 4), collapse = ", "), k_awe))

# ---- 2. Wage rates: award minimum rates, award index, then the Wage Price Index ------------
# Minimum weekly award rates (males, 1949/50 - 1981/82) are linked to the award rates of pay
# index (persons, 1976/77 - 1995/96) over their overlap; the WPI (from Sep 1997) continues it.
# 1996/97 has neither and is interpolated geometrically.
ov2 <- op8 |> filter(!is.na(minwage_male), !is.na(award_index_persons))
k_aw <- exp(mean(log(ov2$award_index_persons / ov2$minwage_male)))
rg <- range(ov2$award_index_persons / ov2$minwage_male / k_aw)
cat(sprintf("Award index / minimum male rates, %d-%d: link %.4f (single years %.3f - %.3f of it)\n",
            min(ov2$year_ended_june), max(ov2$year_ended_june), k_aw, rg[1], rg[2]))
wpi_fy <- wpi |> mutate(fy = fyend(t)) |> group_by(fy) |> filter(n() == 4) |> summarise(wpi = mean(wpi_sa), .groups = "drop")

yrs <- 1950:2026
a <- tibble(year_ended_june = yrs) |>
  left_join(op8 |> select(year_ended_june, minwage_male, award_index_persons, awe_male_op8 = awe_male,
                          avg_earnings_nonfarm, rulc_index), by = "year_ended_june") |>
  left_join(awe_fy, by = c("year_ended_june" = "fy")) |>
  left_join(wpi_fy, by = c("year_ended_june" = "fy")) |>
  mutate(
    awe_male = case_when(!is.na(awe_male_abs) & year_ended_june >= 1996 ~ awe_male_abs,
                         TRUE ~ awe_male_op8 * k_awe),
    awe_source = case_when(!is.na(awe_male_abs) & year_ended_june >= 1996 ~ "ABS 6302.0 male total earnings (Nov + May average)",
                           year_ended_june >= 1982 ~ "OP8: male AWE (quarterly survey), linked",
                           TRUE ~ "OP8: earnings per employed male unit, linked"),
    wage_rates = case_when(!is.na(award_index_persons) ~ award_index_persons,
                           !is.na(minwage_male) ~ minwage_male * k_aw))
# continue wage rates with the WPI: link at 1997/98 via 1995/96 and a geometric 1996/97
gap <- which(a$year_ended_june == 1997); i96 <- which(a$year_ended_june == 1996); i98 <- which(a$year_ended_june == 1998)
# the WPI has no 1995/96 value, so it is linked to the award index assuming 1996/97 and
# 1997/98 grew at the WPI's own first-year rate (Sep 1997 - Jun 1998 annualised)
g1 <- (wpi$wpi_sa[wpi$t == mi("1998-06")] / wpi$wpi_sa[wpi$t == mi("1997-09")])^(4 / 3)
a$wage_rates[gap] <- a$wage_rates[i96] * g1
k_wpi <- a$wage_rates[gap] * g1 / a$wpi[i98]
a <- a |> mutate(wage_rates = if_else(year_ended_june >= 1998, wpi * k_wpi, wage_rates),
                 wage_rates_source = case_when(year_ended_june >= 1998 ~ "ABS Wage Price Index (SA, average of quarters)",
                                               year_ended_june == 1997 ~ "Interpolated (WPI first-year growth)",
                                               !is.na(award_index_persons) ~ "OP8 award rates of pay index",
                                               TRUE ~ "OP8 minimum weekly award rates, males, linked"))
cat(sprintf("WPI first-year growth used for 1996/97 and its link: %.2f%% a year\n", 100 * (g1 - 1)))

# ---- 3. Prices, real wages, unemployment ---------------------------------------------------
cpi_fy <- cpi |> mutate(fy = fyend(t)) |> group_by(fy) |> filter(n() == 4) |> summarise(cpi = mean(cpi), .groups = "drop")
u_fy <- une |> mutate(fy = fyend(t)) |> group_by(fy) |> filter(n() == 12) |> summarise(urate = mean(unemployment_rate), .groups = "drop")
a <- a |> left_join(cpi_fy, by = c("year_ended_june" = "fy")) |> left_join(u_fy, by = c("year_ended_june" = "fy")) |>
  arrange(year_ended_june) |>
  mutate(awe_growth = 100 * (awe_male / lag(awe_male) - 1),
         wage_rates_growth = 100 * (wage_rates / lag(wage_rates) - 1),
         inflation = 100 * (cpi / lag(cpi) - 1),
         real_awe = awe_male / cpi * cpi[year_ended_june == 2025],          # 2024-25 dollars
         real_awe_growth = 100 * (real_awe / lag(real_awe) - 1),
         real_wage_rates_growth = 100 * ((1 + wage_rates_growth / 100) / (1 + inflation / 100) - 1))
# checks: OP8's own percentage changes are reproduced, and the survey snapshots move with it
chk <- svy |> mutate(fy = year + 1L) |> inner_join(a |> select(year_ended_june, awe_male_op8), by = c("fy" = "year_ended_june")) |>
  arrange(year) |> mutate(g_svy = 100 * (awe_all_male / lag(awe_all_male) - 1), g_op8 = 100 * (awe_male_op8 / lag(awe_male_op8) - 1)) |>
  filter(year >= 1983, !is.na(g_svy))
cat(sprintf("Male AWE growth, Oct/Nov survey vs OP8 financial-year series, 1983-94: mean abs gap %.1f points\n",
            mean(abs(chk$g_svy - chk$g_op8))))

dec <- a |> filter(year_ended_june >= 1951) |> mutate(decade = 10 * ((year_ended_june - 1) %/% 10) + 1) |>
  group_by(decade) |> summarise(across(c(awe_growth, wage_rates_growth, inflation, real_awe_growth, urate), ~ round(mean(.x, na.rm = TRUE), 1)), .groups = "drop")
print(as.data.frame(dec), row.names = FALSE)

# ---- 4. Outputs ----------------------------------------------------------------------------
dir.create("output", showWarnings = FALSE)
r2 <- function(x) round(x, 2)
write_csv(a |> transmute(year_ended_june, awe_male = r2(awe_male), awe_source, awe_persons = r2(awe_persons_abs),
                         wage_rates_index = round(100 * wage_rates / wage_rates[year_ended_june == 2025], 3), wage_rates_source,
                         awe_growth = r2(awe_growth), wage_rates_growth = r2(wage_rates_growth), cpi_inflation = r2(inflation),
                         real_awe_2025_dollars = r2(real_awe), real_awe_growth = r2(real_awe_growth),
                         real_wage_rates_growth = r2(real_wage_rates_growth), unemployment_rate = r2(urate),
                         avg_earnings_nonfarm_op8 = avg_earnings_nonfarm, real_unit_labour_costs_op8 = rulc_index),
          "output/wages_annual.csv", na = "")
wq <- wpi |> mutate(wpi_growth_ye = 100 * (wpi_sa / lag(wpi_sa, 4) - 1))
write_csv(wq |> transmute(quarter_end, wpi_sa, wpi_growth_ye = r2(wpi_growth_ye)), "output/wpi_quarterly.csv", na = "")

# ---- 5. Charts -----------------------------------------------------------------------------
pal <- c("#1f4e79", "#c0504d", "#7f7f7f", "#4f9a3f", "#d79b00")
th <- theme_minimal(base_size = 11) + theme(legend.position = "bottom", panel.grid.minor = element_blank(), plot.title.position = "plot")
fyd <- function(y) as.Date(sprintf("%d-06-30", y))
g <- bind_rows(a |> transmute(y = year_ended_june, v = awe_growth, s = "Average weekly earnings (males)"),
               a |> transmute(y = year_ended_june, v = wage_rates_growth, s = "Wage rates (award rates, then WPI)"),
               a |> transmute(y = year_ended_june, v = inflation, s = "CPI inflation")) |> filter(!is.na(v))
g$s <- factor(g$s, unique(g$s))
p1 <- ggplot(g, aes(fyd(y), v, colour = s, linewidth = s)) + geom_hline(yintercept = 0, colour = "grey60") + geom_line() +
  scale_colour_manual(values = pal[c(1, 4, 3)], name = NULL) + scale_linewidth_manual(values = c(0.7, 0.5, 0.45), name = NULL) +
  labs(title = "Wage growth and inflation, years ended June 1951 - 2026 (per cent)",
       subtitle = paste0("Earnings: per employed male unit to 1980/81, male AWE after.\n",
                         "Wage rates: minimum award rates to 1976, award rates index to 1996, Wage Price Index from 1998"),
       x = NULL, y = NULL, caption = "Sources: RBA Occasional Paper 8 (tables 4.17); ABS 6302.0, 6345.0; RBA G1") + th
ggsave("output/wage_growth.png", p1, width = 9.5, height = 5.2, dpi = 150, bg = "white")

p2 <- ggplot(a |> filter(!is.na(real_awe)), aes(fyd(year_ended_june), real_awe)) + geom_line(colour = pal[1], linewidth = 0.8) +
  scale_y_log10() +
  labs(title = "Real average weekly earnings, males, 1949/50 - 2025/26 (2024-25 dollars a week, log scale)",
       subtitle = "Male AWE deflated by the CPI (financial-year averages)", x = NULL, y = NULL) + th
ggsave("output/real_earnings.png", p2, width = 9, height = 5, dpi = 150, bg = "white")

ph <- a |> filter(!is.na(urate), !is.na(wage_rates_growth)) |>
  mutate(period = cut(year_ended_june, c(1950, 1973, 1983, 1993, 2026), labels = c("1951-73", "1974-83", "1984-93", "1994-2026")))
p3 <- ggplot(ph, aes(urate, wage_rates_growth, colour = period)) + geom_path(linewidth = 0.4, alpha = 0.6) + geom_point(size = 1.8) +
  geom_text(data = ph |> filter(year_ended_june %in% c(1951, 1953, 1975, 1983, 1993, 2009, 2021, 2026)),
            aes(label = year_ended_june), size = 2.8, vjust = -0.8, show.legend = FALSE) +
  scale_colour_manual(values = pal[c(1, 2, 5, 4)], name = NULL) +
  labs(title = "Wage Phillips curve: wage-rate growth against unemployment, 1951 - 2026",
       subtitle = "Years ended June. Unemployment: monthly series from 09-unemployment, averaged",
       x = "Unemployment rate (per cent)", y = "Growth in wage rates (per cent)") + th
ggsave("output/phillips_curve.png", p3, width = 8, height = 6, dpi = 150, bg = "white")
cat("Done.\n")
