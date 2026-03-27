---
description: Self-review staged changes before committing — catch bugs and issues early. Use when user says "review my changes", "check this before I commit", "look at my diff", "is this ready to commit", or "what did I change".
---

Review my staged changes before I commit. Context: $ARGUMENTS

Run `git diff --cached` and `git diff` to see all pending changes. Read any relevant surrounding code for context.

Check for:

**Bugs**
- Off-by-one errors, null dereferences, unhandled promises
- Logic that doesn't match the intent

**Security**
- Hardcoded credentials or tokens
- SQL/command injection vectors
- Exposed sensitive data in logs

**Correctness**
- Does this handle the edge cases?
- Are error paths covered?

**Code quality**
- Dead code or debug statements left in (`console.log`, `print`, `debugger`)
- Magic numbers without explanation
- Functions that are too long or doing too much

**Tests**
- Are new behaviors covered by tests?
- Are existing tests likely to still pass?

**Breaking changes**
- Any API or interface changes that could affect callers?

Produce a prioritized list:
- 🔴 Must fix before committing
- 🟡 Should fix soon
- 🟢 Optional / nitpick

If everything looks good, say so clearly.

**If there are no staged changes:** Report that `git diff --cached` is empty and ask whether the user wants to review unstaged changes instead.
