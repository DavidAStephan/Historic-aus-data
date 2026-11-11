# Interest rates, money and credit, Australia, 1950 - 2026
# Run from 08-money-credit-rates/:  Rscript R/money_credit_rates.R
suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })

# ---- 0. Inputs ---------------------------------------------------------------------------
rba  <- read_csv("data-raw/rba_monthly.csv", show_col_types = FALSE)
anc  <- read_csv("data-raw/rba_credit_anchors.csv", show_col_types = FALSE)
op_m <- read_csv("data-raw/op8_3_1_money_june.csv", show_col_types = FALSE)
op_c <- read_csv("data-raw/op8_3_2_credit_june.csv", show_col_types = FALSE)
op_r <- read_csv("data-raw/op8_rates_annual.csv", col_types = cols(.default = "c")) |>
  mutate(across(-year_ended_june, ~ suppressWarnings(as.numeric(.x))), year_ended_june = as.integer(year_ended_june))
ar69 <- read_csv("data-raw/rba_ar1969_quarterly.csv", show_col_types = FALSE)
cpi  <- read_tsv("data-raw/rba_g1_cpi_quarterly.tsv", col_types = "cd")
gdp  <- read_tsv("../06-capex/data-raw/abs_gdp_ipd_quarterly.tsv", col_types = "cddd") |> select(quarter_end, gdp = gdp_cp_sa)

mi  <- function(p) { y <- as.integer(substr(p, 1, 4)); m <- as.integer(substr(p, 6, 7)); y * 12L + m - 1L }
lab <- function(i) sprintf("%d-%02d", i %/% 12L, i %% 12L + 1L)
fyend <- function(i) { y <- i %/% 12L; m <- i %% 12L + 1L; (y + (m >= 7)) }   # year ended June
rba <- rba |> mutate(t = mi(month)) |> arrange(t)

# ---- 1. Monthly interest rates (RBA tables F1.1, F2, F5) ---------------------------------
rates_m <- rba |> transmute(
  t,
  cash_rate = coalesce(FIRMMCRT, FIRMMCRI),          # target from Aug 1990, interbank rate before
  bill_90d = if_else(FIRMMBAB90 == 0, NA_real_, FIRMMBAB90),   # Nov 1969 is recorded as 0 (missing)
  bond_10y = FCMYGBAG10,
  housing_variable = FILRHLBVS,
  small_business_overdraft = FILRSBVOO,
  large_business_average = FILRLBWAV) |>
  mutate(short_rate = coalesce(cash_rate, bill_90d),
         short_rate_source = case_when(!is.na(cash_rate) & t >= mi("1990-08") ~ "Cash rate target",
                                       !is.na(cash_rate) ~ "Interbank overnight cash rate",
                                       !is.na(bill_90d) ~ "90-day bank bill", TRUE ~ NA_character_))
# CPI inflation (year-ended, quarterly, interpolated to months) for real rates
cpi <- cpi |> mutate(t = mi(quarter_end), infl_ye = 100 * (cpi / lag(cpi, 4) - 1))
rates_m$infl_ye <- approx(cpi$t, cpi$infl_ye, xout = rates_m$t, rule = 1)$y
rates_m <- rates_m |> mutate(real_short_rate = short_rate - infl_ye, real_bond_10y = bond_10y - infl_ye)

# ---- 2. Money and credit, monthly, break-adjusted ------------------------------------------
# The RBA's levels contain breaks (new reporters, reclassifications). Its growth rates (table D1)
# are adjusted for these, so break-adjusted levels are built by chaining the growth rates back
# from the latest published level.
chain_back <- function(t, g, anchor_t, anchor_v) {
  # g[i]: % growth from month t[i]-1 to t[i]; returns level at each t
  lv <- rep(NA_real_, length(t)); k <- which(t == anchor_t); lv[k] <- anchor_v
  for (i in seq(k, 2)) if (!is.na(g[i]) && !is.na(lv[i])) lv[i - 1] <- lv[i] / (1 + g[i] / 100)
  if (k < length(t)) for (i in (k + 1):length(t)) if (!is.na(g[i]) && !is.na(lv[i - 1])) lv[i] <- lv[i - 1] * (1 + g[i] / 100)
  lv
}
a <- function(id) anc$value[anc$series_id == id]
at <- function(id) mi(anc$month[anc$series_id == id])
# total credit: growth of credit excluding financial businesses from May 2003, total credit before
g_tot <- with(rba, coalesce(DGFACNFM, DGFACM))
g_bus <- with(rba, coalesce(DGFACBNFM, DGFACBM))
mc <- rba |> transmute(t,
  credit_total = chain_back(t, g_tot, at("DLCACFS"), a("DLCACFS")),
  credit_housing = chain_back(t, DGFACHM, at("DLCACOHS"), a("DLCACOHS") + a("DLCACIHS")),
  credit_personal = chain_back(t, DGFACOPM, at("DLCACOPS"), a("DLCACOPS")),
  credit_business = chain_back(t, g_bus, at("DLCACNFBS"), a("DLCACNFBS")),
  currency = DMACS,
  m3_level = coalesce(DMAM3S, DMAM3N), m3_g = DGFAM3M, bm_g = DGFABMM,
  broad_money = chain_back(t, DGFABMM, max(t[!is.na(DMABMS)]), DMABMS[t == max(t[!is.na(DMABMS)])]))
