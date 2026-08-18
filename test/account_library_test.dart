import 'dart:typed_data';

import 'package:betternotes/data/models/notebook.dart';
import 'package:betternotes/features/library/notebook_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crypto round-trips notebook JSON', () {
    final key = Uint8List.fromList(List<int>.generate(32, (i) => i + 3));
    const payload = '{"pages":[{"id":"p1","strokes":[1,2,3]}]}';
    final blob = NotebookCrypto.encrypt(payload, key);
    expect(blob, isNot(payload));
    expect(NotebookCrypto.decrypt(blob, key), payload);
    expect(
      () => NotebookCrypto.decrypt(blob, Uint8List(32)),
      throwsA(isA<FormatException>()),
    );
  });

  test('locked notebooks are only open for the original account', () {
    final now = DateTime(2026, 1, 1);
    final owned = Notebook(
      id: '1',
      title: 'Bio',
      coverColor: 1,
      createdAt: now,
      updatedAt: now,
      ownerUid: 'alice',
    );
    final locked = owned.copyWith(locked: true);
    final unsigned = Notebook(
      id: '2',
      title: 'Local',
      coverColor: 2,
      createdAt: now,
      updatedAt: now,
    );
    expect(owned.isLockedFor('alice'), isFalse);
    expect(locked.isLockedFor('alice'), isFalse);
    expect(locked.isLockedFor('bob'), isTrue);
    expect(unsigned.isLockedFor('bob'), isFalse);

    expect(
      _plaintextForeign([owned, locked, unsigned], 'bob').map((n) => n.id),
      ['1'],
    );
    expect(
      _unsignedOrOwned([owned, locked, unsigned], 'alice').map((n) => n.id),
      ['1', '2'],
    );
  });
}

List<Notebook> _plaintextForeign(
  List<Notebook> notebooks,
  String? viewerUid,
) {
  return [
    for (final notebook in notebooks)
      if (!notebook.locked &&
          notebook.ownerUid != null &&
          notebook.ownerUid != viewerUid)
        notebook,
  ];
}

List<Notebook> _unsignedOrOwned(List<Notebook> notebooks, String? ownerUid) {
  return [
    for (final notebook in notebooks)
      if (!notebook.locked &&
          (notebook.ownerUid == null || notebook.ownerUid == ownerUid))
        notebook,
  ];
}
