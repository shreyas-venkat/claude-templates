---
description: Summarize inbox or a specific email thread, grouped by urgency. Use when user says "summarize my inbox", "what's in my email", "catch me up on this thread", "what emails need my attention", or "summarize this conversation".
---

Summarize emails. Scope: $ARGUMENTS

If a specific thread or subject is provided, fetch and summarize that thread.
If no scope is given, fetch recent unread inbox messages via Gmail MCP.

**For a single thread:**
- Who is involved?
- What is the central topic or request?
- What decisions or commitments have been made?
- What is outstanding / still needs a response?
- Recommended action: Reply | Archive | Forward | Escalate | No action needed

**For inbox summary:**
Group emails by urgency using these criteria:

🔴 **Needs reply today** — any of:
- Explicit deadline today or "ASAP", "urgent", "blocking"
- Direct question addressed to you with no reply yet
- Calendar invite or meeting request requiring RSVP
- Sender is a direct report, manager, or key stakeholder awaiting a decision

🟡 **Can wait / FYI** — informational, no clear action required, or deadline > 24h
- <sender>: <one-line summary>

📁 **Can archive** — newsletters, notifications, CC'd threads you don't need to act on
- <count> emails

Keep summaries to one line per email. Flag anything with a date, dollar amount, or the word "please" as potentially action-required.

**If the inbox is empty or Gmail MCP returns no results:** Say so clearly — do not fabricate email summaries.
