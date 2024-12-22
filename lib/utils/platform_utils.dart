import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

abstract class PlatformUtils {
  static bool get isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  /// 获取当前应用的包名
  static Future<String> getCurrentAppPackageName() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.packageName; // 返回应用包名
  }
}
