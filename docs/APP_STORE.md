# Putting TwinClimate on the Apple App Store

Everything inside the code is ready: the iPhone project, app icon, privacy
policy, permissions, Apple's privacy file and a cloud build recipe
(`codemagic.yaml`). What's left needs **your** Apple account and payment, so
only you can do it. All steps work in a web browser: Codemagic builds the app on its Macs. With
your own Mac you can also build it yourself (see *Alternative: build on your
own Mac* below).

**Cost:** Apple Developer Program **$99 / year** (Apple's fee; required for
any App Store app). Codemagic is free for this (500 build minutes a month;
one build takes about 15–25 minutes).

**Good to know:** to try the app on an iPhone before it goes public
(TestFlight), you need an iPhone. Without one you can still submit; Apple's
reviewers test it.

---

## Step 1 — Join the Apple Developer Program (once, ~1–2 days)

1. Go to **developer.apple.com/programs/enroll** and click **Start your
   enrollment**.
2. Sign in with your Apple Account (or create one). Two-factor sign-in must
   be on; a phone number for text-message codes is enough.
3. Choose **Individual / Sole proprietor**, fill in your legal name and
   address, and pay the $99.
4. Wait for Apple's confirmation email (usually within 48 hours).

## Step 2 — Register the app ID and create the app (once, ~10 min)

1. Go to **developer.apple.com/account** → **Certificates, IDs & Profiles**
   → **Identifiers** → the **+** button.
2. Choose **App IDs** → **App** → Continue.
3. Description: `TwinClimate`. Bundle ID: **Explicit**, type exactly
   `com.yamackolatan.twinclimate`. Leave the capabilities as they are →
   Continue → Register.
4. Go to **appstoreconnect.apple.com** → **Apps** → **+** → **New App**:
   - Platform: **iOS**
   - Name: **TwinClimate** (if Apple says it's taken, try
     *TwinClimate: What to Wear*)
   - Primary language: **English (U.K.)**
   - Bundle ID: pick **com.yamackolatan.twinclimate**
   - SKU: `twinclimate`
   - User access: Full access → **Create**
5. In the new app, open **App Information** (left menu) and copy the
   **Apple ID** number (about 10 digits). You'll need it in step 4.

## Step 3 — Create an API key so Codemagic can upload for you (once, ~5 min)

1. In App Store Connect go to **Users and Access** → **Integrations** tab →
   **App Store Connect API** → **Team Keys** → **+** (the first time, click
   *Request Access* and accept).
2. Name: `Codemagic`. Access: **App Manager** → **Generate**.
3. Note the **Issuer ID** (top of the page) and the key's **Key ID**.
4. Click **Download** next to the key. Keep the `.p8` file safe: Apple lets
   you download it **only once**.

## Step 4 — Connect Codemagic (once, ~15 min)

1. Go to **codemagic.io** → **Sign up with GitHub** → allow access to the
   **twinclimate** repository → **Add application** → pick
   `yamackolatan/twinclimate`, type **Flutter App (via codemagic.yaml)**.
2. Click your name/team → **Team settings** → **Team integrations** →
   **Developer Portal** → **Manage keys** → **Add key**:
   - App Store Connect API key name: **`TwinClimate App Store key`**
     (exactly this; the build recipe looks for this name)
   - Issuer ID and Key ID from step 3, and upload the `.p8` file → Save.
3. Still in Team settings → **Code signing identities**:
   - **iOS certificates** tab → **Generate certificate** → choose the key
     you just added → type **Apple Distribution** → name it
     `TwinClimate distribution` → Generate.
4. Back on **developer.apple.com/account** → **Profiles** → **+** →
   **App Store Connect** → Continue → App ID **com.yamackolatan.twinclimate**
   → pick the certificate Codemagic just made → name it
   `TwinClimate App Store` → Generate.
5. In Codemagic → Code signing identities → **iOS provisioning profiles** →
   **Fetch profiles** → tick **TwinClimate App Store** → Save.
6. Tell me (or Claude in a new session) the **Apple ID number** from step 2.
   It replaces `0000000000` in `codemagic.yaml`. You can also edit that line
   yourself on GitHub: open `codemagic.yaml` → pencil icon → change the
   number → **Commit changes**.

## Step 5 — Build and upload (every new version, ~25 min)

1. In Codemagic open the twinclimate app → **Start new build** → branch
   **claude/relaxed-brown-be0mcz** (the one the website uses) → workflow
   **iOS App Store** → Start.
2. When it turns green, the build appears in App Store Connect under
   **TestFlight** after 10–30 more minutes (Apple processes it).
3. With an iPhone: install Apple's **TestFlight** app, add yourself as a
   tester in App Store Connect → TestFlight → Internal Testing, and try it.

## Step 6 — Fill in the store page and submit (~30 min, once)

In App Store Connect → your app → the **1.0 Prepare for Submission** page.
Copy the texts below.

- **Screenshots:** under *iPhone 6.9" Display*, upload the four images in
  `docs/app-store/screenshots/` (download them from GitHub: open each file
  → Download). They are exactly the size Apple asks for (1290 × 2796).
