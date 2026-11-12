<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->

<p align="center">
  <img src="public/icon/docrewind.svg" alt="docrewind logo" width="256" height="256">
</p>

<h1 align="center">docrewind</h1>

<p align="center"><strong>Replay Google Docs revision history locally in your browser.</strong></p>

<p align="center">
  <a href="https://github.com/edbfi/docrewind/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-AGPL--3.0--or--later-blue?style=flat" alt="License: AGPL-3.0-or-later"></a>
  <a href="https://github.com/oven-sh/bun"><img src="https://img.shields.io/badge/Bun-000000?style=flat&amp;logo=bun&amp;logoColor=white" alt="Bun"></a>
  <a href="https://github.com/wxt-dev/wxt"><img src="https://img.shields.io/badge/WXT-67D55E?style=flat" alt="WXT"></a>
  <a href="https://github.com/sveltejs/svelte"><img src="https://img.shields.io/badge/Svelte-FF3E00?style=flat&amp;logo=svelte&amp;logoColor=white" alt="Svelte"></a>
  <a href="https://github.com/microsoft/TypeScript"><img src="https://img.shields.io/badge/TypeScript-3178C6?style=flat&amp;logo=typescript&amp;logoColor=white" alt="TypeScript"></a>
</p>

Local-first browser extension that reconstructs and replays the revision history
of a Google Doc — entirely on your own machine, with no backend, account, or
telemetry.

## Build from source

DocRewind is **Bun-only**. Both the Chromium and Firefox MV3 extensions are built
from one codebase by [WXT](https://wxt.dev).

```sh
bun install --frozen-lockfile
bun run --bun postinstall      # wxt prepare — generates .wxt/ types
bun run --bun build            # → .output/chrome-mv3
bun run --bun build:firefox    # → .output/firefox-mv3
```

Load the unpacked build:

- **Chromium:** open `chrome://extensions`, enable **Developer mode**, click
  **Load unpacked**, and select `.output/chrome-mv3`.
- **Firefox:** open `about:debugging#/runtime/this-firefox`, click **Load
  Temporary Add-on…**, and select the `manifest.json` inside `.output/firefox-mv3`.

### Extension icon

The brand icon lives at `public/icon/docrewind.svg`. The sized PNGs WXT wires into
the manifest (`public/icon/{16,32,48,96,128}.png`) are **committed** so the build
stays deterministic and free of a build-time rasterizer. Re-render them only when
the art changes:

```sh
./scripts/generate-icons.sh   # needs librsvg (rsvg-convert) or ImageMagick
```

## Usage

1. Open a Google Doc you can already access.
2. Activate DocRewind via its in-page affordance (it never auto-loads history).
3. DocRewind retrieves and reconstructs the revision history locally, then opens
   the replay tab.
4. Play, pause, change speed, or scrub the timeline. Clear cached data anytime
   from the options page.

Clicking the toolbar icon opens a small popup with a one-line description and
quick access to **Options** and an **About** panel (version, author, license,
source). It opens no document data and requests no extra permissions.
