# CLAUDE.md — Complete project briefing for Claude Code
# READ THIS FULLY BEFORE WRITING OR CHANGING ANY CODE.

## 0. How to work with the owner (most important section)

- The owner, Yamac, is **non-technical**. He directs in plain language; you do
  ALL coding, setup, running, testing, and debugging.
- Explain what you're doing in simple terms. Never assume he reads code.
  When he must act (clicking something, approving a dialog), give exact,
  numbered steps.
- The owner works **in a web browser only** (cloud Claude Code sessions, code
  hosted on GitHub). He has no personal computer and cannot install software.
  Therefore: the app MUST always be runnable as a **Flutter web preview** he
  can open in his browser. Never break web support. Phone builds come later
  via a cloud build service (Codemagic), not via a local machine.
- **Do not invent scope or skip scope.** This file is the single source of
  truth. The full PRD is in `docs/PRD.md`. If the current code does not match
  this file, the gap is a bug to fix, not a decision to revisit.
- At the start of every session: briefly audit the codebase against the
  roadmap (section 6), tell the owner in 3–5 plain sentences what exists,
  what's missing or broken, and what you propose to do next. Then wait for
  his go-ahead.
- Work in small increments. After each feature, run it in the web preview and
  walk the owner through testing it before moving on.

## 1. What this product is

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
6. **Kit list doubles as a packing checklist** with an optional reminder
   (evening before / morning of session).
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

## 3. Architecture & data sources

- **Client:** Flutter (single codebase: web preview now; Android + iOS later
  via Codemagic cloud builds). Material 3. Works in light and dark mode.
- **Weather & geocoding:** Open-Meteo, all keyless:
  - Forecast API (16-day hourly): temperature_2m, apparent_temperature,
    relative_humidity_2m, precipitation_probability, precipitation,
    wind_speed_10m, wind_gusts_10m, weather_code. timezone=auto.
  - Geocoding API for place search.
  - Historical/Archive API (ERA5, hourly back decades) for race fingerprints.
  - Marine API for water temperature (swim, later phase).
  - Elevation API (route profiles, V2).
- Keep all provider calls behind a single `WeatherService` interface so the
  provider stays swappable.
- **Persistence (MVP):** local on-device only — shared_preferences or similar
  that works on Flutter web — for: favourites, target race, comfort profile,
  feedback history, sizes. A backend comes later; do not build one until the
  roadmap says so.
- **Caching:** race fingerprints are expensive (10 years × hourly). Compute
  once per race+date, cache locally, never recompute unless race changes.
- **Data model rules:** races are optional (a list of 0–3, see F2); sessions exist with or
  without a race link; gear items always carry a `reason` string; comfort
  profile stores per-body-part, temperature-banded preferences.

## 4. Feature specifications with acceptance criteria

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

### F5 — Packing reminder
- Toggle on the result screen; local notification evening before (19:00) or
  morning-of with conditions + kit highlights. On web preview, where
  notifications are limited, an in-app "upcoming session" banner is the
  acceptable fallback — say so to the owner rather than silently skipping.

### Later phases (do NOT start without the owner asking)
- V2: exact route suggestions (OSM/Overpass + loop generation, elevation,
  surface), cycling-specific matching, Turkish localization.
- V3: product alternatives via affiliate links, size capture at intent, swim
  water temperature, Strava/Garmin, proactive plan-aware notifications.

## 5. Engineering conventions
- `flutter analyze` clean before showing anything to the owner.
- Add widget/unit tests for the gear engine and the similarity scoring (pure
  logic — cheap to test, costly to get wrong).
- Small, well-named files; prefer the smallest well-maintained packages;
  everything must keep working on Flutter web.
- Commit after each working increment with a plain-English message the owner
  can understand.

## 6. Roadmap order (build strictly in this order)
1. F1 Quick Session — restore/complete it fully, including the 5-part kit
   checklist with reasons. **This comes BEFORE any matching work.**
2. F2 Target race + fingerprint.
3. F3 Race Matching (fixed-date first, then flexible-period).
4. F4 Feedback loop + comfort profile.
5. F5 Packing reminder.
Then stop and review with the owner before any V2/V3 work.

## 7. Current state warning
An earlier session implemented only a city-level climate-similarity feature
and skipped the foundation. FIRST TASK of the next session: audit the code
against sections 4 and 6, report the gaps in plain language, then rebuild
toward F1. Reuse any sound matching code for F3 — but F1 comes first.
