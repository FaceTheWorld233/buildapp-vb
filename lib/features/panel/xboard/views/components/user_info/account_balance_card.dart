// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/utils/global_providers.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/widgets/reusable_input_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
class AccountBalanceCard extends ConsumerWidget {
  const AccountBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountBalanceViewmodel = ref.watch(accountBalanceViewmodelProvider);
    final t = ref.watch(translationsProvider);

    if (accountBalanceViewmodel.userInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildAccountBalanceCard(
        accountBalanceViewmodel.userInfo!, t, context, ref);
  }

  Widget _buildAccountBalanceCard(
    UserInfo userInfo,
    Translations t,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(
              "${t.userInfo.balance} (${t.userInfo.onlyForConsumption})",
            ),
            subtitle: Text(
              '${(userInfo.balance / 100).toStringAsFixed(2)} ${t.userInfo.currency}',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.money),
            title: Text(t.userInfo.commissionBalance),
            subtitle: Text(
              '${(userInfo.commissionBalance / 100).toStringAsFixed(2)} ${t.userInfo.currency}',
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => _showReusableDialog(
                  context,
                  t,
                  ref,
                  title: t.transferDialog.transferTitle,
                  labelText: t.transferDialog.transferAmount,
                  confirmText: t.ensure.confirm,
                  cancelText: t.ensure.cancel,
                  onConfirm: (amount) async {
                    final accountBalanceViewModel =
                        ref.read(accountBalanceViewmodelProvider);
                    final success = await accountBalanceViewModel
                        .transferCommission(amount * 100);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? t.transferDialog.transferSuccess
                            : t.transferDialog.transferError),
                      ),
                    );
                  },
                ),
                child: Text(t.transferDialog.transfer),
              ),
              // const SizedBox(width: 8),
              // ElevatedButton(
              //   onPressed: () => _showReusableDialog(
              //     context,
              //     t,
              //     ref,
              //     title: t.transferDialog.withdrawTitle,
              //     labelText: t.transferDialog.withdrawAmount,
              //     confirmText: t.ensure.confirm,
              //     cancelText: t.ensure.cancel,
              //     onConfirm: (amount) async {
              //       final accountBalanceViewModel =
              //           ref.read(accountBalanceViewmodelProvider);
              //       final success = await accountBalanceViewModel
              //           .withdrawFromCommission(amount * 100);
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         SnackBar(
              //           content: Text(success
              //               ? t.transferDialog.withdrawSuccess
              //               : t.transferDialog.withdrawError),
              //         ),
              //       );
              //     },
              //   ),
              //   child: Text(t.transferDialog.withdraw),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReusableDialog(
    BuildContext context,
    Translations t,
    WidgetRef ref, {
    required String title,
    required String labelText,
    required String confirmText,
    required String cancelText,
    required void Function(int amount) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => ReusableInputDialog(
        title: title,
        labelText: labelText,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
      ),
    );
  }
}
