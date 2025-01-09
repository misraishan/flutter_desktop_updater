import "package:desktop_updater/src/app_archive.dart";
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'desktop_updater_platform_interface.dart';

/// An implementation of [DesktopUpdaterPlatform] that uses method channels.
class MethodChannelDesktopUpdater extends DesktopUpdaterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('desktop_updater');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> restartApp() async {
    await methodChannel.invokeMethod<void>('restartApp');
  }

  @override
  Future<String?> sayHello() async {
    return await methodChannel.invokeMethod<String>('sayHello');
  }

  @override
  Future<String?> getExecutablePath() async {
    return await methodChannel.invokeMethod<String>('getExecutablePath');
  }

  @override
  Future<List<FileHashModel?>> verifyFileHash(String oldHashFilePath, String newHashFilePath) async {
    throw UnimplementedError('verifyFileHash() has not been implemented.');
  }
}
