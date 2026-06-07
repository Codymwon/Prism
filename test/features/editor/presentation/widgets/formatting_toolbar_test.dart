import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/presentation/widgets/formatting_toolbar.dart';
import 'package:prism/features/settings/presentation/providers/custom_macro_provider.dart';

void main() {
  testWidgets('FormattingToolbar renders without overflowing with many custom macros', (WidgetTester tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    // Simulate system text scaling (accessibility scale)
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customMacrosProvider.overrideWith((ref) => CustomMacrosNotifier()
            ..setMacros([
              CustomMacro(label: 'Long Label One', text: '1'),
              CustomMacro(label: 'Long Label Two', text: '2'),
              CustomMacro(label: 'Long Label Three', text: '3'),
              CustomMacro(label: 'Long Label Four', text: '4'),
              CustomMacro(label: 'Long Label Five', text: '5'),
            ])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FormattingToolbar(
                controller: controller,
                focusNode: focusNode,
                onToggleDictation: () {},
                onAttachImage: () {},
              ),
            ),
          ),
        ),
      ),
    );

    // Let it render
    await tester.pumpAndSettle();

    // Verify no overflow exception was thrown
    expect(tester.takeException(), isNull);
    
    // Find the toolbar container position
    final toolbarFinder = find.byType(FormattingToolbar);
    final toolbarRect = tester.getRect(toolbarFinder);
    debugPrint('Toolbar Rect: $toolbarRect');

    // Find the first formatting button position (e.g. Bold button)
    final boldButtonFinder = find.byTooltip('Bold');
    final boldButtonRect = tester.getRect(boldButtonFinder);
    debugPrint('Bold Button Rect: $boldButtonRect');

    // Find the first macro button position (e.g. Long Label One)
    final macroButtonFinder = find.byTooltip('Insert: 1');
    final macroButtonRect = tester.getRect(macroButtonFinder);
    debugPrint('Macro Button Rect: $macroButtonRect');

    // Clear test text scale factor
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  testWidgets('FormattingToolbar renders Attach Image button and triggers callback', (WidgetTester tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    bool attachImageTriggered = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FormattingToolbar(
                controller: controller,
                focusNode: focusNode,
                onToggleDictation: () {},
                onAttachImage: () {
                  attachImageTriggered = true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final attachImageFinder = find.byTooltip('Attach Image');
    expect(attachImageFinder, findsOneWidget);

    await tester.tap(attachImageFinder);
    expect(attachImageTriggered, isTrue);
  });
}
