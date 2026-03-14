---
description: Cut a release — bump version, generate changelog, tag, and publish
---

Cut a release. Target version or bump type: $ARGUMENTS

Steps:
1. Check current version (look in `package.json`, `pyproject.toml`, `VERSION`, or tags)
2. Determine new version — use semver:
   - `patch` — bug fixes only
   - `minor` — new backwards-compatible features
   - `major` — breaking changes
3. Pull commits since last tag: `git log <last-tag>...HEAD --oneline`
4. Group commits into changelog sections:
   - 🚀 Features (`feat:`)
   - 🐛 Bug Fixes (`fix:`)
   - ⚡ Performance (`perf:`)
   - 🔧 Chores / Maintenance (`chore:`, `build:`, `ci:`)
   - 📚 Documentation (`docs:`)
5. Bump the version in the relevant file(s)
6. Update or create `CHANGELOG.md` with the new section
7. Commit: `chore(release): v<version>`
8. Tag: `git tag -a v<version> -m "v<version>"`
9. Create GitHub release via `gh release create` with the generated changelog body

Do not push or publish unless explicitly confirmed.
