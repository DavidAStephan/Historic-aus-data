# Cross-check: our private dwelling approvals (SA) vs RBA statistical table H3 (ABS series GISPSDA),
# Jan 1965 - Dec 1990. Run from 03-building-approvals/:  Rscript R/check_vs_rba_h3.R
suppressPackageStartupMessages({library(readr);library(dplyr);library(ggplot2)})
r <- read_tsv("data-raw/rba_h3_private_approvals_sa.tsv", show_col_types=FALSE)
o <- read_csv("output/dwelling_approvals_spliced_monthly.csv", show_col_types=FALSE)
j <- inner_join(r, select(o, month, private_sa, private_orig, source), by="month") |>
  mutate(ratio = private_sa.y / private_sa.x, g_r = 100*(private_sa.x/lag(private_sa.x)-1), g_o = 100*(private_sa.y/lag(private_sa.y)-1),
         yr=as.integer(substr(month,1,4)))
s <- j |> mutate(period=case_when(yr<1975~"1965-74 (combined basis, scaled)", yr<1983 | month<"1983-07"~"1975-Jun 1983 (bulletins, new basis)", TRUE~"Jul 1983-1990 (ABS 8731.0)")) |>
  group_by(period) |> summarise(n=n(), mean_ratio=round(mean(ratio),3), min=round(min(ratio),3), max=round(max(ratio),3),
                                 mad_pct=round(100*mean(abs(ratio-1)),1), growth_corr=round(cor(g_r,g_o,use="complete"),2), .groups="drop")
print(s)
ann <- j |> group_by(yr) |> summarise(rba=sum(private_sa.x), ours=sum(private_sa.y), r=round(ours/rba,3)) 
print(ann, n=Inf)
# ratio around Nov 1974 break
print(j |> filter(month>="1974-06", month<="1975-06") |> select(month, rba=private_sa.x, ours=private_sa.y, ratio) |> mutate(ratio=round(ratio,3)))
write_csv(ann, "check_vs_rba/approvals_vs_rba_h3_annual.csv")
p <- ggplot(bind_rows(transmute(j, d=as.Date(paste0(month,"-01")), s="RBA H3 (ABS, SA)", v=private_sa.x/1000),
                      transmute(j, d=as.Date(paste0(month,"-01")), s="Ours (03-building-approvals, SA)", v=private_sa.y/1000)),
            aes(d, v, colour=s)) + geom_line(linewidth=0.5) +
  scale_colour_manual(values=c("#c0392b","#1f5aa6"), name=NULL) + scale_x_date(date_breaks="5 years", date_labels="%Y") +
  labs(title="Private dwelling approvals: ours vs RBA table H3, 1965-1990", subtitle="Seasonally adjusted, '000 per month", x=NULL, y="'000") +
  theme_minimal(base_size=11) + theme(legend.position="top", legend.justification="left", panel.grid.minor=element_blank(), plot.title.position="plot")
ggsave("check_vs_rba/approvals_vs_rba_h3.png", p, width=10, height=4.8, dpi=200, bg="white")
