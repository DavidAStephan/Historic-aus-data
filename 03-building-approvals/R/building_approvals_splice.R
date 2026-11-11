# Australian dwelling approvals, monthly, 1960-2026 (spliced)
# ------------------------------------------------------------
# Splices the old ABS / Commonwealth Bureau of Census and Statistics "Building
# Approvals, Australia" bulletins (scans via ANU Open Research) onto the current
# ABS series (8731.0 Building Approvals, Australia, Table 6: number of dwelling
# units approved, Australia, from July 1983), then seasonally adjusts the history.
#
# Inputs (tab-separated, transcribed from the printed tables)
#   ba_raw.tsv   Dec 1962, 1965 and 1966 bulletins: private, government and total
#                new houses and flats approved, Jan 1960 - Dec 1966 (wide: one row
#                per year x sector, columns jan..dec, plus the printed year total)
#   ba_long.tsv  Later bulletins (Jun 1967 - Dec 1985 issues): one row per issue x
#                month with private and total number, original and seasonally
#                adjusted as printed. 'basis' = combined / new (see below).
#                note = thousands_1dp: the Dec 1976 and Dec 1977 issues printed
#                '000 to one decimal place, so those months are rounded to 100.
#   abs_dwellings_approved.tsv  ABS 8731.0 Table 6, Australia, Jul 1983 - Sep 2026
#                (total and private sector, original and seasonally adjusted)
# Outputs
#   dwelling_approvals_spliced_monthly.csv
#   dwelling_approvals_spliced.png, dwelling_approvals_splice_check.png
#
# Definition break
#   Up to the mid-1975 issues the bulletins count "new houses and flats" including
#   dwelling units created by alterations and additions and those in other new
#   buildings ("combined" basis). From the Dec 1975 issue the series is new
#   dwellings in new residential buildings only ("new" basis), revised back to
#   1973-74. Monthly figures on both bases exist for Nov 1974 - Jun 1975.
#
# Method
#   1. For each month take the latest issue that printed it (later issues carry
#      revisions), separately for each basis.
#   2. Link 1 (combined -> new basis): geometric mean of the monthly ratios
#      new / combined over Nov 1974 - Jun 1975 (original figures, same months,
#      so seasonality cancels). Applied to all combined-basis months before Nov 1974.
#   3. Link 2 (old bulletins -> current ABS series): geometric mean of ABS 8731.0 /
#      old bulletin over Jul 1983 - Dec 1985 (original). The current series is
#      about 1% higher (later revisions and small coverage changes).
#   4. Spliced original = ABS 8731.0 from Jul 1983; earlier months = bulletin
#      figures x link factors.
#   5. Seasonal adjustment: STL on the log of the full spliced original series
#      (robust, seasonal window 7, close to an X-11 3x5 filter). The published ABS
#      seasonally adjusted series is used from Jul 1983; STL before that. STL is
#      checked against the seasonally adjusted figures printed in the bulletins.
# Run from this analysis folder (the folder that contains R/), e.g.  Rscript R/building_approvals_splice.R
#   inputs in data-raw/, outputs written to output/

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(ggplot2)
})

gmean <- function(x) exp(mean(log(x)))

# ---- 1. Read the transcriptions --------------------------------------------------
raw0 <- read_tsv("data-raw/ba_raw.tsv", col_types = cols(.default = "c"))
mons <- tolower(month.abb)
raw <- bind_rows(lapply(seq_along(mons), function(i)
    transmute(raw0, issue, page, series, month = as.Date(sprintf("%s-%02d-01", year, i)),
              value = as.numeric(.data[[mons[i]]])))) |>
  group_by(issue, page, month) |>
  summarise(private    = value[series == "private"][1],
            government = value[series == "government"][1],
            total      = value[series == "total"][1], .groups = "drop") |>
  transmute(issue, page = as.integer(page), month,
            private_orig = private,
            total_orig = coalesce(total, private + government),
            private_sa = NA_real_, total_sa = NA_real_,
            note = NA_character_, basis = "combined")

lng <- read_tsv("data-raw/ba_long.tsv", col_types = "cicddddcc") |>
  mutate(month = as.Date(paste0(month, "-01")))

bul <- bind_rows(raw, lng) |>
  mutate(issue_date = as.Date(paste0(issue, "-01")))

# Revisions: months printed by more than one issue with different originals
rev <- bul |>
  filter(!is.na(total_orig)) |>
  group_by(basis, month) |>
  filter(n_distinct(total_orig) > 1) |>
  summarise(values = paste(paste0(total_orig, " (", issue, ")"), collapse = "; "), .groups = "drop")