# M3: chain D1 growth back from the latest level to Aug 1976. The RBA level series has a break
# in Aug 1976 (new reporting, +14%) that D1 does not cover, so the earlier levels (SA from 1965,
# original before) are linked at Jul 1976, taking Jul-Aug 1976 growth as the average monthly
# growth of the following six months.
m3_last <- max(mc$t[!is.na(mc$m3_level)])
mc$m3 <- chain_back(mc$t, mc$m3_g, m3_last, mc$m3_level[mc$t == m3_last])
k76 <- mi("1976-07")
g6 <- mean(mc$m3_g[mc$t >= mi("1976-09") & mc$t <= mi("1977-02")])
m3_jul76 <- mc$m3[mc$t == k76 + 1L] / (1 + g6 / 100)
mc$m3[mc$t <= k76] <- mc$m3_level[mc$t <= k76] * m3_jul76 / mc$m3_level[mc$t == k76]
cat(sprintf("M3 break Aug 1976: RBA level +%.1f%% in the month; linked using %.2f%% a month\n",
            100 * (mc$m3_level[mc$t == k76 + 1L] / mc$m3_level[mc$t == k76] - 1), g6))
mc <- mc |> select(-m3_level, -m3_g, -bm_g)
# credit components should add to total over the period they are on the same basis
ck <- mc |> filter(t >= mi("2003-05")) |>
  mutate(r = (credit_housing + credit_personal + credit_business) / credit_total)
cat(sprintf("Credit components / total, 2003-2026: %.3f - %.3f\n", min(ck$r, na.rm = TRUE), max(ck$r, na.rm = TRUE)))

# ---- 3. Ratios to GDP (quarterly) ------------------------------------------------------
gdp <- gdp |> mutate(t = mi(quarter_end), gdp_4q = gdp + lag(gdp) + lag(gdp, 2) + lag(gdp, 3))
make_q <- function(mc) mc |> filter(t %% 3L == 2L) |> inner_join(gdp |> select(t, gdp_4q), by = "t") |>
  filter(!is.na(gdp_4q)) |>
  mutate(credit_pct_gdp = 100 * credit_total * 1000 / gdp_4q,     # $bn vs $m
         housing_credit_pct_gdp = 100 * credit_housing * 1000 / gdp_4q,
         business_credit_pct_gdp = 100 * credit_business * 1000 / gdp_4q,
         m3_pct_gdp = 100 * m3 * 1000 / gdp_4q,
         broad_money_pct_gdp = 100 * broad_money * 1000 / gdp_4q)
q <- make_q(mc)   # rebuilt in section 4b once monthly credit before Aug 1976 is filled in

# ---- 4. Long-run annual table, years ended June 1950 - 2026 ----------------------------------
fy_avg <- function(t, x) tibble(fy = fyend(t), x) |> group_by(fy) |> filter(n() == 12) |>
  summarise(v = mean(x, na.rm = FALSE), .groups = "drop")
jun <- function(t, x) tibble(fy = t %/% 12L, x, m = t %% 12L) |> filter(m == 5L) |> select(fy, v = x)
bond_fy <- fy_avg(rates_m$t, rates_m$bond_10y) |> filter(!is.na(v))
short_fy <- fy_avg(rates_m$t, rates_m$short_rate) |> filter(!is.na(v))
house_fy <- fy_avg(rates_m$t, rates_m$housing_variable) |> filter(!is.na(v))
sbo_fy <- fy_avg(rates_m$t, rates_m$small_business_overdraft) |> filter(!is.na(v))

# 10-year bond: before 1969-70 only end-June yields on tax-rebateable bonds are available.
# Non-rebateable bonds (issued from late 1968) yielded about 0.35-0.39 points more; the
# adjusted series adds the average of the three quarters printed on both (Dec 1968 - Jun 1969).
reb_spread <- mean(ar69$bond10_non_rebateable - ar69$bond10_rebateable, na.rm = TRUE)
cat(sprintf("Non-rebateable less rebateable 10-year yield, Dec 1968 - Jun 1969: %.2f points\n", reb_spread))
yrs <- 1950:2026
lr <- tibble(year_ended_june = yrs) |>
  left_join(op_r |> select(year_ended_june, bond10_end_june, bond10_fy_avg_op8 = bond10_fy_avg, dealers_june,
                           bill90_fy_avg_op8 = bill90_fy_avg, overdraft_max_june, overdraft_avg_june,
                           small_business_indicator_june), by = "year_ended_june") |>
  left_join(bond_fy |> rename(year_ended_june = fy, bond10_rba = v), by = "year_ended_june") |>
  left_join(short_fy |> rename(year_ended_june = fy, short_rba = v), by = "year_ended_june") |>
  left_join(house_fy |> rename(year_ended_june = fy, housing_rate = v), by = "year_ended_june") |>
  left_join(sbo_fy |> rename(year_ended_june = fy, sbo_rba = v), by = "year_ended_june") |>
  mutate(
    bond_10y = case_when(!is.na(bond10_rba) ~ bond10_rba,
                         !is.na(bond10_fy_avg_op8) ~ bond10_fy_avg_op8,
                         !is.na(bond10_end_june) ~ bond10_end_june + reb_spread),
    bond_10y_basis = case_when(!is.na(bond10_rba) ~ "Average of monthly (RBA F2)",
                               !is.na(bond10_fy_avg_op8) ~ "Financial-year average (RBA OP8)",
                               !is.na(bond10_end_june) ~ "End-June, rebateable bonds + 0.37 (RBA OP8, Annual Report 1969)"),
    short_rate = coalesce(short_rba, bill90_fy_avg_op8, dealers_june),
    short_rate_basis = case_when(!is.na(short_rba) & year_ended_june >= 1977 ~ "Cash rate, average of monthly (RBA F1.1)",
                                 !is.na(short_rba) ~ "90-day bank bill, average of monthly (RBA F1.1)",
                                 !is.na(bill90_fy_avg_op8) ~ "90-day bank bill, financial-year average (RBA OP8)",
                                 !is.na(dealers_june) ~ "Official money-market dealers' rate, end-June (RBA OP8)"),
    business_rate = coalesce(sbo_rba, overdraft_avg_june, overdraft_max_june),
    business_rate_basis = case_when(!is.na(sbo_rba) ~ "Small business overdraft indicator rate, average (RBA F5)",
                                    !is.na(overdraft_avg_june) ~ "Average trading bank overdraft rate, end-June (RBA OP8)",
                                    !is.na(overdraft_max_june) ~ "Maximum trading bank overdraft rate, end-June (RBA OP8)"))
