---
description: Compose a new email from a brief. Use when user says "write an email", "draft an email to X", "compose a message about Y", "help me email someone", or "write a note to Z".
---

Compose an email. Brief: $ARGUMENTS

Parse the brief for:
- **To**: recipient name/email
- **Subject**: topic or derive from context
- **Purpose**: inform | request | follow-up | invite | decline | thank | escalate
- **Tone**: professional (default) | casual | formal | urgent
- **Key points**: what must be communicated
- **Call to action**: what response or action is needed from the recipient

Write the email:
- Subject line: specific, not generic ("Q2 data pipeline timeline" not "Question")
- Opening: context or reason for writing in one sentence
- Body: clearly stated, no more than 3 paragraphs. Use bullets for multiple items.
- Close: clear call to action with any deadline
- Sign-off: appropriate to tone

If the Gmail MCP is available, draft or send the email. Otherwise output the complete email ready to copy.

Ask for confirmation before sending.
