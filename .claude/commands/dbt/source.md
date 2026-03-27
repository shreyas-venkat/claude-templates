---
description: Define dbt source tables with tests and freshness checks in sources.yml. Use when user says "add a dbt source", "define source tables for X", "set up a new source", or "connect dbt to raw schema Y".
---

Define a new dbt source: $ARGUMENTS

Read existing `sources.yml` files in the project for convention reference.

Build the source YAML block:

```yaml
version: 2

sources:
  - name: <source_name>           # logical name (e.g. stripe, shopify, postgres_app)
    description: "<what system this data comes from>"
    database: "{{ env_var('DBT_DATABASE', 'default') }}"
    schema: <raw_schema_name>
    loader: <fivetran|airbyte|custom>

    freshness:
      warn_after: {count: 12, period: hour}
      error_after: {count: 24, period: hour}
    loaded_at_field: _fivetran_synced   # or _airbyte_extracted_at, updated_at, etc.

    tables:
      - name: <table_name>
        description: "<what this raw table contains>"
        columns:
          - name: id
            description: "Primary key"
            tests:
              - unique
              - not_null
          - name: created_at
            description: "When the record was created"
```

Add columns and tests for all key fields, especially:
- Primary keys (unique + not_null)
- Foreign keys (not_null + relationships if the referenced table is also in dbt)
- Status/type enums (accepted_values)

Run `dbt source freshness` after defining to verify connectivity.

**If `dbt source freshness` fails:** Check that `loaded_at_field` matches the actual column name in the raw table. Common alternatives: `_fivetran_synced`, `_airbyte_extracted_at`, `updated_at`, `inserted_at`.
