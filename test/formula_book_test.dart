import 'package:betternotes/features/tools/formula_book/formula_book_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seeded book has a symbols chapter with meaning and pronunciation', () {
    final book = FormulaBook.seeded();
    final symbols = book.byId('symbole');
    expect(symbols, isNotNull);
    expect(symbols!.rows, isNotEmpty);
    expect(symbols.rows.any((row) => row.symbol == 'π'), isTrue);
    expect(symbols.rows.any((row) => row.pronunciation == 'Pi'), isTrue);
    expect(symbols.rows.any((row) => row.meaning.contains('Kreis')), isTrue);
  });

  test('formula rows keep symbol fields through json', () {
    final row = FormulaRow.create(
      symbol: 'Δ',
      term: 'Delta',
      meaning: 'Änderung',
      pronunciation: 'Delta',
      value: 'Δx',
    );
    final roundTrip = FormulaRow.fromJson(row.toJson());
    expect(roundTrip.symbol, 'Δ');
    expect(roundTrip.meaning, 'Änderung');
    expect(roundTrip.pronunciation, 'Delta');
    expect(roundTrip.value, 'Δx');
  });
}
