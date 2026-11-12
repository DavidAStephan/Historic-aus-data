# Investment booms in Australia, 1861 - 2026, and the data-centre build-out in that context.
# Run from 12-investment-booms/:  Rscript R/investment_booms.R
# Base R + readr, dplyr, ggplot2. All inputs are in data-raw/ (see README for sources).
#
# Years: calendar years to 1900 (Butlin), years ended June from 1901 (1901 = 1900/01).
# The main measure is TANGIBLE fixed investment (dwellings, other buildings and structures,
# machinery and equipment; private and public) as a share of nominal GDP. It leaves out
# livestock and orchards (cultivated biological resources), ownership transfer costs and
# intellectual property products (software, R&D, mineral exploration), because the historical
# estimates do not include them. Each segment's share uses that source's own GDP.
suppressPackageStartupMessages({ library(readr); library(dplyr); library(ggplot2) })
rd <- function(f) read_csv(file.path("data-raw", f), show_col_types = FALSE)

# ---- 0. Inputs -------------------------------------------------------------------------------
ngb   <- rd("butlin_ngb1962_gdp_gdcf_1861_1901.csv")           # N.G. Butlin (1962), via Jones-Obstfeld
t9    <- rd("butlin1964_t9_private_pct_gdp.csv")               # N.G. Butlin (1964) table 9
t10   <- rd("butlin1964_t10_public_pct_gdp.csv")               # N.G. Butlin (1964) table 10
mwb   <- rd("butlin_mwb1977_gfcf_by_type_fy1901_1945.csv")     # M.W. Butlin (1977), via Jones-Obstfeld
mit   <- rd("mitchell_gdp_gfcf_fy1945_1960.csv")               # Mitchell, International Historical Statistics
op8   <- rd("op8_5_1a_expenditure_gdp_current.csv") |>         # RBA Occasional Paper 8, table 5.1a
  mutate(fy = as.integer(substr(fy, 1, 4)) + 1L, across(c(pubent, gengov), ~ suppressWarnings(as.numeric(.x))))
abs6  <- rd("abs_5206_gfcf_by_sector_asset_fy.csv")            # ABS 5206.0 table 3 (original), summed to FY
abs52 <- rd("abs_5204_t52_private_gfcf_by_industry_fy.csv")    # ABS 5204.0 table 52
jst   <- rd("jst_r6_australia_iy.csv")                         # Jorda-Schularick-Taylor R6 (cross-check)
dc    <- rd("data_centre_scenarios.csv")                       # published data-centre capex estimates

# ---- 1. Segments ---------------------------------------------------------------------------
# A. 1861-1900, calendar years. Total = N.G. Butlin (1962) gross domestic capital formation,
#    public and private (excluding livestock), / GDP at market prices. Butlin (1964) tables 9-10
#    split it by type as % of GDP; they sum to more than the 1962 total (revised estimates and
#    pastoral investment that partly includes livestock), so the 1964 components are scaled to
#    the 1962 total each year. The unscaled 1964 total is kept as an alternative.
segA <- ngb |> filter(year <= 1900) |>
  transmute(year, total_1962 = 100 * ngb_gdcf_pound_000 / 1000 / ngb_gdp_pound_m) |>
  inner_join(t9 |> mutate(across(-year, ~ coalesce(.x, 0))) |>
               transmute(year, p_res = residential, p_mining = mining, p_other = industrial + commercial + shipping + pastoral,
                         p_tot = total), by = "year") |>
  inner_join(t10 |> transmute(year, g_rail = railways, g_other = total - railways, g_tot = total), by = "year") |>
  mutate(total_1964 = p_tot + g_tot, k = total_1962 / total_1964,
         dwellings = p_res * k, business = (p_mining + p_other) * k, public = (g_rail + g_other) * k,
         mining = p_mining * k, public_railways = g_rail * k, total = dwellings + business + public,
         source = "Butlin (1962) total; Butlin (1964) composition")
cat(sprintf("1861-1900: Butlin 1962 total / Butlin 1964 components: mean %.2f (range %.2f - %.2f)\n",
            mean(segA$k), min(segA$k), max(segA$k)))

