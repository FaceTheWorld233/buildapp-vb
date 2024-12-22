import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/utils/global_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserInfoCard extends ConsumerWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final userInfo = ref.watch(userInfoProvider); // 使用全局状态

    if (userInfo == null) {
      return const SizedBox(); // 如果用户信息为空，返回占位
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(userInfo.avatarUrl),
        ),
        title: Text(userInfo.email),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${t.userInfo.plan}: ${userInfo.planId}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                '${t.userInfo.accountStatus}: ${userInfo.banned ? t.userInfo.banned : t.userInfo.active}',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
