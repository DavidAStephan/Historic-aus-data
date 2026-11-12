# Housing finance, Australia, 1953 - 2026 (years ended June)
# Run from 11-housing-finance/:  Rscript R/housing_finance.R
# Needs the outputs of 04-housing-pipeline, 08-money-credit-rates and 10-wages.
suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })

mi <- function(p) { y <- as.integer(substr(p, 1, 4)); m <- as.integer(substr(p, 6, 7)); y * 12L + m - 1L }
fyend <- function(i) { y <- i %/% 12L; m <- i %% 12L + 1L; y + (m >= 7) }

# ---- 0. Inputs -----------------------------------------------------------------------------
hfc <- read_csv("data-raw/op8_3_3_housing_finance_commitments.csv", show_col_types = FALSE)
abs5601 <- read_csv("data-raw/abs_5601_owner_occupier_commitments_fy.csv", show_col_types = FALSE)
sb <- read_csv("../08-money-credit-rates/data-raw/op8_3_9_savings_banks_june.csv", show_col_types = FALSE)
bs <- read_csv("../08-money-credit-rates/data-raw/op8_3_12_building_societies_june.csv", show_col_types = FALSE)
opc <- read_csv("../08-money-credit-rates/data-raw/op8_3_2_credit_june.csv", show_col_types = FALSE)
mcm <- read_csv("../08-money-credit-rates/output/money_credit_monthly.csv", show_col_types = FALSE) |> mutate(t = mi(month))
lr <- read_csv("../08-money-credit-rates/output/long_run_annual.csv", show_col_types = FALSE) |>
  select(year_ended_june, gdp = nominal_gdp_m, housing_rate, inflation)
wg <- read_csv("../10-wages/output/wages_annual.csv", show_col_types = FALSE) |> select(year_ended_june, awe_male)
hp <- read_csv("../04-housing-pipeline/output/housing_pipeline_quarterly.csv", show_col_types = FALSE) |>
  mutate(t = mi(quarter_end_month), fy = fyend(t)) |> group_by(fy) |> filter(n() == 4) |>
  summarise(starts = sum(starts_orig), .groups = "drop")
rates <- read_csv("../08-money-credit-rates/output/interest_rates_monthly.csv", show_col_types = FALSE) |>
  mutate(fy = fyend(mi(month))) |> group_by(fy) |> filter(n() == 12) |>
  summarise(housing_rate_fy = mean(housing_variable), .groups = "drop")

# ---- 1. Housing credit outstanding, end-June 1960 - 2026 -----------------------------------
# From June 1977: the RBA's housing credit (break-adjusted, 08-money-credit-rates; it starts in
# Aug 1976 and June 1977 is its first June). Before that there is no total, but almost all
# housing loans were made by savings banks and building societies: in June 1977 their housing
# loans (7259 + 5022) were 97% of OP8's housing credit (12642). So housing credit before 1977
# is savings banks' housing loans plus building societies' mortgages, scaled to the RBA level
# by their June 1977 ratio. Building societies are first reported in 1962; for 1960-61 their
# mortgages are put at the 1962 ratio to savings bank housing loans.
rba_h <- mcm |> filter(t %% 12L == 5L, !is.na(credit_housing_bn)) |> transmute(year_ended_june = t %/% 12L, rba_housing_m = credit_housing_bn * 1000)
parts <- sb |> select(year_ended_june = june, sb_housing = loans_housing) |>
  full_join(bs |> select(year_ended_june = june, bs_mortgages = mortgages_outstanding), by = "year_ended_june") |>
  arrange(year_ended_june)
r62 <- with(parts |> filter(year_ended_june == 1962), bs_mortgages / sb_housing)
parts <- parts |> mutate(bs_est = coalesce(bs_mortgages, if_else(year_ended_june < 1962 & !is.na(sb_housing), sb_housing * r62, NA_real_)),
                         sb_bs = sb_housing + bs_est)
op77 <- opc$housing[opc$june == 1977]
k77 <- rba_h$rba_housing_m[rba_h$year_ended_june == 1977] / parts$sb_bs[parts$year_ended_june == 1977]
cat(sprintf("June 1977: savings banks + building societies %.0f = %.1f%% of OP8 housing credit (%.0f); RBA break-adjusted %.0f; scale %.3f\n",
            parts$sb_bs[parts$year_ended_june == 1977], 100 * parts$sb_bs[parts$year_ended_june == 1977] / op77, op77,
            rba_h$rba_housing_m[rba_h$year_ended_june == 1977], k77))
