import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package_manager_platform_interface.dart';

class AndroidInstalledApp extends InstalledApp {
  final Map<String, String> _inner;

  AndroidInstalledApp(this._inner);

  @override
  String get label => _inner['label']!;

  @override
  String get package => _inner['package']!;
}

/// An implementation of [PackageManagerPlatform] that uses method channels.
class MethodChannelPackageManager extends PackageManagerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('package_manager');

  @override
  Future<List<InstalledApp>> getAllApps() async {
    final version = await methodChannel.invokeMethod<List>('getAllApps');
    return version!.map((element) {
      return AndroidInstalledApp(Map.castFrom(element));
    }).toList();
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
