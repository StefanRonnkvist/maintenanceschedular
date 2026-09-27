import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plannedmaintenance/app/splash_screen.dart';
import 'package:plannedmaintenance/core/theme/theme_provider.dart';

/// Root widget that binds application themes to [ThemeProvider].
class PlannedMaintenanceApp extends StatelessWidget {
  const PlannedMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '2D Laser Maintenance',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
          ),
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