yrs <- 1953:2026
a <- tibble(year_ended_june = yrs) |>
  left_join(parts, by = "year_ended_june") |> left_join(rba_h, by = "year_ended_june") |>
  left_join(lr, by = "year_ended_june") |> left_join(wg, by = "year_ended_june") |>
  left_join(rates, by = c("year_ended_june" = "fy")) |> left_join(hp, by = c("year_ended_june" = "fy")) |>
  mutate(housing_credit_m = case_when(year_ended_june >= 1977 ~ rba_housing_m,
                                      !is.na(sb_bs) ~ sb_bs * k77),
         housing_credit_source = case_when(year_ended_june >= 1977 ~ "RBA housing credit (break-adjusted, 08-money-credit-rates)",
                                           year_ended_june >= 1962 ~ "Savings bank housing loans + building society mortgages (OP8 3.9, 3.12), scaled to RBA at June 1977",
                                           !is.na(sb_bs) ~ "Savings bank housing loans (OP8 3.9) + building societies estimated at their 1962 ratio, scaled"),
         housing_credit_pct_gdp = 100 * housing_credit_m / gdp,
         housing_credit_growth = 100 * (housing_credit_m / lag(housing_credit_m) - 1),
         sb_share_pct = 100 * sb_housing / sb_bs)

# ---- 2. Housing finance commitments, 1952/53 - 1996/97 and 2002/03 - 2025/26 -------------
# OP8 table 3.3: loans approved to individuals for owner occupation, by lender, for new
# dwellings (construction or purchase of new) and established dwellings (from 1966/67).
# ABS 5601.0: owner-occupier new loan commitments excluding refinancing, from Sep 2002.
hf <- hfc |> transmute(year_ended_june,
                       new_no = new_total_no * 1000, new_m = new_total_m, est_no = est_total_no * 1000, est_m = est_total_m,
                       all_no = if_else(!is.na(est_no), new_no + est_no, NA_real_), all_m = if_else(!is.na(est_m), new_m + est_m, NA_real_),
                       sb_m = new_savings_banks_m + coalesce(est_savings_banks_m, 0) * !is.na(est_total_m),
                       banks_m = new_banks_m + coalesce(est_banks_m, 0) * !is.na(est_total_m),
                       bsoc_m = new_building_soc_m + coalesce(est_building_soc_m, 0) * !is.na(est_total_m),
                       other_m = new_other_m + coalesce(est_other_m, 0) * !is.na(est_total_m), hf_note = note) |>
  bind_rows(abs5601 |> transmute(year_ended_june, all_no = owner_occupier_loans_number, all_m = owner_occupier_loans_value_m,
                                 hf_note = "ABS 5601.0 owner-occupier new loan commitments excl. refinancing (sum of quarters)"))
a <- a |> left_join(hf, by = "year_ended_june") |>
  mutate(avg_loan = case_when(!is.na(all_no) ~ 1e6 * all_m / all_no, !is.na(new_no) ~ 1e6 * new_m / new_no),
         avg_loan_basis = case_when(!is.na(all_no) & year_ended_june >= 2003 ~ "ABS 5601.0, all owner-occupier loans",
                                    !is.na(all_no) ~ "OP8 3.3, new and established dwellings",
                                    !is.na(new_no) ~ "OP8 3.3, new dwellings only"),
         avg_loan_to_earnings = avg_loan / (52 * awe_male),
         new_loans_per_start = new_no / starts,
         commitments_pct_gdp = 100 * coalesce(all_m, new_m) / gdp,
         lender_total_m = banks_m + bsoc_m + other_m)
ov <- a |> filter(!is.na(new_no), !is.na(all_no), year_ended_june <= 1997)
cat(sprintf("Average loan, new-dwelling loans / all loans, 1967-96: %.2f - %.2f\n", min(1e6 * ov$new_m / ov$new_no / ov$avg_loan), max(1e6 * ov$new_m / ov$new_no / ov$avg_loan)))
for (y in c(1956, 1966, 1976, 1986, 1996, 2006, 2016, 2026))
  with(a[a$year_ended_june == y, ], cat(sprintf("%d: average loan $%.0f = %.2f years of male AWE; housing credit %.1f%% of GDP\n", y, avg_loan, avg_loan_to_earnings, housing_credit_pct_gdp)))

# ---- 3. Outputs ----------------------------------------------------------------------------
dir.create("output", showWarnings = FALSE)
r1 <- function(x) round(x, 1); r2 <- function(x) round(x, 2)
write_csv(a |> transmute(year_ended_june,
                         housing_credit_m = round(housing_credit_m), housing_credit_pct_gdp = r1(housing_credit_pct_gdp),
                         housing_credit_growth = r1(housing_credit_growth), housing_credit_source,
                         savings_bank_housing_loans_m = sb_housing, building_society_mortgages_m = bs_mortgages,
                         savings_bank_share_of_the_two_pct = r1(sb_share_pct),
                         commitments_new_dwellings_number = new_no, commitments_new_dwellings_m = new_m,
                         commitments_established_number = est_no, commitments_established_m = est_m,
                         commitments_all_number = all_no, commitments_all_m = all_m,
                         commitments_banks_m = banks_m, commitments_of_which_savings_banks_m = sb_m,
                         commitments_building_societies_m = bsoc_m, commitments_other_m = other_m, commitments_note = hf_note,
                         average_loan = round(avg_loan), average_loan_basis = avg_loan_basis,
                         average_loan_years_of_male_earnings = r2(avg_loan_to_earnings),
                         dwelling_starts = starts, new_dwelling_loans_per_start = r2(new_loans_per_start),
                         commitments_pct_gdp = r1(commitments_pct_gdp), housing_rate_fy_avg = r2(housing_rate_fy),
                         awe_male, nominal_gdp_m = gdp),
          "output/housing_finance_annual.csv", na = "")

