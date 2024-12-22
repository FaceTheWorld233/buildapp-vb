import 'dart:async';
import 'package:hiddify/features/panel/xboard/utils/log_manager.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DomainManager {
  final Database db;
  final LogManager logManager;
  final int failureThreshold = 3; // 达到3次失败就降级
  final Duration healthCheckInterval = const Duration(minutes: 5);
  final List<String> _cache = []; // 缓存可用域名
  Timer? _healthCheckTimer;

  static const String _cachedDomainKey = 'cachedDomain';

  DomainManager(this.db, this.logManager) {
    _startHealthCheck();
  }

  // 初始化时从缓存或数据库加载可用域名
  Future<void> initializeDomains() async {
    logManager.addLog('Initializing domain manager...');
    final prefs = await SharedPreferences.getInstance();
    final cachedDomain = prefs.getString(_cachedDomainKey);

    // 1. 优先使用缓存的域名
    if (cachedDomain != null && await _checkDomainAccessibility(cachedDomain)) {
      _cache.add(cachedDomain);
      logManager.addLog('Loaded cached domain: $cachedDomain');
    } else {
      // 2. 从数据库获取域名列表
      await _loadDomainsFromDatabase();
    }

    // 记录所有活跃域名的状态到日志
    await _logDomainStatus();
  }

  // 从数据库中加载活跃域名
  Future<void> _loadDomainsFromDatabase() async {
    final List<Map<String, dynamic>> ossList = await db.query(
      'ossTable',
      where: 'is_active = 1',
    );
    _cache.addAll(ossList.map((e) => e['domain'] as String));
    logManager.addLog('Loaded active domains from ossTable: $_cache');
  }


  // 遍历所有表并记录所有域名状态到日志
  Future<void> _logDomainStatus() async {
    logManager.addLog('Logging domain statuses from all tables...');
    for (String tableName in ['apiTable', 'ossTable', 'backupApis']) {
      final List<Map<String, dynamic>> allEntries = await db.query(tableName);

      if (allEntries.isEmpty) {
        logManager.addLog('No domains found in $tableName.');
      } else {
        for (var entry in allEntries) {
          final domain =
              entry['oss_url'] ?? entry['domain'] ?? entry['api_url'];
          final isActive = entry['is_active'] == 1;
          logManager.addLog(
              'Domain in $tableName: $domain - ${isActive ? "Active" : "Inactive"}');
        }
      }
    }
  }

  // 获取一个可用的域名
  Future<String?> getAvailableDomain() async {
    for (String domain in _cache) {
      if (await _checkDomainAccessibility(domain)) {
        await _cacheDomain(domain); // 更新本地缓存
        return domain;
      }
    }
    return null;
  }

  // 记录域名成功的请求
  Future<void> recordSuccess(String domain) async {
    await db.update('ossTable', {'is_active': 1},
        where: 'domain = ?', whereArgs: [domain]);
    if (!_cache.contains(domain)) _cache.add(domain);
    await _cacheDomain(domain); // 更新本地缓存
  }

  // 记录域名失败的请求
  Future<void> recordFailure(String domain) async {
    final result =
        await db.query('ossTable', where: 'domain = ?', whereArgs: [domain]);
    if (result.isNotEmpty) {
      final failures = (result.first['failures'] as int?) ?? 0;
      if (failures + 1 >= failureThreshold) {
        await db.update('ossTable', {'is_active': 0, 'failures': 0},
            where: 'domain = ?', whereArgs: [domain]);
        _cache.remove(domain);
      } else {
        await db.update('ossTable', {'failures': failures + 1},
            where: 'domain = ?', whereArgs: [domain]);
      }
    }
  }

  // 缓存当前可用域名到本地存储
  Future<void> _cacheDomain(String domain) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedDomainKey, domain);
  }

  // 周期性健康检查，恢复降级的域名
  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (_) async {
      final List<Map<String, dynamic>> inactiveDomains = await db.query(
        'ossTable',
        where: 'is_active = 0',
      );

      for (final entry in inactiveDomains) {
        final String domain = entry['domain'] as String;
        if (await _checkDomainAccessibility(domain)) {
          await db.update('ossTable', {'is_active': 1},
              where: 'domain = ?', whereArgs: [domain]);
          if (!_cache.contains(domain)) _cache.add(domain);
        }
      }
    });
  }

  // 停止健康检查
  void dispose() {
    _healthCheckTimer?.cancel();
  }

  // 检查域名可用性
  Future<bool> _checkDomainAccessibility(String domain) async {
    try {
      final response = await http
          .get(Uri.parse(domain))
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
