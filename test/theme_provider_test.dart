import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plannedmaintenance/core/theme/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    test(
      'defaults to system mode and cycles through system, light, and dark',
      () {
        final provider = ThemeProvider();

        expect(provider.themeMode, ThemeMode.system);
        expect(provider.isSystemMode, isTrue);

        provider.toggleTheme();
        expect(provider.themeMode, ThemeMode.light);
        expect(provider.isLightMode, isTrue);

        provider.toggleTheme();
        expect(provider.themeMode, ThemeMode.dark);
        expect(provider.isDarkMode, isTrue);

        provider.toggleTheme();
        expect(provider.themeMode, ThemeMode.system);
        expect(provider.isSystemMode, isTrue);
      },
    );
  });
}
