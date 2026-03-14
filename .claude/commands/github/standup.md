---
description: Generate a standup summary from recent git and GitHub activity. Use when asked for a standup, daily update, "what did I do yesterday", or "what's my status".
---

Generate a standup summary. Time window or focus area: $ARGUMENTS

**Determine the lookback window first:**
- Monday → use `--since="last Friday"` (covers the weekend gap)
- Any other day → use `--since="yesterday 9am"`
- If $ARGUMENTS specifies a range, use that instead

Gather activity:

1. `git log --since="<window>" --author="$(git config user.name)" --oneline --all`
2. `gh pr list --author=@me --state=all --limit=10 --json number,title,state,updatedAt`
3. `gh issue list --assignee=@me --state=all --limit=10 --json number,title,state,updatedAt`

Format the standup as:

**Yesterday**
- <bullet per meaningful commit, PR, or issue activity>

**Today**
- <infer next logical steps from open PRs, issues, and in-progress work>

**Blockers**
- <any PRs awaiting review, failing CI, or stuck issues — or "None">

**Rules:**
- If a section has no activity, write "None" — don't omit the section
- Each bullet is one line maximum
- Skip merge commits and dependency bumps — summarize meaningful work only
- This is for a team standup, not a report. No more than 5 bullets per section.
