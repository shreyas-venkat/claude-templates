---
description: Create a reusable dbt Jinja macro with best-practice structure and compile verification. Use when user says "create a dbt macro", "write a macro for X", "I need a reusable dbt function", or "add a Jinja macro".
---

Create a dbt macro for: $ARGUMENTS

Read `macros/` directory for existing macros and style conventions.

**Macro structure:**
```sql
{% macro macro_name(param1, param2, param3=default_value) %}

  {# Description of what this macro does #}

  ...sql or jinja...

{% endmacro %}
```

**Best practices to follow:**
- Name it verb_noun style: `generate_surrogate_key`, `clean_string`, `pivot_values`
- Accept concrete parameters — avoid reading from `var()` inside macros unless necessary
- Use `{# comments #}` to explain non-obvious logic
- If it generates SQL, test it compiles correctly in at least one model
- If it's a utility macro, add an example call in a comment at the top

**Add a dispatch header if overriding a package macro:**
```sql
{% macro macro_name(...) %}
  {{ return(adapter.dispatch('macro_name', 'project_name')(...)) }}
{% endmacro %}
```

After writing:
1. Run `dbt parse` first — it's faster and catches Jinja syntax errors without running SQL
2. If parse passes, run `dbt compile --select <a model that uses the macro>` to verify full SQL generation
3. Show the compiled SQL output so the user can confirm the macro produces what they expect

**If `dbt parse` fails:** It's a Jinja syntax error. Show the error line and fix it before attempting `dbt compile`. Do not skip the parse step.
