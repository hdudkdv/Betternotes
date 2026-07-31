import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

enum LegalDocKind { privacy, terms, impressum }

/// In-app legal documents (AGB / Datenschutz / Impressum).
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final german = locale.toLowerCase().startsWith('de');

    final title = switch (kind) {
      LegalDocKind.privacy => l10n.privacyPolicy,
      LegalDocKind.terms => l10n.termsOfService,
      LegalDocKind.impressum => l10n.impressum,
    };
    final body = switch (kind) {
      LegalDocKind.privacy =>
        german ? _privacyDe : _privacyEn,
      LegalDocKind.terms => german ? _termsDe : _termsEn,
      LegalDocKind.impressum => german ? _impressumDe : _impressumEn,
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Text(
            body,
            style: AppTheme.body(
              color: AppTheme.ink,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

const _privacyDe = '''
Datenschutzerklärung – BetterNotes

Stand: Juli 2026

1. Verantwortlicher
Für die Verarbeitung personenbezogener Daten im Zusammenhang mit der App BetterNotes ist der in der Impressum-Angabe genannte Anbieter verantwortlich. Kontaktdaten findest du unter „Impressum“.

2. Welche Daten wir verarbeiten
BetterNotes ist offline-first. Ohne Anmeldung bleiben Notizbücher, Seiten, Zeitpläne, Noten und Karteikarten in der Regel nur lokal auf deinem Gerät.

Optional und nur nach deiner Aktion können verarbeitet werden:
• Konto- und Authentifizierungsdaten (z. B. Google- oder Apple-Anmeldung), wenn du dich anmeldest
• Cloud-Synchronisationsdaten (Notizbücher, Seiteninhalte, Einstellungsfragmente), wenn Sync aktiviert ist und ein Cloud-Dienst angebunden ist
• Kauf- und Abo-Informationen über den jeweiligen Store/Payment-Anbieter (z. B. RevenueCat / Apple / Google)
• Werbekennungen und Nutzungsdaten für belohnte Werbung (z. B. Google AdMob), sofern du Werbung nutzt und eingewilligt hast
• Technische Diagnosedaten, die das Betriebssystem oder die Store-Plattform bereitstellt

Bei „Nahe Sync“ (WLAN/Hotspot) werden Notizbuchdaten direkt zwischen Geräten im lokalen Netz ausgetauscht. Dafür ist keine Anmeldung nötig; die Verbindung läuft über dein lokales Netzwerk.

Lehrerfunktionen:
• Live-Unterricht überträgt im lokalen Netz Teilnehmername, Bearbeitungsfortschritt und – nur nach Zustimmung des Schülers – ob BetterNotes im Vordergrund ist. Eine automatische Wiederverbindung speichert Fach und Raum lokal und wird nur versucht, wenn mindestens eines der beiden Kriterien übereinstimmt. Die Lehrkraft prüft dies zusätzlich beim Handshake. Die App erfasst weder Namen noch Inhalte anderer geöffneter Apps.
• Audio-Erklärungen werden erst nach aktivem Start und erteilter Mikrofonberechtigung aufgenommen und zunächst lokal gespeichert. Eine automatische Transkription oder Verteilung erfolgt nur, wenn ein entsprechender Dienst konfiguriert und die erforderliche Einwilligung eingeholt wurde.
• OER-Materialien werden bei freiwilliger Einreichung zusammen mit Fach, Klasse, Bundesland, Bearbeitungszeit und dem angemeldeten Profil zur Prüfung in die Cloud geladen. Sie werden erst nach Freigabe öffentlich gelistet.
• Referendarsnachweise werden in der aktuellen lokalen Version nicht hochgeladen; gespeichert wird nur ein lokaler Bearbeitungsstatus. Ein späterer Prüfservice benötigt eine gesonderte Einwilligung und Löschfrist.

3. Zwecke
• Bereitstellung und Verbesserung der App
• optionale Synchronisation zwischen deinen Geräten
• optionale In-App-Käufe und Abos
• optionale Werbung / Belohnungen (nur mit Einwilligung, soweit erforderlich)
• Erfüllung gesetzlicher Pflichten

4. Rechtsgrundlagen (DSGVO)
Je nach Funktion: Art. 6 Abs. 1 lit. b DSGVO (Vertrag/Nutzung), lit. a (Einwilligung, z. B. Tracking/Werbung), lit. f (berechtigtes Interesse an stabiler, sicherer App) sowie ggf. lit. c (rechtliche Verpflichtung).

5. Speicherdauer
Lokale Daten bleiben, bis du sie löschst oder die App deinstallierst. Cloud-Daten bleiben, bis du sie löschst, das Konto entfernst oder die Sync-Funktion beendest – vorbehaltlich gesetzlicher Aufbewahrungsfristen und Backup-Zyklen der Anbieter.

6. Empfänger / Auftragsverarbeiter
Je nach Nutzung u. a.:
• Firebase / Google (Auth, Firestore, Storage) – wenn Cloud-Sync genutzt wird
• Apple / Google (Anmeldung, Käufe)
• RevenueCat (Abo-Verwaltung)
• Google AdMob (Werbung)
Diese Anbieter können Daten außerhalb der EU verarbeiten; es gelten deren Datenschutzinformationen und ggf. geeignete Garantien (z. B. Standardvertragsklauseln).

7. Deine Rechte
Du hast das Recht auf Auskunft, Berichtigung, Löschung, Einschränkung, Datenübertragbarkeit und Widerspruch sowie das Recht, eine Einwilligung zu widerrufen. Außerdem kannst du dich bei einer Aufsichtsbehörde beschweren.

8. Kinder
BetterNotes richtet sich an Schüler:innen und Studierende. Wenn du unter 16 bist (bzw. unter dem in deinem Land geltenden Alter), nutze die App bitte nur mit Zustimmung einer erziehungsberechtigten Person, soweit erforderlich.

9. Änderungen
Wir können diese Erklärung anpassen, wenn sich die App oder Rechtslage ändert. Die jeweils aktuelle Version findest du in den Einstellungen.

10. Kontakt
Siehe Impressum in den Einstellungen.
''';

const _privacyEn = '''
Privacy Policy – BetterNotes

Last updated: July 2026

1. Controller
The provider named in the Legal notice (Impressum) is responsible for personal data processed in connection with BetterNotes. Contact details are listed there.

2. What we process
BetterNotes is offline-first. Without signing in, notebooks, pages, planners, grades and flashcards usually stay only on your device.

Optionally, and only after you choose to use a feature, we may process:
• Account / authentication data (e.g. Google or Apple sign-in)
• Cloud sync payloads (notebooks, page content, small settings blobs) when sync is enabled
• Purchase / subscription data via the store / payment provider (e.g. RevenueCat / Apple / Google)
• Ad identifiers and related data for rewarded ads (e.g. Google AdMob) if you use ads and consent where required
• Technical diagnostics provided by the OS or store platforms

With Nearby Sync (Wi‑Fi / hotspot), notebook data is exchanged directly between devices on your local network. No account is required; traffic stays on the local network.

Teacher features:
• Live classes transmit the participant name, progress and — only after the student's consent — whether BetterNotes is in the foreground. Automatic reconnection stores the subject and room locally and is attempted only if at least one criterion matches; the teacher also verifies this during the handshake. BetterNotes does not collect the names or contents of other open apps.
• Audio explanations are recorded only after the teacher starts recording and grants microphone permission, and remain local initially. Automated transcription or distribution occurs only when a suitable service is configured and the required consent has been obtained.
• Voluntarily submitted OER material is uploaded for review together with subject, grade, state, duration and the signed-in profile. It is listed publicly only after approval.
• The current local version does not upload trainee proof; it stores only a local review status. A later review service requires separate consent and a deletion period.

3. Purposes
• Providing and improving the app
• Optional sync across your devices
• Optional in-app purchases / subscriptions
• Optional advertising / rewards (with consent where required)
• Legal compliance

4. Legal bases (GDPR)
Depending on the feature: Art. 6(1)(b) (contract/use), (a) consent (e.g. ads/tracking), (f) legitimate interest in a stable secure app, and (c) legal obligation where applicable.

5. Retention
Local data remains until you delete it or uninstall the app. Cloud data remains until you delete it, remove the account, or stop syncing — subject to legal retention and provider backup cycles.

6. Recipients / processors
Depending on use, may include Firebase/Google (auth, Firestore, Storage), Apple/Google (sign-in, purchases), RevenueCat, and Google AdMob. Providers may process data outside the EU under their policies and appropriate safeguards.

7. Your rights
You may request access, rectification, erasure, restriction, portability and objection, and withdraw consent. You may lodge a complaint with a supervisory authority.

8. Children
BetterNotes is aimed at students. If you are under 16 (or the applicable age in your country), use the app only with guardian consent where required.

9. Changes
We may update this policy when the app or law changes. The current version is available in Settings.

10. Contact
See the Legal notice (Impressum) in Settings.
''';

const _termsDe = '''
Allgemeine Nutzungsbedingungen (AGB) – BetterNotes

Stand: Juli 2026

1. Geltungsbereich
Diese Bedingungen gelten für die Nutzung der App BetterNotes („App“) auf unterstützten Geräten.

2. Leistungsbeschreibung
BetterNotes ist eine Notiz- und Organisations-App für Schule und Studium (u. a. handschriftliche Notizen, Bibliothek, Planner, Karteikarten). Funktionen können sich weiterentwickeln. Manche Features (z. B. Cloud-Sync, Abos, Werbung) sind optional.

3. Konto und lokale Nutzung
Die App ist grundsätzlich ohne Konto nutzbar. Für Cloud-Funktionen kann eine Anmeldung erforderlich sein. Du bist für Zugangsdaten und Gerätezugriff selbst verantwortlich.

4. Inhalte
Du behältst die Rechte an deinen Inhalten. Du räumst uns nur die für den Betrieb notwendigen technischen Nutzungsrechte ein (Speichern, Synchronisieren, Anzeigen auf deinen Geräten).

Du darfst keine rechtswidrigen Inhalte speichern oder teilen. Bei „Nahe Sync“ und Teilen bist du dafür verantwortlich, nur an berechtigte Personen zu übertragen.

5. Abos, Käufe, Coins
Kostenpflichtige Angebote werden über die jeweiligen Store-Bedingungen abgerechnet. Widerruf/Kündigung richtet sich nach den Regeln von Apple/Google bzw. dem Zahlungsanbieter. Virtuelle Währung/Coins haben keinen Bargeldwert außerhalb der App.

6. Werbung
Optional können belohnte Anzeigen eingeblendet werden. Die Einwilligung zur personalisierten Werbung steuerst du über die System-/AdMob-Einstellungen, soweit angeboten.

7. Verfügbarkeit und Haftung
Wir bemühen uns um einen stabilen Betrieb, übernehmen aber keine Garantie für ununterbrochene Verfügbarkeit. Für Datenverlust empfehlen wir eigene Backups (z. B. Exporte, Snapshots, Sync).

Soweit gesetzlich zulässig, haften wir nicht für leichte Fahrlässigkeit, außer bei Verletzung wesentlicher Vertragspflichten, Schäden aus der Verletzung des Lebens, des Körpers oder der Gesundheit sowie nach dem Produkthaftungsgesetz. Die Haftung für Vorsatz und grobe Fahrlässigkeit bleibt unberührt.

8. Beendigung
Du kannst die Nutzung jederzeit einstellen und die App deinstallieren. Wir können den Zugang bei schwerwiegenden Verstößen gegen diese Bedingungen einschränken oder beenden.

9. Änderungen
Wir können die AGB anpassen. Wesentliche Änderungen werden in der App oder auf der Projektseite kommuniziert. Die fortgesetzte Nutzung nach Wirksamwerden gilt – soweit zulässig – als Zustimmung.

10. Anwendbares Recht
Es gilt das Recht der Bundesrepublik Deutschland unter Ausschluss des UN-Kaufrechts, sofern dem keine zwingenden Verbraucherschutzvorschriften am Wohnsitz entgegenstehen.

11. Kontakt
Siehe Impressum.
''';

const _termsEn = '''
Terms of Use – BetterNotes

Last updated: July 2026

1. Scope
These terms govern use of the BetterNotes app (“App”) on supported devices.

2. Service
BetterNotes is a notes and organisation app for school and university (handwriting, library, planner, flashcards, and related tools). Features may evolve. Some capabilities (cloud sync, subscriptions, ads) are optional.

3. Account and local use
The App works without an account by default. Cloud features may require sign-in. You are responsible for credentials and device access.

4. Your content
You retain rights to your content. You grant us only the limited technical rights needed to operate the App (store, sync, display on your devices).

Do not store or share unlawful content. When using Nearby Sync or sharing, you are responsible for sending data only to people you intend.

5. Subscriptions, purchases, coins
Paid offers are billed under the relevant store terms. Cancellation/refunds follow Apple/Google or the payment provider rules. Virtual currency/coins have no cash value outside the App.

6. Advertising
Optional rewarded ads may be shown. Consent for personalised ads is managed via system/AdMob settings where offered.

7. Availability and liability
We aim for a stable service but do not guarantee uninterrupted availability. Keep your own backups (exports, snapshots, sync).

To the extent permitted by law, we are not liable for slight negligence, except for breach of essential duties, injury to life/body/health, and product liability. Liability for intent and gross negligence remains unaffected. Mandatory consumer rights remain intact.

8. Termination
You may stop using the App and uninstall at any time. We may restrict or end access for serious breaches of these terms.

9. Changes
We may update these terms. Material changes will be communicated in the App or project channels. Continued use after they take effect may constitute acceptance where allowed.

10. Governing law
German law applies, excluding CISG, unless mandatory consumer protections at your residence require otherwise.

11. Contact
See the Legal notice (Impressum).
''';

const _impressumDe = '''
Impressum

Angaben gemäß § 5 TMG / § 18 MStV (soweit anwendbar)

BetterNotes
[Vollständigen Namen / Firmennamen hier eintragen]
[Straße und Hausnummer]
[PLZ Ort]
Deutschland

Kontakt
E-Mail: [kontakt@example.com]
[Optional: Telefon]

Verantwortlich für den Inhalt
[Name der verantwortlichen Person]
[Anschrift, falls abweichend]

Hinweis
Bitte ersetze die Platzhalter vor einer öffentlichen Store-Veröffentlichung durch echte Anbieterdaten. Für rein private, nicht-gewerbliche Angebote können abweichende Pflichtangaben gelten – prüfe die aktuelle Rechtslage für deinen Fall.

Online-Streitbeilegung
Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung bereit: https://ec.europa.eu/consumers/odr/
Wir sind nicht verpflichtet und derzeit nicht bereit, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen, soweit keine Pflicht besteht.
''';

const _impressumEn = '''
Legal notice (Impressum)

Information according to German Telemedia Act / applicable media law

BetterNotes
[Full legal name / company name]
[Street and number]
[ZIP City]
Germany

Contact
Email: [contact@example.com]
[Optional phone]

Responsible for content
[Name]
[Address if different]

Note
Replace the placeholders with real publisher details before a public store release. Private non-commercial projects may have different disclosure duties — check the rules that apply to you.

Online dispute resolution
The European Commission provides a platform for online dispute resolution: https://ec.europa.eu/consumers/odr/
We are not obliged and currently not willing to participate in dispute resolution before a consumer arbitration board unless required by law.
''';
