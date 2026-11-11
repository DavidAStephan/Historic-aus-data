# Retail sales, Australia: bulletins (1947-48 to 1983) spliced onto ABS 8501.0 (Apr 1982 - Jun 2025)
# Run from 07-retail-sales/:  Rscript R/retail_splice.R
suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })

# ---- 0. Inputs ---------------------------------------------------------------------------
raw <- read_tsv("data-raw/rs_raw.tsv", col_types = "ccicccccdc", na = "") |>
  mutate(v = if_else(unit == "GBP", 2 * value, value))            # $2 = 1 pound
abs <- read_tsv("data-raw/abs_retail_8501.tsv", col_types = "cddd")
cpi <- read_tsv("data-raw/rba_g1_cpi_quarterly.tsv", col_types = "cd")
pop <- read_csv("../05-housing-per-capita/output/population_quarterly.csv", show_col_types = FALSE)

mi  <- function(p) { y <- as.integer(substr(p, 1, 4)); m <- as.integer(substr(p, 6, 7)); y * 12L + m - 1L }
lab <- function(i) sprintf("%d-%02d", i %/% 12L, i %% 12L + 1L)
qend <- function(i) i - (i %% 3L) + 2L                     # month index -> last month of its quarter
fyend <- function(i) { y <- i %/% 12L; m <- i %% 12L + 1L; (y + (m >= 7)) * 12L + 5L }   # -> June of FY
gm <- function(x) exp(mean(log(x)))

# latest print of each (basis, freq, measure, period)
latest <- raw |> mutate(t = mi(period)) |>
  arrange(desc(issue_date)) |>
  distinct(basis, freq, measure, period, .keep_all = TRUE)
get <- function(b, f, m = "orig") latest |> filter(basis == b, freq == f, measure == m) |> arrange(t)

# ---- 1. Proportional Denton --------------------------------------------------------------
# x: indicator; groups: list of index vectors; totals: benchmark for each group
denton_prop <- function(x, groups, totals) {
  n <- length(x); k <- length(groups)
  D <- diff(diag(n))
  A <- matrix(0, k, n)
  for (j in seq_len(k)) A[j, groups[[j]]] <- x[groups[[j]]]
  K <- rbind(cbind(2 * crossprod(D), t(A)), cbind(A, matrix(0, k, k)))
  sol <- solve(K, c(rep(0, n), totals))
  list(y = sol[1:n] * x, ratio = sol[1:n])
}

# ---- 2. Quarterly totals for each census basis (latest revision) ------------------------
# Candidate for each quarter: printed quarter, or the sum of the three printed months; the
# later vintage wins. A printed financial-year total that is newer than all of its quarters
# is then imposed by Denton.
basis_quarters <- function(b) {
  q_pr <- get(b, "Q") |> transmute(t, val = v, vint = issue_date)
  m <- get(b, "M") |> mutate(q = qend(t))
  q_m <- m |> group_by(q) |> filter(n() == 3) |>
    summarise(val = sum(v), vint = min(issue_date), .groups = "drop") |> rename(t = q)
  cand <- bind_rows(q_pr, q_m) |> arrange(t, desc(vint)) |> distinct(t, .keep_all = TRUE)
  tt <- seq(min(cand$t), max(cand$t), by = 3L)
  stopifnot(all(tt %in% cand$t))
  cand <- cand[match(tt, cand$t), ]
  fy <- get(b, "FY") |> filter(t >= min(tt) + 9L, t <= max(tt))
  g <- list(); tot <- c(); used <- c()
  for (j in seq_len(nrow(fy))) {
    idx <- which(fyend(cand$t) == fy$t[j])
    if (length(idx) == 4 && fy$issue_date[j] > max(cand$vint[idx])) {
      g[[length(g) + 1]] <- idx; tot <- c(tot, fy$v[j]); used <- c(used, fy$period[j])
    }
  }
  val <- cand$val
  if (length(g)) {
    others <- setdiff(seq_along(tt), unlist(g))                 # keep the other quarters fixed
    g2 <- c(g, as.list(others)); tot2 <- c(tot, val[others])
    val <- denton_prop(val, g2, tot2)$y
    cat(sprintf("  %s: FY benchmarks imposed for %s\n", b, paste(used, collapse = ", ")))
  }
  tibble(t = tt, q = val, vint = cand$vint)
}

