---
description: Write dbt model documentation in schema.yml — model descriptions, column descriptions, and grain. Use when user says "document this dbt model", "add descriptions to schema.yml", "write dbt docs", or "document these columns".
---

Write documentation for dbt model: $ARGUMENTS

Read the model SQL fully, then read the existing schema.yml for this directory.

For each model and column, write clear, business-friendly descriptions:

**Model description**
- What business concept does this model represent?
- What is the grain (one row = one what)?
- What is the primary source of data?
- Any important exclusions, filters, or caveats?

**Column descriptions**
- Use plain English, not SQL jargon
- For IDs: "Primary key for X" or "Foreign key to Y, representing Z"
- For flags/booleans: "True if..., False if..."
- For dates: "The date on which X occurred"
- For amounts: include the currency and whether it's gross/net

**Format:**
```yaml
- name: <model_name>
  description: >
    One row per <grain>. Contains <what>. Sourced from <where>.
    Excludes <any important caveats>.
  columns:
    - name: <column>
      description: "<clear business description>"
```

Use `>` for multi-line descriptions. Keep descriptions concise but complete.
Do not add descriptions that just restate the column name.

**Output:** Updated schema.yml with descriptions filled in for the target model and all its columns.

**If the model is not in schema.yml yet:** Add a new entry. Do not leave the model undocumented.
