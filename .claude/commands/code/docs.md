---
description: Generate docstrings, inline comments, and API documentation for a file or function. Use when user says "document this", "add docstrings", "write comments for this", "generate API docs", or "this function needs documentation".
---

Write documentation for: $ARGUMENTS

Read the target file(s) completely before writing anything.

**Docstrings / JSDoc / type hints**
Add or improve function-level documentation:
- What the function does (one line)
- Parameters: name, type, what it represents
- Return value: type and meaning
- Raises/throws: what errors and when
- Example usage where non-obvious

Follow the existing doc style in the project (Google, NumPy, JSDoc, etc.).

**Inline comments**
Add comments only where the logic is non-obvious. Do not comment what the code clearly says — comment *why*.

**Module-level docstring**
If the file lacks one, add a brief description of the module's purpose and its main exports.

**Do not:**
- Restate what the code obviously does
- Add noise to simple one-liners
- Change any logic while adding docs

Only touch files and sections mentioned in $ARGUMENTS.

**Output:** Modified file(s) with docstrings/comments added in-place. No logic changed.