# monthly series for a basis: indicator = its own months (newest print), older-basis months
# rescaled where its own are missing; Denton to the basis' quarterly totals
monthly_from <- function(Tq, segs) {
  span <- seq(min(Tq$t) - 2L, max(Tq$t), by = 1L)
  ind <- rep(NA_real_, length(span))
  for (s in segs) {                                   # segs: newest first, tibbles (t, v)
    s <- s[s$t %in% span, ]
    if (!nrow(s)) next
    have <- !is.na(ind[match(s$t, span)])
    k <- if (any(have)) gm(ind[match(s$t[have], span)] / s$v[have]) else 1
    fill <- is.na(ind[match(s$t, span)])
    ind[match(s$t[fill], span)] <- s$v[fill] * k
  }
  ok <- !is.na(ind)
  span <- span[ok]; ind <- ind[ok]
  stopifnot(all(diff(span) == 1L))
  qs <- Tq |> filter(t %in% span, (t - 1L) %in% span, (t - 2L) %in% span)
  g <- lapply(qs$t, function(x) which(qend(span) == x))
  d <- denton_prop(ind, g, qs$q)
  tibble(t = span, v = d$y)
}

cat("Quarterly totals by census basis:\n")
Q6162 <- basis_quarters("c6162")
Q6869 <- basis_quarters("c6869")
Q7374 <- basis_quarters("c7374")
M <- function(b) get(b, "M") |> select(t, v)

# 1968-69 census basis extended back to Sep qtr 1968: the 1961-62-basis quarters, benchmarked to
# the 1968-69 Census total and to the 1968-69-basis quarters from Sep qtr 1971 (so the gap that
# opened up between the two bases over 1968-69 to 1971-72 is spread smoothly over those years)
census6869 <- latest |> filter(basis == "c6869", measure == "census") |> pull(v)
ind <- Q6162 |> filter(t >= mi("1968-09"), t <= mi("1972-09"))
tg <- Q6869 |> filter(t >= mi("1971-09"), t <= mi("1972-09"))
g <- c(list(which(fyend(ind$t) == mi("1969-06"))), lapply(tg$t, function(x) which(ind$t == x)))
d6869 <- denton_prop(ind$q, g, c(census6869, tg$q))
cat(sprintf("1968-69 basis / 1961-62 basis: %.4f in 1968-69 (census) rising to %.4f in 1971-72\n",
            min(d6869$ratio), max(d6869$ratio)))
Q6869x <- bind_rows(tibble(t = ind$t, q = d6869$y) |> filter(t < mi("1971-09")), Q6869 |> select(t, q))

# Monthly series for each basis
M7374 <- monthly_from(Q7374, list(M("c7374"), M("c6869")))
M6869 <- monthly_from(Q6869x, list(M("c6869"), M("c6162")))
M6162 <- monthly_from(Q6162 |> filter(t >= mi("1961-09")), list(M("c6162")))
M7980 <- M("c7980")

