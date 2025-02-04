import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package_manager_platform_interface.dart';

class AndroidInstalledApp extends InstalledApp {
  AndroidInstalledApp({required this.label, required this.package});

  static AndroidInstalledApp? fromJson(Map<String, dynamic> json) {
    final label = json['label'] as String?;
    final package = json['package'] as String?;
    if (label != null && package != null) {
      return AndroidInstalledApp(label: label, package: package);
    }
    return null;
  }

  @override
  String label;

  @override
  String package;
}

/// An implementation of [PackageManagerPlatform] that uses method channels.
class MethodChannelPackageManager extends PackageManagerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('package_manager');

  @override
  Future<List<InstalledApp>> getAllApps() async {
    final version =
        await methodChannel.invokeMethod<List<dynamic>>('getAllApps') ??
            const [];
    return version
        .cast<Map>()
        .map((app) => AndroidInstalledApp.fromJson(app.cast()))
        .nonNulls
        .toList();
  }

  @override
  Future<void> launchApp(String package) async {
    await methodChannel
        .invokeMethod<bool>('launchApp', {"packageName": package});
  }

  @override
  Future<void> launchSettings(String package) async {
    await methodChannel
        .invokeMethod<bool>('launchSettings', {"packageName": package});
  }
}
