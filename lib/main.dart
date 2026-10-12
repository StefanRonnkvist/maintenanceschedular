import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plannedmaintenance/app/planned_maintenance_app.dart';
import 'package:plannedmaintenance/core/storage/app_database.dart';
import 'package:plannedmaintenance/core/theme/theme_provider.dart';

/// Starts the app after opening its local database.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const PlannedMaintenanceApp(),
    ),
  );
}