# B. 1901-1945 (years ended June): M.W. Butlin (1977) fixed capital formation by type.
segB <- mwb |> transmute(year = fy_end, dwellings = 100 * (mwb_priv_dwelling + mwb_pub_dwelling) / mwb_gdp,
                         business = 100 * mwb_priv_nondwelling / mwb_gdp, public = 100 * mwb_pub_nondwelling / mwb_gdp,
                         total = dwellings + business + public, source = "M.W. Butlin (1977)")

# E. 1960-2026: ABS national accounts (current prices, original, summed to years ended June).
segE <- abs6 |> left_join(abs52 |> select(fy, mining_ind = mining, ict_ind = ict), by = "fy") |>
  transmute(year = fy, gdp, dwellings = 100 * dw / gdp, business = 100 * (ndc + me) / gdp, public = 100 * pub / gdp,
            total = dwellings + business + public, mining = 100 * mining_ind / gdp, ict = 100 * ict_ind / gdp,
            ipp_private = 100 * ipp / gdp, livestock_cbr = 100 * cbr / gdp, transfer_costs = 100 * otc / gdp,
            gfcf_all = 100 * gfcf / gdp, source = "ABS 5206.0 / 5204.0")

# D. 1950-1959: OP8 table 5.1a, each component spliced to the ABS basis by its average ratio over
#    the 1960-64 overlap (current ABS GDP is higher, so the shares are a little lower).
op8s <- op8 |> transmute(year = fy, dwellings = 100 * dw / gdp_e, business = 100 * (ndc + equip) / gdp_e,
                         public = 100 * pub / gdp_e)
rat <- op8s |> filter(year %in% 1960:1964) |> inner_join(segE, by = "year", suffix = c("_o", "_a")) |>
  summarise(dwellings = mean(dwellings_a / dwellings_o), business = mean(business_a / business_o), public = mean(public_a / public_o))
cat(sprintf("OP8 -> ABS splice ratios (1960-64): dwellings %.3f, business %.3f, public %.3f\n", rat$dwellings, rat$business, rat$public))
segD <- op8s |> filter(year <= 1959) |>
  mutate(dwellings = dwellings * rat$dwellings, business = business * rat$business, public = public * rat$public,
         total = dwellings + business + public, source = "RBA OP8 table 5.1a (spliced to ABS)")

# C. 1946-1949: Mitchell's total GFCF / GDP, spliced to segment D over 1950-54. Not split by type.
mr <- mit |> transmute(year = fy_end, m = 100 * gfcf / gdp) |> inner_join(segD |> select(year, total), by = "year") |>
  filter(year %in% 1950:1954) |> summarise(r = mean(total / m)) |> pull(r)
cat(sprintf("Mitchell -> OP8/ABS splice ratio (1950-54): %.3f\n", mr))
segC <- mit |> filter(fy_end %in% 1946:1949) |> transmute(year = fy_end, total = 100 * gfcf / gdp * mr, source = "Mitchell (spliced)")

inv <- bind_rows(segA |> select(year, dwellings, business, public, total, mining, public_railways, total_1964, source),
                 segB, segC, segD,
                 segE |> select(year, dwellings, business, public, total, mining, ict, ipp_private, livestock_cbr,
                                transfer_costs, gfcf_all, source)) |>
  left_join(jst |> transmute(year, jst_iy = 100 * iy), by = "year") |>
  arrange(year) |> mutate(across(where(is.numeric) & !year, ~ round(.x, 2)))

# Checks: segment joins and JST.
cat("\nJoins (tangible investment, % of GDP):\n")
print(as.data.frame(inv |> filter(year %in% c(1899:1902, 1944:1951, 1958:1961)) |> select(year, total, jst_iy, source)))
cat(sprintf("\nMean gap to JST investment/GDP: 1870-1900 %.1f, 1901-1945 %.1f, 1950-1959 %.1f, 1960-2020 %.1f pp\n",
            mean((inv$total - inv$jst_iy)[inv$year %in% 1870:1900], na.rm = TRUE),
            mean((inv$total - inv$jst_iy)[inv$year %in% 1901:1945], na.rm = TRUE),
            mean((inv$total - inv$jst_iy)[inv$year %in% 1950:1959], na.rm = TRUE),
            mean((inv$total - inv$jst_iy)[inv$year %in% 1960:2020], na.rm = TRUE)))
