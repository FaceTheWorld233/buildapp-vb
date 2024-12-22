import 'package:riverpod_annotation/riverpod_annotation.dart';

class LogManager {
  final List<String> _logs = [];

  List<String> get logs => List.unmodifiable(_logs);

  void addLog(String message) {
    _logs.add("[${DateTime.now()}] $message");
  }

  void clearLogs() {
    _logs.clear();
  }
}

final logManagerProvider = Provider((ref) => LogManager());
