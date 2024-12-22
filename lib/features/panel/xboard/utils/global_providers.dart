// global_providers.dart
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/account_balance_viewmodel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userInfoProvider = StateProvider<UserInfo?>((ref) => null);
final accountBalanceViewmodelProvider =
    ChangeNotifierProvider((ref) => AccountBalanceViewmodel());
