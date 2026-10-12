# Planned Maintenance
Planned Maintenance (shown in the app as **2D Laser Maintenance**) is an offline
reference for planned maintenance tasks on 2D laser systems and supporting
equipment. It uses bundled schedule data and guided selections to help you find
task requirements and references. It is not an equipment registry or a work
order and workforce management system.

## Features
- Guided lookup by equipment group and task; each selection filters the next
  available choices, and later choices reset when an earlier selection changes.
- Automatic selection and display when only one value matches.
- Task descriptions, estimated time, required personnel level, maintenance sheet
  references, out-of-service status, and applicable service intervals.
- Descriptions for L1 operator, L2 maintenance technician, and L3 authorized
  service technician levels.
- Bundled maintenance schedules and level descriptions available offline.
- Expandable help covering navigation, schedule fields, safety, settings, and
  troubleshooting.
- Tabbed navigation for maintenance lookup, help, and support information.
- Local database persistence for maintenance selections and editable support form
  fields (name, email, and unsent question).
- Optional support-question form and system, light, and dark appearance modes.

## Using the App
1. Open the **Maintenance** tab and choose a **Group**.
2. Continue through the fields shown. A value is filled in automatically when
   only one choice matches.
3. Review the task description, estimated time, personnel level, maintenance
   sheet, out-of-service status, and applicable intervals.
4. Change an earlier selection to explore a different task; dependent choices
   are cleared automatically.
5. Open **Help** for guidance, or **Information** to send a support question.
6. Maintenance selections and support-form fields are saved locally and restored
   when you reopen the app. A successfully submitted question is cleared; your
   name and email remain saved for future requests.

This app is a reference aid. It does not replace the machine manual, approved
maintenance sheets, qualified training, lockout procedures, or workplace safety
requirements. Always follow current approved instructions and use appropriately
qualified and authorized personnel.

## Connectivity and Privacy
Browsing the bundled maintenance schedule does not require an internet
connection. Sending a support question does. The form submits the name, email
address, and question you enter, together with app version/build, package,
platform, orientation, and layout information, to the configured HTTPS support
service. Editable support-form values are stored in the local app database on
your device or browser. Do not include sensitive information in a support request.

## Data Assets

- `assets/data.csv` contains the hierarchical maintenance schedule.
- `assets/level.csv` contains personnel-level names and descriptions.

The CSV loader and parser are in
`lib/features/maintenance/data/csv_data_loader.dart` and
`lib/features/maintenance/data/parsers/maintenance_csv_parser.dart`.

## Project Structure

- `lib/app/`: application shell and launch screen.
- `lib/contact/`: support-question form and submission handling.
- `lib/core/`: shared application state, including theme mode.
- `lib/features/home/`: tab navigation and app bar.
- `lib/features/help/`: in-app guidance and safety information.
- `lib/features/maintenance/`: schedule loading, parsing, and guided lookup UI.
- `store_listing/`: Google Play listing descriptions.
- `test/`: widget and unit tests.

## Development

Flutter SDK requirements are defined in `pubspec.yaml`.

```bash
flutter pub get
flutter run
```

Run static analysis and tests before building a release:

```bash
flutter analyze
flutter test
```

Common release builds:

```bash
flutter build apk --release
flutter build appbundle --release
flutter build web --release
flutter build windows --release
```

## Store Listing
The Google Play short and full descriptions are in
`store_listing/google_play_short_description.txt` and
`store_listing/google_play_long_description.txt`. The corresponding
`google_play_store_*_listing.txt` files are kept as compatibility copies.

The listing describes the app's current guided maintenance-reference features;
it does not claim equipment registry, workforce, work-order, reporting, or bulk
import/export functionality, which this app does not provide.
