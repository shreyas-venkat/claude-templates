---
description: Open a pull request with a full description and test plan. Use when user says "open a PR", "create a pull request", "submit this for review", "push and PR this", or "make a PR for this branch".
---

Create a pull request for the current branch. Context: $ARGUMENTS

**Do not proceed if:**
- The branch has no commits ahead of the default branch (nothing to PR)
- There are uncommitted changes — ask the user to commit or stash them first
- The branch is already `main` or `master`

Steps:
1. Find the default branch: `git remote show origin | grep "HEAD branch"`
2. Sync with remote: `git fetch origin && git pull origin <default>` — pull the latest from the target branch so you're not behind on merges
3. Check existing PRs: `gh pr list --state open` and `gh pr list --state merged --limit 5` — look for an open PR for this branch (`gh pr view` will also show if the current branch already has one). If an open PR already exists, report it and stop — don't create a duplicate.
4. Run `git log origin/<default>...HEAD --oneline` — if empty, stop and report
5. Run `git diff origin/<default>...HEAD --stat` to see changed files
6. Read the key changed files to understand the full scope of changes

Draft a PR with:
- **Title**: concise, imperative, under 70 chars (no period)
- **Summary**: 2–4 bullet points explaining *what* changed and *why*
- **Changes**: grouped list of key modifications
- **Test plan**: bulleted checklist of how to verify correctness
- **Screenshots / notes**: placeholder section if UI changes are present
- **Linked issues**: `Closes #N` if applicable

Use `gh pr create` to open the PR. If there are no open issues to link, omit that section.

Set reviewers if specified in $ARGUMENTS. Default to draft if the branch is a work in progress.
