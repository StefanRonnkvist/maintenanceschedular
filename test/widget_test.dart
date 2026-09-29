// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maintenanceschedular/main.dart';
import 'package:maintenanceschedular/splash_screen.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {});

    await tester.pumpWidget(const MainApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(find.byType(MainApp), findsOneWidget);
  });

  testWidgets('splash screen is replaced after its delay', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(onGenerateRoute: _splashTestRoute),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('App ready'), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('App ready'), findsOneWidget);
  });
}

Route<void> _splashTestRoute(RouteSettings settings) {
  return MaterialPageRoute<void>(
    builder: (_) => const SplashScreen(
      duration: Duration(milliseconds: 100),
      nextScreen: Text('App ready'),
    ),
  );
}
