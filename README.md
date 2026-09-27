# 2D Laser Maintenance

2D Laser Maintenance is a cross-platform reference app for planned maintenance
on 2D laser systems and supporting equipment. It turns bundled schedule data
into a guided lookup: each selection narrows the available choices until the
matching task details are displayed.

## Features

- Guided lookup by equipment group and task, with dependent fields cleared
	automatically when an earlier selection changes.
- Automatic display of fields that have only one matching value.
- Estimated duration, required level, maintenance sheet, out-of-service status,
	and interval details.
- L1 operator, L2 maintenance technician, and L3 authorized service technician
	descriptions.
- Offline browsing of maintenance schedules and level descriptions.
- Expandable help for the workflow, schedule fields, safety, settings, and
	troubleshooting.
- Optional support form with app and platform diagnostics.
- System, light, and dark themes.

## Using the App

1. Open the **Maintenance** tab and choose a **Group**.
2. Continue through each field that appears. A field with one matching value is
	filled automatically.
3. Review the description, estimated time, required level, maintenance sheet,
	out-of-service status, and applicable intervals.
4. Change any earlier choice to start a different lookup; dependent values are
	reset automatically.
5. Use **Help** for field definitions and safety guidance, or **Information** to
	send a support question.

The app is a reference aid and does not replace official machine manuals,
maintenance sheets, training, lockout procedures, or workplace safety rules.
Always use the current approved procedure and personnel with the required level
and authorization.

## Connectivity and Privacy

Maintenance schedules and skill-level descriptions are bundled with the app and
can be browsed without an internet connection. The support form requires an
internet connection. When submitted, it sends the entered name, email address,
and question together with the application package, version, build, platform,
orientation, and layout details to the configured HTTPS support endpoint.

The app does not include analytics, advertising, or tracking SDKs and does not
request camera, location, microphone, or storage permissions. The repository
contains build targets for Android, iOS, web, Windows, macOS, and Linux.

## Data Assets

- `assets/data.csv` contains the hierarchical maintenance schedule.
- `assets/level.csv` contains personnel-level names and descriptions.

CSV loading and parsing are handled in
`lib/features/maintenance/data/csv_data_loader.dart` and its parser layer.

## Project Structure

- `lib/app/`: application shell and `MaterialApp` configuration.
- `lib/contact/`: support request form and submission handling.
- `lib/core/`: shared services such as theme state.
- `lib/features/home/`: tab navigation and app bar.
- `lib/features/help/`: categorized help and safety content.
- `lib/features/maintenance/`: CSV models, parsing, loading, and maintenance UI.
- `store_listing/`: Google Play listing copy.
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

Google Play short and full descriptions are maintained in
`store_listing/google_play_store_listing.txt`.
