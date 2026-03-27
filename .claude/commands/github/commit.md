---
description: Stage changes, generate a conventional commit message, and commit. Use when user says "commit my changes", "write a commit message", "commit this", or "save my work". Do not use for amending existing commits or interactive rebases.
---

Run `git status` and `git diff` to understand all staged and unstaged changes.

Analyze the diff and write a commit message following Conventional Commits:
- Format: `type(scope): short description`
- Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `ci`, `build`
- Keep the subject line under 72 characters
- Add a body paragraph if the change is non-trivial, explaining *why* not *what*
- Reference any related issues at the bottom (`Closes #123`)

Then:
1. Stage the appropriate files (prefer specific paths over `git add -A`)
2. Commit with the generated message
3. Show the final commit with `git show --stat HEAD`

If the user provided guidance: $ARGUMENTS

Do not push unless explicitly asked.