# ---- 3. Links between bases, working back from ABS 8501.0 --------------------------------
abs <- abs |> mutate(t = mi(month), goods = turnover_orig - cafes_restaurants_takeaway_orig)
ov <- inner_join(M7980, abs, by = "t")
L7980 <- gm(ov$turnover_orig / ov$v)
L7980_goods <- gm(ov$goods / ov$v)
apr82 <- latest |> filter(period == "1982-04", freq == "M", measure == "orig", issue == "RS1983-06x")
r_7374_7980 <- apr82$v[apr82$basis == "c7980"] / apr82$v[apr82$basis == "c7374"]
lnk <- function(A, B, from, to) {               # A newer basis, B older (quarterly)
  x <- inner_join(A, B, by = "t", suffix = c(".a", ".b")) |> filter(t >= mi(from), t <= mi(to))
  list(f = gm(x$q.a / x$q.b), r = range(x$q.a / x$q.b), n = nrow(x))
}
l1 <- lnk(Q7374, Q6869, "1975-09", "1975-12")
l2 <- lnk(Q6869x, Q6162, "1968-09", "1969-06")
L7374 <- L7980 * r_7374_7980
L6869 <- L7374 * l1$f
L6162 <- L6869 * l2$f
links <- tibble(
  link = c("bulletin 1979-80 basis -> ABS 8501.0 (total)", "1973-74 -> 1979-80 basis",
           "1968-69 -> 1973-74 basis", "1961-62 -> 1968-69 basis"),
  overlap = c("Apr 1982 - Jun 1983 (15 months)", "Apr 1982 (printed on both)",
              "Sep, Dec qtr 1975", "1968-69 (Census year)"),
  ratio = c(L7980, r_7374_7980, l1$f, l2$f),
  low = c(min(ov$turnover_orig / ov$v), NA, l1$r[1], l2$r[1]),
  high = c(max(ov$turnover_orig / ov$v), NA, l1$r[2], l2$r[2]),
  cumulative = c(L7980, L7374, L6869, L6162))
print(links, width = 200)
cat(sprintf("(Against ABS total less cafes, restaurants and takeaway: %.4f)\n", L7980_goods))

# ---- 4. Monthly spliced series, Jul 1961 - Jun 2025 ------------------------------------
t74 <- min(M7374$t); t69 <- min(M6869$t)
mon <- bind_rows(
  M6162 |> filter(t < t69) |> mutate(v = v * L6162, basis = "1961-62 Census"),
  M6869 |> filter(t < t74) |> mutate(v = v * L6869, basis = "1968-69 Census"),
  M7374 |> filter(t < mi("1982-04")) |> mutate(v = v * L7374, basis = "1973-74 Census"),
  abs |> transmute(t, v = turnover_orig, basis = "ABS 8501.0")) |>
  arrange(t) |> rename(orig = v)
stopifnot(all(diff(mon$t) == 1L))
cat(sprintf("Monthly: %s to %s; switch points %s, %s, Apr 1982\n", lab(min(mon$t)), lab(max(mon$t)), lab(t69), lab(t74)))

# ---- 5. Quarterly back to Sep qtr 1950 and years from 1947-48 ---------------------------
# Annual totals on the 1961-62 basis: printed directly from 1952-53 (1953-54 interpolated),
# earlier years from the 1956-57 basis series linked at their annual overlap
fy6162 <- get("c6162", "FY") |> select(t, v)
fy5657 <- get("c5657", "FY") |> select(t, v)
ov5 <- inner_join(fy6162, fy5657, by = "t", suffix = c(".n", ".o"))
k5657 <- gm(ov5$v.n / ov5$v.o)
cat(sprintf("1956-57 -> 1961-62 basis (annual, %d years): %.4f (range %.4f-%.4f)\n", nrow(ov5), k5657,
            min(ov5$v.n / ov5$v.o), max(ov5$v.n / ov5$v.o)))
fy_all <- bind_rows(fy6162, fy5657 |> filter(!t %in% fy6162$t) |> mutate(v = v * k5657)) |> arrange(t)

