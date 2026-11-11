# Dwelling approvals, monthly, 1960 – 2026

Number of dwelling units approved, Australia, total and private sector, original and
seasonally adjusted. Built from the ABS/CBCS *Building Approvals, Australia* bulletins
(1962–1985 issues) and spliced onto ABS 8731.0 (Table 6) from July 1983.

![Dwelling approvals](output/dwelling_approvals_spliced.png)

## Definition break (1974–75)

Up to the mid-1975 issues the bulletins count "new houses and flats", which include
dwelling units created by alterations and additions and those in non-residential
buildings (the **combined** basis). From the December 1975 issue the series is new
dwellings in new residential buildings only (the **new** basis), revised back to 1973-74.
Both were printed monthly for November 1974 – June 1975.

## Method (`R/building_approvals_splice.R`)

1. For each month, keep the latest issue that printed it, separately for each basis.
2. **Link 1, combined → new basis:** geometric mean of the monthly ratios over
   Nov 1974 – Jun 1975: **0.950** for total (range 0.938–0.981), 0.931 for private.
   Annual cross-check: FY1974-75 printed on both bases gives 0.952.
3. **Link 2, bulletins → ABS 8731.0:** geometric mean over Jul 1983 – Dec 1985
   (30 months): **1.0074** for total (range 1.000–1.015).
4. **Seasonal adjustment:** ABS published SA from Jul 1983. Before that, STL on logs
   (robust, seasonal window 7) with a trading-day adjustment (each extra weekday in a
   month adds about 3.5% to approvals). The two meet within 0.3% at July 1983; STL
   differs from the SA figures printed in the bulletins (1966–83) by 2.8% on average.

## Files

| File | What it is |
|---|---|
| `data-raw/ba_raw.tsv` | Dec 1962, 1965, 1966 issues: private, government and total, Jan 1960 – Dec 1966 (wide, with printed year totals) |
| `data-raw/ba_long.tsv` | Jun 1967 – Dec 1985 issues: one row per issue × month, private and total, original and SA as printed; `basis` = combined/new; `note` = `thousands_1dp` where the issue printed '000 to one decimal (Dec 1976, Dec 1977 issues) |
| `data-raw/abs_dwellings_approved.tsv` | ABS 8731.0 Table 6, Australia, Jul 1983 – Sep 2026 |
| `tools/check_ba_raw.py` | sum and cross-issue checks for `ba_raw.tsv` (all pass) |
| `output/dwelling_approvals_spliced_monthly.csv` | the spliced monthly series with source issue/page, SA method and band |
| `output/dwelling_approvals_splice_check.png` | the three sources over their overlaps |

## Checks

- Every bulletin table was checked with private + public = total (and houses + other =
  total where printed); all rows add up.
- Bulletin totals for 1974-75 printed on both bases match the splice to within 0.2%.

## Caveats

- The 0.950 factor drifts: FY1973-74 printed figures imply about 0.975, so the early
  1970s may be understated by about 2.5%. The band shows the 0.94–0.98 range.
- Oct 1975 – Oct 1977 are rounded to the nearest 100.
- 1960–66 "new houses and flats" are assumed to be on the combined basis; the bulletins
  are consistent with each other where they overlap.
- Sharp one-month spikes in the 1960s (e.g. June 1964, a large month of public housing)
  are as printed, not transcription errors.
