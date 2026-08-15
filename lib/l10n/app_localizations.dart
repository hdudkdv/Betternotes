import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BetterNotes'**
  String get appTitle;

  /// No description provided for @newNotebook.
  ///
  /// In en, this message translates to:
  /// **'New notebook'**
  String get newNotebook;

  /// No description provided for @untitledNotebook.
  ///
  /// In en, this message translates to:
  /// **'Untitled Notebook'**
  String get untitledNotebook;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @blank.
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get blank;

  /// No description provided for @lined.
  ///
  /// In en, this message translates to:
  /// **'Lined'**
  String get lined;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @searchNotebooks.
  ///
  /// In en, this message translates to:
  /// **'Search notebooks'**
  String get searchNotebooks;

  /// No description provided for @globalSearch.
  ///
  /// In en, this message translates to:
  /// **'Global search'**
  String get globalSearch;

  /// No description provided for @noNotebooksYet.
  ///
  /// In en, this message translates to:
  /// **'No notebooks yet'**
  String get noNotebooksYet;

  /// No description provided for @noNotebooksHint.
  ///
  /// In en, this message translates to:
  /// **'Create one and start writing with your stylus.'**
  String get noNotebooksHint;

  /// No description provided for @deleteNotebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete notebook?'**
  String get deleteNotebookTitle;

  /// No description provided for @deleteNotebookBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed permanently.'**
  String deleteNotebookBody(String title);

  /// No description provided for @pageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String pageCount(int count);

  /// No description provided for @outline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get outline;

  /// No description provided for @outlineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add chapters and subsections for deep structure.'**
  String get outlineEmpty;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @addPage.
  ///
  /// In en, this message translates to:
  /// **'Add page'**
  String get addPage;

  /// No description provided for @addSection.
  ///
  /// In en, this message translates to:
  /// **'Add section'**
  String get addSection;

  /// No description provided for @addSubchapter.
  ///
  /// In en, this message translates to:
  /// **'Add subchapter'**
  String get addSubchapter;

  /// No description provided for @addParentChapter.
  ///
  /// In en, this message translates to:
  /// **'Add higher-level chapter'**
  String get addParentChapter;

  /// No description provided for @nameChapterHint.
  ///
  /// In en, this message translates to:
  /// **'Name this chapter…'**
  String get nameChapterHint;

  /// No description provided for @nameSubchapterHint.
  ///
  /// In en, this message translates to:
  /// **'Name this subchapter…'**
  String get nameSubchapterHint;

  /// No description provided for @schoolClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get schoolClass;

  /// No description provided for @schoolClassHint.
  ///
  /// In en, this message translates to:
  /// **'Which class are you in?'**
  String get schoolClassHint;

  /// No description provided for @schoolClassNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get schoolClassNone;

  /// No description provided for @schoolClassValue.
  ///
  /// In en, this message translates to:
  /// **'Grade {n}'**
  String schoolClassValue(int n);

  /// No description provided for @importFromPreviousClass.
  ///
  /// In en, this message translates to:
  /// **'Import from previous class'**
  String get importFromPreviousClass;

  /// No description provided for @importFromClass.
  ///
  /// In en, this message translates to:
  /// **'Import from grade {n}'**
  String importFromClass(int n);

  /// No description provided for @importChapterHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a chapter to add it here.'**
  String get importChapterHint;

  /// No description provided for @newSchoolYearNotebook.
  ///
  /// In en, this message translates to:
  /// **'Create notebook for this school year'**
  String get newSchoolYearNotebook;

  /// No description provided for @importChaptersTitle.
  ///
  /// In en, this message translates to:
  /// **'Import chapters'**
  String get importChaptersTitle;

  /// No description provided for @importChaptersBody.
  ///
  /// In en, this message translates to:
  /// **'Which chapters from “{title}” should carry over to grade {n}?'**
  String importChaptersBody(String title, int n);

  /// No description provided for @importChaptersEmpty.
  ///
  /// In en, this message translates to:
  /// **'The previous notebook has no chapters yet.'**
  String get importChaptersEmpty;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get selectAll;

  /// No description provided for @selectNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get selectNone;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @tapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get tapToContinue;

  /// No description provided for @pen.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get pen;

  /// No description provided for @ballpointPen.
  ///
  /// In en, this message translates to:
  /// **'Ballpoint'**
  String get ballpointPen;

  /// No description provided for @pencil.
  ///
  /// In en, this message translates to:
  /// **'Pencil'**
  String get pencil;

  /// No description provided for @fountainPen.
  ///
  /// In en, this message translates to:
  /// **'Fountain pen'**
  String get fountainPen;

  /// No description provided for @pressureSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressureSensitivity;

  /// No description provided for @marker.
  ///
  /// In en, this message translates to:
  /// **'Marker'**
  String get marker;

  /// No description provided for @textTool.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textTool;

  /// No description provided for @eraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraser;

  /// No description provided for @lasso.
  ///
  /// In en, this message translates to:
  /// **'Lasso'**
  String get lasso;

  /// No description provided for @addTextBox.
  ///
  /// In en, this message translates to:
  /// **'Add text box'**
  String get addTextBox;

  /// No description provided for @paperCreator.
  ///
  /// In en, this message translates to:
  /// **'Paper creator'**
  String get paperCreator;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @deleteSelection.
  ///
  /// In en, this message translates to:
  /// **'Delete selection'**
  String get deleteSelection;

  /// No description provided for @writing.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get writing;

  /// No description provided for @fingerPanZoom.
  ///
  /// In en, this message translates to:
  /// **'Stylus only (finger pans)'**
  String get fingerPanZoom;

  /// No description provided for @fingerPanZoomHint.
  ///
  /// In en, this message translates to:
  /// **'On: stylus draws, finger pans.'**
  String get fingerPanZoomHint;

  /// No description provided for @defaultTemplate.
  ///
  /// In en, this message translates to:
  /// **'Default template'**
  String get defaultTemplate;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLanguage;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get syncUpToDate;

  /// No description provided for @syncQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue empty · offline-first local sync'**
  String get syncQueueEmpty;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} pending ops'**
  String syncPending(int count);

  /// No description provided for @flushSync.
  ///
  /// In en, this message translates to:
  /// **'Flush sync queue'**
  String get flushSync;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'BetterNotes — Smart Text, Custom Paper, Deep Outline, global search, and offline-first sync queue.'**
  String get aboutBody;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search or @Subject @Grade10 …'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type to search across all notes.'**
  String get searchEmpty;

  /// No description provided for @crossLink.
  ///
  /// In en, this message translates to:
  /// **'Cross-link'**
  String get crossLink;

  /// No description provided for @linkToNotebook.
  ///
  /// In en, this message translates to:
  /// **'Link to notebook'**
  String get linkToNotebook;

  /// No description provided for @crossLinkCreated.
  ///
  /// In en, this message translates to:
  /// **'Cross-link created'**
  String get crossLinkCreated;

  /// No description provided for @needAnotherNotebook.
  ///
  /// In en, this message translates to:
  /// **'Create another notebook to link.'**
  String get needAnotherNotebook;

  /// No description provided for @importPdf.
  ///
  /// In en, this message translates to:
  /// **'Import PDF'**
  String get importPdf;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current}/{total}'**
  String pageOf(int current, int total);

  /// No description provided for @infiniteCanvas.
  ///
  /// In en, this message translates to:
  /// **'Infinite canvas'**
  String get infiniteCanvas;

  /// No description provided for @pageMode.
  ///
  /// In en, this message translates to:
  /// **'Page mode'**
  String get pageMode;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @formatText.
  ///
  /// In en, this message translates to:
  /// **'Format text'**
  String get formatText;

  /// No description provided for @bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get bold;

  /// No description provided for @italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get italic;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @renameSection.
  ///
  /// In en, this message translates to:
  /// **'Rename section'**
  String get renameSection;

  /// No description provided for @indent.
  ///
  /// In en, this message translates to:
  /// **'Indent'**
  String get indent;

  /// No description provided for @outdent.
  ///
  /// In en, this message translates to:
  /// **'Outdent'**
  String get outdent;

  /// No description provided for @chapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter {n}'**
  String chapter(int n);

  /// No description provided for @section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get section;

  /// No description provided for @newText.
  ///
  /// In en, this message translates to:
  /// **'New text'**
  String get newText;

  /// No description provided for @style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get style;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @lineSpacing.
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get lineSpacing;

  /// No description provided for @gridSize.
  ///
  /// In en, this message translates to:
  /// **'Grid size'**
  String get gridSize;

  /// No description provided for @leftMargin.
  ///
  /// In en, this message translates to:
  /// **'Left margin'**
  String get leftMargin;

  /// No description provided for @topMargin.
  ///
  /// In en, this message translates to:
  /// **'Top margin'**
  String get topMargin;

  /// No description provided for @myPaper.
  ///
  /// In en, this message translates to:
  /// **'My paper'**
  String get myPaper;

  /// No description provided for @shapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get shapes;

  /// No description provided for @ruler.
  ///
  /// In en, this message translates to:
  /// **'Ruler'**
  String get ruler;

  /// No description provided for @compass.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get compass;

  /// No description provided for @fixGuide.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get fixGuide;

  /// No description provided for @guideFixed.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get guideFixed;

  /// No description provided for @compassSetCenter.
  ///
  /// In en, this message translates to:
  /// **'Tap to set center'**
  String get compassSetCenter;

  /// No description provided for @compassRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get compassRadius;

  /// No description provided for @strokeStyleSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get strokeStyleSolid;

  /// No description provided for @strokeStyleDashed.
  ///
  /// In en, this message translates to:
  /// **'Dashed'**
  String get strokeStyleDashed;

  /// No description provided for @strokeStyleDotted.
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get strokeStyleDotted;

  /// No description provided for @strokeStyleDashDot.
  ///
  /// In en, this message translates to:
  /// **'Dash-dot'**
  String get strokeStyleDashDot;

  /// No description provided for @rulerHint.
  ///
  /// In en, this message translates to:
  /// **'Drag for a straight line (snaps every 15°)'**
  String get rulerHint;

  /// No description provided for @compassHint.
  ///
  /// In en, this message translates to:
  /// **'Center → drag for radius'**
  String get compassHint;

  /// No description provided for @shapeLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get shapeLine;

  /// No description provided for @shapeRect.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get shapeRect;

  /// No description provided for @shapeEllipse.
  ///
  /// In en, this message translates to:
  /// **'Ellipse'**
  String get shapeEllipse;

  /// No description provided for @shapeArrow.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get shapeArrow;

  /// No description provided for @insertImage.
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get insertImage;

  /// No description provided for @readMode.
  ///
  /// In en, this message translates to:
  /// **'Read mode'**
  String get readMode;

  /// No description provided for @editMode.
  ///
  /// In en, this message translates to:
  /// **'Edit mode'**
  String get editMode;

  /// No description provided for @libraryHome.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryHome;

  /// No description provided for @freeTextBox.
  ///
  /// In en, this message translates to:
  /// **'Free box'**
  String get freeTextBox;

  /// No description provided for @pageText.
  ///
  /// In en, this message translates to:
  /// **'Page text'**
  String get pageText;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @notebooks.
  ///
  /// In en, this message translates to:
  /// **'Notebooks'**
  String get notebooks;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entries;

  /// No description provided for @flashcards.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get flashcards;

  /// No description provided for @newFlashcardDeck.
  ///
  /// In en, this message translates to:
  /// **'New flashcard deck'**
  String get newFlashcardDeck;

  /// No description provided for @untitledDeck.
  ///
  /// In en, this message translates to:
  /// **'Untitled deck'**
  String get untitledDeck;

  /// No description provided for @newFlashcard.
  ///
  /// In en, this message translates to:
  /// **'New flashcard'**
  String get newFlashcard;

  /// No description provided for @flashcardFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get flashcardFront;

  /// No description provided for @flashcardBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get flashcardBack;

  /// No description provided for @noFlashcardsYet.
  ///
  /// In en, this message translates to:
  /// **'No flashcards yet'**
  String get noFlashcardsYet;

  /// No description provided for @tapToFlip.
  ///
  /// In en, this message translates to:
  /// **'Tap to flip'**
  String get tapToFlip;

  /// No description provided for @searchEverything.
  ///
  /// In en, this message translates to:
  /// **'Search or @Economics addition …'**
  String get searchEverything;

  /// No description provided for @shareExport.
  ///
  /// In en, this message translates to:
  /// **'Share & export'**
  String get shareExport;

  /// No description provided for @printPdf.
  ///
  /// In en, this message translates to:
  /// **'Print / PDF preview'**
  String get printPdf;

  /// No description provided for @printPdfHint.
  ///
  /// In en, this message translates to:
  /// **'Open the system print dialog'**
  String get printPdfHint;

  /// No description provided for @sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share notebook as PDF'**
  String get sharePdf;

  /// No description provided for @sharePdfHint.
  ///
  /// In en, this message translates to:
  /// **'Entire notebook'**
  String get sharePdfHint;

  /// No description provided for @shareCurrentPage.
  ///
  /// In en, this message translates to:
  /// **'Share current page'**
  String get shareCurrentPage;

  /// No description provided for @shareCurrentPageHint.
  ///
  /// In en, this message translates to:
  /// **'Only this page as PDF'**
  String get shareCurrentPageHint;

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get documentType;

  /// No description provided for @paperSize.
  ///
  /// In en, this message translates to:
  /// **'Paper size'**
  String get paperSize;

  /// No description provided for @pageOrientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get pageOrientation;

  /// No description provided for @portrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// No description provided for @landscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get landscape;

  /// No description provided for @paperLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get paperLetter;

  /// No description provided for @paperLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get paperLegal;

  /// No description provided for @paperTabloid.
  ///
  /// In en, this message translates to:
  /// **'Tabloid'**
  String get paperTabloid;

  /// No description provided for @newPagesOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Only applies to pages added from now on.'**
  String get newPagesOnlyHint;

  /// No description provided for @choosePastEvent.
  ///
  /// In en, this message translates to:
  /// **'Choose a past event'**
  String get choosePastEvent;

  /// No description provided for @repeatEvent.
  ///
  /// In en, this message translates to:
  /// **'Repeat event'**
  String get repeatEvent;

  /// No description provided for @repeatFrequency.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatFrequency;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @repeatUntil.
  ///
  /// In en, this message translates to:
  /// **'Repeat until'**
  String get repeatUntil;

  /// No description provided for @repeatInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get repeatInterval;

  /// No description provided for @repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Every {count}'**
  String repeatEvery(int count);

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @importedPageTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Imported template'**
  String get importedPageTemplateTitle;

  /// No description provided for @importedPageTemplateBody.
  ///
  /// In en, this message translates to:
  /// **'The previous page uses an image or PDF background. Which template should the new page use?'**
  String get importedPageTemplateBody;

  /// No description provided for @keepCurrentTemplate.
  ///
  /// In en, this message translates to:
  /// **'Keep current template'**
  String get keepCurrentTemplate;

  /// No description provided for @useNotebookDefault.
  ///
  /// In en, this message translates to:
  /// **'Use notebook default'**
  String get useNotebookDefault;

  /// No description provided for @documentTypeFixedHint.
  ///
  /// In en, this message translates to:
  /// **'Chosen when the document is created and stays that way'**
  String get documentTypeFixedHint;

  /// No description provided for @infiniteDocument.
  ///
  /// In en, this message translates to:
  /// **'Infinite document'**
  String get infiniteDocument;

  /// No description provided for @infiniteDocumentHint.
  ///
  /// In en, this message translates to:
  /// **'One large canvas with free zoom. Only the visible area is rendered.'**
  String get infiniteDocumentHint;

  /// No description provided for @eraserStroke.
  ///
  /// In en, this message translates to:
  /// **'Stroke'**
  String get eraserStroke;

  /// No description provided for @eraserSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get eraserSection;

  /// No description provided for @eraserPrecise.
  ///
  /// In en, this message translates to:
  /// **'Precise'**
  String get eraserPrecise;

  /// No description provided for @editWidth.
  ///
  /// In en, this message translates to:
  /// **'Adjust stroke width'**
  String get editWidth;

  /// No description provided for @editWidthHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to select · Long-press to edit'**
  String get editWidthHint;

  /// No description provided for @addColor.
  ///
  /// In en, this message translates to:
  /// **'Add color'**
  String get addColor;

  /// No description provided for @removeColor.
  ///
  /// In en, this message translates to:
  /// **'Remove color'**
  String get removeColor;

  /// No description provided for @hue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hue;

  /// No description provided for @saturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get saturation;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @colorPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get colorPickerTitle;

  /// No description provided for @opacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get opacity;

  /// No description provided for @recentColors.
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get recentColors;

  /// No description provided for @presetColors.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get presetColors;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get customColor;

  /// No description provided for @editColorHint.
  ///
  /// In en, this message translates to:
  /// **'Tap: select · Hold: edit'**
  String get editColorHint;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Look and light/dark mode of the app'**
  String get appearanceHint;

  /// No description provided for @lookStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get lookStudio;

  /// No description provided for @lookStudioHint.
  ///
  /// In en, this message translates to:
  /// **'Graphite with an indigo accent'**
  String get lookStudioHint;

  /// No description provided for @lookPaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get lookPaper;

  /// No description provided for @lookPaperHint.
  ///
  /// In en, this message translates to:
  /// **'Cream, deep green, serif'**
  String get lookPaperHint;

  /// No description provided for @lookFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get lookFresh;

  /// No description provided for @lookFreshHint.
  ///
  /// In en, this message translates to:
  /// **'White, teal, airy'**
  String get lookFreshHint;

  /// No description provided for @lookMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get lookMono;

  /// No description provided for @lookMonoHint.
  ///
  /// In en, this message translates to:
  /// **'Black and white, minimal'**
  String get lookMonoHint;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @menuPageGroup.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get menuPageGroup;

  /// No description provided for @menuViewGroup.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuViewGroup;

  /// No description provided for @menuDocumentGroup.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get menuDocumentGroup;

  /// No description provided for @menuPaperGroup.
  ///
  /// In en, this message translates to:
  /// **'Paper of this page'**
  String get menuPaperGroup;

  /// No description provided for @paperPresets.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get paperPresets;

  /// No description provided for @paperPresetsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to apply · Long-press custom templates to delete'**
  String get paperPresetsHint;

  /// No description provided for @paperPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get paperPreview;

  /// No description provided for @paperColor.
  ///
  /// In en, this message translates to:
  /// **'Paper color'**
  String get paperColor;

  /// No description provided for @lineColor.
  ///
  /// In en, this message translates to:
  /// **'Line color'**
  String get lineColor;

  /// No description provided for @applyPaper.
  ///
  /// In en, this message translates to:
  /// **'Apply to page'**
  String get applyPaper;

  /// No description provided for @resetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetDefaults;

  /// No description provided for @blankPaperHint.
  ///
  /// In en, this message translates to:
  /// **'Blank paper — adjust color and name only.'**
  String get blankPaperHint;

  /// No description provided for @editingBuiltinHint.
  ///
  /// In en, this message translates to:
  /// **'Built-in template — saving creates your own copy.'**
  String get editingBuiltinHint;

  /// No description provided for @collegeRuled.
  ///
  /// In en, this message translates to:
  /// **'College'**
  String get collegeRuled;

  /// No description provided for @narrowRuled.
  ///
  /// In en, this message translates to:
  /// **'Narrow ruled'**
  String get narrowRuled;

  /// No description provided for @dotGrid.
  ///
  /// In en, this message translates to:
  /// **'Fine grid'**
  String get dotGrid;

  /// No description provided for @pageBrowseMode.
  ///
  /// In en, this message translates to:
  /// **'Page browsing'**
  String get pageBrowseMode;

  /// No description provided for @pageBrowseModeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe: page by page left/right. Scroll: all pages in one vertical stack.'**
  String get pageBrowseModeHint;

  /// No description provided for @browseSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get browseSwipe;

  /// No description provided for @browseScroll.
  ///
  /// In en, this message translates to:
  /// **'Scroll'**
  String get browseScroll;

  /// No description provided for @gesturesSection.
  ///
  /// In en, this message translates to:
  /// **'Gestures'**
  String get gesturesSection;

  /// No description provided for @gesturesSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Map Apple Pencil and multi-touch shortcuts.'**
  String get gesturesSectionHint;

  /// No description provided for @gesturePencilDoubleTap.
  ///
  /// In en, this message translates to:
  /// **'Pencil double-tap'**
  String get gesturePencilDoubleTap;

  /// No description provided for @gesturePencilSqueeze.
  ///
  /// In en, this message translates to:
  /// **'Pencil squeeze'**
  String get gesturePencilSqueeze;

  /// No description provided for @gestureTwoFingerTap.
  ///
  /// In en, this message translates to:
  /// **'Two-finger tap'**
  String get gestureTwoFingerTap;

  /// No description provided for @gestureThreeFingerSwipeLeft.
  ///
  /// In en, this message translates to:
  /// **'Three-finger swipe left'**
  String get gestureThreeFingerSwipeLeft;

  /// No description provided for @gestureThreeFingerSwipeRight.
  ///
  /// In en, this message translates to:
  /// **'Three-finger swipe right'**
  String get gestureThreeFingerSwipeRight;

  /// No description provided for @gestureActionNone.
  ///
  /// In en, this message translates to:
  /// **'Do nothing'**
  String get gestureActionNone;

  /// No description provided for @gestureActionToggleEraser.
  ///
  /// In en, this message translates to:
  /// **'Pen / eraser'**
  String get gestureActionToggleEraser;

  /// No description provided for @gestureActionPreviousTool.
  ///
  /// In en, this message translates to:
  /// **'Previous tool'**
  String get gestureActionPreviousTool;

  /// No description provided for @gestureActionOpenToolWheel.
  ///
  /// In en, this message translates to:
  /// **'Open tool wheel'**
  String get gestureActionOpenToolWheel;

  /// No description provided for @gestureActionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get gestureActionUndo;

  /// No description provided for @gestureActionRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get gestureActionRedo;

  /// No description provided for @gestureActionNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get gestureActionNextPage;

  /// No description provided for @gestureActionPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get gestureActionPreviousPage;

  /// No description provided for @gestureActionExportPage.
  ///
  /// In en, this message translates to:
  /// **'Export page'**
  String get gestureActionExportPage;

  /// No description provided for @gestureActionCyclePenColor.
  ///
  /// In en, this message translates to:
  /// **'Cycle pen color'**
  String get gestureActionCyclePenColor;

  /// No description provided for @gestureActionFitZoom.
  ///
  /// In en, this message translates to:
  /// **'Fit page'**
  String get gestureActionFitZoom;

  /// No description provided for @gestureActionGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get gestureActionGoBack;

  /// No description provided for @pdfImportProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing PDF… {done}/{total}'**
  String pdfImportProgress(int done, int total);

  /// No description provided for @savePageAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save page as template'**
  String get savePageAsTemplate;

  /// No description provided for @savePageAsTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'Save a reusable page design — with or without lines.'**
  String get savePageAsTemplateHint;

  /// No description provided for @lineLayout.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get lineLayout;

  /// No description provided for @noLines.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noLines;

  /// No description provided for @fromPage.
  ///
  /// In en, this message translates to:
  /// **'From page'**
  String get fromPage;

  /// No description provided for @customLines.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customLines;

  /// No description provided for @customLinesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to add/remove lines. Tap left area to set the margin.'**
  String get customLinesHint;

  /// No description provided for @fillRuled.
  ///
  /// In en, this message translates to:
  /// **'Fill ruled'**
  String get fillRuled;

  /// No description provided for @clearLines.
  ///
  /// In en, this message translates to:
  /// **'Clear lines'**
  String get clearLines;

  /// No description provided for @templateSaved.
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get templateSaved;

  /// No description provided for @timetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get timetable;

  /// No description provided for @timetableHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a cell to fill lessons. Tap times on the left (scroll wheels). Blocks can be full or split. Link subjects to folders.'**
  String get timetableHint;

  /// No description provided for @timetableEmptyToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing for today yet — tap to fill in'**
  String get timetableEmptyToday;

  /// No description provided for @timetableTodayPreview.
  ///
  /// In en, this message translates to:
  /// **'Today: {preview}'**
  String timetableTodayPreview(String preview);

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @subjectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. English'**
  String get subjectHint;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @roomHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. R204'**
  String get roomHint;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @editPeriod.
  ///
  /// In en, this message translates to:
  /// **'Edit period'**
  String get editPeriod;

  /// No description provided for @periodLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get periodLabel;

  /// No description provided for @periodStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get periodStart;

  /// No description provided for @periodEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get periodEnd;

  /// No description provided for @addPeriod.
  ///
  /// In en, this message translates to:
  /// **'Add period'**
  String get addPeriod;

  /// No description provided for @removePeriod.
  ///
  /// In en, this message translates to:
  /// **'Remove last period'**
  String get removePeriod;

  /// No description provided for @mondayShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mondayShort;

  /// No description provided for @tuesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesdayShort;

  /// No description provided for @wednesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesdayShort;

  /// No description provided for @thursdayShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursdayShort;

  /// No description provided for @fridayShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fridayShort;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String lastSync(String time);

  /// No description provided for @blockMode.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockMode;

  /// No description provided for @fullBlock.
  ///
  /// In en, this message translates to:
  /// **'Full block'**
  String get fullBlock;

  /// No description provided for @splitBlock.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get splitBlock;

  /// No description provided for @fullBlockHint.
  ///
  /// In en, this message translates to:
  /// **'One subject for the whole block ({minutes} min).'**
  String fullBlockHint(int minutes);

  /// No description provided for @splitBlockHint.
  ///
  /// In en, this message translates to:
  /// **'Split: {first} · then {second}'**
  String splitBlockHint(String first, String second);

  /// No description provided for @firstHalf.
  ///
  /// In en, this message translates to:
  /// **'1st half'**
  String get firstHalf;

  /// No description provided for @secondHalf.
  ///
  /// In en, this message translates to:
  /// **'2nd half'**
  String get secondHalf;

  /// No description provided for @linkFolder.
  ///
  /// In en, this message translates to:
  /// **'Link to folder'**
  String get linkFolder;

  /// No description provided for @noFolderLink.
  ///
  /// In en, this message translates to:
  /// **'No folder'**
  String get noFolderLink;

  /// No description provided for @blockDuration.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String blockDuration(int minutes);

  /// No description provided for @nowOn.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowOn;

  /// No description provided for @nowLesson.
  ///
  /// In en, this message translates to:
  /// **'Now: {subject} ({when})'**
  String nowLesson(String subject, String when);

  /// No description provided for @nowLessonShort.
  ///
  /// In en, this message translates to:
  /// **'Now: {subject}'**
  String nowLessonShort(String subject);

  /// No description provided for @newInfiniteDocument.
  ///
  /// In en, this message translates to:
  /// **'Endless document'**
  String get newInfiniteDocument;

  /// No description provided for @untitledInfinite.
  ///
  /// In en, this message translates to:
  /// **'Endless canvas'**
  String get untitledInfinite;

  /// No description provided for @pageModeHint.
  ///
  /// In en, this message translates to:
  /// **'Classic pages you can flip through'**
  String get pageModeHint;

  /// No description provided for @infiniteDocumentShortHint.
  ///
  /// In en, this message translates to:
  /// **'Huge board, extreme zoom in and out'**
  String get infiniteDocumentShortHint;

  /// No description provided for @markFavorite.
  ///
  /// In en, this message translates to:
  /// **'Mark as favorite'**
  String get markFavorite;

  /// No description provided for @editFolder.
  ///
  /// In en, this message translates to:
  /// **'Edit folder'**
  String get editFolder;

  /// No description provided for @deleteFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete folder?'**
  String get deleteFolderTitle;

  /// No description provided for @deleteFolderBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed. Notebooks inside stay available in the library root.'**
  String deleteFolderBody(String name);

  /// No description provided for @folderActions.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folderActions;

  /// No description provided for @folderIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get folderIcon;

  /// No description provided for @newFolderHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a color and icon'**
  String get newFolderHint;

  /// No description provided for @newNotebookHint.
  ///
  /// In en, this message translates to:
  /// **'Paged notebook with cover and template'**
  String get newNotebookHint;

  /// No description provided for @newDeckHint.
  ///
  /// In en, this message translates to:
  /// **'Flashcards with a custom color'**
  String get newDeckHint;

  /// No description provided for @planner.
  ///
  /// In en, this message translates to:
  /// **'Grades & calendar'**
  String get planner;

  /// No description provided for @plannerEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add appointments and grades'**
  String get plannerEmptyHint;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @grades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get grades;

  /// No description provided for @addAppointment.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get addAppointment;

  /// No description provided for @editAppointment.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get editAppointment;

  /// No description provided for @addGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get addGrade;

  /// No description provided for @editGrade.
  ///
  /// In en, this message translates to:
  /// **'Edit grade'**
  String get editGrade;

  /// No description provided for @appointmentsOnDay.
  ///
  /// In en, this message translates to:
  /// **'Events on {day}'**
  String appointmentsOnDay(String day);

  /// No description provided for @noAppointmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No events on this day yet.'**
  String get noAppointmentsYet;

  /// No description provided for @noGradesYet.
  ///
  /// In en, this message translates to:
  /// **'No grades yet — pick a subject and add one.'**
  String get noGradesYet;

  /// No description provided for @gradeAverage.
  ///
  /// In en, this message translates to:
  /// **'Average (weighted)'**
  String get gradeAverage;

  /// No description provided for @gradeAverageShort.
  ///
  /// In en, this message translates to:
  /// **'Avg {value}'**
  String gradeAverageShort(String value);

  /// No description provided for @gradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get gradeTitle;

  /// No description provided for @gradeTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Midterm 2'**
  String get gradeTitleHint;

  /// No description provided for @gradeValue.
  ///
  /// In en, this message translates to:
  /// **'Grade / value'**
  String get gradeValue;

  /// No description provided for @gradeWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get gradeWeight;

  /// No description provided for @scaleGerman.
  ///
  /// In en, this message translates to:
  /// **'1–6'**
  String get scaleGerman;

  /// No description provided for @scalePercent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get scalePercent;

  /// No description provided for @scalePoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get scalePoints;

  /// No description provided for @kindAppointment.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get kindAppointment;

  /// No description provided for @kindExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get kindExam;

  /// No description provided for @kindHomework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get kindHomework;

  /// No description provided for @startsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get startsAt;

  /// No description provided for @endsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get endsAt;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @saturdayShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturdayShort;

  /// No description provided for @sundayShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sundayShort;

  /// No description provided for @shareAppointment.
  ///
  /// In en, this message translates to:
  /// **'Forward appointment'**
  String get shareAppointment;

  /// No description provided for @shareAppointmentHint.
  ///
  /// In en, this message translates to:
  /// **'Copy text into chat or mail. ICS works with calendar apps.'**
  String get shareAppointmentHint;

  /// No description provided for @copyForForward.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyForForward;

  /// No description provided for @copiedForForward.
  ///
  /// In en, this message translates to:
  /// **'Copied — ready to forward'**
  String get copiedForForward;

  /// No description provided for @copyIcs.
  ///
  /// In en, this message translates to:
  /// **'Copy as calendar (.ics)'**
  String get copyIcs;

  /// No description provided for @icsCopied.
  ///
  /// In en, this message translates to:
  /// **'ICS text copied'**
  String get icsCopied;

  /// No description provided for @schoolSection.
  ///
  /// In en, this message translates to:
  /// **'School & studies'**
  String get schoolSection;

  /// No description provided for @educationLevel.
  ///
  /// In en, this message translates to:
  /// **'Education level'**
  String get educationLevel;

  /// No description provided for @educationLevelHint.
  ///
  /// In en, this message translates to:
  /// **'Grade scale and labels.'**
  String get educationLevelHint;

  /// No description provided for @eduSek1.
  ///
  /// In en, this message translates to:
  /// **'Lower sec.'**
  String get eduSek1;

  /// No description provided for @eduSek2.
  ///
  /// In en, this message translates to:
  /// **'Upper sec.'**
  String get eduSek2;

  /// No description provided for @eduUniversity.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get eduUniversity;

  /// No description provided for @eduScaleGradesHint.
  ///
  /// In en, this message translates to:
  /// **'Calculated with grades (1–6).'**
  String get eduScaleGradesHint;

  /// No description provided for @eduScalePointsHint.
  ///
  /// In en, this message translates to:
  /// **'Calculated with points.'**
  String get eduScalePointsHint;

  /// No description provided for @eduScaleSek1Hint.
  ///
  /// In en, this message translates to:
  /// **'Grades 1–6 · half-years · written/oral weighting.'**
  String get eduScaleSek1Hint;

  /// No description provided for @eduScaleSek2Hint.
  ///
  /// In en, this message translates to:
  /// **'0–15 points · Q1–Q4 + exams · 900-point projection.'**
  String get eduScaleSek2Hint;

  /// No description provided for @eduScaleUniHint.
  ///
  /// In en, this message translates to:
  /// **'Grades 1.0–5.0 · ECTS-weighted GPA.'**
  String get eduScaleUniHint;

  /// No description provided for @gradeKindWritten.
  ///
  /// In en, this message translates to:
  /// **'Written'**
  String get gradeKindWritten;

  /// No description provided for @gradeKindOral.
  ///
  /// In en, this message translates to:
  /// **'Oral'**
  String get gradeKindOral;

  /// No description provided for @gradeKindOtherParticipation.
  ///
  /// In en, this message translates to:
  /// **'Other participation'**
  String get gradeKindOtherParticipation;

  /// No description provided for @gradeKindKlassenarbeit.
  ///
  /// In en, this message translates to:
  /// **'Class test'**
  String get gradeKindKlassenarbeit;

  /// No description provided for @periodH1.
  ///
  /// In en, this message translates to:
  /// **'1st half-year'**
  String get periodH1;

  /// No description provided for @periodH2.
  ///
  /// In en, this message translates to:
  /// **'2nd half-year'**
  String get periodH2;

  /// No description provided for @periodQ1.
  ///
  /// In en, this message translates to:
  /// **'Q1'**
  String get periodQ1;

  /// No description provided for @periodQ2.
  ///
  /// In en, this message translates to:
  /// **'Q2'**
  String get periodQ2;

  /// No description provided for @periodQ3.
  ///
  /// In en, this message translates to:
  /// **'Q3'**
  String get periodQ3;

  /// No description provided for @periodQ4.
  ///
  /// In en, this message translates to:
  /// **'Q4'**
  String get periodQ4;

  /// No description provided for @periodAbiExam.
  ///
  /// In en, this message translates to:
  /// **'Final exams'**
  String get periodAbiExam;

  /// No description provided for @periodSemester.
  ///
  /// In en, this message translates to:
  /// **'Semester'**
  String get periodSemester;

  /// No description provided for @abiPrognosisTitle.
  ///
  /// In en, this message translates to:
  /// **'Abitur projection'**
  String get abiPrognosisTitle;

  /// No description provided for @abiProjectedPoints.
  ///
  /// In en, this message translates to:
  /// **'Projection: {points} / 900'**
  String abiProjectedPoints(String points);

  /// No description provided for @abiProjectedNote.
  ///
  /// In en, this message translates to:
  /// **'Projected grade: {note}'**
  String abiProjectedNote(String note);

  /// No description provided for @abiMinPassProgress.
  ///
  /// In en, this message translates to:
  /// **'Minimum points: {have} / {need}'**
  String abiMinPassProgress(String have, String need);

  /// No description provided for @abiBlockProgress.
  ///
  /// In en, this message translates to:
  /// **'After {blocks}/5 blocks · avg {avg} points'**
  String abiBlockProgress(int blocks, String avg);

  /// No description provided for @uniPrognosisTitle.
  ///
  /// In en, this message translates to:
  /// **'Study progress'**
  String get uniPrognosisTitle;

  /// No description provided for @uniGpa.
  ///
  /// In en, this message translates to:
  /// **'ECTS GPA: {gpa}'**
  String uniGpa(String gpa);

  /// No description provided for @uniEctsProgress.
  ///
  /// In en, this message translates to:
  /// **'{have} / {need} ECTS'**
  String uniEctsProgress(String have, String need);

  /// No description provided for @ectsLabel.
  ///
  /// In en, this message translates to:
  /// **'ECTS'**
  String get ectsLabel;

  /// No description provided for @semesterLabelField.
  ///
  /// In en, this message translates to:
  /// **'Semester (e.g. WiSe 25/26)'**
  String get semesterLabelField;

  /// No description provided for @markAbiSubject.
  ///
  /// In en, this message translates to:
  /// **'Abitur subject (for exam projection)'**
  String get markAbiSubject;

  /// No description provided for @targetEcts.
  ///
  /// In en, this message translates to:
  /// **'Target ECTS'**
  String get targetEcts;

  /// No description provided for @targetEctsHint.
  ///
  /// In en, this message translates to:
  /// **'Credit points required for graduation.'**
  String get targetEctsHint;

  /// No description provided for @abiProjectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Abitur projection'**
  String get abiProjectionSettings;

  /// No description provided for @abiProjectionHint.
  ///
  /// In en, this message translates to:
  /// **'Course count (block I) and exams (block II).'**
  String get abiProjectionHint;

  /// No description provided for @abiCourseCount.
  ///
  /// In en, this message translates to:
  /// **'Courses in block I'**
  String get abiCourseCount;

  /// No description provided for @abiExams4.
  ///
  /// In en, this message translates to:
  /// **'4 exams'**
  String get abiExams4;

  /// No description provided for @abiExams5.
  ///
  /// In en, this message translates to:
  /// **'5 exams'**
  String get abiExams5;

  /// No description provided for @roundedPoints.
  ///
  /// In en, this message translates to:
  /// **'Rounded: {points} pts'**
  String roundedPoints(String points);

  /// No description provided for @gradeValueUni.
  ///
  /// In en, this message translates to:
  /// **'Grade (1.0–5.0)'**
  String get gradeValueUni;

  /// No description provided for @gradeValuePoints15.
  ///
  /// In en, this message translates to:
  /// **'Points (0–15)'**
  String get gradeValuePoints15;

  /// No description provided for @gradeTendency.
  ///
  /// In en, this message translates to:
  /// **'Tendency'**
  String get gradeTendency;

  /// No description provided for @gradeTendencyNone.
  ///
  /// In en, this message translates to:
  /// **'plain'**
  String get gradeTendencyNone;

  /// No description provided for @selectedGrade.
  ///
  /// In en, this message translates to:
  /// **'Selected: {grade}'**
  String selectedGrade(String grade);

  /// No description provided for @archivedGradesTitle.
  ///
  /// In en, this message translates to:
  /// **'Other levels (archive)'**
  String get archivedGradesTitle;

  /// No description provided for @archivedGradesHint.
  ///
  /// In en, this message translates to:
  /// **'Grades from lower/upper secondary or uni stay saved — listed here.'**
  String get archivedGradesHint;

  /// No description provided for @editingArchivedGrade.
  ///
  /// In en, this message translates to:
  /// **'Archived grade ({level})'**
  String editingArchivedGrade(String level);

  /// No description provided for @scanAttachment.
  ///
  /// In en, this message translates to:
  /// **'Scan worksheet'**
  String get scanAttachment;

  /// No description provided for @scanAttachmentHint.
  ///
  /// In en, this message translates to:
  /// **'Attach a photo/scan of a test or exam to this grade.'**
  String get scanAttachmentHint;

  /// No description provided for @scanAdd.
  ///
  /// In en, this message translates to:
  /// **'Add scan'**
  String get scanAdd;

  /// No description provided for @scanWithCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get scanWithCamera;

  /// No description provided for @scanFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery / file'**
  String get scanFromGallery;

  /// No description provided for @scanPage.
  ///
  /// In en, this message translates to:
  /// **'Scan {n}'**
  String scanPage(int n);

  /// No description provided for @scanCount.
  ///
  /// In en, this message translates to:
  /// **'{count} scans'**
  String scanCount(int count);

  /// No description provided for @gradesSectionsHint.
  ///
  /// In en, this message translates to:
  /// **'Grades stay when you switch levels.'**
  String get gradesSectionsHint;

  /// No description provided for @schoolYear.
  ///
  /// In en, this message translates to:
  /// **'School year'**
  String get schoolYear;

  /// No description provided for @previousSchoolYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get previousSchoolYear;

  /// No description provided for @nextSchoolYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get nextSchoolYear;

  /// No description provided for @gradesEmptyYear.
  ///
  /// In en, this message translates to:
  /// **'No grades in {year} yet.'**
  String gradesEmptyYear(String year);

  /// No description provided for @gradeDetails.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get gradeDetails;

  /// No description provided for @viewMode.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewMode;

  /// No description provided for @noScansAttached.
  ///
  /// In en, this message translates to:
  /// **'No scan attached.'**
  String get noScansAttached;

  /// No description provided for @semesterShort.
  ///
  /// In en, this message translates to:
  /// **'Semester'**
  String get semesterShort;

  /// No description provided for @federalState.
  ///
  /// In en, this message translates to:
  /// **'Federal state'**
  String get federalState;

  /// No description provided for @federalStateHint.
  ///
  /// In en, this message translates to:
  /// **'Used to show school holidays in the calendar.'**
  String get federalStateHint;

  /// No description provided for @stateBw.
  ///
  /// In en, this message translates to:
  /// **'Baden-Württemberg'**
  String get stateBw;

  /// No description provided for @stateBy.
  ///
  /// In en, this message translates to:
  /// **'Bavaria'**
  String get stateBy;

  /// No description provided for @stateBe.
  ///
  /// In en, this message translates to:
  /// **'Berlin'**
  String get stateBe;

  /// No description provided for @stateBb.
  ///
  /// In en, this message translates to:
  /// **'Brandenburg'**
  String get stateBb;

  /// No description provided for @stateHb.
  ///
  /// In en, this message translates to:
  /// **'Bremen'**
  String get stateHb;

  /// No description provided for @stateHh.
  ///
  /// In en, this message translates to:
  /// **'Hamburg'**
  String get stateHh;

  /// No description provided for @stateHe.
  ///
  /// In en, this message translates to:
  /// **'Hesse'**
  String get stateHe;

  /// No description provided for @stateMv.
  ///
  /// In en, this message translates to:
  /// **'Mecklenburg-Western Pomerania'**
  String get stateMv;

  /// No description provided for @stateNi.
  ///
  /// In en, this message translates to:
  /// **'Lower Saxony'**
  String get stateNi;

  /// No description provided for @stateNw.
  ///
  /// In en, this message translates to:
  /// **'North Rhine-Westphalia'**
  String get stateNw;

  /// No description provided for @stateRp.
  ///
  /// In en, this message translates to:
  /// **'Rhineland-Palatinate'**
  String get stateRp;

  /// No description provided for @stateSl.
  ///
  /// In en, this message translates to:
  /// **'Saarland'**
  String get stateSl;

  /// No description provided for @stateSn.
  ///
  /// In en, this message translates to:
  /// **'Saxony'**
  String get stateSn;

  /// No description provided for @stateSt.
  ///
  /// In en, this message translates to:
  /// **'Saxony-Anhalt'**
  String get stateSt;

  /// No description provided for @stateSh.
  ///
  /// In en, this message translates to:
  /// **'Schleswig-Holstein'**
  String get stateSh;

  /// No description provided for @stateTh.
  ///
  /// In en, this message translates to:
  /// **'Thuringia'**
  String get stateTh;

  /// No description provided for @holidayAutumn.
  ///
  /// In en, this message translates to:
  /// **'Autumn break'**
  String get holidayAutumn;

  /// No description provided for @holidayChristmas.
  ///
  /// In en, this message translates to:
  /// **'Christmas break'**
  String get holidayChristmas;

  /// No description provided for @holidayWinter.
  ///
  /// In en, this message translates to:
  /// **'Winter break'**
  String get holidayWinter;

  /// No description provided for @holidayEaster.
  ///
  /// In en, this message translates to:
  /// **'Easter break'**
  String get holidayEaster;

  /// No description provided for @holidayPentecost.
  ///
  /// In en, this message translates to:
  /// **'Pentecost break'**
  String get holidayPentecost;

  /// No description provided for @holidaySummer.
  ///
  /// In en, this message translates to:
  /// **'Summer break'**
  String get holidaySummer;

  /// No description provided for @holidaysForState.
  ///
  /// In en, this message translates to:
  /// **'Holidays: {state}'**
  String holidaysForState(String state);

  /// No description provided for @holidayBanner.
  ///
  /// In en, this message translates to:
  /// **'Holiday: {name}'**
  String holidayBanner(String name);

  /// No description provided for @gradeKindKlausur.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get gradeKindKlausur;

  /// No description provided for @gradeKindTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get gradeKindTest;

  /// No description provided for @gradeKindUniExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get gradeKindUniExam;

  /// No description provided for @gradeKindHomework.
  ///
  /// In en, this message translates to:
  /// **'Coursework'**
  String get gradeKindHomework;

  /// No description provided for @subjectFromTimetableDay.
  ///
  /// In en, this message translates to:
  /// **'Subject from timetable (this weekday)'**
  String get subjectFromTimetableDay;

  /// No description provided for @subjectFromTimetableWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend — no timetable day'**
  String get subjectFromTimetableWeekend;

  /// No description provided for @noSubjectsThatDay.
  ///
  /// In en, this message translates to:
  /// **'No subjects on the timetable for this day.'**
  String get noSubjectsThatDay;

  /// No description provided for @gradesNeedTimetable.
  ///
  /// In en, this message translates to:
  /// **'Add subjects in the timetable first.'**
  String get gradesNeedTimetable;

  /// No description provided for @weightForSubject.
  ///
  /// In en, this message translates to:
  /// **'Weighting: {subject}'**
  String weightForSubject(String subject);

  /// No description provided for @weightHint.
  ///
  /// In en, this message translates to:
  /// **'Set {major} vs {minor} once — Notan-style.'**
  String weightHint(String major, String minor);

  /// No description provided for @weightSummary.
  ///
  /// In en, this message translates to:
  /// **'{major} {majorPct}% · {minor} {minorPct}%'**
  String weightSummary(String major, int majorPct, String minor, int minorPct);

  /// No description provided for @setWeight.
  ///
  /// In en, this message translates to:
  /// **'Weighting'**
  String get setWeight;

  /// No description provided for @gradeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} grades'**
  String gradeCount(int count);

  /// No description provided for @gradeValuePoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get gradeValuePoints;

  /// No description provided for @sectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get sectionGeneral;

  /// No description provided for @sectionSubscription.
  ///
  /// In en, this message translates to:
  /// **'Plan & coins'**
  String get sectionSubscription;

  /// No description provided for @sectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get sectionSupport;

  /// No description provided for @sectionSyncPreview.
  ///
  /// In en, this message translates to:
  /// **'Sync (preview)'**
  String get sectionSyncPreview;

  /// No description provided for @localTierHint.
  ///
  /// In en, this message translates to:
  /// **'Local testing only — no real purchases.'**
  String get localTierHint;

  /// No description provided for @tierFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get tierFree;

  /// No description provided for @tierPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get tierPro;

  /// No description provided for @tierProPlus.
  ///
  /// In en, this message translates to:
  /// **'Pro+'**
  String get tierProPlus;

  /// No description provided for @tierTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get tierTeacher;

  /// No description provided for @coinsBalance.
  ///
  /// In en, this message translates to:
  /// **'{count} coins'**
  String coinsBalance(int count);

  /// No description provided for @watchAdForCoins.
  ///
  /// In en, this message translates to:
  /// **'Watch ad'**
  String get watchAdForCoins;

  /// No description provided for @watchRewardedAd.
  ///
  /// In en, this message translates to:
  /// **'Watch short video'**
  String get watchRewardedAd;

  /// No description provided for @rewardedAdDemoBadge.
  ///
  /// In en, this message translates to:
  /// **'Demo — not a real ad'**
  String get rewardedAdDemoBadge;

  /// No description provided for @rewardedAdTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock reward'**
  String get rewardedAdTitle;

  /// No description provided for @rewardedAdCoinsBody.
  ///
  /// In en, this message translates to:
  /// **'After the demo clip you’ll get {count} coins.'**
  String rewardedAdCoinsBody(int count);

  /// No description provided for @rewardedAdFeatureBody.
  ///
  /// In en, this message translates to:
  /// **'After the demo clip this feature will unlock.'**
  String get rewardedAdFeatureBody;

  /// No description provided for @adPrivacyOptions.
  ///
  /// In en, this message translates to:
  /// **'Ad settings'**
  String get adPrivacyOptions;

  /// No description provided for @adPrivacyOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Change your consent for personalised ads'**
  String get adPrivacyOptionsHint;

  /// No description provided for @rewardedAdLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading ad …'**
  String get rewardedAdLoading;

  /// No description provided for @rewardedAdNotFinished.
  ///
  /// In en, this message translates to:
  /// **'Video was not watched to the end — no reward.'**
  String get rewardedAdNotFinished;

  /// No description provided for @featureUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Feature unlocked'**
  String get featureUnlocked;

  /// No description provided for @collaborationSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in for cloud collaboration.'**
  String get collaborationSignInRequired;

  /// No description provided for @collaborationUpgradeRequired.
  ///
  /// In en, this message translates to:
  /// **'Cloud collaboration requires an eligible plan.'**
  String get collaborationUpgradeRequired;

  /// No description provided for @collabLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby (no account)'**
  String get collabLocalTitle;

  /// No description provided for @collabLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Share this notebook over Wi‑Fi or a hotspot. Works completely offline — no sign-in needed.'**
  String get collabLocalBody;

  /// No description provided for @collabCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud collaboration'**
  String get collabCloudTitle;

  /// No description provided for @collabCloudBody.
  ///
  /// In en, this message translates to:
  /// **'Invite someone by Firebase UID. Role controls whether they can edit or only read.'**
  String get collabCloudBody;

  /// No description provided for @collabMemberUid.
  ///
  /// In en, this message translates to:
  /// **'Firebase UID'**
  String get collabMemberUid;

  /// No description provided for @collabRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get collabRole;

  /// No description provided for @collabSaveInvite.
  ///
  /// In en, this message translates to:
  /// **'Save invitation'**
  String get collabSaveInvite;

  /// No description provided for @collabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get collabMembers;

  /// No description provided for @collabStartLive.
  ///
  /// In en, this message translates to:
  /// **'Start live session'**
  String get collabStartLive;

  /// No description provided for @collabLiveStarted.
  ///
  /// In en, this message translates to:
  /// **'Live session started: {id}'**
  String collabLiveStarted(String id);

  /// No description provided for @collabComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get collabComments;

  /// No description provided for @collabLeaveComment.
  ///
  /// In en, this message translates to:
  /// **'Leave a comment'**
  String get collabLeaveComment;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @coinsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{count} coins'**
  String coinsEarned(int count);

  /// No description provided for @notEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins'**
  String get notEnoughCoins;

  /// No description provided for @unlockWithCoins.
  ///
  /// In en, this message translates to:
  /// **'Unlock with {count} coins'**
  String unlockWithCoins(int count);

  /// No description provided for @featureAvailable.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get featureAvailable;

  /// No description provided for @featurePremiumPaper.
  ///
  /// In en, this message translates to:
  /// **'Premium paper'**
  String get featurePremiumPaper;

  /// No description provided for @featurePremiumCover.
  ///
  /// In en, this message translates to:
  /// **'Premium cover'**
  String get featurePremiumCover;

  /// No description provided for @featureAudioTranscription.
  ///
  /// In en, this message translates to:
  /// **'Audio transcription'**
  String get featureAudioTranscription;

  /// No description provided for @featurePdfCompress.
  ///
  /// In en, this message translates to:
  /// **'Compress PDF'**
  String get featurePdfCompress;

  /// No description provided for @featureHandwritingOcr.
  ///
  /// In en, this message translates to:
  /// **'Handwriting OCR'**
  String get featureHandwritingOcr;

  /// No description provided for @featureNoForcedAds.
  ///
  /// In en, this message translates to:
  /// **'No forced ads'**
  String get featureNoForcedAds;

  /// No description provided for @featureSessionCollab.
  ///
  /// In en, this message translates to:
  /// **'Session collab'**
  String get featureSessionCollab;

  /// No description provided for @featureAsyncCollab.
  ///
  /// In en, this message translates to:
  /// **'Cloud collab'**
  String get featureAsyncCollab;

  /// No description provided for @featureWhiteboard.
  ///
  /// In en, this message translates to:
  /// **'Teacher whiteboard'**
  String get featureWhiteboard;

  /// No description provided for @supportBody.
  ///
  /// In en, this message translates to:
  /// **'BetterNotes stays usable offline. A coffee helps cover future server costs.'**
  String get supportBody;

  /// No description provided for @supportBuyCoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy a coffee'**
  String get supportBuyCoffee;

  /// No description provided for @supportLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Support link copied'**
  String get supportLinkCopied;

  /// No description provided for @serverCostsLabel.
  ///
  /// In en, this message translates to:
  /// **'Server costs (placeholder): €{euro} / month'**
  String serverCostsLabel(int euro);

  /// No description provided for @serverCostsCovered.
  ///
  /// In en, this message translates to:
  /// **'Covered so far: €{euro}'**
  String serverCostsCovered(int euro);

  /// No description provided for @syncPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Preview — real cloud sync comes later.'**
  String get syncPreviewHint;

  /// No description provided for @upcomingNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upcomingNext;

  /// No description provided for @createGradeFromExam.
  ///
  /// In en, this message translates to:
  /// **'Add a grade?'**
  String get createGradeFromExam;

  /// No description provided for @createGradeFromExamBody.
  ///
  /// In en, this message translates to:
  /// **'Save the exam and prepare a grade with subject and date filled in.'**
  String get createGradeFromExamBody;

  /// No description provided for @deviceCalendarComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Device calendar sync is coming later.'**
  String get deviceCalendarComingSoon;

  /// No description provided for @sectionNotebooks.
  ///
  /// In en, this message translates to:
  /// **'Notebooks'**
  String get sectionNotebooks;

  /// No description provided for @exportExtras.
  ///
  /// In en, this message translates to:
  /// **'Export extras'**
  String get exportExtras;

  /// No description provided for @comingSoonGate.
  ///
  /// In en, this message translates to:
  /// **'Coming later — unlockable locally for now'**
  String get comingSoonGate;

  /// No description provided for @firebaseSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'Firebase has not been configured yet. Local data remains available.'**
  String get firebaseSetupRequired;

  /// No description provided for @cloudAccount.
  ///
  /// In en, this message translates to:
  /// **'Cloud account'**
  String get cloudAccount;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String signedInAs(String name);

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInGoogle;

  /// No description provided for @signInApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInApple;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @cloudSyncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline-first: without signing in, data stays on this device.'**
  String get cloudSyncOffline;

  /// No description provided for @cloudSyncError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {message}'**
  String cloudSyncError(String message);

  /// No description provided for @developerTools.
  ///
  /// In en, this message translates to:
  /// **'Developer tools'**
  String get developerTools;

  /// No description provided for @developerTierHint.
  ///
  /// In en, this message translates to:
  /// **'For local testing only — does not replace a store purchase.'**
  String get developerTierHint;

  /// No description provided for @editSupportDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit support details'**
  String get editSupportDetails;

  /// No description provided for @supportUrl.
  ///
  /// In en, this message translates to:
  /// **'Support link'**
  String get supportUrl;

  /// No description provided for @serverCosts.
  ///
  /// In en, this message translates to:
  /// **'Monthly server costs'**
  String get serverCosts;

  /// No description provided for @amountCovered.
  ///
  /// In en, this message translates to:
  /// **'Covered so far'**
  String get amountCovered;

  /// No description provided for @syncStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get syncStatusIdle;

  /// No description provided for @syncStatusUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get syncStatusUpToDate;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusFirebaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not configured'**
  String get syncStatusFirebaseNotConfigured;

  /// No description provided for @syncStatusAuthenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign-in required'**
  String get syncStatusAuthenticationRequired;

  /// No description provided for @syncStatusPreparingCloud.
  ///
  /// In en, this message translates to:
  /// **'Preparing cloud data'**
  String get syncStatusPreparingCloud;

  /// No description provided for @syncStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Sync paused'**
  String get syncStatusPaused;

  /// No description provided for @lockPage.
  ///
  /// In en, this message translates to:
  /// **'Lock page'**
  String get lockPage;

  /// No description provided for @unlockPage.
  ///
  /// In en, this message translates to:
  /// **'Unlock page'**
  String get unlockPage;

  /// No description provided for @pageLocked.
  ///
  /// In en, this message translates to:
  /// **'Page locked'**
  String get pageLocked;

  /// No description provided for @presentView.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get presentView;

  /// No description provided for @exitPresentView.
  ///
  /// In en, this message translates to:
  /// **'Exit presentation'**
  String get exitPresentView;

  /// No description provided for @exitPresentViewHint.
  ///
  /// In en, this message translates to:
  /// **'Double tap to exit the presentation'**
  String get exitPresentViewHint;

  /// No description provided for @dragToAddPage.
  ///
  /// In en, this message translates to:
  /// **'Drag to add a page'**
  String get dragToAddPage;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @fitPage.
  ///
  /// In en, this message translates to:
  /// **'Fit page'**
  String get fitPage;

  /// No description provided for @deselectTool.
  ///
  /// In en, this message translates to:
  /// **'Deselect tool'**
  String get deselectTool;

  /// No description provided for @pageSidebar.
  ///
  /// In en, this message translates to:
  /// **'Page overview'**
  String get pageSidebar;

  /// No description provided for @duplicatePage.
  ///
  /// In en, this message translates to:
  /// **'Duplicate page'**
  String get duplicatePage;

  /// No description provided for @deletePage.
  ///
  /// In en, this message translates to:
  /// **'Delete page'**
  String get deletePage;

  /// No description provided for @lastPageHint.
  ///
  /// In en, this message translates to:
  /// **'A notebook needs at least one page.'**
  String get lastPageHint;

  /// No description provided for @collaborate.
  ///
  /// In en, this message translates to:
  /// **'Collaborate'**
  String get collaborate;

  /// No description provided for @scrollDirection.
  ///
  /// In en, this message translates to:
  /// **'Scrolling direction'**
  String get scrollDirection;

  /// No description provided for @underline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get underline;

  /// No description provided for @strikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get strikethrough;

  /// No description provided for @increaseFontSize.
  ///
  /// In en, this message translates to:
  /// **'Increase font size'**
  String get increaseFontSize;

  /// No description provided for @decreaseFontSize.
  ///
  /// In en, this message translates to:
  /// **'Decrease font size'**
  String get decreaseFontSize;

  /// No description provided for @alignLeft.
  ///
  /// In en, this message translates to:
  /// **'Align left'**
  String get alignLeft;

  /// No description provided for @alignCenter.
  ///
  /// In en, this message translates to:
  /// **'Align center'**
  String get alignCenter;

  /// No description provided for @alignRight.
  ///
  /// In en, this message translates to:
  /// **'Align right'**
  String get alignRight;

  /// No description provided for @alignJustify.
  ///
  /// In en, this message translates to:
  /// **'Justify'**
  String get alignJustify;

  /// No description provided for @deleteTextBlock.
  ///
  /// In en, this message translates to:
  /// **'Delete text box'**
  String get deleteTextBlock;

  /// No description provided for @moveTextBlock.
  ///
  /// In en, this message translates to:
  /// **'Move text box'**
  String get moveTextBlock;

  /// No description provided for @studyMode.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get studyMode;

  /// No description provided for @studyModeHint.
  ///
  /// In en, this message translates to:
  /// **'Ink is hidden — double-tap or use Reveal to show it'**
  String get studyModeHint;

  /// No description provided for @exitStudyMode.
  ///
  /// In en, this message translates to:
  /// **'Exit study mode'**
  String get exitStudyMode;

  /// No description provided for @revealInk.
  ///
  /// In en, this message translates to:
  /// **'Reveal ink'**
  String get revealInk;

  /// No description provided for @hideInk.
  ///
  /// In en, this message translates to:
  /// **'Hide ink'**
  String get hideInk;

  /// No description provided for @saveSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Save snapshot'**
  String get saveSnapshot;

  /// No description provided for @restoreSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Restore snapshot'**
  String get restoreSnapshot;

  /// No description provided for @snapshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Snapshot saved'**
  String get snapshotSaved;

  /// No description provided for @snapshotRestored.
  ///
  /// In en, this message translates to:
  /// **'Snapshot restored'**
  String get snapshotRestored;

  /// No description provided for @noSnapshotsYet.
  ///
  /// In en, this message translates to:
  /// **'No snapshots for this page yet'**
  String get noSnapshotsYet;

  /// No description provided for @snapshotLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {time}'**
  String snapshotLabel(String time);

  /// No description provided for @deleteSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Delete snapshot'**
  String get deleteSnapshot;

  /// No description provided for @confirmRestoreSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Restore this snapshot? Current page content will be replaced.'**
  String get confirmRestoreSnapshot;

  /// No description provided for @nearbySyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby sync'**
  String get nearbySyncTitle;

  /// No description provided for @nearbySyncIntro.
  ///
  /// In en, this message translates to:
  /// **'Share this notebook over the same Wi‑Fi or a phone hotspot. The first transfer sends the whole notebook; afterwards only changes are exchanged — no internet required.'**
  String get nearbySyncIntro;

  /// No description provided for @nearbySyncDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get nearbySyncDeviceName;

  /// No description provided for @nearbySyncHostSection.
  ///
  /// In en, this message translates to:
  /// **'Host this notebook'**
  String get nearbySyncHostSection;

  /// No description provided for @nearbySyncHostHint.
  ///
  /// In en, this message translates to:
  /// **'Start hosting, then tell the other device your IP address and session code. Both devices must be on the same network or hotspot.'**
  String get nearbySyncHostHint;

  /// No description provided for @nearbySyncStartHost.
  ///
  /// In en, this message translates to:
  /// **'Start nearby session'**
  String get nearbySyncStartHost;

  /// No description provided for @nearbySyncJoinSection.
  ///
  /// In en, this message translates to:
  /// **'Join a session'**
  String get nearbySyncJoinSection;

  /// No description provided for @nearbySyncJoinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the host IP and the 6-character code shown on the other device.'**
  String get nearbySyncJoinHint;

  /// No description provided for @nearbySyncHostAddress.
  ///
  /// In en, this message translates to:
  /// **'Host IP address'**
  String get nearbySyncHostAddress;

  /// No description provided for @nearbySyncCode.
  ///
  /// In en, this message translates to:
  /// **'Session code'**
  String get nearbySyncCode;

  /// No description provided for @nearbySyncJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get nearbySyncJoin;

  /// No description provided for @nearbySyncStop.
  ///
  /// In en, this message translates to:
  /// **'Stop session'**
  String get nearbySyncStop;

  /// No description provided for @nearbySyncCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get nearbySyncCopy;

  /// No description provided for @nearbySyncCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get nearbySyncCopied;

  /// No description provided for @nearbySyncPort.
  ///
  /// In en, this message translates to:
  /// **'Port {port}'**
  String nearbySyncPort(int port);

  /// No description provided for @nearbySyncNoAddress.
  ///
  /// In en, this message translates to:
  /// **'No local IP found yet. Connect to Wi‑Fi or enable a hotspot, then reopen this screen.'**
  String get nearbySyncNoAddress;

  /// No description provided for @nearbySyncStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'No nearby session'**
  String get nearbySyncStatusIdle;

  /// No description provided for @nearbySyncStatusHosting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for devices…'**
  String get nearbySyncStatusHosting;

  /// No description provided for @nearbySyncStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get nearbySyncStatusConnecting;

  /// No description provided for @nearbySyncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Transferring notebook…'**
  String get nearbySyncStatusSyncing;

  /// No description provided for @nearbySyncStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Nearby sync active'**
  String get nearbySyncStatusConnected;

  /// No description provided for @nearbySyncStatusError.
  ///
  /// In en, this message translates to:
  /// **'Nearby sync error'**
  String get nearbySyncStatusError;

  /// No description provided for @nearbySyncPeer.
  ///
  /// In en, this message translates to:
  /// **'Peer: {name}'**
  String nearbySyncPeer(String name);

  /// No description provided for @nearbySyncPeers.
  ///
  /// In en, this message translates to:
  /// **'{count} connected'**
  String nearbySyncPeers(int count);

  /// No description provided for @nearbySyncSnapshotReceived.
  ///
  /// In en, this message translates to:
  /// **'Notebook received — opening…'**
  String get nearbySyncSnapshotReceived;

  /// No description provided for @nearbySyncWebUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Nearby sync needs the Android or iOS app.'**
  String get nearbySyncWebUnsupported;

  /// No description provided for @nearbySyncDisconnected.
  ///
  /// In en, this message translates to:
  /// **'The other device disconnected.'**
  String get nearbySyncDisconnected;

  /// No description provided for @nearbySyncInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Wrong session code.'**
  String get nearbySyncInvalidCode;

  /// No description provided for @nearbySyncError.
  ///
  /// In en, this message translates to:
  /// **'Nearby sync failed'**
  String get nearbySyncError;

  /// No description provided for @nearbySyncBinaryNote.
  ///
  /// In en, this message translates to:
  /// **'PDF backgrounds and inserted images are transferred over the air with the notebook. Both devices must stay on the same Wi‑Fi or hotspot.'**
  String get nearbySyncBinaryNote;

  /// No description provided for @nearbySyncDiscoverHint.
  ///
  /// In en, this message translates to:
  /// **'Devices hosting a nearby session appear automatically. Tap one to join.'**
  String get nearbySyncDiscoverHint;

  /// No description provided for @nearbySyncSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching on this network…'**
  String get nearbySyncSearching;

  /// No description provided for @nearbySyncSearchStopped.
  ///
  /// In en, this message translates to:
  /// **'Search paused'**
  String get nearbySyncSearchStopped;

  /// No description provided for @nearbySyncStartSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get nearbySyncStartSearch;

  /// No description provided for @nearbySyncStopSearch.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get nearbySyncStopSearch;

  /// No description provided for @nearbySyncNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No nearby hosts found yet. Ask the other device to start hosting.'**
  String get nearbySyncNoDevices;

  /// No description provided for @nearbySyncManualJoin.
  ///
  /// In en, this message translates to:
  /// **'Join manually (IP + code)'**
  String get nearbySyncManualJoin;

  /// No description provided for @nearbySyncJoinManual.
  ///
  /// In en, this message translates to:
  /// **'Join with IP'**
  String get nearbySyncJoinManual;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @impressum.
  ///
  /// In en, this message translates to:
  /// **'Legal notice'**
  String get impressum;

  /// No description provided for @legalSection.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalSection;

  /// No description provided for @openLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openLicenses;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String appVersion(String version, String build);

  /// No description provided for @flashcardAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get flashcardAgain;

  /// No description provided for @flashcardHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get flashcardHard;

  /// No description provided for @flashcardGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get flashcardGood;

  /// No description provided for @flashcardEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get flashcardEasy;

  /// No description provided for @flashcardStudy.
  ///
  /// In en, this message translates to:
  /// **'Study due cards'**
  String get flashcardStudy;

  /// No description provided for @flashcardBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse deck'**
  String get flashcardBrowse;

  /// No description provided for @flashcardSessionDone.
  ///
  /// In en, this message translates to:
  /// **'You\'re caught up for now'**
  String get flashcardSessionDone;

  /// No description provided for @flashcardReviewedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cards reviewed'**
  String flashcardReviewedCount(int count);

  /// No description provided for @flashcardStudyAll.
  ///
  /// In en, this message translates to:
  /// **'Study all cards'**
  String get flashcardStudyAll;

  /// No description provided for @flashcardDueProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {remaining} left · {due} due today'**
  String flashcardDueProgress(int current, int remaining, int due);

  /// No description provided for @flashcardFlipToRate.
  ///
  /// In en, this message translates to:
  /// **'Flip the card to rate how well you knew it'**
  String get flashcardFlipToRate;

  /// No description provided for @importIntoNotebook.
  ///
  /// In en, this message translates to:
  /// **'Import into notebook'**
  String get importIntoNotebook;

  /// No description provided for @importPickNotebookHint.
  ///
  /// In en, this message translates to:
  /// **'Choose where the shared file should be added as new page(s).'**
  String get importPickNotebookHint;

  /// No description provided for @importCreateNotebook.
  ///
  /// In en, this message translates to:
  /// **'Create new notebook'**
  String get importCreateNotebook;

  /// No description provided for @importNewNotebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get importNewNotebookTitle;

  /// No description provided for @importAddFiles.
  ///
  /// In en, this message translates to:
  /// **'Add files'**
  String get importAddFiles;

  /// No description provided for @importAddFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Pick PDF, images, Office, GoodNotes, or ZIP files'**
  String get importAddFilesHint;

  /// No description provided for @importNoFilesYet.
  ///
  /// In en, this message translates to:
  /// **'No files ready to import'**
  String get importNoFilesYet;

  /// No description provided for @importExistingNotebooks.
  ///
  /// In en, this message translates to:
  /// **'Existing notebooks'**
  String get importExistingNotebooks;

  /// No description provided for @importingFiles.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importingFiles;

  /// No description provided for @importAnyFile.
  ///
  /// In en, this message translates to:
  /// **'Import file'**
  String get importAnyFile;

  /// No description provided for @exportPageAsImage.
  ///
  /// In en, this message translates to:
  /// **'Export page as image'**
  String get exportPageAsImage;

  /// No description provided for @exportPdfForGoodNotes.
  ///
  /// In en, this message translates to:
  /// **'PDF for GoodNotes'**
  String get exportPdfForGoodNotes;

  /// No description provided for @exportPdfForGoodNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Import this PDF in GoodNotes'**
  String get exportPdfForGoodNotesHint;

  /// No description provided for @backupSection.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupSection;

  /// No description provided for @backupSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Export a ZIP of notebooks, pages, flashcards, grades, and timetable — or restore from a previous backup.'**
  String get backupSectionHint;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export backup ZIP'**
  String get backupExport;

  /// No description provided for @backupExportHint.
  ///
  /// In en, this message translates to:
  /// **'Share or save a full backup'**
  String get backupExportHint;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from ZIP'**
  String get backupRestore;

  /// No description provided for @backupRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Merge into or replace local data'**
  String get backupRestoreHint;

  /// No description provided for @backupRestoreMergeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Merge into existing data, or replace notebooks and decks?'**
  String get backupRestoreMergeQuestion;

  /// No description provided for @backupMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get backupMerge;

  /// No description provided for @backupReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get backupReplace;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} notebooks'**
  String backupRestored(int count);

  /// No description provided for @noteToFlashcard.
  ///
  /// In en, this message translates to:
  /// **'Make flashcard'**
  String get noteToFlashcard;

  /// No description provided for @flashcardCreated.
  ///
  /// In en, this message translates to:
  /// **'Flashcard saved'**
  String get flashcardCreated;

  /// No description provided for @pomodoroFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get pomodoroFocus;

  /// No description provided for @pomodoroBreak.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get pomodoroBreak;

  /// No description provided for @pomodoroStart.
  ///
  /// In en, this message translates to:
  /// **'Start timer'**
  String get pomodoroStart;

  /// No description provided for @pomodoroPause.
  ///
  /// In en, this message translates to:
  /// **'Pause timer'**
  String get pomodoroPause;

  /// No description provided for @pomodoroReset.
  ///
  /// In en, this message translates to:
  /// **'Reset timer'**
  String get pomodoroReset;

  /// No description provided for @notebookSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get notebookSubject;

  /// No description provided for @notebookSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Links to timetable & grades'**
  String get notebookSubjectHint;

  /// No description provided for @openLinkedNotebook.
  ///
  /// In en, this message translates to:
  /// **'Open notebook'**
  String get openLinkedNotebook;

  /// No description provided for @createNotebookForSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'No notebook is linked to this subject yet. Create one?'**
  String get createNotebookForSubjectHint;

  /// No description provided for @csvExportFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get csvExportFlashcards;

  /// No description provided for @csvImportFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get csvImportFlashcards;

  /// No description provided for @csvExportGrades.
  ///
  /// In en, this message translates to:
  /// **'Export grades CSV'**
  String get csvExportGrades;

  /// No description provided for @csvImportGrades.
  ///
  /// In en, this message translates to:
  /// **'Import grades CSV'**
  String get csvImportGrades;

  /// No description provided for @csvImportedCards.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} cards'**
  String csvImportedCards(int count);

  /// No description provided for @csvImportedGrades.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} grades'**
  String csvImportedGrades(int count);

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @homework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get homework;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @roleWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you use BetterNotes?'**
  String get roleWelcomeTitle;

  /// No description provided for @roleWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your role. Students get the existing study workspace; teachers also get classroom and material tools.'**
  String get roleWelcomeBody;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @roleStudentHint.
  ///
  /// In en, this message translates to:
  /// **'Notebooks, timetable, grades, flashcards, and study mode.'**
  String get roleStudentHint;

  /// No description provided for @roleTeacherHint.
  ///
  /// In en, this message translates to:
  /// **'Everything in the student workspace plus live classes, lesson planning, materials, and grade reports.'**
  String get roleTeacherHint;

  /// No description provided for @roleChooseStudent.
  ///
  /// In en, this message translates to:
  /// **'Start as student'**
  String get roleChooseStudent;

  /// No description provided for @roleChooseTeacher.
  ///
  /// In en, this message translates to:
  /// **'Start as teacher'**
  String get roleChooseTeacher;

  /// No description provided for @roleCanChangeLater.
  ///
  /// In en, this message translates to:
  /// **'You can change the role later in Settings.'**
  String get roleCanChangeLater;

  /// No description provided for @roleSection.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleSection;

  /// No description provided for @roleSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Your role controls which workspaces and options are shown.'**
  String get roleSectionHint;

  /// No description provided for @teacherWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Teacher workspace'**
  String get teacherWorkspace;

  /// No description provided for @teacherOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get teacherOverview;

  /// No description provided for @teacherOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare and run lessons efficiently'**
  String get teacherOverviewTitle;

  /// No description provided for @teacherOverviewHint.
  ///
  /// In en, this message translates to:
  /// **'Live sessions, assignments, lesson calendar, materials, and audio explanations in one place.'**
  String get teacherOverviewHint;

  /// No description provided for @teacherLiveClass.
  ///
  /// In en, this message translates to:
  /// **'Live class'**
  String get teacherLiveClass;

  /// No description provided for @teacherLiveClassHint.
  ///
  /// In en, this message translates to:
  /// **'Start a host-controlled session and manage writing, hands, focus, and progress.'**
  String get teacherLiveClassHint;

  /// No description provided for @teacherLessonJournal.
  ///
  /// In en, this message translates to:
  /// **'Lesson journal'**
  String get teacherLessonJournal;

  /// No description provided for @teacherMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get teacherMaterials;

  /// No description provided for @teacherGradeReport.
  ///
  /// In en, this message translates to:
  /// **'Grade report'**
  String get teacherGradeReport;

  /// No description provided for @teacherProfile.
  ///
  /// In en, this message translates to:
  /// **'Teacher profile'**
  String get teacherProfile;

  /// No description provided for @teacherAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio explanations'**
  String get teacherAudio;

  /// No description provided for @teacherAudioHint.
  ///
  /// In en, this message translates to:
  /// **'Record explanations locally, transcribe them, and share selectively.'**
  String get teacherAudioHint;

  /// No description provided for @teacherTrainee.
  ///
  /// In en, this message translates to:
  /// **'Teacher trainee special'**
  String get teacherTrainee;

  /// No description provided for @teacherTraineeHint.
  ///
  /// In en, this message translates to:
  /// **'Submit proof and request extended material access.'**
  String get teacherTraineeHint;

  /// No description provided for @teacherSessionActive.
  ///
  /// In en, this message translates to:
  /// **'Session {code} is active'**
  String teacherSessionActive(String code);

  /// No description provided for @teacherLessonCount.
  ///
  /// In en, this message translates to:
  /// **'{count} lesson plan entries'**
  String teacherLessonCount(int count);

  /// No description provided for @teacherMaterialCount.
  ///
  /// In en, this message translates to:
  /// **'{count} materials in your library'**
  String teacherMaterialCount(int count);

  /// No description provided for @teacherNewLesson.
  ///
  /// In en, this message translates to:
  /// **'New lesson'**
  String get teacherNewLesson;

  /// No description provided for @teacherStartSession.
  ///
  /// In en, this message translates to:
  /// **'Start session'**
  String get teacherStartSession;

  /// No description provided for @teacherWhiteboardNotebook.
  ///
  /// In en, this message translates to:
  /// **'Whiteboard notebook'**
  String get teacherWhiteboardNotebook;

  /// No description provided for @teacherAddParticipant.
  ///
  /// In en, this message translates to:
  /// **'Add participant'**
  String get teacherAddParticipant;

  /// No description provided for @teacherNoActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active class session'**
  String get teacherNoActiveSession;

  /// No description provided for @teacherJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Join code: {code}'**
  String teacherJoinCode(String code);

  /// No description provided for @teacherEndSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get teacherEndSession;

  /// No description provided for @teacherParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get teacherParticipants;

  /// No description provided for @teacherAverageProgress.
  ///
  /// In en, this message translates to:
  /// **'Average progress'**
  String get teacherAverageProgress;

  /// No description provided for @teacherFocusCheck.
  ///
  /// In en, this message translates to:
  /// **'Focus check'**
  String get teacherFocusCheck;

  /// No description provided for @teacherFocusCheckPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only reports whether BetterNotes is in the foreground during the session — never other apps or their content.'**
  String get teacherFocusCheckPrivacy;

  /// No description provided for @teacherWaitingParticipants.
  ///
  /// In en, this message translates to:
  /// **'Waiting for participants on the local network. You can add participants manually for testing.'**
  String get teacherWaitingParticipants;

  /// No description provided for @teacherFocused.
  ///
  /// In en, this message translates to:
  /// **'Active in BetterNotes'**
  String get teacherFocused;

  /// No description provided for @teacherLeftApp.
  ///
  /// In en, this message translates to:
  /// **'Left BetterNotes'**
  String get teacherLeftApp;

  /// No description provided for @teacherAllowWriting.
  ///
  /// In en, this message translates to:
  /// **'Toggle writing permission'**
  String get teacherAllowWriting;

  /// No description provided for @teacherMute.
  ///
  /// In en, this message translates to:
  /// **'Toggle mute'**
  String get teacherMute;

  /// No description provided for @teacherAddLesson.
  ///
  /// In en, this message translates to:
  /// **'Add lesson'**
  String get teacherAddLesson;

  /// No description provided for @teacherNoLessons.
  ///
  /// In en, this message translates to:
  /// **'No lessons in the sequence yet.'**
  String get teacherNoLessons;

  /// No description provided for @teacherCancelAndShift.
  ///
  /// In en, this message translates to:
  /// **'Cancel + shift'**
  String get teacherCancelAndShift;

  /// No description provided for @teacherAddMaterial.
  ///
  /// In en, this message translates to:
  /// **'Add material'**
  String get teacherAddMaterial;

  /// No description provided for @teacherDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Work time (minutes)'**
  String get teacherDurationMinutes;

  /// No description provided for @teacherMaterialSearch.
  ///
  /// In en, this message translates to:
  /// **'Filter by subject, grade, or title'**
  String get teacherMaterialSearch;

  /// No description provided for @teacherHybridDistribution.
  ///
  /// In en, this message translates to:
  /// **'Hybrid cloud distribution'**
  String get teacherHybridDistribution;

  /// No description provided for @teacherHybridDistributionHint.
  ///
  /// In en, this message translates to:
  /// **'Local files remain local. With configured cloud storage, only a small download command is sent to students.'**
  String get teacherHybridDistributionHint;

  /// No description provided for @teacherNoMaterials.
  ///
  /// In en, this message translates to:
  /// **'No materials yet. Add PDF, Office, or image files.'**
  String get teacherNoMaterials;

  /// No description provided for @teacherDistribute.
  ///
  /// In en, this message translates to:
  /// **'Distribute to class'**
  String get teacherDistribute;

  /// No description provided for @teacherDistributionQueued.
  ///
  /// In en, this message translates to:
  /// **'Distribution queued. Cloud download commands require a configured backend.'**
  String get teacherDistributionQueued;

  /// No description provided for @teacherGradeReportHint.
  ///
  /// In en, this message translates to:
  /// **'Entered grades automatically produce a count, average, and distribution.'**
  String get teacherGradeReportHint;

  /// No description provided for @teacherGradedCount.
  ///
  /// In en, this message translates to:
  /// **'Graded work'**
  String get teacherGradedCount;

  /// No description provided for @teacherClassAverage.
  ///
  /// In en, this message translates to:
  /// **'Class average'**
  String get teacherClassAverage;

  /// No description provided for @teacherNoGrades.
  ///
  /// In en, this message translates to:
  /// **'No graded work available yet.'**
  String get teacherNoGrades;

  /// No description provided for @teacherVerificationNone.
  ///
  /// In en, this message translates to:
  /// **'Not requested'**
  String get teacherVerificationNone;

  /// No description provided for @teacherVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Review pending'**
  String get teacherVerificationPending;

  /// No description provided for @teacherVerificationVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get teacherVerificationVerified;

  /// No description provided for @teacherVerificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Proof rejected'**
  String get teacherVerificationRejected;

  /// No description provided for @teacherVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get teacherVerificationStatus;

  /// No description provided for @teacherSubmitProof.
  ///
  /// In en, this message translates to:
  /// **'Submit proof'**
  String get teacherSubmitProof;

  /// No description provided for @teacherVerificationPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Proof may only be uploaded after explicit consent and with a defined deletion period to a contracted review service. Currently only the local status is stored.'**
  String get teacherVerificationPrivacy;

  /// No description provided for @teacherMicrophonePermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required to record.'**
  String get teacherMicrophonePermission;

  /// No description provided for @teacherNewExplanation.
  ///
  /// In en, this message translates to:
  /// **'New explanation'**
  String get teacherNewExplanation;

  /// No description provided for @teacherSaveRecording.
  ///
  /// In en, this message translates to:
  /// **'Save recording'**
  String get teacherSaveRecording;

  /// No description provided for @teacherTranscript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get teacherTranscript;

  /// No description provided for @teacherTranscriptHint.
  ///
  /// In en, this message translates to:
  /// **'Paste or correct the transcript. Automatic AI transcription requires a configured privacy-compliant service.'**
  String get teacherTranscriptHint;

  /// No description provided for @teacherAudioPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Recordings initially remain local on this device.'**
  String get teacherAudioPrivacy;

  /// No description provided for @teacherStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get teacherStopRecording;

  /// No description provided for @teacherStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Record explanation'**
  String get teacherStartRecording;

  /// No description provided for @teacherRecordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get teacherRecordings;

  /// No description provided for @teacherNoRecordings.
  ///
  /// In en, this message translates to:
  /// **'No explanations recorded yet.'**
  String get teacherNoRecordings;

  /// No description provided for @teacherTranscriptPending.
  ///
  /// In en, this message translates to:
  /// **'Transcript pending — tap to edit'**
  String get teacherTranscriptPending;

  /// No description provided for @teacherWaitingForWritePermission.
  ///
  /// In en, this message translates to:
  /// **'View only — teacher controls writing'**
  String get teacherWaitingForWritePermission;

  /// No description provided for @teacherWritingAllowed.
  ///
  /// In en, this message translates to:
  /// **'You may write on the whiteboard'**
  String get teacherWritingAllowed;

  /// No description provided for @teacherWritingBlocked.
  ///
  /// In en, this message translates to:
  /// **'The teacher has disabled writing for you.'**
  String get teacherWritingBlocked;

  /// No description provided for @teacherSubmitOer.
  ///
  /// In en, this message translates to:
  /// **'Submit to the community as OER'**
  String get teacherSubmitOer;

  /// No description provided for @teacherSubmitOerHint.
  ///
  /// In en, this message translates to:
  /// **'The item becomes public only after review.'**
  String get teacherSubmitOerHint;

  /// No description provided for @teacherOerSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Material submitted for review.'**
  String get teacherOerSubmitted;

  /// No description provided for @teacherOerSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to submit community material.'**
  String get teacherOerSignInRequired;

  /// No description provided for @teacherOerUploadUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read for upload.'**
  String get teacherOerUploadUnavailable;

  /// No description provided for @teacherStartClassBeforeDistribute.
  ///
  /// In en, this message translates to:
  /// **'Start a live class session first.'**
  String get teacherStartClassBeforeDistribute;

  /// No description provided for @teacherDistributionSent.
  ///
  /// In en, this message translates to:
  /// **'Download command sent to the class.'**
  String get teacherDistributionSent;

  /// No description provided for @teacherAllowFocusCheck.
  ///
  /// In en, this message translates to:
  /// **'Allow focus check'**
  String get teacherAllowFocusCheck;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @teacherLessonCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get teacherLessonCalendar;

  /// No description provided for @teacherLessonCalendarHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to record title, description, and attachments for each lesson from the timetable.'**
  String get teacherLessonCalendarHint;

  /// No description provided for @teacherNoSchoolDay.
  ///
  /// In en, this message translates to:
  /// **'There is no class in the timetable on this day.'**
  String get teacherNoSchoolDay;

  /// No description provided for @teacherNoLessonsForDay.
  ///
  /// In en, this message translates to:
  /// **'No lessons are scheduled for this day.'**
  String get teacherNoLessonsForDay;

  /// No description provided for @teacherPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period {n}'**
  String teacherPeriod(int n);

  /// No description provided for @teacherLessonAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get teacherLessonAttachments;

  /// No description provided for @teacherAttachmentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attachments'**
  String teacherAttachmentCount(int count);

  /// No description provided for @teacherOpenWhiteboard.
  ///
  /// In en, this message translates to:
  /// **'Open board'**
  String get teacherOpenWhiteboard;

  /// No description provided for @teacherSaveLessonMaterials.
  ///
  /// In en, this message translates to:
  /// **'Save materials'**
  String get teacherSaveLessonMaterials;

  /// No description provided for @teacherWhiteboardFinal.
  ///
  /// In en, this message translates to:
  /// **'Final whiteboard'**
  String get teacherWhiteboardFinal;

  /// No description provided for @teacherNoWhiteboardToSave.
  ///
  /// In en, this message translates to:
  /// **'No whiteboard available to save.'**
  String get teacherNoWhiteboardToSave;

  /// No description provided for @teacherSavedMaterialsLabel.
  ///
  /// In en, this message translates to:
  /// **'Materials {time}'**
  String teacherSavedMaterialsLabel(String time);

  /// No description provided for @teacherMaterialsSavedToLesson.
  ///
  /// In en, this message translates to:
  /// **'Materials attached to the current lesson.'**
  String get teacherMaterialsSavedToLesson;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @teacherSubjectOrRoomRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter at least a subject or a room.'**
  String get teacherSubjectOrRoomRequired;

  /// No description provided for @classroomAutoConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect automatically next time?'**
  String get classroomAutoConnectTitle;

  /// No description provided for @classroomAutoConnectBody.
  ///
  /// In en, this message translates to:
  /// **'BetterNotes can look for “{criteria}” during the next lesson. It connects only when the subject or room matches. The teacher verifies these criteria again during the handshake.'**
  String classroomAutoConnectBody(String criteria);

  /// No description provided for @classroomAutoConnectSetting.
  ///
  /// In en, this message translates to:
  /// **'Automatically connect to class'**
  String get classroomAutoConnectSetting;

  /// No description provided for @classroomAutoConnectSettingHint.
  ///
  /// In en, this message translates to:
  /// **'Connects only when at least the saved subject or room matches the teacher session.'**
  String get classroomAutoConnectSettingHint;

  /// No description provided for @classroomAutoConnectMismatch.
  ///
  /// In en, this message translates to:
  /// **'Automatic connection rejected: neither subject nor room matches.'**
  String get classroomAutoConnectMismatch;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @marketplaceHint.
  ///
  /// In en, this message translates to:
  /// **'Optional add-ons that not everyone needs. Purchases come later — this is the catalog.'**
  String get marketplaceHint;

  /// No description provided for @marketplaceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Purchase and unlock will arrive in a later update.'**
  String get marketplaceComingSoon;

  /// No description provided for @marketplaceSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get marketplaceSoonBadge;

  /// No description provided for @marketplaceInkOcrHint.
  ///
  /// In en, this message translates to:
  /// **'Handwriting and photos are recognized on-device and stored only as a hidden search index.'**
  String get marketplaceInkOcrHint;

  /// No description provided for @marketplaceCloudHint.
  ///
  /// In en, this message translates to:
  /// **'Premium cloud relay when no nearby P2P channel is available.'**
  String get marketplaceCloudHint;

  /// No description provided for @featureCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get featureCloudSync;

  /// No description provided for @scanPages.
  ///
  /// In en, this message translates to:
  /// **'Scan pages'**
  String get scanPages;

  /// No description provided for @scanPagesHint.
  ///
  /// In en, this message translates to:
  /// **'System document scanner — sheets become notebook pages.'**
  String get scanPagesHint;

  /// No description provided for @scanExam.
  ///
  /// In en, this message translates to:
  /// **'Scan the exam?'**
  String get scanExam;

  /// No description provided for @scanExamBody.
  ///
  /// In en, this message translates to:
  /// **'Photograph the test now and add the pages to a notebook.'**
  String get scanExamBody;

  /// No description provided for @scannedNotebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan {date}'**
  String scannedNotebookTitle(String date);

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the scanner.'**
  String get scanFailed;

  /// No description provided for @scanAddedPages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 scanned page} other{Added {count} scanned pages}}'**
  String scanAddedPages(num count);

  /// No description provided for @searchAtHint.
  ///
  /// In en, this message translates to:
  /// **'Use @ to search only in a subject, folder, or school year'**
  String get searchAtHint;

  /// No description provided for @pinTool.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pinTool;

  /// No description provided for @calculator.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculator;

  /// No description provided for @calculatorHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2+3*4 or sin(x)'**
  String get calculatorHint;

  /// No description provided for @calculatorEquals.
  ///
  /// In en, this message translates to:
  /// **'='**
  String get calculatorEquals;

  /// No description provided for @calculatorPlot.
  ///
  /// In en, this message translates to:
  /// **'Insert graph'**
  String get calculatorPlot;

  /// No description provided for @calculatorHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent calculations'**
  String get calculatorHistory;

  /// No description provided for @formulaBook.
  ///
  /// In en, this message translates to:
  /// **'Formula book'**
  String get formulaBook;

  /// No description provided for @formulaTerm.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get formulaTerm;

  /// No description provided for @formulaValue.
  ///
  /// In en, this message translates to:
  /// **'Formula / value'**
  String get formulaValue;

  /// No description provided for @formulaAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get formulaAddRow;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @setupStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Your path'**
  String get setupStudentTitle;

  /// No description provided for @setupStudentBody.
  ///
  /// In en, this message translates to:
  /// **'So notes, grades, and the next term match how you learn.'**
  String get setupStudentBody;

  /// No description provided for @setupTeacherTitle.
  ///
  /// In en, this message translates to:
  /// **'Your teacher profile'**
  String get setupTeacherTitle;

  /// No description provided for @setupTeacherBody.
  ///
  /// In en, this message translates to:
  /// **'Are you still studying or already teaching?'**
  String get setupTeacherBody;

  /// No description provided for @setupTeacherTrack.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get setupTeacherTrack;

  /// No description provided for @teacherTrackStudying.
  ///
  /// In en, this message translates to:
  /// **'In studies'**
  String get teacherTrackStudying;

  /// No description provided for @teacherTrackStudyingHint.
  ///
  /// In en, this message translates to:
  /// **'When a semester starts you can create a new notebook and keep chosen chapters.'**
  String get teacherTrackStudyingHint;

  /// No description provided for @teacherTrackQualified.
  ///
  /// In en, this message translates to:
  /// **'Already qualified'**
  String get teacherTrackQualified;

  /// No description provided for @teacherTrackQualifiedHint.
  ///
  /// In en, this message translates to:
  /// **'For class — including sharing notebooks and materials.'**
  String get teacherTrackQualifiedHint;

  /// No description provided for @newTermNotebook.
  ///
  /// In en, this message translates to:
  /// **'Create a notebook for this term'**
  String get newTermNotebook;

  /// No description provided for @importChaptersBodyTerm.
  ///
  /// In en, this message translates to:
  /// **'Which chapters from “{title}” should carry over to {period}?'**
  String importChaptersBodyTerm(String title, String period);

  /// No description provided for @termWinterHalbjahr.
  ///
  /// In en, this message translates to:
  /// **'1st term {year}'**
  String termWinterHalbjahr(String year);

  /// No description provided for @termSummerHalbjahr.
  ///
  /// In en, this message translates to:
  /// **'2nd term {year}'**
  String termSummerHalbjahr(String year);

  /// No description provided for @termWinterSemester.
  ///
  /// In en, this message translates to:
  /// **'Winter semester {year}'**
  String termWinterSemester(String year);

  /// No description provided for @termSummerSemester.
  ///
  /// In en, this message translates to:
  /// **'Summer semester {year}'**
  String termSummerSemester(String year);

  /// No description provided for @teacherShareContent.
  ///
  /// In en, this message translates to:
  /// **'Share content'**
  String get teacherShareContent;

  /// No description provided for @teacherShareContentHint.
  ///
  /// In en, this message translates to:
  /// **'Send the board, notebooks, flashcards, or files to the class.'**
  String get teacherShareContentHint;

  /// No description provided for @teacherShareLiveBoard.
  ///
  /// In en, this message translates to:
  /// **'Send the current board'**
  String get teacherShareLiveBoard;

  /// No description provided for @teacherShareNotebook.
  ///
  /// In en, this message translates to:
  /// **'Share notebook'**
  String get teacherShareNotebook;

  /// No description provided for @teacherShareFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Share flashcards'**
  String get teacherShareFlashcards;

  /// No description provided for @tutorialOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'A short tour?'**
  String get tutorialOfferTitle;

  /// No description provided for @tutorialOfferBody.
  ///
  /// In en, this message translates to:
  /// **'A few steps that point out the main parts of the app.'**
  String get tutorialOfferBody;

  /// No description provided for @tutorialStart.
  ///
  /// In en, this message translates to:
  /// **'Start tutorial'**
  String get tutorialStart;

  /// No description provided for @tutorialSkip.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get tutorialSkip;

  /// No description provided for @tutorialNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// No description provided for @tutorialDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tutorialDone;

  /// No description provided for @tourLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library'**
  String get tourLibraryTitle;

  /// No description provided for @tourLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'Notebooks, folders, and flashcards live here. Tap a cover to open it.'**
  String get tourLibraryBody;

  /// No description provided for @tourCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create something'**
  String get tourCreateTitle;

  /// No description provided for @tourCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Use plus to add a notebook, folder, or flashcard deck.'**
  String get tourCreateBody;

  /// No description provided for @tourSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search with @'**
  String get tourSearchTitle;

  /// No description provided for @tourSearchBody.
  ///
  /// In en, this message translates to:
  /// **'Try @Economics addition to search inside one subject only.'**
  String get tourSearchBody;

  /// No description provided for @tourSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tourSettingsTitle;

  /// No description provided for @tourSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Role, state, stylus gestures, and this tutorial are here.'**
  String get tourSettingsBody;

  /// No description provided for @tourTeacherTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher tools'**
  String get tourTeacherTitle;

  /// No description provided for @tourTeacherBody.
  ///
  /// In en, this message translates to:
  /// **'Start class and share the board, notebooks, or materials.'**
  String get tourTeacherBody;

  /// No description provided for @tourEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Inside a notebook'**
  String get tourEditorTitle;

  /// No description provided for @tourEditorBody.
  ///
  /// In en, this message translates to:
  /// **'The toolbar has pen, eraser, calculator, and the formula book. Swipe to change pages.'**
  String get tourEditorBody;

  /// No description provided for @teacherAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get teacherAssignments;

  /// No description provided for @teacherAssignmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Build worksheets in the editor. PDF scans become draft tasks you should review.'**
  String get teacherAssignmentsHint;

  /// No description provided for @teacherAssignmentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items in the catalog'**
  String teacherAssignmentCount(int count);

  /// No description provided for @teacherNewAssignment.
  ///
  /// In en, this message translates to:
  /// **'New assignment'**
  String get teacherNewAssignment;

  /// No description provided for @teacherUntitledAssignment.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get teacherUntitledAssignment;

  /// No description provided for @teacherImportPdf.
  ///
  /// In en, this message translates to:
  /// **'Import from PDF'**
  String get teacherImportPdf;

  /// No description provided for @teacherImportPdfHint.
  ///
  /// In en, this message translates to:
  /// **'Pages are read and split into editable tasks.'**
  String get teacherImportPdfHint;

  /// No description provided for @teacherImportScan.
  ///
  /// In en, this message translates to:
  /// **'Scan and import'**
  String get teacherImportScan;

  /// No description provided for @teacherImportScanHint.
  ///
  /// In en, this message translates to:
  /// **'Camera or scanner, then review the draft in the editor.'**
  String get teacherImportScanHint;

  /// No description provided for @teacherImportedScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get teacherImportedScanTitle;

  /// No description provided for @teacherReviewBanner.
  ///
  /// In en, this message translates to:
  /// **'Text and structure come from the scan. Please review, edit if needed, and confirm before you use this assignment.'**
  String get teacherReviewBanner;

  /// No description provided for @teacherConfirmDraft.
  ///
  /// In en, this message translates to:
  /// **'Confirm draft'**
  String get teacherConfirmDraft;

  /// No description provided for @teacherNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get teacherNeedsReview;

  /// No description provided for @teacherAnswerKind.
  ///
  /// In en, this message translates to:
  /// **'Answer type'**
  String get teacherAnswerKind;

  /// No description provided for @teacherAnswerText.
  ///
  /// In en, this message translates to:
  /// **'Free text'**
  String get teacherAnswerText;

  /// No description provided for @teacherAnswerMc.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get teacherAnswerMc;

  /// No description provided for @teacherAnswerCalc.
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get teacherAnswerCalc;

  /// No description provided for @teacherAnswerMatch.
  ///
  /// In en, this message translates to:
  /// **'Matching'**
  String get teacherAnswerMatch;

  /// No description provided for @teacherTaskParts.
  ///
  /// In en, this message translates to:
  /// **'Task parts'**
  String get teacherTaskParts;

  /// No description provided for @teacherAddPartText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get teacherAddPartText;

  /// No description provided for @teacherAddPartImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get teacherAddPartImage;

  /// No description provided for @teacherAddPartLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get teacherAddPartLink;

  /// No description provided for @teacherSampleAnswer.
  ///
  /// In en, this message translates to:
  /// **'Sample answer'**
  String get teacherSampleAnswer;

  /// No description provided for @teacherCalcResult.
  ///
  /// In en, this message translates to:
  /// **'Final result'**
  String get teacherCalcResult;

  /// No description provided for @teacherCalcTolerance.
  ///
  /// In en, this message translates to:
  /// **'Tolerance'**
  String get teacherCalcTolerance;

  /// No description provided for @teacherMaxPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get teacherMaxPoints;

  /// No description provided for @teacherKindTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get teacherKindTask;

  /// No description provided for @teacherKindTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get teacherKindTest;

  /// No description provided for @teacherKindExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get teacherKindExam;

  /// No description provided for @teacherCatalogKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get teacherCatalogKind;

  /// No description provided for @teacherCatalogVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get teacherCatalogVisibility;

  /// No description provided for @teacherVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get teacherVisibilityPrivate;

  /// No description provided for @teacherVisibilitySchool.
  ///
  /// In en, this message translates to:
  /// **'School only'**
  String get teacherVisibilitySchool;

  /// No description provided for @teacherVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get teacherVisibilityPublic;

  /// No description provided for @teacherSuggestedDuration.
  ///
  /// In en, this message translates to:
  /// **'Suggested duration (min.)'**
  String get teacherSuggestedDuration;

  /// No description provided for @teacherNoAssignments.
  ///
  /// In en, this message translates to:
  /// **'No assignments yet. Create one or import a PDF or scan.'**
  String get teacherNoAssignments;

  /// No description provided for @teacherImporting.
  ///
  /// In en, this message translates to:
  /// **'Converting into the editor…'**
  String get teacherImporting;

  /// No description provided for @teacherImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not convert this file'**
  String get teacherImportFailed;

  /// No description provided for @teacherAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get teacherAddTask;

  /// No description provided for @teacherCorrectOption.
  ///
  /// In en, this message translates to:
  /// **'Mark the correct answer'**
  String get teacherCorrectOption;

  /// No description provided for @teacherMatchLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get teacherMatchLeft;

  /// No description provided for @teacherMatchRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get teacherMatchRight;

  /// No description provided for @teacherDeleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get teacherDeleteTask;

  /// No description provided for @teacherTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get teacherTags;

  /// No description provided for @teacherTasksHeading.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get teacherTasksHeading;

  /// No description provided for @teacherTaskNumber.
  ///
  /// In en, this message translates to:
  /// **'Task {number}'**
  String teacherTaskNumber(int number);

  /// No description provided for @teacherTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks'**
  String teacherTaskCount(int count);

  /// No description provided for @teacherSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get teacherSchool;

  /// No description provided for @teacherSchoolName.
  ///
  /// In en, this message translates to:
  /// **'School name'**
  String get teacherSchoolName;

  /// No description provided for @teacherSchoolCode.
  ///
  /// In en, this message translates to:
  /// **'School join code'**
  String get teacherSchoolCode;

  /// No description provided for @assignmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get assignmentTitle;

  /// No description provided for @assignmentWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an assignment from the teacher.'**
  String get assignmentWaiting;

  /// No description provided for @assignmentSubmit.
  ///
  /// In en, this message translates to:
  /// **'Done — submit'**
  String get assignmentSubmit;

  /// No description provided for @assignmentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted. This workspace is locked.'**
  String get assignmentSubmitted;

  /// No description provided for @assignmentLocked.
  ///
  /// In en, this message translates to:
  /// **'Time is up. Wait for extra time or collection.'**
  String get assignmentLocked;

  /// No description provided for @assignmentYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get assignmentYourAnswer;

  /// No description provided for @assignmentImportNotebook.
  ///
  /// In en, this message translates to:
  /// **'Add to a notebook'**
  String get assignmentImportNotebook;

  /// No description provided for @assignmentStart.
  ///
  /// In en, this message translates to:
  /// **'Start assignment'**
  String get assignmentStart;

  /// No description provided for @assignmentStartHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a confirmed template and send it to the class as its own page.'**
  String get assignmentStartHint;

  /// No description provided for @assignmentTestMode.
  ///
  /// In en, this message translates to:
  /// **'Test mode (lock calculator and formula book)'**
  String get assignmentTestMode;

  /// No description provided for @assignmentExtend5.
  ///
  /// In en, this message translates to:
  /// **'+5 minutes'**
  String get assignmentExtend5;

  /// No description provided for @assignmentExtend10.
  ///
  /// In en, this message translates to:
  /// **'+10 minutes'**
  String get assignmentExtend10;

  /// No description provided for @assignmentCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get assignmentCollect;

  /// No description provided for @assignmentAllowImport.
  ///
  /// In en, this message translates to:
  /// **'Allow import'**
  String get assignmentAllowImport;

  /// No description provided for @assignmentResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get assignmentResults;

  /// No description provided for @assignmentPrint.
  ///
  /// In en, this message translates to:
  /// **'Print without solutions'**
  String get assignmentPrint;

  /// No description provided for @assignmentClassAverage.
  ///
  /// In en, this message translates to:
  /// **'Class average {percent} %'**
  String assignmentClassAverage(int percent);

  /// No description provided for @assignmentSubmittedCount.
  ///
  /// In en, this message translates to:
  /// **'Submitted: {done}/{total}'**
  String assignmentSubmittedCount(int done, int total);

  /// No description provided for @assignmentTopProblems.
  ///
  /// In en, this message translates to:
  /// **'Most common problems'**
  String get assignmentTopProblems;

  /// No description provided for @assignmentNoProblems.
  ///
  /// In en, this message translates to:
  /// **'No graded problems yet.'**
  String get assignmentNoProblems;

  /// No description provided for @assignmentGroups.
  ///
  /// In en, this message translates to:
  /// **'Similar error patterns'**
  String get assignmentGroups;

  /// No description provided for @assignmentSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get assignmentSubmissions;

  /// No description provided for @assignmentEarly.
  ///
  /// In en, this message translates to:
  /// **'submitted early'**
  String get assignmentEarly;

  /// No description provided for @assignmentOnCollect.
  ///
  /// In en, this message translates to:
  /// **'collected'**
  String get assignmentOnCollect;

  /// No description provided for @assignmentCorrection.
  ///
  /// In en, this message translates to:
  /// **'Send a correction to this device'**
  String get assignmentCorrection;

  /// No description provided for @assignmentLeaveSignals.
  ///
  /// In en, this message translates to:
  /// **'Left / lost focus'**
  String get assignmentLeaveSignals;

  /// No description provided for @assignmentPoolLocked.
  ///
  /// In en, this message translates to:
  /// **'Exchange: publish once to browse other public assignments.'**
  String get assignmentPoolLocked;

  /// No description provided for @assignmentPoolUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Exchange is unlocked. Other teachers\' public items appear once cloud sync is connected.'**
  String get assignmentPoolUnlocked;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