# Quarterly indicator Sep 1950 - Jun 1958 (Sep 1958 on: 1961-62-basis quarters as printed)
q_b <- latest |> filter(basis == "pre5253", freq == "Q") |> select(t, v)
q_57 <- get("c5657", "Q") |> select(t, v)
q_61 <- Q6162 |> select(t, v = q)
qt <- seq(mi("1950-09"), mi("1961-06"), by = 3L)
ind <- rep(NA_real_, length(qt))
put <- function(s, k = 1) { i <- match(s$t, qt); ok <- !is.na(i) & is.na(ind[i]); ind[i[ok]] <<- s$v[ok] * k }
put(q_61)
put(q_57, gm(q_61$v[q_61$t %in% q_57$t] / q_57$v[q_57$t %in% q_61$t]))
put(q_b, k5657)                                        # bulletin quarters (scale is reset by Denton)
# Mar 1954 - Jun 1956 not published: seasonal pattern (average quarterly shares 1950-53,
# 1956-59) on a geometric trend between Dec 1953 and Sep 1956
gap <- which(is.na(ind))
sh <- tibble(t = qt, x = ind) |> filter(!is.na(x)) |>
  mutate(fy = fyend(t)) |> group_by(fy) |> filter(n() == 4) |>
  mutate(s = log(x) - mean(log(x)), qn = (t %% 12L) %/% 3L) |> group_by(qn) |> summarise(s = mean(s))
a <- gap[1] - 1L; b <- tail(gap, 1) + 1L
seas <- function(i) sh$s[match((qt[i] %% 12L) %/% 3L, sh$qn)]
tr_a <- log(ind[a]) - seas(a); tr_b <- log(ind[b]) - seas(b)
for (i in gap) ind[i] <- exp(tr_a + (tr_b - tr_a) * (i - a) / (b - a) + seas(i))
# Denton to the annual totals (1950-51 to 1957-58) and the printed quarters from Sep 1958
grp <- list(); tot <- c()
for (y in fy_all$t[fy_all$t >= mi("1951-06") & fy_all$t <= mi("1958-06")]) {
  grp[[length(grp) + 1]] <- which(fyend(qt) == y); tot <- c(tot, fy_all$v[fy_all$t == y])
}
fix <- which(qt >= mi("1958-09"))
dq <- denton_prop(ind, c(grp, as.list(fix)), c(tot, ind[fix]))
qhist <- tibble(t = qt, orig = dq$y * L6162,
                quarterly_source = case_when(t %in% q_b$t ~ "Bulletins, Sep qtr 1950 - Dec qtr 1953 (benchmarked)",
                                             t %in% q_57$t ~ "1956-57 Census basis (benchmarked)",
                                             t >= mi("1958-09") ~ "1961-62 Census basis",
                                             TRUE ~ "Interpolated (seasonal pattern, annual total)"))

# ---- 6. Seasonal adjustment --------------------------------------------------------------
# Monthly: factors implied by the seasonally adjusted figures printed in the bulletins
# (orig / SA from the same issue, latest issue), Jul 1963 - Mar 1982; ABS SA from Apr 1982.
# Jul 1961 - Jun 1963 (no SA printed): the bulletin factors for Jul 1963 - Jun 1969 regressed on
# calendar month and the number of each weekday in the month (trading days), then predicted.
o <- raw |> filter(freq == "M", measure == "orig") |> select(issue, issue_date, period, basis, o = v)
s <- raw |> filter(freq == "M", measure == "sa") |> select(issue, period, basis, s = v)
sf <- inner_join(o, s, by = c("issue", "period", "basis")) |> mutate(t = mi(period), f = o / s) |>
  arrange(desc(issue_date)) |> distinct(t, .keep_all = TRUE) |> select(t, f, sf_issue = issue)
wd <- function(t) {                              # count of Mon..Sat in each month
  t(sapply(t, function(i) {
    d <- seq(as.Date(sprintf("%d-%02d-01", i %/% 12L, i %% 12L + 1L)), by = "day", length.out = 31)
    d <- d[as.integer(format(d, "%m")) == i %% 12L + 1L]
    tabulate(as.integer(format(d, "%u")), 7)[1:6]
  }))
}
td <- function(t) { w <- wd(t); data.frame(m = factor(t %% 12L, levels = 0:11), w) }
fit_d <- sf |> filter(t >= mi("1963-07"), t <= mi("1969-06"))
fit <- lm(log(fit_d$f) ~ ., data = td(fit_d$t))
cat(sprintf("Trading-day model of bulletin seasonal factors (Jul 1963 - Jun 1969): R2 %.3f, residual sd %.2f%%\n",
            summary(fit)$r.squared, 100 * summary(fit)$sigma))
