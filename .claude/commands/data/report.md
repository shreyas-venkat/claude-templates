---
description: Generate a structured data analysis report
---

Generate a data report on: $ARGUMENTS

**Structure the report as follows:**

## Executive Summary
2–3 sentences: what was analyzed, key finding, recommended action.

## Methodology
- Data source(s) and time range
- Any filters or exclusions applied
- Key assumptions

## Key Metrics
Present the most important numbers in a table or as callouts.
Run the supporting queries via MotherDuck MCP and pull real numbers.

## Findings
For each insight:
- **Finding**: what the data shows
- **Evidence**: the supporting number(s) or trend
- **So what**: why this matters

## Trends
If time-series data is available, show period-over-period changes (WoW, MoM, YoY).

## Anomalies / Watch Items
Anything that looks unexpected and warrants investigation.

## Recommended Actions
Numbered list, prioritized.

---

**Rules:**
- If the data is inconclusive on a point, say "The data does not support a conclusion on X" — do not speculate
- If a section has no data to support it (e.g. no time-series for Trends), omit that section and note why
- If queries return no rows or unexpected nulls, investigate before drawing conclusions — mention the data quality issue in Methodology
- Keep it factual and data-grounded. Don't editorialize beyond what the data supports.
