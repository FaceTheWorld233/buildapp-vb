// views/user_info_page.dart
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/services/future_provider.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/account_balance_card.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/invite_code_section.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/reset_subscription_button.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/user_info_card.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserInfoPage extends ConsumerWidget {
  const UserInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    // 直接使用已加载的数据
    final userTokenInfo = ref.watch(userTokenInfoProvider);
    final inviteCodes = ref.watch(inviteCodesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.userInfo.pageTitle),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      body: Builder(
        builder: (context) {
          if (userTokenInfo.isLoading || inviteCodes.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "加载中...",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (userTokenInfo.hasError || inviteCodes.hasError) {
            final error = userTokenInfo.error ?? inviteCodes.error;
            return Center(
              child: Text(
                '${t.userInfo.fetchUserInfoError} $error',
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          }

          return const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserInfoCard(),
                SizedBox(height: 16),
                AccountBalanceCard(),
                SizedBox(height: 16),
                InviteCodeSection(),
                SizedBox(height: 16),
                ResetSubscriptionButton(),
              ],
            ),
          );
        },
      ),
    );
  }
}
