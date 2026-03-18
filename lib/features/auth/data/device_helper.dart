import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// Get the device ID for the current platform.
  /// Android: uses the Android device ID
  /// iOS: uses the identifier for vendor (IFV)
  static Future<String> getDeviceId() async {
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor ?? '';
    }
    return '';
  }

  /// Get the platform name ('android' or 'ios')
  static String getPlatformName() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return '';
  }
}
