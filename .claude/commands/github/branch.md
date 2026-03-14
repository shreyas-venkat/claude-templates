---
description: Create a correctly-named branch from the latest main/master
---

Create a new branch for: $ARGUMENTS

Steps:
1. Determine the default branch (`git remote show origin | grep HEAD`)
2. Pull latest: `git fetch origin && git checkout <default> && git pull`
3. Choose the correct prefix:
   - `feat/` — new feature
   - `fix/` — bug fix
   - `hotfix/` — urgent production fix
   - `chore/` — maintenance, deps, tooling
   - `docs/` — documentation only
   - `refactor/` — code change with no behavior change
   - `test/` — adding or fixing tests
4. Slug the description: lowercase, hyphens only, max 40 chars
5. Create and checkout: `git checkout -b <type>/<slug>`

Print the branch name at the end.
