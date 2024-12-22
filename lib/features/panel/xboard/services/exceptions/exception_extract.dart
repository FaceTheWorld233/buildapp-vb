// 提取并中文化 422 错误信息
import 'dart:convert';

String extract422ErrorDetails(String exceptionMessage) {
  try {
    // 从错误消息中提取 JSON 部分
    final jsonStartIndex = exceptionMessage.indexOf("{");
    final jsonString = exceptionMessage.substring(jsonStartIndex);
    final Map<String, dynamic> errorResponse =
        json.decode(jsonString) as Map<String, dynamic>;

    if (errorResponse.containsKey("errors")) {
      final Map<String, dynamic> errors =
          errorResponse["errors"] as Map<String, dynamic>;
      final errorMessages = errors.entries.map((entry) {
        final messages = (entry.value as List).join(", ");
        return messages;
      }).toList();

      return errorMessages.join(", ");
    }
  } catch (_) {
    // 解析失败返回通用错误
    return "无法解析详细错误信息，请稍后重试。";
  }
  return "未知错误。";
}
String extract500ErrorDetails(String exceptionMessage) {
  try {
    // 从错误消息中提取 JSON 部分
    final jsonStartIndex = exceptionMessage.indexOf("{");
    final jsonString = exceptionMessage.substring(jsonStartIndex);

    // 将解析后的 JSON 转换为 Map<String, dynamic>
    final Map<String, dynamic> errorResponse =
        json.decode(jsonString) as Map<String, dynamic>;

    // 提取 message 字段
    if (errorResponse.containsKey("message")) {
      final String message = errorResponse["message"] as String; // 直接提取为 String
      return message;
    }
  } catch (e) {
    // 如果解析失败，返回默认的通用错误信息
    return "无法解析服务器错误信息，请稍后重试。";
  }
  return "未知的服务器错误。";
}
