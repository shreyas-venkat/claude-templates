---
description: Write dbt schema tests and custom data tests for a model
---

Write dbt tests for: $ARGUMENTS

Read the target model's SQL and existing schema.yml entry.

**Decision: schema test vs. singular test**
- Use **schema tests** (in schema.yml) for column-level constraints: nulls, uniqueness, accepted values, FK relationships. These run on every column automatically.
- Use **singular tests** (in `tests/`) only when the check involves business logic across rows or models that schema tests can't express. If you're writing SQL that could be a schema test, use the schema test.

**Schema tests (in schema.yml)**

For every column, add the appropriate generic tests:
- `unique` + `not_null` on all primary keys
- `not_null` on required columns
- `accepted_values` for enum/status columns (list the valid values)
- `relationships` for foreign keys pointing to other models
- `dbt_utils.at_least_one` or `dbt_utils.expression_is_true` where useful

**Custom singular tests (in `tests/` directory)**

Write SQL tests for business logic that generic tests can't cover:
- Row count expectations (e.g. mart should never have more rows than the source)
- Cross-model consistency checks
- Date logic (e.g. `end_date >= start_date`)
- Ratio or threshold checks (e.g. refund rate < 20%)

Format for singular tests:
```sql
-- tests/<descriptive_test_name>.sql
-- Fails if any rows are returned
select ...
from {{ ref('<model>') }}
where <condition_that_should_never_be_true>
```

Run `dbt test --select <model_name>` after writing to confirm all tests pass.
