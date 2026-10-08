#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# smoke.sh — packaging and extension smoke, run by CI's `smoke` job (`bun run smoke`).
#
# 1. Builds and zips both browsers (`wxt zip` builds before packaging).
# 2. Audits the shipped manifests (scripts/verify-manifest.sh).
# 3. Lints the Firefox build with web-ext.
# 4. Runs the Playwright extension suite (e2e/, Chromium) against .output/chrome-mv3.
# 5. Checks same-environment build determinism (scripts/verify-reproducible-build.sh).
#
# Needs Playwright's Chromium: `bunx playwright install chromium` (CI adds --with-deps).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

step() { printf '\n==> %s\n' "$*"; }

# verify-manifest.sh requires exactly one zip per kind; drop stale version-stamped zips.
rm -f .output/*.zip

step "zip (Chromium) + zip:firefox"
bun run zip
bun run zip:firefox

step "verify-manifest.sh"
bash scripts/verify-manifest.sh

step "lint:firefox (web-ext)"
bun run lint:firefox

step "Playwright extension smoke (e2e/)"
bun run test:e2e

step "verify-reproducible-build.sh"
bash scripts/verify-reproducible-build.sh

printf '\nOK: smoke passed.\n'
