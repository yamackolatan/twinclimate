# Metrics, privacy-friendly analytics and brand partnerships for TwinClimate (investor / Decathlon readiness)

Research note, 23 Oct 2026. Method caveat: in this session, direct page fetching was blocked for almost all domains (AP, plausible.io, posthog.com, lennysnewsletter.com and decathlon.nl all failed or returned 403). Every finding below comes from search-engine result extracts of the cited URLs. Where only secondary or vendor sources were available, that is flagged. Anything not sourced is marked as an inference or a gap.

## Key Question 1: Which metrics do investors and brand partners want, and what are "good" thresholds for an early consumer (health and fitness) app?

### Takeaway
Investors judge early consumer apps mostly on retention (cohort curves), engagement frequency (DAU/MAU or "L5+") and how fast and how organically active users grow. The headline user count matters much less. Public benchmarks: DAU/MAU of 25% is OK, 40% good, 50%+ great (a16z). Six-month retention of about 25–30% is "good" for consumer social or transactional apps, 40% for consumer SaaS (Lenny Rachitsky). Health and fitness apps typically keep only about 20% of users on day 1, about 8% on day 7 and 3–4% on day 30, so beating those figures is a credible story.

### Cited Findings
**Engagement / stickiness**
- a16z benchmark for DAU/MAU (from private benchmarks of hundreds of early-stage social apps): OK = 25%, Good = 40%, Great = 50%+ — [a16z, "Do You Have Lightning In a Bottle? How to Benchmark Your Social App" (Mar 2023)](https://a16z.com/do-you-have-lightning-in-a-bottle-how-to-benchmark-your-social-app/)
- a16z also tracks "L5+", the share of users active 5–7 days per week: OK = 30%, Good = 40%, Great = 50%+ — [a16z (2023)](https://a16z.com/2023/03/03/how-to-benchmark-your-social-app)
- a16z seed-stage consumer social monthly user growth targets: 20% OK, 35% good, 50% great, "ideally mostly organic" — [a16z (2023)](https://a16z.com/do-you-have-lightning-in-a-bottle-how-to-benchmark-your-social-app/)
- a16z measures N-day retention "in its strictest form" (e.g., day 30: active exactly on day 30), not rolling or unbounded retention — [a16z (2023)](https://a16z.com/2023/03/03/how-to-benchmark-your-social-app)
- Andrew Chen (former a16z growth partner): DAU/MAU above 20% is said to be good and 50%+ is world class, but different product categories have different healthy numbers — [andrewchen.com, "DAU/MAU is an important metric"](https://andrewchen.com/dau-mau-is-an-important-metric/); Andrew Chen also wrote on retention vs. frequency by mobile category — [andrewchen.com](https://andrewchen.com/retention-versus-frequency-for-mobile-product-categories/)

**Retention benchmarks (Lenny Rachitsky / Casey Winters survey of ~20 growth practitioners)**
- User retention: consumer social ~25% good / ~45% great; consumer transactional ~30% good / ~50% great; consumer SaaS ~40% good / ~70% great; SMB/mid-market SaaS 60/80; enterprise SaaS 70/90 — [Lenny's Newsletter, "What is good retention?" (issue 29)](https://www.lennysnewsletter.com/p/what-is-good-retention-issue-29)
- A secondary write-up defines this as the share of signed-up users still active six months later. A reader comment on the original asks whether it is N-day or unbounded, and the extract gave no answer — [foundersfuel summary](https://foundersfuel.beehiiv.com/p/good-great-retention); [Lenny's Newsletter comments](https://www.lennysnewsletter.com/p/what-is-good-retention-issue-29/comments)
- Lenny's piece includes a disclaimer section, "why it may be OK for your retention to be low" — [Lenny's Newsletter](https://www.lennysnewsletter.com/i/465580/disclaimer-why-it-may-be-ok-for-your-retention-to-be-low)

**Health & fitness day-N retention (app-industry data, secondary compilations)**
- Adjust 2022 data: health & fitness day-1 retention 24% — [Adjust, "What makes a good retention rate"](https://www.adjust.com/blog/what-makes-a-good-retention-rate/)
- AppsFlyer data via Business of Apps (reported by Braze): health & fitness day-30 retention 3.9% iOS, 3.4% Android. Braze says day-30 benchmarks range from about 1% to 15% by category, and recommends "classic" rather than rolling retention for fitness apps, because rolling retention always reads higher — [Braze, "App retention: how to measure, benchmark and improve it"](https://www.braze.com/resources/articles/mobile-app-retention)
- Compilation (citing Statista, AppsFlyer, Adjust, Business of Apps): health & fitness ~20% D1, ~8% D7, ~3–4% D30 — [lovable.dev guide](https://lovable.dev/guides/what-is-a-good-retention-rate-for-an-app)
- Cross-industry Adjust medians: D1 ≈ 26%, D7 ≈ 13%, D30 ≈ 7% — [Adjust](https://www.adjust.com/blog/what-makes-a-good-retention-rate/)
- "40-20-10" rule of thumb (D1 40% / D7 20% / D30 10%) is now treated as top-tier. A more realistic "good" profile is cited as 35/15/5, and one compilation gives health & fitness as D1 ~20–27%, D7 ~7%, D30 ~3%. No authoritative origin for the rule was found — [Playio 2026 benchmarks](https://blog.playio.co/d1-d7-d30-retention-benchmarks-2026); [CleverTap](https://clevertap.com/blog/mobile-app-retention/)
- An attributed AppsFlyer 2025 finding: the average app loses over 70% of users within 30 days of install (secondary attribution) — [EngageLab](https://www.engagelab.com/blog/increase-app-retention)

**Growth rate**
- Paul Graham ("Startup = Growth", Sept 2012): a good growth rate during YC is 5–7% a week; 1% a week compounds to 1.7x a year and 5% a week to 12.6x. Measure revenue, or active users if you don't charge yet. 10%/week is exceptional; 1% suggests the business isn't figured out yet — quoted in [TechCrunch (2016)](https://techcrunch.com/2016/12/18/growth-as-a-false-signal-in-y-combinator-startups/?ncid=rss) and [Lean Analytics notes (Goodreads)](https://www.goodreads.com/notes/18897969-lean-analytics/55716289-michael-michael/160c6fd6-3fb2-4bd5-9976-e1ee1ed5b1e9)
- Critique: the 2016 TechCrunch piece argues the "5% club" became a ritual, and notes that Sam Altman and others at YC cautioned against growth at all costs — [TechCrunch](https://techcrunch.com/2016/12/18/growth-as-a-false-signal-in-y-combinator-startups/?ncid=rss)

**How European consumer traction is judged**
- Sifted's Consumer 100 ranking (pre-seed to Series C) scores fundraising, funding velocity, investor quality and headcount growth. For consumer traction it uses app-store performance, ratings, web traffic, search interest and social mentions, and judges then rate "reach, habit and buzz" — [Sifted Consumer 100 (2026)](https://sifted.eu/rankings/sifted-consumer-100-2026)
- Pre-seed investors are described as backing conviction, market size and founder profile rather than traction; at seed they want users, MRR and a working product (third-party guide) — [Pitchwise, "Top pre-seed investors in Europe (2026)"](https://www.pitchwise.se/blog/top-pre-seed-investors-in-europe-2026)
- Sifted describes first-cheque investors as often writing cheques "before there is a product, a pitch deck or — in some cases — even a company" — [Sifted, "Where Europe's most active pre-seed investors are looking next"](https://sifted.eu/articles/where-europes-most-active-pre-seed-investors-are-looking-next)

**Affiliate / partner metrics**
- Impact.com 2025 benchmark report (via secondary): affiliate conversion rates fell 6% year on year while clicks rose 2%; Awin guidance puts typical affiliate conversion at 0.5–1% — [FloatingCTA affiliate benchmarks 2026](https://floatingcta.com/insights/affiliate-marketing-conversion-rate/) (see KQ3 for sports-specific figures)

### Inferences
- TwinClimate is a session-driven utility: people train 2–5 times a week, not daily. WAU, weekly cohort retention (W1/W4/W8) and "sessions planned per active user per week" are therefore more honest headline metrics than DAU/MAU. a16z's L5+ is designed for daily social apps and would understate a training-day tool. A useful equivalent: the share of weekly-active users who plan 2 or more sessions a week.
- A suggested investor and partner metric set, all eventually measurable with an event-based tool:
  1. Weekly and monthly active users (WAU/MAU), and WAU/MAU ratio.
  2. Weekly cohort retention curve; the key sign is whether it flattens.
  3. Week-over-week growth of active users, split organic vs. paid/referral.
  4. Kit lists generated per active user.
  5. Feedback-card response rate (proof the comfort-learning loop works).
  6. Race-matching runs and saved races (a power-user signal).
  7. Shop-link impressions → opens → clicks to decathlon.nl (CTR).
  8. "Already have it" rate (a gear-ownership signal brands value).
  The app's existing on-device "Partner demo" screen already defines items 4 and 7–8. They just need to be counted centrally.
- Beating the health & fitness D30 baseline of about 3–4% (e.g., 10%+ D30, or a flattening weekly curve) would be a stronger signal to investors than a large but leaky signup number. Large signup counts without retention are a known red flag under all these frameworks.
- Investors treat growth "mostly organic" as a quality signal (a16z). Paid-acquired users should be reported separately from word-of-mouth, club and race-community users.

### Gaps
- No primary 2024–2026 European VC source (e.g., Atomico, Dealroom, Sifted) giving concrete user-count or retention thresholds for pre-seed or seed consumer apps was found. Search returned only rankings and generic guides.
- Lenny's newsletter text itself could not be opened, so the exact time window (6-month) definition is from a secondary source.
- The a16z benchmarks are for social apps (2023). No a16z benchmark specific to fitness or utility apps was found.
- No benchmark was found for consumer weather or sport-utility apps specifically.

## Key Question 2: Which privacy-friendly analytics tools work with Flutter web (and later mobile), what do they cost, and what do Dutch/EU consent rules require?

### Takeaway
In the Netherlands, Telecommunicatiewet art. 11.7a requires consent for storing or reading anything on a user's device. Analytics with "no or minor" privacy impact is exempt, provided there is a processor agreement and no third-party own-use. Default Google Analytics 4 / Firebase is widely considered to need consent, so a cookie banner is required. EU-hosted, cookieless tools are designed to fit the exemption: Plausible, Simple Analytics (Amsterdam), Umami, Matomo in a privacy configuration, and PostHog EU configured without persistent identifiers. For a Flutter web demo with custom events ("kit generated", "shop link clicked"), PostHog EU (1M events/month free, official Flutter SDK incl. web) or Umami Cloud's free tier are the cheapest. Plausible has the strongest cookieless/EU story, but its Dart package is weak.

### Cited Findings
**Dutch law and AP position**
- Art. 11.7a Tw requires consent for storing or reading information on a user's device. It carves out strictly necessary cookies and certain privacy-friendly analytics (the 2015 amendment) — [ICTRecht](https://www.ictrecht.nl/blog/tracking-cookies-zonder-geldige-toestemming-autoriteit-persoonsgegevens-stuurt-waarschuwingsbrieven); [NJB, "Uitzondering cookiebepaling"](https://www.njb.nl/wetgeving/staatsbladen/uitzondering-cookiebepaling/)
- The parliamentary explanation said analytics cookies used only to chart and analyse website use have minor privacy effects, so neither notice nor consent is required. ACM stressed this applies only with "no or only minor" privacy impact. If a third party analyses the data, a processor agreement is needed and the third party may not use the data for its own purposes — [Kamerstuk 24095-344](https://zoek.officielebekendmakingen.nl/kst-24095-344.pdf); [Emerce](https://www.emerce.nl/achtergrond/wel-geen-toestemming-nodig-google-analytics) (2013–2015 era sources)
- A commercial 2026 compliance guide lists practical conditions: no sharing of personal data with third parties, IP masking, no cross-site profiling, no advertising features, and a processor agreement. It says self-hosted Matomo, Plausible and Fathom fit, while default GA4 usually does not. This is a blog checklist, not official AP criteria — [Legiscope, "Cookiewet Telecommunicatiewet 11.7a: gids 2026"](https://www.legiscope.com/blog/cookiewet-telecommunicatiewet-2026.html)
- The AP updated its "Handleiding privacyvriendelijk instellen van Google Analytics" on 13 Jan 2022 and warned that GA use "may soon no longer be permitted" after the Austrian DSB decision. The guide was later removed from the AP site without public explanation, and the AP never took a final substantive position on GA4 — [DDMA](https://ddma.nl/kennisbank/google-analytics-verboden-ap-doet-onderzoek/); [Turing Advocaten](https://www.turing.law/nl/de-cookiebrief-van-de-autoriteit-persoonsgegevens-en-het-gebruik-van-google-analytics-4/); [Sens Juristen](https://www.sensjuristen.nl/blog/google-analytics-mogelijk-verboden/)
- A Dutch privacy firm (April 2024) said opinions differ on GA4, and that the AP will likely take the view that consent is required — [privacy-web.nl](https://privacy-web.nl/en/nieuws/google-analytics-cookies-plaatsen-zonder-toestemming-mag-dat/)
- AP enforcement on banners: in April 2025 the AP reportedly published nine rules for cookie banners (no pre-ticked boxes, neutral wording, equal prominence for accept/refuse). Five 2024 investigations led to changes, and about 50 organisations got warning letters in April 2025 — [Epurple (secondary)](https://epurple.nl/kennisbank/cookiewet-2025-zo-maak-je-jouw-cookie-banner-ap-proof/); [ICTRecht](https://www.ictrecht.nl/blog/tracking-cookies-zonder-geldige-toestemming-autoriteit-persoonsgegevens-stuurt-waarschuwingsbrieven)
- In March 2025 the AP asked the Ministry of Economic Affairs to make the AP (instead of ACM) the supervisor for art. 11.7a Tw. Enactment was not confirmed in the results — [AP, "Voorstel AP toezicht cookies"](https://www.autoriteitpersoonsgegevens.nl/documenten/voorstel-ap-toezicht-cookies)
- One blog claims limited analytics cookies fall under "gerechtvaardigd belang" from 2025. No official source confirmed this; treat it as unreliable — [Morgan Black](https://www.morganblack.nl/de-impact-van-de-nieuwe-cookie-regelgeving-2025-update/)
- The European Commission withdrew the ePrivacy Regulation proposal in 2025, so the Telecommunicatiewet and GDPR still govern — [Law & More](https://lawandmore.nl/de-nieuwe-e-privacy-verordening-wat-betekent-dit-voor-uw-cookies-en-digitale-marketing/)

**EU-level**
- EDPB Guidelines 2/2023 on the technical scope of ePrivacy Art. 5(3) (final v2.0, 7 Oct 2024) say the rule is not limited to cookies or personal data. It reaches tracking pixels and links, device fingerprinting, and local processing where information is sent off the device. In short, "cookieless" does not automatically mean "outside the consent rule" — [EDPB guidelines PDF](https://edpb.europa.eu:443/system/files/2024-10/edpb_guidelines_202302_technical_scope_art_53_eprivacydirective_v2_en_0.pdf); [Hunton Andrews Kurth](https://www.hunton.com/privacy-and-cybersecurity-law-blog/edpb-publishes-guidelines-to-clarify-scope-of-eu-cookie-notice-and-consent-requirements)
- France's CNIL (a useful EU reference for what "exempt analytics" looks like) moves audience measurement from opt-in to opt-out if: users are informed and can object; the purpose is limited to audience measurement/A/B testing; no cross-checking with other processing; one publisher per tracker; the last byte of the IP is truncated; lifetime is capped at 13 months — [CNIL Sheet n°16](https://cnil.fr/en/node/677)
- Matomo self-assesses that its Cloud and On-Premise versions meet the CNIL criteria only when configured in CNIL mode (vendor claim). Matomo materials reference a CNIL publication of 4 July 2025 with a self-assessment tool — [Matomo FAQ](https://matomo.org/faq/how-do-i-configure-matomo-without-tracking-consent-for-french-visitors-cnil-exemption/); [Matomo CNIL self-assessment PDF](https://matomo.org/wp-content/uploads/2026/04/CNIL-Consent-Exemption-Self-Assessment-Table.pdf)
- A French agency blog claims Matomo, Plausible and Umami "properly configured" qualify for the CNIL exemption. This is unverified by CNIL — [Agence Scroll](https://agence-scroll.com/en/blog/google-analytics-alternatives-cnil-exemption)
- EU–US transfers: on 3 Sept 2025 the EU General Court dismissed the Latombe challenge (T-553/23) and upheld the 2023 EU–US Data Privacy Framework. DPF-certified US firms can, for now, receive EU personal data, though an appeal is possible. This addresses the transfer problem, not the consent requirement — [King & Spalding](https://www.kslaw.com/insights/articles/framework-intact-for-now-eu-us-data-flows-dodge-another-bullet); [Privacy Company](https://www.privacycompany.eu/blog/latombe-v-european-commission-the-dpf-ca-tombe)

**Tools: hosting, cost, Flutter fit (prices from secondary comparison sites unless stated; verify on vendor pages)**
- **PostHog (EU cloud):**
  - Cost: first 1M product-analytics events/month free, then from $0.00005/event — [PostHog pricing](https://posthog.com/pricing).
  - Hosting: PostHog Cloud EU runs in AWS eu-central-1 Frankfurt as a fully separate instance; the region is chosen at signup and moving later needs support on paid plans — [PostHog Cloud EU blog](https://posthog.com/blog/posthog-cloud-eu); [PostHog privacy docs](https://posthog.com/docs/product-analytics/privacy).
  - Flutter: the official `posthog_flutter` SDK supports iOS, Android, macOS and Web — [PostHog Flutter docs](https://posthog.com/docs/web-analytics/installation/flutter).
- **Plausible:**
  - Company and hosting: incorporated in Estonia; data on Hetzner servers in Falkenstein, Germany; no cookies or persistent identifiers; IP + user agent are hashed with a daily-rotating salt and the raw IP is not stored — [european-alternatives.eu](https://european-alternatives.eu/product/plausible.io); [Plausible GitHub](https://github.com/plausible-insights/plausible).
  - Cost: cloud from ~$9/month for 10k pageviews, Growth $14, Business $19 (funnels); self-hosted Community Edition free (AGPL) — [apiscout comparison](https://apiscout.dev/blog/plausible-vs-umami-vs-fathom-analytics-2026); [DEV Community](https://dev.to/vikasprogrammer/6-best-google-analytics-alternatives-in-2026-i-checked-every-price-2i5m).
  - Flutter: the community Dart `plausible` package marks pageviews and custom events as unchecked in its feature list — [pub.dev plausible](https://pub.dev/documentation/plausible). Plausible has an events API that can be called directly — [GitHub](https://github.com/plausible-insights/plausible).
- **Simple Analytics:**
  - Company: headquartered in Amsterdam.
  - Cost: a permanent free plan with 1 user, 5 websites, 30 days of history and a required badge; paid from about €/$20/month for 100k pageviews. Prices conflict between sources — [Outmano](https://outmano.com/tools/simple-analytics/pricing); [freetier.co](https://freetier.co/directory/products/simple-analytics); [frontdeskreview](https://frontdeskreview.com/software/web-analytics/simple-analytics/).
- **Umami:**
  - Licence: MIT, free to self-host.
  - Cost: Cloud Hobby is free (100K events/month, 6 months retention; 1 or 3 sites, sources differ); Pro $20/month for 1M events; Business $200/month for 10M. Umami counts each pageview and each stored event property as an event — [Cloudzy review (Oct 2026)](https://cloudzy.com/blog/umami-review/); [Softwr](https://www.softwr.com/pricing/umami).
  - Flutter: no Flutter/Dart package found — [search result summary, pub.dev](https://pub.dev/documentation/plausible).
- **Fathom:** $15/month for 100K pageviews, rising to $100 for 2M; EU isolation, no cookies and no PII are listed as included on every plan; no free tier; closed source — [Comparedge](https://comparedge.com/tools/fathom-analytics/pricing); [apiscout](https://apiscout.dev/blog/plausible-vs-umami-vs-fathom-analytics-2026)
- **Matomo:** self-hosted is free. Cloud entry prices conflict (from €29/month for 50k hits with Frankfurt hosting, vs. ~$19/month), and premium plugins such as heatmaps or funnels cost extra — [KI-Syndikat (DE)](https://www.ki-syndikat.de/tools/matomo/); [toolradar](https://toolradar.com/tools/matomo/pricing)
- **Firebase / GA4 on Flutter:** Google's Flutter consent-mode guide (UMP SDK) covers analytics_storage alongside the ad purposes. It requires the Google Analytics for Firebase SDK, initialised before UMP, and advanced consent mode is the default. This implies a consent-banner flow for EU users — [Google AdMob Flutter consent mode](https://developers.google.com/admob/flutter/privacy/consent-mode?hl=en)

### Inferences
- **For TwinClimate now (Flutter web demo, no budget):** the most practical route is PostHog EU (free up to 1M events/month, official Flutter web SDK, funnels and retention cohorts built in). It must be configured not to persist an identifier on the device without consent, or it should sit behind a simple consent prompt. Umami Cloud Hobby (free, 100K events) is the alternative; it would need a small JS snippet in `web/index.html` plus Dart-to-JS calls for events. 100K events is enough for a few hundred active users, given a handful of events per session.
- **Cohorts:** cohort retention, the main investor chart, needs a stable pseudonymous user ID across visits. That requires storing something on the device, which brings art. 11.7a and EDPB 2/2023 into play. Pure cookieless pageview tools (Plausible, Simple Analytics, Fathom) cannot produce true multi-week user cohorts because their hashes rotate daily. A workable split: run cookieless counting for everyone, plus opt-in "help improve TwinClimate" analytics with a persistent ID for retention cohorts. Opt-in rates will bias the cohort sample, so state that in any pitch.
- **Avoid GA4/Firebase Analytics for the demo.** Under the likely AP view it would need a compliant consent banner (AP's nine banner rules, enforcement letters), and the product principle of "no mandatory forms, minimal taps" argues against a banner.
- **Existing storage is fine.** TwinClimate's current on-device storage (shared_preferences/localStorage for favourites, races, comfort profile) is functional storage the user asked for, and likely falls under the strictly-necessary exception. Any analytics identifier stored alongside it is a separate purpose and needs its own assessment. (Inference; not legal advice.)
- **GDPR still applies.** Even exempt analytics processes personal data (IP/hashes). A short privacy notice naming the processor (e.g., PostHog EU/Plausible), the purposes and the retention period is still advisable, and the CNIL model explicitly requires informing users and allowing objection.

### Gaps
- The AP's own current cookie/analytics web pages could not be fetched (DNS blocked in this session), so the exact current AP wording of the analytics exemption is unconfirmed.
- PostHog's current "cookieless" / memory-only persistence options and Plausible's official events API docs were not verified on the vendor sites.
- No source confirmed how `firebase_analytics` handles consent specifically on Flutter web.
- No Umami Flutter package found; a JS-interop integration effort is an inference.
- Mobile-store requirements (Apple privacy labels, Google Play data-safety form) for analytics SDKs were not researched.

## Key Question 3: Affiliate economics: Decathlon NL programme, conversion rates, revenue per 1,000 users, alternatives

### Takeaway
Decathlon NL runs its affiliate programme through Odyssey Partnerships, an Amsterdam network for which Decathlon NL was the launching customer. Decathlon's own page advertises up to 7% commission and a 30-day cookie, but third-party listings conflict (3.6–6%, 14–30 days, Awin or Impact). Sports and outdoor affiliate clicks convert at roughly 0.5–4%, so affiliate revenue per 1,000 users would be a few euros to a few tens of euros a month. The commercial value to show a brand is the intent and click data, not the commission.

### Cited Findings
- **Decathlon NL official affiliate page:** up to 7% commission on the purchase amount, a 30-day cookie, access to ~45,000 products and monthly payouts. Sign-up goes via Odyssey Partnerships (dashboard on a separate domain). Search metadata said the page was ~766 days old, so terms may have changed — [Decathlon.nl, "Het affiliate programma"](https://www.decathlon.nl/c/lp/het-affiliate-programma_5d86498f-9d86-44eb-897f-2b7cf665ee05)
- **Odyssey Partnerships:** an Amsterdam company; Decathlon NL was the launching customer. It uses multi-touch attribution (Odyssey Attribution) to set commission by a publisher's incremental value. Decathlon's online marketing manager said it lets them "allocate commissions to sport publishers based on multi touch attribution" — [Frankwatching](https://www.frankwatching.com/channel/odyssey-lanceert-odyssey-partnerships-en-lost-de-incrementality-uitdaging-op-voor-de-affiliate-industrie-decathlon-is-de-launching-customer/); [Affiverse](https://www.affiversemedia.com/odyssey-launches-odyssey-partnerships-affiliate-platform/); [affiliateblogger.nl interview](https://affiliateblogger.nl/interview-odyssey-partnerships-decathlon/)
- **Conflicting third-party listings:**
  - FlexOffers lists Decathlon NL as deactivated, 3.6%, 30-day cookie — [FlexOffers](https://www.flexoffers.com/affiliate-programs/decathlon-nl-affiliate-program/)
  - Avid Affiliate lists 5.1% via Impact — [Avid Affiliate](https://avidaffiliate.com/programs/decathlon-nl/)
  - Lasso lists 6% with a 14-day cookie — [Lasso](https://getlasso.co/affiliate/decathlon/)
  - UpPromote says Europe/UK runs via Awin at 1–3%, with no commission on marketplace sales — [UpPromote](https://uppromote.com/affiliate-program-directory/decathlon/)
  - Awin hosts Decathlon DE and IE programmes; a Decathlon PT profile lists a 15-day cookie — [Awin Decathlon DE](https://ui.awin.com/merchant-profile-terms/14353); [Awin Decathlon IE](https://ui.awin.com/merchant-profile-terms/37550)
- **Conversion benchmarks:**
  - Outdoor/sporting goods affiliate conversion is cited at 1.5–4%; Awin's guidance puts typical affiliate conversion at 0.5–1%; FirstPageSage reports 2.0% for B2C; top affiliates reach 5–10% (Authority Hacker). Impact 2025: conversion down 6% year on year — [FloatingCTA (secondary)](https://floatingcta.com/insights/affiliate-marketing-conversion-rate/)
  - Whole-site sports e-commerce conversion (not affiliate-specific):
    - Sports & recreation 1.90% (Sept 2026, up from 1.46%), with affiliate marketing 7.1% of channel sales — [IRP Commerce](https://www.irpcommerce.com/en/gb/ecommercemarketdata.aspx?Market=1)
    - Sports & outdoors median 1.24% on Shopify stores (H1 2026) — [Shogun](https://getshogun.com/learn/sports-outdoors-ecommerce-benchmarks)
    - Sports & outdoor average 1.8% — [WisePIM](https://wisepim.com/ecommerce-industry-insights/sports)
    - Outdoor products 2.45%: items under $50 convert at 3.5%, items over $200 at 1.2% — [CUFinder](https://cufinder.io/blog/benchmarks/outdoor-products/)
- **Alternatives:** the bol.com partner programme is reported at 2.5–7% commission on the whole order with a 30-day cookie. An older 2011 note says the cookie was 5 days. Official per-category rates sit on the bol.com Partnerplatform ("Tarieven en commissies") — [Shopify NL blog](https://www.shopify.com/nl/blog/affiliate-programma); [Webwoordenboek](https://webwoordenboek.nl/kenniscentrum/hoeveel-pakt-bol)

### Inferences
- **Estimate, not sourced data: affiliate revenue per 1,000 monthly active users.**
  - Assume 5–15% of MAU tap a shop link in a month → 50–150 clicks.
  - Assume 1–3% of clicks convert → about 0.5–4.5 orders.
  - Assume an average order of €40–80 (an assumption; no Decathlon NL order-value figure was found) → about €20–360 in sales.
  - At 3.6–7% commission → **roughly €1–25 per 1,000 MAU per month**.
  - Commission is therefore not a business model at demo scale. It mainly validates purchase intent.
- **What a brand values more:** demand data such as "which needs were opened" and the click-through rate per kit item, e.g., "rain jacket opened by 18% of users in wet weeks". TwinClimate's Partner demo screen already captures these on-device; aggregating them centrally (with analytics, KQ2) turns them into a partner pitch.
- **Network choice:** because Decathlon NL uses Odyssey's multi-touch, incrementality-based attribution, a weather-triggered "you need this today" recommendation might be credited more fairly than in a last-click network. This is worth raising directly with Decathlon NL's online marketing team.
- **Joining is low-barrier:** joining an affiliate programme (Odyssey or bol.com) is a self-serve publisher application, separate from a strategic partnership. The CLAUDE.md roadmap keeps real affiliate links in V3, so this is a later step.

### Gaps
- Current, verified Decathlon NL commission tiers per category and Odyssey publisher acceptance criteria (e.g., minimum traffic, app vs. website publishers) were not found; the official page could not be opened (403).
- No Decathlon NL average order value or EPC (earnings per click) figure was found.
- Zalando, Bike24, Sigma Sports and running-specialist shop affiliate terms were not researched in the time available. Wiggle's status after its 2023 administration was not verified.

## Key Question 4: How do Decathlon and other sports brands partner with or invest in apps, and which NL partners/accelerators exist?

### Takeaway
Decathlon partners with apps commercially (e.g., the 5-year Freeletics deal from April 2025 bundling app coaching with equipment) and invests through Decathlon Pulse (launched July 2024). Pulse's visible deals are larger, mostly majority stakes in established businesses (Bikeleasing, Rebike, Alltricks, Bergfreunde, a Brompton minority), not pre-seed apps. Decathlon's "Supported by Decathlon" open-innovation programme (Spain) offers 3-month proofs of concept with no capital investment, but asks for 2+ full-time founders and traction. Note: komoot belongs to Bending Spoons (since March 2025), not Decathlon. Garmin's cloud API programme is paused (spring 2026 onward). In the Netherlands, Sportinnovator / SportUp Boost NL is the most relevant early-stage route.

### Cited Findings
**Decathlon Pulse (investment arm)**
- Launched July 2024 as a wholly owned subsidiary combining an investment fund and a startup studio. CEO Franck Vigo, chaired by Decathlon CEO Barbara Martin Coppola, offices in Paris and Boston — [IADS](https://www.iads.org/member/news/decathlon-launches-pulse-for-strategic-diversification); [Maddyness (FR)](https://www.maddyness.com/2024/07/12/decathlon-a-fond-la-forme-avec-les-startups/); [SGI News](https://sginews.com/Content/decathlon-launches-investment-subsidiary.aspx)
- Mandate: build new ventures; take minority stakes in companies that could reshape sport with sustainable models; acquire sports brands and distributors. Focus areas per its job listing: expert sports brands, e-commerce, circular economy, next-gen sport technology — [IADS](https://www.iads.org/member/news/decathlon-launches-pulse-for-strategic-diversification); [Greenhouse job listing](https://job-boards.eu.greenhouse.io/decathlongroup/jobs/4642133101)
- Decathlon has invested about €400M since 2018 in startups, small companies and majority stakes, including Alltricks and Bergfreunde — [FashionNetwork](https://ww.fashionnetwork.com/news/Decathlon-launches-investment-subsidiary-to-drive-diversification,1649430.html)
- Deals:
  - Agreed to acquire ~65% of Bikeleasing Group (Dec 2025; closing expected H1 2026) — [Latham & Watkins](https://www.lw.com/en/news/2025/12/latham-advises-decathlon-pulse-on-acquisition-of-majority-stake-in-bikeleasing-group)
  - Majority stake in Rebike Mobility (2025) — [Sporteco](https://www.sporteco.com/decathlon-pulse-poursuit-ses-prises-de-participation/)
  - Minority stake (~10%) in Brompton — [Sport Guide](https://www.sport-guide.com/news/23510/Decathlon-prend-une-participation-minoritaire-dans-Brompton/)
  - Co-lead of the €40M first close of OSS Ventures (industrial tech) — [SGI Europe](https://www.sgieurope.com/corporate/decathlon-helps-raise-40m-for-manufacturing-focused-fund/119720.article)

**Decathlon app partnerships and own apps**
- **Decathlon x Freeletics (announced April 2025):**
  - Terms: a five-year partnership pairing Decathlon equipment with Freeletics AI coaching. Buyers of qualifying products get 3 months free, or 50% off the annual subscription from summer 2025. The first product was a 3-pack of training bands (7 April 2025), with a target of 100+ products by end of 2026.
  - Feedback loop: Freeletics adapts coaching to Decathlon products, and Decathlon uses the feedback for product development.
  - Decathlon's rationale: ~70% of its fitness-equipment users don't know how to use the equipment properly, and ~50% reduce or abandon training within 3 months.
  - Sources: [Decathlon UK press](https://decathlon-uk.prezly.com/decathlon-and-freeletics-revolutionize-fitness-training); [Decathlon United media](https://www.decathlon-united.media/pressfiles/decathlon-and-freeletics-partnership); [retail-news.de](https://retail-news.de/decathlon-freeletics-fitness-kooperation/); [Retail Times](https://retailtimes.co.uk/decathlon-partners-with-freeletics-to-add-products-to-its-fitness-coaching/)
- Decathlon runs its own apps: Decathlon Coach (running/walking tracking and training plans) and Decathlon Outdoor (hiking). No shutdown evidence was found — [Decathlon Coach](https://www.decathloncoach.com/en/home/advices/advice/app-decathlon-coach1); [App Store, Decathlon Outdoor](https://apps.apple.com/fr/app/decathlon-outdoor-randonn%C3%A9e/id1456596355)
- COROS lists Decathlon's coaching app as a partner integration alongside Strava and komoot. No Decathlon–Strava or Decathlon–komoot corporate deal was found — [COROS partners](https://coros.com/partners)
- **Correction to a common assumption:** komoot was acquired by Bending Spoons (announced 20 March 2025), not Decathlon. komoot reported ~45M users, with ~€36M revenue and profitability per one report — [Business Wire](https://www.businesswire.com/news/home/20250320568940/en); [Techleap Finder](https://finder.techleap.nl/news/feed/bending-spoons-acquires-komoot-for-growth)

**Decathlon open-innovation programme**
- "Decathlon Open Innovation" (Spain) is the umbrella for startup collaboration. Its first programme, "Supported by Decathlon", targets early-growth SportsTech/RetailTech/DataTech startups offering digital solutions to athletes — [Decathlon Open Innovation](https://openinnovation.decathlon.es/en/); [2Playbook](https://www.2playbook.com/retail/decathlon-lanza-programa-apoyar-desarrollo-start-ups-tecnologicas-deportivas_4910_102.html)
  - Eligibility: an incorporated company, at least two full-time founders, traction and metrics, and alignment with Decathlon values; startups from any country.
  - Format: 3-month proofs of concept, run yearly in three phases, with access to Decathlon's market, testing and teams, plus a "Supported by Decathlon" badge.
  - No capital investment.
  - Recruitment partners: South Summit, Barcelona Activa, Startup Valencia.
  - Sources (several years old): [Just Retail](https://www.justretail.news/noticias/retail-supported-by-decathlon-startups-sportstech/); [TradeSport](https://www.tradesport.com/Articulos/514862-Decathlon-lanza-un-programa-de-apoyo-para-emprendedores.html)
- Decathlon Innovation Lab (India) runs challenges with 3-month store pilots in Bangalore — [Decathlon Innovation Lab](https://www.decathloninnovationlab.com/)

**Other potential partners**
- **Garmin:**
  - Health API terms: free for approved business developers, but commercial use requires a licence fee; it targets corporate wellness and population health — [Garmin Developers](https://developer.garmin.com/gc-developer-program/health-api/)
  - Pause: Garmin paused review of new Connect Developer Program API requests in spring 2026 ("evolving and modernizing… unable to provide a specific timeline"). The application form was removed; existing partners are unaffected; Connect IQ (on-device apps) remains open — [Garmin forums](https://forums.garmin.com/developer/connect-iq/f/discussion/441459/connect-developer-program-what-should-a-solo-developer-do-while-applications-are-paused/2054020); [Terra blog](https://tryterra.co/blog/garmin-connect-developer-program-pause); [the5krunner (Sept 2026)](https://the5krunner.com/2026/09/14/garmin-developer-api-access-paused/)
- **TCS Amsterdam Marathon:** TCS (title partner) builds the official race app (bib sharing, live tracking, interactive expo map in 2024), and ran a 2023 "Marathon Runner" mobile game with Le Champion and Mizuno. No startup partner programme was found — [TCS race app](https://www.tcs.com/tcs-amsterdam-marathon-race-app); [TCS Amsterdam Marathon](https://www.tcsamsterdammarathon.eu/innovation-and-technology-bring-tcs-amsterdam-marathon-to-life-in-unique-game)

**Dutch sports-innovation routes**
- **Sportinnovator:**
  - A national network initiated by the Ministry of Health, Welfare and Sport (VWS), supported by ZonMw. Since 2015 it has assessed over 1,250 concepts and supported 500+ initiatives — [Sportinnovator](https://www.sportinnovator.nl/english/); [ZonMw](https://www.zonmw.nl/en/sport-innovation)
  - Centres include Innovatielab Thialf, the Amsterdam Institute of Sport Science (AISS), KNLTB and Johan Cruijff ArenA Innovation Amsterdam — [Sportinnovator centres](https://www.sportinnovator.nl/innovatiecentra/)
  - 2025 vouchers: innovation vouchers of €5k–25k; network vouchers up to €10k — [Sportinnovator](https://www.sportinnovator.nl/english/)
- **SportUp Boost NL:** the national early-stage sports startup accelerator (~3 months; 19 startups supported). In Aug 2025 it was strengthened by a cooperation agreement between Cluster Sports & Technology, Sportinnovator, Innovatielab Thialf and Orange Sports Forum. Later-stage introductions go to the Sports Innovation League, Dutch Sport Tech Fund, Rabobank and LUMO Labs — [Sport & Strategie](https://www.sportenstrategie.nl/sporteconomie/sportup-boost-nl-versterkt-sportinnovatiekracht-met-nieuwe-samenwerking/); [Yespress](https://yespress.io/sportinnovator)

### Inferences
- **Freeletics is the closest precedent.** Decathlon NL is more likely to engage TwinClimate as a commercial or marketing partner than as an investor. Freeletics shows Decathlon pays (via subscription bundles) for app experiences that make customers use its products successfully. TwinClimate's pitch angle mirrors it: "weather-precise kit advice that reduces wrong purchases and returns, and drives seasonal need-based sales".
- **Pulse is a later conversation.** Its visible deals are majority acquisitions or stakes in revenue-generating companies, so it is not a realistic pre-seed source for a solo-founder demo app. A Pulse conversation becomes plausible only with meaningful traction and revenue.
- **Solo-founder hurdle.** The "Supported by Decathlon" criteria (2+ full-time founders, traction) would currently exclude a solo founder. Finding a co-founder or showing measured traction would be prerequisites. Its Spanish base suggests checking whether Decathlon NL/Benelux runs an equivalent.
- **Garmin's pause blocks it for now.** It removes a near-term Garmin Connect integration as a partnership hook; Connect IQ or Strava-style routes would be alternatives (Strava's API terms were not researched here).
- **Best NL first step.** SportUp Boost NL / Sportinnovator vouchers (€5k–25k, non-dilutive) and an AISS or Johan Cruijff ArenA Innovation centre connection are realistic early steps for an Amsterdam founder. They can also produce warm introductions to Dutch Sport Tech Fund and LUMO Labs.

### Gaps
- No named Decathlon Netherlands/Benelux partnership or innovation contact was found.
- No evidence of Decathlon Pulse investing in an early-stage digital consumer app was found. Its full portfolio was not available.
- Polar and Coros partner/API programmes, NN Marathon Rotterdam partners, and KNVB/NOC*NSF innovation programmes were not covered by search results.
- Whether Rockstart or TechLeap run sports-tech programmes in 2025–2026 was not confirmed.
- Strava's developer/API terms were not researched (strava.com was blocked by the proxy).

## Key Question 5: What should a demo-stage founder prepare, and how many users is "enough" for partner talks vs. a pre-seed raise?

### Takeaway
No reliable source gives a numeric user threshold. The cited frameworks all reward evidence of retention and organic growth over raw counts, and pre-seed in Europe is described as backing the founder and market more than traction. The practical package is:
- a live traction dashboard (WAU/MAU, weekly cohort retention, week-over-week growth, organic share);
- engagement and commerce-intent stats (kit lists, feedback responses, shop-link CTR);
- qualitative proof (testimonials, club or race-community pilots);
- an honest explanation of method and consent.

### Cited Findings
- Seed investors want users, MRR and a working product, while pre-seed backs conviction, market size and founder profile (third-party guide) — [Pitchwise](https://www.pitchwise.se/blog/top-pre-seed-investors-in-europe-2026)
- European consumer traction is judged on app-store performance, ratings, web traffic, search interest and social mentions, with judges rating "reach, habit and buzz" — [Sifted Consumer 100](https://sifted.eu/rankings/sifted-consumer-100-2026)
- a16z looks at DAU/MAU, L5+ and monthly growth (20/35/50%), "ideally mostly organic" — [a16z](https://a16z.com/do-you-have-lightning-in-a-bottle-how-to-benchmark-your-social-app/)
- Paul Graham: track active-user growth week over week if not charging yet; 5–7%/week is good — [TechCrunch quoting PG](https://techcrunch.com/2016/12/18/growth-as-a-false-signal-in-y-combinator-startups/?ncid=rss)
- Decathlon's startup programme explicitly screens for "traction and metrics" and two or more full-time founders — [Just Retail](https://www.justretail.news/noticias/retail-supported-by-decathlon-startups-sportstech/)
- Freeletics, Decathlon's chosen app partner, is described as "a widely used European fitness app"; Decathlon's partnership rationale was product-usage and drop-off data — [Decathlon UK press](https://decathlon-uk.prezly.com/decathlon-and-freeletics-revolutionize-fitness-training)

### Inferences (no sourced numeric threshold exists; these are reasoned estimates)
- **For a first partner conversation** (Decathlon NL marketing / affiliate team, a running club, a race organiser), a few hundred real, retained users can be enough. They must come with clean data: e.g., "X WAU, Y% still active after 4 weeks, Z% of kit lists lead to a shop-link open". What makes the data persuasive is the intent and weather-context signal, plus a credible plan to scale. Supporting evidence: Decathlon's Freeletics rationale was usage data, and its programme asks for "traction and metrics".
- **For a pre-seed raise**, a solo non-technical founder will be judged heavily on team. Adding a co-founder and showing a flattening retention curve with organic week-over-week growth matter more than a big signup number. Thousands of signups with D30 below the fitness baseline (~3–4%) would weaken rather than strengthen a pitch.
- **"Large user numbers" need a definition.** The founder's goal of showing them should be reframed as defined active users (WAU/MAU) with cohort charts. Investors and brands discount totals without a definition, and the frameworks above all centre on retention and frequency.
- **Suggested prep checklist:**
  1. A privacy-compliant analytics setup (KQ2) live before any promotion, so cohorts start from day one.
  2. A one-page traction dashboard: WAU/MAU, weekly cohort table, WoW growth, organic vs. referred split.
  3. Commerce-intent stats from the shop features: impressions → opens → clicks, top needs, "already have it" rate.
  4. Feedback-loop proof: response rate and the share of users with a learned comfort adjustment.
  5. Testimonials and quotes from Amsterdam running/cycling clubs or race participants.
  6. A waitlist for the mobile apps (Codemagic builds) as a demand signal.
  7. A clear statement that numbers are counted cookieless/consented, which preempts brand and legal concerns.

### Gaps
- No primary 2024–2026 source states a specific user count needed to open brand-partner talks or to raise a European consumer pre-seed.
- No public data was found on what Decathlon specifically asked of Freeletics (user numbers, exclusivity, revenue share).
