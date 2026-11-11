# Quarterly population for Australia, 1946-2026, and the housing pipeline per capita
# ----------------------------------------------------------------------------------
# Run after ../04-housing-pipeline/R/housing_pipeline.R (needs housing_pipeline_quarterly.csv).
#
# Inputs
#   pop_erp_quarterly.tsv       ABS 3101.0 (Mar 2026 release) Table 4: estimated resident
#                               population (ERP), Australia, end of quarter, Jun 1981 - Mar 2026
#   pop_hist_total_halfyear.tsv ABS Historical Population 2021 (HPDC1 Tables 1 and 2):
#                               population at 30 June and 31 December, 1944-1982
#   pop_hist_age_june.tsv       population at 30 June, total and aged 15-64 and 15+:
#                               1944-1970 from Historical Population (HPDC2 Table 1, five-year
#                               age groups); 1971-2025 from ABS 3101.0 Table 59 (ERP by single
#                               year of age)
# Outputs
#   population_quarterly.csv, housing_pipeline_per_capita.csv,
#   housing_per_capita.png, starts_per_capita_denominators.png
#
# Breaks in the population series and how they are handled
#   1971: the ABS switched from counting people present in Australia to the estimated
#         resident population (adds residents temporarily overseas and an allowance for
#         census undercount). Only ERP exists from June 1971, so the old series is scaled
#         up by the ratio implied by normal growth: June 1971 ERP / (June 1970 old basis x
#         (1 + average growth of 1969-70 and 1971-72)). About +2.5%.
#   1961: the official totals include estimates of the Aboriginal and Torres Strait
#         Islander population from 1961; the age table excludes them until 1966. Totals
#         before June 1961 are scaled by the June 1961 ratio of the two (about +0.4%).
#   Age structure: the shares aged 15-64 and 15+ come from the age table each June
#         (on its own basis) and are applied to the adjusted total. The share moves by
#         only 0.15 points between 1970 and 1971.
# Quarterly values
#   Total: ABS quarterly ERP from June 1981. Before that, June and December values
#   with September and March interpolated geometrically. June 2026 (not yet published)
#   is extrapolated at the March 2026 quarter's growth rate.
#   Age groups: June shares interpolated linearly between years and applied to the
#   quarterly total; extrapolated past June 2025 at the latest annual change.
# Per capita measures
#   Dwellings per 1,000 people, annualised: seasonally adjusted quarterly count x 4 /
#   population at the end of the quarter x 1,000. Same with the 15-64 and 15+ population.
# Run from this analysis folder (the folder that contains R/), e.g.  Rscript R/per_capita.R
#   inputs in data-raw/, outputs written to output/

suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })
md <- function(s) as.Date(paste0(s, "-01"))

erpq <- read_tsv("data-raw/pop_erp_quarterly.tsv", col_types = "cd") |> mutate(q = md(quarter_end))
half <- read_tsv("data-raw/pop_hist_total_halfyear.tsv", col_types = "cd") |> mutate(q = md(month))
age  <- read_tsv("data-raw/pop_hist_age_june.tsv", col_types = "idddc")

# ---- Break factors ---------------------------------------------------------------
jun <- function(y) half$pop_total[half$q == as.Date(sprintf("%d-06-01", y))]
g_before <- jun(1970) / jun(1969) - 1
g_after  <- jun(1972) / jun(1971) - 1
k71 <- jun(1971) / (jun(1970) * (1 + mean(c(g_before, g_after))))
k61 <- jun(1961) / age$pop_total[age$year == 1961]
cat(sprintf("1971 ERP factor %.4f (growth 1969-70 %.2f%%, 1971-72 %.2f%%, raw 1970-71 %.2f%%)\n",
            k71, 100 * g_before, 100 * g_after, 100 * (jun(1971) / jun(1970) - 1)))
cat(sprintf("1961 Indigenous-inclusion factor %.4f\n", k61))

half <- half |>
  mutate(adj = case_when(q < as.Date("1961-06-01") ~ k61 * k71,
                         q < as.Date("1971-06-01") ~ k71,
                         TRUE ~ 1),
         pop_adj = pop_total * adj)

# ---- Quarterly total ----------------------------------------------------------------
qs <- seq(as.Date("1946-06-01"), as.Date("2026-06-01"), by = "3 months")
hq <- tibble(q = qs) |> left_join(select(half, q, pop_adj), by = "q")
# Sep / Mar quarters: geometric mean of the neighbouring Jun and Dec values
for (i in which(is.na(hq$pop_adj) & hq$q < as.Date("1982-06-01"))) {
  hq$pop_adj[i] <- sqrt(hq$pop_adj[i - 1] * hq$pop_adj[i + 1])
}
pop <- hq |>
  left_join(select(erpq, q, erp = pop_total), by = "q") |>
  mutate(pop_total = if_else(q >= as.Date("1981-06-01"), erp, pop_adj),
         pop_source = case_when(!is.na(erp) & q >= as.Date("1981-06-01") ~ "ABS 3101.0 quarterly ERP",
                                q >= as.Date("1971-06-01") ~ "ABS ERP, Jun/Dec (Sep/Mar interpolated)",
                                TRUE ~ "Historical population, adjusted to ERP basis (Sep/Mar interpolated)"))