t_early <- mon$t[mon$t < mi("1963-07")]
f_early <- tibble(t = t_early, f_td = exp(predict(fit, newdata = td(t_early))))
mon <- mon |>
  left_join(sf, by = "t") |> left_join(f_early, by = "t") |>
  left_join(abs |> select(t, sa_abs = turnover_sa), by = "t") |>
  mutate(f = coalesce(f, f_td),
         sa = if_else(!is.na(sa_abs), sa_abs, orig / f),
         sa_method = case_when(!is.na(sa_abs) ~ "ABS 8501.0",
                               t < mi("1963-07") ~ "Bulletin factors modelled with trading days (1963-69 fit)",
                               TRUE ~ paste0("Bulletin factors (", sf_issue, ")"))) |>
  select(-f_td)
stopifnot(!any(is.na(mon$sa)))
# STL check on the monthly original series (STL has no trading-day adjustment, so compare quarters)
stl_m <- function(x, t0) {
  y <- ts(log(x), start = c(t0 %/% 12L, t0 %% 12L + 1L), frequency = 12)
  exp(y - stl(y, s.window = 7, robust = TRUE)$time.series[, "seasonal"])
}
mon$sa_stl <- as.numeric(stl_m(mon$orig, min(mon$t)))
ck <- mon |> filter(t >= mi("1963-07"), t < mi("1982-04")) |> mutate(q = qend(t)) |> group_by(q) |>
  filter(n() == 3) |> summarise(sa = sum(sa), stl = sum(sa_stl))
cat(sprintf("Bulletin-factor SA vs STL, 1963-82 quarters: mean abs level diff %.1f%%; growth correlation %.2f\n",
            mean(abs(100 * (ck$sa / ck$stl - 1))), cor(diff(log(ck$sa)), diff(log(ck$stl)))))
j <- which(mon$t == mi("1982-04"))
cat(sprintf("SA seam: Mar 1982 %.0f -> Apr 1982 %.0f (%+.1f%%); printed old-series SA growth Mar-Apr 1982 %+.1f%%\n",
            mon$sa[j - 1], mon$sa[j], 100 * (mon$sa[j] / mon$sa[j - 1] - 1), 100 * (3207.2 / 3158.1 - 1)))

# Quarterly: sums of monthly from Sep qtr 1961; before that STL on the quarterly original series
qm <- mon |> mutate(t = qend(t)) |> group_by(t) |> filter(n() == 3) |>
  summarise(orig = sum(orig), sa = sum(sa), .groups = "drop")
qall <- bind_rows(qhist |> filter(t < min(qm$t)), qm) |> arrange(t)
stopifnot(all(diff(qall$t) == 3L))
yq <- ts(log(qall$orig), start = c(1950, 3), frequency = 4)
qall$sa_stl <- as.numeric(exp(yq - stl(yq, s.window = 7, robust = TRUE)$time.series[, "seasonal"]))
qall <- qall |> mutate(sa = if_else(is.na(sa), sa_stl, sa),
                       sa_method = if_else(t < min(qm$t), "STL (quarterly)", "Sum of monthly SA"),
                       quarterly_source = coalesce(quarterly_source, "Sum of monthly"))
k <- which(qall$t == min(qm$t))
cat(sprintf("Quarterly SA seam at Sep qtr 1961: STL %.1f vs monthly-based %.1f (%+.1f%%)\n",
            qall$sa_stl[k], qall$sa[k], 100 * (qall$sa_stl[k] / qall$sa[k] - 1)))

