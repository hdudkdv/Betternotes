// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Notis';

  @override
  String get newNotebook => 'Neues Notizbuch';

  @override
  String get untitledNotebook => 'Unbenanntes Notizbuch';

  @override
  String get title => 'Titel';

  @override
  String get cover => 'Cover';

  @override
  String get template => 'Vorlage';

  @override
  String get blank => 'Leer';

  @override
  String get lined => 'Liniert';

  @override
  String get grid => 'Kariert';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get create => 'Erstellen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get searchNotebooks => 'Notizbücher suchen';

  @override
  String get globalSearch => 'Globale Suche';

  @override
  String get noNotebooksYet => 'Noch keine Notizbücher';

  @override
  String get noNotebooksHint => 'Erstelle eines und starte mit dem Stift.';

  @override
  String get deleteNotebookTitle => 'Notizbuch löschen?';

  @override
  String deleteNotebookBody(String title) {
    return '\"$title\" wird dauerhaft entfernt.';
  }

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seiten',
      one: '1 Seite',
    );
    return '$_temp0';
  }

  @override
  String get outline => 'Gliederung';

  @override
  String get outlineEmpty =>
      'Kapitel und Unterkapitel für eine klare Struktur hinzufügen.';

  @override
  String get pages => 'Seiten';

  @override
  String get addPage => 'Seite hinzufügen';

  @override
  String get addSection => 'Abschnitt hinzufügen';

  @override
  String get addSubchapter => 'Unterkapitel hinzufügen';

  @override
  String get addParentChapter => 'Übergeordnetes Kapitel';

  @override
  String get nameChapterHint => 'Kapitel benennen…';

  @override
  String get nameSubchapterHint => 'Unterkapitel benennen…';

  @override
  String get schoolClass => 'Klasse';

  @override
  String get schoolClassHint => 'In welcher Klasse bist du?';

  @override
  String get schoolClassNone => 'Keine Angabe';

  @override
  String schoolClassValue(int n) {
    return 'Klasse $n';
  }

  @override
  String get importFromPreviousClass => 'Aus letzter Klasse übernehmen';

  @override
  String importFromClass(int n) {
    return 'Aus Klasse $n übernehmen';
  }

  @override
  String get importChapterHint => 'Tippe ein Kapitel an, um es zu übernehmen.';

  @override
  String get newSchoolYearNotebook =>
      'Neues Notizbuch für dieses Schuljahr erstellen';

  @override
  String get importChaptersTitle => 'Kapitel übernehmen';

  @override
  String importChaptersBody(String title, int n) {
    return 'Welche Kapitel aus „$title“ sollen in Klasse $n mitkommen?';
  }

  @override
  String get importChaptersEmpty =>
      'Im letzten Notizbuch gibt es noch keine Kapitel.';

  @override
  String get selectAll => 'Alle';

  @override
  String get selectNone => 'Keine';

  @override
  String get dismiss => 'Ausblenden';

  @override
  String get tapToContinue => 'Tippen zum Fortfahren';

  @override
  String get pen => 'Stift';

  @override
  String get ballpointPen => 'Kugelschreiber';

  @override
  String get pencil => 'Bleistift';

  @override
  String get fountainPen => 'Füller';

  @override
  String get pressureSensitivity => 'Druck';

  @override
  String get marker => 'Marker';

  @override
  String get textTool => 'Text';

  @override
  String get eraser => 'Radierer';

  @override
  String get lasso => 'Lasso';

  @override
  String get addTextBox => 'Textfeld hinzufügen';

  @override
  String get paperCreator => 'Papier-Editor';

  @override
  String get undo => 'Rückgängig';

  @override
  String get redo => 'Wiederholen';

  @override
  String get deleteSelection => 'Auswahl löschen';

  @override
  String get writing => 'Schreiben';

  @override
  String get fingerPanZoom => 'Nur Stift malt (Finger schiebt)';

  @override
  String get fingerPanZoomHint => 'An: nur Stift malt, Finger schiebt.';

  @override
  String get defaultTemplate => 'Standardvorlage';

  @override
  String get language => 'Sprache';

  @override
  String get german => 'Deutsch';

  @override
  String get english => 'Englisch';

  @override
  String get systemLanguage => 'System';

  @override
  String get sync => 'Sync';

  @override
  String get syncUpToDate => 'Aktuell';

  @override
  String get syncQueueEmpty => 'Warteschlange leer · Offline-First Sync';

  @override
  String syncPending(int count) {
    return '$count ausstehende Änderungen';
  }

  @override
  String get flushSync => 'Sync-Warteschlange leeren';

  @override
  String get about => 'Über';

  @override
  String get aboutBody =>
      'Notis — Smart Text, Papier-Editor, Gliederung, globale Suche und Offline-First Sync.';

  @override
  String get searchHint => 'Suchen oder @Fach @Klasse10 …';

  @override
  String get searchEmpty => 'Tippe, um in allen Notizen zu suchen.';

  @override
  String get crossLink => 'Querverweis';

  @override
  String get linkToNotebook => 'Mit Notizbuch verknüpfen';

  @override
  String get crossLinkCreated => 'Querverweis erstellt';

  @override
  String get needAnotherNotebook =>
      'Erstelle ein weiteres Notizbuch zum Verknüpfen.';

  @override
  String get importPdf => 'PDF importieren';

  @override
  String get exportPdf => 'PDF exportieren';

  @override
  String pageOf(int current, int total) {
    return 'Seite $current/$total';
  }

  @override
  String get infiniteCanvas => 'Endlose Leinwand';

  @override
  String get pageMode => 'Seitenmodus';

  @override
  String get addTag => 'Tag hinzufügen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get formatText => 'Text formatieren';

  @override
  String get bold => 'Fett';

  @override
  String get italic => 'Kursiv';

  @override
  String get free => 'Frei';

  @override
  String get close => 'Schließen';

  @override
  String get apply => 'Übernehmen';

  @override
  String get renameSection => 'Abschnitt umbenennen';

  @override
  String get indent => 'Einrücken';

  @override
  String get outdent => 'Ausrücken';

  @override
  String chapter(int n) {
    return 'Kapitel $n';
  }

  @override
  String get section => 'Abschnitt';

  @override
  String get newText => 'Neuer Text';

  @override
  String get style => 'Stil';

  @override
  String get background => 'Hintergrund';

  @override
  String get lineSpacing => 'Linienabstand';

  @override
  String get gridSize => 'Karogröße';

  @override
  String get leftMargin => 'Linker Rand';

  @override
  String get topMargin => 'Oberer Rand';

  @override
  String get myPaper => 'Mein Papier';

  @override
  String get shapes => 'Formen';

  @override
  String get ruler => 'Lineal';

  @override
  String get compass => 'Zirkel';

  @override
  String get fixGuide => 'Fixieren';

  @override
  String get guideFixed => 'Fixiert';

  @override
  String get compassSetCenter => 'Mittelpunkt antippen';

  @override
  String get compassRadius => 'Radius';

  @override
  String get strokeStyleSolid => 'Durchgezogen';

  @override
  String get strokeStyleDashed => 'Gestrichelt';

  @override
  String get strokeStyleDotted => 'Gepunktet';

  @override
  String get strokeStyleDashDot => 'Strich-Punkt';

  @override
  String get rulerHint => 'Ziehen für eine Gerade (rastet alle 15°)';

  @override
  String get compassHint => 'Mittelpunkt → Radius ziehen';

  @override
  String get shapeLine => 'Linie';

  @override
  String get shapeRect => 'Rechteck';

  @override
  String get shapeEllipse => 'Ellipse';

  @override
  String get shapeArrow => 'Pfeil';

  @override
  String get insertImage => 'Bild einfügen';

  @override
  String get readMode => 'Lesemodus';

  @override
  String get editMode => 'Bearbeiten';

  @override
  String get libraryHome => 'Bibliothek';

  @override
  String get freeTextBox => 'Freie Box';

  @override
  String get pageText => 'SeitenText';

  @override
  String get newFolder => 'Neuer Ordner';

  @override
  String get folder => 'Ordner';

  @override
  String get folderName => 'Ordnername';

  @override
  String get folders => 'Ordner';

  @override
  String get notebooks => 'Notizbücher';

  @override
  String get chapters => 'Kapitel';

  @override
  String get entries => 'Einträge';

  @override
  String get flashcards => 'Karteikarten';

  @override
  String get newFlashcardDeck => 'Neues Karteikarten-Set';

  @override
  String get untitledDeck => 'Unbenanntes Set';

  @override
  String get newFlashcard => 'Neue Karteikarte';

  @override
  String get flashcardFront => 'Vorderseite';

  @override
  String get flashcardBack => 'Rückseite';

  @override
  String get noFlashcardsYet => 'Noch keine Karteikarten';

  @override
  String get tapToFlip => 'Tippen zum Umdrehen';

  @override
  String get searchEverything => 'Suchen oder @Wirtschaft addition …';

  @override
  String get shareExport => 'Teilen & exportieren';

  @override
  String get printPdf => 'Drucken / PDF-Vorschau';

  @override
  String get printPdfHint => 'System-Druckdialog öffnen';

  @override
  String get sharePdf => 'Notizbuch als PDF teilen';

  @override
  String get sharePdfHint => 'Gesamtes Notizbuch';

  @override
  String get shareCurrentPage => 'Aktuelle Seite teilen';

  @override
  String get shareCurrentPageHint => 'Nur diese Seite als PDF';

  @override
  String get documentType => 'Dokumenttyp';

  @override
  String get paperSize => 'Papierformat';

  @override
  String get pageOrientation => 'Ausrichtung';

  @override
  String get portrait => 'Hochformat';

  @override
  String get landscape => 'Querformat';

  @override
  String get paperLetter => 'Brief (Letter)';

  @override
  String get paperLegal => 'Legal';

  @override
  String get paperTabloid => 'Tabloid';

  @override
  String get newPagesOnlyHint => 'Gilt nur für neu hinzugefügte Seiten.';

  @override
  String get choosePastEvent => 'Vergangenen Termin auswählen';

  @override
  String get repeatEvent => 'Termin wiederholen';

  @override
  String get repeatFrequency => 'Wiederholung';

  @override
  String get repeatDaily => 'Täglich';

  @override
  String get repeatWeekly => 'Wöchentlich';

  @override
  String get repeatMonthly => 'Monatlich';

  @override
  String get repeatUntil => 'Wiederholen bis';

  @override
  String get repeatInterval => 'Intervall';

  @override
  String repeatEvery(int count) {
    return 'Alle $count';
  }

  @override
  String get weekdayMon => 'Mo';

  @override
  String get weekdayTue => 'Di';

  @override
  String get weekdayWed => 'Mi';

  @override
  String get weekdayThu => 'Do';

  @override
  String get weekdayFri => 'Fr';

  @override
  String get weekdaySat => 'Sa';

  @override
  String get weekdaySun => 'So';

  @override
  String get importedPageTemplateTitle => 'Importierte Vorlage';

  @override
  String get importedPageTemplateBody =>
      'Die vorherige Seite nutzt ein Bild oder PDF als Hintergrund. Welche Vorlage soll die neue Seite verwenden?';

  @override
  String get keepCurrentTemplate => 'Aktuelle Vorlage behalten';

  @override
  String get useNotebookDefault => 'Notizbuch-Standard verwenden';

  @override
  String get documentTypeFixedHint =>
      'Wird beim Anlegen festgelegt und bleibt so';

  @override
  String get infiniteDocument => 'Unendliches Dokument';

  @override
  String get infiniteDocumentHint =>
      'Eine große Leinwand mit freiem Zoom. Nur der sichtbare Bereich wird gezeichnet.';

  @override
  String get eraserStroke => 'Strich';

  @override
  String get eraserSection => 'Abschnitt';

  @override
  String get eraserPrecise => 'Genau';

  @override
  String get editWidth => 'Strichstärke anpassen';

  @override
  String get editWidthHint => 'Tippen: wählen · Halten: anpassen';

  @override
  String get addColor => 'Farbe hinzufügen';

  @override
  String get removeColor => 'Farbe entfernen';

  @override
  String get hue => 'Farbton';

  @override
  String get saturation => 'Sättigung';

  @override
  String get brightness => 'Helligkeit';

  @override
  String get colorPickerTitle => 'Farbe wählen';

  @override
  String get opacity => 'Deckkraft';

  @override
  String get recentColors => 'Zuletzt genutzt';

  @override
  String get presetColors => 'Vorschläge';

  @override
  String get customColor => 'Eigene Farbe';

  @override
  String get editColorHint => 'Tippen: wählen · Halten: bearbeiten';

  @override
  String get appearance => 'Aussehen';

  @override
  String get appearanceHint => 'Look und Hell-/Dunkelmodus der App';

  @override
  String get lookStudio => 'Studio';

  @override
  String get lookStudioHint => 'Graphit mit Indigo-Akzent';

  @override
  String get lookPaper => 'Papier';

  @override
  String get lookPaperHint => 'Creme, Tiefgrün, Serifen';

  @override
  String get lookFresh => 'Frisch';

  @override
  String get lookFreshHint => 'Weiß, Türkis, viel Luft';

  @override
  String get lookMono => 'Monochrom';

  @override
  String get lookMonoHint => 'Schwarz-Weiß, reduziert';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Hell';

  @override
  String get themeModeDark => 'Dunkel';

  @override
  String get moreOptions => 'Weitere Optionen';

  @override
  String get menuPageGroup => 'Seite';

  @override
  String get menuViewGroup => 'Ansicht';

  @override
  String get menuDocumentGroup => 'Dokument';

  @override
  String get menuPaperGroup => 'Papier dieser Seite';

  @override
  String get paperPresets => 'Vorlagen';

  @override
  String get paperPresetsHint =>
      'Tipp zum Übernehmen · Eigene Vorlagen lange drücken zum Löschen';

  @override
  String get paperPreview => 'Vorschau';

  @override
  String get paperColor => 'Papierfarbe';

  @override
  String get lineColor => 'Linienfarbe';

  @override
  String get applyPaper => 'Auf Seite anwenden';

  @override
  String get resetDefaults => 'Zurücksetzen';

  @override
  String get blankPaperHint => 'Leeres Papier — nur Farbe und Name anpassen.';

  @override
  String get editingBuiltinHint =>
      'Builtin-Vorlage als Vorlage — Speichern legt eine eigene Kopie an.';

  @override
  String get collegeRuled => 'College';

  @override
  String get narrowRuled => 'Eng liniert';

  @override
  String get dotGrid => 'Feines Raster';

  @override
  String get pageBrowseMode => 'Seiten blättern';

  @override
  String get pageBrowseModeHint =>
      'Wischen: Seite für Seite links/rechts. Scrollen: alle Seiten untereinander.';

  @override
  String get browseSwipe => 'Wischen';

  @override
  String get browseScroll => 'Durchscrollen';

  @override
  String get gesturesSection => 'Gesten';

  @override
  String get gesturesSectionHint =>
      'Apple Pencil und Multi-Touch-Kurzbefehle zuordnen.';

  @override
  String get gesturePencilDoubleTap => 'Pencil Doppeltipp';

  @override
  String get gesturePencilSqueeze => 'Pencil Zusammendrücken';

  @override
  String get gestureTwoFingerTap => 'Zwei-Finger-Tipp';

  @override
  String get gestureThreeFingerSwipeLeft => 'Drei Finger nach links';

  @override
  String get gestureThreeFingerSwipeRight => 'Drei Finger nach rechts';

  @override
  String get gestureActionNone => 'Nichts';

  @override
  String get gestureActionToggleEraser => 'Stift / Radierer';

  @override
  String get gestureActionPreviousTool => 'Vorheriges Werkzeug';

  @override
  String get gestureActionOpenToolWheel => 'Werkzeugrad öffnen';

  @override
  String get gestureActionUndo => 'Rückgängig';

  @override
  String get gestureActionRedo => 'Wiederholen';

  @override
  String get gestureActionNextPage => 'Nächste Seite';

  @override
  String get gestureActionPreviousPage => 'Vorherige Seite';

  @override
  String get gestureActionExportPage => 'Seite exportieren';

  @override
  String get gestureActionCyclePenColor => 'Stiftfarbe wechseln';

  @override
  String get gestureActionFitZoom => 'Seite einpassen';

  @override
  String get gestureActionGoBack => 'Zurück';

  @override
  String pdfImportProgress(int done, int total) {
    return 'PDF importieren… $done/$total';
  }

  @override
  String get savePageAsTemplate => 'Seite als Vorlage';

  @override
  String get savePageAsTemplateHint =>
      'Eigenes Seitendesign speichern — mit oder ohne Linien.';

  @override
  String get lineLayout => 'Linien';

  @override
  String get noLines => 'Keine';

  @override
  String get fromPage => 'Von Seite';

  @override
  String get customLines => 'Eigene';

  @override
  String get customLinesHint =>
      'Tippen setzt/entfernt Linien. Links tippen setzt den Rand.';

  @override
  String get fillRuled => 'Liniert füllen';

  @override
  String get clearLines => 'Linien löschen';

  @override
  String get templateSaved => 'Vorlage gespeichert';

  @override
  String get timetable => 'Stundenplan';

  @override
  String get timetableHint =>
      'Tippe eine Zelle zum Eintragen. Zeiten links tippen (Scroll-Räder). Blöcke können ganz oder geteilt sein. Fächer mit Ordnern verknüpfen.';

  @override
  String get timetableEmptyToday =>
      'Noch nichts für heute — tippen zum Eintragen';

  @override
  String timetableTodayPreview(String preview) {
    return 'Heute: $preview';
  }

  @override
  String get subject => 'Fach';

  @override
  String get subjectHint => 'z. B. Englisch';

  @override
  String get room => 'Raum';

  @override
  String get roomHint => 'z. B. R204';

  @override
  String get color => 'Farbe';

  @override
  String get clear => 'Leeren';

  @override
  String get editPeriod => 'Stunde anpassen';

  @override
  String get periodLabel => 'Bezeichnung';

  @override
  String get periodStart => 'Beginn';

  @override
  String get periodEnd => 'Ende';

  @override
  String get addPeriod => 'Stunde hinzufügen';

  @override
  String get removePeriod => 'Letzte Stunde entfernen';

  @override
  String get mondayShort => 'Mo';

  @override
  String get tuesdayShort => 'Di';

  @override
  String get wednesdayShort => 'Mi';

  @override
  String get thursdayShort => 'Do';

  @override
  String get fridayShort => 'Fr';

  @override
  String lastSync(String time) {
    return 'Zuletzt synchronisiert: $time';
  }

  @override
  String get blockMode => 'Block';

  @override
  String get fullBlock => 'Ganzer Block';

  @override
  String get splitBlock => 'Geteilt';

  @override
  String fullBlockHint(int minutes) {
    return 'Ein Fach für den gesamten Block ($minutes Min).';
  }

  @override
  String splitBlockHint(String first, String second) {
    return 'Geteilt: $first · dann $second';
  }

  @override
  String get firstHalf => '1. Hälfte';

  @override
  String get secondHalf => '2. Hälfte';

  @override
  String get linkFolder => 'Mit Ordner verknüpfen';

  @override
  String get noFolderLink => 'Kein Ordner';

  @override
  String blockDuration(int minutes) {
    return '$minutes Minuten';
  }

  @override
  String get nowOn => 'Jetzt dran';

  @override
  String nowLesson(String subject, String when) {
    return 'Jetzt: $subject ($when)';
  }

  @override
  String nowLessonShort(String subject) {
    return 'Jetzt: $subject';
  }

  @override
  String get newInfiniteDocument => 'Endloses Dokument';

  @override
  String get untitledInfinite => 'Endlose Leinwand';

  @override
  String get pageModeHint => 'Klassische Seiten zum Blättern';

  @override
  String get infiniteDocumentShortHint =>
      'Riesige Fläche, extrem rein- und rauszoomen';

  @override
  String get markFavorite => 'Als Favorit markieren';

  @override
  String get editFolder => 'Ordner bearbeiten';

  @override
  String get deleteFolderTitle => 'Ordner löschen?';

  @override
  String deleteFolderBody(String name) {
    return '\"$name\" wird entfernt. Enthaltene Notizbücher bleiben erhalten und landen im Hauptordner.';
  }

  @override
  String get folderActions => 'Ordner';

  @override
  String get folderIcon => 'Symbol';

  @override
  String get newFolderHint => 'Farbe und Symbol wählen';

  @override
  String get newNotebookHint => 'Seitennotizbuch mit Cover und Vorlage';

  @override
  String get newDeckHint => 'Karteikarten mit eigener Farbe';

  @override
  String get planner => 'Noten & Kalender';

  @override
  String get plannerEmptyHint => 'Termine und Noten eintragen';

  @override
  String get calendar => 'Kalender';

  @override
  String get grades => 'Noten';

  @override
  String get addAppointment => 'Termin';

  @override
  String get editAppointment => 'Termin bearbeiten';

  @override
  String get addGrade => 'Note';

  @override
  String get editGrade => 'Note bearbeiten';

  @override
  String appointmentsOnDay(String day) {
    return 'Termine am $day';
  }

  @override
  String get noAppointmentsYet => 'Noch keine Termine an diesem Tag.';

  @override
  String get noGradesYet => 'Noch keine Noten — Fach wählen und eintragen.';

  @override
  String get gradeAverage => 'Schnitt (gewichtet)';

  @override
  String gradeAverageShort(String value) {
    return 'Schnitt $value';
  }

  @override
  String get gradeTitle => 'Bezeichnung';

  @override
  String get gradeTitleHint => 'z. B. Klassenarbeit 2';

  @override
  String get gradeValue => 'Note / Wert';

  @override
  String get gradeWeight => 'Gewicht';

  @override
  String get scaleGerman => '1–6';

  @override
  String get scalePercent => '%';

  @override
  String get scalePoints => 'Punkte';

  @override
  String get kindAppointment => 'Termin';

  @override
  String get kindExam => 'Klausur';

  @override
  String get kindHomework => 'Hausaufgabe';

  @override
  String get startsAt => 'Beginn';

  @override
  String get endsAt => 'Ende';

  @override
  String get optional => 'Optional';

  @override
  String get noteOptional => 'Notiz (optional)';

  @override
  String get saturdayShort => 'Sa';

  @override
  String get sundayShort => 'So';

  @override
  String get shareAppointment => 'Termin weiterleiten';

  @override
  String get shareAppointmentHint =>
      'Text kopieren und z. B. in Chat oder Mail einfügen. ICS für Kalender-Apps.';

  @override
  String get copyForForward => 'Text kopieren';

  @override
  String get copiedForForward => 'Kopiert — bereit zum Weiterleiten';

  @override
  String get copyIcs => 'Als Kalender (.ics) kopieren';

  @override
  String get icsCopied => 'ICS-Text kopiert';

  @override
  String get schoolSection => 'Schule & Studium';

  @override
  String get educationLevel => 'Bildungsstufe';

  @override
  String get educationLevelHint => 'Notenskala und Begriffe.';

  @override
  String get eduSek1 => 'Sek I';

  @override
  String get eduSek2 => 'Sek II';

  @override
  String get eduUniversity => 'Studium';

  @override
  String get eduScaleGradesHint => 'Rechnung in Noten (1–6).';

  @override
  String get eduScalePointsHint => 'Rechnung in Punkten.';

  @override
  String get eduScaleSek1Hint =>
      'Noten 1–6 · Halbjahre · schriftlich/mündlich gewichtet.';

  @override
  String get eduScaleSek2Hint =>
      '0–15 Punkte · Q1–Q4 + Abitur · Prognose auf 900 Punkte.';

  @override
  String get eduScaleUniHint => 'Noten 1,0–5,0 · ECTS-gewichteter Schnitt.';

  @override
  String get gradeKindWritten => 'Schriftlich';

  @override
  String get gradeKindOral => 'Mündlich';

  @override
  String get gradeKindOtherParticipation => 'Sonstige Mitarbeit';

  @override
  String get gradeKindKlassenarbeit => 'Klassenarbeit';

  @override
  String get periodH1 => '1. Halbjahr';

  @override
  String get periodH2 => '2. Halbjahr';

  @override
  String get periodQ1 => 'Q1';

  @override
  String get periodQ2 => 'Q2';

  @override
  String get periodQ3 => 'Q3';

  @override
  String get periodQ4 => 'Q4';

  @override
  String get periodAbiExam => 'Abitur';

  @override
  String get periodSemester => 'Semester';

  @override
  String get abiPrognosisTitle => 'Abitur-Prognose';

  @override
  String abiProjectedPoints(String points) {
    return 'Hochrechnung: $points / 900';
  }

  @override
  String abiProjectedNote(String note) {
    return 'Voraussichtliche Note: $note';
  }

  @override
  String abiMinPassProgress(String have, String need) {
    return 'Mindestpunkte: $have / $need';
  }

  @override
  String abiBlockProgress(int blocks, String avg) {
    return 'Nach $blocks/5 Blöcken · Ø $avg Punkte';
  }

  @override
  String get uniPrognosisTitle => 'Studienfortschritt';

  @override
  String uniGpa(String gpa) {
    return 'ECTS-Schnitt: $gpa';
  }

  @override
  String uniEctsProgress(String have, String need) {
    return '$have / $need ECTS';
  }

  @override
  String get ectsLabel => 'ECTS';

  @override
  String get semesterLabelField => 'Semester (z. B. WiSe 25/26)';

  @override
  String get markAbiSubject => 'Abiturfach (für Prüfungs-Prognose)';

  @override
  String get targetEcts => 'Ziel-ECTS';

  @override
  String get targetEctsHint => 'Benötigte Credit Points für den Abschluss.';

  @override
  String get abiProjectionSettings => 'Abitur-Hochrechnung';

  @override
  String get abiProjectionHint =>
      'Anzahl Kurse (Block I) und Prüfungen (Block II).';

  @override
  String get abiCourseCount => 'Kurse in Block I';

  @override
  String get abiExams4 => '4 Prüfungen';

  @override
  String get abiExams5 => '5 Prüfungen';

  @override
  String roundedPoints(String points) {
    return 'Gerundet: $points P';
  }

  @override
  String get gradeValueUni => 'Note (1,0–5,0)';

  @override
  String get gradeValuePoints15 => 'Punkte (0–15)';

  @override
  String get gradeTendency => 'Tendenz';

  @override
  String get gradeTendencyNone => 'ohne';

  @override
  String selectedGrade(String grade) {
    return 'Auswahl: $grade';
  }

  @override
  String get archivedGradesTitle => 'Andere Stufen (Archiv)';

  @override
  String get archivedGradesHint =>
      'Noten aus Sek I / Sek II / Studium bleiben erhalten — hier nur abgelegt.';

  @override
  String editingArchivedGrade(String level) {
    return 'Archiv-Note ($level)';
  }

  @override
  String get scanAttachment => 'Arbeit einscannen';

  @override
  String get scanAttachmentHint =>
      'Foto oder Scan von Test, Klassenarbeit, Klausur … an die Note hängen.';

  @override
  String get scanAdd => 'Scan hinzufügen';

  @override
  String get scanWithCamera => 'Kamera';

  @override
  String get scanFromGallery => 'Galerie / Datei';

  @override
  String scanPage(int n) {
    return 'Scan $n';
  }

  @override
  String scanCount(int count) {
    return '$count Scans';
  }

  @override
  String get gradesSectionsHint => 'Noten bleiben beim Stufenwechsel erhalten.';

  @override
  String get schoolYear => 'Schuljahr';

  @override
  String get previousSchoolYear => 'Vorheriges Jahr';

  @override
  String get nextSchoolYear => 'Nächstes Jahr';

  @override
  String gradesEmptyYear(String year) {
    return 'Noch keine Noten in $year.';
  }

  @override
  String get gradeDetails => 'Note';

  @override
  String get viewMode => 'Ansehen';

  @override
  String get noScansAttached => 'Kein Scan hinterlegt.';

  @override
  String get semesterShort => 'Semester';

  @override
  String get federalState => 'Bundesland';

  @override
  String get federalStateHint => 'Für die Anzeige der Schulferien im Kalender.';

  @override
  String get stateBw => 'Baden-Württemberg';

  @override
  String get stateBy => 'Bayern';

  @override
  String get stateBe => 'Berlin';

  @override
  String get stateBb => 'Brandenburg';

  @override
  String get stateHb => 'Bremen';

  @override
  String get stateHh => 'Hamburg';

  @override
  String get stateHe => 'Hessen';

  @override
  String get stateMv => 'Mecklenburg-Vorpommern';

  @override
  String get stateNi => 'Niedersachsen';

  @override
  String get stateNw => 'Nordrhein-Westfalen';

  @override
  String get stateRp => 'Rheinland-Pfalz';

  @override
  String get stateSl => 'Saarland';

  @override
  String get stateSn => 'Sachsen';

  @override
  String get stateSt => 'Sachsen-Anhalt';

  @override
  String get stateSh => 'Schleswig-Holstein';

  @override
  String get stateTh => 'Thüringen';

  @override
  String get holidayAutumn => 'Herbstferien';

  @override
  String get holidayChristmas => 'Weihnachtsferien';

  @override
  String get holidayWinter => 'Winterferien';

  @override
  String get holidayEaster => 'Osterferien';

  @override
  String get holidayPentecost => 'Pfingstferien';

  @override
  String get holidaySummer => 'Sommerferien';

  @override
  String holidaysForState(String state) {
    return 'Ferien: $state';
  }

  @override
  String holidayBanner(String name) {
    return 'Ferien: $name';
  }

  @override
  String get gradeKindKlausur => 'Klausur';

  @override
  String get gradeKindTest => 'Test';

  @override
  String get gradeKindUniExam => 'Klausur';

  @override
  String get gradeKindHomework => 'Hausarbeit';

  @override
  String get subjectFromTimetableDay =>
      'Fach aus dem Stundenplan (dieser Wochentag)';

  @override
  String get subjectFromTimetableWeekend => 'Wochenende — kein Stundenplan-Tag';

  @override
  String get noSubjectsThatDay =>
      'An diesem Tag stehen keine Fächer im Stundenplan.';

  @override
  String get gradesNeedTimetable => 'Trage zuerst Fächer im Stundenplan ein.';

  @override
  String weightForSubject(String subject) {
    return 'Gewichtung: $subject';
  }

  @override
  String weightHint(String major, String minor) {
    return '$major und $minor einmal festlegen — wie in Notan.';
  }

  @override
  String weightSummary(String major, int majorPct, String minor, int minorPct) {
    return '$major $majorPct% · $minor $minorPct%';
  }

  @override
  String get setWeight => 'Gewichtung';

  @override
  String gradeCount(int count) {
    return '$count Noten';
  }

  @override
  String get gradeValuePoints => 'Punkte';

  @override
  String get sectionGeneral => 'Allgemein';

  @override
  String get sectionSubscription => 'Abo & Coins';

  @override
  String get upgradeToNotisPro => 'Notis Pro holen';

  @override
  String get upgradeToNotisProHint =>
      'Monatlich, jährlich oder einmalig — gesteuert über RevenueCat.';

  @override
  String get notisProActive => 'Notis Pro ist aktiv';

  @override
  String get notisProInactive => 'Kostenloser Plan';

  @override
  String get manageSubscription => 'Abo verwalten';

  @override
  String get manageSubscriptionHint =>
      'Kündigen, wiederherstellen oder Support im Customer Center.';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get restorePurchasesSuccess => 'Notis Pro wurde wiederhergestellt.';

  @override
  String get restorePurchasesEmpty => 'Kein aktiver Kauf gefunden.';

  @override
  String get purchaseCancelled => 'Kauf abgebrochen.';

  @override
  String purchaseFailed(String message) {
    return 'Kauf fehlgeschlagen: $message';
  }

  @override
  String get paywallUnavailable =>
      'Die Paywall ist auf diesem Gerät nicht verfügbar.';

  @override
  String get choosePlan => 'Plan wählen';

  @override
  String get choosePlanHint =>
      'Lehrer- und Schülerpläne. Käufe laufen über den Store.';

  @override
  String get revenueCatTestStoreHint =>
      'Die App nutzt noch den RevenueCat-Test-Store. Für Apple den Apple-API-Key (appl_) verwenden.';

  @override
  String get planLehrerLite => 'Lehrer Lite';

  @override
  String get planLehrerPro => 'Lehrer Pro';

  @override
  String get planSchuelerLite => 'Schüler Lite';

  @override
  String get planSchuelerPro => 'Schüler Pro';

  @override
  String get planLehrerLitePrice => '1,99 € / Monat';

  @override
  String get planLehrerProPrice => '9,99 € / Monat';

  @override
  String get planSchuelerLitePrice => '4,99 € / Jahr oder 20 € einmalig';

  @override
  String get planSchuelerProPrice => '9,99 € / Jahr oder 30 € einmalig';

  @override
  String get planPointWeeklyBackup => 'Wöchentliches Backup';

  @override
  String get planPointDailyBackup => 'Tägliches Backup';

  @override
  String get planPointTeacherExchange => 'Zugriff auf den Lehrmittel-Austausch';

  @override
  String get planPointPartialMarketplace => 'Teilweise kostenloser Marketplace';

  @override
  String get planPointFullMarketplace => 'Vollständig kostenloser Marketplace';

  @override
  String get planPointClassLoans => '5 Marketplace-Leihgaben pro Klasse';

  @override
  String get planPointSyncFive => 'Online-Sync für 5 Geräte';

  @override
  String get planPointSyncUnlimited => 'Unbegrenzter Online-Sync';

  @override
  String get planPointMarketplaceThree => '3 Marketplace-Artikel kostenlos';

  @override
  String get sectionSupport => 'Unterstützung';

  @override
  String get sectionSyncPreview => 'Sync (Vorschau)';

  @override
  String get localTierHint => 'Lokal zum Testen — keine echten Käufe.';

  @override
  String get tierFree => 'Free';

  @override
  String get tierPro => 'Pro';

  @override
  String get tierProPlus => 'Pro+';

  @override
  String get tierTeacher => 'Lehrer';

  @override
  String coinsBalance(int count) {
    return '$count Coins';
  }

  @override
  String get watchAdForCoins => 'Werbung ansehen';

  @override
  String get watchRewardedAd => 'Kurzes Video ansehen';

  @override
  String get rewardedAdDemoBadge => 'Demo — kein echtes Werbevideo';

  @override
  String get rewardedAdTitle => 'Belohnung freischalten';

  @override
  String rewardedAdCoinsBody(int count) {
    return 'Nach dem Demo-Schritt erhältst du $count Coins.';
  }

  @override
  String get rewardedAdFeatureBody =>
      'Nach dem Demo-Schritt wird dieses Feature freigeschaltet.';

  @override
  String get adPrivacyOptions => 'Werbe-Einstellungen';

  @override
  String get adPrivacyOptionsHint =>
      'Einwilligung für personalisierte Werbung ändern';

  @override
  String get rewardedAdLoading => 'Werbung wird geladen …';

  @override
  String get rewardedAdNotFinished =>
      'Video nicht vollständig angesehen — keine Belohnung.';

  @override
  String get featureUnlocked => 'Feature freigeschaltet';

  @override
  String get collaborationSignInRequired =>
      'Melde dich an für Cloud-Zusammenarbeit.';

  @override
  String get collaborationUpgradeRequired =>
      'Für Cloud-Zusammenarbeit benötigst du einen passenden Plan.';

  @override
  String get collabLocalTitle => 'In der Nähe (ohne Konto)';

  @override
  String get collabLocalBody =>
      'Teile dieses Notizbuch über WLAN oder Hotspot. Funktioniert komplett offline — keine Anmeldung nötig.';

  @override
  String get collabCloudTitle => 'Cloud-Zusammenarbeit';

  @override
  String get collabCloudBody =>
      'Lade jemanden per Firebase-UID ein. Die Rolle steuert, ob bearbeitet oder nur gelesen werden darf.';

  @override
  String get collabMemberUid => 'Firebase-UID';

  @override
  String get collabRole => 'Rolle';

  @override
  String get collabSaveInvite => 'Einladung speichern';

  @override
  String get collabMembers => 'Mitglieder';

  @override
  String get collabStartLive => 'Live-Session starten';

  @override
  String collabLiveStarted(String id) {
    return 'Live-Session gestartet: $id';
  }

  @override
  String get collabComments => 'Kommentare';

  @override
  String get collabLeaveComment => 'Kommentar hinterlassen';

  @override
  String get signIn => 'Anmelden';

  @override
  String coinsEarned(int count) {
    return '+$count Coins';
  }

  @override
  String get notEnoughCoins => 'Nicht genug Coins';

  @override
  String unlockWithCoins(int count) {
    return 'Mit $count Coins freischalten';
  }

  @override
  String get featureAvailable => 'Freigeschaltet';

  @override
  String get featurePremiumPaper => 'Premium-Papier';

  @override
  String get featurePremiumCover => 'Premium-Cover';

  @override
  String get featureAudioTranscription => 'Audio-Transkription';

  @override
  String get featurePdfCompress => 'PDF komprimieren';

  @override
  String get featureHandwritingOcr => 'Handschrift-OCR';

  @override
  String get featureNoForcedAds => 'Keine Zwangswerbung';

  @override
  String get featureSessionCollab => 'Session-Zusammenarbeit';

  @override
  String get featureAsyncCollab => 'Cloud-Zusammenarbeit';

  @override
  String get featureWhiteboard => 'Lehrer-Whiteboard';

  @override
  String get supportBody =>
      'Notis bleibt lokal nutzbar. Mit einem Kaffee hilfst du bei Serverkosten späterer Features.';

  @override
  String get supportBuyCoffee => 'Kaffee ausgeben';

  @override
  String get supportLinkCopied => 'Unterstützungs-Link kopiert';

  @override
  String serverCostsLabel(int euro) {
    return 'Serverkosten (Platzhalter): $euro € / Monat';
  }

  @override
  String serverCostsCovered(int euro) {
    return 'Bisher gedeckt: $euro €';
  }

  @override
  String get syncPreviewHint => 'Vorschau — echte Cloud-Sync kommt später.';

  @override
  String get upcomingNext => 'Als Nächstes';

  @override
  String get createGradeFromExam => 'Note dazu anlegen?';

  @override
  String get createGradeFromExamBody =>
      'Klausur/Test speichern und gleich eine Note mit Fach und Datum vorbereiten.';

  @override
  String get deviceCalendarComingSoon => 'Geräte-Kalender-Sync kommt später.';

  @override
  String get sectionNotebooks => 'Notizbücher';

  @override
  String get exportExtras => 'Export-Extras';

  @override
  String get comingSoonGate => 'Kommt später — jetzt lokal freischaltbar';

  @override
  String get firebaseSetupRequired =>
      'Firebase ist noch nicht eingerichtet. Lokale Daten bleiben verfügbar.';

  @override
  String get cloudAccount => 'Cloud-Konto';

  @override
  String signedInAs(String name) {
    return 'Angemeldet als $name';
  }

  @override
  String get signInGoogle => 'Mit Google anmelden';

  @override
  String get signInApple => 'Mit Apple anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get cloudSyncOffline =>
      'Offline-first: Ohne Anmeldung bleiben Daten nur auf diesem Gerät.';

  @override
  String cloudSyncError(String message) {
    return 'Anmeldung fehlgeschlagen: $message';
  }

  @override
  String get developerTools => 'Entwicklungswerkzeuge';

  @override
  String get developerTierHint =>
      'Nur für lokale Tests – ersetzt keinen Store-Kauf.';

  @override
  String get editSupportDetails => 'Unterstützungsdaten bearbeiten';

  @override
  String get supportUrl => 'Unterstützungs-Link';

  @override
  String get serverCosts => 'Serverkosten pro Monat';

  @override
  String get amountCovered => 'Bisher gedeckt';

  @override
  String get syncStatusIdle => 'Bereit';

  @override
  String get syncStatusUpToDate => 'Aktuell';

  @override
  String get syncStatusSyncing => 'Wird synchronisiert';

  @override
  String get syncStatusSynced => 'Synchronisiert';

  @override
  String get syncStatusFirebaseNotConfigured => 'Firebase nicht eingerichtet';

  @override
  String get syncStatusAuthenticationRequired => 'Anmeldung erforderlich';

  @override
  String get syncStatusPreparingCloud => 'Cloud-Daten werden vorbereitet';

  @override
  String get syncStatusPaused => 'Synchronisierung pausiert';

  @override
  String get lockPage => 'Seite sperren';

  @override
  String get unlockPage => 'Seite entsperren';

  @override
  String get pageLocked => 'Seite gesperrt';

  @override
  String get presentView => 'Präsentieren';

  @override
  String get exitPresentView => 'Präsentation beenden';

  @override
  String get exitPresentViewHint => 'Doppeltippen beendet die Präsentation';

  @override
  String get dragToAddPage => 'Ziehen, um Seite hinzuzufügen';

  @override
  String get zoomIn => 'Vergrößern';

  @override
  String get zoomOut => 'Verkleinern';

  @override
  String get fitPage => 'Seite einpassen';

  @override
  String get deselectTool => 'Werkzeug abwählen';

  @override
  String get pageSidebar => 'Seitenübersicht';

  @override
  String get duplicatePage => 'Seite duplizieren';

  @override
  String get deletePage => 'Seite löschen';

  @override
  String get lastPageHint => 'Ein Notizbuch benötigt mindestens eine Seite.';

  @override
  String get collaborate => 'Zusammenarbeiten';

  @override
  String get scrollDirection => 'Scrollrichtung';

  @override
  String get underline => 'Unterstrichen';

  @override
  String get strikethrough => 'Durchgestrichen';

  @override
  String get increaseFontSize => 'Schrift größer';

  @override
  String get decreaseFontSize => 'Schrift kleiner';

  @override
  String get alignLeft => 'Linksbündig';

  @override
  String get alignCenter => 'Zentriert';

  @override
  String get alignRight => 'Rechtsbündig';

  @override
  String get alignJustify => 'Blocksatz';

  @override
  String get deleteTextBlock => 'Textfeld löschen';

  @override
  String get moveTextBlock => 'Textfeld verschieben';

  @override
  String get studyMode => 'Lernen';

  @override
  String get studyModeHint =>
      'Tinte ausgeblendet — doppeltippen oder „Tinte zeigen“';

  @override
  String get exitStudyMode => 'Lernmodus beenden';

  @override
  String get revealInk => 'Tinte zeigen';

  @override
  String get hideInk => 'Tinte verstecken';

  @override
  String get saveSnapshot => 'Snapshot speichern';

  @override
  String get restoreSnapshot => 'Snapshot wiederherstellen';

  @override
  String get snapshotSaved => 'Snapshot gespeichert';

  @override
  String get snapshotRestored => 'Snapshot wiederhergestellt';

  @override
  String get noSnapshotsYet => 'Noch keine Snapshots für diese Seite';

  @override
  String snapshotLabel(String time) {
    return 'Version $time';
  }

  @override
  String get deleteSnapshot => 'Snapshot löschen';

  @override
  String get confirmRestoreSnapshot =>
      'Diesen Snapshot wiederherstellen? Der aktuelle Seiteninhalt wird ersetzt.';

  @override
  String get nearbySyncTitle => 'Nahe Sync';

  @override
  String get nearbySyncIntro =>
      'Teile dieses Notizbuch über dasselbe WLAN oder einen Hotspot. Beim ersten Mal wird das ganze Notizbuch übertragen, danach nur noch Änderungen — ohne Internet.';

  @override
  String get nearbySyncDeviceName => 'Gerätename';

  @override
  String get nearbySyncHostSection => 'Dieses Notizbuch hosten';

  @override
  String get nearbySyncHostHint =>
      'Starte die Session und gib dem anderen Gerät deine IP-Adresse und den Code. Beide müssen im selben Netz oder Hotspot sein.';

  @override
  String get nearbySyncStartHost => 'Nahe-Session starten';

  @override
  String get nearbySyncJoinSection => 'Session beitreten';

  @override
  String get nearbySyncJoinHint =>
      'IP des Hosts und den 6-stelligen Code vom anderen Gerät eingeben.';

  @override
  String get nearbySyncHostAddress => 'Host-IP-Adresse';

  @override
  String get nearbySyncCode => 'Session-Code';

  @override
  String get nearbySyncJoin => 'Beitreten';

  @override
  String get nearbySyncStop => 'Session beenden';

  @override
  String get nearbySyncCopy => 'Kopieren';

  @override
  String get nearbySyncCopied => 'Kopiert';

  @override
  String nearbySyncPort(int port) {
    return 'Port $port';
  }

  @override
  String get nearbySyncNoAddress =>
      'Noch keine lokale IP gefunden. Mit WLAN verbinden oder Hotspot starten, dann diesen Bildschirm erneut öffnen.';

  @override
  String get nearbySyncStatusIdle => 'Keine Nahe-Session';

  @override
  String get nearbySyncStatusHosting => 'Warte auf Geräte…';

  @override
  String get nearbySyncStatusConnecting => 'Verbinden…';

  @override
  String get nearbySyncStatusSyncing => 'Notizbuch wird übertragen…';

  @override
  String get nearbySyncStatusConnected => 'Nahe Sync aktiv';

  @override
  String get nearbySyncStatusError => 'Nahe-Sync-Fehler';

  @override
  String nearbySyncPeer(String name) {
    return 'Gerät: $name';
  }

  @override
  String nearbySyncPeers(int count) {
    return '$count verbunden';
  }

  @override
  String get nearbySyncSnapshotReceived =>
      'Notizbuch empfangen — wird geöffnet…';

  @override
  String get nearbySyncWebUnsupported =>
      'Nahe Sync braucht die Android- oder iOS-App.';

  @override
  String get nearbySyncDisconnected =>
      'Das andere Gerät hat die Verbindung getrennt.';

  @override
  String get nearbySyncInvalidCode => 'Falscher Session-Code.';

  @override
  String get nearbySyncError => 'Nahe Sync fehlgeschlagen';

  @override
  String get nearbySyncBinaryNote =>
      'PDF-Hintergründe und eingefügte Bilder werden mit dem Notizbuch übertragen. Beide Geräte müssen im selben WLAN oder Hotspot sein.';

  @override
  String get nearbySyncDiscoverHint =>
      'Geräte mit laufender Session erscheinen automatisch. Tippe zum Beitreten.';

  @override
  String get nearbySyncSearching => 'Suche im Netzwerk…';

  @override
  String get nearbySyncSearchStopped => 'Suche pausiert';

  @override
  String get nearbySyncStartSearch => 'Suchen';

  @override
  String get nearbySyncStopSearch => 'Pause';

  @override
  String get nearbySyncNoDevices =>
      'Noch keine Hosts gefunden. Das andere Gerät muss die Session starten.';

  @override
  String get nearbySyncManualJoin => 'Manuell beitreten (IP + Code)';

  @override
  String get nearbySyncJoinManual => 'Mit IP beitreten';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get termsOfService => 'AGB';

  @override
  String get impressum => 'Impressum';

  @override
  String get legalSection => 'Rechtliches';

  @override
  String get openLicenses => 'Open-Source-Lizenzen';

  @override
  String appVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get flashcardAgain => 'Nochmal';

  @override
  String get flashcardHard => 'Schwer';

  @override
  String get flashcardGood => 'Gut';

  @override
  String get flashcardEasy => 'Leicht';

  @override
  String get flashcardStudy => 'Fällige lernen';

  @override
  String get flashcardBrowse => 'Deck durchblättern';

  @override
  String get flashcardSessionDone => 'Für heute bist du durch';

  @override
  String flashcardReviewedCount(int count) {
    return '$count Karten wiederholt';
  }

  @override
  String get flashcardStudyAll => 'Alle Karten lernen';

  @override
  String flashcardDueProgress(int current, int remaining, int due) {
    return '$current / $remaining übrig · $due fällig';
  }

  @override
  String get flashcardFlipToRate =>
      'Karte umdrehen, um zu bewerten, wie gut du sie kanntest';

  @override
  String get importIntoNotebook => 'In Notizbuch importieren';

  @override
  String get importPickNotebookHint =>
      'Wähle, wohin die geteilte Datei als neue Seite(n) soll.';

  @override
  String get importCreateNotebook => 'Neues Notizbuch';

  @override
  String get importNewNotebookTitle => 'Import';

  @override
  String get importAddFiles => 'Dateien hinzufügen';

  @override
  String get importAddFilesHint =>
      'PDF, Bilder, Office, GoodNotes oder ZIP wählen';

  @override
  String get importNoFilesYet => 'Noch keine Dateien zum Import';

  @override
  String get importExistingNotebooks => 'Vorhandene Notizbücher';

  @override
  String get importingFiles => 'Importiere…';

  @override
  String get importAnyFile => 'Datei importieren';

  @override
  String get exportPageAsImage => 'Seite als Bild';

  @override
  String get exportPdfForGoodNotes => 'PDF für GoodNotes';

  @override
  String get exportPdfForGoodNotesHint => 'Dieses PDF in GoodNotes importieren';

  @override
  String get backupSection => 'Backup & Wiederherstellen';

  @override
  String get backupSectionHint =>
      'ZIP mit Notizbüchern, Seiten, Karteikarten, Noten und Stundenplan exportieren — oder aus einem Backup wiederherstellen.';

  @override
  String get backupExport => 'Backup-ZIP exportieren';

  @override
  String get backupExportHint => 'Vollständiges Backup teilen oder speichern';

  @override
  String get backupRestore => 'Aus ZIP wiederherstellen';

  @override
  String get backupRestoreHint => 'Zusammenführen oder lokale Daten ersetzen';

  @override
  String get backupRestoreMergeQuestion =>
      'In vorhandene Daten mergen oder Notizbücher und Decks ersetzen?';

  @override
  String get backupMerge => 'Zusammenführen';

  @override
  String get backupReplace => 'Ersetzen';

  @override
  String backupRestored(int count) {
    return '$count Notizbücher wiederhergestellt';
  }

  @override
  String get noteToFlashcard => 'Als Karteikarte';

  @override
  String get flashcardCreated => 'Karteikarte gespeichert';

  @override
  String get pomodoroFocus => 'Fokus';

  @override
  String get pomodoroBreak => 'Pause';

  @override
  String get pomodoroStart => 'Timer starten';

  @override
  String get pomodoroPause => 'Timer pausieren';

  @override
  String get pomodoroReset => 'Timer zurücksetzen';

  @override
  String get notebookSubject => 'Fach';

  @override
  String get notebookSubjectHint => 'Verknüpfung mit Stundenplan & Noten';

  @override
  String get openLinkedNotebook => 'Notizbuch öffnen';

  @override
  String get createNotebookForSubjectHint =>
      'Noch kein Notizbuch für dieses Fach. Eines anlegen?';

  @override
  String get csvExportFlashcards => 'CSV exportieren';

  @override
  String get csvImportFlashcards => 'CSV importieren';

  @override
  String get csvExportGrades => 'Noten als CSV';

  @override
  String get csvImportGrades => 'Noten aus CSV';

  @override
  String csvImportedCards(int count) {
    return '$count Karten importiert';
  }

  @override
  String csvImportedGrades(int count) {
    return '$count Noten importiert';
  }

  @override
  String get start => 'Starten';

  @override
  String get name => 'Name';

  @override
  String get homework => 'Hausaufgabe';

  @override
  String get share => 'Teilen';

  @override
  String get roleWelcomeTitle => 'Wie nutzt du Notis?';

  @override
  String get roleWelcomeBody =>
      'Wähle deine Rolle. Schüler erhalten den bisherigen Lernbereich, Lehrer zusätzlich Unterrichts- und Materialwerkzeuge.';

  @override
  String get roleStudent => 'Schüler';

  @override
  String get roleTeacher => 'Lehrer';

  @override
  String get roleStudentHint =>
      'Notizbücher, Stundenplan, Noten, Karteikarten und Lernmodus.';

  @override
  String get roleTeacherHint =>
      'Alles aus dem Schülerbereich plus Live-Unterricht, Reihenplanung, Materialien und Notenspiegel.';

  @override
  String get roleChooseStudent => 'Als Schüler starten';

  @override
  String get roleChooseTeacher => 'Als Lehrer starten';

  @override
  String get roleCanChangeLater =>
      'Du kannst die Rolle später in den Einstellungen ändern.';

  @override
  String get roleSection => 'Rolle';

  @override
  String get roleSectionHint =>
      'Die Rolle bestimmt, welche Arbeitsbereiche und Optionen angezeigt werden.';

  @override
  String get teacherWorkspace => 'Lehrerbereich';

  @override
  String get teacherOverview => 'Übersicht';

  @override
  String get teacherOverviewTitle =>
      'Unterricht effizient vorbereiten und steuern';

  @override
  String get teacherOverviewHint =>
      'Live-Sessions, Aufgaben, Stundenkalender, Materialien und Audio-Erklärungen an einem Ort.';

  @override
  String get teacherLiveClass => 'Live-Unterricht';

  @override
  String get teacherLiveClassHint =>
      'Starte eine host-gesteuerte Session und verwalte Schreibrechte, Hände, Fokus und Fortschritt.';

  @override
  String get teacherLessonJournal => 'Stundentagebuch';

  @override
  String get teacherMaterials => 'Materialien';

  @override
  String get teacherGradeReport => 'Notenspiegel';

  @override
  String get teacherProfile => 'Lehrerprofil';

  @override
  String get teacherAudio => 'Audio-Erklärungen';

  @override
  String get teacherAudioHint =>
      'Erklärungen lokal aufnehmen, transkribieren und gezielt teilen.';

  @override
  String get teacherTrainee => 'Referendar-Special';

  @override
  String get teacherTraineeHint =>
      'Nachweis einreichen und erweiterten Materialzugang beantragen.';

  @override
  String teacherSessionActive(String code) {
    return 'Session $code ist aktiv';
  }

  @override
  String teacherLessonCount(int count) {
    return '$count Einträge im Reihenplan';
  }

  @override
  String teacherMaterialCount(int count) {
    return '$count Materialien in deiner Bibliothek';
  }

  @override
  String get teacherNewLesson => 'Neue Unterrichtsstunde';

  @override
  String get teacherStartSession => 'Session starten';

  @override
  String get teacherWhiteboardNotebook => 'Tafel-Notizbuch';

  @override
  String get teacherAddParticipant => 'Teilnehmer hinzufügen';

  @override
  String get teacherNoActiveSession => 'Keine aktive Unterrichts-Session';

  @override
  String teacherJoinCode(String code) {
    return 'Beitrittscode: $code';
  }

  @override
  String get teacherEndSession => 'Session beenden';

  @override
  String get teacherParticipants => 'Teilnehmer';

  @override
  String get teacherAverageProgress => 'Ø Fortschritt';

  @override
  String get teacherFocusCheck => 'Fokus-Check';

  @override
  String get teacherFocusCheckPrivacy =>
      'Zeigt nur an, ob Notis während der Session im Vordergrund ist – keine fremden Apps oder Inhalte.';

  @override
  String get teacherWaitingParticipants =>
      'Warte auf Teilnehmer im lokalen Netzwerk. Für Tests kannst du Teilnehmer manuell hinzufügen.';

  @override
  String get teacherFocused => 'In Notis aktiv';

  @override
  String get teacherLeftApp => 'Notis verlassen';

  @override
  String get teacherAllowWriting => 'Schreibrecht umschalten';

  @override
  String get teacherMute => 'Stummschaltung umschalten';

  @override
  String get teacherAddLesson => 'Stunde hinzufügen';

  @override
  String get teacherNoLessons => 'Noch keine Stunden im Reihenplan.';

  @override
  String get teacherCancelAndShift => 'Ausfall + verschieben';

  @override
  String get teacherAddMaterial => 'Material hinzufügen';

  @override
  String get teacherDurationMinutes => 'Bearbeitungszeit (Minuten)';

  @override
  String get teacherMaterialSearch => 'Nach Fach, Klasse oder Titel filtern';

  @override
  String get teacherHybridDistribution => 'Hybrid Cloud-Distribution';

  @override
  String get teacherHybridDistributionHint =>
      'Lokale Dateien bleiben lokal. Mit konfigurierter Cloud wird später nur ein kleiner Download-Befehl an Schüler gesendet.';

  @override
  String get teacherNoMaterials =>
      'Noch keine Materialien. Füge PDF-, Office- oder Bilddateien hinzu.';

  @override
  String get teacherDistribute => 'An Klasse verteilen';

  @override
  String get teacherDistributionQueued =>
      'Verteilung vorgemerkt. Für Cloud-Downloadbefehle muss ein Backend konfiguriert sein.';

  @override
  String get teacherGradeReportHint =>
      'Aus eingetragenen Noten werden Anzahl, Durchschnitt und Verteilung automatisch berechnet.';

  @override
  String get teacherGradedCount => 'Bewertete Arbeiten';

  @override
  String get teacherClassAverage => 'Klassendurchschnitt';

  @override
  String get teacherNoGrades => 'Noch keine bewerteten Arbeiten vorhanden.';

  @override
  String get teacherVerificationNone => 'Nicht beantragt';

  @override
  String get teacherVerificationPending => 'Prüfung ausstehend';

  @override
  String get teacherVerificationVerified => 'Verifiziert';

  @override
  String get teacherVerificationRejected => 'Nachweis abgelehnt';

  @override
  String get teacherVerificationStatus => 'Status';

  @override
  String get teacherSubmitProof => 'Nachweis einreichen';

  @override
  String get teacherVerificationPrivacy =>
      'Nachweise dürfen erst nach ausdrücklicher Einwilligung und mit definierter Löschfrist an einen vertraglich gebundenen Prüfservice übertragen werden. Aktuell wird nur der lokale Status gespeichert.';

  @override
  String get teacherMicrophonePermission =>
      'Für die Aufnahme wird Mikrofonzugriff benötigt.';

  @override
  String get teacherNewExplanation => 'Neue Erklärung';

  @override
  String get teacherSaveRecording => 'Aufnahme speichern';

  @override
  String get teacherTranscript => 'Transkript';

  @override
  String get teacherTranscriptHint =>
      'Transkript einfügen oder korrigieren. Automatische KI-Transkription benötigt einen konfigurierten, datenschutzkonformen Dienst.';

  @override
  String get teacherAudioPrivacy =>
      'Aufnahmen bleiben zunächst lokal auf diesem Gerät.';

  @override
  String get teacherStopRecording => 'Aufnahme stoppen';

  @override
  String get teacherStartRecording => 'Erklärung aufnehmen';

  @override
  String get teacherRecordings => 'Aufnahmen';

  @override
  String get teacherNoRecordings => 'Noch keine Erklärungen aufgenommen.';

  @override
  String get teacherTranscriptPending =>
      'Transkript ausstehend – antippen zum Bearbeiten';

  @override
  String get teacherWaitingForWritePermission =>
      'Nur ansehen – Schreibrecht beim Lehrer';

  @override
  String get teacherWritingAllowed => 'Du darfst an der Tafel schreiben';

  @override
  String get teacherWritingBlocked =>
      'Der Lehrer hat das Schreiben für dich gesperrt.';

  @override
  String get teacherSubmitOer => 'Als OER bei der Community einreichen';

  @override
  String get teacherSubmitOerHint =>
      'Der Eintrag wird erst nach Prüfung öffentlich sichtbar.';

  @override
  String get teacherOerSubmitted => 'Material zur Prüfung eingereicht.';

  @override
  String get teacherOerSignInRequired =>
      'Für die Community-Einreichung ist eine Anmeldung erforderlich.';

  @override
  String get teacherOerUploadUnavailable =>
      'Die Datei konnte nicht für den Upload gelesen werden.';

  @override
  String get teacherStartClassBeforeDistribute =>
      'Starte zuerst eine Live-Unterrichts-Session.';

  @override
  String get teacherDistributionSent =>
      'Download-Befehl an die Klasse gesendet.';

  @override
  String get teacherAllowFocusCheck => 'Fokus-Check zustimmen';

  @override
  String get description => 'Beschreibung';

  @override
  String get teacherLessonCalendar => 'Kalender';

  @override
  String get teacherLessonCalendarHint =>
      'Tippe einen Tag an, um Titel, Beschreibung und Anhänge für jede Stunde laut Stundenplan festzuhalten.';

  @override
  String get teacherNoSchoolDay =>
      'An diesem Tag gibt es keinen Unterricht im Stundenplan.';

  @override
  String get teacherNoLessonsForDay =>
      'Für diesen Tag sind im Stundenplan keine Stunden eingetragen.';

  @override
  String teacherPeriod(int n) {
    return '$n. Stunde';
  }

  @override
  String get teacherLessonAttachments => 'Anhänge';

  @override
  String teacherAttachmentCount(int count) {
    return '$count Anhänge';
  }

  @override
  String get teacherOpenWhiteboard => 'Tafel öffnen';

  @override
  String get teacherSaveLessonMaterials => 'Unterlagen sichern';

  @override
  String get teacherWhiteboardFinal => 'Tafel-Endstand';

  @override
  String get teacherNoWhiteboardToSave =>
      'Kein Whiteboard zum Sichern vorhanden.';

  @override
  String teacherSavedMaterialsLabel(String time) {
    return 'Unterlagen $time';
  }

  @override
  String get teacherMaterialsSavedToLesson =>
      'Unterlagen an die aktuelle Stunde angehängt.';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get enable => 'Aktivieren';

  @override
  String get teacherSubjectOrRoomRequired =>
      'Gib mindestens ein Fach oder einen Raum an.';

  @override
  String get classroomAutoConnectTitle => 'Nächstes Mal automatisch verbinden?';

  @override
  String classroomAutoConnectBody(String criteria) {
    return 'Notis kann beim nächsten Unterricht nach „$criteria“ suchen. Eine Verbindung wird nur aufgebaut, wenn Fach oder Raum übereinstimmt. Der Lehrer prüft diese Kriterien zusätzlich beim Handshake.';
  }

  @override
  String get classroomAutoConnectSetting =>
      'Automatisch mit Unterricht verbinden';

  @override
  String get classroomAutoConnectSettingHint =>
      'Verbindet nur, wenn mindestens das gespeicherte Fach oder der gespeicherte Raum mit der Lehrer-Session übereinstimmt.';

  @override
  String get classroomAutoConnectMismatch =>
      'Automatische Verbindung abgelehnt: Fach und Raum stimmen nicht überein.';

  @override
  String get marketplace => 'Marketplace';

  @override
  String get marketplaceHint =>
      'Optionale Funktionen mit Coins oder Werbung freischalten.';

  @override
  String get marketplaceComingSoon =>
      'Kauf und Freischaltung folgen in einem späteren Update.';

  @override
  String get marketplaceSoonBadge => 'Bald';

  @override
  String get marketplaceInkOcrHint =>
      'Handschrift und Fotos werden lokal erkannt und nur als unsichtbarer Suchindex gespeichert.';

  @override
  String get marketplaceCloudHint =>
      'Premium-Cloud-Relay, wenn kein P2P-Kanal in der Nähe ist.';

  @override
  String get featureCloudSync => 'Cloud-Sync';

  @override
  String get scanPages => 'Seiten scannen';

  @override
  String get scanPagesHint =>
      'System-Dokumentenscanner — Blätter werden zu Seiten.';

  @override
  String get scanExam => 'Klausur scannen?';

  @override
  String get scanExamBody =>
      'Die Klausur oder den Test jetzt abfotografieren und als Seiten ins Notizbuch legen.';

  @override
  String scannedNotebookTitle(String date) {
    return 'Scan $date';
  }

  @override
  String get scanFailed => 'Scanner konnte nicht geöffnet werden.';

  @override
  String scanAddedPages(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gescannte Seiten hinzugefügt',
      one: '1 gescannte Seite hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String get searchAtHint =>
      'Mit @ nur in einem Fach, Ordner oder Schuljahr suchen';

  @override
  String get pinTool => 'Anpinnen';

  @override
  String get calculator => 'Taschenrechner';

  @override
  String get calculatorHint => 'z. B. 2+3*4 oder sin(x)';

  @override
  String get calculatorEquals => '=';

  @override
  String get calculatorPlot => 'Funktion einfügen';

  @override
  String get calculatorHistory => 'Letzte Rechnungen';

  @override
  String get formulaBook => 'Tafelwerk';

  @override
  String get formulaTerm => 'Begriff';

  @override
  String get formulaValue => 'Formel / Wert';

  @override
  String get formulaAddRow => 'Zeile hinzufügen';

  @override
  String get continueAction => 'Weiter';

  @override
  String get setupStudentTitle => 'Dein Lernweg';

  @override
  String get setupStudentBody =>
      'Damit Notizen, Noten und das neue Halbjahr zu dir passen.';

  @override
  String get setupTeacherTitle => 'Dein Lehrerprofil';

  @override
  String get setupTeacherBody =>
      'Bist du noch im Studium oder schon im Schuldienst?';

  @override
  String get setupTeacherTrack => 'Status';

  @override
  String get teacherTrackStudying => 'Im Studium';

  @override
  String get teacherTrackStudyingHint =>
      'Semesterstart: neues Notizbuch, Kapitel nach Wahl übernehmen.';

  @override
  String get teacherTrackQualified => 'Schon fertig';

  @override
  String get teacherTrackQualifiedHint =>
      'Für den Unterricht — inkl. Teilen von Notizbüchern und Material.';

  @override
  String get newTermNotebook =>
      'Neues Notizbuch für dieses Halbjahr / Semester';

  @override
  String importChaptersBodyTerm(String title, String period) {
    return 'Welche Kapitel aus „$title“ sollen nach $period mitkommen?';
  }

  @override
  String termWinterHalbjahr(String year) {
    return '1. Halbjahr $year';
  }

  @override
  String termSummerHalbjahr(String year) {
    return '2. Halbjahr $year';
  }

  @override
  String termWinterSemester(String year) {
    return 'Wintersemester $year';
  }

  @override
  String termSummerSemester(String year) {
    return 'Sommersemester $year';
  }

  @override
  String get teacherShareContent => 'Inhalte teilen';

  @override
  String get teacherShareContentHint =>
      'Whiteboard, Notizbücher, Karteikarten oder Dateien an die Klasse senden.';

  @override
  String get teacherShareLiveBoard => 'Aktuelle Tafel senden';

  @override
  String get teacherShareNotebook => 'Notizbuch teilen';

  @override
  String get teacherShareFlashcards => 'Karteikarten teilen';

  @override
  String get tutorialOfferTitle => 'Kurzes Tutorial?';

  @override
  String get tutorialOfferBody =>
      'Wir zeigen dir die wichtigsten Stellen der App in ein paar Schritten.';

  @override
  String get tutorialStart => 'Tutorial starten';

  @override
  String get tutorialSkip => 'Jetzt nicht';

  @override
  String get tutorialNext => 'Weiter';

  @override
  String get tutorialDone => 'Fertig';

  @override
  String get tourLibraryTitle => 'Deine Bibliothek';

  @override
  String get tourLibraryBody =>
      'Hier liegen alle Notizbücher, Ordner und Karteikarten. Wische, um zu öffnen.';

  @override
  String get tourCreateTitle => 'Neu anlegen';

  @override
  String get tourCreateBody =>
      'Über Plus erstellst du Notizbücher, Ordner oder Karteikarten.';

  @override
  String get tourSearchTitle => 'Suche mit @';

  @override
  String get tourSearchBody =>
      'Tippe z. B. @Wirtschaft addition, um nur in einem Fach zu suchen.';

  @override
  String get tourSettingsTitle => 'Einstellungen';

  @override
  String get tourSettingsBody =>
      'Rolle, Bundesland, Stift-Gesten und das Tutorial findest du hier wieder.';

  @override
  String get tourTeacherTitle => 'Lehrerbereich';

  @override
  String get tourTeacherBody =>
      'Starte den Unterricht und teile Tafel, Notizbücher oder Material mit der Klasse.';

  @override
  String get tourEditorTitle => 'Im Notizbuch';

  @override
  String get tourEditorBody =>
      'Oben liegen Stift, Radierer, Taschenrechner und Tafelwerk. Seiten wischst du zur Seite.';

  @override
  String get teacherAssignments => 'Aufgaben';

  @override
  String get teacherAssignmentsHint =>
      'Arbeitsblätter und Tests im Editor anlegen. PDF-Scans werden in Aufgaben umgewandelt – bitte prüfen.';

  @override
  String teacherAssignmentCount(int count) {
    return '$count Einträge im Katalog';
  }

  @override
  String get teacherNewAssignment => 'Neue Aufgabe';

  @override
  String get teacherUntitledAssignment => 'Ohne Titel';

  @override
  String get teacherImportPdf => 'Aus PDF übernehmen';

  @override
  String get teacherImportPdfHint =>
      'Seiten werden gelesen und in bearbeitbare Aufgaben zerlegt.';

  @override
  String get teacherImportScan => 'Scannen und übernehmen';

  @override
  String get teacherImportScanHint =>
      'Foto oder Scanner, danach als Entwurf im Editor prüfen.';

  @override
  String get teacherImportedScanTitle => 'Scan';

  @override
  String get teacherReviewBanner =>
      'Text und Struktur stammen aus dem Scan. Bitte prüfen, anpassen und bestätigen, bevor du die Aufgabe einsetzt.';

  @override
  String get teacherConfirmDraft => 'Entwurf bestätigen';

  @override
  String get teacherNeedsReview => 'Bitte prüfen';

  @override
  String get teacherAnswerKind => 'Antwortart';

  @override
  String get teacherAnswerText => 'Freitext';

  @override
  String get teacherAnswerMc => 'Multiple Choice';

  @override
  String get teacherAnswerCalc => 'Rechnung';

  @override
  String get teacherAnswerMatch => 'Zuordnung';

  @override
  String get teacherTaskParts => 'Aufgabenteile';

  @override
  String get teacherAddPartText => 'Text';

  @override
  String get teacherAddPartImage => 'Bild';

  @override
  String get teacherAddPartLink => 'Link';

  @override
  String get teacherSampleAnswer => 'Musterlösung';

  @override
  String get teacherCalcResult => 'Endergebnis';

  @override
  String get teacherCalcTolerance => 'Toleranz';

  @override
  String get teacherMaxPoints => 'Punkte';

  @override
  String get teacherKindTask => 'Aufgabe';

  @override
  String get teacherKindTest => 'Test';

  @override
  String get teacherKindExam => 'Klausur';

  @override
  String get teacherCatalogKind => 'Art';

  @override
  String get teacherCatalogVisibility => 'Sichtbarkeit';

  @override
  String get teacherVisibilityPrivate => 'Nur ich';

  @override
  String get teacherVisibilitySchool => 'Nur Schule';

  @override
  String get teacherVisibilityPublic => 'Öffentlich';

  @override
  String get teacherSuggestedDuration => 'Vorschlag Dauer (Min.)';

  @override
  String get teacherNoAssignments =>
      'Noch keine Aufgaben. Lege eine an oder übernimm ein PDF bzw. einen Scan.';

  @override
  String get teacherImporting => 'Wird in den Editor umgewandelt…';

  @override
  String get teacherImportFailed => 'Umwandlung fehlgeschlagen';

  @override
  String get teacherAddTask => 'Aufgabe hinzufügen';

  @override
  String get teacherCorrectOption => 'Richtige Antwort markieren';

  @override
  String get teacherMatchLeft => 'Links';

  @override
  String get teacherMatchRight => 'Rechts';

  @override
  String get teacherDeleteTask => 'Aufgabe löschen';

  @override
  String get teacherTags => 'Schlagworte';

  @override
  String get teacherTasksHeading => 'Aufgaben';

  @override
  String teacherTaskNumber(int number) {
    return 'Aufgabe $number';
  }

  @override
  String teacherTaskCount(int count) {
    return '$count Aufgaben';
  }

  @override
  String get teacherSchool => 'Schule';

  @override
  String get teacherSchoolName => 'Schulname';

  @override
  String get teacherSchoolCode => 'Schul-Beitrittscode';

  @override
  String get assignmentTitle => 'Aufgabe';

  @override
  String get assignmentWaiting => 'Warte auf eine Aufgabe vom Lehrer.';

  @override
  String get assignmentSubmit => 'Fertig — abgeben';

  @override
  String get assignmentSubmitted =>
      'Abgegeben. Der Arbeitsbereich ist gesperrt.';

  @override
  String get assignmentLocked =>
      'Die Zeit ist abgelaufen. Warte auf eine Verlängerung oder das Einsammeln.';

  @override
  String get assignmentYourAnswer => 'Deine Antwort';

  @override
  String get assignmentImportNotebook => 'In ein Notizbuch übernehmen';

  @override
  String get assignmentStart => 'Aufgabe starten';

  @override
  String get assignmentStartHint =>
      'Wähle eine bestätigte Vorlage und sende sie als eigene Seite an die Klasse.';

  @override
  String get assignmentTestMode => 'Testmodus (Rechner und Tafelwerk sperren)';

  @override
  String get assignmentExtend5 => '+5 Minuten';

  @override
  String get assignmentExtend10 => '+10 Minuten';

  @override
  String get assignmentCollect => 'Einsammeln';

  @override
  String get assignmentAllowImport => 'Import erlauben';

  @override
  String get assignmentResults => 'Ergebnisse';

  @override
  String get assignmentPrint => 'Drucken ohne Lösung';

  @override
  String assignmentClassAverage(int percent) {
    return 'Klassenschnitt $percent %';
  }

  @override
  String assignmentSubmittedCount(int done, int total) {
    return 'Abgegeben: $done/$total';
  }

  @override
  String get assignmentTopProblems => 'Häufigste Probleme';

  @override
  String get assignmentNoProblems => 'Noch keine ausgewerteten Probleme.';

  @override
  String get assignmentGroups => 'Ähnliche Fehlerbilder';

  @override
  String get assignmentSubmissions => 'Abgaben';

  @override
  String get assignmentEarly => 'früh abgegeben';

  @override
  String get assignmentOnCollect => 'eingesammelt';

  @override
  String get assignmentCorrection => 'Korrektur an das Gerät senden';

  @override
  String get assignmentLeaveSignals => 'Verlassen / Fokus verloren';

  @override
  String get assignmentPoolLocked =>
      'Tauschbörse: Teile einmal öffentlich, um andere öffentliche Aufgaben zu sehen.';

  @override
  String get assignmentPoolUnlocked =>
      'Tauschbörse ist offen. Öffentliche Einträge anderer Lehrer erscheinen, sobald die Cloud verbunden ist.';
}