last <- max(erpq$q)
gq <- erpq$pop_total[erpq$q == last] / erpq$pop_total[erpq$q == seq(last, by = "-3 months", length.out = 2)[2]]
pop <- pop |>
  mutate(pop_total = if_else(q > last, erpq$pop_total[erpq$q == last] * gq^(as.numeric(round((q - last) / 91.3))), pop_total),
         pop_source = if_else(q > last, "Extrapolated (latest quarterly growth)", pop_source)) |>
  select(q, pop_total, pop_source)
stopifnot(!any(is.na(pop$pop_total)))
# seam check at Jun 1981 (ERP quarterly vs Jun/Dec historical ERP)
cat("Jun 1981 check: historical", jun(1981), "vs quarterly ERP", erpq$pop_total[erpq$q == as.Date("1981-06-01")], "\n")

# ---- Working-age shares -------------------------------------------------------------
sh <- age |> transmute(q = as.Date(sprintf("%d-06-01", year)),
                       s1564 = pop_15_64 / pop_total, s15p = pop_15plus / pop_total)
cat(sprintf("Share 15-64: Jun 1970 %.4f, Jun 1971 %.4f | share 15+: %.4f, %.4f\n",
            sh$s1564[sh$q == as.Date("1970-06-01")], sh$s1564[sh$q == as.Date("1971-06-01")],
            sh$s15p[sh$q == as.Date("1970-06-01")], sh$s15p[sh$q == as.Date("1971-06-01")]))
interp <- function(x, xs, ys) {
  out <- approx(as.numeric(xs), ys, xout = as.numeric(x), rule = 1)$y
  # extrapolate beyond last June at the last annual change
  n <- length(ys); slope <- (ys[n] - ys[n - 1]) / as.numeric(xs[n] - xs[n - 1])
  after <- as.numeric(x) > as.numeric(xs[n])
  out[after] <- ys[n] + slope * (as.numeric(x[after]) - as.numeric(xs[n]))
  out
}
pop <- pop |>
  mutate(share_15_64 = interp(q, sh$q, sh$s1564),
         share_15plus = interp(q, sh$q, sh$s15p),
         pop_15_64 = pop_total * share_15_64,
         pop_15plus = pop_total * share_15plus)
stopifnot(!any(is.na(pop$pop_15_64[pop$q >= as.Date("1946-06-01")])))

write_csv(pop |> transmute(quarter_end = format(q, "%Y-%m"), pop_total = round(pop_total),
                           pop_15_64 = round(pop_15_64), pop_15plus = round(pop_15plus),
                           share_15_64 = round(share_15_64, 4), share_15plus = round(share_15plus, 4),
                           pop_source),
          "output/population_quarterly.csv")

# ---- Per capita -------------------------------------------------------------------
hp <- read_csv("../04-housing-pipeline/output/housing_pipeline_quarterly.csv", show_col_types = FALSE) |>
  mutate(q = md(quarter_end_month)) |>
  left_join(pop, by = "q")
stopifnot(!any(is.na(hp$pop_total)))
pc <- function(x, p) 4 * x / p * 1000
hp <- hp |>
  mutate(approvals_per_1000 = pc(approvals_sa, pop_total),
         starts_per_1000 = pc(starts_sa, pop_total),
         completions_per_1000 = pc(completions_sa, pop_total),
         approvals_per_1000_15_64 = pc(approvals_sa, pop_15_64),
         starts_per_1000_15_64 = pc(starts_sa, pop_15_64),
         completions_per_1000_15_64 = pc(completions_sa, pop_15_64),
         approvals_per_1000_15plus = pc(approvals_sa, pop_15plus),
         starts_per_1000_15plus = pc(starts_sa, pop_15plus),
         completions_per_1000_15plus = pc(completions_sa, pop_15plus))
out <- hp |>
  select(quarter, quarter_end_month, approvals_sa, starts_sa, completions_sa,
         pop_total, pop_15_64, pop_15plus, ends_with("per_1000"), ends_with("15_64"), ends_with("15plus"), pop_source) |>
  select(-any_of(c("share_15_64", "share_15plus"))) |>
  mutate(across(c(pop_total, pop_15_64, pop_15plus), round),
         across(contains("per_1000"), ~ round(.x, 2)))
