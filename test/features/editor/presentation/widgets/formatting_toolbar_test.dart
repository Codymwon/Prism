import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/presentation/widgets/formatting_toolbar.dart';
import 'package:prism/features/settings/presentation/providers/custom_macro_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';

class FakeCustomMacros extends CustomMacros {
  final List<CustomMacro> initialMacros;
  FakeCustomMacros(this.initialMacros);

  @override
  List<CustomMacro> build() {
    return initialMacros;
  }
}

void main() {
  testWidgets('FormattingToolbar renders without overflowing with many custom macros', (WidgetTester tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    // Simulate system text scaling (accessibility scale)
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          customMacrosProvider.overrideWith(() => FakeCustomMacros([
            CustomMacro(label: 'Long Label One', text: '1'),
            CustomMacro(label: 'Long Label Two', text: '2'),
            CustomMacro(label: 'Long Label Three', text: '3'),
            CustomMacro(label: 'Long Label Four', text: '4'),
            CustomMacro(label: 'Long Label Five', text: '5'),
          ])),
        ],
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    await tester.ensureVisible(attachImageFinder);
    await tester.tap(attachImageFinder);
    expect(attachImageTriggered, isTrue);
  });

  testWidgets('Heading chooser does not crash and inserts prefix at cursor 0', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'Initial text');
    controller.selection = const TextSelection.collapsed(offset: 0);
    final focusNode = FocusNode();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    await tester.pumpAndSettle();

    final headingBtnFinder = find.byTooltip('Heading (H1–H4)');
    expect(headingBtnFinder, findsOneWidget);
    await tester.ensureVisible(headingBtnFinder);
    await tester.tap(headingBtnFinder);
    await tester.pumpAndSettle();

    final h1Finder = find.text('Heading 1');
    expect(h1Finder, findsOneWidget);
    await tester.ensureVisible(h1Finder);
    await tester.tap(h1Finder);
    await tester.pumpAndSettle();

    expect(controller.text, equals('# Initial text'));
    expect(controller.selection.baseOffset, equals(14));
  });

  testWidgets('Bullet List button formats single line without extra newlines', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'Single line text');
    controller.selection = const TextSelection.collapsed(offset: 0);
    final focusNode = FocusNode();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    await tester.pumpAndSettle();

    final listBtnFinder = find.byTooltip('Bullet List');
    expect(listBtnFinder, findsOneWidget);
    await tester.ensureVisible(listBtnFinder);
    await tester.tap(listBtnFinder);
    await tester.pumpAndSettle();

    expect(controller.text, equals('- Single line text'));
  });

  testWidgets('Bullet List button formats multiple lines', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'line 1\nline 2\nline 3');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 20);
    final focusNode = FocusNode();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    await tester.pumpAndSettle();

    final listBtnFinder = find.byTooltip('Bullet List');
    expect(listBtnFinder, findsOneWidget);
    await tester.ensureVisible(listBtnFinder);
    await tester.tap(listBtnFinder);
    await tester.pumpAndSettle();

    expect(controller.text, equals('- line 1\n- line 2\n- line 3'));
  });

  testWidgets('Checklist button formats single and multiple lines', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'line 1\nline 2');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 13);
    final focusNode = FocusNode();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    await tester.pumpAndSettle();

    final checklistBtnFinder = find.byTooltip('Checklist');
    expect(checklistBtnFinder, findsOneWidget);
    await tester.ensureVisible(checklistBtnFinder);
    await tester.tap(checklistBtnFinder);
    await tester.pumpAndSettle();

    expect(controller.text, equals('- [ ] line 1\n- [ ] line 2'));
  });

  testWidgets('Blockquote button formats single and multiple lines', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'line 1\nline 2');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 13);
    final focusNode = FocusNode();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    await tester.pumpAndSettle();

    final quoteBtnFinder = find.byTooltip('Blockquote');
    expect(quoteBtnFinder, findsOneWidget);
    await tester.ensureVisible(quoteBtnFinder);
    await tester.tap(quoteBtnFinder);
    await tester.pumpAndSettle();

    expect(controller.text, equals('> line 1\n> line 2'));
  });

  testWidgets('Divider button inserts divider dynamically', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'Some text');
    controller.selection = const TextSelection.collapsed(offset: 9);
    final focusNode = FocusNode();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    await tester.pumpAndSettle();

    final dividerBtnFinder = find.byTooltip('Divider');
    expect(dividerBtnFinder, findsOneWidget);
    await tester.ensureVisible(dividerBtnFinder);
    await tester.tap(dividerBtnFinder);
    await tester.pumpAndSettle();

    expect(controller.text, equals('Some text\n---\n'));
  });

  testWidgets('Table button inserts table dynamically', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'Some text');
    controller.selection = const TextSelection.collapsed(offset: 9);
    final focusNode = FocusNode();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    await tester.pumpAndSettle();

    final tableBtnFinder = find.byTooltip('Table');
    expect(tableBtnFinder, findsOneWidget);
    await tester.ensureVisible(tableBtnFinder);
    await tester.tap(tableBtnFinder);
    await tester.pumpAndSettle();

    const expectedTable = 'Some text\n| Header 1 | Header 2 |\n| -------- | -------- |\n| Cell 1   | Cell 2   |\n';
    expect(controller.text, equals(expectedTable));
  });
}
