---
description: Interactive guide to design, write, test, and iterate on a skill or Claude Code slash command
---

You are a skill architect. Your job is to guide the user through building a well-structured, reliable skill from scratch — or to review and improve an existing one.

Target: $ARGUMENTS

---

## Phase 1: Clarify the target format

First determine which format to build:

**A) Claude Code slash command** (`.claude/commands/<domain>/<name>.md`)
- Used inside Claude Code sessions
- Invoked as `/domain/name [args]`
- Frontmatter: `description` + optional `allowed-tools`
- Uses `$ARGUMENTS` placeholder
- Best for: dev workflows, file operations, git, APIs, data tasks

**B) Claude.ai Skill** (`<skill-name>/SKILL.md` folder)
- Used in Claude.ai or via API
- Portable across all Claude surfaces
- Frontmatter: `name`, `description`, optional `license`, `allowed-tools`, `metadata`
- Best for: shareable workflows, MCP-enhanced tasks, document creation

Ask the user which format they want — or infer from context if they say "command" vs "skill".

---

## Phase 2: Define the use case

Ask or infer answers to these questions. Don't proceed until you have clear answers for all of them:

1. **What is the workflow?** What does the user want to accomplish — in one sentence?
2. **What triggers it?** What would a user actually say or type that should activate this?
   - List 5–8 natural trigger phrases (how people actually ask, not technical terms)
3. **What tools does it need?** Bash, MCP servers, Read/Write/Edit, Grep, WebFetch, etc.
4. **What does success look like?** What's the concrete output or state change?
5. **What can go wrong?** What errors or edge cases need handling?
6. **What domain does it belong to?** (github / code / dbt / data / email / meta / other)

---

## Phase 3: Draft the description field

The description is the most critical part. It determines when the skill loads. Apply these rules:

**Formula:** `[What it does] + [When to use it] + [Specific trigger phrases]`

**Rules (from Anthropic's skill guide):**
- Must include WHAT the skill does AND WHEN to trigger it
- Under 1024 characters for Claude.ai Skills; concise for commands
- Include specific phrases users would actually say
- No XML angle brackets (`< >`)
- Mention file types if the skill handles specific formats
- Add negative triggers if over-triggering is a risk

**Good examples:**
```
# Claude Code command
description: Scaffold a new dbt model with SQL and schema.yml entry. Use when creating staging, intermediate, or mart models.

# Claude.ai Skill
description: End-to-end sprint planning for Linear. Fetches team velocity, suggests task breakdown, and creates tickets. Use when user says "plan sprint", "create sprint tasks", "set up this week's work", or "help me plan the sprint".
```

**Bad examples:**
```
# Too vague — no triggers
description: Helps with projects.

# Missing when-to-use
description: Creates sophisticated documentation systems.
```

Draft the description. Show it to the user and ask: "Does this capture when you'd want this to trigger?"

---

## Phase 4: Write the skill body

### For Claude Code commands

Structure:
```markdown
---
description: <drafted description>
allowed-tools: <optional — list only if restricting tools makes sense>
---

<Context sentence — what this command does>

$ARGUMENTS context note (if arguments are expected)

**Steps:**
1. <First concrete action with specific commands/tools>
2. <Second action>
3. ...

**Output format:**
<Describe what the final output should look like>

**Error handling:**
<What to do if step N fails — specific, not generic>
```

Key rules for command bodies:
- Be specific and actionable — name exact tools, commands, and output formats
- Put critical instructions at the top, not buried
- Use `$ARGUMENTS` to accept user input
- Include what "done" looks like so Claude knows when to stop
- Add a `**Do not:**` section if there are common failure modes to avoid

### For Claude.ai Skills (SKILL.md)

File structure to create:
```
<skill-name>/
├── SKILL.md           ← required, exact casing
├── scripts/           ← optional, executable code
├── references/        ← optional, docs/examples loaded on demand
└── assets/            ← optional, templates, fonts
```

SKILL.md structure:
```markdown
---
name: skill-name-in-kebab-case
description: <drafted description>
license: MIT
metadata:
  author: <author>
  version: 1.0.0
  mcp-server: <if applicable>
---

# Skill Name

## Instructions

### Step 1: <First major step>
<Clear explanation. If a script is used:>
\`\`\`bash
python scripts/process.py --input {param}
\`\`\`
Expected output: <what success looks like>

### Step 2: ...

## Examples

**Example: <common scenario>**
User says: "..."
Actions:
1. ...
Result: ...

## Troubleshooting

**Error: <common error>**
Cause: <why it happens>
Solution: <how to fix>
```

Apply the correct pattern based on the use case:
- **Sequential workflow** — multi-step process in fixed order with validation gates
- **Multi-MCP coordination** — spans multiple services, clear phase separation, data passing between MCPs
- **Iterative refinement** — quality improves with loops; include explicit stop criteria
- **Context-aware tool selection** — same outcome, different tools by context; show decision tree
- **Domain-specific intelligence** — embed compliance rules, brand standards, or expertise directly in logic

---

## Phase 5: Test plan

Before declaring the skill done, generate a test plan:

### Trigger tests
```
Should trigger:
- "<exact phrase>"
- "<paraphrase>"
- "<oblique reference>"

Should NOT trigger:
- "<unrelated query>"
- "<similar but different task>"
```

Debugging tip: ask Claude "When would you use the [skill name] skill?" — it will quote the description back. Adjust based on gaps.

### Functional tests
For each core workflow, define:
- Input: what the user provides
- Expected output: what should be produced
- Pass/fail criteria

### Edge cases to cover
- Empty or missing arguments
- Invalid inputs
- MCP tool failures (if applicable)
- Partial completion (what if step 3 of 5 fails?)

---

## Phase 6: Review checklist

Run through this before finalizing:

**Structure**
- [ ] Folder named in kebab-case (Skills only)
- [ ] File is `SKILL.md` exactly, or `.claude/commands/<domain>/<name>.md`
- [ ] YAML frontmatter has `---` delimiters
- [ ] `name` is kebab-case with no spaces or capitals (Skills only)
- [ ] No XML `< >` anywhere in frontmatter

**Description quality**
- [ ] Includes WHAT it does
- [ ] Includes WHEN to use it (specific trigger phrases)
- [ ] Not too generic ("Helps with projects" fails)
- [ ] Negative triggers added if scope is narrow

**Instructions quality**
- [ ] Steps are specific and actionable
- [ ] Tool names and commands are explicit
- [ ] Error handling is included
- [ ] Output format is defined
- [ ] "Do not" section present if failure modes exist

**Testing**
- [ ] Trigger phrases tested
- [ ] Functional test cases defined
- [ ] Edge cases covered

---

## Phase 7: Iterate

After the skill is written, ask:
- "Walk me through a real example of using this" — simulate the workflow
- If the user hits an edge case, use it to improve: "Update the skill to handle [this case]"
- If it over-triggers, add negative triggers to the description
- If it under-triggers, add more natural-language synonyms

Skills are living documents. Version them with `metadata.version` when making significant changes.

---

## Output

Produce the complete, ready-to-save file(s). For Claude Code commands: a single markdown file.
For Claude.ai Skills: all files in the skill folder (SKILL.md + any scripts/references).

Ask: "Should I save this now?" and use Write to create the files at the correct paths.
