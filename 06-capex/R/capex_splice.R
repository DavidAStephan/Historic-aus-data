# Private new capital expenditure, Australia, quarterly 1961-2026 (spliced),
# and businesses' investment expectations vs what they actually spent, 1961-2026
# -------------------------------------------------------------------------------
# Run from this analysis folder (the folder that contains R/), e.g.  Rscript R/capex_splice.R
#
# Inputs (data-raw/)
#   cx_raw.tsv  Quarterly actual expenditure transcribed from the CBCS/ABS capex
#       bulletins (ANU Open Research scans), one row per issue x quarter: total,
#       buildings & structures (bs), equipment, plant & machinery (epm),
#       manufacturing, non-manufacturing, mining; original series. Pre-1966 issues in
#       pounds (GBP_m, converted at the decimal-currency rate $2 = GBP 1).
#       Three bases, recorded in the note column:
#         old         "private businesses subject to pay-roll tax, excluding rural
#                     industries" (Jun qtr 1961 - Sep qtr 1974)
#         integrated  integrated with the economic censuses (Dec qtr 1973 - Sep qtr 1978)
#         selected    "new fixed capital expenditure by private enterprises in
#                     selected industries" (Mar qtr 1978 - Mar qtr 1992)
#   sa_printed.tsv  seasonally adjusted totals printed in the bulletins (for checking)
#   abs_capex_quarterly.csv  ABS 5625.0 (June 2026), Australia, Jun qtr 1987 - Jun qtr
#       2026: original by asset x (all industries, mining, manufacturing, non-mining),
#       and seasonally adjusted totals by asset
#   abs_capex_fy_expectations.csv  ABS 5625.0 Table 17: the seven successive estimates
#       for each financial year (E1 = 12-month expectation reported in Jan-Feb of the
#       previous financial year ... E7 = actual), 1987-88 to 2026-27
#   cx_fy_expect_raw.tsv  the same seven-estimate table as printed in the Jun 1986 and
#       Jun 1990 bulletins (FY 1980-81 to 1990-91, selected industries)
#   cx_anticipated_pct.tsv  half-yearly anticipated vs actual % change (on the previous
#       half), Jul-Dec 1961 to Jan-Jun 1969 (Jun 1965 and Jun 1969 bulletins)
#   cx_half_antic.tsv  half-yearly anticipated and actual levels, 1969-1977
#   cx_expect_raw.tsv  other expectations printed in the bulletins (next quarter or
#       next six months), 1978-1990
#   abs_short_term_expected_half.tsv  ABS 5625.0 Table 2: short-term expected
#       expenditure reported in June and December surveys (= the next six months)
#   abs_gdp_ipd_quarterly.tsv  ABS 5206.0 (June 2026): nominal GDP (SA) and implicit
#       price deflators for private non-dwelling construction and machinery & equipment
# Outputs (output/)
#   capex_spliced_quarterly.csv, capex_realisation_ratios.csv, capex_fy_expectations.csv
#   capex_spliced.png, capex_share_gdp.png, capex_expectations.png, capex_splice_check.png
#
# Method
#   1. Each basis: keep the latest issue that printed each quarter (later issues carry
#      revisions; a final issue beats a preliminary one of the same date).
#   2. Links, each the geometric mean of same-quarter ratios of original figures, done
#      separately for total, bs, epm, mining and manufacturing:
#        old -> integrated   Dec qtr 1973 - Sep qtr 1974 (4 quarters)
#        integrated -> selected  Mar - Sep qtr 1978 (3 quarters)
#        selected -> ABS 5625.0   Jun qtr 1987 - Mar qtr 1992 (20 quarters)
#   3. Spliced original = ABS from Jun qtr 1987; earlier quarters = bulletin x links.
#   4. Seasonal adjustment: ABS published SA (total, bs, epm) from Jun qtr 1987; before
#      that STL on logs (robust, seasonal window 7) on the full spliced series.
#      Checked against the SA figures printed in the bulletins (quarterly % changes).
#   5. Real: bs deflated by the private non-dwelling construction deflator, epm by the
#      machinery & equipment deflator (2023-24 prices); total real = sum.
#   6. Expectations: realisation ratio = actual / what businesses expected beforehand.
#      Financial-year ratios use the seven-estimate tables (bulletins to 1987-88, ABS
#      from 1988-89). Half-year ratios use the next-six-months expectation reported at
#      the start of the half (bulletins 1961-1990; ABS from 1987).

suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })
dir.create("output", showWarnings = FALSE)
md <- function(s) as.Date(paste0(s, "-01"))
gmean <- function(x) exp(mean(log(x)))

# ---- 1. Bulletin quarters -----------------------------------------------------------
raw <- read_tsv("data-raw/cx_raw.tsv", col_types = cols(.default = "c")) |>
  mutate(across(c(total, bs, epm, manufacturing, mining), as.numeric),
         fx = if_else(unit == "GBP_m", 2, 1),
         across(c(total, bs, epm, manufacturing, mining), ~ .x * fx),
         basis = case_when(grepl("basis=selected", note) ~ "selected",
                           grepl("basis=integrated", note) ~ "integrated",
                           TRUE ~ "old"),
         q = md(quarter),
         issue_date = md(substr(issue_key, 3, 9)),
         final = grepl("f[0-9]+$", issue_key))

latest <- raw |>
  group_by(basis, q) |>
  arrange(desc(issue_date), desc(final), .by_group = TRUE) |>
  slice(1) |> ungroup() |>
  select(basis, q, total, bs, epm, manufacturing, mining, issue_key, note)
revs <- raw |> group_by(basis, q) |> filter(n_distinct(round(total, 1)) > 1) |> ungroup()
cat("Quarters revised between issues:", n_distinct(paste(revs$basis, revs$q)), "\n")
for (b in c("old", "integrated", "selected")) {
  d <- filter(latest, basis == b)
  stopifnot(all(diff(sort(d$q)) %in% 89:92))
  cat(sprintf("%-10s %s - %s (%d quarters)\n", b, format(min(d$q), "%b %Y"), format(max(d$q), "%b %Y"), nrow(d)))
}

abs <- read_csv("data-raw/abs_capex_quarterly.csv", col_types = cols(.default = "d", quarter = "c")) |>
  mutate(q = as.Date(sprintf("%s-%s-01", substr(quarter, 1, 4), substr(quarter, 5, 6)))) |>
  transmute(q, total = o_tot_all, bs = o_bs_all, epm = o_epm_all,
            mining = o_tot_min, manufacturing = o_tot_man,
            total_sa = sa_tot_all, bs_sa = sa_bs_all, epm_sa = sa_epm_all)

# ---- 2. Links -----------------------------------------------------------------------------
vars <- c("total", "bs", "epm", "mining", "manufacturing")
link <- function(from, to, label) {
  j <- inner_join(from, to, by = "q", suffix = c(".f", ".t"))
  out <- lapply(vars, function(v) {
    r <- j[[paste0(v, ".t")]] / j[[paste0(v, ".f")]]
    r <- r[is.finite(r)]
    tibble(link = label, var = v, n = length(r), factor = gmean(r), lo = min(r), hi = max(r))
  })
  bind_rows(out)
}
old <- filter(latest, basis == "old"); intg <- filter(latest, basis == "integrated")
sel <- filter(latest, basis == "selected")
L <- bind_rows(link(old, intg, "old -> integrated"),
               link(intg, sel, "integrated -> selected"),
               link(sel, abs, "selected -> ABS 5625.0"))
cat("\nLink factors (geometric mean of same-quarter ratios, original series):\n")
print(mutate(L, across(c(factor, lo, hi), ~ round(.x, 3))), n = Inf)
k <- function(lbl, v) L$factor[L$link == lbl & L$var == v]

