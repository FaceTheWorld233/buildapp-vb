import 'dart:io'; // 用于平台判断
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class SubscriptionService {
  final HttpService _httpService = HttpService();

  // 获取订阅链接的方法
  Future<String?> getSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/getSubscribe",
      headers: {
        'Authorization': accessToken,
      },
    );

    if (result.containsKey("data")) {
      final data = result["data"];
      if (data is Map<String, dynamic> && data.containsKey("subscribe_url")) {
        final baseLink = data["subscribe_url"] as String?;
        return _appendPlatformSuffix(baseLink); // 动态添加平台后缀
      }
    }

    // 返回 null 或抛出异常，如果数据结构不匹配
    throw Exception("Failed to retrieve subscription link");
  }

  // 重置订阅链接的方法
  Future<String?> resetSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/resetSecurity",
      headers: {
        'Authorization': accessToken,
      },
    );
    if (result.containsKey("data")) {
      final data = result["data"];
      if (data is String) {
        return _appendPlatformSuffix(data); // 动态添加平台后缀
      }
    }
    throw Exception("Failed to reset subscription link");
  }

  Future<String?> getPlanName(String token) async {
    try {
      final response = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {'Authorization': token},
      );

      // 检查 "subscribe_url" 字段是否存在，作为判断条件
      if (response['data']?['subscribe_url'] != null) {
        // 提取 "name" 字段并返回
        final name = response['data']?['plan']?['name'];
        return name as String?;
      } else {
        return null; // 如果 "subscribe_url" 不存在，返回 null
      }
    } catch (_) {
      return null; // 出现错误时返回 null
    }
  }

  // 动态判断平台并添加后缀
  String? _appendPlatformSuffix(String? url) {
    if (url == null) return null;

    final platform = _getPlatform();
    if (platform != null) {
      return '$url&platform=$platform';
    }
    return url;
  }

  // 判断当前运行的操作系统
  String? _getPlatform() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else if (Platform.isMacOS) {
      return null;
    } else {
      return null; // 无法判断平台时返回 null
    }
  }
}
