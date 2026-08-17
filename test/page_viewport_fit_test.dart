import 'package:betternotes/features/editor/presentation/widgets/page_viewport_fit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('framed page stays centered in a tight landscape viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const pageSize = Size(595, 842);
    const paperKey = Key('paper');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ColoredBox(
              color: Color(0xFF111111),
              child: PageViewportFitFramed(
                viewport: Size(1200, 700),
                pageSize: pageSize,
                paper: ColoredBox(key: paperKey, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );

    final paper = tester.getRect(find.byKey(paperKey));
    expect(paper.width, closeTo(pageSize.width * _scale(pageSize), 1));
    expect(
      (paper.center.dx - 600).abs(),
      lessThan(8),
      reason: 'paper must sit on the horizontal center, not in a corner',
    );
    expect(
      (paper.center.dy - 350).abs(),
      lessThan(8),
      reason: 'paper must sit on the vertical center, not in a corner',
    );
  });
}

double _scale(Size pageSize) =>
    PageViewportFit.fitScale(const Size(1200, 700), pageSize);

/// Test wrapper so [PageViewportFit.framed] can be used as a const child.
class PageViewportFitFramed extends StatelessWidget {
  const PageViewportFitFramed({
    super.key,
    required this.viewport,
    required this.pageSize,
    required this.paper,
  });

  final Size viewport;
  final Size pageSize;
  final Widget paper;

  @override
  Widget build(BuildContext context) {
    return PageViewportFit.framed(
      viewport: viewport,
      pageSize: pageSize,
      paper: paper,
    );
  }
}
