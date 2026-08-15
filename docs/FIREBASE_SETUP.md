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
3. Für Apple im Apple Developer Portal die Sign-in-with-Apple-Capability,
   Service-ID, Team-ID und den privaten Key konfigurieren; die Werte anschließend
   im Firebase-Apple-Provider hinterlegen.

Google Calendar wird nicht angefragt oder synchronisiert. Login dient in dieser
Ausbaustufe ausschließlich dem persönlichen Cloud-Speicher.

## Regeln

Die Dateien `firestore.rules` und `storage.rules` im Projektstamm deployen:

```bash
firebase deploy --only firestore:rules,storage
```

Die Daten liegen jeweils unter `users/{uid}` und können ausschließlich vom
angemeldeten Besitzer gelesen oder geschrieben werden.
