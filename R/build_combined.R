# Build one long-format file of the repository's headline series, with a catalogue.
# Run from the repository root after run_all.R:  Rscript R/build_combined.R
# Writes data/aus_historic_series.csv (series_id, date, value) and data/series_catalogue.csv.
suppressPackageStartupMessages({ library(readr); library(dplyr) })

# One row per series: id, section folder, output file, date column, value column, frequency
# (M monthly, Q quarterly, A annual year ended June), unit, adjustment, description.
# Dates are the last month of the period (YYYY-MM) except where noted in the description.
s <- function(id, sec, file, date, col, freq, unit, adj, desc) tibble(series_id = id, section = sec, file = file, date_col = date,
                                                                    column = col, frequency = freq, unit = unit, adjustment = adj, description = desc)
man <- bind_rows(
  # 01, 02: vacancies and the Beveridge curve
  s("vacancies_000_q", "01-job-vacancies", "job_vacancies_spliced_quarterly.csv", "month", "vacancies_000", "Q", "'000", "SA",
    "Job vacancies, CES (scaled) spliced onto ABS 6354.0; dated at the mid-quarter survey month"),
  s("ces_vacancies_sa_m", "01-job-vacancies", "ces_vacancies_sa_monthly.csv", "month", "vacancies_sa", "M", "number", "SA",
    "CES registered unfilled vacancies"),
  s("vacancy_rate_q", "02-beveridge-curve", "beveridge_quarterly.csv", "month", "vacancy_rate", "Q", "per cent", "SA",
    "Vacancies as a share of the labour force; mid-quarter month"),
  s("vacancies_per_unemployed_q", "02-beveridge-curve", "beveridge_quarterly.csv", "month", "v_per_u", "Q", "ratio", "SA",
    "Vacancies per unemployed person; mid-quarter month"),
  # 03 - 05: dwellings and population
  s("dwelling_approvals_m", "03-building-approvals", "dwelling_approvals_spliced_monthly.csv", "month", "total_orig", "M", "number", "original", "Dwelling units approved, total"),
  s("dwelling_approvals_sa_m", "03-building-approvals", "dwelling_approvals_spliced_monthly.csv", "month", "total_sa", "M", "number", "SA", "Dwelling units approved, total"),
  s("dwelling_approvals_private_sa_m", "03-building-approvals", "dwelling_approvals_spliced_monthly.csv", "month", "private_sa", "M", "number", "SA", "Dwelling units approved, private sector"),
  s("dwelling_starts_q", "04-housing-pipeline", "housing_pipeline_quarterly.csv", "quarter_end_month", "starts_orig", "Q", "number", "original", "New dwellings commenced"),
  s("dwelling_starts_sa_q", "04-housing-pipeline", "housing_pipeline_quarterly.csv", "quarter_end_month", "starts_sa", "Q", "number", "SA", "New dwellings commenced"),
  s("dwelling_completions_sa_q", "04-housing-pipeline", "housing_pipeline_quarterly.csv", "quarter_end_month", "completions_sa", "Q", "number", "SA", "New dwellings completed"),
  s("population_q", "05-housing-per-capita", "population_quarterly.csv", "quarter_end", "pop_total", "Q", "persons", "", "Population, total (ERP basis)"),
  s("population_15_64_q", "05-housing-per-capita", "population_quarterly.csv", "quarter_end", "pop_15_64", "Q", "persons", "", "Population aged 15-64"),
  s("dwelling_starts_per_1000_q", "05-housing-per-capita", "housing_pipeline_per_capita.csv", "quarter_end_month", "starts_per_1000", "Q", "per 1,000 people, annualised", "SA", "Dwellings commenced per 1,000 people"),
  # 06, 07: investment and retail
  s("capex_sa_q", "06-capex", "capex_spliced_quarterly.csv", "quarter_end_month", "total_sa", "Q", "$ million", "SA", "Private new capital expenditure, total"),
  s("capex_buildings_sa_q", "06-capex", "capex_spliced_quarterly.csv", "quarter_end_month", "bs_sa", "Q", "$ million", "SA", "Private new capex, buildings and structures"),
  s("capex_equipment_sa_q", "06-capex", "capex_spliced_quarterly.csv", "quarter_end_month", "epm_sa", "Q", "$ million", "SA", "Private new capex, equipment, plant and machinery"),
  s("capex_real_q", "06-capex", "capex_spliced_quarterly.csv", "quarter_end_month", "total_real_2023_24_prices", "Q", "$ million, 2023-24 prices", "SA", "Private new capital expenditure, real"),
  s("capex_pct_gdp_q", "06-capex", "capex_spliced_quarterly.csv", "quarter_end_month", "share_gdp_pct", "Q", "per cent of GDP", "SA", "Private new capital expenditure, share of GDP"),
  s("retail_sales_m", "07-retail-sales", "retail_sales_monthly.csv", "month", "turnover_sa", "M", "$ million", "SA", "Retail turnover"),
  s("retail_sales_real_m", "07-retail-sales", "retail_sales_monthly.csv", "month", "turnover_sa_real_2024_25", "M", "$ million, 2024-25 prices", "SA", "Retail turnover, real"),
  s("retail_sales_q", "07-retail-sales", "retail_sales_quarterly.csv", "quarter", "turnover_sa", "Q", "$ million", "SA", "Retail turnover"),
  s("retail_real_per_capita_q", "07-retail-sales", "retail_sales_quarterly.csv", "quarter", "real_per_capita_annualised", "Q", "$ a person a year, 2024-25 prices", "SA", "Retail turnover, real, per person"),
  # 08: rates
  s("cash_rate_m", "08-money-credit-rates", "interest_rates_monthly.csv", "month", "cash_rate", "M", "per cent", "", "Cash rate (target from Aug 1990, interbank overnight before)"),
  s("bill_90d_m", "08-money-credit-rates", "interest_rates_monthly.csv", "month", "bill_90d", "M", "per cent", "", "90-day bank bill yield"),
  s("short_rate_m", "08-money-credit-rates", "interest_rates_monthly.csv", "month", "short_rate", "M", "per cent", "", "Short-term rate: cash rate, 90-day bills before May 1976"),
  s("bond_10y_m", "08-money-credit-rates", "interest_rates_monthly.csv", "month", "bond_10y", "M", "per cent", "", "10-year government bond yield"),
  s("housing_rate_m", "08-money-credit-rates", "interest_rates_monthly.csv", "month", "housing_variable", "M", "per cent", "", "Banks' standard variable housing rate"),
  s("small_business_rate_m", "08-money-credit-rates", "interest_rates_monthly.csv", "month", "small_business_overdraft", "M", "per cent", "", "Small business variable overdraft indicator rate"),
  s("real_short_rate_m", "08-money-credit-rates", "interest_rates_monthly.csv", "month", "real_short_rate", "M", "per cent", "", "Short rate less year-ended CPI inflation"),
  s("real_bond_10y_m", "08-money-credit-rates", "interest_rates_monthly.csv", "month", "real_bond_10y", "M", "per cent", "", "10-year bond yield less year-ended CPI inflation"),
  s("cpi_inflation_m", "08-money-credit-rates", "interest_rates_monthly.csv", "month", "cpi_inflation_ye", "M", "per cent", "", "CPI inflation, year-ended (quarterly, interpolated to months)"),
  s("breakeven_10y_m", "08-money-credit-rates", "breakeven_inflation_monthly.csv", "month", "breakeven_10y", "M", "per cent", "", "10-year break-even inflation (nominal less indexed bond yield)"),
  s("real_bond_10y_indexed_m", "08-money-credit-rates", "breakeven_inflation_monthly.csv", "month", "real_bond_10y_indexed", "M", "per cent", "", "10-year indexed bond yield (real)"),
  s("infl_exp_consumer_1y_q", "08-money-credit-rates", "inflation_expectations_quarterly.csv", "quarter", "consumer_1y", "Q", "per cent", "", "Consumer inflation expectations, 1 year ahead (Melbourne Institute)"),
  s("infl_exp_business_3m_q", "08-money-credit-rates", "inflation_expectations_quarterly.csv", "quarter", "business_3m_annualised", "Q", "per cent", "", "Business expectations of selling prices, 3 months ahead, annualised (NAB)"),
  s("infl_exp_economists_1y_q", "08-money-credit-rates", "inflation_expectations_quarterly.csv", "quarter", "market_economists_1y", "Q", "per cent", "", "Market economists' inflation expectations, 1 year ahead"),
  s("infl_exp_economists_2y_q", "08-money-credit-rates", "inflation_expectations_quarterly.csv", "quarter", "market_economists_2y", "Q", "per cent", "", "Market economists' inflation expectations, 2 years ahead"),
  s("infl_exp_unions_1y_q", "08-money-credit-rates", "inflation_expectations_quarterly.csv", "quarter", "union_officials_1y", "Q", "per cent", "", "Union officials' inflation expectations, 1 year ahead"),
  # 08: money and credit
  s("currency_m", "08-money-credit-rates", "money_credit_monthly.csv", "month", "currency_bn", "M", "$ billion", "SA", "Currency"),
  s("m3_m", "08-money-credit-rates", "money_credit_monthly.csv", "month", "m3_bn", "M", "$ billion", "SA from 1965", "M3, break-adjusted"),
  s("broad_money_m", "08-money-credit-rates", "money_credit_monthly.csv", "month", "broad_money_bn", "M", "$ billion", "SA", "Broad money, break-adjusted"),
  s("credit_total_m", "08-money-credit-rates", "money_credit_monthly.csv", "month", "credit_total_bn", "M", "$ billion", "SA", "Total credit, break-adjusted (interpolated before Sep 1976)"),
  s("credit_housing_m", "08-money-credit-rates", "money_credit_monthly.csv", "month", "credit_housing_bn", "M", "$ billion", "SA", "Housing credit, break-adjusted"),
  s("credit_personal_m", "08-money-credit-rates", "money_credit_monthly.csv", "month", "credit_personal_bn", "M", "$ billion", "SA", "Personal credit, break-adjusted"),
  s("credit_business_m", "08-money-credit-rates", "money_credit_monthly.csv", "month", "credit_business_bn", "M", "$ billion", "SA", "Business credit, break-adjusted"),
  s("credit_pct_gdp_q", "08-money-credit-rates", "money_credit_pct_gdp_quarterly.csv", "quarter", "credit_pct_gdp", "Q", "per cent of GDP", "", "Total credit / four-quarter nominal GDP"),
  s("housing_credit_pct_gdp_q", "08-money-credit-rates", "money_credit_pct_gdp_quarterly.csv", "quarter", "housing_credit_pct_gdp", "Q", "per cent of GDP", "", "Housing credit / four-quarter nominal GDP"),
  s("m3_pct_gdp_q", "08-money-credit-rates", "money_credit_pct_gdp_quarterly.csv", "quarter", "m3_pct_gdp", "Q", "per cent of GDP", "", "M3 / four-quarter nominal GDP"),
  s("trading_bank_lending_m", "08-money-credit-rates", "bank_lending_monthly_1957_76.csv", "month", "trading_bank_lending_sa_m", "M", "$ million", "SA", "Major trading banks' loans, advances and bills discounted, 1957-76 (break-adjusted)"),
  s("savings_bank_lending_m", "08-money-credit-rates", "bank_lending_monthly_1957_76.csv", "month", "savings_bank_lending_m", "M", "$ million", "original", "Savings banks' loans, 1957-76 (break-adjusted; interpolated between Junes before Sep 1971)"),
  s("all_bank_lending_m", "08-money-credit-rates", "bank_lending_monthly_1957_76.csv", "month", "all_bank_lending_sa_m", "M", "$ million", "SA", "Lending by major trading banks plus savings banks, 1957-76"),
  s("nonbank_lending_m", "08-money-credit-rates", "bank_lending_monthly_1957_76.csv", "month", "nonbank_lending_m", "M", "$ million", "SA", "Non-bank lending, monthly estimate 1957-76"),
  s("instalment_credit_m", "08-money-credit-rates", "instalment_credit_monthly_1953_72.csv", "month", "instalment_credit_sa_m", "M", "$ million", "SA", "Finance businesses' instalment credit for retail sales outstanding, 1953-72"),
  s("bank_loans_a", "08-money-credit-rates", "lending_banks_nonbanks_june_1953_97.csv", "year_ended_june", "bank_loans_m", "A", "$ million", "", "Lending by banks, end-June (OP8)"),
  s("nonbank_loans_a", "08-money-credit-rates", "lending_banks_nonbanks_june_1953_97.csv", "year_ended_june", "nonbank_loans_restated_m", "A", "$ million", "", "Lending by non-bank financial intermediaries, end-June (OP8; restated before 1963)"),
  # 08: annual long run
  s("short_rate_a", "08-money-credit-rates", "long_run_annual.csv", "year_ended_june", "short_rate", "A", "per cent", "", "Short-term rate (see short_rate_basis in the source file)"),
  s("bond_10y_a", "08-money-credit-rates", "long_run_annual.csv", "year_ended_june", "bond_10y", "A", "per cent", "", "10-year bond yield (end-June before 1970, average after)"),
  s("business_rate_a", "08-money-credit-rates", "long_run_annual.csv", "year_ended_june", "business_rate", "A", "per cent", "", "Business overdraft rate"),
  s("cpi_inflation_a", "08-money-credit-rates", "long_run_annual.csv", "year_ended_june", "inflation", "A", "per cent", "", "CPI inflation, financial-year average on previous year"),
  s("real_short_rate_a", "08-money-credit-rates", "long_run_annual.csv", "year_ended_june", "real_short_rate", "A", "per cent", "", "Short rate less CPI inflation"),
  s("real_bond_10y_a", "08-money-credit-rates", "long_run_annual.csv", "year_ended_june", "real_bond_10y", "A", "per cent", "", "10-year bond yield less CPI inflation"),
  s("m3_growth_a", "08-money-credit-rates", "long_run_annual.csv", "year_ended_june", "m3_growth", "A", "per cent", "", "M3 growth, June to June"),
  s("credit_growth_a", "08-money-credit-rates", "long_run_annual.csv", "year_ended_june", "credit_growth", "A", "per cent", "", "Credit growth, June to June (break-adjusted)"),
  s("m3_pct_gdp_a", "08-money-credit-rates", "long_run_annual.csv", "year_ended_june", "m3_pct_gdp", "A", "per cent of GDP", "", "M3, end-June, / financial-year GDP"),
  s("credit_pct_gdp_a", "08-money-credit-rates", "long_run_annual.csv", "year_ended_june", "credit_pct_gdp", "A", "per cent of GDP", "", "Credit, end-June, / financial-year GDP"),
  s("nominal_gdp_a", "08-money-credit-rates", "long_run_annual.csv", "year_ended_june", "nominal_gdp_m", "A", "$ million", "", "Nominal GDP, financial year (ABS from 1959-60; OP8 scaled before)"),
  # 09, 10: labour market and wages
  s("unemployment_rate_m", "09-unemployment", "unemployment_rate_monthly.csv", "month", "unemployment_rate", "M", "per cent", "SA", "Unemployment rate (CES-based estimate to Jan 1978, ABS LFS after)"),
  s("unemployed_000_m", "09-unemployment", "unemployment_rate_monthly.csv", "month", "unemployed_000", "M", "'000", "SA", "Unemployed persons"),
  s("labour_force_000_m", "09-unemployment", "unemployment_rate_monthly.csv", "month", "labour_force_000", "M", "'000", "SA", "Labour force"),
  s("awe_male_a", "10-wages", "wages_annual.csv", "year_ended_june", "awe_male", "A", "$ a week", "", "Average weekly earnings, males (per employed male unit to 1980-81)"),
  s("awe_male_growth_a", "10-wages", "wages_annual.csv", "year_ended_june", "awe_growth", "A", "per cent", "", "Male AWE growth"),
  s("wage_rates_index_a", "10-wages", "wages_annual.csv", "year_ended_june", "wage_rates_index", "A", "index, 2024-25 = 100", "", "Wage rates: minimum award rates, award index, then WPI"),
  s("wage_rates_growth_a", "10-wages", "wages_annual.csv", "year_ended_june", "wage_rates_growth", "A", "per cent", "", "Wage rates growth"),
  s("real_awe_male_a", "10-wages", "wages_annual.csv", "year_ended_june", "real_awe_2025_dollars", "A", "$ a week, 2024-25 prices", "", "Real male AWE"),
  s("awe_male_q", "10-wages", "wages_quarterly.csv", "quarter_end", "awe_male_sa", "Q", "$ a week", "SA", "Male AWE, quarterly, benchmarked to the annual series (to Jun 2012)"),
  s("wage_growth_q", "10-wages", "wages_quarterly.csv", "quarter_end", "wage_growth_ye", "Q", "per cent", "SA", "Wage growth, year-ended: male AWE to Jun 1998, WPI after"),
  s("wpi_q", "10-wages", "wpi_quarterly.csv", "quarter_end", "wpi_sa", "Q", "index", "SA", "Wage Price Index"),
  # 11: housing finance
  s("housing_credit_a", "11-housing-finance", "housing_finance_annual.csv", "year_ended_june", "housing_credit_m", "A", "$ million", "", "Housing credit outstanding, end-June (savings banks + building societies, scaled, before 1977)"),
  s("housing_credit_pct_gdp_a", "11-housing-finance", "housing_finance_annual.csv", "year_ended_june", "housing_credit_pct_gdp", "A", "per cent of GDP", "", "Housing credit, end-June, / financial-year GDP"),
  s("housing_commitments_new_number_a", "11-housing-finance", "housing_finance_annual.csv", "year_ended_june", "commitments_new_dwellings_number", "A", "number", "", "Owner-occupier housing loan commitments for new dwellings"),
  s("housing_commitments_new_value_a", "11-housing-finance", "housing_finance_annual.csv", "year_ended_june", "commitments_new_dwellings_m", "A", "$ million", "", "Owner-occupier housing loan commitments for new dwellings, value"),
  s("housing_commitments_number_a", "11-housing-finance", "housing_finance_annual.csv", "year_ended_june", "commitments_all_number", "A", "number", "", "Owner-occupier housing loan commitments, new and established dwellings"),
  s("housing_commitments_value_a", "11-housing-finance", "housing_finance_annual.csv", "year_ended_june", "commitments_all_m", "A", "$ million", "", "Owner-occupier housing loan commitments, value"),
  s("average_housing_loan_a", "11-housing-finance", "housing_finance_annual.csv", "year_ended_june", "average_loan", "A", "$", "", "Average new owner-occupier housing loan"),
  s("housing_loan_to_earnings_a", "11-housing-finance", "housing_finance_annual.csv", "year_ended_june", "average_loan_years_of_male_earnings", "A", "years", "", "Average new housing loan / annual male AWE")
)
stopifnot(!any(duplicated(man$series_id)))

