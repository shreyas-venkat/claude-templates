---
description: Audit and improve all existing Claude Code slash commands. Evaluates description quality, trigger clarity, instruction specificity, and error handling — then applies fixes. Use when reviewing, cleaning up, or standardizing your command library.
---

Audit and improve the existing Claude Code slash commands. Scope: $ARGUMENTS (default: all commands in `.claude/commands/`)

---

## Step 1: Discover all commands

Use Glob to find every command file:
```
pattern: **/*.md
path: .claude/commands/
```

List them grouped by domain folder. If no commands are found, stop and say so.

---

## Step 2: Score each command

Read every file. For each one, score it against this rubric:

### Description (40 pts)
| Check | Points |
|-------|--------|
| States clearly WHAT the command does | 10 |
| States clearly WHEN to use it (trigger conditions) | 10 |
| Includes specific trigger phrases users would actually say | 10 |
| Not vague or generic ("helps with X" scores 0) | 10 |

### Instructions (40 pts)
| Check | Points |
|-------|--------|
| Steps are specific and name exact tools/commands | 10 |
| Uses `$ARGUMENTS` correctly for user input | 10 |
| Defines what "done" looks like (output format or end state) | 10 |
| Includes error handling or a "Do not" guard | 10 |

### Structure (20 pts)
| Check | Points |
|-------|--------|
| Frontmatter has `---` delimiters | 5 |
| No XML angle brackets (`< >`) in frontmatter | 5 |
| Instructions are concise (not buried in prose) | 5 |
| Critical steps are at the top, not the bottom | 5 |

---

## Step 3: Produce the audit report

Format:

```
## Audit Report — .claude/commands/

### Summary
- Total commands: N
- Need improvement: N
- Passing (≥ 80/100): N

### Per-command scores

#### /github/commit — 85/100 ✅
- Description: 35/40 — missing negative trigger (could over-fire on amend requests)
- Instructions: 40/40
- Structure: 10/20 — no explicit "done" state

#### /dbt/model — 60/100 ⚠️
- Description: 20/40 — no trigger phrases, too vague
- Instructions: 30/40 — error handling missing
- Structure: 10/20

#### ...
```

Flag each command as:
- ✅ Good (80–100) — minor polish only
- ⚠️ Needs work (50–79) — description or instruction gaps
- 🔴 Poor (< 50) — rewrite needed

---

## Step 4: Confirm before editing

Show the report to the user. Ask:

> "I found N commands that need improvement. Apply all fixes automatically, or review each one interactively?"

- **"all"** → proceed through every ⚠️ and 🔴 command automatically
- **"interactive"** → show each proposed change and ask for approval before applying
- **"just show me"** → stop here, report only

---

## Step 5: Apply fixes

For each ⚠️ or 🔴 command, apply targeted improvements using Edit:

### Fix: Weak description
Rewrite the `description` field using the formula:
`[What it does] + [When to use it] + [trigger phrase 1, trigger phrase 2, ...]`

Keep the rest of the file intact.

### Fix: Missing trigger phrases
Add 3–5 natural-language phrases a user would actually say. Append them to the description:
`Use when user says "...", "...", or "...".`

### Fix: Vague instructions
Replace prose instructions with numbered steps. Each step should name a specific tool or command.

### Fix: Missing $ARGUMENTS
If the command is generic and takes no input, it may not need `$ARGUMENTS`. But if the workflow clearly varies by user input (target file, PR number, etc.), add `$ARGUMENTS` with a clear label:
```
Target: $ARGUMENTS
```

### Fix: Missing error handling
Add a `**Do not:**` or `**If X fails:**` section at the end covering the most likely failure mode.

### Fix: Missing output definition
Add an explicit statement of what the final output looks like:
```
**Output:** <describe the end state or artifact>
```

---

## Step 6: Validate changes

After all edits, re-read each modified file and confirm:
- [ ] Description still under ~300 characters and no XML brackets
- [ ] `---` frontmatter delimiters present
- [ ] `$ARGUMENTS` present where expected
- [ ] No instructions were accidentally deleted

---

## Step 7: Final summary

Print a before/after table:

```
| Command             | Before | After | Changes |
|---------------------|--------|-------|---------|
| /github/commit      | 85     | 95    | Added negative trigger, output definition |
| /dbt/model          | 60     | 88    | Rewrote description, added error handling |
```

Total commands improved: N
Commands still below 80 (needs human review): N — list them
