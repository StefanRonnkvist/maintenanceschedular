import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plannedmaintenance/app/planned_maintenance_app.dart';
import 'package:plannedmaintenance/core/theme/theme_provider.dart';

/// Starts the app with a shared provider that owns the selected theme mode.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const PlannedMaintenanceApp(),
    ),
  );
}
