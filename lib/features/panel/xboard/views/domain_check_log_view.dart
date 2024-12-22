import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/utils/log_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DomainCheckLogViewer extends ConsumerWidget {
  const DomainCheckLogViewer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logManager = ref.watch(logManagerProvider);

    return AlertDialog(
      title: const Text(
        "检查日志",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Container(
          width: double.maxFinite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: logManager.logs.map((log) {
              final isInactive =
                  log.contains("未激活") || log.contains("inactive"); // 检查是否为未激活状态
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color:
                          isInactive ? Colors.red : Colors.blueGrey, // 未激活标记为红色
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log,
                        style: TextStyle(
                          fontSize: 14,
                          color: isInactive
                              ? Colors.red
                              : Colors.black87, // 未激活文本标红
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            "关闭",
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
        TextButton(
          onPressed: () {
            ref.read(logManagerProvider).clearLogs();
            Navigator.of(context).pop();
          },
          child: const Text(
            "清空日志",
            style: TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }
}
