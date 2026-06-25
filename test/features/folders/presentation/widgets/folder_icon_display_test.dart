import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/folders/presentation/widgets/folder_icon_display.dart';

void main() {
  group('FolderIconDisplay', () {
    Widget buildWidget({required String iconKey, required Color color}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: FolderIconDisplay(
              iconKey: iconKey,
              color: color,
              size: 44,
              badgeSize: 10,
            ),
          ),
        ),
      );
    }

    testWidgets('renders icon when iconKey is non-empty', (tester) async {
      await tester.pumpWidget(
        buildWidget(iconKey: 'folder', color: const Color(0xFF7C6FF7)),
      );
      await tester.pump();

      // Should have an icon widget
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('renders NO icon widget when iconKey is empty', (tester) async {
      await tester.pumpWidget(
        buildWidget(iconKey: '', color: const Color(0xFF7C6FF7)),
      );
      await tester.pump();

      // SizedBox.shrink() is returned — no Icon, no background Container from us
      expect(find.byType(Icon), findsNothing);
      // The widget itself should be a SizedBox (zero size), not a SizedBox with children
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      // At least one SizedBox.shrink (width=0, height=0) from our widget
      expect(sizedBoxes.any((s) => s.width == 0 && s.height == 0), isTrue);
    });

    testWidgets('renders nothing at all (SizedBox.shrink) when iconKey is empty',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(iconKey: '', color: const Color(0xFF10B981)),
      );
      await tester.pump();

      // No icon rendered — completely empty from FolderIconDisplay's perspective
      expect(find.byType(Icon), findsNothing);
      // SizedBox.shrink exists with zero dimensions
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(sizedBoxes.any((s) => s.width == 0 && s.height == 0), isTrue);
    });
  });
}
