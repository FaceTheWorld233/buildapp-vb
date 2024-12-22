import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'package:hiddify/features/panel/xboard/utils/log_manager.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

class HttpService {
  static late DomainManager _domainManager;

  // 初始化服务并设置 DomainManager
  static Future<void> initialize(Database db, LogManager logManager) async {
    _domainManager = DomainManager(db, logManager); // 将日志管理器传递给 DomainManager
    await _domainManager.initializeDomains(); 
  }
  // 获取一个可用的域名
  static Future<String?> getAvailableDomain() async {
    return await _domainManager.getAvailableDomain();
  }
  // GET 请求
  Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final String? domain = await _domainManager.getAvailableDomain();

    if (domain == null) {
      throw Exception("No accessible domains available.");
    }

    final url = Uri.parse('$domain$endpoint');
    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          "GET request failed: ${response.statusCode}, ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("GET request error for domain $domain: $e");
    }
  }

  // 获取域名并发送 POST 请求
  Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final String? domain = await _domainManager.getAvailableDomain();

    if (domain == null) {
      throw Exception("No accessible domains available.");
    }

    final url = Uri.parse('$domain$endpoint');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json', ...?headers},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          "POST request failed: ${response.statusCode}, ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("POST request error for domain $domain: $e");
    }
  }
}
