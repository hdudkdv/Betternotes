# BetterNotes — Product

## Goal

Modern note app for students and professionals with a look of its own: flexible text, custom paper, deep structure, reliable offline-first sync, and app-wide search.

## Vision USPs

- **Smart-Text Engine** — hybrid free/line-bound text; per-span size, color, font
- **Custom Paper Creator** — adjustable line/grid/margins/colors, saved templates
- **Deep Structure** — multi-level outline + tags (not just folders)
- **Global Search** — across notebooks, outline, text, tags
- **Offline-First Sync** — background sync that does not eat edits (CRDT-oriented)

## Look & feel

Four looks — Studio (graphite/indigo), Paper (cream/green), Fresh (white/teal) and
Mono (black and white) — each in light and dark, picked under Settings →
Appearance and following the system brightness by default. Every screen reads its
colours from `AppPalette` (`lib/app/palettes.dart`); `AppTheme` publishes the
resolved palette and `EditorChrome` derives the editor surfaces from it. Nothing
outside those two files names a raw colour, so a new look is a new palette entry.

The document font is deliberately fixed (`text_block_layer.dart`): notes must not
reflow when the app look changes.

## Editor UX

- Dark editor chrome in every look, so the page stays the brightest surface
- Document tabs as pills for open notebooks
- Read vs Edit interaction mode
- Tools: lasso, pen, eraser, marker, shapes, text, images
- Contextual properties (width presets + colors, full picker behind the swatches)
- Three-dot menu as a grouped sheet: paper, view, document
- Thumbnail grid overlay; outline as sheet
- No audio / no stickers (by design)

## Phase A

- Page mode + infinite canvas toggle
- Ink: pen, marker, eraser, lasso
- Smart text fields with span formatting
- Custom paper creator + templates
- Deep outline sidebar
- PDF import/export
- Local persistence (Isar native / prefs web)

## Phase B

- Global search
- Tags + cross-links
- GoodNotes-style chrome + shapes/images/tabs
- Study mode + local page snapshots

## Phase C

- Accounts + devices
- Offline-first sync queue
- Block-level CRDT merge for text/ink/outline
- Sync status in settings
- Nearby LAN / hotspot sync (AirDrop-like, same network)
## Non-Goals (near term)

- Live multiplayer collaboration
- Full AI summaries / OCR pipeline
- Shape recognition from handwriting
- Audio notes / stickers