cat("Months revised between issues (total, original):", nrow(rev), "\n")

# ---- 2. Latest issue for each month, variable and basis --------------------------
vars <- c("private_orig", "private_sa", "total_orig", "total_sa")
latest <- bind_rows(lapply(vars, function(v)
    transmute(bul, issue, page, issue_date, basis, month, note, var = v, value = .data[[v]]))) |>
  filter(!is.na(value)) |>
  group_by(basis, month, var) |>
  slice_max(issue_date, n = 1, with_ties = FALSE) |>
  ungroup()

old <- latest |>
  group_by(basis, month) |>
  summarise(private_orig = value[var == "private_orig"][1],
            private_sa   = value[var == "private_sa"][1],
            total_orig   = value[var == "total_orig"][1],
            total_sa     = value[var == "total_sa"][1], .groups = "drop") |>
  arrange(basis, month)
src <- latest |>
  filter(var == "total_orig") |>
  transmute(basis, month, source_issue = issue, source_page = page,
            rounded_to_100 = !is.na(note) & note == "thousands_1dp")
old <- left_join(old, src, by = c("basis", "month"))

comb <- filter(old, basis == "combined")
newb <- filter(old, basis == "new")

chk_months <- function(d) {
  all <- seq(min(d$month), max(d$month), by = "month")
  setdiff(all, d$month)
}
stopifnot(length(chk_months(comb)) == 0, length(chk_months(newb)) == 0)
cat("Combined basis:", format(min(comb$month)), "-", format(max(comb$month)),
    "| New basis:", format(min(newb$month)), "-", format(max(newb$month)), "\n")

# ---- 3. Link 1: combined -> new basis --------------------------------------------
l1 <- inner_join(select(comb, month, c_tot = total_orig, c_prv = private_orig),
                 select(newb, month, n_tot = total_orig, n_prv = private_orig), by = "month") |>
  mutate(r_tot = n_tot / c_tot, r_prv = n_prv / c_prv)
cat("\nLink 1, new / combined basis, same month (original):\n")
print(mutate(l1, across(starts_with("r_"), ~ round(.x, 3))), n = Inf)
k1_tot <- gmean(l1$r_tot); k1_prv <- gmean(l1$r_prv)
cat(sprintf("Link 1 factor: total %.3f (range %.3f-%.3f), private %.3f (range %.3f-%.3f)\n",
            k1_tot, min(l1$r_tot), max(l1$r_tot), k1_prv, min(l1$r_prv), max(l1$r_prv)))
# Annual cross-check printed in the Jun 1975 / Dec 1975 issues
cat("Annual cross-check: FY1974-75 new 121,130 / combined 127,238 =", round(121130 / 127238, 3),
    "; FY1973-74 =", round(179700 / 184384, 3), "(new basis printed in '000)\n")

# ---- 4. Link 2: old bulletins -> ABS 8731.0 ---------------------------------------
abs <- read_tsv("data-raw/abs_dwellings_approved.tsv", col_types = "cdddd") |>
  mutate(month = as.Date(paste0(month, "-01")))
l2 <- inner_join(select(newb, month, o_tot = total_orig, o_prv = private_orig),
                 select(abs, month, a_tot = total_orig, a_prv = private_orig), by = "month") |>
  mutate(r_tot = a_tot / o_tot, r_prv = a_prv / o_prv)
k2_tot <- gmean(l2$r_tot); k2_prv <- gmean(l2$r_prv)
cat(sprintf("\nLink 2 (ABS 8731.0 / bulletin, %s - %s, %d months): total %.4f (range %.3f-%.3f), private %.4f (range %.3f-%.3f)\n",
            format(min(l2$month), "%b %Y"), format(max(l2$month), "%b %Y"), nrow(l2),
            k2_tot, min(l2$r_tot), max(l2$r_tot), k2_prv, min(l2$r_prv), max(l2$r_prv)))

