import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/services/monitor_pay_status.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hiddify/features/panel/xboard/views/components/dialog/payment_result_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentMethodsViewModel extends ChangeNotifier {
  final String tradeNo;
  final double totalAmount;
  final VoidCallback onPaymentSuccess;
  final PurchaseService _purchaseService = PurchaseService();

  bool _isDisposed = false;

  PaymentMethodsViewModel({
    required this.tradeNo,
    required this.totalAmount,
    required this.onPaymentSuccess,
  });

  @override
  void dispose() {
    _isDisposed = true; // 标记 ViewModel 已经被销毁
    super.dispose();
  }

Future<void> handlePayment(
      BuildContext context, dynamic selectedMethod) async {
    final accessToken = await getToken(); // 获取用户的token
    try {
      final response = await _purchaseService.submitOrder(
        tradeNo,
        selectedMethod['id'].toString(),
        accessToken!,
      );


      final type = response['type'];
      final data = response['data'];

      if (type is int) {
        if (type == -1 && data == true) {
          if (kDebugMode) {
            print('订单已通过钱包余额支付成功，无需跳转支付页面');
          }
          handlePaymentSuccess(context); // 显示成功动画
          return;
        }

        if (type == 1 && data is String) {
          openPaymentUrl(data); // 打开支付链接
          monitorOrderStatus(context); // 监听订单状态
          return;
        }
      }

      if (kDebugMode) {
        print('支付处理失败: 意外的响应。');
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PaymentResultDialog(
          isSuccess: false,
          message: "支付失败，请重试或联系支持。",
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('支付错误: $e');
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PaymentResultDialog(
          isSuccess: false,
          message: "支付过程中出现问题，请稍后再试。",
        ),
      );
    }
  }

  Future<void> monitorOrderStatus(BuildContext context) async {
    final accessToken = await getToken();
    if (accessToken == null) return;

    MonitorPayStatus().monitorOrderStatus(tradeNo, accessToken, (bool isPaid) {
      if (isPaid) {
        if (kDebugMode) {
          print('订单支付成功');
        }
        _safeCall(() => handlePaymentSuccess(context));
      } else {
        if (kDebugMode) {
          print('订单未支付');
        }
      }
    });
  }

void handlePaymentSuccess(BuildContext context) {
    if (kDebugMode) {
      print('订单已标记为已支付。');
    }
    // 显示成功动画
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PaymentResultDialog(
        isSuccess: true,
        message: "感谢您的支付，订单已完成！",
      ),
    ).then((_) {
      // 支付成功后回调
      onPaymentSuccess();

    });
  }

  void openPaymentUrl(String paymentUrl) {
    final Uri url = Uri.parse(paymentUrl);
    launchUrl(url);
  }

  /// 安全调用回调，避免在销毁后调用 notifyListeners
  void _safeCall(VoidCallback callback) {
    if (!_isDisposed) {
      callback();
    }
  }
}
