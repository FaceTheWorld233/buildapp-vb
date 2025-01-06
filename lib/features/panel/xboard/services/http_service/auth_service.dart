// services/auth_service.dart
import 'package:hiddify/features/panel/xboard/services/exceptions/exception_extract.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class AuthService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      return await _httpService.postRequest(
        "/api/v1/passport/auth/login",
        {"email": email, "password": password},
        // requiresHeaders: false,
      );
    } on Exception catch (e) {
      if (e.toString().contains("422")) {
        // 捕获 422 错误并解析响应体中的错误信息
        final errorDetails = extract422ErrorDetails(e.toString());
        throw errorDetails;
      } else if (e.toString().contains("500") || e.toString().contains("400")) {
        final errorDetails = extract500ErrorDetails(e.toString());
        throw errorDetails;
      } else if (e.toString().contains("No accessible domains")) {
        throw "当前没有可用域名，请稍后再试。";
      } else if (e.toString().contains("timeout")) {
        throw "网络超时，请检查网络连接。";
      } else {
        throw "发生未知错误，请稍后重试。";
      }
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String inviteCode,
    String emailCode,
  ) async {
    try {
      // 调用 HttpService 的 postRequest 方法
      return await _httpService.postRequest(
        "/api/v1/passport/auth/register",
        {
          "email": email,
          "password": password,
          "invite_code": inviteCode,
          "email_code": emailCode,
        },
      );
    } on Exception catch (e) {
      if (e.toString().contains("422")) {
        // 捕获 422 错误并解析响应体中的错误信息
        final errorDetails = extract422ErrorDetails(e.toString());
        throw "输入信息有误，请检查您的注册信息。\n$errorDetails";
      } else if (e.toString().contains("500")) {
        final errorDetails = extract500ErrorDetails(e.toString());
        throw errorDetails;
      } else if (e.toString().contains("No accessible domains")) {
        throw "当前没有可用域名，请稍后再试。";
      } else if (e.toString().contains("timeout")) {
        throw "网络超时，请检查网络连接。";
      } else {
        throw "发生未知错误，请稍后重试。";
      }
    }
  }

  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      return await _httpService.postRequest(
        "/api/v1/passport/comm/sendEmailVerify",
        {'email': email},
      );
    } on Exception catch (e) {
      if (e.toString().contains("422")) {
        // 直接返回固定的错误信息
        throw "邮箱格式不正确，请检查输入的邮箱地址。";
      } else if (e.toString().contains("timeout")) {
        // 网络超时错误
        throw "网络连接超时，请稍后重试。";
      } else {
        // 其他未知错误
        throw "发送验证码失败：发生未知错误，请稍后再试。";
      }
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String password, String emailCode) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/forget",
      {
        "email": email,
        "password": password,
        "email_code": emailCode,
      },
    );
  }
}
