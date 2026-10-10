import 'package:flutter_test/flutter_test.dart';
import 'package:package_manager/package_manager.dart';
import 'package:package_manager/package_manager_platform_interface.dart';
import 'package:package_manager/package_manager_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPackageManagerPlatform
    with MockPlatformInterfaceMixin
    implements PackageManagerPlatform {

  @override
  Future<List<InstalledApp>> getAllApps() => Future.value([]);

  @override
  Future<void> launchApp(String package) => Future.value();

  @override
  Future<void> launchSettings(String package) => Future.value();
}

void main() {
  final PackageManagerPlatform initialPlatform = PackageManagerPlatform.instance;

  test('$MethodChannelPackageManager is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPackageManager>());
  });

  test('getPlatformVersion', () async {
    PackageManager packageManagerPlugin = PackageManager();
    MockPackageManagerPlatform fakePlatform = MockPackageManagerPlatform();
    PackageManagerPlatform.instance = fakePlatform;

    expect(await packageManagerPlugin.getAllApps(), []);
  });
}