write_csv(inv, "output/investment_share_gdp_1861_2026.csv", na = "")

# ---- 2. Booms ---------------------------------------------------------------------------------
# A boom is a rise in a share of GDP from a trough to a peak.
#  - Candidate peaks: the highest value within 4 years either side.
#  - Trough: the lowest value in the 12 years before the peak, not counting the war years
#    1915-1919 and 1940-1946 (so a post-war rebound is measured from the first peacetime trough).
#  - The peak is then moved to the highest point reached before the share falls by more than a
#    third of the rise from its running high (booms that plateau are measured to their top).
#  - Episodes are taken largest first and must not overlap an episode already taken.
#  - Kept if the rise is at least `min_rise` percentage points.
war <- c(1915:1919, 1940:1946)
find_booms <- function(y, v, min_rise, w = 4, back = 12) {
  cand <- NULL
  for (i in seq_along(v)) {
    if (is.na(v[i]) || v[i] < max(v[abs(y - y[i]) <= w], na.rm = TRUE)) next
    pre <- y >= y[i] - back & y < y[i] & !(y %in% war) & !is.na(v)
    if (!any(pre)) next
    j <- which(pre)[which.min(v[pre])]
    if (v[i] - v[j] < min_rise) next
    k <- i; hi <- v[i]
    while (k < length(v) && !is.na(v[k + 1]) && v[k + 1] >= hi - (hi - v[j]) / 3) { k <- k + 1; hi <- max(hi, v[k]) }
    pk <- (j:k)[which.max(v[j:k])]
    cand <- rbind(cand, data.frame(trough_year = y[j], peak_year = y[pk], trough = v[j], peak = v[pk]))
  }
  if (is.null(cand)) return(NULL)
  cand <- unique(cand); cand$rise <- cand$peak - cand$trough
  cand <- cand[order(-cand$rise), ]
  keep <- NULL
  for (r in seq_len(nrow(cand))) {
    a <- cand[r, ]
    if (!is.null(keep) && any(a$trough_year < keep$peak_year & a$peak_year > keep$trough_year)) next
    keep <- rbind(keep, a)
  }
  keep
}
lab_era <- function(p) as.character(cut(p, c(-Inf, 1870, 1879, 1892, 1914, 1930, 1940, 1956, 1972, 1985, 1990, 2000, 2016, Inf),
  labels = c("1860s: pastoral expansion, gold-field towns", "1870s: pastoral expansion and railways",
             "1870s-80s: pastoral expansion, railways, land boom", "Federation to WWI: railways, wheat lands, cities",
             "1920s: post-war development boom", "Late 1930s: recovery from the Depression",
             "Post-war reconstruction and migration", "1960s: manufacturing and minerals expansion",
             "Early 1980s: resources (energy) boom", "Late 1980s: commercial property boom", "Late 1990s",
             "2000s-2010s: mining boom", "2020s")))
bt <- find_booms(inv$year, inv$total, 2.5) |> mutate(measure = "Total tangible investment")
comp <- lapply(c("dwellings", "business", "public", "mining"), function(cc) {
  b <- find_booms(inv$year, inv[[cc]], 1.5)
  if (!is.null(b)) b$measure <- cc
  b
}) |> bind_rows()
booms <- bind_rows(bt, comp) |> mutate(across(c(trough, peak, rise), ~ round(.x, 1)), era = lab_era(peak_year)) |>
  arrange(measure, desc(rise))
# Driver of each total boom: the component with the largest rise over the same trough-peak span.
drv <- function(t0, t1) {
  d <- sapply(c("dwellings", "business", "public"), function(cc) inv[[cc]][inv$year == t1] - inv[[cc]][inv$year == t0])
  if (all(is.na(d))) return(NA_character_)
  paste(sprintf("%s %+.1f", names(d), d), collapse = ", ")
}
booms$change_by_component <- ifelse(booms$measure == "Total tangible investment", mapply(drv, booms$trough_year, booms$peak_year), "")
write_csv(booms, "output/investment_booms.csv", na = "")
cat("\nInvestment booms (rise in share of GDP, percentage points):\n")
print(as.data.frame(booms |> select(measure, trough_year, peak_year, trough, peak, rise, era)), row.names = FALSE)