# ---- 7. Real and per capita --------------------------------------------------------------
cpi <- cpi |> mutate(t = mi(quarter_end))
base <- mean(cpi$cpi[cpi$t >= mi("2024-09") & cpi$t <= mi("2025-06")])
cpi_m <- approx(cpi$t - 1L, cpi$cpi, xout = mon$t, rule = 2)$y          # quarter index at mid-quarter
popq <- pop |> mutate(t = mi(quarter_end))
pop_m <- exp(approx(popq$t, log(popq$pop_total), xout = mon$t, rule = 2)$y)
mon <- mon |> mutate(real_sa = sa * base / cpi_m, pop = pop_m,
                     real_sa_per_capita_annual = real_sa * 12 * 1e6 / pop)
qall <- qall |> left_join(cpi |> select(t, cpi), by = "t") |>
  left_join(popq |> select(t, pop = pop_total), by = "t") |>
  mutate(real_sa = sa * base / cpi, real_sa_per_capita_annual = real_sa * 4 * 1e6 / pop)

# Financial years: from 1947-48 (annual totals) and sums of quarters from 1950-51
fyq <- qall |> mutate(fy = fyend(t)) |> group_by(fy) |> filter(n() == 4) |>
  summarise(orig = sum(orig), .groups = "drop")
fy_early <- fy_all |> filter(t < min(fyq$fy)) |> transmute(fy = t, orig = v * L6162)
fyall <- bind_rows(fy_early, fyq) |> arrange(fy)
cpi_fy <- cpi |> mutate(fy = fyend(t)) |> group_by(fy) |> summarise(cpi = mean(cpi))
pop_fy <- popq |> transmute(fy = fyend(t), pop_total) |> group_by(fy) |> summarise(pop = mean(pop_total))
fyall <- fyall |> left_join(cpi_fy, by = "fy") |> left_join(pop_fy, by = "fy") |>
  mutate(real = orig * base / cpi, real_per_capita = real * 1e6 / pop,
         growth_nominal = 100 * (orig / lag(orig) - 1), growth_real_per_capita = 100 * (real_per_capita / lag(real_per_capita) - 1))

# ---- 8. Checks ---------------------------------------------------------------------------
# printed financial-year totals reproduced (each basis, scaled)
chk <- bind_rows(
  get("c6162", "FY") |> mutate(L = L6162), get("c6869", "FY") |> mutate(L = L6869),
  get("c7374", "FY") |> mutate(L = L7374)) |>
  inner_join(fyall |> select(t = fy, spliced = orig), by = "t") |>
  mutate(ratio = spliced / (v * L))
cat("Spliced FY / printed FY x link (should be 1 except where a newer basis takes over):\n")
print(chk |> group_by(basis) |> summarise(n = n(), min = min(ratio), max = max(ratio)))
big <- fyall |> filter(abs(growth_nominal) > 25)
if (nrow(big)) { cat("FY nominal growth > 25%:\n"); print(big |> mutate(fy = lab(fy)) |> select(fy, growth_nominal)) }

# ---- 9. Outputs --------------------------------------------------------------------------
dir.create("output", showWarnings = FALSE)
r1 <- function(x) round(x, 1)
mon_out <- mon |> transmute(month = lab(t), turnover_orig = r1(orig), turnover_sa = r1(sa),
  turnover_sa_real_2024_25 = r1(real_sa), real_per_capita_annualised = round(real_sa_per_capita_annual),
  source = if_else(basis == "ABS 8501.0", "ABS 8501.0", paste0("Bulletins, ", basis, " basis, linked")),
  sa_method)
write_csv(mon_out, "output/retail_sales_monthly.csv")
q_out <- qall |> transmute(quarter = lab(t), turnover_orig = r1(orig), turnover_sa = r1(sa),
  turnover_sa_real_2024_25 = r1(real_sa), real_per_capita_annualised = round(real_sa_per_capita_annual),
  source = quarterly_source, sa_method)
