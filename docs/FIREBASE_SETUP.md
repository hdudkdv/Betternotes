# Firebase einrichten

BetterNotes bleibt ohne Firebase vollständig lokal nutzbar. Cloud-Sync und
Google-/Apple-Anmeldung werden erst aktiv, wenn die folgenden Schritte erfolgt
sind.

## Projekt und Plattformen

1. Firebase-Projekt `notis-2dee0` nutzen und Firestore sowie Storage aktivieren.
2. Die Apps mit den bestehenden IDs registrieren:
   - Android: `com.notis.app`
   - iOS: `de.notis.app`
   - Web: die produktive Web-Domain ergänzen
3. FlutterFire CLI installieren und im Projekt ausführen:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Dies überschreibt die sichere Platzhalterdatei `lib/firebase_options.dart` und
erzeugt die Firebase-Konfigurationsdateien für die Plattformen. Diese Dateien
gehören zum jeweiligen Firebase-Projekt und enthalten keine Platzhalterwerte.

## Authentifizierung

1. In Firebase Authentication Google und Apple als Provider aktivieren.
2. Für Google die Android-SHA-1/SHA-256-Fingerprints und die erlaubten Web-Domains
   eintragen.
3. Für Apple im Apple Developer Portal:
   - App-ID `de.notis.app` mit Capability **Sign in with Apple**
   - **Services ID** z. B. `de.notis.app.web` (für den Browser-Login)
   - Domains: `notis-2dee0.firebaseapp.com` und `notis-notizbuecher.web.app`
   - Return URLs:
     `https://notis-notizbuecher.web.app/__/auth/handler`
     und `https://notis-2dee0.firebaseapp.com/__/auth/handler`
   - Key mit Sign in with Apple → Team-ID, Key-ID und `.p8` in Firebase
     Authentication → Sign-in method → Apple eintragen
4. Authorized domains in Firebase: `notis-notizbuecher.web.app`

Google Calendar wird nicht angefragt oder synchronisiert. Login dient in dieser
Ausbaustufe ausschließlich dem persönlichen Cloud-Speicher.

## Hosting (Landingpage)

Die öffentliche Seite liegt in `hosting/` und wird nach `https://notis-notizbuecher.web.app`
veröffentlicht (Datenschutz, AGB, Impressum).

```bash
firebase use notis-2dee0
firebase deploy --only hosting
```

In Firebase Authentication die Domain `notis-notizbuecher.web.app` unter Authorized domains
ergänzen. In AdMob die Privacy-URL `https://notis-notizbuecher.web.app/datenschutz` eintragen.

## Regeln

Die Dateien `firestore.rules` und `storage.rules` im Projektstamm deployen:

```bash
firebase deploy --only firestore:rules,storage
```

Die Daten liegen jeweils unter `users/{uid}` und können ausschließlich vom
angemeldeten Besitzer gelesen oder geschrieben werden.