# CPI inflation, financial year average over previous year
cpi_fy <- cpi |> mutate(fy = fyend(t)) |> group_by(fy) |> filter(n() == 4) |> summarise(c = mean(cpi)) |>
  mutate(inflation = 100 * (c / lag(c) - 1)) |> select(year_ended_june = fy, inflation)
# money and credit at end-June, $ million.
# From 1977 (credit) and 1960 (M3): the break-adjusted monthly series. Before that, OP8's annual
# growth rates (which the RBA adjusted for breaks) are chained back from those levels. OP8 has no
# credit growth for 1976-77 (a new collection began in Aug 1976), so June 1976 is estimated
# from Sep 1976 using the average monthly growth of the next nine months.
mc_jun <- mc |> filter(t %% 12L == 5L) |> transmute(year_ended_june = t %/% 12L, credit_total = credit_total * 1000,
                                                     m3 = m3 * 1000, broad_money = broad_money * 1000)
g9 <- rba |> filter(t >= mi("1976-10"), t <= mi("1977-06")) |> pull(DGFACM)
cr76 <- 1000 * mc$credit_total[mc$t == mi("1976-09")] / prod(1 + rep(mean(g9) / 100, 3))
lr <- lr |> left_join(cpi_fy, by = "year_ended_june") |> left_join(mc_jun, by = "year_ended_june") |>
  left_join(op_c |> select(year_ended_june = june, op_credit = total_credit, op_credit_g = total_credit_growth,
                           op_credit_gdp = total_credit_pct_gdp), by = "year_ended_june") |>
  left_join(op_m |> select(year_ended_june = june, op_m3 = m3, op_m3_g = m3_growth, op_m3_gdp = m3_pct_gdp), by = "year_ended_june") |>
  mutate(credit_total = if_else(year_ended_june < 1977, NA_real_, credit_total),
         credit_total = if_else(year_ended_june == 1976, cr76, credit_total),
         m3 = if_else(year_ended_june < 1960, NA_real_, m3))
back <- function(v, g, y, from) {           # chain annual growth g (in year y, % on previous June) back
  for (i in rev(which(y < from))) if (!is.na(g[i + 1]) && !is.na(v[i + 1])) v[i] <- v[i + 1] / (1 + g[i + 1] / 100)
  v
}
# OP8 credit growth is missing for 1953 (first year) and for 1962-63 is given; M3 growth for 1953 etc.
lr$op_credit_g[is.na(lr$op_credit_g) & lr$year_ended_june < 1976 & !is.na(lr$op_credit)] <- NA
lr$credit_total <- back(lr$credit_total, lr$op_credit_g, lr$year_ended_june, 1976)
lr$op_m3_g2 <- coalesce(lr$op_m3_g, 100 * (lr$op_m3 / lag(lr$op_m3) - 1))     # 1951-53 from levels
lr$m3 <- back(lr$m3, lr$op_m3_g2, lr$year_ended_june, 1960)
# nominal GDP for the year: ABS 5206.0 from 1959-60; before that GDP implied by OP8's ratios
# (level / per cent of GDP), scaled to ABS over 1960-1970 (OP8 used an older GDP vintage)
gdp_fy <- gdp |> filter(t %% 12L == 5L, !is.na(gdp_4q)) |> transmute(year_ended_june = t %/% 12L, gdp_abs = gdp_4q)
lr <- lr |> left_join(gdp_fy, by = "year_ended_june") |>
  mutate(gdp_op8 = coalesce(op_m3 / (op_m3_gdp / 100), op_credit / (op_credit_gdp / 100)))
