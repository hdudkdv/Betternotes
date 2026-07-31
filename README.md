# BetterNotes

Tablet-first handwritten notes app (GoodNotes-inspired) built with Flutter for **iOS**, **Android**, and **Web**.

## Features (MVP)

- Notebook library with search, favorites, rename/delete
- Page-based editor with blank / lined / grid templates
- Ink tools: pen, marker, stroke eraser, lasso, colors, width, undo/redo
- Stylus writes; finger pans/zooms (toggle in Settings)
- PDF import as drawable backgrounds + PDF export
- Local offline storage (Isar on native, SharedPreferences JSON on web)

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome          # web
flutter run -d windows         # desktop
flutter run                    # connected device / emulator
```

## Docs

- [Product scope](docs/PRODUCT.md)
- [Roadmap](docs/ROADMAP.md)
