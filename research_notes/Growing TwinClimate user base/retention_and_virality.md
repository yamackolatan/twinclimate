# Retention and virality mechanics for consumer fitness and weather utility apps (TwinClimate)

Research note (23 Oct 2026). Method caveat: in this session the page-fetch tool and curl could not reach any external site (DNS and proxy errors). Every finding below therefore comes from search-engine extracts of the cited pages, not from reading the full pages. Treat the exact figures as "reported by the cited page". Where extracts conflicted, that is noted.

## 1. Retention benchmarks (Day-1 / Day-7 / Day-30, DAU/MAU) for health & fitness and weather apps, 2023–2026

### Takeaway
Health & fitness apps keep only about 3–8% of installers by Day 30. Most benchmark pages put Day 1 at about 20–35% and Day 7 at about 7–18%. Weather apps are among the "stickiest" utilities by DAU/MAU: AccuWeather was about 44% in the US in June 2024, and the figure rises and falls with how dramatic the weather is. Benchmark pages disagree a lot and often relabel 2023 data as "2026", so a single number should not be quoted to investors without that caveat.

### Cited Findings
- Health & fitness Day-30 retention was reported as **3% in 2023** (citing Business of Apps data) — [GetStream app retention guide](https://getstream.io/blog/app-retention-guide/)
- Other roundups give fitness Day-30 as **3.5–4%** ([Snoopr 2026 benchmarks](https://www.snoopr.co/blog/mobile-app-retention-benchmarks-2026-what-good-looks-like-for-fitness-ecommerce-gaming-and-more)) and **3.7%** ([Growth-onomics](https://growth-onomics.com/mobile-app-retention-benchmarks-by-industry-2026/)). Other pages claim **8–12%** or a "median 5%, strong performers 8–12%" ([SemNexus](https://semnexus.com/day-1-day-7-day-30-retention-benchmarks-app-category-2026), [Apsteq](https://apsteq.com/blog/app-retention-benchmarks/), [Enable3](https://enable3.io/blog/app-retention-benchmarks-2025)). One roundup attributes a **6–8% Day-30 over the 2023 calendar year to Adjust** — [UXCam](https://uxcam.com/blog/mobile-app-retention-benchmarks/). These sources contradict each other. The range runs from about 20% (Day 1), 7–8.5% (Day 7) and 3% (Day 30) up to 30–35% (Day 1), 15–22% (Day 7) and 8–12% (Day 30), and top apps are claimed to reach about 45% on Day 1.
- OneSignal 2024 (all categories): average **Day-1 28.29%, Day-7 17.86%, Day-30 7.88%** — [OneSignal Mobile App Benchmarks 2024](https://onesignal.com/mobile-app-benchmarks-2024)
- Seasonality (Adjust data via a secondary source): health & fitness installs spike in January. They are **down 6% by February and 20% / 44% lower in April / May**, and sessions decline steeply by April — [Digital Yield Group](https://digitalyieldgroup.com/blog/health-fitness-apps-the-resolutioner-churn-problem/)
- The same source says fitness trackers connected to wearables (Strava, Fitbit) "generally show higher retention" because passive data collection lowers friction — [Digital Yield Group](https://digitalyieldgroup.com/blog/health-fitness-apps-the-resolutioner-churn-problem/)
- **Weather apps, DAU/MAU, US, June 2024:** AccuWeather 44%, The Weather Channel 40%, WeatherBug 38%, MyRadar and Weather Home 32% each. AccuWeather, TWC, WeatherBug and MyRadar each slipped about 2 points year over year. The ratios **rise during intense weather events and fall in calm periods** — [Sensor Tower](https://sensortower.com/blog/inclement-weather-patterns-impact-weather-app-user-stickiness)
- Mixpanel's 2024 Benchmarks report reportedly puts **all-industry DAU/MAU at about 37%**. The older 13% figure reflected B2B SaaS. This is from a secondary page and was not verified against Mixpanel — [AppStorys](https://appstorys.com/blog-Mobile-App-Stickiness-Ultimate-Guide)
- A 30–50% DAU/MAU "healthy range" for fitness and habit-tracking apps is attributed to Mixpanel/Adapty/CleverTap 2026 data. Unverified, and it is unclear which report it comes from — [Builtbyfoundry](https://www.builtbyfoundry.io/blog/what-is-dau-mau-stickiness-creator-apps)
- Mixpanel's average week-1 retention across industries reportedly **fell from 50% to 28% in 2023**. The source is a Mixpanel community AI answer, not an official report — [Mixpanel community](https://community.mixpanel.com/x/ask-ai/msg_maR5MKirQtyt/understanding-mixpanel-retention-rates-and-mau-ben)
- Generic DAU/MAU guides: 10–25% is "standard" and 20%+ signals a habit; social/messaging apps reach 50–70% — [vmobify](https://vmobify.com/blog/dau-mau-stickiness-benchmarks), [Daymark](https://www.usedaymark.io/metrics/dau-mau-stickiness)
- For fitness apps, WAU/MAU is suggested instead of DAU/MAU because weekly use is normal for the category — [PM Toolkit](https://pmtoolkit.ai/how-to/calculate-dau-mau)
- 2025 health & fitness push opt-in (Airship 2025, as reported by a third party): median **54.98% on iPhone and 58.48% on Android**. Median direct open rate **4.25% on iPhone and 6.6% on Android** — [MobiLoud push stats](https://www.mobiloud.com/blog/push-notification-statistics/) (Airship PDF: [Airship 2025 benchmarks](https://growth.airship.com/rs/313-QPJ-195/images/Airship-2025-Push-Notification-Benchmarks-EN.pdf?version=0))
- OneSignal 2024 health & fitness push opt-in: **43.2% on Android and 33.5% on iOS**. This conflicts with the Airship figures above, probably because the methods differ — [OneSignal 2024](https://onesignal.com/mobile-app-benchmarks-2024)

### Inferences
- A realistic investor-facing target for TwinClimate is Day-30 retention clearly above the 3–8% health & fitness band and DAU/MAU near weather-app levels (30–45%). Because the app answers a "what's it like at my session time?" question, it can borrow weather-app frequency rather than workout-app frequency.
- WAU/MAU (sessions per week) is probably the more honest headline metric for a training-session planner, since most amateur athletes train 3–5 times a week, not daily.
- Weather-app stickiness depends on the weather. TwinClimate's usage is likely to peak in shoulder seasons (cold mornings, wet or windy days) and around race season. Its seasonality would then differ from the January "resolutioner" spike seen in general fitness apps. This is an inference; no data was found for weather-plus-kit apps.
- Today TwinClimate is a web-only app with no accounts, so it cannot measure cohort retention across devices. Showing retention to investors will need some form of anonymous analytics or an optional account.

### Gaps
- No primary 2025/2026 Adjust, AppsFlyer, Business of Apps or Amplitude report could be read directly. All the category numbers above come from secondary roundups that disagree.
- No published Day-1/7/30 retention figures specific to weather apps were found, only Sensor Tower's DAU/MAU figures.
- No benchmark was found for a "weather + what to wear" utility (no comparable app publishes figures).

## 2. Habit mechanics for a weather/kit utility (push, widgets, watch, calendar, saved schedule, streaks) — evidence of effect

### Takeaway
The best-evidenced lever is push notifications: Airship reports users who receive pushes in their first 90 days retain about 3x better, and more frequent pushes correlate with higher retention. These are correlations, not controlled trials. Widgets have only case-study evidence (Gratitude: +25% retention for widget users). Streaks have the best-documented experiment (Duolingo: +3.3% relative Day-14 retention), but they suit daily habits better than a 3-times-a-week training tool. TwinClimate is web-only, which blocks native widgets and watch complications. Web push on iPhone works only after the user adds the app to the Home Screen.

### Cited Findings
**Push notifications**
- Airship 2023: users who receive **any** push notification in their first 90 days have **3x higher retention** than those who receive none, and **more frequent notifications correlate with higher retention** — [Airship 2023 benchmarks PDF](https://grow.urbanairship.com/rs/313-QPJ-195/images/Airship-2023-Push-Notification-Benchmarks-en.pdf). Some later secondary coverage describes the same finding as "about a third higher". That conflicts with "3x", so check the PDF before quoting.
- A third-party blog attributes to Airship a study of **63 million users across 1,500 apps** showing retention uplifts versus zero pushes of **+120% (one notification), +440% (weekly) and +820% (daily)**. It gives no date or methodology and blends in a Pushwoosh 2025 study, so these figures are unverified — [MessageFlow](https://messageflow.com/blog/reasons-your-app-needs-mobile-push-notifications/)
- Airship 2026 report: at one airline, users who opted in to push had a **2.9x higher Day-30 activation rate** than users who opted out. This is a single case — [Airship 2026 benchmarks](https://www.airship.com/mobile-app-push-notification-benchmarks-for-2026/)
- **Web constraint:** iOS 16.4 (March 2023) gave web apps added to the Home Screen push and badging. Before that, web apps could not send notifications — [MagicBell](https://www.magicbell.com/blog/pwa-ios-limitations-safari-support-complete-guide), [Notificare](https://notificare.com/blog/2024/02/16/apple-giveth-apple-taketh-away/)
- **EU:** in February 2024 Apple said it would remove Home Screen web apps (including push) for EU users in iOS 17.4, citing the DMA — [The Register, 8 Feb 2024](https://www.theregister.com/2024/02/08/apple_web_apps_eu/). Apple **reversed this before the March 2024 DMA deadline** — [The Register, 2 Mar 2024](https://www.theregister.com/2024/03/02/apple_reverses_pwa_decision/). A MagicBell guide still lists web push as "not available in EU (iOS 17.4+)". That conflicts with the reversal reporting and is unverified — [MagicBell](https://www.magicbell.com/blog/pwa-ios-limitations-safari-support-complete-guide)

**Widgets**
- Android Developers Blog (May 2026): the Gratitude journaling app's interactive home-screen widgets brought **25% higher retention for widget users**. This is self-reported, with no published control group (widget users self-select) — [Android Developers Blog](https://android-developers.googleblog.com/2026/05/how-gratitude-widgets-boosted-user-retention-25-percent.html)
- A glossary page claims widget users show **2.5x higher daily engagement and 45% lower monthly churn**, and cites "a weather app with 55% lower churn". It names no sources, so it is unverified — [Botsi](https://www.botsi.com/dictionary/widget-engagement)
- Duolingo's streak widget runs on the iOS home screen and lock screen — [Duolingo fandom wiki](https://duolingo.fandom.com/wiki/Streak). The widely repeated claim that Duolingo's iOS streak widget raised "user commitment by 60%" traces only to secondary blogs, with no primary Duolingo source — [Orizon](https://www.orizon.co/blog/duolingos-gamification-secrets)

**Streaks**
- Duolingo's reported streak experiment: **+3.3% relative Day-14 retention, +1% daily active learners, and +10.5% share of daily learners with a streak after 20 days**. A "Streak Wager" reportedly improved Day-7 retention by 14%. These come from secondary teardowns of Duolingo's published experiments — [Apsteq Duolingo streak teardown](https://apsteq.com/blog/duolingo-streak-teardown/), [Propel](https://www.trypropel.ai/resources/blogs/duolingo-customer-retention-strategy)
- A claim that streaks lift retention "from 12% to 55%" (attributed to StriveCloud) could not be verified — [Apsteq](https://apsteq.com/blog/duolingo-streak-teardown/)

**Smartwatch**
- Garmin Connect IQ supports **widgets, data fields, device apps, watch faces and audio-content apps**. The SDK was at version 7.4.2 (Jan 2025) — [Garmin Developers](https://developer.garmin.com/connect-iq). Data fields show sensor, activity and history data. Widgets give "information at a glance" — [Garmin manual](https://www8.garmin.com/manuals/webhelp/GUID-08ACA9FC-DEE6-4C8D-8A95-F62181C512E9/EN-GB/GUID-5B6D4B3E-EB70-4869-9D65-3D382A21083A.html)
- Garmin's only download figure found is old: **more than 20 million Connect IQ app downloads to more than 3 million devices** (early years of the store) — [Garmin newsroom](https://www.garmin.com/en-US/newsroom/?p=1441)

### Inferences
- For TwinClimate, the highest-value habit mechanic is likely a **plan-aware evening/morning alert**. Example: "Tomorrow 07:00 Vondelpark run: feels 6°, wet. Gloves + rain shell." It needs a saved weekly training schedule, so the app knows when to alert. CLAUDE.md lists "proactive plan-aware notifications" as V3 and cancelled F5 (packing reminder), so this needs an explicit owner decision.
- On Flutter web, push works on Android/desktop browsers. iPhone users must first "Add to Home Screen". That adds friction, so this is a strong argument for the planned Codemagic native builds (native push, home-screen widget, lock-screen widget).
- A "next session" home-screen widget (felt temperature + one key kit item) fits the product closely. The evidence (Gratitude +25%) is weak but consistently positive.
- Strict daily streaks clash with sensible training (rest days). A weekly "sessions planned/checked" streak or a "feedback given" count fits better, but there is no direct evidence for fitness-utility streaks.
- A Garmin Connect IQ widget or data field ("kit check for today's planned session") would reach a highly engaged audience. It needs separate Monkey C development and is a later-phase item.
- Calendar export (.ics) of planned sessions is cheap on web and keeps sessions visible. No retention evidence was found (see Gaps).

### Gaps
- No evidence was found on how **calendar integration** or a **saved weekly training schedule** affects retention.
- No controlled study was found on widgets or watch complications for weather or fitness apps. All evidence is self-reported case studies.
- No push-timing evidence (evening-before vs morning-of) specific to fitness or weather apps was found.
- No primary source confirms the 2026 EU status of iOS web push. The reversal reporting suggests it still works, but this is unconfirmed.
- No Apple Watch complication usage data was found.

## 3. Integrations as growth channels (Strava API rules 2024–2026, activity-description apps like Klimat, Garmin, Apple Health / Health Connect)

### Takeaway
Writing a line into the user's own Strava activity description is the best-documented organic growth channel for Strava add-ons (Klimat: 80 million activities). It is technically supported (activity:write scope). The 2024–2026 rule changes add heavy friction, though. Data may be shown only to the user who connected it. AI/ML use is banned. New apps start at 1 athlete, can self-upgrade to 10, and need Strava's review for more. Since June 2026 the developer of a Standard-tier app must hold a paid Strava subscription. Club endpoints were removed in September 2026. Strava has also cut off apps before (Relive, 2019) and built its own weather feature (2020), so this channel carries platform risk.

### Cited Findings
**Strava API rules**
- Since **11 Nov 2024**, an app a user has connected may show that user's Strava data **only to that user**. Strava expected under 0.1% of apps to be affected — [Strava Support](https://support.strava.com/en-us/articles/15401608-api-agreement-update-how-data-appears-on-3rd-party-apps), [Strava press](https://press.strava.com/articles/updates-to-stravas-api-agreement)
- API Policy section 2.3, "Display Limited to the Authenticated User": "Strava Data provided by a specific Strava user may be displayed or disclosed in your Developer Application only to that user. You may not display or disclose Strava Data related to other users, even if such data is publicly viewable on the Strava Platform." Section 6.1 suggests an exception for apps with capacity of 9,999 or fewer, but the agreement controls conflicts — [Strava API Policy](https://www.strava.com/legal/api_policy), [Strava API Agreement](https://www.strava.com/legal/api), [Tryterra 2026](https://tryterra.co/blog/strava-api-changes-2026)
- The agreement bars using Strava API materials, directly or indirectly, for **AI/ML model training** or similar — [Marathon Handbook](https://marathonhandbook.com/strava-api-changes/), [Tryterra](https://tryterra.co/blog/strava-discontinues-api). In 2026 AI use is restricted except through Strava's own MCP — [Sahha](https://sahha.ai/blog/strava-api-changes-2026/)
- Coaching: a Strava call reported second-hand (intervals.icu, quoted by DC Rainmaker) suggests coaches can still see athletes' data. This is not an official statement — [DC Rainmaker](https://www.dcrainmaker.com/2024/11/stravas-changes-to-kill-off-apps.html)
- **2026 Developer Program:** developers of Standard-tier apps must hold a paid Strava subscription, from **1 June 2026 (new) and 30 June 2026 (existing)**. Strava's FAQ, as quoted, says there is no extra API fee beyond the subscription. Outlets put it at **$11.99/month** — [Apps for Strava](https://appsforstrava.com/blog/strava-developer-program-changes-2026), [AI Chat Daily](https://www.aichatdaily.com/ai-business/strava-puts-api-behind-11-99-paywall-blaming), [GIGAZINE](https://gigazine.net/gsc_news/en/20260602-strava-ai-scraping/)
- **Capacity:** new apps start in "Single Player Mode" (1 athlete), can self-upgrade to 10 without review, and need Strava's review beyond 10, with no guaranteed timelines. "Extended Access" (10,000+ athletes) is exempt from the subscription requirement. Sources disagree on the exact threshold (">10,000" vs "Standard up to 9,999") — [Sahha](https://sahha.ai/blog/strava-api-changes-2026/), [Strava Getting Started](https://developers.strava.com/docs/getting-started/), [Apps for Strava](https://appsforstrava.com/blog/strava-developer-program-changes-2026)
- Section 5.16 bans routing Strava data through integration platforms, no-code AI platforms, pass-through proxies, intermediaries or aggregators — [Sahha](https://sahha.ai/blog/strava-api-changes-2026/)
- Club Activities, Club Members and Club Admins endpoints were **removed on 1 Sept 2026**. A new base URL arrives on **4 Jan 2027**, with migration required before 1 June 2027 — [Sahha](https://sahha.ai/blog/strava-api-changes-2026/), [strava-mcp GitHub issue](https://github.com/r-huijts/strava-mcp/issues/53), [Strava changelog](https://developers.strava.com/docs/changelog/)
- **Rate limits:** the official docs list a default of **200 requests per 15 minutes and 2,000 per day**. Blogs report 400/15 min and 4,000/day after the 10-athlete upgrade, and others give 100/1,000 for read limits. These conflict — [Strava rate limits](https://developers.strava.com/docs/rate-limits/), [Sahha](https://sahha.ai/blog/strava-api-changes-2026/)
- **Writing to descriptions:** `PUT /activities/{id}` (Update Activity) requires the `activity:write` scope. Updating "Only Me" activities also needs `activity:read_all` — [Apps for Strava API reference](https://appsforstrava.com/developers/api-reference), [Strava hexdocs](https://strava.hexdocs.pm/Strava.Activities.html)
- When several apps write to the same description, there are reportedly "no official guidelines; it's last one wins" — [Strava Community Hub thread](https://communityhub.strava.com/developers-api-7/question-about-updating-activity-descriptions-using-the-strava-api-9125)

**Description-writing apps as a growth channel**
- Klimat writes weather into the Strava activity description "where you and your followers can see them". Newer features sample start, middle and end conditions and add dew point, heat stress (WBGT) and air density — [Klimat](https://klimat.app/strava-weather)
- Klimat had processed **80 million Strava activities** by Feb 2026 — [the5krunner, Feb 2026](https://the5krunner.com/2026/02/03/klimat-strava-weather-review/), [the5krunner on X](https://x.com/the5krunner/status/2018631493338448239). It is a free add-in with a paid tier — [the5krunner 2023](https://the5krunner.com/2023/08/17/air-density-now-on-strava-via-klimat/)
- Strava launched its own built-in weather in 2020, which the5krunner compared against Klimat. Klimat survived, positioned as richer than Strava's native weather — [the5krunner 2020](https://the5krunner.com/2020/04/03/new-strava-weather-service-vs-klimat-strava-add-in/), [the5krunner 2026](https://the5krunner.com/2026/02/03/klimat-strava-weather-review/)
- An open-source "strava weather app" does the same description-writing — [GitHub vol1ura/strava_weather_app](https://github.com/vol1ura/strava_weather_app)
- Documented growth tactics for Strava apps: shareable output, **a line in the athlete's own activity that followers see**, launch posts (r/Strava, Show HN), Strava's channels, clubs, and press. Strava has no obligation to promote third-party apps. Getting past 10 athletes requires Strava's review — [Apps for Strava, "How Apps That Work with Strava Get Their First Users"](https://appsforstrava.com/blog/how-strava-apps-get-users)
- ROVR's sign-up text says the activity lines are **on by default "so others can hear of ROVR"**. Roast My Strava passed **100,000 users** on an Instagram trend in Dec 2025 — [Apps for Strava](https://appsforstrava.com/blog/how-strava-apps-get-users)
- Weather-focused Strava apps were still being listed as working in Sept 2026 (e.g., Route Companion) — [Apps for Strava blog](https://appsforstrava.com/blog)
- **Platform risk:** in July 2019 Strava ended Relive's integration, saying Relive "violates several of the terms that we ask of API partners" — [DC Rainmaker 2019](https://dcrainmaker.com/2019/07/strava-platform-dispute.html)

**Garmin / Apple Health / Health Connect**
- Garmin Connect IQ offers widgets and data fields distributed via the Connect IQ store app, with wireless install to the device — [Garmin Developers](https://developer.garmin.com/connect-iq), [Nasdaq/Garmin PR](https://www.nasdaq.com/press-release/introducing-garminr-connect-iq-app-all-one-store-device-personalization-and-content)

### Inferences
- **A "TwinClimate line" in the user's own Strava description is allowed in practice and fits the product well.** Example: "Felt 7° (11° in sun), wind 18 km/h — wore long-sleeve + gloves · twinclimate.app". It is TwinClimate's version of Klimat's proven loop, extended with "what I wore" and comfort feedback ("felt just right"). Writing to the user's own activity is not displaying other users' data in TwinClimate, so section 2.3 does not obviously block it. That reading is an inference (see Gaps).
- **Blocking or limiting rules for TwinClimate features:**
  - (a) Any "see what your clubmates wore" or group view built from Strava data is blocked by section 2.3, and club endpoints are gone (Sept 2026).
  - (b) Using Strava data to train the comfort profile could fall under the AI/ML ban. The current rule-based learning (count-based steps) is probably not "model training", but get clarity before using Strava data for learning.
  - (c) Growth is capped at 10 users until Strava reviews the app. The founder must pay for a Strava subscription (about $11.99/month) to run a Standard-tier app.
  - (d) A no-code or aggregator route (e.g., Terra-style middleware) is banned under section 5.16.
  - (e) Strava can revoke access (Relive precedent).
- Strava needs OAuth and a server-side token exchange and refresh to keep the client secret off the device. That conflicts with "no backend in MVP" (CLAUDE.md section 3) and would need an owner decision.
- Apple HealthKit and Google Health Connect are native-only APIs (general platform knowledge, not researched here). They cannot be used from the Flutter web preview and would only come with the Codemagic native builds.

### Gaps
- The Strava API Agreement and Policy text on **writing** to activity descriptions (as opposed to displaying data) could not be read in full. No source explicitly confirms or forbids the Klimat-style write-back under the 2026 terms. Ask Strava developer support before building it.
- No Klimat user count or growth timeline was found (only the activity count).
- No public user or growth figures were found for the Garmin Connect Developer Program (activity/health API, which needs business approval) or for Connect IQ in 2025–2026.
- Apple Health and Health Connect rules were not researched in this session.
- No evidence was found on whether the 2026 subscription requirement has reduced the number of new Strava apps.

## 4. Shareable outputs, referrals, club/group features and Wrapped-style recaps — evidence of virality

### Takeaway
Comparable apps' virality comes from **shareable artefacts users post themselves**: Relive (1 in 3 viewed videos shared), Spotify Wrapped (200M users on day 1 and 500M+ shares in 2025), Strava Year in Sport (made free in 2024 with video/static share formats) and Roast My Strava (an Instagram trend drove it past 100k users). No evidence was found that referral programs work for a free fitness utility. Group features are strongly supported by Strava's data (group activities are longer, and people prefer meeting friends in fitness groups), but Strava-sourced group data is now blocked.

### Cited Findings
- **Spotify Wrapped 2025:** **200 million users in its first day**. The prior year took 62 hours to reach 200M — [TechCrunch, Dec 2025](https://techcrunch.com/2025/12/04/spotify-says-wrapped-2025-is-its-biggest-yet-with-200m-users-in-its-first-day). It reached 250 million engagements in less than three days (65 hours), a milestone that took over a week in 2024 — [Variety](https://variety.com/2025/music/news/spotify-wrapped-breaks-own-record-250-million-engagements-1236603493/). Wrapped 2025 was reportedly **shared more than 500 million times, up 41%** on the previous year — [Variety](https://variety.com/2025/music/news/spotify-wrapped-breaks-own-record-250-million-engagements-1236603493/). The 2024 benchmark figures differ between the two outlets.
- **Strava Year in Sport 2024** was **free** for everyone, with **video and static versions** of favourite moments designed for sharing — [Strava Community Hub](https://communityhub.strava.com/what-s-new-10/your-2024-year-in-sport-is-here-8084). The report drew on activities from **135 million people in 190 countries** — [The Running Channel](https://therunningchannel.com/strava-year-in-sport-2024/), [Marathon Handbook](https://marathonhandbook.com/strava-2024-year-in-sport-report/). On release day "social media is flooded" with the visuals (anecdotal) — [Bikepacking.com](https://bikepacking.com/plog/strava-year-in-sport/)
- Strava 2024 findings on group behaviour: runs, rides and hikes with more than 10 people were **40% longer on average** than solo activities, and people are **4x more likely to prefer meeting new friends in fitness groups than in bars** — [Marathon Handbook](https://marathonhandbook.com/strava-2024-year-in-sport-report/), [Yahoo](https://www.yahoo.com/lifestyle/run-clubs-over-night-clubs-195518037.html)
- **Relive** (Dutch, activity-video app): a co-founder said **1 of 3 videos viewed gets shared on social media** and called the product "a marketing tool for its users". It reported **2.3M users, growing about 100k/month** — [Silicon Canals](https://siliconcanals.com/relive-app-3d-video-news/). An earlier Esri article said 1.2M users — [Esri](https://www.esri.com/about/newsroom/?p=80162). The figures are dated (pre-2020).
- **Roast My Strava** passed **100,000 users** on an Instagram trend of athletes posting their roasts (Dec 2025) — [Apps for Strava](https://appsforstrava.com/blog/how-strava-apps-get-users)
- Strava's own engagement is often attributed to gamification and community (clubs, segments, kudos) — [StriveCloud](https://www.strivecloud.io/blog/app-engagement-strava), [Community Inc.](https://community.inc/deep-dives/community-growth-strava). These are analyst pieces without primary metrics.

### Inferences
- Shareable assets that fit TwinClimate:
  - (1) a **"Race-day climate card"** (e.g., "Ironman Kalmar, 29 Aug, 07:00–16:00: typically 17–20°, humid, 30% rain. My closest training match: X, 82%"), designed for Instagram Stories and WhatsApp groups;
  - (2) a **"What I wore today" card** (felt temperature + 5-part kit + "just right");
  - (3) a **"Share session plan" link** for training groups. The link carries place, date, time and sport in the URL, which works with no accounts or backend, and the recipient's app computes their own kit, which is personal by design;
  - (4) a year-end **"Your climate year"** recap (coldest session, wettest, most-used kit item, comfort lessons learned).
- Each card should carry the app URL and look like the user's own achievement or knowledge, not an ad. The Relive and Wrapped pattern is "the user shows themselves off", not "the user promotes the app".
- Because each person's kit is computed by the recipient's own app (their comfort profile), a shared session link drives installs. The friend must open TwinClimate to see "what I should wear", which is a natural loop.
- Group features must use TwinClimate's own sharing (links), not Strava clubs (endpoints removed, display rule).

### Gaps
- No evidence was found on referral programs (give/get rewards) for free fitness or weather utilities, nor on viral coefficients for any comparable app.
- No published share counts were found for Strava Year in Sport.
- No data was found on "what I wore" style shares in any app.
- Relive's growth figures are pre-2020. No current figures were found.

## 5. Personalisation and onboarding (time to value, fitness-utility onboarding, effect of sign-up walls)

### Takeaway
The consistent best practice is "value before sign-up" (gradual engagement, Duolingo's product-first onboarding). Reported lifts are +10–30% activation and +20% trial starts, but those figures come from vendor blogs. TwinClimate's current no-account, ask-nothing-upfront design matches this. Early value matters most because abandonment is fastest right after download.

### Cited Findings
- **Gradual engagement** (a term associated with Luke Wroblewski) lets people use the app before registering, so the effort behind a download isn't wasted at a sign-up wall. Duolingo is the standard example ("use the product first, then sign up"). Masterclass and Instagram show previews before login — [Decode](https://decode.agency/article/app-onboarding-mistakes/), [CleverTap](https://clevertap.com/blog/app-onboarding/), [Plotline](https://www.plotline.so/blog/mobile-app-onboarding-examples)
- A Purchasely A/B test is cited as showing that **delaying account creation until after core value improved trial starts by 20%**. A claim of a **10–30% activation lift** from deferred sign-up is attributed loosely to "Appcues and similar". Neither was verified against a primary report — [Purchasely](https://www.purchasely.com/blog/app-onboarding-process), [All Day Tech](https://alldaystech.com/guides/mobile-development/mobile-app-onboarding-ux-patterns-activation-retention)
- Recommended patterns: a **guest mode whose data attaches to an account when the user registers later**, progressive profiling, and **deferring permission prompts** until users see their value — [All Day Tech](https://alldaystech.com/guides/mobile-development/mobile-app-onboarding-ux-patterns-activation-retention), [Customlytics](https://customlytics.com/mobile-onboarding/)
- Abandonment is **fastest soon after download**. A median of **70% of users discontinue within 100 days** (2024 JMIR scoping review, 18 studies, about 526,000 participants) — [JMIR 2024](https://www.jmir.org/2024/1/e56897)
- Fitness apps "require users to complete workouts, track progress over time and develop habits before experiencing results", which delays value — [Snoopr](https://www.snoopr.co/blog/mobile-app-retention-benchmarks-2026-what-good-looks-like-for-fitness-ecommerce-gaming-and-more)
- Complex onboarding, manual entry, generic content and unclear value are listed among reasons users quit (2026 industry report, weak method) — [Fitness Refined](https://fitnessrefined.co/fitness-app-retention-statistics/), [OpenPR](https://www.openpr.com/news/4602398/fitness-refined-releases-2026-report-on-why-fitness-app-users)

### Inferences
- TwinClimate already gives value in the first minute (pick place, time, sport → kit list) with no account. That is a structural advantage over workout apps whose value arrives weeks later. The first-run screen should go straight to a pre-filled answer (e.g., nearest favourite place, "tomorrow 07:00", run) rather than an empty form.
- An optional account later (for cross-device sync, Strava, retention measurement) should follow the "guest data attaches later" pattern, so the on-device comfort profile is never lost.
- The notification permission prompt (if push is added) should come after the first useful kit list, with an obvious value line ("Get tomorrow's kit the night before?"), not at launch.
- Personalisation that shows learning ("next time we'll suggest a lighter top") is the app's retention moat. Users who give feedback have invested in a profile they would lose by switching apps. This is an inference; no direct evidence was found.

### Gaps
- No primary A/B data was found on sign-up walls specific to fitness or weather apps.
- No benchmark was found for "time to first value" in fitness utilities.
- No evidence was found on whether post-session feedback loops (like F4) improve retention.

## 6. Why users stop using weather/fitness apps (churn reasons)

### Takeaway
Peer-reviewed work points to amotivation and loss of interest, trying other apps, and cost. Industry surveys add manual data entry, complex onboarding, generic content and unclear value. For weather apps, engagement falls when the weather is calm. The free built-in phone weather app is the main substitute.

### Cited Findings
- A cross-sectional survey of 209 mHealth users found **amotivation, loss of interest and experimenting with different apps** to be the critical drivers of abandonment. The **financial cost** of apps also mattered — [PMC8872344](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8872344/)
- A median of **70% discontinue within 100 days**. Abandonment is fastest soon after download, and physical-activity apps last longer than alcohol or smoking apps — [JMIR 2024 scoping review](https://www.jmir.org/2024/1/e56897)
- Manual data entry is commonly cited as the top reason people stop using health apps. This is a secondary claim citing a JMIR survey, not verified — [Sahha](https://sahha.ai/blog/health-app-churn-retention/)
- **Loss of motivation (38%) and free alternatives (25%)** of cancellations, and about 9.2% monthly churn for fitness apps in 2026. No method was disclosed — [RetentionCheck](https://retentioncheck.com/churn-benchmarks/fitness-apps)
- Reasons cited in a 2026 industry report: manual entry, complex onboarding, technical issues, generic content, unclear value — [Fitness Refined](https://fitnessrefined.co/fitness-app-retention-statistics/)
- A "2024 University of Auckland study of 1,200 users" cited by some blogs **could not be corroborated** and should not be used — [Vocal](https://vocal.media/01/why-most-fitness-apps-lose-80-of-users-in-30-days)
- Weather-app DAU/MAU **falls during calm weather** and rises in intense weather — [Sensor Tower](https://sensortower.com/blog/inclement-weather-patterns-impact-weather-app-user-stickiness)
- Fitness installs and sessions decline steeply after the January peak (Adjust, via secondary) — [Digital Yield Group](https://digitalyieldgroup.com/blog/health-fitness-apps-the-resolutioner-churn-problem/)
- Annual subscription plans retain best. Monthly plan retention fell to 17.0% (RevenueCat, via secondary) — [Digital Yield Group](https://digitalyieldgroup.com/blog/health-fitness-apps-the-resolutioner-churn-problem/)

### Inferences
- TwinClimate's specific churn risks:
  - (a) **"My phone's weather app is good enough"** on mild, stable days. Counter: make the kit answer, not the forecast, the hero, and be fastest to that answer.
  - (b) **Re-entering the session each time**, which is the manual-entry problem. Counter: save the weekly training schedule and favourites so the app opens straight to "your next session".
  - (c) **Generic kit advice** that ignores the user. Counter: make the comfort-profile learning visible.
  - (d) **No trigger to come back**, since there are no notifications or widget today. This is the largest gap versus benchmarks.
  - (e) **Off-season** for race matching. Counter: make Quick Session the everyday loop.
- Since the app is free with no subscription, cost-driven churn is not a factor. Free-alternative churn (built-in weather apps, Strava's native weather) is the main competitive risk.

### Gaps
- No churn-reason study specific to weather apps was found.
- No data was found on how often runners or cyclists check weather before sessions, or which app they use.
- No evidence was found on churn for apps with no accounts or notifications versus apps with them in the fitness-utility niche.
