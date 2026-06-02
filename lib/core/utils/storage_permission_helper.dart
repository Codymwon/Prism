import 'dart:io';
import 'package:flutter/services.dart';

class StoragePermissionHelper {
  static const _channel = MethodChannel('com.meridian.app/storage');

  /// Checks if the app has MANAGE_EXTERNAL_STORAGE permission on Android 11+
  static Future<bool> hasAllFilesAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool hasAccess = await _channel.invokeMethod('isExternalStorageManager');
      return hasAccess;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Requests the user to enable MANAGE_EXTERNAL_STORAGE permission
  static Future<void> requestAllFilesAccess() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestExternalStorageManager');
    } on PlatformException catch (_) {}
  }
}