kg <- with(lr |> filter(year_ended_june %in% 1960:1970), exp(mean(log(gdp_abs / gdp_op8))))
cat(sprintf("ABS / OP8-implied nominal GDP, 1960-70: %.3f\n", kg))
cat(sprintf("Credit, June 1976: estimated %.0f (break-adjusted) vs OP8 %.0f on the old basis (ratio %.3f)\n",
            cr76, lr$op_credit[lr$year_ended_june == 1976], cr76 / lr$op_credit[lr$year_ended_june == 1976]))
lr <- lr |> mutate(gdp = coalesce(gdp_abs, gdp_op8 * kg),
  credit_growth = 100 * (credit_total / lag(credit_total) - 1),
  m3_growth = 100 * (m3 / lag(m3) - 1),
  credit_pct_gdp = 100 * credit_total / gdp,
  m3_pct_gdp = 100 * m3 / gdp,
  real_short_rate = short_rate - inflation, real_bond_10y = bond_10y - inflation)

# checks: OP8 vs RBA monthly over the overlap
ov <- lr |> filter(!is.na(bond10_fy_avg_op8), !is.na(bond10_rba))
cat(sprintf("10-year bond, OP8 FY average vs RBA monthly average, %d years: max abs diff %.2f points\n",
            nrow(ov), max(abs(ov$bond10_fy_avg_op8 - ov$bond10_rba))))
ov <- lr |> filter(year_ended_june %in% 1979:1997)
cat(sprintf("Credit growth: ours vs OP8, 1979-97: mean abs diff %.1f points\n", mean(abs(ov$credit_growth - ov$op_credit_g))))
cat(sprintf("Credit/GDP: ours vs OP8, 1978-97: mean diff %.1f points (current GDP vintage is higher; current credit definition narrower)\n",
            mean((lr$credit_pct_gdp - lr$op_credit_gdp)[lr$year_ended_june %in% 1978:1997])))
ov2 <- lr |> filter(year_ended_june %in% 1961:1992)
cat(sprintf("M3 growth: ours vs OP8, 1961-92: mean abs diff %.1f points; M3/GDP mean diff %.1f points\n",
            mean(abs(ov2$m3_growth - ov2$op_m3_g), na.rm = TRUE), mean(ov2$m3_pct_gdp - ov2$op_m3_gdp)))

# ---- 4b. Bank lending, monthly 1957 - 1976, and monthly credit before Aug 1976 -------------
# Major trading banks' loans, advances and bills discounted (average of weekly figures for the
# month), transcribed from the CBCS/ABS banking bulletins (ANU Open Research scans). Every value
# records its issue and page. Where a month was printed in several issues, the latest is used.
bl <- read_csv("data-raw/anu_bank_loans_monthly.csv", col_types = "ccdcccc")
issue_date <- function(k) {                     # MBxxxx = December issue; MB1965n = Nov 1965
  y <- as.integer(substr(gsub("[^0-9]", "", k), 1, 4))
  m <- ifelse(grepl("-", k), suppressWarnings(as.integer(sub("^.*-([0-9]{2})[a-z]?$", "\\1", k))), 12L)
  m[k == "MB1965n"] <- 11L
  y * 12L + m - 1L
}
bl <- bl |> mutate(t = mi(month), d = issue_date(issue),
                   v = case_when(grepl("'000", unit) ~ value * 2 / 1000, !startsWith(unit, "$") ~ value * 2,
                                 TRUE ~ value))      # pounds to dollars at the 1966 rate ($2 = £1)
# consistency of repeated transcriptions (originals): different issues for the same month
dup <- bl |> filter(series == "mtb_loans") |> group_by(t) |> filter(n() > 1) |>
  summarise(range = max(v) - min(v), .groups = "drop")
cat(sprintf("Bank lending: %d months printed in more than one issue; %d differ by more than $1m (the Jul-Oct 1973 break)\n",
            nrow(dup), sum(dup$range > 1)))
latest <- function(s) bl |> filter(series == s, t >= mi("1957-01")) |> group_by(t) |> slice_max(d, n = 1, with_ties = FALSE) |>
  ungroup() |> select(t, v, issue = issue, d)
lo <- latest("mtb_loans"); ls <- latest("mtb_loans_sa")
stopifnot(all(diff(lo$t) == 1L))                # complete Jan 1957 - Dec 1976 (Decembers 1947-56 kept in data-raw only)
# Break in July 1973 (change in definition, BS Mar 1975 Table 23 note (b)). Jul-Oct 1973 were
# printed on both bases (BS Oct 1973 old, BS Oct 1974 / Mar 1975 new); earlier months are scaled
# by the average new/old ratio.
old73 <- bl |> filter(series == "mtb_loans", issue == "BS1973-10", t >= mi("1973-07"))
k73 <- exp(mean(log(lo$v[match(old73$t, lo$t)] / old73$v)))
cat(sprintf("Trading bank lending break, Jul 1973: new/old basis %.4f (Jul-Oct 1973)\n", k73))
bank <- lo |> transmute(t, mtb_orig_printed = v, issue,
                        mtb_orig = if_else(t < mi("1973-07"), v * k73, v)) |>
  left_join(ls |> transmute(t, sa_printed = v, sa_issue = issue), by = "t")
