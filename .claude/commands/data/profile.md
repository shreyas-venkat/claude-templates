---
description: Profile a table — nulls, distributions, duplicates, and anomalies
---

Profile table: $ARGUMENTS

Run a full data quality profile via MotherDuck MCP.

**1. Overview**
```sql
SELECT COUNT(*) AS rows, COUNT(DISTINCT <pk>) AS unique_pks FROM <table>;
```

**2. Column-level null rates**
```sql
SELECT
  '<col>' AS column_name,
  ROUND(100.0 * SUM(CASE WHEN <col> IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS null_pct
FROM <table>
```
(Generate this for all columns)

**3. Numeric column distributions**
```sql
SELECT
  MIN(<col>), MAX(<col>), AVG(<col>),
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY <col>) AS p25,
  PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY <col>) AS median,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY <col>) AS p75,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY <col>) AS p99
FROM <table>;
```

**4. Categorical column frequencies**
Top 10 values for each string/enum column.

**5. Duplicate check**
```sql
SELECT <pk>, COUNT(*) AS n FROM <table> GROUP BY 1 HAVING COUNT(*) > 1;
```

**6. Date gaps** (if a date column exists)
Check for unexpected gaps in the time series.

**Large table guard:** If row count > 100M, add `USING SAMPLE 1000000` to distribution and null queries to avoid timeouts.

Produce a summary scorecard using these consistent thresholds:

| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Null rate per column | < 1% | 1–10% | > 10% |
| Duplicate PK rows | 0 | — | any |
| Columns missing from schema | 0 | — | any |
| Outlier (value > p99 × 10) | none | — | any |
| Date gap (missing > 1 expected period) | none | — | any |

Overall health: 🟢 all green / 🟡 any yellow / 🔴 any red
