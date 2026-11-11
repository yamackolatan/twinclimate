# PROGRESS.md — where TwinClimate stands

Last updated: **11 November 2026**. Update this file at the end of every
session. Permanent rules and feature specifications are in `CLAUDE.md`;
this file is the current state, the reasons behind decisions, and what to
do next.

## 1. Snapshot

- **Live website:** https://yamackolatan.github.io/twinclimate/ (Flutter
  web, published by GitHub Pages from branch `claude/relaxed-brown-be0mcz`).
- **Code state:** everything described below is committed and published.
  Latest app commit: "Long race-match periods use the real forecast;
  small polish". `flutter analyze` clean, **208 tests pass**, web build
  succeeds.
- **Branches:** `claude/relaxed-brown-be0mcz` = the published one;
  `claude/confident-goldberg-0g8kdx` = last session's working branch (same
  content). No `main` branch, no pull requests.
- **Version:** 1.0.0+1 (`pubspec.yaml`; `appVersion` in
  `lib/app_config.dart` must match).
- **iPhone app:** project and cloud-build recipe are in the repository,
  but it has **never been built or run**. Nothing is in the App Store yet.
- **Name:** still "TwinClimate". The owner chose **"Acclimate"** as the new
  name but the rename is **on hold** until he checks trademarks (see 5).

## 2. What has been built (in order)

1. **Quick Session (F1).** Home form: Run / Bike / Swim tiles (Swim: open
   water or pool), place (search, quick picks Vondelpark / Amsterdamse Bos /
   Sloterplas / Zandvoort, recent places, "Use my location"), Now / Today /
   Tomorrow / Other day, start time, distance slider, optional personal
   pace. Result screen: colour headline card by felt temperature with a
   one-line verdict, sunrise/sunset, wind direction, hour-by-hour timeline
   with rain bars, "Better at HH:MM" hint, 1 h earlier/later, Share, and
   the kit list for head / torso / hands / legs / feet with a reason per
   item, rain/wind tags and a tap-to-pack checklist.
2. **Kit rules.** 10 felt-temperature ranges, sun (+) and wet (−)
   adjustments, sport baselines, lights and reflective gear in the dark
   (20 min twilight allowed), sunscreen at UV ≥ 3, water / electrolytes /
   food on long or warm sessions, pool kit.
3. **Beyond the forecast.** Dates more than 16 days ahead (up to a year)
   show "Typical weather, not a forecast" from the last 10 years.
4. **Target races (F2).** Up to 3 races; triathlon legs; quick-fill
   distances; 10-year race-day climate per race and per leg, cached.
5. **Race Matching (F3).** From a starting point and travel range: top 5
   places with a match score, best start window, score bars and a
   "here vs race typical" comparison; specific date or best day in a
   period; user's training hours; daylight-only switch; weights under
   "Advanced". Race detail has a "Find where to train like this" button.
6. **Comfort profile (F4).** "How did it feel?" card after a finished
   session (multiple answers, optional "did you wear that?"), learning per
   sport / body part / temperature range, manual sliders, forget/reset.
7. **Shopping demo (F5a/F5b).** "Don't have one? See options at
   Decathlon" under **every** kit item, product sheet with real
   decathlon.nl products, "My gear & shopping", race-day kit on match
   results, Partner demo counters (long-press the app title).
8. **Two review rounds (Nov 2026).** Bug fixes, easier first use, more
   advice, new look, iPhone layout safety, Monday-first calendars and
   24-hour clock, clearer race screens. Details in `CLAUDE.md` section 7.
