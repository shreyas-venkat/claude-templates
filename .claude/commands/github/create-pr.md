---
description: Open a pull request with a full description and test plan
---

Create a pull request for the current branch. Context: $ARGUMENTS

**Do not proceed if:**
- The branch has no commits ahead of the default branch (nothing to PR)
- There are uncommitted changes — ask the user to commit or stash them first
- The branch is already `main` or `master`

Steps:
1. Find the default branch: `git remote show origin | grep "HEAD branch"`
2. Run `git log origin/<default>...HEAD --oneline` — if empty, stop and report
3. Run `git diff origin/<default>...HEAD --stat` to see changed files
4. Read the key changed files to understand the full scope of changes

Draft a PR with:
- **Title**: concise, imperative, under 70 chars (no period)
- **Summary**: 2–4 bullet points explaining *what* changed and *why*
- **Changes**: grouped list of key modifications
- **Test plan**: bulleted checklist of how to verify correctness
- **Screenshots / notes**: placeholder section if UI changes are present
- **Linked issues**: `Closes #N` if applicable

Use `gh pr create` to open the PR. If there are no open issues to link, omit that section.

Set reviewers if specified in $ARGUMENTS. Default to draft if the branch is a work in progress.
