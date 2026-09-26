# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

DocRewind: Bun-only WXT + Svelte 5 MV3 extension (Chromium + Firefox) that reconstructs
Google Docs/Sheets/Slides revision history locally. No backend, no telemetry.

## Setup

`bun install --frozen-lockfile` runs `postinstall` (`wxt prepare`), which generates `.wxt/`
(tsconfig base, `#imports`, WXT globals). Without it typecheck, build and Vitest fail to resolve.
Rerun `bun run postinstall` after changing `wxt.config.ts`.

## Commands

| Task | Command |
| --- | --- |
| Typecheck (svelte-check + tsc + svelte-check `--tsgo`) | `bun run compile` |
| Lint + format, **writes** | `bun run check` (CI runs non-writing `bunx biome ci .`) |
| Pure-core tests (Bun) | `bun run test:logic` |
| Platform/UI tests (Vitest, one-shot) | `bun run test:run` (`bun run test` is watch mode) |
| Coverage gate | `bun run test:coverage` |
| E2E (Playwright, Chromium) | `bun run build`, then `bun run test:e2e` |
| CI guards | `bash scripts/check-pure-core.sh`, `bash scripts/check-no-foreign-hosts.sh`, `bash scripts/check-coverage-gate-disjoint.sh` |

Single file / single case:

```sh
bun test ./lib/core/domain/kind.test.ts -t "case name"   # lib/core/** (bun:test)
bunx vitest run test/popup.test.ts -t "case name"        # lib/platform/**, test/** (vitest)
bunx playwright test e2e/replay-smoke.spec.ts            # needs .output/chrome-mv3 from `bun run build`
```

Never run bare `bun test` at the root: it also picks up the Vitest and Playwright files and
fails. Use `bun run test:logic` or an explicit `./lib/core/...` path.

`check-coverage-gate-disjoint.sh` uses `mapfile`, `jq` and Python `tomllib`, so it needs bash 4+
(stock macOS `/bin/bash` 3.2 fails); the other two guards are 3.2-safe.

## Test tiers

| Code under test | Runner | Import from |
| --- | --- | --- |
| `lib/core/**` (pure) | Bun, dirs enumerated in `test:logic` | `bun:test` |
| `lib/platform/**`, `components/**`, `entrypoints/**` | Vitest (`test/**` or colocated in `lib/platform/`) | `vitest`, `fakeBrowser` from `wxt/testing/fake-browser` |
| Built extension | Playwright, `e2e/**` | `./fixtures` (`e2e/fixtures.ts`) |

Adding a new directory under `lib/core/`:

1. Add its path to `test:logic` in `package.json`.
2. Add it to `test.exclude` in `vitest.config.ts`; otherwise Vitest collects its tests and fails on `bun:test`.
3. Add it to `BASE_DIRS` in `scripts/check-pure-core.sh` (or `EXTRA_DIRS` if it must also be free of `fetch(`/`new Worker`/`globalThis`).
4. If it should be coverage-gated, add it to `test:coverage` and keep it out of `coveragePathIgnorePatterns` in `bunfig.toml`; if it is only imported transitively by a gated tier, add `**/lib/core/<dir>/**` to that ignore list.

## Coverage gate

The 85% line/function floor in `bunfig.toml` applies **per file**, so a new partially covered file in
a gated dir fails from its first commit. To exempt one file, add its exact path glob to
`coveragePathIgnorePatterns` with a one-line justification; don't lower `coverageThreshold` or
ignore a whole gated dir (the disjointness guard fails CI).

## Boundaries

- `lib/core/**` is pure: no `#imports`, `browser.`, `wxt`, DOM. Browser APIs live in
  `lib/platform/**` (idb, `browser.storage`, messaging). `components/**` (Svelte UI) sits at the
  repo root, not under `lib/`. Import via the `@/` alias rooted at the repo root (`@/lib/...`, `@/components/...`).
- The only live `fetch` is in `entrypoints/background.ts`; the only Worker is
  `entrypoints/replay/parse.worker.ts`. A pure module needing I/O takes it as an injected
  dependency, as with `ChunkFetcher` in `lib/core/retrieval/transport.ts`.
- Each editor has its own closed-world core in `lib/core/{docs,sheets,slides}/{decoder,reconstruction}`;
  shared machinery is `lib/core/replay-core` (snapshot spine), `lib/core/timeline`, `lib/core/summary`.
  `DocumentKind` (`lib/core/domain/kind.ts`) is a boundary-only routing tag: never put it inside a core's op union or model.
