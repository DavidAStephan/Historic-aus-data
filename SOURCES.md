# Sources

Every number in this repository comes from one of the sources below. This page lists them with links. Two machine-readable registers sit beside it:

- [`sources/anu_issues.csv`](sources/anu_issues.csv): every scanned bulletin issue that was transcribed (202 issues), with its persistent ANU link and the `data-raw` files that use it;
- [`sources/data_raw_files.csv`](sources/data_raw_files.csv): every file in a `data-raw/` folder, with its source, links, and which of its columns record provenance.

## How to trace a number

1. Each folder's `output/` files are built by the script in its `R/` folder from the files in its `data-raw/` folder.
2. Every transcribed value in `data-raw` records the bulletin issue (an issue key such as `BS1974-10` or `LRP48`, or an issue date) and the page it was read from.
3. Look up the issue key in the tables below (or in `sources/anu_issues.csv`) to open the scan. Page numbers are the page of the PDF scan, which can differ from the number printed on the page.
4. Files from the RBA, ABS, OECD/FRED and the Internet Archive are listed further down with links to the tables they were taken from.

## Scanned bulletins (ANU Open Research)

The CBCS and ABS bulletins were read from scans in the [ANU Open Research repository](https://openresearch-repository.anu.edu.au). Each link is the issue's persistent handle.

The issue keys were assigned when transcribing. For most issues the key was recorded against the repository item at the time ("issue used in transcription"). For issues transcribed in earlier sessions, the item was found again by searching the repository for the title and date. Where a search found more than one candidate, the note says so. Ten capital expenditure issues were matched by date only. For seven, no title was recorded when they were transcribed, and the link is that quarter's issue with the same preliminary or final status. **For three (`CX1974-12p2`, `CX1979-09p1`, `CX1980-09f3`) the title recorded in the transcription differs from the linked item (the repository also holds a parallel series for those quarters), so check the title before relying on the link.**

### Australian Banking Statistics (monthly bulletin)

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `M1965-02b` | [Australian Banking Statistics Monthly Bulletin 234 - 1965-02](https://hdl.handle.net/1885/733734280) | 1965-02 |  | `08-money-credit-rates` |
| `M1965-04` | [Australian Banking Statistics Monthly Bulletin 236 - 1965-04](https://hdl.handle.net/1885/733734283) | 1965-04 |  | `08-money-credit-rates` |
| `M1965-06` | [Australian Banking Statistics Monthly Bulletin 238 - 1965-06](https://hdl.handle.net/1885/733734285) | 1965-06 |  | `08-money-credit-rates` |
| `M1965-08` | [Australian Banking Statistics Monthly Bulletin 240 - 1965-08](https://hdl.handle.net/1885/733734288) | 1965-08 |  | `08-money-credit-rates` |
| `M1965-10` | [Australian Banking Statistics Monthly Bulletin 242 - 1965-10](https://hdl.handle.net/1885/733734290) | 1965-10 |  | `08-money-credit-rates` |
| `M1966-02` | [Australian Banking Statistics Monthly Bulletin 246 - 1966-02](https://hdl.handle.net/1885/733734295) | 1966-02 |  | `08-money-credit-rates` |
| `M1966-08` | [Australian Banking Statistics Monthly Bulletin 252 - 1966-08](https://hdl.handle.net/1885/733734302) | 1966-08 |  | `08-money-credit-rates` |
| `M1966-10` | [Australian Banking Statistics Monthly Bulletin 254 - 1966-10](https://hdl.handle.net/1885/733734304) | 1966-10 |  | `08-money-credit-rates` |
| `M1966-12` | [Australian Banking Statistics Monthly Bulletin 256 - 1966-12](https://hdl.handle.net/1885/733734306) | 1966-12 |  | `08-money-credit-rates` |
| `M1967-02` | [Australian Banking Statistics Monthly Bulletin 258 - 1967-02](https://hdl.handle.net/1885/733734309) | 1967-02 |  | `08-money-credit-rates` |
| `M1967-04` | [Australian Banking Statistics Monthly Bulletin 260 - 1967-04](https://hdl.handle.net/1885/733734311) | 1967-04 |  | `08-money-credit-rates` |
| `M1967-06` | [Australian Banking Statistics Monthly Bulletin 262 - 1967-06](https://hdl.handle.net/1885/733734313) | 1967-06 |  | `08-money-credit-rates` |
| `M1967-08` | [Australian Banking Statistics Monthly Bulletin 264 - 1967-08](https://hdl.handle.net/1885/733734315) | 1967-08 |  | `08-money-credit-rates` |
| `M1967-10` | [Australian Banking Statistics Monthly Bulletin 266 - 1967-10](https://hdl.handle.net/1885/733734317) | 1967-10 |  | `08-money-credit-rates` |
| `M1967-12` | [Australian Banking Statistics Monthly Bulletin 268 - 1967-12](https://hdl.handle.net/1885/733734319) | 1967-12 |  | `08-money-credit-rates` |
| `M1968-02` | [Australian Banking Statistics Monthly Bulletin 270 - 1968-02](https://hdl.handle.net/1885/733734321) | 1968-02 |  | `08-money-credit-rates` |
| `M1968-06` | [Australian Banking Statistics Monthly Bulletin 274 - 1968-06](https://hdl.handle.net/1885/733734325) | 1968-06 |  | `08-money-credit-rates` |
| `M1968-08` | [Australian Banking Statistics Monthly Bulletin 276 - 1968-08](https://hdl.handle.net/1885/733734327) | 1968-08 |  | `08-money-credit-rates` |
| `M1968-11` | [Australian Banking Statistics Monthly Bulletin 279 - 1968-11](https://hdl.handle.net/1885/733734330) | 1968-11 |  | `08-money-credit-rates` |

### Australian Banking Statistics (monthly bulletin), December issues

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `MB1957` | [Australian Banking Statistics Monthly Bulletin 148 - 1957-12](https://hdl.handle.net/1885/733734191) | 1957-12 |  | `08-money-credit-rates` |
| `MB1958` | [Australian Banking Statistics Monthly Bulletin 160 - 1958-12](https://hdl.handle.net/1885/733734203) | 1958-12 |  | `08-money-credit-rates` |
| `MB1959` | [Australian Banking Statistics Monthly Bulletin 172 - 1959-12](https://hdl.handle.net/1885/733734215) | 1959-12 |  | `08-money-credit-rates` |
| `MB1960` | [Australian Banking Statistics Monthly Bulletin 184 - 1960-12](https://hdl.handle.net/1885/733734227) | 1960-12 |  | `08-money-credit-rates` |
| `MB1961` | [Australian Banking Statistics Monthly Bulletin 196 - 1961-12](https://hdl.handle.net/1885/733734241) | 1961-12 |  | `08-money-credit-rates` |
| `MB1962` | [Australian Banking Statistics Monthly Bulletin 208 - 1962-12](https://hdl.handle.net/1885/733734253) | 1962-12 |  | `08-money-credit-rates` |
| `MB1963` | [Australian Banking Statistics Monthly Bulletin 220 - 1963-12](https://hdl.handle.net/1885/733734266) | 1963-12 |  | `08-money-credit-rates` |
| `MB1964` | [Australian Banking Statistics Monthly Bulletin 232 - 1964-12](https://hdl.handle.net/1885/733734278) | 1964-12 |  | `08-money-credit-rates` |
| `MB1965n` | [Australian Banking Statistics Monthly Bulletin 243 - 1965-11](https://hdl.handle.net/1885/733734291) | 1965-11 |  | `08-money-credit-rates` |

### Banking (monthly bulletin)

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `BK1975-12` | [Banking - 1975-12](https://hdl.handle.net/1885/733734591) | 1975-12 |  | `08-money-credit-rates` |
| `BK1976-12` | [Banking - 1976-12](https://hdl.handle.net/1885/733734443) | 1976-12 |  | `08-money-credit-rates` |

### Banking Statistics

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `BS1971-10` | [Banking Statistics - 1971-10](https://hdl.handle.net/1885/733734368) | 1971-10 |  | `08-money-credit-rates` |
| `BS1972-10` | [Banking Statistics - 1972-10](https://hdl.handle.net/1885/733734380) | 1972-10 |  | `08-money-credit-rates` |
| `BS1973-10` | [Banking Statistics - 1973-10](https://hdl.handle.net/1885/733734392) | 1973-10 |  | `08-money-credit-rates` |
| `BS1974-10` | [Banking Statistics - 1974-10](https://hdl.handle.net/1885/733734404) | 1974-10 |  | `08-money-credit-rates` |
| `BS1975-03` | [Banking Statistics - 1975-03](https://hdl.handle.net/1885/733734409) | 1975-03 |  | `08-money-credit-rates` |

### Building Approvals, Australia

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `BA1962-12` | [Building Approvals, Australia, December 1962](https://hdl.handle.net/1885/733790510) | 1962-12 | matched by title and date | `03-building-approvals` |
| `BA1965-12` | [Building Approvals, Australia, December 1965](https://hdl.handle.net/1885/733790546) | 1965-12 | matched by title and date | `03-building-approvals` |
| `BA1966-12` | [Building Approvals, Australia, December 1966](https://hdl.handle.net/1885/733790558) | 1966-12 | matched by title and date | `03-building-approvals` |
| `BA1967-06` | [Building Approvals, Australia, June 1967](https://hdl.handle.net/1885/733790564) | 1967-06 | matched by title and date | `03-building-approvals` |
| `BA1967-12` | [Building Approvals, Australia, December 1967](https://hdl.handle.net/1885/733790570) | 1967-12 | matched by title and date | `03-building-approvals` |
| `BA1968-06` | [Building Approvals, Australia, June 1968](https://hdl.handle.net/1885/733790576) | 1968-06 | matched by title and date | `03-building-approvals` |
| `BA1968-12` | [Building Approvals, Australia, December 1968](https://hdl.handle.net/1885/733790582) | 1968-12 | matched by title and date | `03-building-approvals` |
| `BA1969-12` | [Building Approvals, Australia, December 1969](https://hdl.handle.net/1885/733790594) | 1969-12 | matched by title and date | `03-building-approvals` |
| `BA1970-12` | [Building Approvals, Australia, December 1970](https://hdl.handle.net/1885/733790607) | 1970-12 | matched by title and date | `03-building-approvals` |
| `BA1971-12` | [Building Approvals, Australia, December 1971](https://hdl.handle.net/1885/733790619) | 1971-12 | matched by title and date | `03-building-approvals` |
| `BA1972-12` | [Building Approvals, Australia, December 1972](https://hdl.handle.net/1885/733790631) | 1972-12 | matched by title and date | `03-building-approvals` |
| `BA1973-12` | [Building Approvals, Australia, December 1973](https://hdl.handle.net/1885/733790643) | 1973-12 | matched by title and date | `03-building-approvals` |
| `BA1974-12` | [Building Approvals, Australia, December 1974](https://hdl.handle.net/1885/733790655) | 1974-12 | matched by title and date | `03-building-approvals` |
| `BA1975-06` | [Building Approvals, Australia, June 1975](https://hdl.handle.net/1885/733790661) | 1975-06 | matched by title and date | `03-building-approvals` |
| `BA1975-12` | [Building Approvals, Australia, December 1975](https://hdl.handle.net/1885/733790667) | 1975-12 | matched by title and date | `03-building-approvals` |
| `BA1976-12` | [Building Approvals, Australia, December 1976](https://hdl.handle.net/1885/733790679) | 1976-12 | matched by title and date | `03-building-approvals` |
| `BA1977-12` | [Building Approvals, Australia, December 1977](https://hdl.handle.net/1885/733790691) | 1977-12 | matched by title and date | `03-building-approvals` |
| `BA1978-12` | [Building Approvals, Australia, December 1978](https://hdl.handle.net/1885/733790703) | 1978-12 | matched by title and date | `03-building-approvals` |
| `BA1979-12` | [Building Approvals, Australia, December 1979](https://hdl.handle.net/1885/733790715) | 1979-12 | matched by title and date | `03-building-approvals` |
| `BA1980-12` | [Building Approvals, Australia, December 1980](https://hdl.handle.net/1885/733790727) | 1980-12 | matched by title and date | `03-building-approvals` |
| `BA1981-12` | [Building Approvals, Australia, December 1981](https://hdl.handle.net/1885/733790739) | 1981-12 | matched by title and date | `03-building-approvals` |
| `BA1982-12` | [Building Approvals, Australia, December 1982](https://hdl.handle.net/1885/733790751) | 1982-12 | matched by title and date | `03-building-approvals` |
| `BA1983-12` | [Building Approvals, Australia, December 1983](https://hdl.handle.net/1885/733790763) | 1983-12 | matched by title and date | `03-building-approvals` |
| `BA1984-12` | [Building Approvals, Australia, December 1984](https://hdl.handle.net/1885/733790775) | 1984-12 | matched by title and date | `03-building-approvals` |
| `BA1985-12` | [Building Approvals, Australia, December 1985](https://hdl.handle.net/1885/733790787) | 1985-12 | matched by title and date | `03-building-approvals` |

### Capital expenditure by private businesses (survey bulletins)

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `CX1961-09p1` | [Capital Expenditure by Private Businesses in Australia September Quarter 1961 (Preliminary)](https://hdl.handle.net/1885/733740625) | 1961-09 | matched by exact title | `06-capex` |
| `CX1965-06f1` | [Capital Expenditure by Private Business in Australia, June Quarter 1965](https://hdl.handle.net/1885/733740814) | 1965-06 | matched by date and preliminary/final status (no title recorded) | `06-capex` |
| `CX1965-09p1` | [Capital Expenditure by Private Businesses in Australia, September Quarter, 1965 (Preliminary)](https://hdl.handle.net/1885/733740822) | 1965-09 | matched by exact title | `06-capex` |
| `CX1967-09p1` | [Capital Expenditure by Private Businesses in Australia, September Quarter, 1967 (Preliminary)](https://hdl.handle.net/1885/733740839) | 1967-09 | matched by exact title | `06-capex` |
| `CX1969-06f2` | [Capital Expenditure by Private Businesses in Australia, June Quarter 1969 Survey](https://hdl.handle.net/1885/733740751) | 1969-06 | matched by date and preliminary/final status (no title recorded) | `06-capex` |
| `CX1969-09p1` | [Capital Expenditure by Private Businesses in Australia, September Quarter, 1969 (Preliminary)](https://hdl.handle.net/1885/733740847) | 1969-09 | matched by exact title | `06-capex` |
| `CX1971-09p1` | [Capital Expenditure by Private Businesses in Australia, September Quarter, 1971 (Preliminary)](https://hdl.handle.net/1885/733740855) | 1971-09 | matched by exact title | `06-capex` |
| `CX1972-06f1` | [Capital Expenditure by Private Businesses in Australia, June Quarter, 1972](https://hdl.handle.net/1885/733740693) | 1972-06 | matched by date and preliminary/final status (no title recorded) | `06-capex` |
| `CX1973-09p2` | [Capital Expenditure by Private Businesses in Australia, September Quarter, 1973 (Preliminary)](https://hdl.handle.net/1885/733740863) | 1973-09 | matched by exact title | `06-capex` |
| `CX1974-06f2` | [Capital Expenditure by Private Businesses in Australia, June Quarter, 1974](https://hdl.handle.net/1885/733740695) | 1974-06 | matched by date and preliminary/final status (no title recorded) | `06-capex` |
| `CX1974-09p1` | [Capital Expenditure by Private Businesses in Australia, September Quarter, 1974 (Preliminary)](https://hdl.handle.net/1885/733740867) | 1974-09 | matched by exact title | `06-capex` |
| `CX1974-12p2` | [New Capital Expenditure by Private Enterprises in Australia, December Quarter, 1974 (Preliminary)](https://hdl.handle.net/1885/733740868) | 1974-12 | matched by date; the title recorded in the transcription differs, check before use | `06-capex` |
| `CX1975-06f1` | [Capital Expenditure by Private Businesses in Australia, June Quarter, 1975](https://hdl.handle.net/1885/733740699) | 1975-06 | matched by date and preliminary/final status (no title recorded) | `06-capex` |
| `CX1976-09p2` | [New Capital Expenditure by Private Enterprises in Australia, September Quarter, 1976 (Preliminary)](https://hdl.handle.net/1885/733740875) | 1976-09 | matched by exact title | `06-capex` |
| `CX1977-06f1` | [Capital Expenditure by Private Businesses in Australia, June Quarter, 1977](https://hdl.handle.net/1885/733740707) | 1977-06 | matched by date and preliminary/final status (no title recorded) | `06-capex` |
| `CX1977-09p2` | [New Capital Expenditure by Private Enterprises in Australia, September Quarter, 1977 (Preliminary)](https://hdl.handle.net/1885/733740879) | 1977-09 | matched by exact title | `06-capex` |
| `CX1978-09p2` | [New Capital Expenditure by Private Enterprises in Australia, September Quarter 1978 (Preliminary) Actual, December Quarter 1978 (Preliminary) Expected](https://hdl.handle.net/1885/733740883) | 1978-09 | matched by exact title | `06-capex` |
| `CX1979-09p1` | [New Capital Expenditure by Private Enterprises in Australia, September Quarter, 1979 (Preliminary)](https://hdl.handle.net/1885/733740887) | 1979-09 | matched by date; the title recorded in the transcription differs, check before use | `06-capex` |
| `CX1979-12f2` | [New Capital Expenditure by Private Enterprises in Australia, December Quarter 1979](https://hdl.handle.net/1885/733740741) | 1979-12 | matched by date and preliminary/final status (no title recorded) | `06-capex` |
| `CX1980-09f3` | [New Capital Expenditure by Private Enterprises in Australia, September Quarter 1980](https://hdl.handle.net/1885/733740744) | 1980-09 | matched by date; the title recorded in the transcription differs, check before use | `06-capex` |
| `CX1981-06f1` | [New Fixed Capital Expenditure by Private Enterprises in Selected Industries, Australia, June Quarter 1981](https://hdl.handle.net/1885/733740717) | 1981-06 | matched by exact title | `06-capex` |
| `CX1982-12f1` | [New Fixed Capital Expenditure by Private Enterprises in Selected Industries, Australia, December Quarter 1982](https://hdl.handle.net/1885/733740711) | 1982-12 | matched by exact title | `06-capex` |
| `CX1984-12f1` | [New Fixed Capital Expenditure by Private Enterprises in Selected Industries, Australia, December Quarter 1984](https://hdl.handle.net/1885/733740727) | 1984-12 | matched by exact title | `06-capex` |
| `CX1986-06f1` | [New Fixed Capital Expenditure by Private Enterprises in Selected Industries, Australia, June Quarter 1986](https://hdl.handle.net/1885/733740733) | 1986-06 | matched by exact title | `06-capex` |
| `CX1987-06f1` | [Capital Expenditure by Private Businesses in Australia, June Quarter 1987 (Revised)](https://hdl.handle.net/1885/733740757) | 1987-06 | matched by exact title | `06-capex` |
| `CX1988-06f1` | [Private New Capital Expenditure, Australia, June Quarter 1988 Survey](https://hdl.handle.net/1885/733740762) | 1988-06 | matched by exact title | `06-capex` |
| `CX1989-06f2` | [Private New Capital Expenditure, Australia, Actual, And Expected Expenditure to June 1990, June Quarter 1989 Survey](https://hdl.handle.net/1885/733740766) | 1989-06 | matched by exact title | `06-capex` |
| `CX1990-06f2` | [Private New Capital Expenditure, Australia, Actual, And Expected Expenditure to June 1991, June Quarter 1990 Survey](https://hdl.handle.net/1885/733740770) | 1990-06 | matched by exact title | `06-capex` |
| `CX1992-03f1` | [State Estimates of Private New Capital Expenditure March Quarter 1992](https://hdl.handle.net/1885/733742391) | 1992-03 | matched by exact title | `06-capex` |

### Digest of Current Economic Statistics

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `DG1976-01` | [Digest of Current Economic Statistics, January 1976](https://hdl.handle.net/1885/308382) | 1976-01 |  | `10-wages` |
| `DG1976-05` | [Digest of Current Economic Statistics, May 1976](https://hdl.handle.net/1885/308386) | 1976-05 |  | `10-wages` |
| `DG1976-06` | [Digest of Current Economic Statistics, June 1976](https://hdl.handle.net/1885/308387) | 1976-06 |  | `10-wages` |
| `DG1978-07` | [Digest of Current Economic Statistics, July 1978](https://hdl.handle.net/1885/308388) | 1978-07 |  | `10-wages` |
| `DG1979-06` | [Digest of Current Economic Statistics, June 1979](https://hdl.handle.net/1885/308399) | 1979-06 |  | `10-wages` |
| `DG1980-06` | [Digest of Current Economic Statistics, June 1980](https://hdl.handle.net/1885/308411) | 1980-06 |  | `10-wages` |
| `DG1981-06` | [Digest of Current Economic Statistics, June 1981](https://hdl.handle.net/1885/308423) | 1981-06 |  | `10-wages` |
| `DG1982-06` | [Digest of Current Economic Statistics, June 1982](https://hdl.handle.net/1885/308435) | 1982-06 |  | `10-wages` |
| `DG1983-03` | [Digest of Current Economic Statistics, March 1983](https://hdl.handle.net/1885/308444) | 1983-03 |  | `10-wages` |
| `DG1984-03` | [Digest of Current Economic Statistics, March 1984](https://hdl.handle.net/1885/308456) | 1984-03 |  | `10-wages` |

### Employment and Unemployment

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `EU1963-10` | [Employment and Unemployment - October 1963](https://hdl.handle.net/1885/733743157) | 1963-10 |  | `09-unemployment` |
| `EU1964-04` | [Employment and Unemployment - April 1964](https://hdl.handle.net/1885/733743163) | 1964-04 |  | `09-unemployment` |
| `EU1964-07` | [Employment and Unemployment - July 1964](https://hdl.handle.net/1885/733743166) | 1964-07 |  | `09-unemployment` |
| `EU1964-12` | [Employment and Unemployment - December 1964](https://hdl.handle.net/1885/733743171) | 1964-12 |  | `09-unemployment` |
| `EU1965-06` | [Employment and Unemployment - June 1965](https://hdl.handle.net/1885/733743182) | 1965-06 |  | `09-unemployment` |
| `EU1965-12` | [Employment and Unemployment - December 1965](https://hdl.handle.net/1885/733743188) | 1965-12 |  | `09-unemployment` |
| `EU1966-06` | [Employment and Unemployment - June 1966](https://hdl.handle.net/1885/733743194) | 1966-06 |  | `01-job-vacancies`, `09-unemployment` |
| `EU1966-12` | [Employment and Unemployment - December 1966](https://hdl.handle.net/1885/733743200) | 1966-12 |  | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1967-06` | [Employment and Unemployment - June 1967](https://hdl.handle.net/1885/733743206) | 1967-06 |  | `01-job-vacancies`, `09-unemployment` |
| `EU1967-12` | [Employment and Unemployment - December 1967](https://hdl.handle.net/1885/733743212) | 1967-12 |  | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1968-04` | [Employment and Unemployment - April 1968](https://hdl.handle.net/1885/733743216) | 1968-04 |  | `09-unemployment` |
| `EU1968-06` | [Employment and Unemployment - June 1968](https://hdl.handle.net/1885/733743218) | 1968-06 |  | `01-job-vacancies` |
| `EU1968-08` | [Employment and Unemployment - August 1968](https://hdl.handle.net/1885/733743220) | 1968-08 |  | `09-unemployment` |
| `EU1968-12` | [Employment and Unemployment - December 1968](https://hdl.handle.net/1885/733743224) | 1968-12 |  | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1969-02` | [Employment and Unemployment - February 1969](https://hdl.handle.net/1885/733743226) | 1969-02 |  | `01-job-vacancies` |
| `EU1969-03to09` | [Employment and Unemployment - March to September 1969](https://hdl.handle.net/1885/733743227) | 1969-09 | matched by title and date | `01-job-vacancies` |
| `EU1969-09` | [Employment and Unemployment - March to September 1969](https://hdl.handle.net/1885/733743227) | 1969-09 |  | `09-unemployment` |
| `EU1969-10to12` | [Employment and Unemployment - October to December 1969](https://hdl.handle.net/1885/733743228) | 1969-12 | matched by title and date | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1970-12` | [Employment and Unemployment - December 1970](https://hdl.handle.net/1885/733743238) | 1970-12 |  | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1971-04` | [Employment and Unemployment - April 1971](https://hdl.handle.net/1885/733743242) | 1971-04 |  | `09-unemployment` |
| `EU1971-06` | [Employment and Unemployment - June 1971](https://hdl.handle.net/1885/733743244) | 1971-06 |  | `01-job-vacancies` |
| `EU1971-12` | [Employment and Unemployment - December 1971](https://hdl.handle.net/1885/733743250) | 1971-12 |  | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1972-12` | [Employment and Unemployment - December 1972](https://hdl.handle.net/1885/733743262) | 1972-12 |  | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1973-12` | [Employment and Unemployment - December 1973](https://hdl.handle.net/1885/733743275) | 1973-12 |  | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1974-12` | [Employment and Unemployment - December 1974](https://hdl.handle.net/1885/733743287) | 1974-12 |  | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1975-03` | [Employment and Unemployment - March 1975](https://hdl.handle.net/1885/733743290) | 1975-03 |  | `09-unemployment` |
| `EU1975-06` | [Employment and Unemployment - June 1975](https://hdl.handle.net/1885/733743293) | 1975-06 |  | `01-job-vacancies` |
| `EU1975-11to12` | [Employment and Unemployment - November and December 1975](https://hdl.handle.net/1885/733743298) | 1975-12 | matched by title and date | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1976-12` | [Employment and Unemployment - December 1976](https://hdl.handle.net/1885/733743306) | 1976-12 |  | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1977-12` | [Employment and Unemployment - December 1977](https://hdl.handle.net/1885/733743318) | 1977-12 |  | `01-job-vacancies`, `02-beveridge-curve` |
| `EU1978-06` | [Employment and Unemployment - June 1978](https://hdl.handle.net/1885/733743324) | 1978-06 |  | `01-job-vacancies` |

### Hire purchase / Instalment Credit for Retail Sales

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `IC1958-12` | [Retail Hire Purchase Operations of Finance Businesses: Australia, Month of December 1958, Preliminary Estimates](https://hdl.handle.net/1885/733739194) | 1958-12 |  | `08-money-credit-rates` |
| `IC1961-06b` | [Retail Hire Purchase Operations of Finance Businesses: Australia, June 1961 (Provisional)](https://hdl.handle.net/1885/733739504) | 1961-06 |  | `08-money-credit-rates` |
| `IC1962-12b` | [Instalment Credit for Retail Sales: Australia, December 1962 (Provisional)](https://hdl.handle.net/1885/733739240) | 1962-12 |  | `08-money-credit-rates` |
| `IC1964-12b` | [Instalment Credit for Retail Sales: Australia, December 1964 (Provisional)](https://hdl.handle.net/1885/733739264) | 1964-12 |  | `08-money-credit-rates` |
| `IC1966-12b` | [Instalment Credit for Retail Sales: Australia, November 1966 (Preliminary Estimates), December 1966 (Provisional Estimate)](https://hdl.handle.net/1885/733739287) | 1966-12 |  | `08-money-credit-rates` |
| `IC1967-08` | [Instalment Credit for Retail Sales: Australia, July 1967 (Preliminary Estimates), August 1967 (Provisional Estimate)](https://hdl.handle.net/1885/733739295) | 1967-08 |  | `08-money-credit-rates` |
| `IC1968-11b` | [Instalment Credit for Retail Sales: Australia, October 1968 (Preliminary Estimates), November 1968 (Provisional Estimate)](https://hdl.handle.net/1885/733739310) | 1968-11 |  | `08-money-credit-rates` |
| `IC1969-12c` | [Instalment Credit for Retail Sales: Australia, November 1969 (Preliminary Estimates), December 1969 (Provisional Estimate)](https://hdl.handle.net/1885/733739324) | 1969-12 |  | `08-money-credit-rates` |
| `IC1971-01` | [Instalment Credit for Retail Sales: Australia, December 1970 (Preliminary Estimates), January 1971 (Provisional Estimate)](https://hdl.handle.net/1885/733739337) | 1971-01 |  | `08-money-credit-rates` |
| `IC1971-12` | [Instalment Credit for Retail Sales, December Quarter 1971](https://hdl.handle.net/1885/733739179) | 1971-12 |  | `08-money-credit-rates` |
| `IC1972-04` | [Instalment Credit for Retail Sales: Australia, March 1972 (Preliminary Estimates), April 1972 (Provisional Estimate)](https://hdl.handle.net/1885/733739352) | 1972-04 |  | `08-money-credit-rates` |

### Labour Report

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `LRP48` | [Labour Report No.48, 1960](https://hdl.handle.net/1885/733743082) | 1962-06 |  | `10-wages` |
| `LRP55` | [Labour Report No.55, 1970](https://hdl.handle.net/1885/733743860) | 1971-10 |  | `10-wages` |
| `LRP58` | [Labour Report No.58, 1973](https://hdl.handle.net/1885/733743137) | 1974-12 |  | `10-wages` |

### Major trading banks: preliminary statements

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `PS1966-01` | [Banking Statistics - Major Trading Banks Preliminary Statement, January 1966](https://hdl.handle.net/1885/733740245) | 1966-01 |  | `08-money-credit-rates` |
| `PS1966-04` | [Banking Statistics - Major Trading Banks Preliminary Statement, April 1966](https://hdl.handle.net/1885/733740248) | 1966-04 |  | `08-money-credit-rates` |
| `PS1966-06` | [Banking Statistics - Major Trading Banks Preliminary Statement, June 1966](https://hdl.handle.net/1885/733740250) | 1966-06 |  | `08-money-credit-rates` |
| `PS1966-08` | [Banking Statistics - Major Trading Banks Preliminary Statement, August 1966](https://hdl.handle.net/1885/733740252) | 1966-08 |  | `08-money-credit-rates` |
| `PS1968-12` | [Banking Statistics - Major Trading Banks Preliminary Statement, December 1968](https://hdl.handle.net/1885/733740127) | 1968-12 |  | `08-money-credit-rates` |
| `PS1969-02` | [Banking Statistics - Major Trading Banks Preliminary Statement, February 1969](https://hdl.handle.net/1885/733740129) | 1969-02 |  | `08-money-credit-rates` |
| `PS1969-04` | [Banking Statistics - Major Trading Banks Preliminary Statement, April 1969](https://hdl.handle.net/1885/733740131) | 1969-04 |  | `08-money-credit-rates` |
| `PS1969-06` | [Banking Statistics - Major Trading Banks Preliminary Statement, June 1969](https://hdl.handle.net/1885/733740133) | 1969-06 |  | `08-money-credit-rates` |
| `PS1969-08` | [Banking Statistics - Major Trading Banks Preliminary Statement, August 1969](https://hdl.handle.net/1885/733740135) | 1969-08 |  | `08-money-credit-rates` |
| `PS1969-10` | [Banking Statistics - Major Trading Banks Preliminary Statement, October 1969](https://hdl.handle.net/1885/733740137) | 1969-10 |  | `08-money-credit-rates` |
| `PS1969-12` | [Banking Statistics - Major Trading Banks Preliminary Statement, December 1969](https://hdl.handle.net/1885/733740139) | 1969-12 |  | `08-money-credit-rates` |
| `PS1970-02` | [Banking Statistics - Major Trading Banks Preliminary Statement, February 1970](https://hdl.handle.net/1885/733740141) | 1970-02 |  | `08-money-credit-rates` |
| `PS1970-04` | [Banking Statistics - Major Trading Banks Preliminary Statement, April 1970](https://hdl.handle.net/1885/733740143) | 1970-04 |  | `08-money-credit-rates` |
| `PS1970-06` | [Banking Statistics - Major Trading Banks Preliminary Statement, June 1970](https://hdl.handle.net/1885/733740145) | 1970-06 |  | `08-money-credit-rates` |
| `PS1970-08` | [Banking Statistics - Major Trading Banks Preliminary Statement, August 1970](https://hdl.handle.net/1885/733740147) | 1970-08 |  | `08-money-credit-rates` |

### Monthly Bulletin of Employment Statistics

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `ME1952-12` | [Monthly Bulletin of Employment Statistics, No.133, December 1952](https://hdl.handle.net/1885/733743785) | 1952-12 |  | `09-unemployment` |
| `ME1953-12` | [Monthly Bulletin of Employment Statistics, No.145, December 1953](https://hdl.handle.net/1885/733743797) | 1953-12 |  | `09-unemployment` |
| `ME1954-12` | [Monthly Bulletin of Employment Statistics, No.157, December 1954](https://hdl.handle.net/1885/733743809) | 1954-12 |  | `09-unemployment` |
| `ME1955-12` | [Monthly Bulletin of Employment Statistics, No.169, December 1955](https://hdl.handle.net/1885/733743821) | 1955-12 |  | `09-unemployment` |
| `ME1956-12` | [Monthly Bulletin of Employment Statistics, No.181, December 1956](https://hdl.handle.net/1885/733743833) | 1956-12 |  | `09-unemployment` |
| `ME1957-12` | [Monthly Bulletin of Employment Statistics, No.193, December 1957](https://hdl.handle.net/1885/733743845) | 1957-12 |  | `09-unemployment` |
| `ME1958-12` | [Monthly Bulletin of Employment Statistics, No.205, December 1958](https://hdl.handle.net/1885/733743857) | 1958-12 |  | `09-unemployment` |
| `ME1959-12` | [Monthly Bulletin of Employment Statistics, No.217, December 1959](https://hdl.handle.net/1885/733743871) | 1959-12 |  | `09-unemployment` |
| `ME1960-12` | [Monthly Bulletin of Employment Statistics, No.229, December 1960](https://hdl.handle.net/1885/733743883) | 1960-12 |  | `09-unemployment` |
| `ME1961-06` | [Monthly Bulletin of Employment Statistics, No.235, June 1961](https://hdl.handle.net/1885/733743889) | 1961-06 |  | `09-unemployment` |
| `ME1961-12` | [Monthly Bulletin of Employment Statistics, No.241, December 1961](https://hdl.handle.net/1885/733743895) | 1961-12 |  | `09-unemployment` |
| `ME1962-06` | [Monthly Bulletin of Employment Statistics, No.247, June 1962](https://hdl.handle.net/1885/733743901) | 1962-06 |  | `09-unemployment` |
| `ME1962-12` | [Monthly Bulletin of Employment Statistics, No.253, December 1962](https://hdl.handle.net/1885/733743907) | 1962-12 |  | `09-unemployment` |
| `ME1963-04` | [Monthly Bulletin of Employment Statistics, No.257, April 1963](https://hdl.handle.net/1885/733743911) | 1963-04 |  | `09-unemployment` |

### Quarterly Bulletin of Building Statistics

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `QB1948-12` | [Quarterly Bulletin of Building Statistics, No.4, December Quarter 1948](https://hdl.handle.net/1885/733789972) | 1948-12 | matched by title and date | `04-housing-pipeline` |
| `QB1949-12` | [Quarterly Bulletin of Building Statistics, No.8, December Quarter 1949](https://hdl.handle.net/1885/733789976) | 1949-12 | matched by title and date | `04-housing-pipeline` |
| `QB1950-12` | [Quarterly Bulletin of Building Statistics, Australia, No.12, December Quarter 1950](https://hdl.handle.net/1885/733789980) | 1950-12 | matched by title and date | `04-housing-pipeline` |
| `QB1951-12` | [Quarterly Bulletin of Building Statistics, Australia, No.16, December Quarter 1951](https://hdl.handle.net/1885/733789984) | 1951-12 | matched by title and date | `04-housing-pipeline` |
| `QB1952-12` | [Quarterly Bulletin of Building Statistics, Australia, No.20, December Quarter 1952](https://hdl.handle.net/1885/733789988) | 1952-12 | matched by title and date | `04-housing-pipeline` |
| `QB1953-12` | [Quarterly Bulletin of Building Statistics, Australia, No.24, December Quarter 1953](https://hdl.handle.net/1885/733789992) | 1953-12 | matched by title and date | `04-housing-pipeline` |
| `QB1954-12` | [Quarterly Bulletin of Building Statistics, Australia, No.28, December Quarter 1954](https://hdl.handle.net/1885/733789996) | 1954-12 | matched by title and date | `04-housing-pipeline` |
| `QB1955-12` | [Quarterly Bulletin of Building Statistics, Australia, No.32, December Quarter 1955](https://hdl.handle.net/1885/733790000) | 1955-12 | matched by title and date | `04-housing-pipeline` |
| `QB1956-12` | [Quarterly Bulletin of Building Statistics, Australia, No.36, December Quarter 1956](https://hdl.handle.net/1885/733790004) | 1956-12 | matched by title and date | `04-housing-pipeline` |
| `QB1957-12` | [Quarterly Bulletin of Building Statistics, Australia, No.40, December Quarter 1957](https://hdl.handle.net/1885/733790008) | 1957-12 | matched by title and date | `04-housing-pipeline` |

### Quarterly Summary of Australian Statistics

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `QSAS226` | [Quarterly Summary of Australian Statistics, Number 226, December 1956](https://hdl.handle.net/1885/310692) | 1956-12 | matched by title and date | `07-retail-sales` |
| `QSAS238` | [Quarterly Summary of Australian Statistics, Number 238, December 1959](https://hdl.handle.net/1885/310704) | 1959-12 | matched by title and date | `07-retail-sales` |
| `QSAS254` | [Quarterly Summary of Australian Statistics, Number 254, December 1964](https://hdl.handle.net/1885/310720) | 1964-12 | matched by title and date | `07-retail-sales` |

### Retail Sales of Goods / Survey of Retail Establishments

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `RS1953-09` | [Survey of Retail Establishments, Australia, September Quarter 1953](https://hdl.handle.net/1885/733789053) | 1953-09 | matched by title and date | `07-retail-sales` |
| `RS1953-12` | [Survey of Retail Establishments, Australia, December Quarter 1953](https://hdl.handle.net/1885/733789054) | 1953-12 | matched by title and date | `07-retail-sales` |
| `RS1959-09` | [Survey of Retail Establishments, Australia, September Quarter 1959](https://hdl.handle.net/1885/733789072) | 1959-09 | matched by title and date | `07-retail-sales` |
| `RS1965-06q` | [Retail Sales of Goods, Australia, June Quarter 1965 (Preliminary)](https://hdl.handle.net/1885/733788898) | 1965-06 | matched by title and date | `07-retail-sales` |
| `RS1967-12q` | [Retail Sales of Goods, Australia, December Quarter 1967](https://hdl.handle.net/1885/733788994) | 1967-12 | matched by title and date | `07-retail-sales` |
| `RS1971-12q` | [Retail Sales of Goods, Australia, December Quarter 1971 (Preliminary)](https://hdl.handle.net/1885/733788904) | 1971-12 | matched by title and date | `07-retail-sales` |
| `RS1973-12q` | [Retail Sales of Goods, Australia (Provisional), December 1973](https://hdl.handle.net/1885/733788612) | 1973-12 | matched by title and date | `07-retail-sales` |
| `RS1975-12q` | [Retail Sales of Goods, Australia, December Quarter 1975 (Preliminary)](https://hdl.handle.net/1885/733788912) | 1975-12 | matched by title and date | `07-retail-sales` |
| `RS1977-12q` | [Retail Sales of Goods, Australia, December Quarter 1977 (Preliminary)](https://hdl.handle.net/1885/733788917) | 1977-12 | matched by title and date | `07-retail-sales` |
| `RS1978-12q` | [Retail Sales of Goods, Australia, December Quarter 1978](https://hdl.handle.net/1885/733789010) | 1978-12 | matched by title and date | `07-retail-sales` |
| `RS1979-12q` | [Retail Sales of Goods, Australia, December Quarter 1979 (Preliminary)](https://hdl.handle.net/1885/733788925) | 1979-12 | matched by title and date | `07-retail-sales` |
| `RS1980-12q` | [Retail Sales of Goods, Australia, December Quarter 1980](https://hdl.handle.net/1885/733789018) | 1980-12 | matched by title and date | `07-retail-sales` |
| `RS1982-03q` | [Retail Sales of Goods, Australia, March Quarter 1982 (Preliminary)](https://hdl.handle.net/1885/733788933) | 1982-03 | matched by title and date | `07-retail-sales` |
| `RS1982-05x` | [Retail Sales of Goods (Excluding Motor Vehicles, Parts, Petrol, Etc.), Australia, May 1982](https://hdl.handle.net/1885/733788712) | 1982-05 | matched by title and date | `07-retail-sales` |
| `RS1983-06x` | [Retail Sales of Goods (Excluding Motor Vehicles, Parts, Petrol, Etc.), Australia, June 1983](https://hdl.handle.net/1885/733788725) | 1983-06 | matched by title and date | `07-retail-sales` |

### The Labour Force

| Issue key | Title in the repository | Date | Match | Used in |
|---|---|---|---|---|
| `LF1979-05` | [The Labour Force, May 1979 (Preliminary)](https://hdl.handle.net/1885/733744793) | 1979-05 | matched by title and date | `01-job-vacancies` |

## Reserve Bank of Australia

- **Statistical tables** ([index](https://www.rba.gov.au/statistics/tables/)): [F1.1 interest rates](https://www.rba.gov.au/statistics/tables/xls/f01hist.xlsx), [F2 government bond yields](https://www.rba.gov.au/statistics/tables/xls/f02hist.xlsx), [F5 indicator lending rates](https://www.rba.gov.au/statistics/tables/xls/f05hist.xlsx), [D1 growth in financial aggregates](https://www.rba.gov.au/statistics/tables/xls/d01hist.xlsx), [D2 lending and credit aggregates](https://www.rba.gov.au/statistics/tables/xls/d02hist.xlsx), [D3 monetary aggregates](https://www.rba.gov.au/statistics/tables/xls/d03hist.xlsx), [G1 consumer price inflation](https://www.rba.gov.au/statistics/tables/xls/g01hist.xlsx), [G3 inflation expectations](https://www.rba.gov.au/statistics/tables/xls/g03hist.xlsx), [H3 building approvals](https://www.rba.gov.au/statistics/tables/xls/h03hist.xlsx).
- **Historical files**: [F2, 1969-2013 (f02histhist.xls)](https://www.rba.gov.au/statistics/tables/xls-hist/f02histhist.xls).
- **Occasional Paper No. 8**, *Australian Economic Statistics 1949-50 to 1996-97* ([tables page](https://www.rba.gov.au/statistics/frequency/occ-paper-8.html)). Tables used: [3.1](https://www.rba.gov.au/statistics/xls/op8/3-1.xls), [3.2](https://www.rba.gov.au/statistics/xls/op8/3-2.xls), [3.3](https://www.rba.gov.au/statistics/xls/op8/3-3.xls), [3.8](https://www.rba.gov.au/statistics/xls/op8/3-8.xls), [3.9](https://www.rba.gov.au/statistics/xls/op8/3-9.xls), [3.12](https://www.rba.gov.au/statistics/xls/op8/3-12.xls), [3.13](https://www.rba.gov.au/statistics/xls/op8/3-13.xls), [3.21a](https://www.rba.gov.au/statistics/xls/op8/3-21a.xls), [3.22a-b](https://www.rba.gov.au/statistics/xls/op8/3-22a-b.xls), [3.23](https://www.rba.gov.au/statistics/xls/op8/3-23.xls), [4.3](https://www.rba.gov.au/statistics/xls/op8/4-3.xls), [4.14](https://www.rba.gov.au/statistics/xls/op8/4-14.xls), [4.15](https://www.rba.gov.au/statistics/xls/op8/4-15.xls), [4.17](https://www.rba.gov.au/statistics/xls/op8/4-17.xls), [4.18](https://www.rba.gov.au/statistics/xls/op8/4-18.xls).
- **RBA Annual Report 1969**, *Australian Interest Rates and Security Yields* (printed report; quarterly 10-year bond yields Sep 1966 - Jun 1969).

## Australian Bureau of Statistics

| Catalogue | Publication | Link |
|---|---|---|
| 3101.0 | National, state and territory population | [latest release](https://www.abs.gov.au/statistics/people/population/national-state-and-territory-population/latest-release) |
| 3105.0.65.001 | Historical Population | [latest release](https://www.abs.gov.au/statistics/people/population/historical-population/latest-release) |
| 5206.0 | Australian National Accounts | [latest release](https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release) |
| 5601.0 | Lending Indicators | [latest release](https://www.abs.gov.au/statistics/economy/finance/lending-indicators/latest-release) |
| 5625.0 | Private New Capital Expenditure and Expected Expenditure | [latest release](https://www.abs.gov.au/statistics/economy/business-indicators/private-new-capital-expenditure-and-expected-expenditure-australia/latest-release) |
| 6202.0 | Labour Force | [latest release](https://www.abs.gov.au/statistics/labour/employment-and-unemployment/labour-force-australia/latest-release) |
| 6302.0 | Average Weekly Earnings | [latest release](https://www.abs.gov.au/statistics/labour/earnings-and-working-conditions/average-weekly-earnings-australia/latest-release) |
| 6345.0 | Wage Price Index | [latest release](https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/wage-price-index-australia/latest-release) |
| 6354.0 | Job Vacancies | [latest release](https://www.abs.gov.au/statistics/labour/jobs/job-vacancies-australia/latest-release) |
| 8501.0 | Retail Trade (ceased after June 2025) | [latest release](https://www.abs.gov.au/statistics/industry/retail-and-wholesale-trade/retail-trade-australia/latest-release) |
| 8731.0 | Building Approvals | [latest release](https://www.abs.gov.au/statistics/industry/building-and-construction/building-approvals-australia/latest-release) |
| 8752.0 | Building Activity | [latest release](https://www.abs.gov.au/statistics/industry/building-and-construction/building-activity-australia/latest-release) |

The release and table used for each file are given in `sources/data_raw_files.csv` and the folder READMEs. ABS material is used under the Creative Commons Attribution 4.0 International licence.

## OECD (via FRED)

- [LRUNTTTTAUM156S](https://fred.stlouisfed.org/series/LRUNTTTTAUM156S): Unemployment rate, monthly, SA (ABS 6202.0)
- [LFUNTTTTAUM647S](https://fred.stlouisfed.org/series/LFUNTTTTAUM647S): Unemployed, monthly, SA
- [LFACTTTTAUM647S](https://fred.stlouisfed.org/series/LFACTTTTAUM647S): Labour force, monthly, SA
- [LRHUTTTTAUQ156S](https://fred.stlouisfed.org/series/LRHUTTTTAUQ156S): Unemployment rate, quarterly, SA
- [LFHUTTTTAUQ647S](https://fred.stlouisfed.org/series/LFHUTTTTAUQ647S): Unemployed, quarterly, SA (1964-66)
- [LFACTTTTAUQ647S](https://fred.stlouisfed.org/series/LFACTTTTAUQ647S): Labour force, quarterly, SA
- [LMJVTTUVAUQ647S](https://fred.stlouisfed.org/series/LMJVTTUVAUQ647S): Job vacancies, quarterly, SA
- [LCEATT02AUQ661N](https://fred.stlouisfed.org/series/LCEATT02AUQ661N): Weekly earnings, all activities, index (ABS AWE)

## Internet Archive copies of RBA files

Older vintages of RBA files that the RBA no longer publishes in full:

- f02hist.xls, [14 Nov 2016](https://web.archive.org/web/20161114/https://www.rba.gov.au/statistics/tables/xls/f02hist.xls): indexed bond yields Jun 2013 - Oct 2014.
- g03hist.xls (inflation expectations): [2015-04-25](https://web.archive.org/web/20150425/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls), [2015-09-20](https://web.archive.org/web/20150920/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls), [2017-03-21](https://web.archive.org/web/20170321/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls), [2018-04-25](https://web.archive.org/web/20180425/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls), [2019-03-18](https://web.archive.org/web/20190318/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls), [2021-03-16](https://web.archive.org/web/20210316/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls), [2022-01-20](https://web.archive.org/web/20220120/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls), [2023-03-21](https://web.archive.org/web/20230321/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls).

## Newspapers (Trove)

CES unfilled vacancies for Jul 1979 - Jul 1980 (the bulletins stopped printing them) are from *The Canberra Times*, via the National Library of Australia's Trove: articles [110577795](https://trove.nla.gov.au/newspaper/article/110577795), [110600510](https://trove.nla.gov.au/newspaper/article/110600510), [110975431](https://trove.nla.gov.au/newspaper/article/110975431), [125608290](https://trove.nla.gov.au/newspaper/article/125608290), [125617739](https://trove.nla.gov.au/newspaper/article/125617739), [137011968](https://trove.nla.gov.au/newspaper/article/137011968) (dates and pages in `01-job-vacancies/data-raw/ces_1979_80_points.tsv`).

## Every `data-raw` file

| File | Source | Links | Provenance columns |
|---|---|---|---|
| [`01-job-vacancies/data-raw/abs_current_sa.tsv`](01-job-vacancies/data-raw/abs_current_sa.tsv) | ABS 6354.0 Job Vacancies, SA (and the OECD copy for early quarters) | [ABS release page](https://www.abs.gov.au/statistics/labour/jobs/job-vacancies-australia/latest-release) [LMJVTTUVAUQ647S](https://fred.stlouisfed.org/series/LMJVTTUVAUQ647S) | source |
| [`01-job-vacancies/data-raw/abs_overlap.tsv`](01-job-vacancies/data-raw/abs_overlap.tsv) | Early ABS job vacancy surveys as first published (Labour Statistics 1978; Job Vacancies bulletin Mar 1977) and ABS 6354.0 original | [ABS release page](https://www.abs.gov.au/statistics/labour/jobs/job-vacancies-australia/latest-release) | note |
| [`01-job-vacancies/data-raw/ces_1979_80_points.tsv`](01-job-vacancies/data-raw/ces_1979_80_points.tsv) | The Canberra Times reports of CES unfilled vacancies, Jul 1979 - Jul 1980 | https://trove.nla.gov.au/newspaper/article/<Trove id in the source column> | source |
| [`01-job-vacancies/data-raw/handles.tsv`](01-job-vacancies/data-raw/handles.tsv) | ANU handles of the Employment and Unemployment issues | https://hdl.handle.net/1885/<handle> | handle |
| [`01-job-vacancies/data-raw/raw.tsv`](01-job-vacancies/data-raw/raw.tsv) | CBCS/ABS Employment and Unemployment bulletins, CES unfilled vacancies by sex | ANU scans: see the issue tables above | issue, page |
| [`01-job-vacancies/data-raw/raw_adult_junior.tsv`](01-job-vacancies/data-raw/raw_adult_junior.tsv) | CBCS/ABS Employment and Unemployment (1977-78) and The Labour Force (May 1979), CES vacancies, adults/juniors | ANU scans: see the issue tables above | issue, page |
| [`02-beveridge-curve/data-raw/ces_registered_raw.tsv`](02-beveridge-curve/data-raw/ces_registered_raw.tsv) | Employment and Unemployment bulletins, CES registered unemployed | ANU scans: see the issue tables above | issue, page |
| [`02-beveridge-curve/data-raw/ces_registered_revdef.tsv`](02-beveridge-curve/data-raw/ces_registered_revdef.tsv) | Employment and Unemployment bulletins, CES registered unemployed (revised definition, from Jul 1973) | ANU scans: see the issue tables above | issue, page |
| [`02-beveridge-curve/data-raw/labour_force_quarterly.tsv`](02-beveridge-curve/data-raw/labour_force_quarterly.tsv) | ABS Labour Force (6202.0) via OECD/FRED, quarterly; current ABS release for the latest quarter | [LRHUTTTTAUQ156S](https://fred.stlouisfed.org/series/LRHUTTTTAUQ156S) [LFACTTTTAUQ647S](https://fred.stlouisfed.org/series/LFACTTTTAUQ647S) [ABS release page](https://www.abs.gov.au/statistics/labour/employment-and-unemployment/labour-force-australia/latest-release) | source |
| [`02-beveridge-curve/data-raw/lf_raw.txt`](02-beveridge-curve/data-raw/lf_raw.txt) | FRED download, labour force (quarterly) | [LFACTTTTAUQ647S](https://fred.stlouisfed.org/series/LFACTTTTAUQ647S) | none |
| [`02-beveridge-curve/data-raw/oecd_lfs_1964_66.tsv`](02-beveridge-curve/data-raw/oecd_lfs_1964_66.tsv) | OECD Main Economic Indicators via FRED, unemployed and labour force, pre-Aug-1966 survey basis | [LFHUTTTTAUQ647S](https://fred.stlouisfed.org/series/LFHUTTTTAUQ647S) [LFACTTTTAUQ647S](https://fred.stlouisfed.org/series/LFACTTTTAUQ647S) | note |
| [`02-beveridge-curve/data-raw/rba_op8_historical.tsv`](02-beveridge-curve/data-raw/rba_op8_historical.tsv) | RBA Occasional Paper 8, tables 4.3, 4.14, 4.15 (labour force, vacancies, unemployment) | [OP8 page](https://www.rba.gov.au/statistics/frequency/occ-paper-8.html) [4-3.xls](https://www.rba.gov.au/statistics/xls/op8/4-3.xls) [4-14.xls](https://www.rba.gov.au/statistics/xls/op8/4-14.xls) [4-15.xls](https://www.rba.gov.au/statistics/xls/op8/4-15.xls) | none (table named in the README) |
| [`02-beveridge-curve/data-raw/u_rate_raw.txt`](02-beveridge-curve/data-raw/u_rate_raw.txt) | FRED download, unemployment rate (quarterly) | [LRHUTTTTAUQ156S](https://fred.stlouisfed.org/series/LRHUTTTTAUQ156S) | none |
| [`03-building-approvals/data-raw/abs_dwellings_approved.tsv`](03-building-approvals/data-raw/abs_dwellings_approved.tsv) | ABS 8731.0 Building Approvals, Table 6 | [ABS release page](https://www.abs.gov.au/statistics/industry/building-and-construction/building-approvals-australia/latest-release) | none |
| [`03-building-approvals/data-raw/ba_long.tsv`](03-building-approvals/data-raw/ba_long.tsv) | CBCS/ABS Building Approvals, Australia, Jun 1967 - Dec 1985 issues | ANU scans: see the issue tables above | issue, page |
| [`03-building-approvals/data-raw/ba_raw.tsv`](03-building-approvals/data-raw/ba_raw.tsv) | CBCS/ABS Building Approvals, Australia, Dec 1962, 1965, 1966 issues | ANU scans: see the issue tables above | issue, page |
| [`03-building-approvals/data-raw/rba_h3_private_approvals_sa.tsv`](03-building-approvals/data-raw/rba_h3_private_approvals_sa.tsv) | RBA table H3, private dwelling approvals, SA | [h03hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/h03hist.xlsx) | none |
| [`04-housing-pipeline/data-raw/abs_starts_completions.tsv`](04-housing-pipeline/data-raw/abs_starts_completions.tsv) | ABS 8752.0 Building Activity, Tables 33 and 37 | [ABS release page](https://www.abs.gov.au/statistics/industry/building-and-construction/building-activity-australia/latest-release) | none |
| [`04-housing-pipeline/data-raw/qb_raw.tsv`](04-housing-pipeline/data-raw/qb_raw.tsv) | CBCS Quarterly Bulletin of Building Statistics, December issues 1948-1957 | ANU scans: see the issue tables above | issue |
| [`05-housing-per-capita/data-raw/pop_erp_quarterly.tsv`](05-housing-per-capita/data-raw/pop_erp_quarterly.tsv) | ABS 3101.0, Table 4, ERP Australia, quarterly | [ABS release page](https://www.abs.gov.au/statistics/people/population/national-state-and-territory-population/latest-release) | none |
| [`05-housing-per-capita/data-raw/pop_hist_age_june.tsv`](05-housing-per-capita/data-raw/pop_hist_age_june.tsv) | ABS 3105.0.65.001 (HPDC2 Table 1) and ABS 3101.0 Table 59, population by age at 30 June | [ABS release page](https://www.abs.gov.au/statistics/people/population/historical-population/latest-release) [ABS release page](https://www.abs.gov.au/statistics/people/population/national-state-and-territory-population/latest-release) | source |
| [`05-housing-per-capita/data-raw/pop_hist_total_halfyear.tsv`](05-housing-per-capita/data-raw/pop_hist_total_halfyear.tsv) | ABS 3105.0.65.001 Historical Population, 30 June and 31 December 1944-1982 | [ABS release page](https://www.abs.gov.au/statistics/people/population/historical-population/latest-release) | none |
| [`06-capex/data-raw/abs_capex_fy_expectations.csv`](06-capex/data-raw/abs_capex_fy_expectations.csv) | ABS 5625.0, Table 17, expectations E1-E7 | [ABS release page](https://www.abs.gov.au/statistics/economy/business-indicators/private-new-capital-expenditure-and-expected-expenditure-australia/latest-release) | none |
| [`06-capex/data-raw/abs_capex_quarterly.csv`](06-capex/data-raw/abs_capex_quarterly.csv) | ABS 5625.0 Private New Capital Expenditure, by asset and industry | [ABS release page](https://www.abs.gov.au/statistics/economy/business-indicators/private-new-capital-expenditure-and-expected-expenditure-australia/latest-release) | none |
| [`06-capex/data-raw/abs_gdp_ipd_quarterly.tsv`](06-capex/data-raw/abs_gdp_ipd_quarterly.tsv) | ABS 5206.0 National Accounts: nominal GDP (SA) and investment deflators | [ABS release page](https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release) | none |
| [`06-capex/data-raw/abs_na_business_investment.tsv`](06-capex/data-raw/abs_na_business_investment.tsv) | ABS 5206.0: private non-dwelling construction and machinery and equipment | [ABS release page](https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release) | none |
| [`06-capex/data-raw/abs_short_term_expected_half.tsv`](06-capex/data-raw/abs_short_term_expected_half.tsv) | ABS 5625.0, Table 2, short-term expectations | [ABS release page](https://www.abs.gov.au/statistics/economy/business-indicators/private-new-capital-expenditure-and-expected-expenditure-australia/latest-release) | none |
| [`06-capex/data-raw/cx_anticipated_pct.tsv`](06-capex/data-raw/cx_anticipated_pct.tsv) | Capex bulletins, anticipated vs actual half-yearly changes 1961-69 | ANU scans: see the issue tables above | issue_key |
| [`06-capex/data-raw/cx_expect_raw.tsv`](06-capex/data-raw/cx_expect_raw.tsv) | Capex bulletins, next-quarter and next-six-months expectations 1965-90 | ANU scans: see the issue tables above | issue_key |
| [`06-capex/data-raw/cx_fy_expect_raw.tsv`](06-capex/data-raw/cx_fy_expect_raw.tsv) | Capex bulletins, financial-year expectations (1986, 1990, 1992 issues) | ANU scans: see the issue tables above | issue_key |
| [`06-capex/data-raw/cx_half_antic.tsv`](06-capex/data-raw/cx_half_antic.tsv) | Capex bulletins, anticipated and actual half-year levels 1969-77 | ANU scans: see the issue tables above | issue_key |
| [`06-capex/data-raw/cx_raw.tsv`](06-capex/data-raw/cx_raw.tsv) | CBCS/ABS capital expenditure survey bulletins, quarterly actuals 1961-1992 | ANU scans: see the issue tables above | issue_key, issue_title, page |
| [`06-capex/data-raw/sa_printed.tsv`](06-capex/data-raw/sa_printed.tsv) | Capex bulletins, printed seasonally adjusted totals | ANU scans: see the issue tables above | issue_key, page |
| [`07-retail-sales/data-raw/abs_retail_8501.tsv`](07-retail-sales/data-raw/abs_retail_8501.tsv) | ABS 8501.0 Retail Trade (June 2025), Table 1 | [ABS release page](https://www.abs.gov.au/statistics/industry/retail-and-wholesale-trade/retail-trade-australia/latest-release) | none |
| [`07-retail-sales/data-raw/rba_g1_cpi_quarterly.tsv`](07-retail-sales/data-raw/rba_g1_cpi_quarterly.tsv) | RBA table G1, CPI | [g01hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/g01hist.xlsx) | none |
| [`07-retail-sales/data-raw/rs_raw.tsv`](07-retail-sales/data-raw/rs_raw.tsv) | CBCS/ABS Retail Sales of Goods / Survey of Retail Establishments bulletins (1953-1983) and Quarterly Summary of Australian Statistics Nos 226, 238, 254 | ANU scans: see the issue tables above | issue, issue_date, page |
| [`08-money-credit-rates/data-raw/anu_bank_loans_monthly.csv`](08-money-credit-rates/data-raw/anu_bank_loans_monthly.csv) | CBCS/ABS Australian Banking Statistics monthly bulletin, Banking Statistics, Banking, and major trading banks preliminary statements | ANU scans: see the issue tables above | issue, page |
| [`08-money-credit-rates/data-raw/anu_instalment_credit.csv`](08-money-credit-rates/data-raw/anu_instalment_credit.csv) | CBCS hire purchase and Instalment Credit for Retail Sales bulletins, 1958-1972 | ANU scans: see the issue tables above | issue, page |
| [`08-money-credit-rates/data-raw/anu_savings_bank_loans_monthly.csv`](08-money-credit-rates/data-raw/anu_savings_bank_loans_monthly.csv) | CBCS/ABS Banking Statistics (1971-74) and Banking (1975-76), savings bank assets tables | ANU scans: see the issue tables above | issue, page |
| [`08-money-credit-rates/data-raw/op8_3_12_building_societies_june.csv`](08-money-credit-rates/data-raw/op8_3_12_building_societies_june.csv) | RBA Occasional Paper 8, table 3.12 (permanent building societies) | [3-12.xls](https://www.rba.gov.au/statistics/xls/op8/3-12.xls) | note |
| [`08-money-credit-rates/data-raw/op8_3_13_finance_companies_june.csv`](08-money-credit-rates/data-raw/op8_3_13_finance_companies_june.csv) | RBA Occasional Paper 8, table 3.13 (finance companies) | [3-13.xls](https://www.rba.gov.au/statistics/xls/op8/3-13.xls) | note |
| [`08-money-credit-rates/data-raw/op8_3_1_money_june.csv`](08-money-credit-rates/data-raw/op8_3_1_money_june.csv) | RBA Occasional Paper 8, table 3.1 (monetary aggregates) | [3-1.xls](https://www.rba.gov.au/statistics/xls/op8/3-1.xls) | none |
| [`08-money-credit-rates/data-raw/op8_3_2_credit_june.csv`](08-money-credit-rates/data-raw/op8_3_2_credit_june.csv) | RBA Occasional Paper 8, table 3.2 (credit) | [3-2.xls](https://www.rba.gov.au/statistics/xls/op8/3-2.xls) | note |
| [`08-money-credit-rates/data-raw/op8_3_2_lending_banks_nbfi_june.csv`](08-money-credit-rates/data-raw/op8_3_2_lending_banks_nbfi_june.csv) | RBA Occasional Paper 8, table 3.2 (lending by banks and non-banks) | [3-2.xls](https://www.rba.gov.au/statistics/xls/op8/3-2.xls) | note |
| [`08-money-credit-rates/data-raw/op8_3_8_trading_banks_june.csv`](08-money-credit-rates/data-raw/op8_3_8_trading_banks_june.csv) | RBA Occasional Paper 8, table 3.8 (trading banks) | [3-8.xls](https://www.rba.gov.au/statistics/xls/op8/3-8.xls) | note |
| [`08-money-credit-rates/data-raw/op8_3_9_savings_banks_june.csv`](08-money-credit-rates/data-raw/op8_3_9_savings_banks_june.csv) | RBA Occasional Paper 8, table 3.9 (savings banks) | [3-9.xls](https://www.rba.gov.au/statistics/xls/op8/3-9.xls) | note |
| [`08-money-credit-rates/data-raw/op8_rates_annual.csv`](08-money-credit-rates/data-raw/op8_rates_annual.csv) | RBA Occasional Paper 8, tables 3.21a, 3.22a, 3.22b, 3.23 (interest rates) | [3-21a.xls](https://www.rba.gov.au/statistics/xls/op8/3-21a.xls) [3-22a-b.xls](https://www.rba.gov.au/statistics/xls/op8/3-22a-b.xls) [3-23.xls](https://www.rba.gov.au/statistics/xls/op8/3-23.xls) | none |
| [`08-money-credit-rates/data-raw/rba_ar1969_quarterly.csv`](08-money-credit-rates/data-raw/rba_ar1969_quarterly.csv) | RBA Annual Report 1969, Australian Interest Rates and Security Yields | (printed report) | source |
| [`08-money-credit-rates/data-raw/rba_credit_anchors.csv`](08-money-credit-rates/data-raw/rba_credit_anchors.csv) | RBA D2, latest credit levels | [d02hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/d02hist.xlsx) | none |
| [`08-money-credit-rates/data-raw/rba_d2_bank_loans_1976_81.csv`](08-money-credit-rates/data-raw/rba_d2_bank_loans_1976_81.csv) | RBA D2, lending by all banks (DLCALAB) | [d02hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/d02hist.xlsx) | none |
| [`08-money-credit-rates/data-raw/rba_f2_indexed_bond_monthly.csv`](08-money-credit-rates/data-raw/rba_f2_indexed_bond_monthly.csv) | RBA F2: historical file, current file, and the 14 Nov 2016 copy of f02hist.xls | [f02histhist.xls](https://www.rba.gov.au/statistics/tables/xls-hist/f02histhist.xls) [f02hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/f02hist.xlsx) [archived 20161114](https://web.archive.org/web/20161114/https://www.rba.gov.au/statistics/tables/xls/f02hist.xls) | source |
| [`08-money-credit-rates/data-raw/rba_g1_cpi_quarterly.tsv`](08-money-credit-rates/data-raw/rba_g1_cpi_quarterly.tsv) | RBA table G1, CPI | [g01hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/g01hist.xlsx) | none |
| [`08-money-credit-rates/data-raw/rba_g3_inflation_expectations.csv`](08-money-credit-rates/data-raw/rba_g3_inflation_expectations.csv) | RBA G3: current file and copies of g03hist.xls 2015-2023 (Internet Archive) | [g03hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/g03hist.xlsx) [archived 20150425](https://web.archive.org/web/20150425/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls) [archived 20150920](https://web.archive.org/web/20150920/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls) [archived 20170321](https://web.archive.org/web/20170321/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls) [archived 20180425](https://web.archive.org/web/20180425/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls) [archived 20190318](https://web.archive.org/web/20190318/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls) [archived 20210316](https://web.archive.org/web/20210316/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls) [archived 20220120](https://web.archive.org/web/20220120/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls) [archived 20230321](https://web.archive.org/web/20230321/https://www.rba.gov.au/statistics/tables/xls/g03hist.xls) | source |
| [`08-money-credit-rates/data-raw/rba_monthly.csv`](08-money-credit-rates/data-raw/rba_monthly.csv) | RBA tables F1.1, F2, F5, D1, D2, D3 (series ids as column names) | [f01hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/f01hist.xlsx) [f02hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/f02hist.xlsx) [f05hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/f05hist.xlsx) [d01hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/d01hist.xlsx) [d02hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/d02hist.xlsx) [d03hist.xlsx](https://www.rba.gov.au/statistics/tables/xls/d03hist.xlsx) [f02histhist.xls](https://www.rba.gov.au/statistics/tables/xls-hist/f02histhist.xls) | column names = RBA series ids |
| [`09-unemployment/data-raw/ces_benefit_raw.csv`](09-unemployment/data-raw/ces_benefit_raw.csv) | CBCS Monthly Bulletin of Employment Statistics (1952-63) and Employment and Unemployment (1963-75): CES registrations and unemployment benefit | ANU scans: see the issue tables above | issue, page, table |
| [`09-unemployment/data-raw/lfs_monthly_sa_fred.csv`](09-unemployment/data-raw/lfs_monthly_sa_fred.csv) | ABS Labour Force (6202.0) via OECD/FRED, monthly SA | [LRUNTTTTAUM156S](https://fred.stlouisfed.org/series/LRUNTTTTAUM156S) [LFUNTTTTAUM647S](https://fred.stlouisfed.org/series/LFUNTTTTAUM647S) [LFACTTTTAUM647S](https://fred.stlouisfed.org/series/LFACTTTTAUM647S) | none |
| [`10-wages/data-raw/abs_6302_awe_original.csv`](10-wages/data-raw/abs_6302_awe_original.csv) | ABS 6302.0 Average Weekly Earnings (May 2026), Table 3 | [ABS release page](https://www.abs.gov.au/statistics/labour/earnings-and-working-conditions/average-weekly-earnings-australia/latest-release) | none |
| [`10-wages/data-raw/abs_6345_wpi_sa.csv`](10-wages/data-raw/abs_6345_wpi_sa.csv) | ABS 6345.0 Wage Price Index (Jun 2026), Table 1 | [ABS release page](https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/wage-price-index-australia/latest-release) | none |
| [`10-wages/data-raw/anu_awe_quarterly.csv`](10-wages/data-raw/anu_awe_quarterly.csv) | CBCS Labour Reports 48, 55, 58 and Digest of Current Economic Statistics (1976-84), quarterly earnings | ANU scans: see the issue tables above | issue, page |
| [`10-wages/data-raw/oecd_fred_weekly_earnings_quarterly.csv`](10-wages/data-raw/oecd_fred_weekly_earnings_quarterly.csv) | OECD Main Economic Indicators, weekly earnings, all activities (via FRED) | [LCEATT02AUQ661N](https://fred.stlouisfed.org/series/LCEATT02AUQ661N) | none |
| [`10-wages/data-raw/op8_4_17_wages_annual.csv`](10-wages/data-raw/op8_4_17_wages_annual.csv) | RBA Occasional Paper 8, table 4.17 (wages and earnings) | [4-17.xls](https://www.rba.gov.au/statistics/xls/op8/4-17.xls) | none |
| [`10-wages/data-raw/op8_4_18_awe_survey.csv`](10-wages/data-raw/op8_4_18_awe_survey.csv) | RBA Occasional Paper 8, table 4.18 (AWE survey) | [4-18.xls](https://www.rba.gov.au/statistics/xls/op8/4-18.xls) | none |
| [`11-housing-finance/data-raw/abs_5601_owner_occupier_commitments_fy.csv`](11-housing-finance/data-raw/abs_5601_owner_occupier_commitments_fy.csv) | ABS 5601.0 Lending Indicators, Table 1 (summed to financial years) | [ABS release page](https://www.abs.gov.au/statistics/economy/finance/lending-indicators/latest-release) | none |
| [`11-housing-finance/data-raw/op8_3_3_housing_finance_commitments.csv`](11-housing-finance/data-raw/op8_3_3_housing_finance_commitments.csv) | RBA Occasional Paper 8, table 3.3 (housing finance commitments) | [3-3.xls](https://www.rba.gov.au/statistics/xls/op8/3-3.xls) | note |
