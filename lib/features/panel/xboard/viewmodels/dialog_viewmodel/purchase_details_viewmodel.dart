// purchase_details_view_model.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/models/order_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

class PurchaseDetailsViewModel extends ChangeNotifier {
  final int planId;
  String? selectedPeriod;
  double? selectedPrice;
  String? tradeNo;
  bool _isLoading = false; // 新增加载状态
  String _statusMessage = ''; // 当前操作状态信息
  final PurchaseService _purchaseService = PurchaseService();
  final OrderService _orderService = OrderService();
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  final TextEditingController couponCodeController = TextEditingController();
  double discount = 1.0;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setStatusMessage(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  PurchaseDetailsViewModel({
    required this.planId,
    this.selectedPeriod,
    this.selectedPrice,
  });

  void setSelectedPrice(double? price, String? period) {
    selectedPrice = price;
    selectedPeriod = period;
    notifyListeners();
  }

  Future<String> handleVerify() async {
    _setLoading(true);
    final accessToken = await getToken();
    if (accessToken == null) return '访问令牌无效';
    try {
      final checkResponse = await _purchaseService.verifyCoupon(planId, accessToken, couponCodeController.text);
      if (checkResponse != null) {
        _setLoading(false); // 加载完成
        final value = checkResponse['data']?['value'];
        if (value != null) {
          if (value is int) {
            discount = (100 - value) / 100;
            return '优惠码可用';
          } else {
            resetDiscount();
            return '优惠码无效';
          }
        }
        resetDiscount();
        return '优惠码无效';
      } else {
        _setLoading(false);
        resetDiscount();
        return '优惠码验证失败';
      }
    } catch (e) {
      _setLoading(false);
      resetDiscount();
      return "$e";
    }
  }

  Future<List<dynamic>> handleSubscribe() async {
    _setLoading(true); // 开始加载
    final accessToken = await getToken();
    if (accessToken == null) {
      _setStatusMessage('访问令牌无效');
      return [];
    }

    try {
      // 检查未支付的订单
      final List<Order> orders =
          await _orderService.fetchUserOrders(accessToken);
      for (final order in orders) {
        if (order.status == 0) {
          // 如果订单未支付
          _setStatusMessage('取消未支付订单 ${order.tradeNo}...');
          await _orderService.cancelOrder(order.tradeNo!, accessToken);
        }
      }
      _setStatusMessage('正在创建新订单...');
      // 创建新订单
      final orderResponse = await _purchaseService.createOrder(
        planId,
        selectedPeriod!,
        accessToken,
        couponCodeController.text
      );
      if (orderResponse != null) {
        tradeNo = orderResponse['data']?.toString();
        if (kDebugMode) {
          _setStatusMessage('订单创建成功，正在获取支付方式...');
        }
        final paymentMethods =
            await _purchaseService.getPaymentMethods(accessToken);
        _setLoading(false); // 加载完成
        return paymentMethods;
      } else {
        _setStatusMessage('订单创建失败');
        return [];
      }
    }  catch (e) {
      _setStatusMessage("$e");
      return [];
    }
  }

  void resetDiscount() {
    discount = 1.0;
    couponCodeController.clear();
  }
}
