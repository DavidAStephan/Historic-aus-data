# Interest rates, money and credit, 1950 – 2026

Long-run Australian series in three parts:

- **interest rates:** short-term rate, 10-year government bond, housing and business lending;
- **money:** currency, M3 and broad money;
- **credit:** total, housing, personal and business.

Each comes in levels, growth and shares of GDP, and real rates are also given.

- **Monthly:** interest rates from 1959 (housing) and 1969 (bills and bonds); money from 1959; credit from 1976.
- **Annual (years ended June):** everything back to 1950. These come from the RBA's
  *Australian Economic Statistics 1949–50 to 1996–97* (Occasional Paper No. 8) and the 1969
  Annual Report, linked to the monthly series.

![Interest rates](output/interest_rates.png)

## Sources

| Source | Series | Period |
|---|---|---|
| RBA F1.1 | Cash rate target (from Aug 1990), interbank overnight cash rate (from May 1976), 90-day bank bills (from Jun 1969); monthly averages | 1969 – Oct 2026 |
| RBA F2 (historical file and current) | 10-year Australian Government bond yield | Jul 1969 – Oct 2026 |
| RBA F5 | Banks' standard variable housing rate (from 1959), small business variable overdraft indicator rate (from 1976), large business weighted average (1978–2019) | 1959 – Oct 2026 |
| RBA D3 | Currency, M3 (levels, seasonally adjusted from 1965), broad money | Jul 1959 – Sep 2026 |
| RBA D1, D2 | Credit and money growth rates (break-adjusted), and the latest levels | Sep 1976 – Sep 2026 |
| RBA Occasional Paper 8, tables 3.1, 3.2, 3.21a, 3.22a, 3.22b, 3.23 | M3 (from 1950), total credit (from 1953), bond yields, Treasury notes, money-market dealers' rate, bank bills, overdraft rates | 1949-50 – 1996-97 |
| RBA Annual Report 1969, *Australian Interest Rates and Security Yields* | 10-year bond yields on rebateable and non-rebateable bonds, end of quarter | Sep 1966 – Jun 1969 |
| RBA G1; ABS 5206.0 | CPI; nominal GDP (quarterly, from Sep 1959) | |

The RBA tables were read in the browser and saved to `data-raw/rba_monthly.csv`, with the
latest credit levels in `data-raw/rba_credit_anchors.csv`. The Occasional Paper 8 and 1969
Annual Report figures are in the other `data-raw` files.

## Method (`R/money_credit_rates.R`)

1. **Short-term rate.** The series is joined from three rates, all published by the RBA:

   | Period | Rate | Frequency |
   |---|---|---|
   | 1959-60 – 1968-69 | Official money-market dealers' weighted average rate | End-June |
   | Jun 1969 – Apr 1976 | 90-day bank bill rate | Monthly |
   | From May 1976 | Cash rate (interbank overnight, then the target from 1990) | Monthly |

   November 1969's bill rate is recorded as 0 in the RBA table and is treated as missing.
2. **10-year bond yield.**
   - **From July 1969:** RBA monthly.
   - **1949-50 to 1968-69:** end-June yields from Occasional Paper 8. These are for tax-rebateable
     bonds. From late 1968 the Commonwealth issued non-rebateable bonds, which yielded
     0.35–0.39 points more. The three quarters printed on both bases (Dec 1968 – Jun 1969,
     1969 Annual Report) average **0.37 points**, which is added to the earlier yields.
   - **Check:** Occasional Paper 8's financial-year averages from 1969-70 match the RBA monthly
     series to within 0.17 points.
3. **Money and credit: breaks.** The RBA's levels contain breaks, such as new reporting
   institutions and reclassifications. Its growth rates (table D1) are adjusted for them. So the
   levels are rebuilt by chaining the monthly growth rates back from the latest published level:
   - **Total credit:** the series excluding financial businesses (current definition) from May
     2003, and the older total credit series before.
   - **Housing credit:** owner-occupier plus investor.
   - **Business and personal credit:** the same approach as total credit.
   - **Check:** the components add to the total within 0–2.5% from 2003.
4. **M3 before September 1976.** These are the RBA's levels. The new reporting from August 1976
   raised the level by 14.5% in one month, which D1 does not cover. The earlier levels are
   linked at July 1976, taking July–August growth as the average of the next six months
   (1.16% a month).
5. **Annual figures before the monthly series.**
   - **Method:** Occasional Paper 8's end-June growth rates (adjusted by the RBA for breaks) are
     chained back from the monthly levels: M3 before 1960 and credit before 1977.
   - **Credit's 1977 gap:** the paper gives no credit growth for 1976-77, because a new
     collection began in August 1976. June 1976 is estimated from September 1976 using the
     average growth of the following nine months.
   - **Checks against the paper:**

     | Measure | Years | Mean absolute difference |
     |---|---|---|
     | Credit growth | 1979–97 | 0.2 points |
     | M3 growth | 1961–92 | 0.9 points |