- **Promotional text, Description, Keywords, Support URL, Marketing URL**:
  see below.
- **Build:** click **+** and pick the build from step 5.
- **App Review Information:** no sign-in needed (untick *Sign-in
  required*). Paste the review notes below. Contact: your name, phone and
  email.
- **App Information** (left menu): Category **Sports**, secondary
  **Weather**. Content rights: *does not contain third-party content*.
  Age rating: answer **None/No** to everything → **4+**.
- **Pricing and Availability:** **Free**; all countries, or EU only.
- **App Privacy** (left menu) → Get Started:
  - Do you collect data? **Yes**
  - Data type: **Location → Precise Location** only
  - Use: **App Functionality** only
  - Linked to the user's identity? **No**. Used for tracking? **No**
  - Privacy policy URL: `https://yamackolatan.github.io/twinclimate/privacy.html`
- Click **Add for Review** → **Submit to App Review**. Apple usually answers
  within 1–3 days. If they ask questions, paste their message to Claude.

### Store texts (copy & paste)

**Subtitle** (max 30 characters):
`What to wear for every workout`

**Promotional text:**
`Plan a run, ride or swim and see how it will really feel, hour by hour, with a kit list that explains every item.`

**Description:**
```
Know exactly what to wear before you head out.

Pick your sport, your spot and your start time. TwinClimate shows the weather for exactly the hours you'll be out, at the exact spot (a forest outside town is not the city centre), and turns it into a kit list for head, torso, hands, legs and feet. Every item says why it's there: "Still dark at the start", "60% rain chance during your session", "Session feels like 4°".

• Hour-by-hour weather for your session, with how it really feels
• A packing checklist you tick off as you get ready
• Lights in the dark, sunscreen when the UV is high, water and food on long sessions
• "Better at 11:00 – drier": a nicer start time when there is one
• Learns whether you run warm or cold from a two-tap question after each session
• Training for a race? See its typical race-day weather and find where and when near you training feels the same
• Run, ride or swim, in open water or the pool, at your own pace
• No account, no ads, no tracking. Your data stays on your phone.

Weather data by Open-Meteo.com. Place names © OpenStreetMap contributors.
```

**Keywords** (max 100 characters):
`running,cycling,triathlon,what to wear,weather,kit,training,forecast,swim,layers,race,clothing`

**Support URL:** `https://yamackolatan.github.io/twinclimate/support.html`
**Marketing URL:** `https://yamackolatan.github.io/twinclimate/`
**Copyright:** `2026 Yamac` (your name)

**Notes for the App Review team:**
```
No account or sign-in is needed. To try it: tap "What should I wear?" on the first screen; a kit list for a run in Vondelpark (Amsterdam) appears. You can change the sport, place (search or "Use my location"), day and time. Location is only requested when "Use my location" is tapped. Weather comes from the free Open-Meteo service; place names from OpenStreetMap. The app has no in-app purchases, ads or tracking.
```

---

## Alternative: build on your own Mac (instead of steps 3–5)

You have a Mac, so you can also build and upload the app yourself with
Apple's free **Xcode**, and try it on a simulated iPhone first. Codemagic
(steps 3–5) remains the route with the fewest technical steps; the Mac route
lets you see the app running before you upload it.

1. Install **Xcode** from the Mac App Store (free, large: ~15 GB). Open it
   once and accept the extra components.
2. Install **Claude Code** on the Mac (claude.com/claude-code) and open it
   in a copy of this project. Ask it to *"install Flutter, run the app on the
   iPhone simulator, then build the App Store version with
   STORE_BUILD=true"*. It will run the commands
   (`flutter run`, then `flutter build ipa --dart-define=STORE_BUILD=true`).
3. In Xcode: **Settings → Accounts → +** → sign in with your Apple Account.
   Open `ios/Runner.xcworkspace`, select **Runner → Signing & Capabilities**,
   tick **Automatically manage signing** and pick your team.
4. Upload: open the built archive (Xcode **Window → Organizer**) →
   **Distribute App → App Store Connect → Upload**. Then continue with
   step 6.

## What's different in the App Store version

The App Store build (`STORE_BUILD=true` in `codemagic.yaml`) leaves out the
**Decathlon shopping demo** (shop links, race-day product picks, "My gear &
shopping" and the Partner demo screen). Apple rejects apps labelled "demo"
(App Review Guideline 2.2) and apps that use another company's brand without
permission (5.2). The **website keeps the demo** for investor and partner
pitches. Once there is a real partnership, the shopping features can go into
the app too.

## Things to keep in mind later

- **Open-Meteo's free service is for non-commercial use.** A free app with no
  ads or purchases is fine. If TwinClimate ever earns money (ads,
  subscriptions, paid partnerships), switch to Open-Meteo's paid plan,
  which needs an API key. Claude can make that change.
- **New versions:** raise `version:` in `pubspec.yaml` (e.g. `1.0.1+2`) and
  `appVersion` in `lib/app_config.dart`, then repeat step 5 and submit the
  new build from App Store Connect.
