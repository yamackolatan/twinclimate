# CLAUDE.md — permanent project briefing for TwinClimate
# READ THIS FULLY BEFORE WRITING OR CHANGING ANY CODE.
# Then read PROGRESS.md for the current state and the next steps.

This file holds what stays true: what the product is, how it is built, how
to run and test it, the rules, and the feature specifications. **What has
been done, what is unfinished and what to do next lives in `PROGRESS.md`** —
update that file at the end of every session.

## 0. How to work with the owner (most important section)

- The owner, **Yamac**, is **non-technical**. He directs in plain language;
  you do ALL coding, setup, running, testing and debugging.
- Explain what you are doing in simple terms. Never assume he reads code.
  When he must act (click something, approve a dialog, sign up somewhere),
  give exact, numbered steps.
- He mostly works **in a web browser** (cloud Claude Code sessions, code on
  GitHub) and looks at the app on the published website. Since Nov 2026 he
  also has a **Mac laptop** (Xcode can be installed for iPhone builds), but
  keep every step doable without it. The app MUST always work as a
  **Flutter web app**. Never break web support.
- **Standing permission (Nov 2026):** "I confirm every change you want to
  do, don't ask for my permission." Proceed with changes that follow from
  his request without asking first; still stop for anything destructive,
  anything that costs money, and real product decisions (e.g. the app's
  name). Things only he can do (Apple account, payments, GitHub settings)
  are written as numbered steps for him.
- **Do not invent scope or skip scope.** This file is the single source of
  truth for product rules. (There is no `docs/PRD.md`; an older version of
  this file referred to one that never existed.) If the code does not
  match this file, that is a bug to fix.
- At the start of every session: read this file and `PROGRESS.md`, check
  the repository state, and tell the owner in 3–5 plain sentences what
  exists, what is unfinished and what you propose next.
- Work in small increments. After each one: run the checks, look at the
  result in a browser, publish, and tell him how to try it.
- Write to him in plain language: lead with the outcome, say honestly what
  was and was not tested, no jargon.

## 1. What TwinClimate is

**TwinClimate** (working title) — an app for outdoor athletes (runners,
cyclists, triathletes, amateur sportspeople) answering two questions:

1. **Everyday (default mode, "Quick Session"):** "I'm training at place X on
   day Y at time Z — what will conditions be like, and exactly what should I
   wear and bring?"
2. **Race prep ("Race Matching"):** "Where and when, within my travel range,
   can I train in conditions most similar to my target race's race-day
   climate?" Example: a triathlete in Istanbul racing Ironman Kalmar (Sweden,
   29 August) wants the closest Kalmar-like conditions within driving range.

### Product principles (apply to every feature)
- **Result-oriented, minimal taps.** Every screen ends in an actionable
  answer, never raw data alone.
- **Ask once, default everything.** No mandatory forms. Personalization is
  learned progressively, never demanded upfront.
- **Honest matching.** If nothing matches the race climate well, show the
  best option with a transparent similarity % and adaptation advice. Never
  fake a good match.
- **Advice first, commerce second.** Product links (a later phase) appear
  only where context creates real need.

## 2. Confirmed product decisions (do not re-litigate)

1. **Quick Session is the default mode.** A target race is OPTIONAL — a
   nullable property of the user. The app must be fully useful with no race.
2. **Race Matching has two sub-modes**, chosen at the "When" field:
   - **Fixed date:** training plans fix the session date. Optimize the free
     variables: best LOCATION within travel range AND best START TIME window
     on that day. Output: ranked location+time combinations with scores.
   - **Flexible period:** "best day in the next N weeks" — scan period ×
     radius, recommend day+location+time closest to the race fingerprint.
