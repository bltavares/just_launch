import 'package_manager_platform_interface.dart';

class PackageManager {
  Future<List<InstalledApp>> getAllApps() async {
    return PackageManagerPlatform.instance.getAllApps();
  }

  Future<void> launchApp(String package) async {
    return PackageManagerPlatform.instance.launchApp(package);
  }

  Future<void> launchSettings(String package) async {
    return PackageManagerPlatform.instance.launchSettings(package);
  }
}
