import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';

class ForgetPasswordViewModel extends ChangeNotifier {
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
  final TextEditingController emailCodeController = TextEditingController();

  ForgetPasswordViewModel({required AuthService authService})
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
        _showSnackbar(context, "验证码已发送到： $email");
      } else {
        _showSnackbar(context, response["message"].toString());
      }
    } catch (e) {
      if (kDebugMode) {
        print('$context, Error: $e');
      }
      _showSnackbar(context, "发送验证码失败：$e");
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

  Future<void> resetPassword(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final emailCode = emailCodeController.text.trim();

    try {
      final result =
          await _authService.resetPassword(email, password, emailCode);
      print(result);
      if (result["data"] == true) {
        _showSnackbar(context, "密码重置成功，请重新登录");
      } else {
        _showSnackbar(context, result["message"].toString());
      }
    } catch (e) {
      _showSnackbar(context, "密码重置失败：$e");
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
    emailCodeController.dispose();
    super.dispose();
  }
}
