// viewmodels/register_viewmodel.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthService _authService;
  // 添加 FormKey
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCountingDown = false;
  bool get isCountingDown => _isCountingDown;

  int _countdownTime = 60;
  int get countdownTime => _countdownTime;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();
  final TextEditingController emailCodeController = TextEditingController();

  RegisterViewModel({required AuthService authService})
      : _authService = authService;

  Future<void> sendVerificationCode(BuildContext context) async {
    final email = emailController.text.trim();
    _isCountingDown = true;
    _countdownTime = 60;
    notifyListeners();

    try {
      final response = await _authService.sendVerificationCode(email);
      print(response);
      if (response["data"] == true) {
        _showSnackbar(context, "验证码发送成功： $email");
      } else {
        _showSnackbar(context, response["message"].toString());
      }
    } catch (e) {
      if (kDebugMode) {
        print('$context, Error: $e');
      }
    }

    // 倒计时逻辑
    while (_countdownTime > 0) {
      await Future.delayed(const Duration(seconds: 1));
      _countdownTime--;
      notifyListeners();
    }

    _isCountingDown = false;
    notifyListeners();
  }

  Future<void> register(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final inviteCode = inviteCodeController.text.trim();
    final emailCode = emailCodeController.text.trim();

    try {
      final result = await _authService.register(
        email,
        password,
        inviteCode,
        emailCode,
      );
      print(result);
      if (result["data"] != null) {
        _showSnackbar(context, "注册成功");
        if (context.mounted) {
          context.go('/login');
        }
      } else {
        _showSnackbar(context, result["message"].toString());
      }
    } catch (e) {
      // 捕获所有错误并显示到页面
      _showSnackbar(context, "$e");
      if (kDebugMode) {
        print('$context, Error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    inviteCodeController.dispose();
    emailCodeController.dispose();
    super.dispose();
  }
}
