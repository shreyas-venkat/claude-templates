---
description: Triage open issues — label, prioritize, and assign
---

Triage open GitHub issues. Focus or filter: $ARGUMENTS

Steps:
1. Fetch open issues: `gh issue list --state=open --limit=50 --json number,title,body,labels,assignees,createdAt`
2. For each unlabelled or unassigned issue, apply this decision tree:

   **Type:**
   - Contains "bug", "broken", "error", "crash", "wrong" → `bug`
   - Contains "add", "feature", "support", "allow", "new" → `feature`
   - Contains "docs", "readme", "typo", "comment" → `docs`
   - Contains "question", "how", "?" → `question`
   - Otherwise → `chore`

   **Priority:**
   - P0: production broken, data loss, security issue, or "urgent/critical" in title
   - P1: core workflow blocked, no workaround
   - P2: impactful but has workaround, or user-reported friction
   - P3: nice-to-have, minor polish, low traffic path

   **Effort:**
   - XS: config change or one-liner
   - S: single function or file change
   - M: touches multiple files, under a day
   - L: multi-day, multiple components
   - XL: architectural change, requires design discussion

   **Owner:** suggest based on issue content (backend/frontend/data/infra) if team info is available

3. Produce a triage table:

| # | Title | Type | Priority | Effort | Suggested Action |
|---|-------|------|----------|--------|-----------------|
| 12 | ... | bug | P1 | M | Assign to backend |

4. Flag any issues that are:
   - **Duplicates**: same root cause — note which is the canonical one to keep
   - **Incomplete bugs**: missing reproduction steps — comment `gh issue comment <n> --body "Could you share steps to reproduce?"`
   - **Stale**: no activity > 30 days — suggest closing or labeling `needs-info`
   - **Good first issues**: well-scoped, no deep context required, effort XS/S — label `good first issue`

If $ARGUMENTS includes `--apply`, execute:
```bash
gh issue edit <n> --add-label "<type>,<priority>"
# Repeat for each issue in the triage table
```
Otherwise output the triage plan only and wait for confirmation.
