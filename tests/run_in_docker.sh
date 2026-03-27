#!/usr/bin/env bash
# Run the full test suite inside a Linux Docker container.
# Verifies that tests pass on Linux, not just the local dev machine.
#
# Usage: bash tests/run_in_docker.sh [pytest-args...]
# Example: bash tests/run_in_docker.sh -v -m "not integration"
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="$(basename "$REPO_ROOT")-test:$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo latest)"

echo "==> Building test image: $IMAGE"
docker build \
  --file "$REPO_ROOT/Dockerfile.test" \
  --tag "$IMAGE" \
  "$REPO_ROOT"

echo "==> Running pytest inside Linux container"
docker run --rm \
  "$IMAGE" \
  python -m pytest tests/ -v -m "not integration" "$@"

echo "==> All tests passed on Linux (Docker)"
