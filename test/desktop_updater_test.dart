import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_updater/desktop_updater.dart';
import 'package:desktop_updater/desktop_updater_platform_interface.dart';
import 'package:desktop_updater/desktop_updater_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDesktopUpdaterPlatform
    with MockPlatformInterfaceMixin
    implements DesktopUpdaterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
  
  @override
  Future<void> restartApp() {
    return Future.value();
  }

  @override
  Future<String?> sayHello() {
    return Future.value();
  }
}

void main() {
  final DesktopUpdaterPlatform initialPlatform = DesktopUpdaterPlatform.instance;

  test('$MethodChannelDesktopUpdater is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDesktopUpdater>());
  });

  test('getPlatformVersion', () async {
    DesktopUpdater desktopUpdaterPlugin = DesktopUpdater();
    MockDesktopUpdaterPlatform fakePlatform = MockDesktopUpdaterPlatform();
    DesktopUpdaterPlatform.instance = fakePlatform;

    expect(await desktopUpdaterPlugin.getPlatformVersion(), '42');
  });
}