# ---- 3. Data-centre scenarios ---------------------------------------------------------------------
# Published totals (data-raw/data_centre_scenarios.csv) are spread over years ended June with the
# profiles there (illustrative; the sources give totals and peak timing, not annual paths).
# Nominal GDP after 2025/26 is assumed to grow 5% a year.
g0 <- segE$gdp[segE$year == 2026]
dcs <- dc |> mutate(gdp_proj = g0 * 1.05^(year - 2026), pct_gdp = 100 * capex_bn * 1000 / gdp_proj,
                    pct_gdp_domestic = pct_gdp * domestic_share)
write_csv(dcs |> mutate(across(c(gdp_proj, pct_gdp, pct_gdp_domestic), ~ round(.x, 2))), "output/data_centre_scenarios_pct_gdp.csv")
dpk <- dcs |> group_by(scenario) |> summarise(total_bn = sum(capex_bn), peak_year = year[which.max(pct_gdp)],
                                              peak_pct_gdp = max(pct_gdp), peak_domestic = max(pct_gdp_domestic), .groups = "drop")
cat("\nData-centre scenarios, peak capex as % of GDP:\n"); print(as.data.frame(dpk |> mutate(across(where(is.double), ~ round(.x, 2)))))
ict_base <- mean(inv$ict[inv$year %in% 2019:2023])
cat(sprintf("ICT-industry investment: %.2f%% of GDP in 2025/26 vs %.2f%% average 2018/19-2022/23 (+%.2f pp)\n",
            inv$ict[inv$year == 2026], ict_base, inv$ict[inv$year == 2026] - ict_base))

# ---- 4. Charts --------------------------------------------------------------------------------------
pal <- c(dwellings = "#c0504d", business = "#1f4e79", public = "#7f7f7f", mining = "#d79b00", ict = "#4f9a3f")
th <- theme_minimal(base_size = 11) + theme(legend.position = "bottom", panel.grid.minor = element_blank(), plot.title.position = "plot")

long <- bind_rows(lapply(c("dwellings", "business", "public"), function(cc) data.frame(year = inv$year, part = cc, v = inv[[cc]]))) |>
  filter(!is.na(v)) |> mutate(part = factor(part, c("public", "dwellings", "business"),
                                            c("Public (railways, roads, utilities, government)", "Dwellings", "Private business (incl. mining)")))
tot <- inv |> filter(!is.na(total))
breaks_src <- data.frame(x = c(1900.5, 1945.5, 1949.5, 1959.5))
p1 <- ggplot() +
  geom_col(data = long, aes(year, v, fill = part), width = 1) +
  geom_line(data = tot |> filter(year %in% 1946:1949), aes(year, total), colour = "black", linewidth = 0.6) +
  geom_line(data = inv |> filter(!is.na(jst_iy)), aes(year, jst_iy, linetype = "Jorda-Schularick-Taylor investment/GDP (all GFCF)"), colour = "black", linewidth = 0.35) +
  geom_vline(data = breaks_src, aes(xintercept = x), colour = "grey60", linewidth = 0.25, linetype = "dotted") +
  annotate("text", x = c(1880, 1923, 1985), y = 31.5, size = 3, colour = "grey30",
           label = c("Butlin 1861-1900\n(calendar years)", "M.W. Butlin 1901-45", "OP8 1950-59, ABS 1960-2026")) +
  scale_fill_manual(values = unname(pal[c("public", "dwellings", "business")]), name = NULL) +
  scale_linetype_manual(values = "solid", name = NULL) +
  scale_x_continuous(breaks = seq(1860, 2020, 20), expand = c(0.01, 0)) + scale_y_continuous(limits = c(0, 33), expand = c(0, 0)) +
  labs(title = "Tangible fixed investment as a share of GDP, Australia 1861 - 2026 (per cent)",
       subtitle = "Buildings, structures, machinery and equipment; excludes livestock, transfer costs and intellectual property. 1946-49 total only.",
       x = NULL, y = NULL, caption = "Sources: Butlin (1962, 1964), M.W. Butlin (1977), Mitchell, RBA OP8, ABS 5206.0; JST Macrohistory R6.") +
  th + guides(fill = guide_legend(order = 1), linetype = guide_legend(order = 2))
