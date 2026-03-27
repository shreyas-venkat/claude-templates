---
description: Refactor code for clarity, simplicity, and performance without changing behavior. Use when user says "clean up this code", "refactor this", "this is too complex", "simplify this function", or "improve this code".
---

Refactor: $ARGUMENTS

**Do not:**
- Change external interfaces or function signatures without flagging it first
- Add features or handle cases not already in the code
- Over-abstract into patterns for their own sake
- Refactor files not mentioned in $ARGUMENTS

Read the target file(s) fully before making any changes.

Apply only improvements that are clearly better:

**Targets (apply where relevant):**
- Remove duplication (DRY, but only when the abstraction is obvious)
- Improve naming (variables, functions, types should read like prose)
- Simplify control flow (early returns, remove double negatives, flatten nesting)
- Break apart functions that do more than one thing
- Remove dead code and unused imports
- Replace raw loops with idiomatic constructs
- Fix performance issues (N+1, unnecessary recomputation, blocking calls)

After changes, run any existing tests to confirm nothing broke.

Present a brief summary of what you changed and why for each significant change.
