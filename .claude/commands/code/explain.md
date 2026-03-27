---
description: Deep explanation of a file, function, or concept in the codebase. Use when user says "explain this", "how does X work", "walk me through this file", "what does this function do", or "I don't understand this code".
---

Explain the following in depth: $ARGUMENTS

If a file path is given, read it fully first. If a function or class name is given, find it with Grep/Glob then read the surrounding context.

Structure your explanation as:

**What it is**
One-sentence summary of purpose.

**How it works**
Step-by-step walkthrough of the logic, in plain English. Reference specific line numbers.

**Key design decisions**
Why is it structured this way? What trade-offs were made?

**Dependencies & interfaces**
What does it depend on? What calls it or consumes its output?

**Gotchas / non-obvious behavior**
Edge cases, side effects, or things that would surprise a new reader.

**Example**
A concrete usage example if applicable.

Pitch the explanation at a competent engineer who is new to this codebase, not a beginner.

**If the file or function is not found:** Use Grep to search for the name across the codebase before giving up. If still not found, report clearly and ask the user to clarify the path or name.
