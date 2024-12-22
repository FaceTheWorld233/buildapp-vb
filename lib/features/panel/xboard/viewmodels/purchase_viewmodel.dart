import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';

class PurchaseViewModel extends ChangeNotifier {
  final PurchaseService _purchaseService;
  List<Plan> _plans = [];
  String? _errorMessage;
  bool _isLoading = false;
  bool _hasFetchedData = false; // 新增变量，指示是否已经加载过数据

  List<Plan> get plans => _plans;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  PurchaseViewModel({required PurchaseService purchaseService})
      : _purchaseService = purchaseService;

  // 加载数据的唯一方法
  Future<void> fetchPlans() async {
    // 如果已经加载过数据，直接返回，不再加载
    if (_hasFetchedData) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _plans = await _purchaseService.fetchPlanData();
      _hasFetchedData = true; // 标记数据已经加载
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
