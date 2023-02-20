import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package_manager_method_channel.dart';

abstract class PackageManagerPlatform extends PlatformInterface {
  PackageManagerPlatform() : super(token: _token);

  static final Object _token = Object();

  static PackageManagerPlatform _instance = MethodChannelPackageManager();

  /// The default instance of [PackageManagerPlatform] to use.
  ///
  /// Defaults to [MethodChannelPackageManager].
  static PackageManagerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PackageManagerPlatform] when
  /// they register themselves.
  static set instance(PackageManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<InstalledApp>> getAllApps() async {
    throw UnimplementedError('getAllApps() has not been implemented.');
  }

  Future<void> launchApp(String package) async {
    throw UnimplementedError('launchApp() has not been implemented.');
  }

  Future<void> launchSettings(String package) async {
    throw UnimplementedError('launchSettings() has not been implemented.');
  }
}

abstract class InstalledApp {
  String get label;
  String get package;
}
