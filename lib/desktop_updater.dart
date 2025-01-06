import 'package:flutter/services.dart';

import 'desktop_updater_platform_interface.dart';
import 'dart:io';

class DesktopUpdater {
  Future<String?> getPlatformVersion() {
    return DesktopUpdaterPlatform.instance.getPlatformVersion();
  }

  Future<String?> sayHello() {
    return Future.value("Hello from DesktopUpdater!");
  }

  /// Uygulamayı kapatır ve yeniden başlatır
  Future<void> restartApp() {
    if (!Platform.isMacOS && !Platform.isLinux) {
      throw PlatformException(
        code: 'Unsupported Platform',
        message: 'This feature is only supported on macOS and Linux',
      );
    }
    return DesktopUpdaterPlatform.instance.restartApp();
  }
}