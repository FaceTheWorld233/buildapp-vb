import 'package:flutter/material.dart';

class PaymentResultDialog extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const PaymentResultDialog({
    super.key,
    required this.isSuccess,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              child: isSuccess
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                      key: ValueKey("success"),
                    )
                  : const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 80,
                      key: ValueKey("error"),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              isSuccess ? "支付成功" : "支付失败",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "关闭",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