# normalise dates to YYYY-MM (last month of the period; mid-quarter month where noted)
to_month <- function(x, freq) {
  x <- as.character(x)
  if (freq == "A") return(sprintf("%s-06", substr(x, 1, 4)))
  substr(x, 1, 7)
}
long <- bind_rows(lapply(seq_len(nrow(man)), function(i) {
  m <- man[i, ]
  d <- read_csv(file.path(m$section, "output", m$file), col_types = cols(.default = "c"))
  stopifnot(m$date_col %in% names(d), m$column %in% names(d))
  tibble(series_id = m$series_id, date = to_month(d[[m$date_col]], m$frequency),
         value = suppressWarnings(as.numeric(d[[m$column]]))) |> filter(!is.na(value))
}))
stopifnot(!any(duplicated(long[c("series_id", "date")])))
cat_ <- man |> left_join(long |> group_by(series_id) |> summarise(first = min(date), last = max(date), n = n(), .groups = "drop"), by = "series_id") |>
  mutate(source_file = file.path(section, "output", file)) |> select(-file, -date_col)
dir.create("data", showWarnings = FALSE)
write_csv(long |> arrange(series_id, date), "data/aus_historic_series.csv")
write_csv(cat_ |> select(series_id, description, unit, adjustment, frequency, first, last, n, section, source_file, column), "data/series_catalogue.csv")
cat(sprintf("Combined file: %d series, %d observations, %s to %s\n", nrow(man), nrow(long), min(long$date), max(long$date)))
