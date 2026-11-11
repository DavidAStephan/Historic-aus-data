# CES registered job vacancies, Australia, 1962-1979
# ---------------------------------------------------
# Compiles the "Vacancies registered with the Commonwealth Employment Service"
# tables transcribed from scanned ABS/Commonwealth Bureau of Census and Statistics
# bulletins "Employment and Unemployment" (ref. no. 6.22 / cat. 6213.0), digitised
# by ANU Open Research (https://openresearch-repository.anu.edu.au).
#
# Inputs  (tab-separated, one row per printed table row, as transcribed):
#   raw.tsv              Australia totals by sex: males, females, total (original series)
#   raw_adult_junior.tsv 1976-78 issues, which split by adults/juniors instead of sex,
#                        plus ABS 'The Labour Force' May 1979 (6203.0, Table 25), which
#                        carried the CES table to May 1979
#   handles.tsv          ANU handle for each bulletin issue
# Output:
#   ces_vacancies_monthly.csv  one row per reference month
#   ces_vacancies.png          chart
#
# Definition (footnote to the tables): vacancies notified to the CES that were still
# unfilled at the Friday nearest the end of the month and which employers said could
# be filled immediately or by the end of the following month. Original
# (not seasonally adjusted) series. Includes full-time, part-time, permanent,
# temporary and seasonal positions.
# Run from this analysis folder (the folder that contains R/), e.g.  Rscript R/build_ces_vacancies.R
#   inputs in data-raw/, outputs written to output/

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(ggplot2)
})

rd <- function(f) read_tsv(f, col_types = cols(.default = "c"), na = "") |> suppressWarnings()

sex <- rd("data-raw/raw.tsv") |>
  mutate(across(c(males, females, total), as.integer))
aj  <- rd("data-raw/raw_adult_junior.tsv") |>
  mutate(across(c(adults, juniors, total), as.integer))
handles <- rd("data-raw/handles.tsv") |> filter(series %in% c("EU", "LF")) |> select(issue = label, handle)

# --- Reference month ---------------------------------------------------------
# 1960s issues print the actual Friday (e.g. "2 July 1965" = the June 1965 count,
# because it is the Friday nearest the end of June). Later issues print the month.
to_month <- function(lbl) {
  out <- as.Date(rep(NA, length(lbl)))
  m <- nchar(lbl) == 7
  out[m] <- as.Date(paste0(lbl[m], "-01"))
  d <- as.Date(lbl[!m])
  day <- as.integer(format(d, "%d"))
  first <- as.Date(format(d, "%Y-%m-01"))
  # day <= 7 -> the Friday belongs to the previous month's end
  prev <- as.Date(format(first - 1, "%Y-%m-01"))
  out[!m] <- if_else(day <= 7, prev, first)
  out
}

# Issue order: the later issue wins where months are printed more than once,
# because later issues carry revisions.
issue_key <- function(x) as.Date(paste0(regmatches(x, regexpr("[0-9]{4}-[0-9]{2}", x)), "-01"))

sex <- sex |>
  mutate(month = to_month(date_label),
         reference_date = if_else(nchar(date_label) == 10, date_label, NA_character_),
         sum_check = males + females - total)
aj <- aj |>
  mutate(month = to_month(date_label),
         sum_check = adults + juniors - total)

# --- Consistency checks ------------------------------------------------------
cat("Rows where males + females != printed total:\n")
print(filter(sex, sum_check != 0) |> select(issue, date_label, males, females, total, sum_check))
cat("\nRows where adults + juniors != printed total:\n")
print(filter(aj, sum_check != 0) |> select(issue, date_label, adults, juniors, total, sum_check))

# Months printed in more than one issue with different totals (revisions / misprints)
both <- bind_rows(select(sex, issue, month, total), select(aj, issue, month, total))
conflicts <- both |>
  group_by(month) |>
  filter(n_distinct(total) > 1) |>
  arrange(month, issue_key(issue))
cat("\nMonths whose printed total differs between issues:\n")
print(conflicts, n = Inf)

# --- Keep the latest issue for each month -------------------------------------
pick_latest <- function(df) df |>
  group_by(month) |>
  slice_max(issue_key(issue), n = 1, with_ties = FALSE) |>
  ungroup()

sex_l <- pick_latest(sex)
aj_l  <- pick_latest(aj)

monthly <- full_join(
  select(sex_l, month, reference_date, males, females, total_sex = total,
         issue_sex = issue, page_sex = page, note_sex = note),
  select(aj_l, month, adults, juniors, total_aj = total,
         issue_aj = issue, page_aj = page, note_aj = note),
  by = "month") |>
  mutate(
    # The adult/junior tables (1976-78 issues) are the latest print for 1976 onwards
    use_aj = !is.na(total_aj),
    vacancies = if_else(use_aj, total_aj, total_sex),
    source_issue = if_else(use_aj, issue_aj, issue_sex),
    source_page  = if_else(use_aj, page_aj, page_sex),
    note = coalesce(if_else(use_aj, note_aj, note_sex), "")
  ) |>
  left_join(handles, by = c("source_issue" = "issue")) |>
  mutate(source_url = if_else(startsWith(handle, "http"), handle, paste0("https://hdl.handle.net/1885/", handle)),
         note = na_if(note, "")) |>
  arrange(month) |>
  select(month, vacancies, males, females, adults, juniors,
         reference_date, source_issue, source_page, source_url, note)

# Flag the annual June-only observations before monthly coverage begins
monthly <- monthly |>
  mutate(frequency = case_when(month >= as.Date("1965-12-01") ~ "monthly",
                               month <= as.Date("1965-06-01") ~ "June only",
                               TRUE ~ "isolated month"),
         .after = vacancies)

# --- Coverage report ----------------------------------------------------------
all_months <- seq(as.Date("1965-12-01"), max(monthly$month), by = "month")
missing <- setdiff(all_months, monthly$month)
cat("\nMonthly coverage", format(min(all_months)), "to", format(max(monthly$month)),
    "- missing months:", if (length(missing)) format(as.Date(missing, origin = "1970-01-01")) else "none", "\n")
cat("Rows written:", nrow(monthly), "\n")

write_csv(monthly, "output/ces_vacancies_monthly.csv", na = "")

# --- Chart ---------------------------------------------------------------------
p <- ggplot(monthly, aes(month, vacancies / 1000)) +
  geom_line(data = filter(monthly, month >= as.Date("1965-12-01")),
            colour = "#1f5aa6", linewidth = 0.7) +
  geom_point(data = filter(monthly, month < as.Date("1965-12-01")),
             colour = "#1f5aa6", size = 2) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(title = "Job vacancies registered with the Commonwealth Employment Service",
       subtitle = "Australia, unfilled at end of month, original series ('000). Points before Dec 1965: June 1962-65 and July 1965 only.",
       x = NULL, y = "Vacancies ('000)",
       caption = "Source: ABS/CBCS 'Employment and Unemployment' bulletins (scans via ANU Open Research); compiled from printed tables.") +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot")

ggsave("output/ces_vacancies.png", p, width = 9, height = 4.8, dpi = 200, bg = "white")