write_csv(q_out, "output/retail_sales_quarterly.csv")
fy_out <- fyall |> transmute(year_ended_june = fy %/% 12L, turnover = r1(orig), turnover_real_2024_25 = r1(real),
  real_per_capita = round(real_per_capita), growth_nominal_pct = r1(growth_nominal),
  growth_real_per_capita_pct = r1(growth_real_per_capita))
write_csv(fy_out, "output/retail_sales_financial_year.csv")
write_csv(links |> mutate(across(where(is.numeric), ~ round(.x, 4))), "output/retail_splice_links.csv")

# ---- 10. Charts --------------------------------------------------------------------------
dt <- function(i) as.Date(sprintf("%d-%02d-15", i %/% 12L, i %% 12L + 1L))
pal <- c("#1f4e79", "#c0504d", "#7f7f7f", "#4f9a3f", "#d79b00")
th <- theme_minimal(base_size = 11) + theme(legend.position = "bottom", panel.grid.minor = element_blank(),
                                            plot.title.position = "plot")
qd <- qall |> mutate(d = dt(t), seg = if_else(t < mi("1982-06"), "Bulletins (linked)", "ABS 8501.0"))
p1 <- ggplot(qd, aes(d, real_sa_per_capita_annual)) +
  geom_line(aes(colour = seg), linewidth = 0.6) +
  scale_colour_manual(values = pal[c(2, 1)], name = NULL) +
  scale_y_continuous(labels = scales::label_dollar(), limits = c(0, NA)) +
  labs(title = "Retail sales per person, in 2024-25 prices, 1950 - 2025",
       subtitle = "Quarterly, seasonally adjusted, annual rate; deflated by the CPI",
       x = NULL, y = NULL,
       caption = "Sources: ABS/CBCS retail sales bulletins (ANU Open Research), ABS 8501.0, RBA G1, ABS population; author's splice") + th
ggsave("output/retail_sales_real_per_capita.png", p1, width = 9, height = 5, dpi = 150, bg = "white")

p2 <- ggplot(qd, aes(d, sa)) + geom_line(aes(colour = seg), linewidth = 0.5) +
  scale_y_log10(labels = scales::label_dollar(suffix = "m", accuracy = 1), breaks = c(300, 1000, 3000, 10000, 30000, 100000)) +
  scale_colour_manual(values = pal[c(2, 1)], name = NULL) +
  labs(title = "Retail sales, current prices, quarterly, seasonally adjusted (log scale)", x = NULL, y = NULL,
       caption = "Bulletin series scaled to the level of ABS 8501.0 total turnover") + th
ggsave("output/retail_sales_spliced.png", p2, width = 9, height = 5, dpi = 150, bg = "white")

# splice check: each basis (scaled) over its overlap
segs <- bind_rows(
  M6162 |> mutate(v = v * L6162, s = "1961-62 Census basis"),
  M6869 |> mutate(v = v * L6869, s = "1968-69 Census basis"),
  M7374 |> mutate(v = v * L7374, s = "1973-74 Census basis"),
  M7980 |> mutate(v = v * L7980, s = "1979-80 Census basis (bulletin)"),
  abs |> filter(t <= mi("1985-06")) |> transmute(t, v = turnover_orig, s = "ABS 8501.0")) |>
  inner_join(mon |> select(t, final = orig), by = "t") |>
  mutate(d = dt(t), r = v / final)
p3 <- ggplot(segs |> filter(t >= mi("1966-07")), aes(d, r, colour = s)) +
  geom_hline(yintercept = 1, colour = "grey40") + geom_line(linewidth = 0.5) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1), name = NULL) +
  scale_colour_manual(values = pal, name = NULL) + guides(colour = guide_legend(nrow = 2)) +
  labs(title = "Each census basis, scaled by its link factor, relative to the spliced series",
       subtitle = "Monthly, original. 100% = the series used; the gap 1968-72 is the 1968-69 benchmark revision spread over those years",
       x = NULL) + th

ggsave("output/retail_splice_check.png", p3, width = 9, height = 5, dpi = 150, bg = "white")

cat("Done.\n")