scale_seg <- function(d, links) {
  for (v in vars) {
    f <- prod(sapply(links, k, v = v))
    d[[v]] <- d[[v]] * f
  }
  d
}

# ---- 3. Splice ------------------------------------------------------------------------------
abs_start <- min(abs$q); sel_start <- min(sel$q); int_start <- min(intg$q)
spl <- bind_rows(
  scale_seg(filter(old, q < int_start), c("old -> integrated", "integrated -> selected", "selected -> ABS 5625.0")) |>
    mutate(source = "Bulletins: pay-roll-tax businesses (scaled)"),
  scale_seg(filter(intg, q < sel_start), c("integrated -> selected", "selected -> ABS 5625.0")) |>
    mutate(source = "Bulletins: integrated series (scaled)"),
  scale_seg(filter(sel, q < abs_start), "selected -> ABS 5625.0") |>
    mutate(source = "Bulletins: selected industries (scaled)"),
  mutate(abs, source = "ABS 5625.0")
) |> arrange(q) |>
  select(q, all_of(vars), total_sa_abs = total_sa, bs_sa_abs = bs_sa, epm_sa_abs = epm_sa, source, issue_key)
stopifnot(!any(duplicated(spl$q)), all(diff(spl$q) %in% 89:92))

# ---- 4. Seasonal adjustment -----------------------------------------------------------------
stl_q <- function(x, q) {
  ok <- !is.na(x); y <- ts(log(x[ok]), start = c(as.integer(format(q[ok][1], "%Y")), as.integer(format(q[ok][1], "%m")) / 3), frequency = 4)
  f <- stl(y, s.window = 7, robust = TRUE)
  out <- rep(NA_real_, length(x)); out[ok] <- exp(y - f$time.series[, "seasonal"]); out
}
for (v in vars) spl[[paste0(v, "_sa_stl")]] <- stl_q(spl[[v]], spl$q)
spl <- spl |>
  mutate(total_sa = coalesce(total_sa_abs, total_sa_stl),
         bs_sa = coalesce(bs_sa_abs, bs_sa_stl),
         epm_sa = coalesce(epm_sa_abs, epm_sa_stl),
         mining_sa = mining_sa_stl, manufacturing_sa = manufacturing_sa_stl,
         sa_method = if_else(q >= abs_start, "ABS published (total, bs, epm)", "STL (this study)"))

# Check against bulletin-printed SA: compare quarterly % changes (scale-free)
sap <- read_tsv("data-raw/sa_printed.tsv", col_types = "ccc ddd" |> gsub(pattern = " ", replacement = "")) |>
  mutate(q = md(quarter), issue_date = md(substr(issue_key, 3, 9))) |>
  filter(!is.na(total_sa)) |>
  group_by(q) |> slice_max(issue_date, n = 1, with_ties = FALSE) |> ungroup() |>
  arrange(q) |> mutate(g_printed = 100 * (total_sa / lag(total_sa) - 1),
                       same_issue = issue_key == lag(issue_key)) |>
  filter(same_issue)
chk <- inner_join(sap, select(spl, q, total_sa_stl), by = "q") |>
  left_join(transmute(spl, q, prev = lag(total_sa_stl)), by = "q") |>
  mutate(g_stl = 100 * (total_sa_stl / prev - 1), diff = g_stl - g_printed)
cat(sprintf("\nSTL vs bulletin-printed SA, quarterly growth (%d quarters, %s-%s): mean abs difference %.1f pp; correlation %.2f\n",
            nrow(chk), format(min(chk$q), "%Y"), format(max(chk$q), "%Y"),
            mean(abs(chk$diff)), cor(chk$g_stl, chk$g_printed)))
seam <- filter(spl, q %in% c(abs_start - 92, abs_start)) |> select(q, total_sa_stl, total_sa_abs)
cat("Seam at Jun qtr 1987:\n"); print(seam)

