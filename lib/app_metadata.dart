import 'package:package_info_plus/package_info_plus.dart';

const String fallbackPackageName = String.fromEnvironment(
  'APP_PACKAGE_NAME',
  defaultValue: 'maintenanceschedular',
);
const String fallbackAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '0.1.14',
);
const String fallbackBuildNumber = String.fromEnvironment(
  'APP_BUILD_NUMBER',
  defaultValue: '24',
);

/// Package identity and build information displayed by the application.
class AppMetadata {
  const AppMetadata({
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  final String packageName;
  final String version;
  final String buildNumber;
}

/// Loads metadata from the current platform package.
///
/// The optional [packageInfoLoader] makes the platform boundary replaceable in
/// tests. Missing, blank, or unavailable values fall back to compile-time
/// constants so callers always receive usable metadata.
Future<AppMetadata> loadAppMetadata({
  Future<PackageInfo> Function()? packageInfoLoader,
}) async {
  try {
    final PackageInfo packageInfo =
        await (packageInfoLoader ?? PackageInfo.fromPlatform)();

    return AppMetadata(
      packageName: packageInfo.packageName.trim().isEmpty
          ? fallbackPackageName
          : packageInfo.packageName,
      version: packageInfo.version.trim().isEmpty
          ? fallbackAppVersion
          : packageInfo.version,
      buildNumber: packageInfo.buildNumber.trim().isEmpty
          ? fallbackBuildNumber
          : packageInfo.buildNumber,
    );
  } catch (_) {
    return const AppMetadata(
      packageName: fallbackPackageName,
      version: fallbackAppVersion,
      buildNumber: fallbackBuildNumber,
    );
  }
}