3. **Five body parts** in all gear logic: head, torso, hands, legs, **feet**.
4. **Comfort profile is learned, not asked:**
   - Zero-data baseline: sport defaults (runners breeze-tolerant on
     legs/torso; cyclists warm hands/torso/head).
   - Primary learning loop: 2-tap post-session feedback card — "How did it
     feel?" (too cold / just right / too warm) → optional "where?" (one of
     the five body parts). Each datapoint is anchored to that session's
     measured weather (so the app learns e.g. "runs warm ABOVE 15°C").
   - After feedback, immediately tell the user what was learned ("next time
     we'll suggest a lighter top").
   - Sizes (shoes, garments) are requested only at first product-interest
     moment, never onboarding.
   - An explicit body-map "Comfort profile" editor lives in Settings,
     fully optional.
5. **Every gear suggestion shows its reason** ("you run warm above 15°C",
   "wet forest paths").
6. **Kit list doubles as a packing checklist.** (The optional reminder was
   cancelled by the owner in Oct 2026 — do not build it.)
7. **Forecasts are session-window and coordinate-precise:** hour-by-hour for
   the session hours (e.g. 08:00–10:00) at the exact place coordinates
   (Belgrad Forest ≠ central Istanbul), plus a "feels like at start" line.
8. **Race fingerprint = 10 years of history, race-hour window:** average
   conditions over ±5 days around the race date AND only over the race hours
   (e.g. 07:00–16:00 for a full Ironman), not whole-day means.
9. **Similarity score is sport-weighted and shown to the user:** run →
   temperature & humidity high, wind medium; bike → wind high; swim → water
   temperature. Weights user-adjustable for power users.
10. **Exact routes, not areas (V2):** given area + sport + distance, suggest
    specific loops with surface and elevation, not just a region.
11. **Honest fallback with adaptation notes:** e.g. "6°C warmer than race
    day — consider pacing 10–15 sec/km slower."
12. **No API keys/accounts unless unavoidable.** Open-Meteo is the weather
    provider (free, keyless). If a key ever becomes necessary, explain to the
    owner exactly what to sign up for.

## 3. Tech stack and data sources

- **Flutter** (Dart SDK ^3.12.2; Flutter **3.44.2 stable**, the version the
  website build and Codemagic use). One codebase: **web** (the live site)
  and **iOS** (App Store build). Android is not set up yet. Material 3,
  light and dark mode, shared theme in `lib/theme.dart`.
- **Packages** (`pubspec.yaml`, keep this list small): `http`,
  `shared_preferences`, `url_launcher`, `web` (browser location + share),
  `geolocator` and `share_plus` (location + share in the iPhone app),
  `flutter_localizations` (en_GB: Monday-first calendars, 24-hour clock).
- **Weather and place search: Open-Meteo**, free and keyless, called
  straight from the browser/app (no server of our own):
  - Forecast API (16 days, hourly): temperature_2m, apparent_temperature,
    relative_humidity_2m, precipitation_probability, precipitation,
    wind_speed_10m, wind_gusts_10m, weather_code, is_day,
    shortwave_radiation, wind_direction_10m, uv_index; plus
    `daily=sunrise,sunset`; `timezone=auto` (times are local to the place).
  - Geocoding API for place search.
  - Archive API (ERA5 history) for race fingerprints and "typical weather".
  - Not used yet: Marine API (water temperature, V3), Elevation API (V2).
  - Free-tier limits are per internet address: per minute, per hour
    (~5,000) and per day. A 43-spot request counts as ~43 calls. The free
    API is for **non-commercial use**: if the app ever earns money, move
    to their paid API (needs a key) and tell the owner.
- **Place names: OpenStreetMap Nominatim** reverse geocoding (max 1
  request/second; the app sends a `TwinClimate/<version>` User-Agent).
- All weather calls go through the `WeatherService` interface
  (`lib/services/weather_service.dart`) so the provider stays swappable.
- **Storage:** on the device only (`shared_preferences`; browser storage
  on the web) via `lib/services/prefs_store.dart`: places, last-used
  settings, pace, races with cached fingerprints, comfort profile and
  feedback, session records, owned gear, shop counters. **No backend, no
  accounts, no analytics** — do not add any without the owner asking.
- **Data model rules:** races are optional (0–3); sessions exist with or
  without a race; every gear item carries a `reason`; the comfort profile
  is per sport, per body part, per temperature range.
- Race fingerprints are expensive (10 years of hourly data): compute once
  per race, cache with the race, recompute only when the race changes.

## 4. Folder structure

```
lib/
  main.dart            app start, theme, en_GB locale, 24-hour clock
  app_config.dart      STORE_BUILD switch, shoppingDemo, appVersion
  theme.dart           AppTheme, feelGradient, pagePadding
  models/              plain data: place, session (Sport, SessionPlan, pace),
                       weather, gear, race, fingerprint, matching, comfort,
                       product
  logic/               pure logic, no Flutter UI, unit-tested:
                       gear_engine (kit rules), best_time, weather_text,
                       share_text, fingerprint_builder/_text,
                       typical_weather, match_engine/_text, feedback_logic,
                       shop_logic
  services/            talks to the outside world: weather_service
                       (Open-Meteo), fingerprint_service,
                       typical_weather_service, match_service, place_namer
                       (OpenStreetMap), prefs_store (device storage),
                       device_services*.dart (location + share: _web for
                       the browser, _native for iPhone)
  screens/             quick_session_page (home: Quick Session + Match my
                       race forms), session_result_page, race_form_page,
                       race_detail_page, match_result_page,
                       comfort_profile_page, my_gear_page,
                       partner_demo_page, about_page
  widgets/             hour_cards, kit_checklist, place_search_sheet,
                       feedback_card, races_section, weights_panel,
                       product_sheet
  data/decathlon_catalogue.dart   demo product snapshot (109 products)
test/                  190 tests: unit tests for all logic + widget "flow"
                       tests that walk the screens with fake weather
tool/                  scripts run by hand against REAL weather:
                       check_real_weather, check_real_matching,
                       check_typical, print_kit_table (sandbox_proxy is a
                       helper for cloud sessions)
web/                   index.html, manifest.json, icons, privacy.html,
                       support.html (App Store privacy + support URLs)
ios/                   iPhone project (Info.plist, PrivacyInfo.xcprivacy,
                       app icons)
codemagic.yaml         cloud build of the iPhone app → TestFlight
.github/workflows/deploy-pages.yml   builds and publishes the website
docs/APP_STORE.md      the owner's step-by-step App Store guide + store texts
docs/app-store/        icon-1024.png and four 1290×2796 store screenshots
docs/screenshots/      README screenshots
reports/, research_notes/   growth research (how to attract users)
PROGRESS.md            current state, decisions and next steps
```

## 5. How to run, test and publish

**Flutter is usually NOT installed in a fresh cloud session.** Install the
same version the builds use (about 1.5 GB download, a few minutes):

```bash
mkdir -p /tmp/fl && cd /tmp/fl
curl -sL -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.2-stable.tar.xz
tar xf flutter.tar.xz && rm flutter.tar.xz
git config --global --add safe.directory /tmp/fl/flutter
F=/tmp/fl/flutter/bin/flutter      # use $F below
```

**Checks to run before every commit** (all must be clean):

```bash
$F pub get
/tmp/fl/flutter/bin/dart format lib test
$F analyze                                   # must say "No issues found!"
$F test                                      # all tests must pass
$F test --dart-define=STORE_BUILD=true test/store_build_test.dart test/app_flow_test.dart
$F build web --release --no-web-resources-cdn
```

**Looking at the app in a cloud session.** Cloud sessions cannot reach
Open-Meteo, the live site or decathlon.nl (blocked by the network proxy).
To see screens, serve `build/web` locally and drive it with Playwright
(`/opt/node22/lib/node_modules/playwright`, Chromium at
`/opt/pw-browsers/chromium-*/chrome-linux/chrome`), intercepting
`**open-meteo.com**` and `**nominatim**` with canned JSON (a list response
when `latitude` has several comma-separated values; include
`daily.sunrise/sunset`). Flutter web draws on a canvas: click by screen
coordinates, not by text. Always tell the owner that such checks used
sample weather. On a Mac: `flutter run -d chrome`.

**Publishing the website.** Live at
**https://yamackolatan.github.io/twinclimate/**. GitHub Pages only accepts
deployments from the branch **`claude/relaxed-brown-be0mcz`** (an
environment rule in the repository settings that cannot be changed from a
session). The workflow runs on pushes to that branch (and `main`), runs
the tests, builds and deploys in about 2–3 minutes.
- Do the work on the session's own branch, then publish with
  `git push origin HEAD:<session-branch> HEAD:claude/relaxed-brown-be0mcz`
  (fast-forward only; never force-push that branch).
- Check the result: `gh run list -R yamackolatan/twinclimate -b
  claude/relaxed-brown-be0mcz -L 1`. If a run is "cancelled", re-run it
  with `gh run rerun <id> -R yamackolatan/twinclimate`.
- Add `[skip ci]` to commit messages for docs-only changes.
- There is no `main` branch yet and pull requests are not used.

**iPhone app.** `codemagic.yaml` (workflow "iOS App Store") builds with
`--dart-define=STORE_BUILD=true` and uploads to TestFlight; the owner's
steps are in `docs/APP_STORE.md`. The iPhone build has **never been
compiled or run** (it needs a Mac); see PROGRESS.md.

**Real-weather checks** (only where Open-Meteo is reachable, e.g. a Mac):
`dart run tool/check_real_weather.dart`, `tool/check_real_matching.dart`,
`tool/check_typical.dart`; `tool/print_kit_table.dart` prints the kit for
every temperature range.

## 6. Rules and conventions

Engineering
- `flutter analyze` clean and all tests passing before showing anything.
- Every bug fix and every logic rule gets a test. For a bug fix, check
  that the test fails without the fix.
- Pure logic goes in `lib/logic/` (no UI imports) so it is cheap to test.
- Small, well-named files; the smallest well-maintained packages;
  everything must keep working on Flutter web.
- Commit after each working increment with a **plain-English message the
  owner can understand** (what changed for the user, as a short list).
- Record every new owner decision in this file (rules/specs) or in
  PROGRESS.md (state/next steps) in the same commit.

Product
- Every kit item has a reason. Never invent data: no made-up products,
  prices, ratings or weather. Label typical weather as "not a forecast".
- Advice first, commerce second: shop links are small text links, never
  banners; one switch turns them off.
- The App Store build must never show the Decathlon demo (see section 7,
  "iPhone / App Store").
- European conventions: °C, km, 24-hour clock, weeks start on Monday.
- Screens: use `pagePadding(context)` for page padding (clears the iPhone
  home bar), 640 px max content width, cards styled only by `AppTheme`.
- Privacy promises in `web/privacy.html`, the About screen,
  `ios/Runner/Info.plist` and `ios/Runner/PrivacyInfo.xcprivacy` must stay
  true: no accounts, no tracking, location only on "Use my location".
- decathlon.nl blocks automated reading — do not try to get around it; new
  catalogue products come from web-search listings of real product pages.

Honesty with the owner
- Say what was checked with sample weather versus live weather, and what
  could not be checked at all (iPhone build, real location, share menu).

## 7. Feature specifications with acceptance criteria

These describe how the app must behave. Sections marked "build to these"
are owner decisions; do not re-open them without him asking.

### F1 — Quick Session (the foundation; must exist before anything else)
Inputs: sport (run/bike/swim), place (Open-Meteo search + preset favourites,
e.g. Belgrad Forest / Kilyos / Caddebostan for Istanbul), date (next 16 days),
start time, distance (slider, range adapts to sport).
Output screen:
- Hourly forecast cards covering the session window only (session duration
  estimated from sport + distance; minimum 2 hours shown).
- Summary line: feels-like at start, sky description, humidity, wind note.
- Kit list grouped under HEAD / TORSO / HANDS / LEGS / FEET, each item with a
  reason; rain/wind-triggered items visually highlighted; tappable as a
  packing checklist with an "all packed" state.
ACCEPT: search "Belgrad" → pick → tomorrow 08:00 → 15 km run → screen shows
hourly cards for ~08:00–10:00, a feels-like line, and a 5-section kit list
with reasons. Works in web preview.

**Kit ranges (owner request + research, Oct 2026 — build to these):**
- 10 felt-temperature ranges: <−5, −5–0, 0–4, 4–7, 7–10, 10–13, 13–16,
  16–20, 20–24, 24+ °C. Narrow (~3 °C) where kit changes often (cycling
  guides change kit every 2–3 °C between ~7 and 21 °C; owner: 10–12 feels
  the same, 13–15 needs other kit; below 10 every degree counts).
- Felt temperature for kit = Open-Meteo "feels like" (already includes
  wind chill and humidity, but verified NOT to include sun) **+3 °C in
  strong sun (≥500 W/m²), +1.5 °C in moderate sun (≥250 W/m²), −3 °C when
  wet** (rain ≥0.5 mm or ≥60 % chance). Reasons say so ("Session feels
  like 11°, more like 14° in the sun"). Sport baselines unchanged (run
  torso/legs +3; bike torso/hands −3, head/feet −2).
- Bike tops follow the cycling guides after the −3 baseline: short sleeves
  ~19–27 °C air, + arm warmers 16–19, + gilet 13–16, long-sleeve thermal +
  gilet 10–13, then base layer + jackets. `tool/print_kit_table.dart`
  prints the table for review.

**Beyond the 16-day forecast (owner request, Oct 2026 — build to this):**
- Researched: day-to-day forecast skill fades after ~10–16 days; Open-Meteo's
  35-day ensemble adds only marginal skill in weeks 3–4 (ECMWF), and its
  ~7-month seasonal forecast gives daily summaries/tendencies only. So for
  dates past today + 15 the app shows **typical weather from the last 10
  years** at the exact spot: same clock hours, date ±5 days (same machinery
  as race fingerprints), clearly labelled "Typical weather, not a forecast"
  with the date the real forecast becomes available.
- Quick Session dates go up to a year ahead. Race Matching specific dates
  and "Choose dates" periods too (periods capped at 31 days; beyond the
  forecast a period is ranked on its middle day ±5 days). Race Matching
  fetches history for all 43 spots in one request per year, sequentially
  (per-minute limit). Each 43-spot request is ~650 KB / 1–2 s, but counts
  as ~43 calls against Open-Meteo's free hourly limit (~5,000), so results
  are cached per visit (date + spots) — changing sport, weights or hours
  re-ranks without downloading again.
- Code: `lib/logic/typical_weather.dart`, `lib/services/
  typical_weather_service.dart`; `tool/check_typical.dart` checks it on
  real data.

### F2 — Target race & fingerprint
- Add/edit a target race: name, place (geocoded), date, race start time +
  expected duration window, sport(s). Stored locally; deletable; app fully
  functional without one.
- Fingerprint: for the last 10 years, fetch the race place's hourly history
  for race-date ±5 days, restricted to race hours; compute per-variable mean
  and standard deviation (temp, apparent, humidity, wind, precip probability/
  amount). Cache it. Show the user a readable summary ("Kalmar on 29 Aug,
  07:00–16:00: typically 17–20°C, humid, 15–25 km/h wind, 30% rain chance").
ACCEPT: enter Ironman Kalmar (Kalmar, Sweden, 29 Aug, 07:00, ~9h) → within a
minute a cached fingerprint exists and its summary is displayed.

**Owner decisions for F2 (confirmed Oct 2026 — build to these):**
- **Up to 3 races** saved at once, shown as "My races" cards on the home
  screen (soonest first). With 3 saved, "Add race" is replaced by a note.
- **Separate swim / bike / run fingerprints.** The form has one row per
  ticked sport ("leg") with distance + expected time; legs run back-to-back
  in fixed order swim → bike → run from the start time (duathlons not
  supported yet; transitions ignored). Quick-fill buttons: Sprint / Olympic /
  70.3 / Ironman (triathlon) and 10 km / Half / Marathon (run). Results show
  an overall headline plus one summary per leg. Swim water temperature stays
  in V3.
- **Rain chance** = share of past race days with ≥ 1 mm of rain during the
  race (or leg) hours, plus the typical amount on those wet days. (The
  history archive has no forecast-style "probability".)
- **"Through the race day" line**: start temperature, warmest/coolest point,
  finish temperature.
- **Years** = the 10 most recent years whose race window (date ±5 days) is
  already in the archive.
- Code: `lib/models/race.dart`, `lib/models/fingerprint.dart`,
  `lib/logic/fingerprint_builder.dart` (pure maths),
  `lib/logic/fingerprint_text.dart` (wording),
  `lib/services/fingerprint_service.dart` (one archive request per year).
  `tool/check_real_weather.dart` prints real fingerprints for Kalmar, Kona,
  Istanbul Marathon, Barcelona and Wales for sanity checks.
- Open-Meteo's free tier is limited per internet address per day. Cloud
  sessions share addresses and can hit it ("Daily API request limit
  exceeded"); the owner's browser is not affected.

### F3 — Race Matching
- Entry: same session form, but with travel-range slider and the "When"
  field offering BOTH sub-modes: "Specific date" and "Best day in a period".
- Candidate generation: sample locations within the radius (graded grid or
  curated points; include coast/altitude variety), fetch their session-hour
  forecasts, score each against the fingerprint.
- Scoring: normalized weighted distance across variables; sport-default
  weights (run: temp .35, humidity .3, wind .2, precip .15 — tune as needed);
  expose as 0–100% similarity.
- Fixed-date mode additionally scans candidate START TIMES (e.g. 06:00–18:00
  hourly) and ranks location+time pairs.
- Results: ranked list (top 5) with similarity %, key numbers vs. the race
  ("19°C vs 18°C race typical"), and — when best score < ~70% — adaptation
  notes (pacing, heat-acclimatization pointer).
ACCEPT (fixed): race=Kalmar, from Istanbul, range 150 km, Saturday → ranked
location+time list with scores and honest notes. ACCEPT (flexible): same but
"next 14 days" → day+location+time ranking.

**Owner decisions for F3 (confirmed Oct 2026 — build to these):**
- **Match the same leg as the training sport** (training run → race's run
  leg); if the race lacks that sport, the whole race window.
- **Advise a time window, not just a start time:** each result shows the
  best start plus the run of neighbouring start times scoring within 8
  points of it (never below 70 %; within 5 points for weak matches), as
  "Start between 07:00 and 09:00 → you'd train 07:00–10:30", and a small
  score bar per start time.
- **Place names from OpenStreetMap** (Nominatim reverse geocoding, max 1
  request/second, only for the 5 results); fall back to "38 km north".
- **Top 5 = five different places**, each at its best time.
- **Swim:** air conditions + wind only, with a note to check open-water
  access; water temperature stays in V3.
- **Period mode:** next 7 or 14 days (default 14), **or "Choose dates"**
  (owner request, Oct 2026): a calendar range picker, up to a year ahead,
  at most 31 days long (see "Beyond the 16-day forecast"); the results
  summary reads "best day between Sat 24 Oct and Thu 29 Oct".
- **Training hours are the user's choice** (owner decision, Oct 2026): the
  form asks "When can you train?" — earliest start and latest finish
  (default 06:00–20:00); start times are tried hourly from the earliest
  start while the session still finishes in time. **"Daylight only" is an
  optional switch** (default on): when on, sessions must start and finish
  before dark. Both are remembered on the device.
- Built behaviour: 43 spots in 5 rings out to the travel range; sea spots
  (forecast height 0) dropped; score = 100·e^(−D²/2.88) where D is the
  weighted gap measured in the race's own standard deviations (one spread
  off ≈ 70 %); sport-default weights run .35/.30/.20/.15, bike
  .30/.15/.35/.20, swim .40/.15/.35/.10 (temp/humidity/wind/rain),
  adjustable under "Advanced: what matters most".
- Code: `lib/models/matching.dart`, `lib/logic/match_engine.dart` (pure
  maths), `lib/logic/match_text.dart`, `lib/services/match_service.dart`,
  `lib/services/place_namer.dart`, `lib/screens/match_result_page.dart`.
  `tool/check_real_matching.dart` runs the acceptance cases on live
  forecasts.

### F4 — Comfort profile & feedback loop
- After a session's start time passes, the home screen shows the 2-tap
  feedback card (see decision 4). Store each response with that session's
  weather aggregates.
- Profile adjusts gear bands per body part (e.g. two "too warm, torso"
  reports above 15°C → shift torso recommendations one band lighter when
  forecast ≥15°C) and the affected items' reasons mention it ("you run warm
  above 15°C").
- Settings → "Comfort profile": per-body-part cold↔warm slider, optional.
ACCEPT: give "too warm → torso" feedback twice on warm runs → next warm-run
kit shows a lighter torso item with a personalized reason.

**Owner decisions for F4 (confirmed Oct 2026 — build to these):**
- **Card timing:** after the session's expected *finish* (not its start);
  only the most recent finished session; disappears after 3 days;
  "I didn't go" / "Not now" close it.
- **Feedback design (chosen after research, see conversation):** 2 taps —
  how did it feel → optional where (5 parts or "Everywhere"). **Only on
  uncomfortable days**, an optional third question: "We suggested: X. Did
  you wear that?" (Yes / Something warmer / Something lighter / Skip). It
  is skipped when the **packing checklist** already shows the suggestion
  was packed (ticks are saved and double as "what you wore"). Too warm in
  something warmer, or too cold in something lighter, is not learned from.
- **Learning (updated Oct 2026, owner asked for finer ranges):** 8 ranges
  that follow the kit ranges — below 0, 0–4, 4–7, 7–10, 10–13, 13–16,
  16–20, above 20 °C (felt temperature). A report counts fully in its own
  range and half in each neighbouring range (so learning stays quick);
  two matching reports = one step = one kit range lighter/warmer; "just
  right" cancels one report; max ±2 steps; "Everywhere" counts for all
  parts; separate profiles per sport.
- **Multiple answers (owner request, Oct 2026):** "Too cold" and "Too
  warm" can both be picked (→ Next), and several body parts per feeling
  (→ Done; each row needs ≥1; "Everywhere" excludes specific parts; a part
  can't be both warm and cold). "Just right" stays a single tap. Each
  feeling + part is stored as its own answer; "Did you wear that?" is asked
  once — naming the item only when a single part was picked — and skipped
  when the checklist shows every picked part's suggestion was packed.
- **Weather anchor:** the session's actual recorded "feels like" (forecast
  API, past days), falling back to the forecast shown; the message says
  when the two differed by 3 °C or more.
- **Ask less once it knows you:** after 4 "just right" in a row for a sport
  and zone, only every third finished session is asked about.
- Items changed by the profile get a reason prefix ("You run warm above
  15°C, so this is lighter than usual."); unchanged items get none.
- Settings → Comfort profile (person icon on the home screen): Run / Bike /
  Swim tabs, a −2…+2 slider per body part, "What we've learned" with
  Forget, recent feedback with delete, Reset everything.
- Code: `lib/models/comfort.dart`, `lib/logic/feedback_logic.dart`,
  `lib/widgets/feedback_card.dart`, `lib/screens/comfort_profile_page.dart`;
  gear engine takes an optional `ComfortProfile`.

### F5 — Packing reminder — CANCELLED by the owner (Oct 2026)
Replaced by the two shopping features (F5a, F5b) below.

### Market & demo status (owner decision, Oct 2026)
- The owner lives in **Amsterdam**; the app is built for the **EU**.
  Quick-pick places: Vondelpark, Amsterdamse Bos, Sloterplas, Zandvoort.
- This is a **demo/trial** to attract investors and brand partners. No real
  orders: shop links simply open the product page on **decathlon.nl** (NL
  only). No partnership exists yet — every product area says "Shop links
  go to decathlon.nl. Demo — not affiliated with Decathlon."
- **Catalogue method:** decathlon.nl blocks automated reading (Cloudflare
  bot check) — do NOT try to get around it. The catalogue in
  `lib/data/decathlon_catalogue.dart` is a dated snapshot (`catalogueDate`)
  compiled from web-search listings of real decathlon.nl product pages:
  real names and links; price, rating and review count only where the
  listing showed them, otherwise null — never invented. Icon cards, no
  product photos.
- **Not pushy rules:** ~~at most 3 shop links per kit list~~ — changed by
  the owner in Nov 2026: **every kit suggestion gets a shop link** (the
  limit left most items without one). Still a small text link, never a
  banner; one switch
  turns all suggestions off (menu → My gear & shopping); the race-day kit
  is folded away until opened.
- **Owned gear keeps its link (owner request, Oct 2026):** "I already have
  this" (or ticking an item while packing) saves it in "My gear", but the
  link stays — people may want to see other models. It then reads "You
  have one — see other models at Decathlon"; the sheet says "Other models
  at Decathlon" and "You have one — saved in My gear". Owning doesn't
  change which items get links. Race-day picks the user owns stay too,
  with "You have one — another model to consider".

### F5a — Kit shopping (Quick Session)
- Under kit items the user may not own: "Don't have one? See options at
  Decathlon" → a sheet with the item's reason and 1–3 products matched by
  product type and function (`itemProductTypes` in `lib/logic/
  shop_logic.dart`), each with brand, price, rating (or "Reviews on
  decathlon.nl"), what it's good for, and "View at decathlon.nl" (new tab).
- Ranking: rating shrunk towards 4.0★ until there are enough reviews, plus
  a small popularity bonus — a 4.7★ product with 1,000 reviews beats 5★
  with 3; unrated last.

### F5b — Race-day kit (Race Matching)
- Below the matched places: "Race-day kit for <race>" (folded), up to 5
  picks chosen from the race's typical weather (wetsuit below 20 °C,
  trisuit for triathlons, gels for races ≥ 90 min, electrolytes when warm
  or humid, rain jacket when ≥ 30 % of race days are wet, gilet for windy
  bike legs, cap/top, bottle, soft flask, race belt, gloves, sunscreen),
  each with its reason. Per need, the best-rated product; unrated only
  when its type has no rated one.

### Partner demo screen
- Opened by **long-pressing the "TwinClimate" title** on the home screen
  (not in the menu; hidden in the App Store build): suggestions shown,
  opened, clicks to shop, "already
  have it", shown → shop rate, most opened needs, most clicked products.
  Counted on the device only; reset button. For pitching to brands.
- Code: `lib/models/product.dart`, `lib/data/decathlon_catalogue.dart`,
  `lib/logic/shop_logic.dart`, `lib/widgets/product_sheet.dart`,
  `lib/screens/my_gear_page.dart`, `lib/screens/partner_demo_page.dart`;
  tests in `test/shop_test.dart` (every kit item must lead to at least
  one catalogue product; `noShopItems` is empty).

### App review improvements (owner-approved, Nov 2026 — build to these)
- **Bugs fixed:** packing ticks tracked by item name (survive redraws);
  forecast hours without a temperature are skipped (never read as 0 °C);
  history downloads run one year at a time and wait once (~65 s) on the
  per-minute limit; race-day kit uses only the race's own sports;
  comparing start times for one day/sport replaces the earlier untouched
  session record.
- **Ease of use:** first visit pre-picks the last place or Vondelpark;
  date defaults to today if the usual start time is ≥30 min ahead, else
  tomorrow; Now / Today / Tomorrow / Other day chips; session form first,
  races below; "Use my location" (browser geolocation + Nominatim name);
  result screen has Share (Web Share API, clipboard fallback), Change,
  and 1 h earlier/later; Partner demo is opened by long-pressing the
  TwinClimate name (removed from the menu); Comfort profile also in ⋮.
- **More advice (all with reasons):** dark sessions (before sunrise /
  after sunset from Open-Meteo `daily=sunrise,sunset`, else `is_day`) →
  headlamp + reflective vest (run), front/rear lights (bike, legally
  required after dark), lit tow float (swim); sunscreen at UV ≥ 3
  (`uv_index`); water from 1 h (or 30 min when kit-feels ≥ 22 °C),
  electrolytes from 1.5 h at ≥ 20 °C, gel/snack from 1.5 h; wind
  direction (`wind_direction_10m`) in summary and hour cards, bike tip to
  ride out into the wind; "Better at HH:MM" hint scans ±4 h the same day
  (`lib/logic/best_time.dart`); Swim has Open water / Pool (pool kit, no
  neoprene); optional personal pace per sport (`formatPace`,
  `paceChoices`). Since Nov 2026 lights, reflective gear, shoes, pool kit
  and tow floats have catalogue products too (`noShopItems` is empty;
  `test/shop_test.dart` fails if any suggestion has no product). New
  products must be real decathlon.nl pages found via web search — never
  invented.
- **Look:** `lib/theme.dart` (AppTheme, `feelGradient`); colour headline
  card by felt temperature with a one-line verdict (`sessionVerdict`);
  hour timeline card with rain bars; kit rows tag rain (blue) / wind
  (violet), packing progress bar, per-part icon + count, empty parts on
  one line; two columns on screens ≥ 1000 px; 640 px max width on all
  pages; web manifest/description updated.

### iPhone / App Store (owner request, Nov 2026 — build to these)
- iOS project in `ios/` (bundle id `com.yamackolatan.twinclimate`, iPhone
  only, portrait, display name "TwinClimate", version from pubspec
  `1.0.0+N`). Built and uploaded to TestFlight by Codemagic
  (`codemagic.yaml`, workflow "iOS App Store"); the owner's Mac + Xcode is
  an alternative route.
  Owner setup steps and store texts: `docs/APP_STORE.md`.
- **Store build = `--dart-define=STORE_BUILD=true`** (`lib/app_config.dart`):
  hides the Decathlon shopping demo (shop links, race-day kit, My gear &
  shopping, Partner demo) — Apple guidelines 2.2 (no demos) and 5.2
  (third-party brands). The website keeps the demo. `test/store_build_test.dart`
  checks it (`flutter test --dart-define=STORE_BUILD=true ...`).
- Location and sharing: browser APIs on the web, `geolocator` /
  `share_plus` in the app (`lib/services/device_services*.dart`).
  `NSLocationWhenInUseUsageDescription` and `ios/Runner/PrivacyInfo.xcprivacy`
  (precise location, app functionality, not linked, no tracking) must stay
  in step with what the app actually does.
- Nominatim requests from the app send a `TwinClimate/<version>` User-Agent.
- About & privacy screen (⋮ menu) with Open-Meteo (CC BY 4.0) and
  OpenStreetMap attribution; public pages `web/privacy.html` and
  `web/support.html` are the App Store privacy and support URLs. Keep
  `appVersion` in `lib/app_config.dart` equal to pubspec's version.
- Open-Meteo's free API is for non-commercial use: if the app ever earns
  money, move to their paid API (key) and tell the owner.

### Second review (owner-approved, Nov 2026 — build to these)
- European conventions app-wide: locale `en_GB` (weeks start Monday) and
  24-hour clock (`lib/main.dart`, `flutter_localizations`).
- Every scrolling page uses `pagePadding(context)` (`lib/theme.dart`) so
  content clears the iPhone home indicator. Cards take their look from
  `AppTheme` — don't hand-style `elevation`/`surfaceContainerLow`.
- Lights/"dark" advice and the better-time hint allow 20 min of twilight
  (`twilight` in `lib/logic/gear_engine.dart`).
- Race Matching remembers travel range, date/period mode and 7/14 days
  (`PrefsStore.rememberMatch`). Race detail has a colour headline and a
  "Find where to train like this" button that returns to the home screen
  in Match mode for that race. Match result cards: rank badge, score ring,
  "Here vs race typical" grid; the best match is outlined.
- Race form asks before discarding unsaved changes. Loading screens say
  what they're doing; error messages never show raw exception text; links
  open in the system browser (`LaunchMode.externalApplication`).
- Known limitation (not fixed): "now" comes from the phone's clock, so for
  places in another time zone "Now", "start time has passed" and "1 h
  earlier" can be off by the time difference.

### Later phases (do NOT start without the owner asking)
- V2: exact route suggestions (OSM/Overpass + loop generation, elevation,
  surface), cycling-specific matching, Turkish localization.
- V3: real affiliate links / partner feeds, size capture at intent, swim
  water temperature, Strava/Garmin, proactive plan-aware notifications.

## 8. Roadmap

F1–F4, the shopping demo (F5a/F5b), two review rounds and App Store
preparation are built. **What is open and what comes next is in
`PROGRESS.md`.** V2/V3 items above are not to be started without the owner
asking.