# ---- 5. Splice the original series ------------------------------------------------
abs_start <- min(abs$month)
new_start <- min(newb$month)
hist <- bind_rows(
  comb |> filter(month < new_start) |>
    transmute(month, total_orig = total_orig * k1_tot * k2_tot,
              private_orig = private_orig * k1_prv * k2_prv,
              total_sa_printed = total_sa * k1_tot * k2_tot,
              private_sa_printed = private_sa * k1_prv * k2_prv,
              total_low  = total_orig * min(l1$r_tot) * k2_tot,
              total_high = total_orig * max(l1$r_tot) * k2_tot,
              source = "Bulletins, combined basis (scaled)", source_issue, source_page, rounded_to_100),
  newb |> filter(month < abs_start) |>
    transmute(month, total_orig = total_orig * k2_tot, private_orig = private_orig * k2_prv,
              total_sa_printed = total_sa * k2_tot, private_sa_printed = private_sa * k2_prv,
              total_low = total_orig * k2_tot, total_high = total_orig * k2_tot,
              source = "Bulletins, new dwellings basis (scaled)", source_issue, source_page, rounded_to_100)
)
spl <- bind_rows(
  hist,
  abs |> transmute(month, total_orig, private_orig,
                   total_sa_abs = total_sa, private_sa_abs = private_sa,
                   total_low = total_orig, total_high = total_orig,
                   source = "ABS 8731.0", rounded_to_100 = FALSE)
) |> arrange(month)
stopifnot(!any(duplicated(spl$month)), all(diff(spl$month) %in% 28:31))

# ---- 6. Seasonal adjustment (STL) --------------------------------------------------
# Trading days: approvals are processed by councils on weekdays, so a month with
# more weekdays than usual for that calendar month records more approvals. This is
# estimated by regressing the STL remainder on the weekday count (relative to the
# average for that calendar month) and removed before the final STL pass. The ABS
# and the old bulletins both adjust for trading days, so this brings STL closer
# to their published seasonally adjusted series.
weekdays_in <- function(m) {
  vapply(seq_along(m), function(i) {
    days <- seq(m[i], seq(m[i], by = "month", length.out = 2)[2] - 1, by = "day")
    sum(!format(days, "%u") %in% c("6", "7"))
  }, numeric(1))
}
spl$weekdays <- weekdays_in(spl$month)
td <- spl$weekdays - ave(spl$weekdays, format(spl$month, "%m"))

stl_sa <- function(x, start) {
  y <- ts(log(x), start = start, frequency = 12)
  f0 <- stl(y, s.window = 7, robust = TRUE)
  b <- unname(coef(lm(as.numeric(f0$time.series[, "remainder"]) ~ td))[2])
  y2 <- y - b * td
  f <- stl(y2, s.window = 7, robust = TRUE)
  list(sa = as.numeric(exp(y2 - f$time.series[, "seasonal"])), td_coef = b)
}
st <- c(as.integer(format(min(spl$month), "%Y")), as.integer(format(min(spl$month), "%m")))
s_tot <- stl_sa(spl$total_orig, st); s_prv <- stl_sa(spl$private_orig, st)
spl$total_sa_stl   <- s_tot$sa
spl$private_sa_stl <- s_prv$sa
cat(sprintf("\nTrading-day effect: +%.1f%% (total), +%.1f%% (private) per extra weekday\n",
            100 * s_tot$td_coef, 100 * s_prv$td_coef))

spl <- spl |>
  mutate(total_sa   = if_else(month >= abs_start, total_sa_abs, total_sa_stl),
         private_sa = if_else(month >= abs_start, private_sa_abs, private_sa_stl),
         sa_method  = if_else(month >= abs_start, "ABS published", "STL with trading-day adjustment (this study)"))

# Checks: STL vs the seasonally adjusted figures printed in the bulletins, and vs ABS
cmp <- spl |>
  filter(!is.na(total_sa_printed)) |>
  mutate(pct = 100 * (total_sa_stl / total_sa_printed - 1))
cat(sprintf("\nSTL vs bulletin-printed SA (total, %d months, %s-%s): mean abs diff %.1f%%, 90th pct %.1f%%\n",
            nrow(cmp), format(min(cmp$month), "%Y"), format(max(cmp$month), "%Y"),
            mean(abs(cmp$pct)), quantile(abs(cmp$pct), 0.9)))
cmp2 <- spl |> filter(month >= abs_start) |> mutate(pct = 100 * (total_sa_stl / total_sa_abs - 1))
cat(sprintf("STL vs ABS published SA (total, Jul 1983 - Sep 2026): mean abs diff %.1f%%\n",
            mean(abs(cmp2$pct), na.rm = TRUE)))
jump <- spl |> filter(month %in% c(abs_start - 31, abs_start)) |> select(month, total_sa_stl, total_sa_abs)
cat("Seam at Jun/Jul 1983 (STL vs ABS SA):\n"); print(jump)

out <- spl |>
  transmute(month = format(month, "%Y-%m"),
            total_orig = round(total_orig), total_sa = round(total_sa),
            private_orig = round(private_orig), private_sa = round(private_sa),
            total_sa_stl = round(total_sa_stl),
            total_sa_printed_scaled = round(total_sa_printed),
            total_low = round(total_low), total_high = round(total_high),
            source, sa_method, source_issue, source_page,
            rounded_to_100 = if_else(rounded_to_100 %in% TRUE, TRUE, NA))
