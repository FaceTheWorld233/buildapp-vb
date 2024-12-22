import 'package:flutter/material.dart';

class ReusableInputDialog extends StatelessWidget {
  final String title;
  final String labelText;
  final String confirmText;
  final String cancelText;
  final void Function(int amount) onConfirm;

  const ReusableInputDialog({
    super.key,
    required this.title,
    required this.labelText,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController amountController = TextEditingController();

    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: amountController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: labelText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = int.tryParse(amountController.text) ?? 0;
            if (amount > 0) {
              onConfirm(amount);
            }
            Navigator.pop(context);
          },
          child: Text(confirmText),
        ),
      ],
    );
  }
}
