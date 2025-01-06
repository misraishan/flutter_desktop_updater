import 'desktop_updater_platform_interface.dart';

class DesktopUpdater {
  Future<String?> getPlatformVersion() {
    return DesktopUpdaterPlatform.instance.getPlatformVersion();
  }

  Future<String?> sayHello() {
    return Future.value("Hello from DesktopUpdater!");
  }

  /// Uygulamayı kapatır ve yeniden başlatır
  Future<void> restartApp() {
    return DesktopUpdaterPlatform.instance.restartApp();
  }
}