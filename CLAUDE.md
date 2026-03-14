# Claude Templates

A drop-in `.claude/` configuration for Claude Code providing MCP server setup and a full library of slash commands for daily development work.

## MCP Servers

| Server | Purpose | Key env vars |
|--------|---------|--------------|
| `filesystem` | Expanded file access beyond the project root | — |
| `github` | Issues, PRs, reviews, releases, repo management | `GITHUB_TOKEN` |
| `gmail` | Read, compose, reply, and search email | file-based OAuth (one-time setup) |
| `motherduck` | Run SQL against MotherDuck (cloud DuckDB) | `MOTHERDUCK_TOKEN` |

## Setup

1. Copy the `.claude/` directory, `CLAUDE.md`, and `.mcp.json` into the root of your repo.
2. Copy `.env.example` to `.env` and fill in your credentials.
3. Export the env vars in your shell before launching Claude Code:
   ```bash
   export $(grep -v '^#' .env | xargs)
   # or use direnv: add `dotenv` to your .envrc
   ```
4. Authenticate Gmail (one-time):
   ```bash
   npx @gongrzhe/server-gmail-autoauth-mcp auth
   ```
   A browser window opens — sign in with Google. Credentials are saved to `~/.gmail-mcp/` and reused automatically.
5. Open the project in Claude Code — MCP servers start automatically.

## Slash Commands

Commands are grouped by domain. Invoke with `/domain/command [args]`.

### GitHub `/github/*`
| Command | What it does |
|---------|-------------|
| `/github/commit` | Stage, write a conventional commit message, and commit |
| `/github/branch` | Create a correctly-named feature/fix/chore branch |
| `/github/create-pr` | Open a PR with title, description, and test plan |
| `/github/review-pr` | Review a PR for correctness, style, security, and performance |
| `/github/create-issue` | Create a well-structured issue with labels and context |
| `/github/release` | Cut a release: bump version, generate changelog, tag, publish |
| `/github/standup` | Generate a standup summary from recent git and GitHub activity |
| `/github/triage` | Triage open issues: label, prioritize, and assign |

### Code `/code/*`
| Command | What it does |
|---------|-------------|
| `/code/explain` | Deep explanation of a file, function, or concept |
| `/code/refactor` | Refactor for readability, performance, and simplicity |
| `/code/tests` | Write comprehensive unit and integration tests |
| `/code/docs` | Generate docstrings, inline comments, and API docs |
| `/code/debug` | Systematic root-cause analysis and fix |
| `/code/review` | Self-review before committing — catch bugs and issues |

### dbt `/dbt/*`
| Command | What it does |
|---------|-------------|
| `/dbt/model` | Scaffold a new dbt model with SQL and schema.yml |
| `/dbt/tests` | Write schema tests and custom data tests |
| `/dbt/docs` | Write model documentation in schema.yml |
| `/dbt/source` | Define source tables and freshness checks |
| `/dbt/macro` | Create a reusable Jinja macro |

### Meta `/meta/*`
| Command | What it does |
|---------|-------------|
| `/meta/create-skill` | Interactive guide to design, write, test, and iterate on a new skill or slash command |
| `/meta/cleanup-skills` | Audit all existing slash commands against a quality rubric and apply targeted improvements |

### Email `/email/*`
| Command | What it does |
|---------|-------------|
| `/email/compose` | Compose a new email from a brief |
| `/email/reply` | Reply to an email thread with context-aware response |
| `/email/summarize` | Summarize inbox or a specific thread |
| `/email/followup` | Write a follow-up to an existing email |

### Data `/data/*`
| Command | What it does |
|---------|-------------|
| `/data/query` | Write and run SQL against MotherDuck |
| `/data/explore` | Explore a table or dataset: schema, samples, stats |
| `/data/report` | Generate a structured data analysis report |
| `/data/profile` | Profile a table for nulls, distributions, and anomalies |

## Conventions

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).
- Branch names follow `type/short-description` (e.g. `feat/add-user-auth`).
- dbt models follow the project's existing layering convention (staging → intermediate → mart).
- Emails default to professional and concise unless otherwise specified.
