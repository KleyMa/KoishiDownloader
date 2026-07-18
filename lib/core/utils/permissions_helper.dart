import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class that requests the correct Android runtime permissions
/// depending on the device's SDK version.
class PermissionsHelper {
  PermissionsHelper._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns the Android SDK version, or `0` on non-Android platforms.
  static Future<int> _androidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    final info = await _deviceInfo.androidInfo;
    return info.version.sdkInt;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Storage / Media permissions
  // ──────────────────────────────────────────────────────────────────────────

  /// Requests the appropriate storage or media permissions.
  ///
  /// * **Android 13+ (API 33)**: `READ_MEDIA_AUDIO` + `READ_MEDIA_VIDEO`
  /// * **Android 12 and below**: `READ_EXTERNAL_STORAGE` + `WRITE_EXTERNAL_STORAGE`
  /// * In both cases also requests `MANAGE_EXTERNAL_STORAGE` so the app can
  ///   write to arbitrary directories chosen by the user.
  ///
  /// Returns `true` if all critical permissions were granted.
  static Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    final sdkVersion = await _androidSdkVersion();
    final List<Permission> permissions;

    if (sdkVersion >= 33) {
      permissions = [
        Permission.audio,
        Permission.videos,
      ];
    } else {
      permissions = [
        Permission.storage,
      ];
    }

    // Request the scoped permissions first.
    final Map<Permission, PermissionStatus> results =
        await permissions.request();

    final bool scopedGranted = results.values.every(
      (status) => status.isGranted || status.isLimited,
    );

    // Request MANAGE_EXTERNAL_STORAGE separately since it navigates to
    // a system settings screen on API 30+.
    bool manageGranted = await Permission.manageExternalStorage.isGranted;
    if (!manageGranted) {
      final manageStatus = await Permission.manageExternalStorage.request();
      manageGranted =
          manageStatus.isGranted || manageStatus.isLimited;
    }

    return scopedGranted && manageGranted;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Notification permission
  // ──────────────────────────────────────────────────────────────────────────

  /// Requests the `POST_NOTIFICATIONS` permission on Android 13+.
  ///
  /// On older versions this is a no-op that returns `true`.
  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    final sdkVersion = await _androidSdkVersion();
    if (sdkVersion < 33) return true;

    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Convenience – request everything at once
  // ──────────────────────────────────────────────────────────────────────────

  /// Requests both storage/media and notification permissions.
  ///
  /// Returns `true` only if **all** permissions were granted.
  static Future<bool> requestAllPermissions() async {
    final storageGranted = await requestStoragePermissions();
    final notificationGranted = await requestNotificationPermission();
    return storageGranted && notificationGranted;
  }
}
