import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/balance.service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/user_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

class AccountBalanceViewmodel extends ChangeNotifier {
  UserInfo? _userInfo;

  UserInfo? get userInfo => _userInfo;
  
  AccountBalanceViewmodel() {
    fetchUserInfo(); // 自动调用用户信息获取
  }

  Future<void> fetchUserInfo() async {
    final token = await getToken();
    if (token != null) {
      _userInfo = await UserService().fetchUserInfo(token);
      notifyListeners();
    }
  }

  Future<bool> transferCommission(int amount) async {
    final token = await getToken();
    if (token == null) return false;

    final success = await BalanceService().transferCommission(token, amount);
    if (success) {
      await fetchUserInfo(); // 更新用户信息
    }
    return success;
  }

  Future<bool> withdrawFromCommission(int amount) async {
    final token = await getToken();
    if (token == null) return false;

    final success = await BalanceService().transferCommission(token, amount);
    if (success) {
      await fetchUserInfo(); // 更新用户信息
    }
    return success;
  }
}