# seasonal factors from the bulletins (original / seasonally adjusted, same issue as far as
# possible); 1957-59, before the printed adjusted series, use the 1960-64 average for the month
bank <- bank |> mutate(sf = mtb_orig_printed / sa_printed, mo = t %% 12L)
sf0 <- bank |> filter(t >= mi("1960-01"), t <= mi("1964-12")) |> group_by(mo) |> summarise(sf0 = mean(sf))
bank <- bank |> left_join(sf0, by = "mo") |>
  mutate(sf = coalesce(sf, sf0), mtb_sa = mtb_orig / sf,
         sa_method = if_else(is.na(sa_printed), "1960-64 average bulletin factor", "Bulletin factor (X-11)")) |>
  select(-sf0, -mo)
# compare with the RBA's lending by all banks (D2) where they overlap
d2 <- read_csv("data-raw/rba_d2_bank_loans_1976_81.csv", show_col_types = FALSE) |> mutate(t = mi(month))
ov3 <- bank |> inner_join(d2, by = "t")
cat(sprintf("Major trading banks / RBA lending by all banks (DLCALAB), Sep-Dec 1976: %.3f - %.3f\n",
            min(ov3$mtb_orig / (1000 * ov3$DLCALAB)), max(ov3$mtb_orig / (1000 * ov3$DLCALAB))))
# Monthly total credit, Jun 1957 - Aug 1976: the end-June totals above (OP8 growth chained back)
# and Sep 1976 (the first month of the RBA series), interpolated by proportional Denton (first differences) on seasonally
# adjusted trading bank lending. For stock benchmarks this interpolates the credit / bank lending
# ratio linearly between benchmark months.
bm <- bind_rows(lr |> filter(year_ended_june %in% 1957:1976) |> transmute(t = mi(sprintf("%d-06", year_ended_june)), b = credit_total),
                mc |> filter(t == min(t[!is.na(credit_total)])) |> transmute(t, b = credit_total * 1000)) |>
  inner_join(bank |> select(t, mtb_sa), by = "t") |> mutate(r = b / mtb_sa)
bank <- bank |> mutate(credit_total = if_else(t >= min(bm$t) & t <= max(bm$t),
                                              approx(bm$t, bm$r, xout = t)$y * mtb_sa, NA_real_))
# fill the monthly credit series and rebuild the quarterly shares of GDP
fill <- bank |> filter(t < max(bm$t), !is.na(credit_total)) |> select(t, cr_fill = credit_total)
mc <- mc |> left_join(fill, by = "t") |> mutate(credit_total = coalesce(credit_total, cr_fill / 1000)) |> select(-cr_fill)
q <- make_q(mc)
# how well does trading bank lending track total credit, June to June?
gchk <- bank |> filter(t %% 12L == 5L) |> transmute(year_ended_june = t %/% 12L, g_bank = 100 * (mtb_sa / lag(mtb_sa) - 1)) |>
  inner_join(lr |> select(year_ended_june, credit_growth), by = "year_ended_june") |> filter(!is.na(g_bank), !is.na(credit_growth))
cat(sprintf("Trading bank lending vs total credit growth, years to June %d-%d: correlation %.2f; mean %.1f vs %.1f per cent\n",
            min(gchk$year_ended_june), max(gchk$year_ended_june), cor(gchk$g_bank, gchk$credit_growth),
            mean(gchk$g_bank), mean(gchk$credit_growth)))

# ---- 4c. Break-even inflation and inflation expectations, 1985 - 2026 ----------------------
# The RBA's current files show only part of this history: table G3 has break-even inflation from
# 2015 and consumer expectations from 2022 only, and F2's indexed bond yield is missing Jun 2013
# - Oct 2014. The history is rebuilt from the RBA's historical F2 file (1986 - May 2013), copies
# of f02hist.xls and g03hist.xls archived by the Internet Archive (2015 - 2023), and the current
# files. data-raw records the file each value came from.
ib <- read_csv("data-raw/rba_f2_indexed_bond_monthly.csv", show_col_types = FALSE) |> mutate(t = mi(month))
g3 <- read_csv("data-raw/rba_g3_inflation_expectations.csv", show_col_types = FALSE) |> mutate(t = mi(quarter_end_month))
gs <- function(id) g3 |> filter(series_id == id) |> select(t, value)
rbe <- gs("GBONYLD") |> rename(rbe = value)          # RBA break-even, end-quarter month
# Monthly break-even = 10-year nominal less indexed bond yield (the RBA's definition). The F2
# indexed series changed in Nov 2014 (the old series is 0.3-0.5 points higher where they overlap),
# and the RBA revised its quarterly history in 2016. So the monthly differences are benchmarked
# to the RBA's quarterly series: the gap at each quarter-end month is interpolated linearly
# across the months between.
be <- ib |> transmute(t, bond_10y, indexed = if_else(t >= mi("2014-11"), indexed_bond_new, indexed_bond_old),
                      indexed_basis = if_else(t >= mi("2014-11"), "new", "old"), be_raw = bond_10y - indexed) |>
  full_join(rbe, by = "t") |> arrange(t)
