import 'package:flutter/material.dart';

import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/payment_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/plan_service.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'exceptions/exception_extract.dart';

class PurchaseService {
  Future<List<Plan>> fetchPlanData() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      print("No access token found.");
      return [];
    }

    return await PlanService().fetchPlanData(accessToken);
  }

  Future<void> addSubscription(
    BuildContext context,
    String accessToken,
    WidgetRef ref,
    Function showSnackbar,
  ) async {
    Subscription.updateSubscription(context, ref);
  }

  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

  Future<Map<String, dynamic>?> createOrder(
      int planId, String period, String accessToken, String? couponCode) async {
    try {
      return await _orderService.createOrder(accessToken, planId, period, couponCode);
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

  Future<Map<String, dynamic>?> verifyCoupon(
      int planId, String accessToken, String couponCode) async {
    try {
      return await _orderService.verifyCoupon(accessToken, planId, couponCode);
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

  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    return await _paymentService.getPaymentMethods(accessToken);
  }

  Future<Map<String, dynamic>> submitOrder(
      String tradeNo, String method, String accessToken) async {
    return await _paymentService.submitOrder(tradeNo, method, accessToken);
  }
}
