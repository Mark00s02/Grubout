# Getting GrubOut onto your iPhone (TestFlight → App Store)

Apple only lets you build iPhone apps on a Mac. You're on Windows, so this guide
uses **Codemagic**, which rents you a cloud Mac. The free tier (500 build
minutes/month) is plenty. The project is already configured (`codemagic.yaml`).

Expect about 1–2 hours of setup the first time, plus Apple's approval waits.

---

## 1. Join the Apple Developer Program ($99/year)

1. Go to <https://developer.apple.com/programs/enroll/> and sign in with your Apple ID.
2. Enroll as an **Individual** (fastest). Approval usually takes 24–48 hours.

You can't do anything below until this is approved.

## 2. Register the app

1. **Bundle ID:** <https://developer.apple.com/account/resources/identifiers> → **+** →
   App IDs → App → Description `GrubOut`, Bundle ID **Explicit**: `com.grubout.app`.
   Leave capabilities as they are (In-App Purchase is on by default). Register.
   - If `com.grubout.app` is taken, pick something like `com.yourname.grubout` and
     replace `com.grubout.app` in `codemagic.yaml` and
     `ios/Runner.xcodeproj/project.pbxproj` (3 places).
2. **App record:** <https://appstoreconnect.apple.com> → Apps → **+** → New App
   - Platform: iOS · Name: `GrubOut` (add a word if taken, e.g. "GrubOut: Calorie Counter")
   - Primary language: English · Bundle ID: the one above · SKU: `grubout-001`
3. Open the new app → **App Information** → copy the **Apple ID** (a 10-digit
   number). Put it in `codemagic.yaml` → `APP_STORE_APPLE_ID`.

## 3. Create an App Store Connect API key

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API**
   → Team Keys → **+**. Name it `Codemagic`, access **App Manager**.
2. Download the `.p8` file (you can only download it once). Note the **Issuer ID** and **Key ID**.

## 4. Put the code on GitHub

Codemagic builds from a Git repository. This folder already points at
`https://github.com/Mark00s02/Grubout.git`. Commit and push to `main`:

```powershell
cd "C:\Users\Marc Neo\Downloads\Diet Mobile App\DietAppFlutter"
git add -A
git commit -m "GrubOut 1.0"
git push origin HEAD:main
```

## 5. Connect Codemagic

1. Sign up at <https://codemagic.io> with GitHub and add the `Grubout` repository.
2. **Team settings → Integrations → Developer Portal → Connect**: upload the `.p8`,
   enter Issuer ID + Key ID, and name it exactly **`GrubOut ASC Key`**.
3. **Team settings → codemagic.yaml settings → Code signing identities**:
   - iOS certificates → **Generate certificate** (type: Apple Distribution) using the key.
   - iOS provisioning profiles → **Fetch profiles**, or let Codemagic create one for `com.grubout.app`.
4. (Optional but recommended) Get a free USDA key at
   <https://fdc.nal.usda.gov/api-key-signup>. In the app's **Environment variables**,
   add `USDA_API_KEY` to a group named **`grubout`** (mark it secret). Without it the app
   uses USDA's heavily rate-limited demo key. Open Food Facts, barcode scanning and the
   Filipino food list still work either way. If you skip this, delete the `groups:`
   lines from `codemagic.yaml`.
5. Start the **iOS → TestFlight** workflow (or just push to `main`).

The build takes about 15–25 minutes. When it's green, the build appears in App Store Connect →
**TestFlight** after Apple finishes "Processing" (usually 5–30 minutes).

## 6. Install it on your iPhone

1. App Store Connect → TestFlight → **Internal Testing** → **+** → add yourself.
2. Install the **TestFlight** app from the App Store on your iPhone.
3. Accept the email invite → **Install**. 🎉

The first upload may ask about **export compliance**. The app declares
`ITSAppUsesNonExemptEncryption = NO` (it only uses standard HTTPS), so it should go through automatically.

## 7. Turn on Premium subscriptions

Premium uses real Apple In-App Purchases. They can't be faked in a release build.

1. App Store Connect → **Business** → accept the **Paid Apps Agreement** and add
   bank + tax info. Products won't load until this is done.
2. Your app → **Monetization → Subscriptions** → create a subscription group "GrubOut Premium" with:
   - `grubout_premium_monthly` — 1 month (e.g. ₱149 / $2.99)
   - `grubout_premium_yearly` — 1 year (e.g. ₱999 / $19.99)
   - Optional: add a **7-day free trial** as an Introductory Offer.
   - Fill in the display name and description, and add a review screenshot of the paywall.
3. In TestFlight, purchases use Apple's **sandbox** and are free. Sign in with a sandbox tester
   (Users and Access → Sandbox) when prompted.

Debug builds (`flutter run`) show a "Developer: unlock Premium" button so you
can test Premium screens without the store. That button never appears in TestFlight
or App Store builds.

## 8. Submit to the App Store

In App Store Connect → your app → **iOS App 1.0**:

| Field | What to enter |
|---|---|
| Screenshots | 6.9" iPhone (1320×2868) — at least 3. Take them in TestFlight with your phone. |
| Promotional text | Track calories, macros, water & weight — with Filipino foods built in. |
| Description | See below |
| Keywords | calorie counter,macro tracker,diet,food diary,weight loss,filipino,fasting,barcode |
| Support URL | Your GitHub repo or any page with contact info |
| Privacy Policy URL | Host `PRIVACY.md` (e.g. GitHub Pages, or the file's GitHub link) |
| Category | Health & Fitness |
| Age rating | 4+ (answer "None" to everything) |
| App Privacy | "Data Not Collected" — everything stays on the device |
| Sign-in info for review | Not needed (reviewers create an account in the app) |

Then select the TestFlight build, attach the subscriptions, and press **Submit for Review**.
Review usually takes 1–2 days.

**Suggested description**

> GrubOut is the calorie and macro tracker that actually knows Filipino food.
>
> • Personal plan — a daily calorie, macro and water goal built from your body and goal
> • Fast logging — search foods, scan barcodes, quick-add or re-add recent meals
> • Filipino favourites — adobo, sinigang, kare-kare, lechon kawali and more, ready to log
> • Food diary — Goal − Food + Exercise = Remaining, just like the pros
> • Exercise, water and weight tracking with streaks and progress charts
> • Healthy recipes with full nutrition, plus a library of global dishes
> • Reminders that keep your streak alive
>
> GrubOut Premium unlocks diet plans, intermittent fasting timers, 30/90-day
> insights and custom macro targets.
>
> GrubOut is not medical advice. Consult a professional before major diet changes.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Codemagic: "No matching profiles found" | Step 5.3: fetch or create a profile for the exact bundle ID |
| Codemagic: build-number error | Check `APP_STORE_APPLE_ID` is the numeric Apple ID from step 2.3 |
| Paywall says subscriptions aren't available | Finish step 7 (Paid Apps Agreement + products in "Ready to Submit") |
| Rejected under Guideline 5.1.1(v) | Account deletion is in Profile → Delete account. Mention it in the review notes. |
| Barcode scanner shows "camera access is off" | iPhone Settings → GrubOut → Camera → On |
