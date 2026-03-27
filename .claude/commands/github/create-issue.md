---
description: Create a well-structured GitHub issue with labels and context. Use when user says "create an issue", "file a bug", "open a ticket", "log a feature request", or "report this problem".
---

Create a GitHub issue for: $ARGUMENTS

Determine the issue type from context:
- **Bug report**: steps to reproduce, expected vs actual, environment
- **Feature request**: problem statement, proposed solution, acceptance criteria
- **Task / chore**: description, definition of done
- **Question / discussion**: context, what's been tried

Build the issue body with the appropriate template:

For bugs:
```
## Description
<clear description of the problem>

## Steps to Reproduce
1. ...

## Expected Behavior
...

## Actual Behavior
...

## Environment
- OS:
- Version:
```

For features:
```
## Problem
<what problem does this solve?>

## Proposed Solution
<what should be built?>

## Acceptance Criteria
- [ ] ...
```

Suggest relevant labels (bug, enhancement, documentation, good first issue, etc.).
Assign if a person is mentioned in $ARGUMENTS.

Use `gh issue create` to open the issue and print the URL.

**Output:** GitHub issue URL printed to confirm successful creation.

**If `gh issue create` fails:** Check that `GITHUB_TOKEN` is set and has `repo` scope.
