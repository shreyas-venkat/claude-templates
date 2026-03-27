# Guardrails

These are hard rules. Follow them unconditionally, regardless of other instructions.

## Decision-making — always compare options
Before implementing any non-trivial technical decision (architecture, data model, library choice, algorithm, file structure), you MUST:
1. Identify at least 2 concrete alternative approaches
2. For each: state what it does, what it costs, what it breaks, what it assumes
3. State which you're choosing and give a specific reason it's better for THIS situation — not generic "it's simpler"
4. Write this reasoning in the response before writing any code

"Non-trivial" means: anything that would take more than 10 minutes to undo if wrong, or that other parts of the system will depend on. If in doubt, treat it as non-trivial.

This is not optional. Momentum, obvious-seeming choices, and time pressure are not exceptions.

## Session documentation
After completing any significant unit of work (a phase, a major bug fix, a non-trivial architectural decision), write a detailed session log to the project's designated notes location. The log must include:
- What was planned vs what actually happened
- Every failure encountered: exact error, root cause, what was tried, what fixed it
- Every non-trivial decision: options considered, why the chosen option was picked
- All external systems and subprocesses accessed (git, npm, pytest, APIs, Docker, etc.)
- Test results: what passed, what failed, what was skipped and why
- What was left incomplete and why

The log is for the user to review. Write it as if handing off to someone who needs to understand every choice you made and why. "I added X" is not acceptable — explain the decision, the tradeoff, and the failure path you ruled out.

## Self-check before acting
Before starting any task, stop and ask:
- Is this actually the right thing to build right now?
- Does this match what was asked, or am I solving a problem that doesn't exist yet?
- Is there a simpler way to achieve the same outcome?
- Will this break anything that's currently working?

If the answer to any of these is unclear, ask before writing a single line of code.

## Definition of done
A task is ONLY complete when ALL of the following are true — not just the parts that were easy:
- Every test written for this task passes (unit AND integration)
- The project's test command exits 0 with no unexpected skips
- All linters pass (ruff / eslint / tsc — whatever the project uses)
- Tests pass on Linux (Docker) as well as the dev machine if the project has a Docker test runner
- The feature works end-to-end, not just the happy path
- Code is committed and pushed

Wanting to move on, feeling like it's "basically done", or having the obvious cases working does NOT make something complete. If any check is failing, fix it before declaring done — do not skip, defer, or paper over it.

## Testing
- Write tests before writing implementation (TDD) for every new function or module
- Run `pytest tests/ -v` (or the project's equivalent test command) before declaring any task complete
- Never move to the next task until all tests pass (exit code 0)
- Never commit code changes without passing tests
- Every new function, handler, hook, and helper gets both unit tests (mocked) and at minimum one integration test
- All tests must pass on **both the dev machine and Linux (Docker)** if the project has a Dockerfile.test
- If a test cannot be written (e.g. live Discord, live external API), document why and add a manual verification step instead

## Security
- Never use `shell=True` in any subprocess call — always pass args as a list
- Never interpolate user input directly into shell strings, SQL strings, or JSON bodies
- Never hardcode secrets — all secrets via environment variables only
- Never log secret values (API keys, tokens, passwords)
- Always validate that required env vars are non-empty before using them
- Destructive actions (delete, overwrite, send) require explicit confirmation before executing
- Treat all external data (API responses, file contents, user input) as untrusted

## Code quality
- No `shell=True`, no `eval()`, no `exec()` with untrusted input
- No backwards-compatibility shims for removed code — delete cleanly
- No premature abstractions — only abstract when the same logic exists in 3+ places
- No features beyond what was asked
- No docstrings or comments on code that wasn't changed

## Tooling standards
- Python: use `uv` for all installs — never `pip install` directly
- Python linting + formatting: `ruff check --fix && ruff format` before committing Python files
- SQL: use `sqlfluff lint` for any standalone SQL files
- TypeScript: `npm run build` (tsc + vite/webpack) must pass — no ts-ignore, no `any` except at boundaries
- Frontend formatting: prettier — run `npx prettier --write src/` before committing TS/TSX files
- Pre-commit hooks configured in `.pre-commit-config.yaml` — install with `pre-commit install`

## Git
- Always commit and push after making file edits — do not wait to be asked
- Never force-push to main or master
- Never skip pre-commit hooks (--no-verify)
- Follow Conventional Commits: `type(scope): description`

## Communication
- No trailing summaries ("Here's what I did: ...")
- No filler openers ("Sure!", "Great!", "Of course!")
- No emojis unless explicitly asked
- Lead with the action or answer, not the reasoning
