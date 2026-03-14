---
description: Write and run a SQL query against MotherDuck
---

Write and run a SQL query: $ARGUMENTS

Steps:
1. If a database or table name is mentioned, first inspect its schema:
   ```sql
   DESCRIBE <table>;
   -- or
   SELECT * FROM information_schema.columns WHERE table_name = '<table>';
   ```
2. Write the query to answer the question in $ARGUMENTS
3. Apply DuckDB-specific idioms where useful:
   - `COLUMNS(*)` for wildcard column selection
   - `PIVOT` / `UNPIVOT` for reshaping
   - `ASOF JOIN` for time-series nearest-match joins
   - `read_parquet()`, `read_csv_auto()` for direct file queries
   - Window functions for running totals, ranks, etc.
4. Run the query via MotherDuck MCP
5. Present the results clearly — use a table for small results, summary stats for large ones

If the result is empty or unexpected, explain why and suggest a corrected query.

Add a comment at the top of the query explaining what it answers.
