---
description: Scaffold a new dbt model with SQL and schema.yml entry
---

Create a new dbt model: $ARGUMENTS

First, understand the project structure:
- Read `dbt_project.yml` for model paths and conventions
- Check the existing models directory for naming patterns and layering (staging → intermediate → mart)
- Look at 1–2 existing models at the same layer as a style reference

**Determine the layer:**
- `staging` — raw source cleaning, 1:1 with source tables, `stg_<source>__<entity>.sql`
- `intermediate` — joins and transformations, `int_<description>.sql`
- `mart` — business-facing, wide tables, `fct_<entity>.sql` or `dim_<entity>.sql`

**Create the SQL file:**
- Use CTEs (`with source as (...)`, `renamed as (...)`, `final as (...)`)
- Apply correct `{{ ref() }}` or `{{ source() }}` references
- Add `{{ config(...) }}` block if materialization differs from default
- Include `-- depends_on:` comments for non-ref dependencies

**Add the schema.yml entry:**
```yaml
- name: <model_name>
  description: "<what this model represents>"
  columns:
    - name: <pk_column>
      description: "<description>"
      tests:
        - unique
        - not_null
    - name: <other_columns>
      description: "<description>"
```

Run `dbt compile --select <model_name>` to verify the model compiles.