# (interpolated within each indexed series, so no gap is spread across the Nov 2014 change)
kq <- !is.na(be$rbe) & !is.na(be$be_raw)
be$adj <- NA_real_
for (b in c("old", "new")) {
  k <- which(be$indexed_basis == b)
  kk <- k[kq[k]]
  be$adj[k] <- approx(be$t[kk], (be$rbe - be$be_raw)[kk], xout = be$t[k], rule = 2)$y
}
be <- be |> mutate(breakeven_10y = coalesce(be_raw + adj, rbe),
                   be_source = case_when(!is.na(be_raw) ~ "Monthly F2 yields, benchmarked to RBA quarterly G3",
                                         !is.na(rbe) ~ "RBA G3 quarterly only"),
                   real_bond_10y_indexed = bond_10y - breakeven_10y)
ckq <- be |> filter(kq)
cat(sprintf("Break-even: RBA quarterly %s - %s (%d of %d quarters); monthly F2 from %s\n",
            lab(min(rbe$t)), lab(max(rbe$t)), nrow(rbe), (max(rbe$t) - min(rbe$t)) / 3 + 1, lab(min(ib$t))))
cat(sprintf("Monthly nominal less indexed vs RBA quarterly break-even, mean abs gap: old indexed series %.2f, new series (Nov 2014 -) %.2f points\n",
            mean(abs(ckq$adj[ckq$indexed_basis == "old"])), mean(abs(ckq$adj[ckq$indexed_basis == "new"]))))
# quarterly expectations table (end-quarter months)
ie <- tibble(t = seq(mi("1985-12"), max(g3$t), by = 3L)) |>
  left_join(be |> select(t, breakeven_10y, real_bond_10y_indexed), by = "t") |>
  left_join(gs("GCONEXP") |> rename(consumer_1y = value), by = "t") |>
  left_join(gs("GBUSEXP") |> rename(business_3m_annualised = value), by = "t") |>
  left_join(gs("GMAREXPY") |> rename(market_economists_1y = value), by = "t") |>
  left_join(gs("GMAREXPYY") |> rename(market_economists_2y = value), by = "t") |>
  left_join(gs("GUNIEXPY") |> rename(union_officials_1y = value), by = "t") |>
  left_join(gs("GUNIEXPYY") |> rename(union_officials_2y = value), by = "t") |>
  left_join(cpi |> select(t, cpi_inflation_ye = infl_ye), by = "t")
# annual: break-even and the real 10-year yield it implies (ex ante), years ended June
be_fy <- fy_avg(be$t[!is.na(be$be_raw)], be$breakeven_10y[!is.na(be$be_raw)]) |> rename(year_ended_june = fy, breakeven_10y = v)
lr <- lr |> left_join(be_fy, by = "year_ended_june") |> mutate(real_bond_10y_exante = bond_10y - breakeven_10y)
ov4 <- lr |> filter(!is.na(breakeven_10y))
cat(sprintf("Years to June %d-%d: break-even averages %.1f%%, CPI inflation %.1f%%; ex-ante real bond %.1f%% vs ex-post %.1f%%\n",
            min(ov4$year_ended_june), max(ov4$year_ended_june), mean(ov4$breakeven_10y), mean(ov4$inflation),
            mean(ov4$real_bond_10y_exante), mean(ov4$real_bond_10y)))

# ---- 5. Outputs --------------------------------------------------------------------------
dir.create("output", showWarnings = FALSE)
r2 <- function(x) round(x, 2)
write_csv(rates_m |> filter(t >= mi("1959-01")) |>
            transmute(month = lab(t), cash_rate, bill_90d, bond_10y, housing_variable, small_business_overdraft,
                      large_business_average, short_rate, short_rate_source, cpi_inflation_ye = r2(infl_ye),
                      real_short_rate = r2(real_short_rate), real_bond_10y = r2(real_bond_10y)),
          "output/interest_rates_monthly.csv", na = "")
write_csv(mc |> filter(t >= mi("1959-07")) |>
            transmute(month = lab(t), currency_bn = round(currency, 2), m3_bn = round(m3, 2),
                      broad_money_bn = round(broad_money, 2), credit_total_bn = round(credit_total, 2),
                      credit_housing_bn = round(credit_housing, 2), credit_personal_bn = round(credit_personal, 2),
                      credit_business_bn = round(credit_business, 2)),
          "output/money_credit_monthly.csv", na = "")
write_csv(q |> transmute(quarter = lab(t), credit_pct_gdp = round(credit_pct_gdp, 1),
                         housing_credit_pct_gdp = round(housing_credit_pct_gdp, 1),
                         business_credit_pct_gdp = round(business_credit_pct_gdp, 1),
                         m3_pct_gdp = round(m3_pct_gdp, 1), broad_money_pct_gdp = round(broad_money_pct_gdp, 1)),
          "output/money_credit_pct_gdp_quarterly.csv", na = "")
write_csv(lr |> transmute(year_ended_june, short_rate = r2(short_rate), short_rate_basis, bond_10y = r2(bond_10y),
                          bond_10y_basis, housing_rate = r2(housing_rate), business_rate = r2(business_rate),
                          business_rate_basis, inflation = r2(inflation), real_short_rate = r2(real_short_rate),
                          real_bond_10y = r2(real_bond_10y), breakeven_10y = r2(breakeven_10y),
                          real_bond_10y_exante = r2(real_bond_10y_exante), m3_growth = round(m3_growth, 1),
                          credit_growth = round(credit_growth, 1), m3_pct_gdp = round(m3_pct_gdp, 1),
                          credit_pct_gdp = round(credit_pct_gdp, 1), m3_m = round(m3), credit_total_m = round(credit_total),
                          nominal_gdp_m = round(gdp)),
          "output/long_run_annual.csv", na = "")