# ---- 5. Real and share of GDP ---------------------------------------------------------------
na <- read_tsv("data-raw/abs_gdp_ipd_quarterly.tsv", col_types = "cddd") |> mutate(q = md(quarter_end))
spl <- left_join(spl, select(na, q, gdp_cp_sa, ipd_nondwelling_construction, ipd_machinery_equipment), by = "q") |>
  mutate(bs_real = bs_sa / ipd_nondwelling_construction * 100,
         epm_real = epm_sa / ipd_machinery_equipment * 100,
         total_real = bs_real + epm_real,
         share_gdp = 100 * total_sa / gdp_cp_sa,
         share_gdp_bs = 100 * bs_sa / gdp_cp_sa,
         share_gdp_epm = 100 * epm_sa / gdp_cp_sa)
nabi <- read_tsv("data-raw/abs_na_business_investment.tsv", col_types = "cdd") |> mutate(q = md(quarter_end))
spl <- left_join(spl, select(nabi, q, na_ndc = na_nondwelling_construction_cp_sa, na_me = na_machinery_equipment_cp_sa), by = "q") |>
  mutate(na_bi_share_gdp = 100 * (na_ndc + na_me) / gdp_cp_sa,
         coverage_vs_na = total_sa / (na_ndc + na_me))
cov <- spl |> mutate(era = cut(as.integer(format(q, "%Y")), c(1960, 1973, 1978, 1986, 2000, 2026),
                               labels = c("1961-73 (pay-roll-tax survey)", "1974-78 (integrated)", "1979-86 (selected industries)", "1987-2000 (ABS current)", "2001-26 (ABS current)"))) |>
  filter(!is.na(coverage_vs_na)) |> group_by(era) |> summarise(capex_over_na_business_investment = round(mean(coverage_vs_na), 2), .groups = "drop")
cat("\nCoverage check: spliced capex / national-accounts private business investment (both current prices, SA):\n"); print(cov)

out <- spl |>
  transmute(quarter = paste0(format(q, "%Y"), "-Q", as.integer(format(q, "%m")) / 3), quarter_end_month = format(q, "%Y-%m"),
            total_orig = round(total, 1), bs_orig = round(bs, 1), epm_orig = round(epm, 1),
            mining_orig = round(mining, 1), manufacturing_orig = round(manufacturing, 1),
            total_sa = round(total_sa, 1), bs_sa = round(bs_sa, 1), epm_sa = round(epm_sa, 1),
            mining_sa = round(mining_sa, 1), manufacturing_sa = round(manufacturing_sa, 1),
            total_real_2023_24_prices = round(total_real, 1), bs_real = round(bs_real, 1), epm_real = round(epm_real, 1),
            share_gdp_pct = round(share_gdp, 2), na_business_investment_share_gdp_pct = round(na_bi_share_gdp, 2),
            capex_over_na_business_investment = round(coverage_vs_na, 3), share_gdp_bs_pct = round(share_gdp_bs, 2), share_gdp_epm_pct = round(share_gdp_epm, 2),
            source, sa_method, bulletin_issue = issue_key)
write_csv(out, "output/capex_spliced_quarterly.csv", na = "")
cat("\nWrote", nrow(out), "quarters:", out$quarter[1], "to", out$quarter[nrow(out)], "\n")

ann <- spl |> mutate(fy = as.integer(format(q, "%Y")) + (as.integer(format(q, "%m")) > 6)) |>
  group_by(fy) |> summarise(n = n(), share = mean(share_gdp), real = sum(total_real), mining_share = sum(mining) / sum(total), .groups = "drop") |>
  filter(n == 4)
cat("Capex as % of GDP, highest financial years:\n"); print(slice_max(ann, share, n = 6) |> mutate(across(c(share, mining_share), ~ round(.x, 3))))
cat("Lowest:\n"); print(slice_min(ann, share, n = 4) |> mutate(across(c(share, mining_share), ~ round(.x, 3))))

