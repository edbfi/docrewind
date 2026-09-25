# Development CI

Every PR, default-branch push and manual dispatch runs two required lanes:

- `test`: frozen Bun install (including WXT prepare), complementary prek hygiene
  and secret checks, Svelte and TypeScript checks, read-only Biome, purity and
  network-isolation guards, coverage-disjointness guard, pure-core tests,
  the existing per-file coverage floor, Vitest, Chrome build and Chromium E2E.
- `packaging-smoke`: Chrome and Firefox build/zip, shipped-manifest audit,
  Firefox static lint and same-environment build determinism. WXT `zip` builds
  internally, so a separate preceding build is unnecessary. Zips remain available
  as artifacts; browser failures retain traces/reports for seven days.

`ci / required` rejects failed, cancelled, missing or skipped lanes. Validation
has read-only permissions and must leave tracked files unchanged. The versioned
shared gate, policy and Biome repair come from `edbfi/automation` `v4.0.0`;
action references use full release tags. Local commands are documented in AGENTS.md. CI skips only
prek's local branch guard and Biome/typecheck hooks already run explicitly;
it does not replace or weaken the three test tiers.

Biome uses the official Renovate schema-version manager in the shared preset.
The separate repair workflow computes changes without write permissions, publishes
only allowlisted changes from an isolated job. Its head guard checks the live PR
before and after validation. The App-authored push starts the normal
`pull_request` CI and policy runs on the repaired commit; nothing is dispatched.
Repository scripts never run in the write-enabled publisher.
Existing Svelte formatting exclusions remain in biome.json.

Renovate owns ongoing dependency merging through the shared `automerge.json`
preset: it arms GitHub auto-merge with the rebase strategy, preserving signed
commits. The legacy Actions merger and maintainer command are
retired. The separately required `policy / ci / policy` check validates the PR
title, commit sign-offs, review state and hold labels from fresh read-only API
evidence. After a pass, policy re-runs the other event's older failed verdict
for the same head (`actions: write`), so a withdrawn objection clears without a
manual re-run. Protection requires this check and `ci / required` from GitHub Actions
for the current head and base. Release ages and the TypeScript 7 hold remain in
place; shared automation configuration updates remain manual. Svelte and TypeScript
compatibility checks remain mandatory.
Live browser-store submission and loading the extension against a real Google
account remain manual release checks. The tag-only release workflow is preserved.

The configured Biome App repair workflow remains enabled. A repair must receive complete current-head
CI and policy checks. If a workflow-token publication suppresses PR events, the
missing policy check blocks merging until a supported App/Renovate update triggers
full validation. Metadata and review events refresh policy; GitHub review rules
provide the independent server-side review guarantee during event propagation.