# ---- 4. Charts -----------------------------------------------------------------------------
pal <- c("#1f4e79", "#c0504d", "#7f7f7f", "#4f9a3f", "#d79b00")
th <- theme_minimal(base_size = 11) + theme(legend.position = "bottom", panel.grid.minor = element_blank(), plot.title.position = "plot")
fyd <- function(y) as.Date(sprintf("%d-06-30", y))
hc <- a |> filter(!is.na(housing_credit_pct_gdp)) |>
  mutate(s = if_else(year_ended_june >= 1977, "RBA housing credit", "Savings banks + building societies, scaled to RBA at 1977"))
p1 <- ggplot(hc, aes(fyd(year_ended_june), housing_credit_pct_gdp, colour = s)) + geom_line(linewidth = 0.8) +
  geom_point(data = hc |> filter(year_ended_june < 1977), size = 1) +
  scale_colour_manual(values = pal[c(1, 5)], name = NULL) +
  labs(title = "Housing credit relative to GDP, end-June 1960 - 2026 (per cent)",
       subtitle = paste0("Before 1977 savings banks and building societies made almost all housing loans (97% in June 1977);\n",
                         "their loans are scaled to the RBA's housing credit at June 1977. 1960-61 building societies estimated."),
       x = NULL, y = NULL, caption = "Sources: RBA Occasional Paper 8 (tables 3.2, 3.9, 3.12); RBA D2 via 08-money-credit-rates; ABS 5206.0") + th
ggsave("output/housing_credit_gdp.png", p1, width = 9, height = 5, dpi = 150, bg = "white")

al <- a |> filter(!is.na(avg_loan_to_earnings))
p2 <- ggplot(al, aes(fyd(year_ended_june), avg_loan_to_earnings, colour = avg_loan_basis, group = 1)) +
  geom_line(data = al |> filter(year_ended_june <= 1997), linewidth = 0.7) + geom_line(data = al |> filter(year_ended_june >= 2003), linewidth = 0.7) +
  geom_point(size = 1.1) + scale_colour_manual(values = pal[c(1, 5, 2)], name = NULL) +
  guides(colour = guide_legend(nrow = 2)) +
  labs(title = "Average new owner-occupier housing loan, in years of male earnings, 1953 - 2026",
       subtitle = paste0("Value of loan commitments / number, divided by annual male average weekly earnings (x 52).\n",
                         "No consistent commitments series for 1997/98 - 2001/02."),
       x = NULL, y = "Years of male earnings", caption = "Sources: RBA Occasional Paper 8 (table 3.3); ABS 5601.0; 10-wages") + th
ggsave("output/average_loan_to_earnings.png", p2, width = 9, height = 5.2, dpi = 150, bg = "white")

L <- c("Savings banks", "Trading banks", "Building societies", "Other lenders")
lv <- bind_rows(a |> transmute(y = year_ended_june, s = L[1], v = sb_m), a |> transmute(y = year_ended_june, s = L[2], v = banks_m - sb_m),
                a |> transmute(y = year_ended_june, s = L[3], v = bsoc_m), a |> transmute(y = year_ended_june, s = L[4], v = other_m)) |>
  filter(y >= 1955, y <= 1989, y != 1976) |> group_by(y) |> filter(!any(is.na(v[s %in% L[c(1, 2, 4)]]))) |>
  mutate(v = coalesce(v, 0), share = 100 * v / sum(v)) |> ungroup() |> mutate(s = factor(s, rev(L)))
p3 <- ggplot(lv, aes(fyd(y), share, fill = s)) + geom_area(position = "stack", alpha = 0.9) +
  scale_fill_manual(values = setNames(pal[c(4, 1, 5, 3)], L), breaks = L, name = NULL) +
  labs(title = "Who lent for owner-occupied housing: shares of loan commitments, 1954/55 - 1988/89 (per cent of value)",
       subtitle = paste0("New dwellings to 1965/66, new and established after. Building societies are counted from 1969/70\n",
                         "(earlier in 'other'). 1975/76 missing (new collection)."),
       x = NULL, y = NULL, caption = "Source: RBA Occasional Paper 8, table 3.3") + th
ggsave("output/housing_lenders.png", p3, width = 9.5, height = 5.2, dpi = 150, bg = "white")
cat("Done.\n")
