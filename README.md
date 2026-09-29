# Maintenance Schedular

Maintenance Schedular is a local-first Flutter application for organizing
machines, sub-assemblies, recurring maintenance tasks, employees, work orders,
and schedule forecasts.

Core records are stored in an on-device SQLite database. The app does not
require a hosted service, and provides JSON and CSV tools for moving selected
data between installations. The optional Information form uses an internet
connection to send a support request with app and platform details.

## What This App Does

- Register machines with model, serial, location, manufacturer, operating-hour,
	maintenance-document, and license-requirement details.
- Add sub-assemblies and recurring tasks to each machine.
- Use built-in or custom task types, component categories, skills, and license
	types.
- Forecast date-based maintenance from each machine's last-check date.
- Record machine and sub-assembly detail changes with timestamped history.
- Search and filter machines by maintenance task.
- Manage employees, skills, and license qualifications.
- Assign scheduled tasks to employees who hold every license required by the
	machine; use the contractor-needed option when no employee qualifies.
- Save the current work-order outcome as Work Complete, Partial, or Bypass,
	with optional notes and rescheduling for Partial or Bypass work.
- Generate PDF reports for the machine list, schedule, and work orders.
- Export and import machine-registry data as JSON.
- Export and import employees or machines as CSV, with templates for bulk entry.
- Choose a light, dark, or system theme and arrange the tabs for the current
	device.

## Scheduling Logic

Tasks support Hours, Days, Weeks, Months, Quarters, Semi-Annual, Annual,
Biannual, and Years intervals.

Calendar dates are calculated only for date-based intervals. They use the
machine's last-check date as the baseline and select the next recurring date on
or after today. Approximate day conversions are used: 30 days per month, 91 per
quarter, 182 per half-year, 365 per year, and 730 per biannual interval. Hours
tasks remain part of the maintenance record but do not receive a calendar date.

The Work Orders view includes sub-assemblies whose earliest calculated task is
due within the next five days. Employee qualification is based on the licenses
required by the machine. Skills are recorded for workforce reference but are
not used by the assignment filter.

## Main UI Sections

- Add Machine
- Machines List
- Employees
- Schedule (maintenance due)
- Work Orders
- Forecast (calendar)
- Edit Machines
- Help
- Information (support request)

The tab order, light/dark/system theme, and employee-list search, filter, and
sort choices are stored in local preferences.

## Platform Notes

- Android, iOS, and macOS use native `sqflite`.
- Windows and Linux use `sqflite_common_ffi`.
- Web builds open with a warning, but database functions are unavailable and
	entered data is temporary for the current browser session. Use a native build
	for persistent records.

## Tech Stack

- Flutter (Material 3)
- SQLite (`sqflite`, `sqflite_common_ffi`)
- PDF generation and print/share (`pdf`, `printing`)
- File picker for CSV workflows (`file_picker`)
- CSV parsing/serialization (`csv`)
- Local app preferences (`shared_preferences`)

## Getting Started

### Prerequisites

- Flutter SDK (matching `pubspec.yaml` SDK constraints)
- Platform toolchains for your target (Android Studio/Xcode/Windows build tools)

### Install Dependencies

```powershell
flutter pub get
```

### Run the App

```powershell
flutter run
```

Optional examples:

```powershell
flutter run -d windows
flutter run -d android
```

## Build Commands

You can use the workspace tasks, or run Flutter directly.

Direct commands:

```powershell
flutter build apk --release
flutter build appbundle --release
flutter build web --release
flutter build windows --release
```

MSIX packaging (Windows, after building the Windows release):

```powershell
dart run msix:create --build-windows=false
```

## Data Import And Export

Database actions are available from the toolbar storage icon.

- Export Database: creates JSON containing machines, required licenses,
	sub-assemblies, maintenance tasks, skill types, employees, employee skills,
	and employee licenses.
- Import Database: replaces the current registry with supported data from a
	compatible JSON export.
- Export Employees CSV / Export Machines CSV.
- Import Employees CSV / Import Machines CSV.
- Create Employee CSV Template / Create Machine CSV Template.

The JSON format covers the registry, but it does not include machine or
sub-assembly detail-history rows, work-order statuses, or saved task
assignments. Importing replaces the registry and clears those excluded records.
Treat the export as a transferable registry backup, not a complete operational
archive.

CSV files are intentionally narrower: machine CSV does not include
sub-assemblies or tasks, and employee CSV contains employee names, skills, and
licenses.

CSV notes:

- Employee required field: `name`
- Machine required fields: `name`, `modelName`, `modelNumber`
- Multi-value employee `skills` and `licenses` are semicolon-separated.
- License booleans accept `1/0`, `true/false`, or `yes/no`.

## Privacy And Connectivity

- Machine, employee, schedule, and work-order records stay in the app's local
	database; there is no hosted account or synchronization service.
- PDF, JSON, and CSV files leave the app only when you choose an export, print,
	or share action.
- Sending the Information form posts your name, email address, question, app
	version/build, platform, orientation, layout class, and submission time to
	the configured support endpoint.

## Validation

```powershell
flutter analyze
flutter test
```

## Repository Utilities

### Dependency Snapshot

Run this command from the repository root to regenerate dependency reports:

```powershell
./tool/dependency_snapshot.ps1
```

Generated files:

- `reports/dependency/dependency-health.md`
- `reports/dependency/pub-outdated.txt`
- `reports/dependency/pub-deps-compact.txt`
- `reports/dependency/snapshot-timestamp.txt`
