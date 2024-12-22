// viewmodels/domain_check_viewmodel.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/domain/models/init_database.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/utils/log_manager.dart';
class DomainCheckViewModel extends ChangeNotifier {
  final LogManager logManager;

  bool _isChecking = true;
  bool _isSuccess = false;
  int _retryCount = 0;
  int _dotsCount = 0;
  Timer? _timer;

  bool get isChecking => _isChecking;
  bool get isSuccess => _isSuccess;
  int get retryCount => _retryCount;
  String get progressIndicator => '检查中${'.' * _dotsCount}';

  DomainCheckViewModel(this.logManager);

  Future<void> initialize() async {
    logManager.addLog("开始域名检查...");
    checkDomain();
  }

Future<void> checkDomain() async {
    _isChecking = true;
    _isSuccess = false;
    _retryCount++;
    _dotsCount = 0;
    notifyListeners();

    logManager.addLog("尝试第 $_retryCount 次检查域名...");
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _dotsCount = (_dotsCount + 1) % 4;
      notifyListeners();
    });

    try {
      // 初始化数据库
      final db = await initDatabase();
      logManager.addLog("数据库初始化完成。");

      // 初始化 HTTP 服务
      await HttpService.initialize(db, logManager);
      logManager.addLog("域名检查成功！");
      _isSuccess = true;
      _timer?.cancel();
    } catch (e) {
      logManager.addLog("域名检查失败：$e");

      // 针对 SQLiteException code 14 的处理逻辑
      if (e.toString().contains("SqliteException(14)")) {
        logManager.addLog("检测到 SQLite 数据库文件损坏，尝试重新创建数据库...");
        try {
          // 删除损坏的数据库文件并重建
          await recreateDatabase();
          logManager.addLog("数据库重新创建成功，重新初始化检查...");
          await checkDomain();
          return; // 避免后续错误继续触发重试
        } catch (recreateError) {
          logManager.addLog("重新创建数据库失败：$recreateError");
        }
      }

      _isSuccess = false;
      _timer?.cancel();

      // 延迟后再次尝试检查
      Future.delayed(const Duration(seconds: 2), () {
        checkDomain();
      });
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  void retry() {
    logManager.addLog("用户手动触发重新检查。");
    _retryCount = 0;
    checkDomain();
  }
}
