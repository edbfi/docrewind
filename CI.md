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
has read-only permissions and must leave tracked files unchanged. Versioned
shared guard/gate actions come from `edbfi/automation`; action references use
full release tags. Local commands are documented in AGENTS.md. CI skips only
prek's local branch guard and Biome/typecheck hooks already run explicitly;
it does not replace or weaken the three test tiers.

Biome uses the official Renovate schema-version manager in the shared preset.
The separate repair workflow computes changes without write permissions, publishes
only allowlisted changes from an isolated job, then dispatches this entire CI
workflow on the repaired commit. Its head guard checks the live PR before and
after validation. Repository scripts never run in the write-enabled publisher.
Existing Svelte formatting exclusions remain in biome.json.

Renovate owns ongoing dependency merging after the protected native canary
[automation#39](https://github.com/edbfi/automation/pull/39). Native PR rebase merges
preserve signed commits. The legacy Actions merger and maintainer command are
retired. The separately required `policy / ci / policy` check validates the PR
title, commit sign-offs, review state and hold labels from fresh read-only API
evidence. Protection requires this check and `ci / required` from GitHub Actions
for the current head and base. Release ages and the TypeScript 7 hold remain in
place; shared automation configuration updates remain manual. Svelte and TypeScript
compatibility checks remain mandatory.
Live browser-store submission and loading the extension against a real Google
account remain manual release checks. The tag-only release workflow is preserved.

Repair CI recovery reads `.github/repair-policy.json`. Recovery remains disabled,
preserving the previous policy; the configured Biome App repair workflow remains
enabled and uses the released v3 action. A repair must receive complete current-head
CI and policy checks. If a workflow-token publication suppresses PR events, the
missing policy check blocks merging until a supported App/Renovate update triggers
full validation. Metadata and review events refresh policy; GitHub review rules
provide the independent server-side review guarantee during event propagation.
