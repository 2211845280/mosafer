class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const AppException({required this.message, this.statusCode, this.code});

  @override
  String toString() =>
      'AppException: $message (code: $code, status: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Unauthorized',
    super.code = 'UNAUTHORIZED',
  });
}

class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    super.message = 'Validation failed',
    super.code = 'VALIDATION_ERROR',
    this.errors,
  });
}