# ---- 6. Expectations -------------------------------------------------------------------------
## 6a. Financial-year seven-estimate tables
bfy <- read_tsv("data-raw/cx_fy_expect_raw.tsv", col_types = "cicddddddd") |>
  filter(asset == "tot") |>
  mutate(issue_date = md(substr(issue_key, 3, 9))) |>
  group_by(fy_end) |> slice_max(issue_date, n = 1, with_ties = FALSE) |> ungroup() |>
  filter(fy_end <= 1988) |> mutate(source = "Bulletins (selected industries)")
afy <- read_csv("data-raw/abs_capex_fy_expectations.csv", show_col_types = FALSE) |>
  transmute(fy_end, e1 = tot_all_e1, e2 = tot_all_e2, e3 = tot_all_e3, e4 = tot_all_e4,
            e5 = tot_all_e5, e6 = tot_all_e6, e7 = tot_all_e7, source = "ABS 5625.0") |>
  filter(fy_end >= 1989)
fy <- bind_rows(select(bfy, fy_end, e1:e7, source), afy) |> arrange(fy_end) |>
  mutate(rr_e1 = e7 / e1, rr_e2 = e7 / e2, rr_e3 = e7 / e3, rr_e4 = e7 / e4, rr_e5 = e7 / e5, rr_e6 = e7 / e6)
# overlap check 1989-1990: bulletin and ABS ratios
ov <- inner_join(read_tsv("data-raw/cx_fy_expect_raw.tsv", col_types = "cicddddddd") |> filter(issue_key == "CX1990-06f2"),
                 read_csv("data-raw/abs_capex_fy_expectations.csv", show_col_types = FALSE), by = "fy_end") |>
  transmute(fy_end, rr_e1_bulletin = e7 / e1, rr_e1_abs = tot_all_e7 / tot_all_e1, rr_e3_bulletin = e7 / e3, rr_e3_abs = tot_all_e7 / tot_all_e3) |>
  filter(!is.na(rr_e1_abs), !is.na(rr_e1_bulletin))
cat("\nRealisation ratios where bulletin and ABS overlap:\n"); print(mutate(ov, across(-fy_end, ~ round(.x, 3))))
write_csv(fy |> mutate(across(starts_with("rr_"), ~ round(.x, 3))), "output/capex_fy_expectations.csv", na = "")
done <- filter(fy, !is.na(e7))
cat(sprintf("\nFY realisation ratio actual/E1: mean %.2f, range %.2f-%.2f (%d years); actual/E3 (Jul-Aug, start of year): mean %.2f, range %.2f-%.2f\n",
            mean(done$rr_e1, na.rm = TRUE), min(done$rr_e1, na.rm = TRUE), max(done$rr_e1, na.rm = TRUE), sum(!is.na(done$rr_e1)),
            mean(done$rr_e3, na.rm = TRUE), min(done$rr_e3, na.rm = TRUE), max(done$rr_e3, na.rm = TRUE)))
nxt <- filter(fy, is.na(e7)) |> tail(1)
last5 <- tail(filter(done, !is.na(rr_e3)), 5)
cat(sprintf("FY%d-%02d: E3 = $%s m; x 5-year average actual/E3 (%.3f) implies $%s m (%.1f%% on FY%d-%02d actual)\n",
            nxt$fy_end - 1, nxt$fy_end %% 100, format(nxt$e3, big.mark = ","), mean(last5$rr_e3),
            format(round(nxt$e3 * mean(last5$rr_e3)), big.mark = ","),
            100 * (nxt$e3 * mean(last5$rr_e3) / tail(done$e7, 1) - 1), tail(done$fy_end, 1) - 1, tail(done$fy_end, 1) %% 100))

