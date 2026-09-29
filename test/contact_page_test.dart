import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenanceschedular/contact/contact_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('contact form shows version and environment information', (
    WidgetTester tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'Maintenance Schedular',
      packageName: 'com.example.maintenanceschedular',
      version: '0.1.4',
      buildNumber: '14',
      buildSignature: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: createContactPage(
          serverUrl: 'https://example.com',
          showAppBar: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Send a Question'), findsOneWidget);
    expect(find.text('AAB version'), findsOneWidget);
    expect(find.text('MSIX version'), findsOneWidget);
    expect(find.text('0.1.4 (build 14)'), findsNWidgets(2));
    expect(find.text('Platform'), findsOneWidget);
    expect(find.text('Orientation'), findsOneWidget);
    expect(find.text('Layout'), findsOneWidget);
  });

  testWidgets('contact form falls back when package metadata is empty', (
    WidgetTester tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: '',
      packageName: '',
      version: '',
      buildNumber: '',
      buildSignature: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: createContactPage(
          serverUrl: 'https://example.com',
          showAppBar: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('maintenanceschedular'), findsOneWidget);
    expect(find.text('0.1.14 (build 24)'), findsNWidgets(2));
    expect(find.text('Package detection failed.'), findsNothing);
  });
}