write_csv(out, "output/dwelling_approvals_spliced_monthly.csv", na = "")
cat("\nWrote", nrow(out), "months:", out$month[1], "to", out$month[nrow(out)], "\n")

# Annual totals for a quick look
ann <- spl |> mutate(year = as.integer(format(month, "%Y"))) |>
  group_by(year) |> summarise(total = round(sum(total_orig)), n = n(), .groups = "drop") |>
  filter(n == 12)
cat("Peak calendar years:\n"); print(slice_max(ann, total, n = 5))

# ---- 7. Charts ---------------------------------------------------------------------
lab_src <- c("Bulletins, combined basis (scaled)" = "#7f9cc9",
             "Bulletins, new dwellings basis (scaled)" = "#1f5aa6",
             "ABS 8731.0" = "#c0392b")
pd <- spl |> mutate(source = factor(source, levels = names(lab_src)))
p <- ggplot(pd, aes(month)) +
  geom_line(aes(y = total_orig / 1000), colour = "grey80", linewidth = 0.3) +
  geom_ribbon(data = filter(pd, month < new_start),
              aes(ymin = total_sa_stl * min(l1$r_tot) / k1_tot / 1000,
                  ymax = total_sa_stl * max(l1$r_tot) / k1_tot / 1000),
              fill = "#9db7d9", alpha = 0.45) +
  geom_line(aes(y = total_sa / 1000, colour = source, group = 1), linewidth = 0.6) +
  geom_line(aes(y = private_sa / 1000), colour = "black", linewidth = 0.35, linetype = "22") +
  geom_vline(xintercept = c(new_start, abs_start), colour = "grey50", linewidth = 0.3, linetype = "dotted") +
  annotate("text", x = new_start, y = 2, label = "definition break\n(Nov 1974)", size = 2.8, hjust = 1.05, vjust = 0, colour = "grey35") +
  annotate("text", x = abs_start, y = 2, label = "ABS 8731.0\nfrom Jul 1983", size = 2.8, hjust = -0.05, vjust = 0, colour = "grey35") +
  scale_colour_manual(values = lab_src, name = NULL) +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y", expand = expansion(mult = 0.01)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.04))) +
  labs(title = "Australian dwelling approvals, 1960-2026 (spliced)",
       subtitle = paste0("Number of dwelling units approved per month, '000. Coloured: total, seasonally adjusted; ",
                         "dashed: private sector, SA; grey: total, original.\n",
                         "Shading before Nov 1974: range of the monthly combined-to-new-basis ratios (",
                         sprintf("%.2f-%.2f", min(l1$r_tot), max(l1$r_tot)), ")."),
       x = NULL, y = "Dwellings approved ('000 per month)",
       caption = "Sources: ABS/CBCS Building Approvals bulletins, 1962-1985 issues (scans via ANU Open Research); ABS 8731.0 Table 6. Seasonal adjustment before Jul 1983: STL with trading-day adjustment.") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.minor = element_blank(), plot.title.position = "plot")
ggsave("output/dwelling_approvals_spliced.png", p, width = 11, height = 5.6, dpi = 200, bg = "white")

# Splice check: the three sources over their overlaps
ov <- bind_rows(
  transmute(comb, month, value = total_orig, series = "Bulletins, combined basis (as printed)"),
  transmute(newb, month, value = total_orig, series = "Bulletins, new dwellings basis (as printed)"),
  transmute(abs, month, value = total_orig, series = "ABS 8731.0")
) |> filter(month >= as.Date("1972-01-01"), month <= as.Date("1987-12-01"))
p2 <- ggplot(ov, aes(month, value / 1000, colour = series)) +
  geom_line(linewidth = 0.55) +
  scale_colour_manual(values = c("Bulletins, combined basis (as printed)" = "#7f9cc9",
                                 "Bulletins, new dwellings basis (as printed)" = "#1f5aa6",
                                 "ABS 8731.0" = "#c0392b"), name = NULL) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(title = "Splice overlaps: total dwelling approvals, original, '000",
       subtitle = sprintf("Link 1 (new / combined, Nov 1974 - Jun 1975) = %.3f; link 2 (ABS 8731.0 / bulletin, Jul 1983 - Dec 1985) = %.3f",
                          k1_tot, k2_tot),
       x = NULL, y = "'000 per month") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.minor = element_blank(), plot.title.position = "plot")
ggsave("output/dwelling_approvals_splice_check.png", p2, width = 10, height = 4.6, dpi = 200, bg = "white")
