import 'package:flutter_test/flutter_test.dart';
import 'package:maintenanceschedular/app_metadata.dart';

void main() {
  test(
    'uses bundled metadata when platform metadata cannot be loaded',
    () async {
      final AppMetadata metadata = await loadAppMetadata(
        packageInfoLoader: () async => throw Exception('version.json missing'),
      );

      expect(metadata.packageName, 'maintenanceschedular');
      expect(metadata.version, '0.1.14');
      expect(metadata.buildNumber, '24');
    },
  );
}