write_csv(ar69 |> select(-source) |> mutate(spread = bond10_non_rebateable - bond10_rebateable),
          "output/bond_10y_quarterly_1966_69.csv", na = "")
write_csv(be |> filter(!is.na(breakeven_10y)) |>
            transmute(month = lab(t), bond_10y, indexed_bond_yield = indexed, indexed_series = indexed_basis,
                      nominal_less_indexed = round(be_raw, 3), rba_breakeven_quarterly = rbe,
                      breakeven_10y = round(breakeven_10y, 2), real_bond_10y_indexed = round(real_bond_10y_indexed, 2),
                      source = be_source),
          "output/breakeven_inflation_monthly.csv", na = "")
write_csv(ie |> transmute(quarter = lab(t), breakeven_10y = round(breakeven_10y, 2),
                          real_bond_10y_indexed = round(real_bond_10y_indexed, 2), consumer_1y = round(consumer_1y, 2),
                          business_3m_annualised, market_economists_1y, market_economists_2y,
                          union_officials_1y, union_officials_2y, cpi_inflation_ye = round(cpi_inflation_ye, 2)),
          "output/inflation_expectations_quarterly.csv", na = "")
write_csv(bank |> transmute(month = lab(t), trading_bank_lending_m = round(mtb_orig, 1),
                            trading_bank_lending_sa_m = round(mtb_sa, 1), sa_method,
                            trading_bank_lending_as_printed_m = round(mtb_orig_printed, 1), source_issue = issue,
                            credit_total_interpolated_m = round(credit_total)),
          "output/bank_lending_monthly_1957_76.csv", na = "")

# ---- 6. Charts ---------------------------------------------------------------------------
pal <- c("#1f4e79", "#c0504d", "#7f7f7f", "#4f9a3f", "#d79b00")
th <- theme_minimal(base_size = 11) + theme(legend.position = "bottom", panel.grid.minor = element_blank(),
                                            plot.title.position = "plot")
dt <- function(i) as.Date(sprintf("%d-%02d-15", i %/% 12L, i %% 12L + 1L))
fyd <- function(y) as.Date(sprintf("%d-06-30", y))
# nominal rates: annual before monthly data, monthly after
S <- c("10-year government bond", "Short-term rate", "Housing loan (bank variable)", "Business overdraft")
ann <- bind_rows(
  lr |> filter(year_ended_june < 1970, !is.na(bond_10y)) |> transmute(d = fyd(year_ended_june), v = bond_10y, s = S[1]),
  lr |> filter(year_ended_june < 1970, !is.na(short_rate)) |> transmute(d = fyd(year_ended_june), v = short_rate, s = S[2]),
  lr |> filter(year_ended_june < 1977, !is.na(business_rate)) |> transmute(d = fyd(year_ended_june), v = business_rate, s = S[4]))
mon <- bind_rows(
  rates_m |> filter(!is.na(bond_10y)) |> transmute(d = dt(t), v = bond_10y, s = S[1]),
  rates_m |> filter(!is.na(short_rate)) |> transmute(d = dt(t), v = short_rate, s = S[2]),
  rates_m |> filter(!is.na(housing_variable)) |> transmute(d = dt(t), v = housing_variable, s = S[3]),
  rates_m |> filter(!is.na(small_business_overdraft)) |> transmute(d = dt(t), v = small_business_overdraft, s = S[4]))
mon$s <- factor(mon$s, S); ann$s <- factor(ann$s, S)
p1 <- ggplot(mapping = aes(d, v, colour = s)) +
  geom_line(data = mon, linewidth = 0.45) + geom_point(data = ann, size = 1) +
  geom_line(data = ann, linewidth = 0.3, linetype = "22") +
  scale_colour_manual(values = pal[c(1, 2, 4, 5)], name = NULL, drop = FALSE) +
  guides(colour = guide_legend(nrow = 2)) +
  labs(title = "Australian interest rates, 1950 - 2026 (per cent)",
       subtitle = paste0("Lines are monthly; dots are end-June or financial-year values before monthly data start.\n",
                         "Short rate: money-market dealers' rate to 1969, 90-day bank bill to Apr 1976, cash rate after.\n",
                         "Bonds before 1969: tax-rebateable yields plus 0.37 points. Overdraft: average rate to 1976, small-business indicator after."),
       x = NULL, y = NULL, caption = "Sources: RBA F1.1, F2, F5; RBA Occasional Paper 8; RBA Annual Report 1969") + th
ggsave("output/interest_rates.png", p1, width = 9, height = 5.2, dpi = 150, bg = "white")

rr <- bind_rows(lr |> transmute(y = year_ended_june, v = real_short_rate, s = "Short-term rate less inflation"),
                lr |> transmute(y = year_ended_june, v = real_bond_10y, s = "10-year bond yield less inflation")) |>
  filter(!is.na(v))
