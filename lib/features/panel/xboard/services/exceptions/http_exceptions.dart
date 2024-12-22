class HttpRequestException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseBody;
  final bool shouldMarkDomainUnusable;

  HttpRequestException({
    required this.message,
    this.statusCode,
    this.responseBody,
    this.shouldMarkDomainUnusable = false,
  });

  @override
  String toString() {
    return 'HttpRequestException($statusCode): $message, Response: $responseBody';
  }
}