6. **Shares of GDP.** Each stock at the end of the period is divided by nominal GDP over the
   four quarters to then.
   - **From 1959-60:** ABS 5206.0 GDP.
   - **Before that:** the GDP implied by the paper's own ratios, raised by 14.5%. That is the
     average gap between today's GDP estimates and the paper's 1990s vintage over 1960–1970.

   Today's GDP is higher, and today's credit definition is narrower. As a result, credit/GDP
   here runs about 7 points below the paper's published ratio in 1978–97, but on a consistent
   basis.
7. **Real rates.** Nominal rate (financial-year average, or end-June where only that exists)
   less CPI inflation over the year (RBA G1).

![Credit and money relative to GDP](output/credit_money_gdp.png)

## Results

| Years ended June | Short rate | 10-year bond | CPI inflation | Real short rate | Real bond | M3 growth | Credit growth |
|---|---|---|---|---|---|---|---|
| 1951–1960 | 3.2* | 5.0 | 6.2 | 1.2* | −1.2 | 5.9 | 11.5 |
| 1961–1970 | 4.4 | 5.4 | 2.5 | 1.9 | 2.9 | 7.7 | 10.9 |
| 1971–1980 | 8.4 | 8.6 | 10.2 | −1.8 | −1.6 | 13.6 | 18.9 |
| 1981–1990 | 14.3 | 13.6 | 8.3 | 6.0 | 5.3 | 13.4 | 18.0 |
| 1991–2000 | 6.7 | 8.2 | 2.2 | 4.5 | 5.9 | 7.1 | 7.8 |
| 2001–2010 | 5.2 | 5.6 | 3.2 | 2.1 | 2.4 | 11.5 | 10.9 |
| 2011–2020 | 2.4 | 3.1 | 2.0 | 0.4 | 1.0 | 6.8 | 4.3 |
| 2021–2026 | 2.6 | 3.3 | 3.9 | −1.3 | −0.6 | 6.9 | 6.4 |

\* 1959-60 only. Averages of annual values, per cent.

**Credit/GDP:**

| Period | Credit, % of GDP |
|---|---|
| 1950s | About 20% |
| 1977 | 41% |
| 1990 | 81% |
| 2000 | 103% |
| Peak, March 2008 | 152% |
| June 2026 | 144% |

Housing credit made up most of the rise, from 15% of GDP in 1977 to 89% now.

**M3/GDP:**

| Period | M3, % of GDP |
|---|---|
| 1950 (wool-boom deposits) | 75% |
| 1960s–1980s | Flat at 40–50% |
| June 2026 | 119% |

![Real interest rates](output/real_interest_rates.png)

## Files

| File | What it is |
|---|---|
| `output/interest_rates_monthly.csv` | Jan 1959 – Oct 2026: cash rate, 90-day bill, 10-year bond, housing variable, small business overdraft, large business average, the joined short rate and its source, CPI inflation, real short rate and real bond yield |
| `output/money_credit_monthly.csv` | Jul 1959 – Sep 2026, $ billion: currency, M3, broad money (from 1976), and break-adjusted credit (total, housing, personal, business, from Aug 1976) |
| `output/money_credit_pct_gdp_quarterly.csv` | Credit (total, housing, business), M3 and broad money as % of GDP, quarterly |
| `output/long_run_annual.csv` | Years ended June 1950 – 2026: rates (with the basis of each value), inflation, real rates, M3 and credit growth, levels and % of GDP, nominal GDP |
| `output/bond_10y_quarterly_1966_69.csv` | The 1969 Annual Report's rebateable and non-rebateable 10-year yields |
| `data-raw/` | The RBA extract, the Occasional Paper 8 tables and the 1969 Annual Report figures |

## Caveats

- **Mixed frequencies before 1969.** Before 1969-70 the rates are mostly end-June values rather
  than averages, so single years can be unrepresentative (for example 1951-52, during the
  Korean War wool-boom inflation). Most bank rates were regulated and changed rarely until the
  1980s.
- **Short-term rate.** The dealers' rate, the 90-day bill rate and the cash rate are different
  instruments, joined without adjustment. In 1976–1982 the 90-day bill rate ran about 1 point
  above the cash rate on average. The 1974 bill-rate spike reflects a
  liquidity squeeze.
- **Bond yields before 1969.** These depend on the 0.37-point rebateable adjustment, which is
  measured on only three quarters.
- **Monthly credit.** This starts in August 1976. Monthly bank lending for 1959–76 is in the
  RBA's *Statistical Bulletin* and the CBCS *Digest of Current Economic Statistics* (ANU
  scans), not transcribed here.
- **Old business rates.** Before 1976, the maximum overdraft rate (to 1955) and the average
  overdraft rate (1956–76) were regulated rates.
