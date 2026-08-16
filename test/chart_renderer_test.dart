import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/tools/charts/chart_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a free mindmap', () async {
    final bytes = await ChartRenderer.renderPng(
      kind: ChartKind.mindmap,
      title: 'Thema',
      rows: [
        ChartSeriesRow(label: 'Ursache'),
        ChartSeriesRow(label: 'Folge'),
      ],
    );
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(200));
  });

  test('renders an ER sketch', () async {
    final bytes = await ChartRenderer.renderPng(
      kind: ChartKind.er,
      title: 'Shop',
      rows: [
        ChartSeriesRow(label: 'Kunde', value: 'id, Name', end: 'kauft'),
        ChartSeriesRow(label: 'Bestellung', value: 'Datum'),
      ],
    );
    expect(bytes, isNotNull);
  });
}
