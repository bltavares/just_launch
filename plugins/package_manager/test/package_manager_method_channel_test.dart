import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_manager/package_manager_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelPackageManager platform = MethodChannelPackageManager();
  const MethodChannel channel = MethodChannel('package_manager');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '[]';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getAllApps(), []);
  });
}
