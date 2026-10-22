import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/l10n/l10n.dart';
import 'package:prism/features/graph/presentation/widgets/graph_settings_panel.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestablePanel({
    double repulsionRate = 0.5,
    double repulsionPercentage = 0.5,
    double attractionRate = 0.35,
    double damping = 0.85,
    VoidCallback? onClose,
    VoidCallback? onResetDefaults,
    VoidCallback? onReLayout,
  }) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Stack(
            children: [
              GraphSettingsPanel(
                repulsionRate: repulsionRate,
                repulsionPercentage: repulsionPercentage,
                attractionRate: attractionRate,
                damping: damping,
                onChangedRepulsionRate: (_) {},
                onChangedRepulsionPercentage: (_) {},
                onChangedAttractionRate: (_) {},
                onChangedDamping: (_) {},
                onClose: onClose ?? () {},
                onResetDefaults: onResetDefaults ?? () {},
                onReLayout: onReLayout ?? () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('renders human-centered terminology for graph simulation settings and tooltips', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestablePanel());
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Graph Settings'), findsOneWidget);

    // Verify humanized parameter titles
    expect(find.text('Node Spacing'), findsOneWidget);
    expect(find.text('Connection Length'), findsOneWidget);
    expect(find.text('Connection Tension'), findsOneWidget);
    expect(find.text('Motion Smoothness'), findsOneWidget);

    // Verify old technical physics terms are NOT present
    expect(find.text('Repulsion Force'), findsNothing);
    expect(find.text('Link Spring Distance'), findsNothing);
    expect(find.text('Spring Stiffness'), findsNothing);
    expect(find.text('Simulation Damping'), findsNothing);

    // Verify tooltips with humanized helper text are configured
    expect(find.byTooltip('Adjust how far unconnected notes sit from each other'), findsOneWidget);
    expect(find.byTooltip('Adjust the length of links between related notes'), findsOneWidget);
    expect(find.byTooltip('Adjust the tension of links between related notes'), findsOneWidget);
    expect(find.byTooltip('Control how quickly nodes settle into place'), findsOneWidget);
  });
}
