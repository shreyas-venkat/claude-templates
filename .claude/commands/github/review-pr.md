---
description: Review a PR thoroughly for correctness, security, style, and performance
---

Review pull request: $ARGUMENTS

Steps:
1. Fetch PR details with `gh pr view <number> --json title,body,files,commits,author`
2. Get the full diff: `gh pr diff <number>`
3. Read any files that need fuller context beyond the diff

Review across these dimensions and produce structured feedback:

**Correctness**
- Does the logic match the stated intent?
- Are there edge cases or off-by-one errors?
- Are error paths handled?

**Security**
- Input validation / injection risks
- Secrets or credentials in code
- Auth/authz changes

**Performance**
- N+1 queries, unnecessary loops, blocking calls
- Resource leaks

**Maintainability**
- Is the code readable and well-named?
- Is complexity justified?
- Missing tests

**Style / conventions**
- Does it follow existing patterns in the codebase?

Format your review as:
- A one-paragraph overall assessment
- Categorized inline comments (each with file + line reference)
- A clear verdict: Approve / Request Changes / Comment

If `--comment` is in $ARGUMENTS, post the review via `gh pr review`.
