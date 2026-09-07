import 'dart:ui';

/// Standard paper formats expressed in PDF points (1/72 inch).
enum PaperFormat { a2, a3, a4, a5, a6, letter, legal, tabloid }

enum PageOrientation { portrait, landscape }

/// Resolves the physical drawing area of a notebook page.
class NotePageSize {
  static const Size a4 = Size(595, 842);
  static const Size a2 = Size(1191, 1684);
  static const Size a3 = Size(842, 1191);
  static const Size a5 = Size(420, 595);
  static const Size a6 = Size(298, 420);
  static const Size letter = Size(612, 792);
  static const Size legal = Size(612, 1008);
  static const Size tabloid = Size(792, 1224);

  static Size get defaultSize => a4;

  static Size resolve(PaperFormat format, PageOrientation orientation) {
    final portrait = switch (format) {
      PaperFormat.a2 => a2,
      PaperFormat.a3 => a3,
      PaperFormat.a4 => a4,
      PaperFormat.a5 => a5,
      PaperFormat.a6 => a6,
      PaperFormat.letter => letter,
      PaperFormat.legal => legal,
      PaperFormat.tabloid => tabloid,
    };
    return orientation == PageOrientation.portrait
        ? portrait
        : Size(portrait.height, portrait.width);
  }

  /// Closest standard paper to [image] pixels, matching landscape/portrait.
  static ({PaperFormat format, PageOrientation orientation}) bestForImage(
    Size image,
  ) {
    final landscape = image.width >= image.height;
    final imageAr = landscape
        ? image.width / image.height
        : image.height / image.width;
    var best = PaperFormat.a4;
    var bestDiff = double.infinity;
    for (final format in PaperFormat.values) {
      final size = resolve(format, PageOrientation.portrait);
      final formatAr = size.height / size.width;
      final diff = (formatAr - imageAr).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = format;
      }
    }
    return (
      format: best,
      orientation: landscape
          ? PageOrientation.landscape
          : PageOrientation.portrait,
    );
  }
}
