---
description: Explore a table or dataset — schema, samples, and basic stats
---

Explore dataset: $ARGUMENTS

**Before running any query:** Check row count first with `SELECT COUNT(*) FROM <table>`. If > 10M rows, append `USING SAMPLE 100000` to all full-table scans to avoid timeouts.

Run each of the following against MotherDuck and present the results:

**Schema**
```sql
DESCRIBE <table>;
```

**Row count and date range**
```sql
SELECT
  COUNT(*) AS row_count,
  MIN(<date_col>) AS earliest,
  MAX(<date_col>) AS latest
FROM <table>;
```

**Sample rows**
```sql
SELECT * FROM <table> USING SAMPLE 10;
```

**Null summary**
```sql
SELECT
  COUNT(*) AS total_rows,
  <for each column>: SUM(CASE WHEN <col> IS NULL THEN 1 ELSE 0 END) AS <col>_nulls
FROM <table>;
```

**Cardinality of key columns**
```sql
SELECT <col>, COUNT(*) AS n FROM <table> GROUP BY 1 ORDER BY 2 DESC LIMIT 20;
```

Summarize findings:
- What is the grain of this table?
- Any data quality concerns (nulls, duplicates, gaps)?
- What are the most useful columns for analysis?
- What questions does this data seem designed to answer?
