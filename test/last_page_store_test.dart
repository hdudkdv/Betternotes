import 'package:betternotes/features/editor/domain/last_page_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LastPageStore> store() async {
    SharedPreferences.setMockInitialValues({});
    return LastPageStore(await SharedPreferences.getInstance());
  }

  test('remembers the last page per notebook', () async {
    final s = await store();

    expect(s.read('nb-1'), isNull);

    await s.write('nb-1', 'page-3');
    await s.write('nb-2', 'page-7');

    expect(s.read('nb-1'), 'page-3');
    expect(s.read('nb-2'), 'page-7');
  });

  test('overwrites and clears', () async {
    final s = await store();

    await s.write('nb-1', 'page-3');
    await s.write('nb-1', 'page-4');
    expect(s.read('nb-1'), 'page-4');

    await s.clear('nb-1');
    expect(s.read('nb-1'), isNull);
  });
}
