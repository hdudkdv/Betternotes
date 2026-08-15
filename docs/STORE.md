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

Android is wired up; identifiers live in `lib/features/entitlements/ad_config.dart`.

- App ID `ca-app-pub-1753845428125059~9465582582`, also declared as
  `com.google.android.gms.ads.APPLICATION_ID` in `android/app/src/main/AndroidManifest.xml`
- Rewarded unit `ca-app-pub-1753845428125059/2237563329`
- Debug and profile builds request Google's rewarded test unit, so live fill
  rates and metrics stay clean. Only release builds use the real unit.
- Rewards are granted from `onUserEarnedReward` only. Closing the ad early
  grants nothing.
- GDPR consent runs through Google's User Messaging Platform on first launch.
  Ads are only requested after `canRequestAds()` returns true, and the consent
  form stays reachable under Settings → Plan & coins → Ad settings whenever
  AdMob reports the privacy entry point as required.

Set up the consent message in the AdMob console under **Privacy & messaging →
GDPR** before release, otherwise EEA users get no ads at all. For on-device
testing of the form, add your device hash via `ConsentDebugSettings` in
`RewardedAdService._gatherConsent`.

Platforms without AdMob (web, desktop, iOS for now) fall back to the demo
confirmation dialog in `rewarded_ad_mock.dart`, so feature unlocks keep working.

### Still to do for iOS

1. Register an iOS app in AdMob and create a rewarded unit
2. Add `GADApplicationIdentifier` to `ios/Runner/Info.plist` plus the
   `SKAdNetworkItems` list from Google's docs
3. Add `NSUserTrackingUsageDescription` for the ATT prompt
4. Extend `AdConfig` with the iOS IDs and allow `TargetPlatform.iOS`

The SDK is intentionally not initialized on iOS until step 2 is done: the iOS
Google Mobile Ads SDK aborts when the app ID is missing from `Info.plist`.

## Legal (in-app)

- Privacy / Terms / Impressum: Settings → About → Legal (`/legal/privacy`, `/legal/terms`, `/legal/impressum`)
- Impressum still contains placeholders (`[kontakt@example.com]`, address, etc.) — replace with real publisher data before store release
- Host a public privacy URL (same text as in-app or a hosted copy) for Play/App Store listing fields

## Import / export / backup

- Share/open files into BetterNotes (Android intent filters; iOS document types). Flow: `/import` → pick notebook → pages created.
- Formats: PDF (raster pages), images (page background), GoodNotes/ZIP (best-effort extract), Office docx/pptx/xlsx (media + text extract + original attachment).
- Export from editor Share sheet: PDF, page as image, PDF for GoodNotes (importable in GoodNotes). No proprietary `.goodnotes` file.
- Full backup ZIP: Settings → Backup & restore (notebooks, pages, decks, planner, timetable + files).

## Before first store submission

1. Replace default launcher icons (`flutter_launcher_icons` recommended)
2. Publish privacy policy URL + fill Impressum placeholders
3. Screenshots for tablet landscape + portrait
4. iPad / large Android tablet device testing for stylus latency
5. App Store / Play Console listings in German + English
6. For full iOS Share Sheet support, add a Share Extension target (see `share_handler` docs); document types already enable Open-in.