write_csv(out, "output/housing_pipeline_per_capita.csv", na = "")

# Annual (calendar year, original series) per 1,000 mean population
ann <- read_csv("../04-housing-pipeline/output/housing_pipeline_quarterly.csv", show_col_types = FALSE) |>
  mutate(q = md(quarter_end_month), year = as.integer(format(q, "%Y"))) |>
  left_join(pop, by = "q") |>
  group_by(year) |>
  summarise(n = n(), pop = mean(pop_total),
            starts = sum(starts_orig), completions = sum(completions_orig), approvals = sum(approvals_orig), .groups = "drop") |>
  filter(n == 4) |>
  mutate(starts_pc = 1000 * starts / pop, completions_pc = 1000 * completions / pop, approvals_pc = 1000 * approvals / pop)
cat("\nStarts per 1,000 people, highest calendar years:\n")
print(slice_max(ann, starts_pc, n = 6) |> transmute(year, starts, starts_pc = round(starts_pc, 1)))
cat("Recent years:\n")
print(filter(ann, year >= 2019) |> transmute(year, starts_pc = round(starts_pc, 1), completions_pc = round(completions_pc, 1), approvals_pc = round(approvals_pc, 1)))
avg <- function(a, b) round(mean(ann$completions_pc[ann$year >= a & ann$year <= b]), 1)
cat(sprintf("Average completions per 1,000: 1950s %.1f, 1960s %.1f, 1970s %.1f, 1980s %.1f, 1990s %.1f, 2000s %.1f, 2010s %.1f, 2020-25 %.1f\n",
            avg(1950, 1959), avg(1960, 1969), avg(1970, 1979), avg(1980, 1989), avg(1990, 1999), avg(2000, 2009), avg(2010, 2019), avg(2020, 2025)))

# ---- Charts ----------------------------------------------------------------------
cols <- c("Approvals" = "#7f9cc9", "Starts" = "#c0392b", "Completions" = "#1b7f5a")
long <- bind_rows(
  transmute(hp, q, series = "Approvals", v = approvals_per_1000),
  transmute(hp, q, series = "Starts", v = starts_per_1000),
  transmute(hp, q, series = "Completions", v = completions_per_1000)
) |> filter(!is.na(v)) |> mutate(series = factor(series, levels = names(cols)))
p1 <- ggplot(long, aes(q, v, colour = series)) +
  annotate("rect", xmin = min(hp$q), xmax = as.Date("1955-06-01"), ymin = -Inf, ymax = Inf, fill = "grey92") +
  geom_line(linewidth = 0.55) +
  scale_colour_manual(values = cols, name = NULL) +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y", expand = expansion(mult = 0.01)) +
  scale_y_continuous(limits = c(0, NA), breaks = seq(0, 14, 2), expand = expansion(mult = c(0, 0.04))) +
  labs(title = "New dwellings per 1,000 people, Australia, 1946-2026",
       subtitle = "Annualised rate, seasonally adjusted quarterly data. Shading: starts and completions from the 1948-57 bulletins, benchmarked.",
       x = NULL, y = "Dwellings per 1,000 people per year",
       caption = "Population: ABS estimated resident population (quarterly from 1981); earlier years from ABS Historical Population, adjusted to the ERP basis.") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.minor = element_blank(), plot.title.position = "plot",
        plot.caption = element_text(hjust = 0, size = 8, colour = "grey35"))
ggsave("output/housing_per_capita.png", p1, width = 11, height = 5.6, dpi = 200, bg = "white")

dcols <- c("Per 1,000 people" = "#c0392b", "Per 1,000 aged 15+" = "#e08b2c", "Per 1,000 aged 15-64" = "#6a3d9a")
dl <- bind_rows(
  transmute(hp, q, d = "Per 1,000 people", v = starts_per_1000),
  transmute(hp, q, d = "Per 1,000 aged 15+", v = starts_per_1000_15plus),
  transmute(hp, q, d = "Per 1,000 aged 15-64", v = starts_per_1000_15_64)
) |> mutate(d = factor(d, levels = names(dcols)))
p2 <- ggplot(dl, aes(q, v, colour = d)) +
  geom_line(linewidth = 0.5) +
  scale_colour_manual(values = dcols, name = NULL) +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y", expand = expansion(mult = 0.01)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.04))) +
  labs(title = "Dwelling starts relative to three population measures, 1946-2026",
       subtitle = "Annualised rate, seasonally adjusted", x = NULL, y = "Starts per 1,000 per year") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.minor = element_blank(), plot.title.position = "plot")
ggsave("output/starts_per_capita_denominators.png", p2, width = 10, height = 4.8, dpi = 200, bg = "white")
