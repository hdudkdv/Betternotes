// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Notis';

  @override
  String get newNotebook => 'New notebook';

  @override
  String get untitledNotebook => 'Untitled Notebook';

  @override
  String get title => 'Title';

  @override
  String get cover => 'Cover';

  @override
  String get template => 'Template';

  @override
  String get blank => 'Blank';

  @override
  String get lined => 'Lined';

  @override
  String get grid => 'Grid';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get settings => 'Settings';

  @override
  String get searchNotebooks => 'Search notebooks';

  @override
  String get globalSearch => 'Global search';

  @override
  String get noNotebooksYet => 'No notebooks yet';

  @override
  String get noNotebooksHint =>
      'Create one and start writing with your stylus.';

  @override
  String get deleteNotebookTitle => 'Delete notebook?';

  @override
  String deleteNotebookBody(String title) {
    return '\"$title\" will be removed permanently.';
  }

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get outline => 'Outline';

  @override
  String get outlineEmpty => 'Add chapters and subsections for deep structure.';

  @override
  String get pages => 'Pages';

  @override
  String get addPage => 'Add page';

  @override
  String get addSection => 'Add section';

  @override
  String get addSubchapter => 'Add subchapter';

  @override
  String get addParentChapter => 'Add higher-level chapter';

  @override
  String get nameChapterHint => 'Name this chapter…';

  @override
  String get nameSubchapterHint => 'Name this subchapter…';

  @override
  String get schoolClass => 'Class';

  @override
  String get schoolClassHint => 'Which class are you in?';

  @override
  String get schoolClassNone => 'Not set';

  @override
  String schoolClassValue(int n) {
    return 'Grade $n';
  }

  @override
  String get importFromPreviousClass => 'Import from previous class';

  @override
  String importFromClass(int n) {
    return 'Import from grade $n';
  }

  @override
  String get importChapterHint => 'Tap a chapter to add it here.';

  @override
  String get newSchoolYearNotebook => 'Create notebook for this school year';

  @override
  String get importChaptersTitle => 'Import chapters';

  @override
  String importChaptersBody(String title, int n) {
    return 'Which chapters from “$title” should carry over to grade $n?';
  }

  @override
  String get importChaptersEmpty =>
      'The previous notebook has no chapters yet.';

  @override
  String get selectAll => 'All';

  @override
  String get selectNone => 'None';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get tapToContinue => 'Tap to continue';

  @override
  String get pen => 'Pen';

  @override
  String get ballpointPen => 'Ballpoint';

  @override
  String get pencil => 'Pencil';

  @override
  String get fountainPen => 'Fountain pen';

  @override
  String get pressureSensitivity => 'Pressure';

  @override
  String get marker => 'Marker';

  @override
  String get textTool => 'Text';

  @override
  String get eraser => 'Eraser';

  @override
  String get lasso => 'Lasso';

  @override
  String get addTextBox => 'Add text box';

  @override
  String get paperCreator => 'Paper creator';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get deleteSelection => 'Delete selection';

  @override
  String get writing => 'Writing';

  @override
  String get fingerPanZoom => 'Stylus only (finger pans)';

  @override
  String get fingerPanZoomHint => 'On: stylus draws, finger pans.';

  @override
  String get defaultTemplate => 'Default template';

  @override
  String get language => 'Language';

  @override
  String get german => 'German';

  @override
  String get english => 'English';

  @override
  String get systemLanguage => 'System';

  @override
  String get sync => 'Sync';

  @override
  String get syncUpToDate => 'Up to date';

  @override
  String get syncQueueEmpty => 'Queue empty · offline-first local sync';

  @override
  String syncPending(int count) {
    return '$count pending ops';
  }

  @override
  String get flushSync => 'Flush sync queue';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'Notis — Smart Text, Custom Paper, Deep Outline, global search, and offline-first sync queue.';

  @override
  String get searchHint => 'Search or @Subject @Grade10 …';

  @override
  String get searchEmpty => 'Type to search across all notes.';

  @override
  String get crossLink => 'Cross-link';

  @override
  String get linkToNotebook => 'Link to notebook';

  @override
  String get crossLinkCreated => 'Cross-link created';

  @override
  String get needAnotherNotebook => 'Create another notebook to link.';

  @override
  String get importPdf => 'Import PDF';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String pageOf(int current, int total) {
    return 'Page $current/$total';
  }

  @override
  String get infiniteCanvas => 'Infinite canvas';

  @override
  String get pageMode => 'Page mode';

  @override
  String get addTag => 'Add tag';

  @override
  String get add => 'Add';

  @override
  String get formatText => 'Format text';

  @override
  String get bold => 'Bold';

  @override
  String get italic => 'Italic';

  @override
  String get free => 'Free';

  @override
  String get close => 'Close';

  @override
  String get apply => 'Apply';

  @override
  String get renameSection => 'Rename section';

  @override
  String get indent => 'Indent';

  @override
  String get outdent => 'Outdent';

  @override
  String chapter(int n) {
    return 'Chapter $n';
  }

  @override
  String get section => 'Section';

  @override
  String get newText => 'New text';

  @override
  String get style => 'Style';

  @override
  String get background => 'Background';

  @override
  String get lineSpacing => 'Line spacing';

  @override
  String get gridSize => 'Grid size';

  @override
  String get leftMargin => 'Left margin';

  @override
  String get topMargin => 'Top margin';

  @override
  String get myPaper => 'My paper';

  @override
  String get shapes => 'Shapes';

  @override
  String get ruler => 'Ruler';

  @override
  String get compass => 'Compass';

  @override
  String get fixGuide => 'Pin';

  @override
  String get guideFixed => 'Pinned';

  @override
  String get compassSetCenter => 'Tap to set center';

  @override
  String get compassRadius => 'Radius';

  @override
  String get strokeStyleSolid => 'Solid';

  @override
  String get strokeStyleDashed => 'Dashed';

  @override
  String get strokeStyleDotted => 'Dotted';

  @override
  String get strokeStyleDashDot => 'Dash-dot';

  @override
  String get rulerHint => 'Drag for a straight line (snaps every 15°)';

  @override
  String get compassHint => 'Center → drag for radius';

  @override
  String get shapeLine => 'Line';

  @override
  String get shapeRect => 'Rectangle';

  @override
  String get shapeEllipse => 'Ellipse';

  @override
  String get shapeArrow => 'Arrow';

  @override
  String get insertImage => 'Insert image';

  @override
  String get readMode => 'Read mode';

  @override
  String get editMode => 'Edit mode';

  @override
  String get libraryHome => 'Library';

  @override
  String get freeTextBox => 'Free box';

  @override
  String get pageText => 'Page text';

  @override
  String get newFolder => 'New folder';

  @override
  String get folder => 'Folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get folders => 'Folders';

  @override
  String get notebooks => 'Notebooks';

  @override
  String get chapters => 'Chapters';

  @override
  String get entries => 'Entries';

  @override
  String get flashcards => 'Flashcards';

  @override
  String get newFlashcardDeck => 'New flashcard deck';

  @override
  String get untitledDeck => 'Untitled deck';

  @override
  String get newFlashcard => 'New flashcard';

  @override
  String get flashcardFront => 'Front';

  @override
  String get flashcardBack => 'Back';

  @override
  String get noFlashcardsYet => 'No flashcards yet';

  @override
  String get tapToFlip => 'Tap to flip';

  @override
  String get searchEverything => 'Search or @Economics addition …';

  @override
  String get shareExport => 'Share & export';

  @override
  String get printPdf => 'Print / PDF preview';

  @override
  String get printPdfHint => 'Open the system print dialog';

  @override
  String get sharePdf => 'Share notebook as PDF';

  @override
  String get sharePdfHint => 'Entire notebook';

  @override
  String get shareCurrentPage => 'Share current page';

  @override
  String get shareCurrentPageHint => 'Only this page as PDF';

  @override
  String get documentType => 'Document type';

  @override
  String get paperSize => 'Paper size';

  @override
  String get pageOrientation => 'Orientation';

  @override
  String get portrait => 'Portrait';

  @override
  String get landscape => 'Landscape';

  @override
  String get paperLetter => 'Letter';

  @override
  String get paperLegal => 'Legal';

  @override
  String get paperTabloid => 'Tabloid';

  @override
  String get newPagesOnlyHint => 'Only applies to pages added from now on.';

  @override
  String get choosePastEvent => 'Choose a past event';

  @override
  String get repeatEvent => 'Repeat event';

  @override
  String get repeatFrequency => 'Repeat';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get repeatUntil => 'Repeat until';

  @override
  String get repeatInterval => 'Interval';

  @override
  String repeatEvery(int count) {
    return 'Every $count';
  }

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get importedPageTemplateTitle => 'Imported template';

  @override
  String get importedPageTemplateBody =>
      'The previous page uses an image or PDF background. Which template should the new page use?';

  @override
  String get keepCurrentTemplate => 'Keep current template';

  @override
  String get useNotebookDefault => 'Use notebook default';

  @override
  String get documentTypeFixedHint =>
      'Chosen when the document is created and stays that way';

  @override
  String get infiniteDocument => 'Infinite document';

  @override
  String get infiniteDocumentHint =>
      'One large canvas with free zoom. Only the visible area is rendered.';

  @override
  String get eraserStroke => 'Stroke';

  @override
  String get eraserSection => 'Section';

  @override
  String get eraserPrecise => 'Precise';

  @override
  String get editWidth => 'Adjust stroke width';

  @override
  String get editWidthHint => 'Tap to select · Long-press to edit';

  @override
  String get addColor => 'Add color';

  @override
  String get removeColor => 'Remove color';

  @override
  String get hue => 'Hue';

  @override
  String get saturation => 'Saturation';

  @override
  String get brightness => 'Brightness';

  @override
  String get colorPickerTitle => 'Pick a color';

  @override
  String get opacity => 'Opacity';

  @override
  String get recentColors => 'Recently used';

  @override
  String get presetColors => 'Suggestions';

  @override
  String get customColor => 'Custom color';

  @override
  String get editColorHint => 'Tap: select · Hold: edit';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceHint => 'Look and light/dark mode of the app';

  @override
  String get lookStudio => 'Studio';

  @override
  String get lookStudioHint => 'Graphite with an indigo accent';

  @override
  String get lookPaper => 'Paper';

  @override
  String get lookPaperHint => 'Cream, deep green, serif';

  @override
  String get lookFresh => 'Fresh';

  @override
  String get lookFreshHint => 'White, teal, airy';

  @override
  String get lookMono => 'Mono';

  @override
  String get lookMonoHint => 'Black and white, minimal';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get moreOptions => 'More options';

  @override
  String get menuPageGroup => 'Page';

  @override
  String get menuViewGroup => 'View';

  @override
  String get menuDocumentGroup => 'Document';

  @override
  String get menuPaperGroup => 'Paper of this page';

  @override
  String get paperPresets => 'Templates';

  @override
  String get paperPresetsHint =>
      'Tap to apply · Long-press custom templates to delete';

  @override
  String get paperPreview => 'Preview';

  @override
  String get paperColor => 'Paper color';

  @override
  String get lineColor => 'Line color';

  @override
  String get applyPaper => 'Apply to page';

  @override
  String get resetDefaults => 'Reset';

  @override
  String get blankPaperHint => 'Blank paper — adjust color and name only.';

  @override
  String get editingBuiltinHint =>
      'Built-in template — saving creates your own copy.';

  @override
  String get collegeRuled => 'College';

  @override
  String get narrowRuled => 'Narrow ruled';

  @override
  String get dotGrid => 'Fine grid';

  @override
  String get pageBrowseMode => 'Page browsing';

  @override
  String get pageBrowseModeHint =>
      'Swipe: page by page left/right. Scroll: all pages in one vertical stack.';

  @override
  String get browseSwipe => 'Swipe';

  @override
  String get browseScroll => 'Scroll';

  @override
  String get gesturesSection => 'Gestures';

  @override
  String get gesturesSectionHint =>
      'Map Apple Pencil and multi-touch shortcuts.';

  @override
  String get gesturePencilDoubleTap => 'Pencil double-tap';

  @override
  String get gesturePencilSqueeze => 'Pencil squeeze';

  @override
  String get gestureTwoFingerTap => 'Two-finger tap';

  @override
  String get gestureThreeFingerSwipeLeft => 'Three-finger swipe left';

  @override
  String get gestureThreeFingerSwipeRight => 'Three-finger swipe right';

  @override
  String get gestureActionNone => 'Do nothing';

  @override
  String get gestureActionToggleEraser => 'Pen / eraser';

  @override
  String get gestureActionPreviousTool => 'Previous tool';

  @override
  String get gestureActionOpenToolWheel => 'Open tool wheel';

  @override
  String get gestureActionUndo => 'Undo';

  @override
  String get gestureActionRedo => 'Redo';

  @override
  String get gestureActionNextPage => 'Next page';

  @override
  String get gestureActionPreviousPage => 'Previous page';

  @override
  String get gestureActionExportPage => 'Export page';

  @override
  String get gestureActionCyclePenColor => 'Cycle pen color';

  @override
  String get gestureActionFitZoom => 'Fit page';

  @override
  String get gestureActionGoBack => 'Go back';

  @override
  String pdfImportProgress(int done, int total) {
    return 'Importing PDF… $done/$total';
  }

  @override
  String get savePageAsTemplate => 'Save page as template';

  @override
  String get savePageAsTemplateHint =>
      'Save a reusable page design — with or without lines.';

  @override
  String get lineLayout => 'Lines';

  @override
  String get noLines => 'None';

  @override
  String get fromPage => 'From page';

  @override
  String get customLines => 'Custom';

  @override
  String get customLinesHint =>
      'Tap to add/remove lines. Tap left area to set the margin.';

  @override
  String get fillRuled => 'Fill ruled';

  @override
  String get clearLines => 'Clear lines';

  @override
  String get templateSaved => 'Template saved';

  @override
  String get timetable => 'Timetable';

  @override
  String get timetableHint =>
      'Tap a cell to fill lessons. Tap times on the left (scroll wheels). Blocks can be full or split. Link subjects to folders.';

  @override
  String get timetableEmptyToday => 'Nothing for today yet — tap to fill in';

  @override
  String timetableTodayPreview(String preview) {
    return 'Today: $preview';
  }

  @override
  String get subject => 'Subject';

  @override
  String get subjectHint => 'e.g. English';

  @override
  String get room => 'Room';

  @override
  String get roomHint => 'e.g. R204';

  @override
  String get color => 'Color';

  @override
  String get clear => 'Clear';

  @override
  String get editPeriod => 'Edit period';

  @override
  String get periodLabel => 'Label';

  @override
  String get periodStart => 'Start';

  @override
  String get periodEnd => 'End';

  @override
  String get addPeriod => 'Add period';

  @override
  String get removePeriod => 'Remove last period';

  @override
  String get mondayShort => 'Mon';

  @override
  String get tuesdayShort => 'Tue';

  @override
  String get wednesdayShort => 'Wed';

  @override
  String get thursdayShort => 'Thu';

  @override
  String get fridayShort => 'Fri';

  @override
  String lastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String get blockMode => 'Block';

  @override
  String get fullBlock => 'Full block';

  @override
  String get splitBlock => 'Split';

  @override
  String fullBlockHint(int minutes) {
    return 'One subject for the whole block ($minutes min).';
  }

  @override
  String splitBlockHint(String first, String second) {
    return 'Split: $first · then $second';
  }

  @override
  String get firstHalf => '1st half';

  @override
  String get secondHalf => '2nd half';

  @override
  String get linkFolder => 'Link to folder';

  @override
  String get noFolderLink => 'No folder';

  @override
  String blockDuration(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get nowOn => 'Now';

  @override
  String nowLesson(String subject, String when) {
    return 'Now: $subject ($when)';
  }

  @override
  String nowLessonShort(String subject) {
    return 'Now: $subject';
  }

  @override
  String get newInfiniteDocument => 'Endless document';

  @override
  String get untitledInfinite => 'Endless canvas';

  @override
  String get pageModeHint => 'Classic pages you can flip through';

  @override
  String get infiniteDocumentShortHint => 'Huge board, extreme zoom in and out';

  @override
  String get markFavorite => 'Mark as favorite';

  @override
  String get editFolder => 'Edit folder';

  @override
  String get deleteFolderTitle => 'Delete folder?';

  @override
  String deleteFolderBody(String name) {
    return '\"$name\" will be removed. Notebooks inside stay available in the library root.';
  }

  @override
  String get folderActions => 'Folder';

  @override
  String get folderIcon => 'Icon';

  @override
  String get newFolderHint => 'Pick a color and icon';

  @override
  String get newNotebookHint => 'Paged notebook with cover and template';

  @override
  String get newDeckHint => 'Flashcards with a custom color';

  @override
  String get planner => 'Grades & calendar';

  @override
  String get plannerEmptyHint => 'Add appointments and grades';

  @override
  String get calendar => 'Calendar';

  @override
  String get grades => 'Grades';

  @override
  String get addAppointment => 'Event';

  @override
  String get editAppointment => 'Edit event';

  @override
  String get addGrade => 'Grade';

  @override
  String get editGrade => 'Edit grade';

  @override
  String appointmentsOnDay(String day) {
    return 'Events on $day';
  }

  @override
  String get noAppointmentsYet => 'No events on this day yet.';

  @override
  String get noGradesYet => 'No grades yet — pick a subject and add one.';

  @override
  String get gradeAverage => 'Average (weighted)';

  @override
  String gradeAverageShort(String value) {
    return 'Avg $value';
  }

  @override
  String get gradeTitle => 'Title';

  @override
  String get gradeTitleHint => 'e.g. Midterm 2';

  @override
  String get gradeValue => 'Grade / value';

  @override
  String get gradeWeight => 'Weight';

  @override
  String get scaleGerman => '1–6';

  @override
  String get scalePercent => '%';

  @override
  String get scalePoints => 'Points';

  @override
  String get kindAppointment => 'Event';

  @override
  String get kindExam => 'Exam';

  @override
  String get kindHomework => 'Homework';

  @override
  String get startsAt => 'Starts';

  @override
  String get endsAt => 'Ends';

  @override
  String get optional => 'Optional';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get saturdayShort => 'Sat';

  @override
  String get sundayShort => 'Sun';

  @override
  String get shareAppointment => 'Forward appointment';

  @override
  String get shareAppointmentHint =>
      'Copy text into chat or mail. ICS works with calendar apps.';

  @override
  String get copyForForward => 'Copy text';

  @override
  String get copiedForForward => 'Copied — ready to forward';

  @override
  String get copyIcs => 'Copy as calendar (.ics)';

  @override
  String get icsCopied => 'ICS text copied';

  @override
  String get schoolSection => 'School & studies';

  @override
  String get educationLevel => 'Education level';

  @override
  String get educationLevelHint => 'Grade scale and labels.';

  @override
  String get eduSek1 => 'Lower sec.';

  @override
  String get eduSek2 => 'Upper sec.';

  @override
  String get eduUniversity => 'University';

  @override
  String get eduScaleGradesHint => 'Calculated with grades (1–6).';

  @override
  String get eduScalePointsHint => 'Calculated with points.';

  @override
  String get eduScaleSek1Hint =>
      'Grades 1–6 · half-years · written/oral weighting.';

  @override
  String get eduScaleSek2Hint =>
      '0–15 points · Q1–Q4 + exams · 900-point projection.';

  @override
  String get eduScaleUniHint => 'Grades 1.0–5.0 · ECTS-weighted GPA.';

  @override
  String get gradeKindWritten => 'Written';

  @override
  String get gradeKindOral => 'Oral';

  @override
  String get gradeKindOtherParticipation => 'Other participation';

  @override
  String get gradeKindKlassenarbeit => 'Class test';

  @override
  String get periodH1 => '1st half-year';

  @override
  String get periodH2 => '2nd half-year';

  @override
  String get periodQ1 => 'Q1';

  @override
  String get periodQ2 => 'Q2';

  @override
  String get periodQ3 => 'Q3';

  @override
  String get periodQ4 => 'Q4';

  @override
  String get periodAbiExam => 'Final exams';

  @override
  String get periodSemester => 'Semester';

  @override
  String get abiPrognosisTitle => 'Abitur projection';

  @override
  String abiProjectedPoints(String points) {
    return 'Projection: $points / 900';
  }

  @override
  String abiProjectedNote(String note) {
    return 'Projected grade: $note';
  }

  @override
  String abiMinPassProgress(String have, String need) {
    return 'Minimum points: $have / $need';
  }

  @override
  String abiBlockProgress(int blocks, String avg) {
    return 'After $blocks/5 blocks · avg $avg points';
  }

  @override
  String get uniPrognosisTitle => 'Study progress';

  @override
  String uniGpa(String gpa) {
    return 'ECTS GPA: $gpa';
  }

  @override
  String uniEctsProgress(String have, String need) {
    return '$have / $need ECTS';
  }

  @override
  String get ectsLabel => 'ECTS';

  @override
  String get semesterLabelField => 'Semester (e.g. WiSe 25/26)';

  @override
  String get markAbiSubject => 'Abitur subject (for exam projection)';

  @override
  String get targetEcts => 'Target ECTS';

  @override
  String get targetEctsHint => 'Credit points required for graduation.';

  @override
  String get abiProjectionSettings => 'Abitur projection';

  @override
  String get abiProjectionHint =>
      'Course count (block I) and exams (block II).';

  @override
  String get abiCourseCount => 'Courses in block I';

  @override
  String get abiExams4 => '4 exams';

  @override
  String get abiExams5 => '5 exams';

  @override
  String roundedPoints(String points) {
    return 'Rounded: $points pts';
  }

  @override
  String get gradeValueUni => 'Grade (1.0–5.0)';

  @override
  String get gradeValuePoints15 => 'Points (0–15)';

  @override
  String get gradeTendency => 'Tendency';

  @override
  String get gradeTendencyNone => 'plain';

  @override
  String selectedGrade(String grade) {
    return 'Selected: $grade';
  }

  @override
  String get archivedGradesTitle => 'Other levels (archive)';

  @override
  String get archivedGradesHint =>
      'Grades from lower/upper secondary or uni stay saved — listed here.';

  @override
  String editingArchivedGrade(String level) {
    return 'Archived grade ($level)';
  }

  @override
  String get scanAttachment => 'Scan worksheet';

  @override
  String get scanAttachmentHint =>
      'Attach a photo/scan of a test or exam to this grade.';

  @override
  String get scanAdd => 'Add scan';

  @override
  String get scanWithCamera => 'Camera';

  @override
  String get scanFromGallery => 'Gallery / file';

  @override
  String scanPage(int n) {
    return 'Scan $n';
  }

  @override
  String scanCount(int count) {
    return '$count scans';
  }

  @override
  String get gradesSectionsHint => 'Grades stay when you switch levels.';

  @override
  String get schoolYear => 'School year';

  @override
  String get previousSchoolYear => 'Previous year';

  @override
  String get nextSchoolYear => 'Next year';

  @override
  String gradesEmptyYear(String year) {
    return 'No grades in $year yet.';
  }

  @override
  String get gradeDetails => 'Grade';

  @override
  String get viewMode => 'View';

  @override
  String get noScansAttached => 'No scan attached.';

  @override
  String get semesterShort => 'Semester';

  @override
  String get federalState => 'Federal state';

  @override
  String get federalStateHint =>
      'Used to show school holidays in the calendar.';

  @override
  String get stateBw => 'Baden-Württemberg';

  @override
  String get stateBy => 'Bavaria';

  @override
  String get stateBe => 'Berlin';

  @override
  String get stateBb => 'Brandenburg';

  @override
  String get stateHb => 'Bremen';

  @override
  String get stateHh => 'Hamburg';

  @override
  String get stateHe => 'Hesse';

  @override
  String get stateMv => 'Mecklenburg-Western Pomerania';

  @override
  String get stateNi => 'Lower Saxony';

  @override
  String get stateNw => 'North Rhine-Westphalia';

  @override
  String get stateRp => 'Rhineland-Palatinate';

  @override
  String get stateSl => 'Saarland';

  @override
  String get stateSn => 'Saxony';

  @override
  String get stateSt => 'Saxony-Anhalt';

  @override
  String get stateSh => 'Schleswig-Holstein';

  @override
  String get stateTh => 'Thuringia';

  @override
  String get holidayAutumn => 'Autumn break';

  @override
  String get holidayChristmas => 'Christmas break';

  @override
  String get holidayWinter => 'Winter break';

  @override
  String get holidayEaster => 'Easter break';

  @override
  String get holidayPentecost => 'Pentecost break';

  @override
  String get holidaySummer => 'Summer break';

  @override
  String holidaysForState(String state) {
    return 'Holidays: $state';
  }

  @override
  String holidayBanner(String name) {
    return 'Holiday: $name';
  }

  @override
  String get gradeKindKlausur => 'Exam';

  @override
  String get gradeKindTest => 'Test';

  @override
  String get gradeKindUniExam => 'Exam';

  @override
  String get gradeKindHomework => 'Coursework';

  @override
  String get subjectFromTimetableDay => 'Subject from timetable (this weekday)';

  @override
  String get subjectFromTimetableWeekend => 'Weekend — no timetable day';

  @override
  String get noSubjectsThatDay => 'No subjects on the timetable for this day.';

  @override
  String get gradesNeedTimetable => 'Add subjects in the timetable first.';

  @override
  String weightForSubject(String subject) {
    return 'Weighting: $subject';
  }

  @override
  String weightHint(String major, String minor) {
    return 'Set $major vs $minor once — Notan-style.';
  }

  @override
  String weightSummary(String major, int majorPct, String minor, int minorPct) {
    return '$major $majorPct% · $minor $minorPct%';
  }

  @override
  String get setWeight => 'Weighting';

  @override
  String gradeCount(int count) {
    return '$count grades';
  }

  @override
  String get gradeValuePoints => 'Points';

  @override
  String get sectionGeneral => 'General';

  @override
  String get sectionSubscription => 'Plan & coins';

  @override
  String get upgradeToNotisPro => 'Get Notis Pro';

  @override
  String get upgradeToNotisProHint =>
      'Monthly, yearly, or lifetime — managed through RevenueCat.';

  @override
  String get notisProActive => 'Notis Pro is active';

  @override
  String get notisProInactive => 'Free plan';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get manageSubscriptionHint =>
      'Cancel, restore, or contact support in Customer Center.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restorePurchasesSuccess => 'Notis Pro was restored.';

  @override
  String get restorePurchasesEmpty => 'No active purchase found.';

  @override
  String get purchaseCancelled => 'Purchase cancelled.';

  @override
  String purchaseFailed(String message) {
    return 'Purchase failed: $message';
  }

  @override
  String get paywallUnavailable =>
      'The paywall is not available on this device.';

  @override
  String get sectionSupport => 'Support';

  @override
  String get sectionSyncPreview => 'Sync (preview)';

  @override
  String get localTierHint => 'Local testing only — no real purchases.';

  @override
  String get tierFree => 'Free';

  @override
  String get tierPro => 'Pro';

  @override
  String get tierProPlus => 'Pro+';

  @override
  String get tierTeacher => 'Teacher';

  @override
  String coinsBalance(int count) {
    return '$count coins';
  }

  @override
  String get watchAdForCoins => 'Watch ad';

  @override
  String get watchRewardedAd => 'Watch short video';

  @override
  String get rewardedAdDemoBadge => 'Demo — not a real ad';

  @override
  String get rewardedAdTitle => 'Unlock reward';

  @override
  String rewardedAdCoinsBody(int count) {
    return 'After the demo clip you’ll get $count coins.';
  }

  @override
  String get rewardedAdFeatureBody =>
      'After the demo clip this feature will unlock.';

  @override
  String get adPrivacyOptions => 'Ad settings';

  @override
  String get adPrivacyOptionsHint => 'Change your consent for personalised ads';

  @override
  String get rewardedAdLoading => 'Loading ad …';

  @override
  String get rewardedAdNotFinished =>
      'Video was not watched to the end — no reward.';

  @override
  String get featureUnlocked => 'Feature unlocked';

  @override
  String get collaborationSignInRequired => 'Sign in for cloud collaboration.';

  @override
  String get collaborationUpgradeRequired =>
      'Cloud collaboration requires an eligible plan.';

  @override
  String get collabLocalTitle => 'Nearby (no account)';

  @override
  String get collabLocalBody =>
      'Share this notebook over Wi‑Fi or a hotspot. Works completely offline — no sign-in needed.';

  @override
  String get collabCloudTitle => 'Cloud collaboration';

  @override
  String get collabCloudBody =>
      'Invite someone by Firebase UID. Role controls whether they can edit or only read.';

  @override
  String get collabMemberUid => 'Firebase UID';

  @override
  String get collabRole => 'Role';

  @override
  String get collabSaveInvite => 'Save invitation';

  @override
  String get collabMembers => 'Members';

  @override
  String get collabStartLive => 'Start live session';

  @override
  String collabLiveStarted(String id) {
    return 'Live session started: $id';
  }

  @override
  String get collabComments => 'Comments';

  @override
  String get collabLeaveComment => 'Leave a comment';

  @override
  String get signIn => 'Sign in';

  @override
  String coinsEarned(int count) {
    return '+$count coins';
  }

  @override
  String get notEnoughCoins => 'Not enough coins';

  @override
  String unlockWithCoins(int count) {
    return 'Unlock with $count coins';
  }

  @override
  String get featureAvailable => 'Unlocked';

  @override
  String get featurePremiumPaper => 'Premium paper';

  @override
  String get featurePremiumCover => 'Premium cover';

  @override
  String get featureAudioTranscription => 'Audio transcription';

  @override
  String get featurePdfCompress => 'Compress PDF';

  @override
  String get featureHandwritingOcr => 'Handwriting OCR';

  @override
  String get featureNoForcedAds => 'No forced ads';

  @override
  String get featureSessionCollab => 'Session collab';

  @override
  String get featureAsyncCollab => 'Cloud collab';

  @override
  String get featureWhiteboard => 'Teacher whiteboard';

  @override
  String get supportBody =>
      'Notis stays usable offline. A coffee helps cover future server costs.';

  @override
  String get supportBuyCoffee => 'Buy a coffee';

  @override
  String get supportLinkCopied => 'Support link copied';

  @override
  String serverCostsLabel(int euro) {
    return 'Server costs (placeholder): €$euro / month';
  }

  @override
  String serverCostsCovered(int euro) {
    return 'Covered so far: €$euro';
  }

  @override
  String get syncPreviewHint => 'Preview — real cloud sync comes later.';

  @override
  String get upcomingNext => 'Up next';

  @override
  String get createGradeFromExam => 'Add a grade?';

  @override
  String get createGradeFromExamBody =>
      'Save the exam and prepare a grade with subject and date filled in.';

  @override
  String get deviceCalendarComingSoon =>
      'Device calendar sync is coming later.';

  @override
  String get sectionNotebooks => 'Notebooks';

  @override
  String get exportExtras => 'Export extras';

  @override
  String get comingSoonGate => 'Coming later — unlockable locally for now';

  @override
  String get firebaseSetupRequired =>
      'Firebase has not been configured yet. Local data remains available.';

  @override
  String get cloudAccount => 'Cloud account';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get signInApple => 'Sign in with Apple';

  @override
  String get signOut => 'Sign out';

  @override
  String get cloudSyncOffline =>
      'Offline-first: without signing in, data stays on this device.';

  @override
  String cloudSyncError(String message) {
    return 'Sign-in failed: $message';
  }

  @override
  String get developerTools => 'Developer tools';

  @override
  String get developerTierHint =>
      'For local testing only — does not replace a store purchase.';

  @override
  String get editSupportDetails => 'Edit support details';

  @override
  String get supportUrl => 'Support link';

  @override
  String get serverCosts => 'Monthly server costs';

  @override
  String get amountCovered => 'Covered so far';

  @override
  String get syncStatusIdle => 'Ready';

  @override
  String get syncStatusUpToDate => 'Up to date';

  @override
  String get syncStatusSyncing => 'Syncing';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusFirebaseNotConfigured => 'Firebase is not configured';

  @override
  String get syncStatusAuthenticationRequired => 'Sign-in required';

  @override
  String get syncStatusPreparingCloud => 'Preparing cloud data';

  @override
  String get syncStatusPaused => 'Sync paused';

  @override
  String get lockPage => 'Lock page';

  @override
  String get unlockPage => 'Unlock page';

  @override
  String get pageLocked => 'Page locked';

  @override
  String get presentView => 'Present';

  @override
  String get exitPresentView => 'Exit presentation';

  @override
  String get exitPresentViewHint => 'Double tap to exit the presentation';

  @override
  String get dragToAddPage => 'Drag to add a page';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get fitPage => 'Fit page';

  @override
  String get deselectTool => 'Deselect tool';

  @override
  String get pageSidebar => 'Page overview';

  @override
  String get duplicatePage => 'Duplicate page';

  @override
  String get deletePage => 'Delete page';

  @override
  String get lastPageHint => 'A notebook needs at least one page.';

  @override
  String get collaborate => 'Collaborate';

  @override
  String get scrollDirection => 'Scrolling direction';

  @override
  String get underline => 'Underline';

  @override
  String get strikethrough => 'Strikethrough';

  @override
  String get increaseFontSize => 'Increase font size';

  @override
  String get decreaseFontSize => 'Decrease font size';

  @override
  String get alignLeft => 'Align left';

  @override
  String get alignCenter => 'Align center';

  @override
  String get alignRight => 'Align right';

  @override
  String get alignJustify => 'Justify';

  @override
  String get deleteTextBlock => 'Delete text box';

  @override
  String get moveTextBlock => 'Move text box';

  @override
  String get studyMode => 'Study';

  @override
  String get studyModeHint =>
      'Ink is hidden — double-tap or use Reveal to show it';

  @override
  String get exitStudyMode => 'Exit study mode';

  @override
  String get revealInk => 'Reveal ink';

  @override
  String get hideInk => 'Hide ink';

  @override
  String get saveSnapshot => 'Save snapshot';

  @override
  String get restoreSnapshot => 'Restore snapshot';

  @override
  String get snapshotSaved => 'Snapshot saved';

  @override
  String get snapshotRestored => 'Snapshot restored';

  @override
  String get noSnapshotsYet => 'No snapshots for this page yet';

  @override
  String snapshotLabel(String time) {
    return 'Version $time';
  }

  @override
  String get deleteSnapshot => 'Delete snapshot';

  @override
  String get confirmRestoreSnapshot =>
      'Restore this snapshot? Current page content will be replaced.';

  @override
  String get nearbySyncTitle => 'Nearby sync';

  @override
  String get nearbySyncIntro =>
      'Share this notebook over the same Wi‑Fi or a phone hotspot. The first transfer sends the whole notebook; afterwards only changes are exchanged — no internet required.';

  @override
  String get nearbySyncDeviceName => 'Device name';

  @override
  String get nearbySyncHostSection => 'Host this notebook';

  @override
  String get nearbySyncHostHint =>
      'Start hosting, then tell the other device your IP address and session code. Both devices must be on the same network or hotspot.';

  @override
  String get nearbySyncStartHost => 'Start nearby session';

  @override
  String get nearbySyncJoinSection => 'Join a session';

  @override
  String get nearbySyncJoinHint =>
      'Enter the host IP and the 6-character code shown on the other device.';

  @override
  String get nearbySyncHostAddress => 'Host IP address';

  @override
  String get nearbySyncCode => 'Session code';

  @override
  String get nearbySyncJoin => 'Join';

  @override
  String get nearbySyncStop => 'Stop session';

  @override
  String get nearbySyncCopy => 'Copy';

  @override
  String get nearbySyncCopied => 'Copied';

  @override
  String nearbySyncPort(int port) {
    return 'Port $port';
  }

  @override
  String get nearbySyncNoAddress =>
      'No local IP found yet. Connect to Wi‑Fi or enable a hotspot, then reopen this screen.';

  @override
  String get nearbySyncStatusIdle => 'No nearby session';

  @override
  String get nearbySyncStatusHosting => 'Waiting for devices…';

  @override
  String get nearbySyncStatusConnecting => 'Connecting…';

  @override
  String get nearbySyncStatusSyncing => 'Transferring notebook…';

  @override
  String get nearbySyncStatusConnected => 'Nearby sync active';

  @override
  String get nearbySyncStatusError => 'Nearby sync error';

  @override
  String nearbySyncPeer(String name) {
    return 'Peer: $name';
  }

  @override
  String nearbySyncPeers(int count) {
    return '$count connected';
  }

  @override
  String get nearbySyncSnapshotReceived => 'Notebook received — opening…';

  @override
  String get nearbySyncWebUnsupported =>
      'Nearby sync needs the Android or iOS app.';

  @override
  String get nearbySyncDisconnected => 'The other device disconnected.';

  @override
  String get nearbySyncInvalidCode => 'Wrong session code.';

  @override
  String get nearbySyncError => 'Nearby sync failed';

  @override
  String get nearbySyncBinaryNote =>
      'PDF backgrounds and inserted images are transferred over the air with the notebook. Both devices must stay on the same Wi‑Fi or hotspot.';

  @override
  String get nearbySyncDiscoverHint =>
      'Devices hosting a nearby session appear automatically. Tap one to join.';

  @override
  String get nearbySyncSearching => 'Searching on this network…';

  @override
  String get nearbySyncSearchStopped => 'Search paused';

  @override
  String get nearbySyncStartSearch => 'Search';

  @override
  String get nearbySyncStopSearch => 'Pause';

  @override
  String get nearbySyncNoDevices =>
      'No nearby hosts found yet. Ask the other device to start hosting.';

  @override
  String get nearbySyncManualJoin => 'Join manually (IP + code)';

  @override
  String get nearbySyncJoinManual => 'Join with IP';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get impressum => 'Legal notice';

  @override
  String get legalSection => 'Legal';

  @override
  String get openLicenses => 'Open-source licenses';

  @override
  String appVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get flashcardAgain => 'Again';

  @override
  String get flashcardHard => 'Hard';

  @override
  String get flashcardGood => 'Good';

  @override
  String get flashcardEasy => 'Easy';

  @override
  String get flashcardStudy => 'Study due cards';

  @override
  String get flashcardBrowse => 'Browse deck';

  @override
  String get flashcardSessionDone => 'You\'re caught up for now';

  @override
  String flashcardReviewedCount(int count) {
    return '$count cards reviewed';
  }

  @override
  String get flashcardStudyAll => 'Study all cards';

  @override
  String flashcardDueProgress(int current, int remaining, int due) {
    return '$current / $remaining left · $due due today';
  }

  @override
  String get flashcardFlipToRate =>
      'Flip the card to rate how well you knew it';

  @override
  String get importIntoNotebook => 'Import into notebook';

  @override
  String get importPickNotebookHint =>
      'Choose where the shared file should be added as new page(s).';

  @override
  String get importCreateNotebook => 'Create new notebook';

  @override
  String get importNewNotebookTitle => 'Imported';

  @override
  String get importAddFiles => 'Add files';

  @override
  String get importAddFilesHint =>
      'Pick PDF, images, Office, GoodNotes, or ZIP files';

  @override
  String get importNoFilesYet => 'No files ready to import';

  @override
  String get importExistingNotebooks => 'Existing notebooks';

  @override
  String get importingFiles => 'Importing…';

  @override
  String get importAnyFile => 'Import file';

  @override
  String get exportPageAsImage => 'Export page as image';

  @override
  String get exportPdfForGoodNotes => 'PDF for GoodNotes';

  @override
  String get exportPdfForGoodNotesHint => 'Import this PDF in GoodNotes';

  @override
  String get backupSection => 'Backup & restore';

  @override
  String get backupSectionHint =>
      'Export a ZIP of notebooks, pages, flashcards, grades, and timetable — or restore from a previous backup.';

  @override
  String get backupExport => 'Export backup ZIP';

  @override
  String get backupExportHint => 'Share or save a full backup';

  @override
  String get backupRestore => 'Restore from ZIP';

  @override
  String get backupRestoreHint => 'Merge into or replace local data';

  @override
  String get backupRestoreMergeQuestion =>
      'Merge into existing data, or replace notebooks and decks?';

  @override
  String get backupMerge => 'Merge';

  @override
  String get backupReplace => 'Replace';

  @override
  String backupRestored(int count) {
    return 'Restored $count notebooks';
  }

  @override
  String get noteToFlashcard => 'Make flashcard';

  @override
  String get flashcardCreated => 'Flashcard saved';

  @override
  String get pomodoroFocus => 'Focus';

  @override
  String get pomodoroBreak => 'Break';

  @override
  String get pomodoroStart => 'Start timer';

  @override
  String get pomodoroPause => 'Pause timer';

  @override
  String get pomodoroReset => 'Reset timer';

  @override
  String get notebookSubject => 'Subject';

  @override
  String get notebookSubjectHint => 'Links to timetable & grades';

  @override
  String get openLinkedNotebook => 'Open notebook';

  @override
  String get createNotebookForSubjectHint =>
      'No notebook is linked to this subject yet. Create one?';

  @override
  String get csvExportFlashcards => 'Export CSV';

  @override
  String get csvImportFlashcards => 'Import CSV';

  @override
  String get csvExportGrades => 'Export grades CSV';

  @override
  String get csvImportGrades => 'Import grades CSV';

  @override
  String csvImportedCards(int count) {
    return 'Imported $count cards';
  }

  @override
  String csvImportedGrades(int count) {
    return 'Imported $count grades';
  }

  @override
  String get start => 'Start';

  @override
  String get name => 'Name';

  @override
  String get homework => 'Homework';

  @override
  String get share => 'Share';

  @override
  String get roleWelcomeTitle => 'How do you use Notis?';

  @override
  String get roleWelcomeBody =>
      'Choose your role. Students get the existing study workspace; teachers also get classroom and material tools.';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get roleStudentHint =>
      'Notebooks, timetable, grades, flashcards, and study mode.';

  @override
  String get roleTeacherHint =>
      'Everything in the student workspace plus live classes, lesson planning, materials, and grade reports.';

  @override
  String get roleChooseStudent => 'Start as student';

  @override
  String get roleChooseTeacher => 'Start as teacher';

  @override
  String get roleCanChangeLater => 'You can change the role later in Settings.';

  @override
  String get roleSection => 'Role';

  @override
  String get roleSectionHint =>
      'Your role controls which workspaces and options are shown.';

  @override
  String get teacherWorkspace => 'Teacher workspace';

  @override
  String get teacherOverview => 'Overview';

  @override
  String get teacherOverviewTitle => 'Prepare and run lessons efficiently';

  @override
  String get teacherOverviewHint =>
      'Live sessions, assignments, lesson calendar, materials, and audio explanations in one place.';

  @override
  String get teacherLiveClass => 'Live class';

  @override
  String get teacherLiveClassHint =>
      'Start a host-controlled session and manage writing, hands, focus, and progress.';

  @override
  String get teacherLessonJournal => 'Lesson journal';

  @override
  String get teacherMaterials => 'Materials';

  @override
  String get teacherGradeReport => 'Grade report';

  @override
  String get teacherProfile => 'Teacher profile';

  @override
  String get teacherAudio => 'Audio explanations';

  @override
  String get teacherAudioHint =>
      'Record explanations locally, transcribe them, and share selectively.';

  @override
  String get teacherTrainee => 'Teacher trainee special';

  @override
  String get teacherTraineeHint =>
      'Submit proof and request extended material access.';

  @override
  String teacherSessionActive(String code) {
    return 'Session $code is active';
  }

  @override
  String teacherLessonCount(int count) {
    return '$count lesson plan entries';
  }

  @override
  String teacherMaterialCount(int count) {
    return '$count materials in your library';
  }

  @override
  String get teacherNewLesson => 'New lesson';

  @override
  String get teacherStartSession => 'Start session';

  @override
  String get teacherWhiteboardNotebook => 'Whiteboard notebook';

  @override
  String get teacherAddParticipant => 'Add participant';

  @override
  String get teacherNoActiveSession => 'No active class session';

  @override
  String teacherJoinCode(String code) {
    return 'Join code: $code';
  }

  @override
  String get teacherEndSession => 'End session';

  @override
  String get teacherParticipants => 'Participants';

  @override
  String get teacherAverageProgress => 'Average progress';

  @override
  String get teacherFocusCheck => 'Focus check';

  @override
  String get teacherFocusCheckPrivacy =>
      'Only reports whether Notis is in the foreground during the session — never other apps or their content.';

  @override
  String get teacherWaitingParticipants =>
      'Waiting for participants on the local network. You can add participants manually for testing.';

  @override
  String get teacherFocused => 'Active in Notis';

  @override
  String get teacherLeftApp => 'Left Notis';

  @override
  String get teacherAllowWriting => 'Toggle writing permission';

  @override
  String get teacherMute => 'Toggle mute';

  @override
  String get teacherAddLesson => 'Add lesson';

  @override
  String get teacherNoLessons => 'No lessons in the sequence yet.';

  @override
  String get teacherCancelAndShift => 'Cancel + shift';

  @override
  String get teacherAddMaterial => 'Add material';

  @override
  String get teacherDurationMinutes => 'Work time (minutes)';

  @override
  String get teacherMaterialSearch => 'Filter by subject, grade, or title';

  @override
  String get teacherHybridDistribution => 'Hybrid cloud distribution';

  @override
  String get teacherHybridDistributionHint =>
      'Local files remain local. With configured cloud storage, only a small download command is sent to students.';

  @override
  String get teacherNoMaterials =>
      'No materials yet. Add PDF, Office, or image files.';

  @override
  String get teacherDistribute => 'Distribute to class';

  @override
  String get teacherDistributionQueued =>
      'Distribution queued. Cloud download commands require a configured backend.';

  @override
  String get teacherGradeReportHint =>
      'Entered grades automatically produce a count, average, and distribution.';

  @override
  String get teacherGradedCount => 'Graded work';

  @override
  String get teacherClassAverage => 'Class average';

  @override
  String get teacherNoGrades => 'No graded work available yet.';

  @override
  String get teacherVerificationNone => 'Not requested';

  @override
  String get teacherVerificationPending => 'Review pending';

  @override
  String get teacherVerificationVerified => 'Verified';

  @override
  String get teacherVerificationRejected => 'Proof rejected';

  @override
  String get teacherVerificationStatus => 'Status';

  @override
  String get teacherSubmitProof => 'Submit proof';

  @override
  String get teacherVerificationPrivacy =>
      'Proof may only be uploaded after explicit consent and with a defined deletion period to a contracted review service. Currently only the local status is stored.';

  @override
  String get teacherMicrophonePermission =>
      'Microphone access is required to record.';

  @override
  String get teacherNewExplanation => 'New explanation';

  @override
  String get teacherSaveRecording => 'Save recording';

  @override
  String get teacherTranscript => 'Transcript';

  @override
  String get teacherTranscriptHint =>
      'Paste or correct the transcript. Automatic AI transcription requires a configured privacy-compliant service.';

  @override
  String get teacherAudioPrivacy =>
      'Recordings initially remain local on this device.';

  @override
  String get teacherStopRecording => 'Stop recording';

  @override
  String get teacherStartRecording => 'Record explanation';

  @override
  String get teacherRecordings => 'Recordings';

  @override
  String get teacherNoRecordings => 'No explanations recorded yet.';

  @override
  String get teacherTranscriptPending => 'Transcript pending — tap to edit';

  @override
  String get teacherWaitingForWritePermission =>
      'View only — teacher controls writing';

  @override
  String get teacherWritingAllowed => 'You may write on the whiteboard';

  @override
  String get teacherWritingBlocked =>
      'The teacher has disabled writing for you.';

  @override
  String get teacherSubmitOer => 'Submit to the community as OER';

  @override
  String get teacherSubmitOerHint =>
      'The item becomes public only after review.';

  @override
  String get teacherOerSubmitted => 'Material submitted for review.';

  @override
  String get teacherOerSignInRequired =>
      'Sign in to submit community material.';

  @override
  String get teacherOerUploadUnavailable =>
      'The file could not be read for upload.';

  @override
  String get teacherStartClassBeforeDistribute =>
      'Start a live class session first.';

  @override
  String get teacherDistributionSent => 'Download command sent to the class.';

  @override
  String get teacherAllowFocusCheck => 'Allow focus check';

  @override
  String get description => 'Description';

  @override
  String get teacherLessonCalendar => 'Calendar';

  @override
  String get teacherLessonCalendarHint =>
      'Tap a day to record title, description, and attachments for each lesson from the timetable.';

  @override
  String get teacherNoSchoolDay =>
      'There is no class in the timetable on this day.';

  @override
  String get teacherNoLessonsForDay => 'No lessons are scheduled for this day.';

  @override
  String teacherPeriod(int n) {
    return 'Period $n';
  }

  @override
  String get teacherLessonAttachments => 'Attachments';

  @override
  String teacherAttachmentCount(int count) {
    return '$count attachments';
  }

  @override
  String get teacherOpenWhiteboard => 'Open board';

  @override
  String get teacherSaveLessonMaterials => 'Save materials';

  @override
  String get teacherWhiteboardFinal => 'Final whiteboard';

  @override
  String get teacherNoWhiteboardToSave => 'No whiteboard available to save.';

  @override
  String teacherSavedMaterialsLabel(String time) {
    return 'Materials $time';
  }

  @override
  String get teacherMaterialsSavedToLesson =>
      'Materials attached to the current lesson.';

  @override
  String get notNow => 'Not now';

  @override
  String get enable => 'Enable';

  @override
  String get teacherSubjectOrRoomRequired =>
      'Enter at least a subject or a room.';

  @override
  String get classroomAutoConnectTitle => 'Connect automatically next time?';

  @override
  String classroomAutoConnectBody(String criteria) {
    return 'Notis can look for “$criteria” during the next lesson. It connects only when the subject or room matches. The teacher verifies these criteria again during the handshake.';
  }

  @override
  String get classroomAutoConnectSetting => 'Automatically connect to class';

  @override
  String get classroomAutoConnectSettingHint =>
      'Connects only when at least the saved subject or room matches the teacher session.';

  @override
  String get classroomAutoConnectMismatch =>
      'Automatic connection rejected: neither subject nor room matches.';

  @override
  String get marketplace => 'Marketplace';

  @override
  String get marketplaceHint =>
      'Optional add-ons that not everyone needs. Purchases come later — this is the catalog.';

  @override
  String get marketplaceComingSoon =>
      'Purchase and unlock will arrive in a later update.';

  @override
  String get marketplaceSoonBadge => 'Soon';

  @override
  String get marketplaceInkOcrHint =>
      'Handwriting and photos are recognized on-device and stored only as a hidden search index.';

  @override
  String get marketplaceCloudHint =>
      'Premium cloud relay when no nearby P2P channel is available.';

  @override
  String get featureCloudSync => 'Cloud sync';

  @override
  String get scanPages => 'Scan pages';

  @override
  String get scanPagesHint =>
      'System document scanner — sheets become notebook pages.';

  @override
  String get scanExam => 'Scan the exam?';

  @override
  String get scanExamBody =>
      'Photograph the test now and add the pages to a notebook.';

  @override
  String scannedNotebookTitle(String date) {
    return 'Scan $date';
  }

  @override
  String get scanFailed => 'Could not open the scanner.';

  @override
  String scanAddedPages(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count scanned pages',
      one: 'Added 1 scanned page',
    );
    return '$_temp0';
  }

  @override
  String get searchAtHint =>
      'Use @ to search only in a subject, folder, or school year';

  @override
  String get pinTool => 'Pin';

  @override
  String get calculator => 'Calculator';

  @override
  String get calculatorHint => 'e.g. 2+3*4 or sin(x)';

  @override
  String get calculatorEquals => '=';

  @override
  String get calculatorPlot => 'Insert graph';

  @override
  String get calculatorHistory => 'Recent calculations';

  @override
  String get formulaBook => 'Formula book';

  @override
  String get formulaTerm => 'Term';

  @override
  String get formulaValue => 'Formula / value';

  @override
  String get formulaAddRow => 'Add row';

  @override
  String get continueAction => 'Continue';

  @override
  String get setupStudentTitle => 'Your path';

  @override
  String get setupStudentBody =>
      'So notes, grades, and the next term match how you learn.';

  @override
  String get setupTeacherTitle => 'Your teacher profile';

  @override
  String get setupTeacherBody => 'Are you still studying or already teaching?';

  @override
  String get setupTeacherTrack => 'Status';

  @override
  String get teacherTrackStudying => 'In studies';

  @override
  String get teacherTrackStudyingHint =>
      'When a semester starts you can create a new notebook and keep chosen chapters.';

  @override
  String get teacherTrackQualified => 'Already qualified';

  @override
  String get teacherTrackQualifiedHint =>
      'For class — including sharing notebooks and materials.';

  @override
  String get newTermNotebook => 'Create a notebook for this term';

  @override
  String importChaptersBodyTerm(String title, String period) {
    return 'Which chapters from “$title” should carry over to $period?';
  }

  @override
  String termWinterHalbjahr(String year) {
    return '1st term $year';
  }

  @override
  String termSummerHalbjahr(String year) {
    return '2nd term $year';
  }

  @override
  String termWinterSemester(String year) {
    return 'Winter semester $year';
  }

  @override
  String termSummerSemester(String year) {
    return 'Summer semester $year';
  }

  @override
  String get teacherShareContent => 'Share content';

  @override
  String get teacherShareContentHint =>
      'Send the board, notebooks, flashcards, or files to the class.';

  @override
  String get teacherShareLiveBoard => 'Send the current board';

  @override
  String get teacherShareNotebook => 'Share notebook';

  @override
  String get teacherShareFlashcards => 'Share flashcards';

  @override
  String get tutorialOfferTitle => 'A short tour?';

  @override
  String get tutorialOfferBody =>
      'A few steps that point out the main parts of the app.';

  @override
  String get tutorialStart => 'Start tutorial';

  @override
  String get tutorialSkip => 'Not now';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialDone => 'Done';

  @override
  String get tourLibraryTitle => 'Your library';

  @override
  String get tourLibraryBody =>
      'Notebooks, folders, and flashcards live here. Tap a cover to open it.';

  @override
  String get tourCreateTitle => 'Create something';

  @override
  String get tourCreateBody =>
      'Use plus to add a notebook, folder, or flashcard deck.';

  @override
  String get tourSearchTitle => 'Search with @';

  @override
  String get tourSearchBody =>
      'Try @Economics addition to search inside one subject only.';

  @override
  String get tourSettingsTitle => 'Settings';

  @override
  String get tourSettingsBody =>
      'Role, state, stylus gestures, and this tutorial are here.';

  @override
  String get tourTeacherTitle => 'Teacher tools';

  @override
  String get tourTeacherBody =>
      'Start class and share the board, notebooks, or materials.';

  @override
  String get tourEditorTitle => 'Inside a notebook';

  @override
  String get tourEditorBody =>
      'The toolbar has pen, eraser, calculator, and the formula book. Swipe to change pages.';

  @override
  String get teacherAssignments => 'Assignments';

  @override
  String get teacherAssignmentsHint =>
      'Build worksheets in the editor. PDF scans become draft tasks you should review.';

  @override
  String teacherAssignmentCount(int count) {
    return '$count items in the catalog';
  }

  @override
  String get teacherNewAssignment => 'New assignment';

  @override
  String get teacherUntitledAssignment => 'Untitled';

  @override
  String get teacherImportPdf => 'Import from PDF';

  @override
  String get teacherImportPdfHint =>
      'Pages are read and split into editable tasks.';

  @override
  String get teacherImportScan => 'Scan and import';

  @override
  String get teacherImportScanHint =>
      'Camera or scanner, then review the draft in the editor.';

  @override
  String get teacherImportedScanTitle => 'Scan';

  @override
  String get teacherReviewBanner =>
      'Text and structure come from the scan. Please review, edit if needed, and confirm before you use this assignment.';

  @override
  String get teacherConfirmDraft => 'Confirm draft';

  @override
  String get teacherNeedsReview => 'Needs review';

  @override
  String get teacherAnswerKind => 'Answer type';

  @override
  String get teacherAnswerText => 'Free text';

  @override
  String get teacherAnswerMc => 'Multiple choice';

  @override
  String get teacherAnswerCalc => 'Calculation';

  @override
  String get teacherAnswerMatch => 'Matching';

  @override
  String get teacherTaskParts => 'Task parts';

  @override
  String get teacherAddPartText => 'Text';

  @override
  String get teacherAddPartImage => 'Image';

  @override
  String get teacherAddPartLink => 'Link';

  @override
  String get teacherSampleAnswer => 'Sample answer';

  @override
  String get teacherCalcResult => 'Final result';

  @override
  String get teacherCalcTolerance => 'Tolerance';

  @override
  String get teacherMaxPoints => 'Points';

  @override
  String get teacherKindTask => 'Task';

  @override
  String get teacherKindTest => 'Test';

  @override
  String get teacherKindExam => 'Exam';

  @override
  String get teacherCatalogKind => 'Kind';

  @override
  String get teacherCatalogVisibility => 'Visibility';

  @override
  String get teacherVisibilityPrivate => 'Only me';

  @override
  String get teacherVisibilitySchool => 'School only';

  @override
  String get teacherVisibilityPublic => 'Public';

  @override
  String get teacherSuggestedDuration => 'Suggested duration (min.)';

  @override
  String get teacherNoAssignments =>
      'No assignments yet. Create one or import a PDF or scan.';

  @override
  String get teacherImporting => 'Converting into the editor…';

  @override
  String get teacherImportFailed => 'Could not convert this file';

  @override
  String get teacherAddTask => 'Add task';

  @override
  String get teacherCorrectOption => 'Mark the correct answer';

  @override
  String get teacherMatchLeft => 'Left';

  @override
  String get teacherMatchRight => 'Right';

  @override
  String get teacherDeleteTask => 'Delete task';

  @override
  String get teacherTags => 'Tags';

  @override
  String get teacherTasksHeading => 'Tasks';

  @override
  String teacherTaskNumber(int number) {
    return 'Task $number';
  }

  @override
  String teacherTaskCount(int count) {
    return '$count tasks';
  }

  @override
  String get teacherSchool => 'School';

  @override
  String get teacherSchoolName => 'School name';

  @override
  String get teacherSchoolCode => 'School join code';

  @override
  String get assignmentTitle => 'Assignment';

  @override
  String get assignmentWaiting => 'Waiting for an assignment from the teacher.';

  @override
  String get assignmentSubmit => 'Done — submit';

  @override
  String get assignmentSubmitted => 'Submitted. This workspace is locked.';

  @override
  String get assignmentLocked =>
      'Time is up. Wait for extra time or collection.';

  @override
  String get assignmentYourAnswer => 'Your answer';

  @override
  String get assignmentImportNotebook => 'Add to a notebook';

  @override
  String get assignmentStart => 'Start assignment';

  @override
  String get assignmentStartHint =>
      'Pick a confirmed template and send it to the class as its own page.';

  @override
  String get assignmentTestMode =>
      'Test mode (lock calculator and formula book)';

  @override
  String get assignmentExtend5 => '+5 minutes';

  @override
  String get assignmentExtend10 => '+10 minutes';

  @override
  String get assignmentCollect => 'Collect';

  @override
  String get assignmentAllowImport => 'Allow import';

  @override
  String get assignmentResults => 'Results';

  @override
  String get assignmentPrint => 'Print without solutions';

  @override
  String assignmentClassAverage(int percent) {
    return 'Class average $percent %';
  }

  @override
  String assignmentSubmittedCount(int done, int total) {
    return 'Submitted: $done/$total';
  }

  @override
  String get assignmentTopProblems => 'Most common problems';

  @override
  String get assignmentNoProblems => 'No graded problems yet.';

  @override
  String get assignmentGroups => 'Similar error patterns';

  @override
  String get assignmentSubmissions => 'Submissions';

  @override
  String get assignmentEarly => 'submitted early';

  @override
  String get assignmentOnCollect => 'collected';

  @override
  String get assignmentCorrection => 'Send a correction to this device';

  @override
  String get assignmentLeaveSignals => 'Left / lost focus';

  @override
  String get assignmentPoolLocked =>
      'Exchange: publish once to browse other public assignments.';

  @override
  String get assignmentPoolUnlocked =>
      'Exchange is unlocked. Other teachers\' public items appear once cloud sync is connected.';
}