p2 <- ggplot(rr, aes(fyd(y), v, colour = s)) + geom_hline(yintercept = 0, colour = "grey50") +
  geom_line(linewidth = 0.6) + scale_colour_manual(values = pal[c(1, 4)], name = NULL) +
  labs(title = "Real interest rates, years ended June 1950 - 2026 (per cent)",
       subtitle = "Nominal rate (financial-year average, or end-June before 1970) less CPI inflation over the year",
       x = NULL, y = NULL) + th
ggsave("output/real_interest_rates.png", p2, width = 9, height = 5, dpi = 150, bg = "white")

cg <- bind_rows(
  lr |> filter(year_ended_june < 1960) |> transmute(d = fyd(year_ended_june), v = credit_pct_gdp, s = "Credit (OP8 linked, end-June)"),
  q |> transmute(d = dt(t), v = credit_pct_gdp, s = "Credit (break-adjusted, quarterly)"),
  lr |> filter(year_ended_june < 1960) |> transmute(d = fyd(year_ended_june), v = m3_pct_gdp, s = "M3 (OP8 linked, end-June)"),
  q |> transmute(d = dt(t), v = m3_pct_gdp, s = "M3 (quarterly)")) |> filter(!is.na(v)) |>
  mutate(g = if_else(grepl("^Credit", s), "Credit", "M3"))
p3 <- ggplot(cg, aes(d, v, colour = g, linetype = grepl("OP8", s))) + geom_line(linewidth = 0.6) +
  scale_colour_manual(values = pal[c(2, 1)], name = NULL) + scale_linetype_manual(values = c(1, 2), guide = "none") +
  labs(title = "Credit and money (M3) as a share of GDP, 1950 - 2026 (per cent)",
       subtitle = paste0("End-of-period stock over the year's nominal GDP. Dashed: end-June, linked from RBA Occasional Paper 8;\n",
                         "solid: quarterly, break-adjusted (RBA D1-D3, ABS 5206.0); credit before Sep 1976 interpolated on trading bank lending"),
       x = NULL, y = NULL) + th
ggsave("output/credit_money_gdp.png", p3, width = 9, height = 5, dpi = 150, bg = "white")

# year-ended growth: trading bank lending (1958-76) and total credit (monthly)
yy <- function(x) 100 * (x / lag(x, 12) - 1)
gr <- bind_rows(
  bank |> transmute(t, v = yy(mtb_sa), s = "Major trading banks' lending (bulletins, 1957-76)"),
  mc |> transmute(t, v = yy(credit_total), s = "Total credit (interpolated to Aug 1976, RBA after)")) |>
  filter(!is.na(v), t <= mi("1990-12"))
p4 <- ggplot(gr, aes(dt(t), v, colour = s)) + geom_hline(yintercept = 0, colour = "grey50") +
  geom_line(linewidth = 0.5) + scale_colour_manual(values = pal[c(2, 1)], name = NULL) +
  labs(title = "Bank lending and credit growth, 1958 - 1990 (per cent, year-ended, monthly)",
       subtitle = "Trading bank loans, advances and bills discounted, seasonally adjusted, break-adjusted at Jul 1973",
       x = NULL, y = NULL, caption = "Sources: CBCS/ABS banking bulletins (ANU Open Research); RBA D1, OP8") + th
ggsave("output/bank_lending_growth.png", p4, width = 9, height = 5, dpi = 150, bg = "white")

# inflation expectations: break-even (monthly) and survey measures (quarterly), with CPI inflation
ex <- bind_rows(
  be |> filter(!is.na(breakeven_10y)) |> transmute(t, v = breakeven_10y, s = "10-year bond break-even"),
  ie |> transmute(t, v = market_economists_1y, s = "Market economists, 1 year ahead"),
  ie |> transmute(t, v = consumer_1y, s = "Consumers, 1 year ahead"),
  ie |> transmute(t, v = business_3m_annualised, s = "Businesses, 3 months ahead (annualised)"),
  cpi |> filter(t >= mi("1985-12")) |> transmute(t, v = infl_ye, s = "CPI inflation, year-ended")) |> filter(!is.na(v))
ex$s <- factor(ex$s, unique(ex$s))
p5 <- ggplot(ex, aes(dt(t), v, colour = s, linewidth = s)) + geom_hline(yintercept = c(2, 3), colour = "grey80") +
  geom_line() + scale_colour_manual(values = c(pal[1], pal[4], pal[5], "#9467bd", pal[3]), name = NULL) +
  scale_linewidth_manual(values = c(0.6, 0.45, 0.45, 0.35, 0.35), name = NULL) +
  guides(colour = guide_legend(nrow = 2), linewidth = guide_legend(nrow = 2)) +
  labs(title = "Inflation expectations in Australia, 1985 - 2026 (per cent)",
       subtitle = paste0("Break-even: 10-year nominal less indexed bond yield, monthly from Jul 1986, quarterly before.\n",
                         "Rebuilt from RBA F2 and G3 files, including copies archived 2015-2023. Grey lines: the 2-3 per cent target."),
       x = NULL, y = NULL, caption = "Sources: RBA F2, G3 (NAB, Melbourne Institute, RBA survey), G1; Internet Archive") + th
ggsave("output/inflation_expectations.png", p5, width = 9, height = 5.2, dpi = 150, bg = "white")
cat("Done.\n")