## 6b. Half-year: expectation for the next six months, reported at the start of the half
half_actual <- function(seg, h) {          # sum of two quarters of a basis segment
  y <- as.integer(substr(h, 1, 4)); qs <- if (substr(h, 5, 6) == "H1") md(sprintf("%d-%02d", y, c(3, 6))) else md(sprintf("%d-%02d", y, c(9, 12)))
  x <- seg$total[match(qs, seg$q)]; if (any(is.na(x))) NA_real_ else sum(x)
}
pct <- read_tsv("data-raw/cx_anticipated_pct.tsv", col_types = "ccddc") |>
  filter(!is.na(actual_pct_change_total)) |>
  transmute(half = half_year, rr = (1 + actual_pct_change_total / 100) / (1 + anticipated_pct_change_total / 100),
            source = "Bulletins: anticipated vs actual % change")
hl <- read_tsv("data-raw/cx_half_antic.tsv", col_types = "cccdddddc") |>
  mutate(issue_date = md(substr(issue_key, 3, 9)), basis = if_else(grepl("INTEGRATED", note), "integrated", "old"))
seg_of <- function(b) switch(b, old = old, integrated = intg, selected = sel)
hl_ant <- hl |> filter(kind == "antic") |> group_by(half) |> slice_max(issue_date, n = 1, with_ties = FALSE) |> ungroup()
lev <- hl_ant |> rowwise() |>
  mutate(actual = half_actual(seg_of(basis), half)) |> ungroup() |>
  transmute(half, expected = total, actual, rr = actual / expected, source = paste0("Bulletins: anticipated level (", basis, " basis)"))
ex <- read_tsv("data-raw/cx_expect_raw.tsv", col_types = "cccc ddddd c" |> gsub(pattern = " ", replacement = "")) |>
  filter(kind == "H_expected_next_half", !target_period %in% pct$half, !target_period %in% lev$half) |>
  mutate(target = paste0(substr(target_period, 1, 4), substr(target_period, 5, 6))) |>
  rowwise() |> mutate(actual = half_actual(sel, target)) |> ungroup() |>
  transmute(half = target, expected = total, actual, rr = actual / expected, source = "Bulletins: expected next six months (selected industries)")
st <- read_tsv("data-raw/abs_short_term_expected_half.tsv", col_types = "cd") |>
  mutate(y = as.integer(substr(survey_quarter, 1, 4)), m = substr(survey_quarter, 6, 7),
         half = if_else(m == "06", paste0(y, "H2"), paste0(y + 1, "H1"))) |>
  rowwise() |> mutate(actual = half_actual(abs, half)) |> ungroup() |>
  transmute(half, expected = expected_next_6_months_total, actual, rr = actual / expected, source = "ABS 5625.0: expected next six months")
halves <- bind_rows(transmute(pct, half, expected = NA_real_, actual = NA_real_, rr, source), lev, ex, st) |>
  mutate(t = as.Date(sprintf("%s-%s-01", substr(half, 1, 4), if_else(substr(half, 5, 6) == "H1", "03", "09")))) |>
  arrange(t)
write_csv(halves |> select(-t) |> mutate(across(c(expected, actual), ~ round(.x, 1)), rr = round(rr, 3)),
          "output/capex_realisation_ratios.csv", na = "")
cat("\nHalf-year realisation ratios (actual / expected at start of half):\n")
print(halves |> mutate(era = cut(as.integer(substr(half, 1, 4)), c(1960, 1969, 1979, 1990, 2000, 2010, 2027),
                                 labels = c("1961-69", "1970-79", "1980-90", "1991-2000", "2001-10", "2011-26"))) |>
        filter(!is.na(rr)) |> group_by(era) |>
        summarise(n = n(), mean_rr = round(mean(rr), 3), min = round(min(rr), 3), max = round(max(rr), 3), .groups = "drop"))
