# historic-aus-data

Long-run Australian macroeconomic series rebuilt from scanned statistical bulletins
and joined ("spliced") onto the current ABS series, with seasonal adjustment, checks
and R code to reproduce every number.

Most of the historical figures were read off page images of old Commonwealth Bureau of
Census and Statistics (CBCS) and ABS bulletins digitised by
[ANU Open Research](https://openresearch-repository.anu.edu.au). The OCR text of
those scans is unusable, so each table was read from a high-resolution render of the
page. Every transcribed row records the bulletin issue and page it came from, and
the tables were checked by adding up their parts (e.g. males + females = total,
quarters = printed year total). Where a period was printed in more than one issue,
the latest issue is used because it carries revisions.

## What's here

| Folder | Series | Period | Frequency |
|---|---|---|---|
| [`01-job-vacancies`](01-job-vacancies) | Commonwealth Employment Service (CES) unfilled vacancies, seasonally adjusted and spliced onto ABS Job Vacancies (6354.0) | 1962 (June only), Dec 1965 – Aug 2026 | Monthly / quarterly |
| [`02-beveridge-curve`](02-beveridge-curve) | Beveridge curve: vacancy rate against unemployment rate | 1950/51 – Aug 2026 | Annual to 1963/64, then quarterly |
| [`03-building-approvals`](03-building-approvals) | Dwelling units approved, total and private, spliced onto ABS 8731.0 | Jan 1960 – Sep 2026 | Monthly |
| [`04-housing-pipeline`](04-housing-pipeline) | New dwellings commenced (starts) and completed, with approvals | Sep qtr 1946 – Jun qtr 2026 | Quarterly |
| [`05-housing-per-capita`](05-housing-per-capita) | Quarterly population (total, 15–64, 15+) and the housing pipeline per 1,000 people | 1946 – 2026 | Quarterly |

Each folder has the same layout:

```
R/          scripts (run from the analysis folder)
data-raw/   transcriptions and downloaded source data
output/     the finished series (CSV) and charts (PNG)
README.md   method, sources, checks and caveats
```

## Headline charts

| | |
|---|---|
| ![Job vacancies](01-job-vacancies/output/job_vacancies_spliced.png) | ![Beveridge curve](02-beveridge-curve/output/beveridge_curve_1952_2026.png) |
| ![Dwelling approvals](03-building-approvals/output/dwelling_approvals_spliced.png) | ![Housing pipeline per capita](05-housing-per-capita/output/housing_per_capita.png) |

## Reproducing

Requires R (4.1 or later) with `readr`, `dplyr` and `ggplot2`. From the repository root:

```r
Rscript run_all.R
```

This rebuilds every output in dependency order:

```
01-job-vacancies ──► 02-beveridge-curve
03-building-approvals ──► 04-housing-pipeline ──► 05-housing-per-capita
```

Each script prints its checks (sum checks, splice ratios, overlap comparisons) as it runs.

## How the splices work, in one paragraph

Old and new series are joined by comparing them over months or quarters where both
exist, always using original (not seasonally adjusted) figures for the same period so
seasonality cancels. The old series is scaled by the average (geometric mean) ratio
and the range of single-period ratios is reported as an uncertainty band. Where a
definition changed inside the old bulletins (e.g. building approvals in 1974–75, or
houses-only vs houses-and-flats in the 1950s), the same overlap or benchmarking logic
is applied at that break too. Seasonal adjustment uses the ABS's own published
seasonally adjusted series wherever it exists and STL (base R) before that, checked
against the seasonally adjusted figures printed in the old bulletins.

## Sources

- ABS / CBCS bulletins (scans): ANU Open Research repository —
  *Employment and Unemployment*, *Building Approvals*, *Quarterly Bulletin of Building Statistics*
- ABS current releases: Job Vacancies (6354.0), Labour Force (6202.0), Building Approvals (8731.0),
  Building Activity (8752.0), National, state and territory population (3101.0),
  Historical Population (3105.0.65.001)
- RBA Occasional Paper No. 8, *Australian Economic Statistics 1949–50 to 1996–97*
- OECD copies of ABS labour force series via FRED
- *The Canberra Times* via Trove (CES vacancy counts 1979–80)

ABS material is used under the Creative Commons Attribution 4.0 International licence.
Details of each source are in the folder READMEs.
