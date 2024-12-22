// ignore_for_file: use_setters_to_change_properties

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

// 抽象更新策略接口
abstract class UpdateStrategy {
  Future<void> execute(Database db, String url);
}

// API 更新策略
class ApiUpdateStrategy implements UpdateStrategy {
  @override
  Future<void> execute(Database db, String url) async {
    print('Executing API update strategy for: $url');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // 检查字段是否存在并是列表
        if (data['oss_addresses'] is List) {
          final ossAddresses = (data['oss_addresses'] as List)
              .whereType<
                  Map<String, dynamic>>() // 确保每个元素都是 Map<String, dynamic>
              .toList();

          for (final oss in ossAddresses) {
            final ossUrl = oss['oss_url'] as String?;
            final priority = oss['priority'] as int?;

            if (ossUrl == null || priority == null) {
              print('OSS entry missing required fields: $oss');
              continue; // 跳过无效数据
            }

            await db.insert(
              'apiTable',
              {'oss_url': ossUrl, 'priority': priority, 'is_active': 1},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            print('Inserted/Updated OSS address from API: $ossUrl');
          }
        } else {
          throw Exception(
              'Invalid data format: "oss_addresses" is not a list or is null.');
        }
      } catch (e) {
        throw Exception('Failed to parse JSON data from $url: $e');
      }
    } else {
      throw Exception(
          'Failed to fetch data from API: $url, status: ${response.statusCode}');
    }
  }
}

// OSS 更新策略
class OssUpdateStrategy implements UpdateStrategy {
  @override
  Future<void> execute(Database db, String url) async {
    print('Executing OSS update strategy for: $url');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['domains'] is List) {
          final domains = (data['domains'] as List)
              .whereType<Map<String, dynamic>>() // 确保是 Map<String, dynamic>
              .toList();

          for (final domain in domains) {
            final domainUrl = domain['domain'] as String?;
            if (domainUrl == null) {
              print('Domain entry missing "domain" field: $domain');
              continue; // 跳过无效域名
            }

            final isAccessible = await _checkDomainAccessibility(domainUrl);
            if (isAccessible) {
              await db.insert(
                'ossTable',
                {'domain': domainUrl, 'is_active': 1},
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              print('Inserted/Updated domain: $domainUrl');
            } else {
              print('Domain $domainUrl is not accessible.');
            }
          }
        } else {
          throw Exception('Invalid data format: "domains" is not a list.');
        }
      } catch (e) {
        throw Exception('Failed to parse JSON data from $url: $e');
      }
    } else {
      throw Exception(
          'Failed to fetch data from OSS: $url, status: ${response.statusCode}');
    }
  }

  Future<bool> _checkDomainAccessibility(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// 更新服务主类
class UpdateService {
  final Database db;
  UpdateStrategy? strategy;

  UpdateService(this.db);

  // 设置更新策略
  void setStrategy(UpdateStrategy strategy) {
    this.strategy = strategy;
  }

  // 执行更新
  Future<void> update(String url) async {
    if (strategy == null) {
      throw Exception('Update strategy is not set.');
    }
    await strategy!.execute(db, url);
  }
}

// 主监控服务
class OssMonitorService {
  final Database db;

  OssMonitorService(this.db) : _updateService = UpdateService(db);

  final UpdateService _updateService;

  // 初始化并监控
  Future<void> monitorAndUpdateDomains() async {
    final List<Map<String, dynamic>> ossList = await fetchOssData();

    for (final ossEntry in ossList) {
      final ossUrl = ossEntry['oss_url'] as String;
      if (kDebugMode) {
        print('Monitoring OSS URL: $ossUrl');
      }

      try {
        // 使用 OSS 策略更新
        _updateService.setStrategy(OssUpdateStrategy());
        await _updateService.update(ossUrl);

        // 使用 API 策略更新
        _updateService.setStrategy(ApiUpdateStrategy());
        await _updateService.update(ossUrl);
      } catch (e) {
        if (kDebugMode) {
          print('Error during update for $ossUrl: $e');
        }
      }
    }
  }

  // 从数据库中获取所有活跃的 OSS 地址
  Future<List<Map<String, dynamic>>> fetchOssData() async {
    return await db.query('apiTable', where: 'is_active = 1');
  }
}
