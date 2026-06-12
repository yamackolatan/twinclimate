# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this project is

**TwinClimate** — a Flutter **web** app that compares the climates of two
cities and ranks "climate twins" for a chosen home city. The owner is
non-technical and uses Claude Code from the browser: keep explanations
jargon-free, keep the app deployable as a static site, and verify changes
visually (screenshots) before pushing.

The app is entirely client-side with a bundled dataset — no backend, no API
keys, no third-party packages beyond the Flutter SDK. Keep it that way
unless there's a strong reason.

## Layout

| Path | Purpose |
| --- | --- |
| `lib/models.dart` | `City` model (12-month highs/lows/precip), month names, °F conversion |
| `lib/data.dart` | Bundled dataset: 46 cities, approximate 1991–2020 climate normals |
| `lib/similarity.dart` | Twin Score (0–100): mean monthly difference of highs/lows + log-scaled precipitation; tries both calendar alignment and a 6-month shift (cross-hemisphere twins) |
| `lib/main.dart` | App shell: two tabs (Compare / Find my twin), city pickers, °C/°F toggle |
| `lib/widgets/` | Custom-painted charts (temp band chart, rainfall bars), score card, facts cards, ranked twin list |
| `test/similarity_test.dart` | Data sanity + scoring behavior tests |
| `.github/workflows/deploy-pages.yml` | Builds and deploys to GitHub Pages on push |
| `docs/screenshots/` | Screenshots embedded in the README |

## Commands

```bash
export PATH="/opt/flutter/bin:$PATH"   # cloud sessions: see below
flutter pub get
flutter analyze                         # keep at zero issues
flutter test                            # keep green
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8080 -d build/web   # serve the built app
```

**Always build with `--no-web-resources-cdn`.** It bundles the CanvasKit
renderer into `build/web/` instead of loading it from gstatic.com at
runtime. Roboto is likewise bundled as an asset (see `pubspec.yaml`); both
choices make the app fully self-contained — it must keep working with no
runtime CDN access.

## Cloud (web) session setup

The Claude Code cloud container does **not** ship Flutter. Install it with:

```bash
curl -sL -o /tmp/flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.2-stable.tar.xz
tar xf /tmp/flutter.tar.xz -C /opt && rm /tmp/flutter.tar.xz
git config --global --add safe.directory /opt/flutter   # required, or flutter commands fail
export PATH="/opt/flutter/bin:$PATH"
```

(Check `https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json`
for the current stable version. Consider moving this into the environment's
setup script so it's cached across sessions.)

## Verifying changes visually

There is no port preview in cloud sessions. Verify with headless Chromium
(Playwright is preinstalled globally):

```bash
python3 -m http.server 8080 -d build/web &
NODE_PATH=$(npm root -g) node screenshot-script.js
```

Two sandbox quirks the script must handle:

- Launch contexts with `locale: 'en-US'` — headless Chromium otherwise
  reports a locale Flutter can't parse and the app crashes at startup.
- Flag emoji render as boxes in the sandbox (the Noto emoji font comes from
  gstatic.com, which the sandbox proxy blocks). Harmless in real browsers.

Send the screenshots to the user — they can't run the app any other way
mid-session.

## Deployment

`.github/workflows/deploy-pages.yml` builds, tests, and deploys to GitHub
Pages on every push to `main` or `claude/**`, publishing at
`https://yamackolatan.github.io/twinclimate/`. The `--base-href` is set from
the repo name; keep that in sync if the repo is ever renamed. Pages requires
the repo to be public on GitHub's Free plan.

## Data and roadmap

`lib/data.dart` values are approximate climate normals written for v1 —
plausible and clearly labeled as approximate in the UI. Planned v2: search
any city via the free Open-Meteo geocoding + climate API (CORS-friendly, no
key) with the bundled dataset as offline fallback. Keep the bundled data as
the guaranteed-working path.
