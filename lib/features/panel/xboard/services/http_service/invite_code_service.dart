// services/invite_service.dart
import 'package:hiddify/features/panel/xboard/models/invite_code_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class InviteCodeService {
  final HttpService _httpService = HttpService();
  // 生成邀请码的方法
  Future<bool> generateInviteCode(String accessToken) async {
    try {
      await _httpService.getRequest(
        "/api/v1/user/invite/save",
        headers: {'Authorization': accessToken},
      );
      // 如果请求成功，直接返回 true
      return true;
    } catch (e) {
      // 捕获异常，解析并抛出更友好的错误信息
      if (e.toString().contains("已达到创建数量上限")) {
        throw Exception("错误：已达到邀请码的创建数量上限，无法继续创建新邀请码。");
      } else {
        throw Exception("错误：已达到邀请码的创建数量上限，无法继续创建新邀请码。");
      }
    }
  }

  // 获取邀请码数据的方法
  Future<List<InviteCode>> fetchInviteCodes(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/invite/fetch",
      headers: {'Authorization': accessToken},
    );

    if (result.containsKey("data") && result["data"] is Map<String, dynamic>) {
      final data = result["data"];
      // ignore: avoid_dynamic_calls
      final codes = data["codes"] as List;
      return codes
          .cast<Map<String, dynamic>>()
          .map((json) => InviteCode.fromJson(json))
          .toList();
    } else {
      throw Exception("错误：邀请码获取失败！");
    }
  }

  // 获取完整邀请码链接的方法
  Future<String> getInviteLink(String code) async {
    final String? baseUrl = await HttpService.getAvailableDomain();

    final inviteLinkBase = "$baseUrl/#/register?code=";
    return '$inviteLinkBase$code';
  }
}