9. **App Store preparation.** `ios/` project (bundle id
   `com.yamackolatan.twinclimate`, iPhone only, portrait), app icon,
   location permission text, privacy manifest, About & privacy screen,
   `web/privacy.html` + `web/support.html`, `codemagic.yaml`,
   `docs/APP_STORE.md` (owner's steps + store texts), four store
   screenshots in `docs/app-store/screenshots/`.
10. **Growth research** in `reports/` and `research_notes/` (how to attract
    and keep users; first milestone suggested there: 300–500 weekly users).
11. **Time zones, honest long periods, polish (11 Nov 2026).** All "now"
    decisions use the clock at the training place (home screen notes the
    difference, e.g. "1 h ahead of you"); a Race Matching period that
    runs past the 16-day forecast uses the real forecast for the days it
    covers and typical weather only for the later days; Back buttons in
    the feedback card; Undo for comfort "Forget"/delete; "Widen range"
    on weak matches; scores in words under the score bars; one rain
    measure for race day and typical weather (≥ 1 mm in those hours).

## 3. What is working, and how it was checked

- **Automated:** 208 tests covering the kit rules, session window, race
  climate maths, matching, typical weather, comfort learning, shop rules,
  weather parsing and widget "flow" tests through every main screen. The
  App Store variant is tested with `--dart-define=STORE_BUILD=true`.
- **Seen in a browser (cloud session, SAMPLE weather):** home (light,
  dark, desktop), result screen, place search, race form, race detail,
  match form and results, kit list with links. On 11 Nov 2026 also: the
  time-difference note, feedback card Back buttons, Comfort profile Undo,
  "Widen range" (50 → 100 km re-search), score text and rain footnote.
  The mixed forecast/typical period was checked by tests only.
- **On the live site with real weather:** used by the owner. Earlier
  sessions also ran the `tool/check_*` scripts against real Open-Meteo
  data for race climates, matching and typical weather.

## 4. What is unfinished, unverified or known to be wrong

Not verified at all
- **The iPhone build.** Never compiled. First Codemagic or Xcode build may
  need fixes (signing, CocoaPods/Swift Package setup, `geolocator` and
  `share_plus` on iOS, the privacy manifest entry added by hand to
  `ios/Runner.xcodeproj/project.pbxproj`).
- **"Use my location"** (needs a real browser/phone permission prompt) and
  the **phone share menu** (falls back to copying the kit list).
- **New Decathlon product links (Nov 2026).** Found via web search; the
  product pages could not be opened from a cloud session. The owner was
  asked to tap a few to confirm.
- **iPhone layout fixes** (bottom safe area) — only reasoned from code.

- **Time zones with real data.** Checked with sample offsets only; a real
  check: pick a place abroad (e.g. Kona) and see the "h behind you" note
  and "Now" in its local time.

Known limitations (not fixed)
- **Time zones, small gaps:** Race Matching assumes every spot shares the
  starting point's time zone (fine within 300 km almost everywhere). If
  the time-zone request fails, the phone's clock is used, as before.
- **Close-but-not-exact products:** "Headlamp or chest light" links to a
  clip-on hip light; "Bright tow float with a light" links to a float
  without a light (closest real product pages found).
- **Mixed periods compare two kinds of weather:** a day from the forecast
  and a day of typical (averaged) weather are ranked against each other;
  averages are smoother, so typical days can look slightly more "steady".
  Each such result is labelled.
- **Rain on match cards:** race day and typical weather now share one
  measure (share of past days with ≥ 1 mm in those hours). A forecast
  can't count past days, so forecast results show the forecast's own
  rain chance; the footer says so.
- **Feedback card:** more than 2 taps for "too cold/warm" (by owner's
  multi-answer design).
- **Undo bar** from the Comfort profile stays visible for a few seconds
  after going back to the home screen (Undo still works there).
- **Partner demo counters:** race-day kit picks are never counted as
  "shown"; opening a sheet counts once per product type.
- **Swim:** no water temperature (planned V3); open-water advice is based
  on air temperature and says so.
- **No offline mode:** results are not cached; no connection = error
  screen with "Try again".
- `codemagic.yaml` still has the placeholder `APP_STORE_APPLE_ID:
  0000000000`.
- `README.md` roadmap does not yet mention the two review rounds or the
  iPhone preparation in detail — refresh when next touched.

## 5. Waiting on the owner

1. **Name.** He picked "Acclimate". Before renaming he should search
   **ACCLIMATE** at tmdn.org/tmview (filter EUIPO and BOIP; look at classes
   9, 42, 41, 25) and see whether App Store Connect accepts the name. What
   a web search found: no App Store app with that name; US trademarks only
   for clothing, heated garments, sunscreen and medical heaters (none for
   software); an unrelated "AcclimateAI" travel-packing tool on Product
   Hunt (closest risk); acclimate.com is taken. EU/Benelux registers could
   not be searched from a cloud session. Suggested store title:
   "Acclimate: What to Wear & Where to Train". **Do not rename until he
   says "go ahead".** The rename touches: app title and texts in `lib/`,
   `web/index.html`, `web/manifest.json`, `web/privacy.html`,
   `web/support.html`, `ios/Runner/Info.plist` (display name; the bundle
   id can stay), the Nominatim User-Agent, `docs/APP_STORE.md`,
   `README.md`, `CLAUDE.md`. The website address
   (`/twinclimate/`) follows the repository name and would stay unless the
   repository is renamed.
2. **App Store steps** in `docs/APP_STORE.md`: join the Apple Developer
   Program ($99/year), register the app ID, create the app, create an API
   key, connect Codemagic (or use Xcode on his Mac), then send the app's
   **Apple ID number** so it can replace the placeholder in
   `codemagic.yaml`.
3. **Tap-test the new Decathlon links** on the live site.
4. Optional: GitHub → Settings → Environments → `github-pages` → allow
   other branches (or create `main`), so publishing no longer depends on
   one branch name.

## 6. Decisions and why

- **Quick Session is the default; races are optional.** Most days people
  just want to know what to wear; race prep is the special extra.
- **Open-Meteo, no keys, no backend, device-only storage.** The owner is
  non-technical: nothing to sign up for, host or pay for; also the basis
  of the "no account, no tracking" privacy promise.
- **Typical weather beyond 16 days instead of long-range forecasts.**
  Research showed forecast skill fades after ~10–16 days; honest averages
  from 10 years beat a pretend forecast. Always labelled.
- **Race climate = 10 years, ±5 days, race hours only.** Whole-day
  averages hide what the athlete actually meets on the course.
- **Finer temperature ranges (10 for kit, 8 for learning).** Owner: below
  10 °C every degree matters; cycling guides change kit every 2–3 °C.
- **Comfort is learned from short feedback, never asked up front**, and
  packing ticks double as "what you wore" to avoid extra questions.
- **Packing reminder cancelled (Oct 2026)** in favour of the shopping
  demo, to have something to show brands and investors.
- **Decathlon links are a labelled demo, no partnership.** Real product
  pages on decathlon.nl; catalogue is a dated snapshot built from web
  search because decathlon.nl blocks automated reading.
- **Link on every kit item (Nov 2026)** replaced the earlier "at most 3
  links" rule: the owner saw the missing links as a defect.
- **App Store build hides the whole shopping demo.** Apple rejects apps
  labelled "demo" (guideline 2.2) and use of another company's brand
  without permission (5.2). The website keeps it for pitches.
- **Amsterdam quick picks, EU conventions** (°C, km, 24-hour clock,
  Monday-first): the owner lives in Amsterdam and targets the EU.
- **Pre-picked place and Today/Tomorrow chips:** first visit should give an
  answer in one tap ("ask once, default everything").
- **Lights only outside 20 minutes of twilight:** advice triggered by a
  session ending a minute after sunset felt wrong.
- **History downloads one year at a time with one wait on the per-minute
  limit:** parallel bursts tripped Open-Meteo's free limit and failed the
  whole result.
- **Publishing only from `claude/relaxed-brown-be0mcz`:** GitHub's Pages
  environment rule; pushes to other branches used to start a failing
  publish that could cancel the real one, so the workflow trigger was
  narrowed.
- **iPhone only, portrait:** avoids extra iPad screenshots and layouts for
  the first release.
- **Name:** "TwinClimate" only describes race matching; "Acclimate" covers
  both dressing for today's conditions and training for race conditions.

## 7. Next steps, in priority order

1. **Get the first iPhone build working** once the owner has done the
   Apple/Codemagic steps (or on his Mac with Xcode): put the Apple ID
   number in `codemagic.yaml`, run the build, fix whatever fails, install
   via TestFlight, and check on a real iPhone: location permission, share
   menu, bottom spacing, links opening in Safari, dark mode.
2. **Rename to Acclimate** when the owner confirms (see 5.1), including
   new store screenshots and store texts; keep bundle id unless he wants
   it changed before the first upload (it cannot change afterwards).
3. **Submit to App Review** using the texts in `docs/APP_STORE.md`; handle
   any rejection feedback the owner pastes in.
4. ~~Time zones~~, ~~honest long periods~~ and ~~the polish list~~ — done
   11 Nov 2026. Still open from that list: refresh `README.md`.
5. **Better product matches** for headlamp/chest light and lit tow float
   if real decathlon.nl pages can be found; refresh catalogue prices
   (snapshot dated Oct–Nov 2026).
6. **Growth, only when the owner asks** (from `reports/`): privacy-
   friendly analytics, a landing page and own domain, shareable session
   links, club outreach in Amsterdam.
7. **Later phases, only when the owner asks** (`CLAUDE.md` section 7,
   "Later phases"): routes, Turkish, real affiliate links, water
   temperature, Strava/Garmin, notifications, Android.

## 8. Practical notes for the next session

- Install Flutter first (commands in `CLAUDE.md` section 5); it takes a
  few minutes and is needed for every check.
- Cloud sessions cannot reach Open-Meteo, the live site, decathlon.nl,
  Product Hunt or the trademark databases. Web search works.
- To publish: push to the session branch **and**
  `claude/relaxed-brown-be0mcz` in one command, then confirm the Pages run
  is green (re-run it if "cancelled").
- The Decathlon demo and the App Store build are two variants of one
  codebase; test both after touching shopping code.
- The owner reads screenshots more easily than descriptions: after visual
  changes, capture the screens (Playwright with mocked weather) and send
  them.
