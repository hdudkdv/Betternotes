import 'package:betternotes/features/editor/domain/ink_models.dart';
import 'package:betternotes/features/editor/providers/tool_presets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('each pen type keeps its own color', () async {
    SharedPreferences.setMockInitialValues({});
    final presets = ToolPresets(await SharedPreferences.getInstance());

    presets.setColorFor(InkTool.pen, 0xFF111111);
    presets.setColorFor(InkTool.fountain, 0xFF2222AA);
    presets.setColorFor(InkTool.pencil, 0xFF555555);
    presets.setColorFor(InkTool.marker, 0xFFFFCC00);

    expect(presets.colorFor(InkTool.pen), 0xFF111111);
    expect(presets.colorFor(InkTool.fountain), 0xFF2222AA);
    expect(presets.colorFor(InkTool.pencil), 0xFF555555);
    expect(presets.colorFor(InkTool.marker), 0xFFFFCC00);
  });
}