- IndexedDB write ownership (`lib/core/store.ts` header): background/orchestrator writes `rawChunks` +
  `checkpoints`; the replay page writes replay publications. The worker only reads raw data and posts results back.
- User-visible strings go in `lib/core/i18n/strings.ts`, not inline in components.

| Persisting... | Put it in |
| --- | --- |
| A user setting or small flag | `storage.defineItem` in `lib/platform/settings.ts` (`local:`; `session:` for in-memory only) |
| Revision data, snapshots, checkpoints | The `RevisionStore` interface (`lib/core/store.ts`), implemented in `lib/platform/db.ts` |

## Change checklists

- **New message**: add the payload type and `ProtocolMap` entry in `lib/platform/messaging.ts`, and
  register its `onMessage("...")` handler inside `defineBackground` in `entrypoints/background.ts`.
- **Store behavior**: `lib/platform/db.ts` (idb) and `lib/platform/db.memory.ts` must behave the same.
  Change both, and cover the change in `lib/platform/db.contract.ts`, which runs against both.
- **Cache invalidation**: bump `DB_VERSION` (`lib/platform/db.ts`) for IndexedDB schema changes. Bump
  `PARSER_VERSION` / `SHEETS_PARSER_VERSION` / `SLIDES_PARSER_VERSION` (`lib/core/{docs,sheets,slides}/decoder/version.ts`)
  for any change to that editor's decode or reconstruction output. Skipping the bump serves stale cached data.
- **Network host or permission**: `docs.google.com` + `storage` is the whole footprint. A new one needs
  `wxt.config.ts`, `allowed_host` in `scripts/check-no-foreign-hosts.sh`, `ALLOWED_PUBLIC_HOSTS` in
  `e2e/network-isolation.spec.ts`, and the expected JSON in `scripts/verify-manifest.sh`. The host guard
  fails on any other `http(s)://` literal in non-comment code under `lib/` or `entrypoints/` (`github.com` is allowed for display links only).
- **New UnoCSS shortcut**: add it to the `shortcuts` const in `uno.config.ts` (`safelist` derives from its keys).
  A bare utility that only one entrypoint emits must be added to `safelist` by hand, or it is dropped from the shared CSS chunk and renders unstyled.

## Generated files

- `manifest.json` is generated by WXT. Change `wxt.config.ts` instead.
- `public/icon/{16,32,48,96,128}.png` are committed but come from `public/icon/docrewind.svg`.
  Regenerate them with `./scripts/generate-icons.sh`.

## Conventions

- Every `.ts`, `.svelte` and `.sh` file starts with an `SPDX-License-Identifier: AGPL-3.0-or-later` comment.
- Entrypoints import `virtual:uno.css`, not `uno.css`. Content-script UI mounts in `createShadowRootUi` with
  `cssInjectionMode: "ui"` and `isolateEvents` (keydown/keyup/click/wheel), so UI code must not rely on those events reaching the host page.
- Color: use the semantic tokens from `uno.config.ts` (`bg-canvas`, `text-ink`, `bg-brand`, ...), not `dark:`
  color variants. The CSS variables switch under `.dark`, which `components/common/theme-sync.svelte.ts` toggles.
- Biome uses experimental full Svelte support for formatting, linting and import organization.
  Exact-path formatter exceptions protect components containing `{@const}`: Biome 2.5.14
  adds invalid parentheses around those declarations. Keep these components formatted by hand
  until a newer Biome release passes `bun run compile`; linting and assists remain enabled.
- `ReplaySurface.svelte` keeps a narrow `noNoninteractiveTabindex` exception because its
  `role="tabpanel"` regions intentionally support keyboard focus.
- Hooks: `bun run hooks:install` (prek) enforces Conventional Commits and `no-commit-to-branch main`, so do the work on a branch.

## Reference

- `.agents/rules/wxt-svelte5-extension.md`: generic WXT / Svelte 5 runes / MV3 background and content-script guidance.
  Read it before writing new entrypoints or components. Where it disagrees with this repo, the repo wins: script names
  (`check` = Biome, `compile` = typecheck), `bun:test` for `lib/core`, `jsdom`, double quotes, `lib/platform/` instead of `utils/`.
- `lib/core/fixtures/README.md`: the fixture corpus's acceptance tiers (`expectedFinalText` is worked out by hand,
  not snapshotted). Read it before adding or changing decoder/reconstruction fixtures.
