---
description: Systematic root-cause analysis and fix for a bug or unexpected behavior. Use when user says "this is broken", "I'm getting an error", "why is this failing", "debug this", or "help me figure out what's wrong".
---

Debug the following issue: $ARGUMENTS

Work methodically:

**1. Understand the symptom**
- What is the exact error message or unexpected behavior?
- When does it occur? Always, sometimes, only in certain environments?

**2. Reproduce**
- Find or write the minimal code path that triggers the issue
- Run it to confirm the failure

**3. Trace the cause**
- Read the relevant code paths from entry point to failure
- Check: incorrect assumptions, off-by-one, null/undefined, async timing, type mismatch, wrong env var, stale cache
- Use logs, print statements, or debugger output as needed

**4. Identify the root cause**
- State clearly: *the bug is X because Y*
- Distinguish root cause from symptoms

**5. Fix**
- Make the minimal change that resolves the root cause
- Do not refactor unrelated code while fixing
- Add a test that would have caught this bug

**6. Verify**
- Run the test suite
- Confirm the original symptom is gone

Document the root cause in a comment if the fix is non-obvious.

**If you cannot reproduce the issue:** State this clearly. Ask the user for the exact command, environment, and output. Do not guess at a fix without reproducing first.
