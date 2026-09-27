import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plannedmaintenance/core/theme/theme_provider.dart';
import 'package:plannedmaintenance/features/help/presentation/help_page.dart';
import 'package:plannedmaintenance/features/home/presentation/home_page.dart';
import 'package:plannedmaintenance/features/home/presentation/widgets/pwa_database_notice.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows help categories and expands their guidance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HelpPage())),
    );

    expect(find.text('Getting started'), findsOneWidget);
    expect(find.text('Schedule fields'), findsOneWidget);
    expect(find.text('App settings and data'), findsOneWidget);
    expect(find.text('Skill levels and safety'), findsOneWidget);
    expect(find.text('Troubleshooting and contact'), findsOneWidget);

    await tester.tap(find.text('Getting started'));
    await tester.pumpAndSettle();

    expect(find.text('Find a maintenance task'), findsOneWidget);
    expect(find.text('Change an earlier selection'), findsOneWidget);

    await tester.tap(find.text('Getting started'));
    await tester.pumpAndSettle();

    final Finder appSettingsCategory = find.text('App settings and data');
    await tester.ensureVisible(appSettingsCategory);
    await tester.tap(appSettingsCategory);
    await tester.pumpAndSettle();

    expect(find.text('Offline maintenance data'), findsOneWidget);
    expect(find.text('Change the theme'), findsOneWidget);
  });

  testWidgets('opens the Help tab by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('Help Center'), findsOneWidget);
  });

  testWidgets('shows and dismisses the red PWA database notice', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PwaDatabaseNotice())),
    );

    const String noticeText =
        'PWA notice: database functions are not available on web builds. '
        'Data is temporary for this browser session only.';
    final Finder notice = find.text(noticeText);
    final Finder noticeMaterial = find.ancestor(
      of: notice,
      matching: find.byType(Material),
    );

    expect(notice, findsOneWidget);
    expect(
      tester.widget<Material>(noticeMaterial.first).color,
      Theme.of(tester.element(notice)).colorScheme.error,
    );

    await tester.tap(find.byTooltip('Dismiss PWA notice'));
    await tester.pump();

    expect(notice, findsNothing);
  });
}
