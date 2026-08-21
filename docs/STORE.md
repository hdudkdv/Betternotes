# Store / release basics

## Identifiers

- Android application id: `com.notis.app`
- iOS bundle id: `de.notis.app`
- Display name: **Notis**

## Web / PWA

- Manifest: `web/manifest.json` (standalone, theme `#0F6E56`)
- Build: `flutter build web --release`
- Output: `build/web`

## AdMob (rewarded ads)

Identifiers live in `lib/features/entitlements/ad_config.dart`. The SDK
initializes on Android and iOS; web/desktop fall back to the demo dialog in
`rewarded_ad_mock.dart`.

### iOS

- App ID `ca-app-pub-5148114115565319~7652831090` in
  `ios/Runner/Info.plist` (`GADApplicationIdentifier`)
- Rewarded unit `ca-app-pub-5148114115565319/8291909166` (`CoinsWerbung`)

### Android

- App ID `ca-app-pub-5148114115565319~5749506300` in
  `android/app/src/main/AndroidManifest.xml`
- Rewarded unit `ca-app-pub-5148114115565319/7963133920` (`CoinsWerbung`)

Both units grant **10 coins**. Debug/profile still request Google's test
units. Release uses the live units.

Still needed before real ads earn money in production:

1. AdMob **Privacy & messaging → GDPR / UMP** for EEA + UK, with the
   public privacy URL. Without this, consent stays empty and many ads
   will not fill in Europe.
2. iOS **ATT / IDFA**: `NSUserTrackingUsageDescription` is in Info.plist,
   but the app does not yet call `ATTrackingManager.requestTrackingAuthorization`.
   Add that (or a plugin) before asking for personalized ads on iOS 14.5+.
3. Confirm both apps in AdMob are **Ready / serving**, payment profile
   and PIN are verified, and the rewarded units stay **10 coins**.
4. Ship a **release** build (debug always uses Google test units).
5. Play Console / App Store: declare ads, add the privacy URL, and on
   iOS complete the tracking nutrition label.
6. Test on a real device in the EEA: consent form, then a live rewarded
   ad, then coins. Add your device hash in `ConsentDebugSettings` only
   while testing the form.

### Shared behaviour

- Debug and profile always request Google's test rewarded units.
- Release uses live units only after the matching platform ID is configured.
- Rewards are granted from `onUserEarnedReward` only. Closing the ad early
  grants nothing.
- GDPR consent runs through Google's User Messaging Platform on first launch.
  Ads are only requested after `canRequestAds()` returns true. The consent
  form stays reachable under Marketplace → Ad settings whenever AdMob reports
  the privacy entry point as required.

For on-device testing of the consent form, add your device hash via
`ConsentDebugSettings` in `RewardedAdService._gatherConsent`.

## Legal (in-app and public)

Public site (Firebase Hosting): [https://notis-notizbuecher.web.app](https://notis-notizbuecher.web.app)

- Privacy: [https://notis-notizbuecher.web.app/datenschutz](https://notis-notizbuecher.web.app/datenschutz)
- Terms: [https://notis-notizbuecher.web.app/agb](https://notis-notizbuecher.web.app/agb)
- Impressum: [https://notis-notizbuecher.web.app/impressum](https://notis-notizbuecher.web.app/impressum)

Use the privacy URL in AdMob (**Privacy & messaging**), Play Console and App Store Connect.

### App Store Connect — required for auto-renewable subscriptions

Apple rejects the binary if the **listing metadata** has no working EULA link
(Guideline 3.1.2). This is not the in-app Settings page.

Use these URLs (already live):

- Terms of Use (EULA): https://notis-notizbuecher.web.app/agb  
  alias: https://notis-notizbuecher.web.app/eula (after the next web deploy)
- Privacy Policy: https://notis-notizbuecher.web.app/datenschutz

Do all of the following in App Store Connect, then reply to App Review
(no new build required for this specific rejection):

1. **App Information → Privacy Policy URL**  
   `https://notis-notizbuecher.web.app/datenschutz`
2. **App Information → License Agreement → Edit**  
   Choose **Custom EULA** (we have our own terms, not only Apple’s standard).  
   Paste the English “Terms of Use (EULA)” text from `/agb`.
3. **Subscriptions → [group] → App Store Localization** (every locale)  
   Terms of Use (EULA) URL: `https://notis-notizbuecher.web.app/agb`  
   Privacy Policy URL: `https://notis-notizbuecher.web.app/datenschutz`
4. **iOS version → Description** (German and English), last lines:

```
Terms of Use (EULA): https://notis-notizbuecher.web.app/agb
Apple Standard EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://notis-notizbuecher.web.app/datenschutz
```

```
Nutzungsbedingungen (EULA): https://notis-notizbuecher.web.app/agb
Apple-Standard-EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Datenschutzerklärung: https://notis-notizbuecher.web.app/datenschutz
```

Then **Reply to App Review** that the EULA is in the description, as a custom
license, and on the subscription group.

In-app copies stay under Settings → About (`/legal/privacy`, `/legal/terms`, `/legal/impressum`).
Impressum still contains placeholders — replace with real publisher data before store release.

## Import / export / backup

- Share/open files into BetterNotes (Android intent filters; iOS document types). Flow: `/import` → pick notebook → pages created.
- Formats: PDF (raster pages), images (page background), GoodNotes/ZIP (best-effort extract), Office docx/pptx/xlsx (media + text extract + original attachment).
- Export from editor Share sheet: PDF, page as image, PDF for GoodNotes (importable in GoodNotes). No proprietary `.goodnotes` file.
- Full backup ZIP: Settings → Backup & restore (notebooks, pages, decks, planner, timetable + files).

## Before first store submission

1. Launcher icons are generated from `assets/branding/app_icon.png` via `flutter_launcher_icons`
2. Privacy URL is `https://notis-notizbuecher.web.app/datenschutz` — fill Impressum placeholders
3. Screenshots for tablet landscape + portrait
4. iPad / large Android tablet device testing for stylus latency
5. App Store / Play Console listings in German + English
6. For full iOS Share Sheet support, add a Share Extension target (see `share_handler` docs); document types already enable Open-in.