ovh <- halves |> filter(half >= "1987H2", half <= "1990H2") |> select(half, source, rr)
cat("Overlap 1987-90, bulletin vs ABS six-month expectations:\n"); print(mutate(ovh, rr = round(rr, 3)), n = Inf)

# ---- 7. Charts -------------------------------------------------------------------------------
theme_set(theme_minimal(base_size = 11) +
            theme(legend.position = "top", legend.justification = "left",
                  panel.grid.minor = element_blank(), plot.title.position = "plot",
                  plot.caption = element_text(hjust = 0, size = 8, colour = "grey35")))
breaks_v <- as.Date(c("1974-01-01", "1978-03-01", "1987-04-01"))
src_cap <- "Sources: CBCS/ABS capital expenditure bulletins 1961-92 (scans via ANU Open Research); ABS 5625.0 and 5206.0 (June 2026). Seasonal adjustment before Jun qtr 1987: STL."

rl <- bind_rows(transmute(spl, q, s = "Total", v = total_real),
                transmute(spl, q, s = "Equipment, plant and machinery", v = epm_real),
                transmute(spl, q, s = "Buildings and structures", v = bs_real)) |>
  mutate(s = factor(s, levels = c("Total", "Equipment, plant and machinery", "Buildings and structures")))
p1 <- ggplot(rl, aes(q, v / 1000, colour = s)) +
  geom_vline(xintercept = breaks_v, colour = "grey70", linetype = "dotted") +
  geom_line(linewidth = 0.55) +
  scale_colour_manual(values = c("#1f2d5a", "#c0392b", "#1b7f5a"), name = NULL) +
  scale_y_log10(breaks = c(1, 2.5, 5, 10, 20, 40)) +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y", expand = expansion(mult = 0.01)) +
  labs(title = "Private new capital expenditure, Australia, 1961-2026",
       subtitle = "Quarterly, seasonally adjusted, $ billion in 2023-24 prices, log scale. Dotted lines: survey changes (1974, 1978) and the start of the current ABS series (1987).",
       x = NULL, y = "$bn per quarter (2023-24 prices, log)", caption = src_cap)
ggsave("output/capex_spliced.png", p1, width = 11, height = 5.6, dpi = 200, bg = "white")

sl <- bind_rows(transmute(spl, q, s = "Total", v = share_gdp),
                transmute(spl, q, s = "Equipment, plant and machinery", v = share_gdp_epm),
                transmute(spl, q, s = "Buildings and structures", v = share_gdp_bs),
                transmute(spl, q, s = "Mining (all assets)", v = 100 * mining_sa / gdp_cp_sa),
                transmute(spl, q, s = "National accounts private business investment (reference)", v = na_bi_share_gdp)) |>
  filter(!is.na(v)) |>
  mutate(s = factor(s, levels = c("Total", "Equipment, plant and machinery", "Buildings and structures", "Mining (all assets)", "National accounts private business investment (reference)")))
p2 <- ggplot(sl, aes(q, v, colour = s, linetype = s)) +
  geom_vline(xintercept = breaks_v, colour = "grey70", linetype = "dotted") +
  geom_line(linewidth = 0.55) +
  scale_colour_manual(values = c("#1f2d5a", "#c0392b", "#1b7f5a", "#b8860b", "grey55"), name = NULL) +
  scale_linetype_manual(values = c("solid", "solid", "solid", "22", "solid"), name = NULL) +
  guides(colour = guide_legend(nrow = 2), linetype = guide_legend(nrow = 2)) +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y", expand = expansion(mult = 0.01)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.04))) +
  labs(title = "Private new capital expenditure as a share of GDP, 1961-2026",
       subtitle = "Seasonally adjusted, % of nominal GDP. The capex survey excludes agriculture and dwellings; grey line: the national accounts measure for comparison.\nBefore 1987 the survey covered a different set of businesses, so the level of the back-cast is less certain than its movements (see README).",
       x = NULL, y = "% of GDP", caption = src_cap)