ggsave("output/investment_share_gdp_1861_2026.png", p1, width = 11, height = 6, dpi = 150, bg = "white")

# Booms ranked, with the data-centre scenarios (increase over the pre-boom level).
bt2 <- bt |> mutate(label = sprintf("%d-%d  %s", trough_year, peak_year, lab_era(peak_year)), kind = "Past booms: total tangible investment")
mb <- comp |> filter(measure == "mining", peak_year >= 2005) |> slice_max(rise, n = 1) |>
  mutate(label = sprintf("%d-%d  Mining investment only (2010s boom)", trough_year, peak_year), kind = "Past booms: mining investment only")
dcb <- dpk |> transmute(label = sprintf("Data centres, peak %d/%02d: %s", peak_year - 1, peak_year %% 100, scenario), rise = peak_pct_gdp,
                        dom = peak_domestic, kind = "Data-centre build-out (projected capex)")
bars <- bind_rows(bt2 |> select(label, rise, kind), mb |> select(label, rise, kind), dcb) |>
  mutate(label = factor(label, rev(label[order(kind != "Past booms: total tangible investment", -rise)])))
p2 <- ggplot(bars, aes(rise, label, fill = kind)) + geom_col(width = 0.7) +
  geom_point(data = dcb |> mutate(label = factor(label, levels(bars$label))), aes(dom, label), inherit.aes = FALSE, shape = 124, size = 5) +
  geom_text(aes(label = sprintf("%.1f", rise)), hjust = -0.2, size = 3.2) +
  scale_fill_manual(values = c("Past booms: total tangible investment" = "#1f4e79", "Past booms: mining investment only" = "#d79b00",
                               "Data-centre build-out (projected capex)" = "#4f9a3f"), name = NULL) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(title = "How big were Australia's investment booms? Rise in investment as a share of GDP, trough to peak (percentage points)",
       subtitle = "Data centres: projected annual capex at its peak as a share of GDP, all of it treated as new; the tick marks the part spent in Australia",
       x = NULL, y = NULL) + th + theme(legend.position = "bottom", legend.direction = "vertical")
ggsave("output/investment_booms_ranked.png", p2, width = 11, height = 6.5, dpi = 150, bg = "white")

# Modern detail: mining and ICT-industry investment with data-centre scenarios.
mod <- bind_rows(data.frame(year = inv$year, v = inv$mining, s = "Mining industry investment (ABS 5204, all assets)"),
                 data.frame(year = inv$year, v = inv$ict, s = "Information media and telecommunications industry investment")) |>
  filter(!is.na(v), year >= 1960)
# Data-centre operators are classified to the information media and telecommunications industry
# (ANZSIC division J), so the scenarios are drawn on top of that industry's pre-boom level.
p3 <- ggplot() + geom_line(data = mod, aes(year, v, colour = s), linewidth = 0.8) +
  geom_line(data = bind_rows(dcs, dcs |> distinct(scenario) |> mutate(year = 2025, pct_gdp = inv$ict[inv$year == 2025] - ict_base)),
            aes(year, ict_base + pct_gdp, linetype = scenario), colour = "#4f9a3f", linewidth = 0.7) +
  scale_colour_manual(values = unname(pal[c("ict", "mining")]), name = NULL) +
  scale_linetype_manual(values = c("dashed", "dotted", "dotdash", "longdash"), name = "ICT investment if data-centre capex follows") +
  scale_x_continuous(breaks = seq(1960, 2030, 10)) +
  labs(title = "Mining investment and the data-centre build-out, share of GDP (per cent), years ended June",
       x = NULL, y = NULL, caption = paste0("Scenarios: data-centre capex added to the ICT industry's 2018/19-2022/23 average share (", sprintf("%.2f", ict_base),
                        "%).\nAnnual paths are illustrative spreads of published totals; nominal GDP grows 5% a year after 2025/26.")) +
  th + theme(legend.box = "vertical")
ggsave("output/mining_vs_data_centres.png", p3, width = 10, height = 5.8, dpi = 150, bg = "white")

cat("\nDone.\n")
