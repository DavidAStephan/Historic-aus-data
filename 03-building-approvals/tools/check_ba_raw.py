# Consistency checks for data-raw/ba_raw.tsv: month sums vs printed year totals,
# private + government = total, and agreement between issues. Run from 03-building-approvals/.
import csv,sys
rows=list(csv.DictReader(open(sys.argv[1] if len(sys.argv)>1 else 'data-raw/ba_raw.tsv'),delimiter='\t'))
M=['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec']
by={}
for r in rows: by[(r['issue'],r['year'],r['series'])]=r
bad=0
for r in rows:
    v=[r[m] for m in M]
    if all(v) and r['year_total']:
        s=sum(int(x) for x in v)
        if s!=int(r['year_total']): print('SUM',r['issue'],r['year'],r['series'],s,r['year_total'],s-int(r['year_total'])); bad+=1
for (iss,y,s),r in by.items():
    if s!='total': continue
    p=by.get((iss,y,'private')); g=by.get((iss,y,'government'))
    if not p or not g: continue
    for m in M+['year_total']:
        if r[m] and p[m] and g[m] and int(p[m])+int(g[m])!=int(r[m]): print('PG',iss,y,m,p[m],g[m],r[m]); bad+=1
# cross issue
from collections import defaultdict
seen=defaultdict(set)
for r in rows:
    if r['series']=='total': continue
    for m in M:
        if r[m]: seen[(r['year'],r['series'],m)].add((r[m],r['issue']))
for k,v in seen.items():
    if len({x[0] for x in v})>1: print('XISSUE',k,sorted(v)); bad+=1
print('rows',len(rows),'problems',bad)
