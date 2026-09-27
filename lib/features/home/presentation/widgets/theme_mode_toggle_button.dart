import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plannedmaintenance/core/theme/theme_provider.dart';

/// Displays the active theme mode and advances it when pressed.
class ThemeModeToggleButton extends StatelessWidget {
  const ThemeModeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final icon = switch (themeProvider.themeMode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };

    return IconButton(
      icon: Icon(icon),
      tooltip: 'Cycle theme mode',
      onPressed: themeProvider.toggleTheme,
    );
  }
}
