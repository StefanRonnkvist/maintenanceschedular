import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'contact/contact_page.dart';
import 'db_registry_helpers.dart';
import 'splash_screen.dart';

part 'src/models.dart';
part 'src/drafts.dart';
part 'src/machine_database.dart';
part 'src/app_shell.dart';
part 'src/machine_entry_page.dart';
part 'src/machine_entry_page_due.dart';
part 'src/machine_entry_page_actions.dart';
part 'src/machine_entry_page_forms.dart';
part 'src/machine_entry_page_work_orders.dart';
part 'src/machine_entry_page_calendar.dart';
part 'src/machine_entry_page_reports.dart';
part 'src/machine_entry_page_employees.dart';
part 'src/machine_entry_page_import_export.dart';

const List<String> _maintenanceTaskTypes = [
  'Check',
  'Align',
  'Adjust',
  'Clean',
  'Lubricate',
  'Replace',
];

const List<String> _maintenanceTimeCategories = [
  'Hours',
  'Days',
  'Weeks',
  'Months',
  'Quarters',
  'Semi-Annual',
  'Annual',
  'Biannual',
  'Years',
];

const List<String> _maintenanceSuperCategory = [
  'Assembly Brake',
  'Assembly Burner',
  'Assembly Clutch',
  'Assembly Cooling',
  'Assembly Electrical',
  'Assembly Electronic',
  'Assembly Fluid',
  'Assembly Gas',
  'Assembly Heating',
  'Assembly Hydraulic',
  'Assembly Mechanical',
  'Assembly Pneumatic',
  'Assembly Safety',
  'Assembly Ventilation',
];

const List<String> _subCategories = [
  'Automatic Tool Changer',
  'Actuator',
  'Backup Battery',
  'Bearings',
  'Belts',
  'Bushings',
  'Chains',
  'Circuit Breaker',
  'Contactor',
  'Control Board',
  'Display Unit',
  'Drainage',
  'Emergency Stop',
  'Encoder',
  'Fan',
  'Filter',
  'Firmware',
  'Fluid',
  'Fuse',
  'Gearbox',
  'Harness',
  'Lubricant',
  'Machine Control Unit',
  'Module',
  'Motor',
  'Pan',
  'Power Unit',
  'Pump',
  'Relay',
  'Seal',
  'Sensor',
  'Sprocket',
  'Switch',
  'System Parameters',
  'Thermostat',
  'Transformer',
  'Valve',
];

/// Initializes the platform-specific SQLite factory before mounting the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    // Use native sqflite implementation on Android/iOS/macOS.
    databaseFactory = sqflite.databaseFactory;
  }

  runApp(const MainApp());
}
