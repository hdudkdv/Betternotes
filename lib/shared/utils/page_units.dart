/// PDF-point ↔ millimetre helpers.
///
/// Notebook pages use PDF points (1/72 inch). Physical rulers need mm/cm.
abstract final class PageUnits {
  static const double pointsPerMm = 72 / 25.4;
  static const double pointsPerCm = pointsPerMm * 10;

  static double mmToPt(double mm) => mm * pointsPerMm;
  static double cmToPt(double cm) => cm * pointsPerCm;
  static double ptToMm(double pt) => pt / pointsPerMm;
  static double ptToCm(double pt) => pt / pointsPerCm;
}