ggsave("output/capex_share_gdp.png", p2, width = 11, height = 5.6, dpi = 200, bg = "white")

hp <- halves |> filter(!is.na(rr)) |>
  mutate(src = case_when(grepl("^ABS", source) ~ "ABS (next six months)", TRUE ~ "Bulletins (next six months)")) |>
  arrange(src, t) |> group_by(src) |>
  mutate(run = cumsum(c(TRUE, diff(as.numeric(t)) > 200))) |> ungroup()   # break the line across gaps
fyp <- bind_rows(transmute(fy, t = as.Date(sprintf("%d-01-01", fy_end)), src = "Financial year: actual / E3 (Jul-Aug, start of year)", rr = rr_e3),
                 transmute(fy, t = as.Date(sprintf("%d-01-01", fy_end)), src = "Financial year: actual / E1 (Jan-Feb, ~17 months ahead)", rr = rr_e1)) |>
  filter(!is.na(rr))
cols3 <- c("Bulletins (next six months)" = "#7f9cc9", "ABS (next six months)" = "#1f5aa6",
           "Financial year: actual / E3 (Jul-Aug, start of year)" = "#c0392b",
           "Financial year: actual / E1 (Jan-Feb, ~17 months ahead)" = "#e6a23c")
p3 <- ggplot() +
  geom_hline(yintercept = 1, colour = "grey40") +
  geom_line(data = hp, aes(t, rr, colour = src, group = interaction(src, run)), linewidth = 0.4, alpha = 0.6) +
  geom_point(data = hp, aes(t, rr, colour = src), size = 1.1) +
  geom_line(data = fyp, aes(t, rr, colour = src), linewidth = 0.7) +
  geom_point(data = fyp, aes(t, rr, colour = src), size = 1.3) +
  scale_colour_manual(values = cols3, name = NULL) +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y", expand = expansion(mult = 0.01)) +
  scale_y_continuous(labels = function(x) sprintf("%.1f", x)) +
  guides(colour = guide_legend(nrow = 2)) +
  labs(title = "How well did businesses forecast their own investment? 1961-2026",
       subtitle = "Realisation ratio = actual capital expenditure / what businesses said they expected to spend. Above 1: spent more than planned.",
       x = NULL, y = "Actual / expected",
       caption = "Sources: CBCS/ABS capital expenditure bulletins (anticipated half-yearly expenditure 1961-90; seven-estimate tables 1980-81 to 1987-88); ABS 5625.0 Tables 2 and 17.")
ggsave("output/capex_expectations.png", p3, width = 11, height = 5.8, dpi = 200, bg = "white")

ck <- bind_rows(transmute(old, q, s = "Bulletins: pay-roll-tax businesses", v = total),
                transmute(intg, q, s = "Bulletins: integrated series", v = total),
                transmute(sel, q, s = "Bulletins: selected industries", v = total),
                transmute(abs, q, s = "ABS 5625.0 (current)", v = total)) |>
  filter(q >= as.Date("1970-01-01"), q <= as.Date("1994-12-01"))
p4 <- ggplot(ck, aes(q, v / 1000, colour = s)) + geom_line(linewidth = 0.55) +
  scale_colour_manual(values = c("#9aa9c9", "#7f9cc9", "#1f5aa6", "#c0392b"), name = NULL) +
  scale_y_log10() + scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(title = "Splice overlaps: total private new capital expenditure, original, $bn per quarter (log)",
       subtitle = sprintf("Links: old -> integrated %.3f; integrated -> selected %.3f; selected -> ABS %.3f",
                          k("old -> integrated", "total"), k("integrated -> selected", "total"), k("selected -> ABS 5625.0", "total")),
       x = NULL, y = "$bn (log)")
ggsave("output/capex_splice_check.png", p4, width = 10, height = 4.8, dpi = 200, bg = "white")
