import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// Unwraps [DioException.error] when it holds an [AppException].
Object unwrapApiError(Object error) {
  if (error is DioException) {
    final inner = error.error;
    if (inner is AppException) {
      return inner;
    }
  }
  if (error is AppException) {
    return error;
  }
  return AppException(message: error.toString());
}

/// Extracts a user-facing message from API-layer errors.
String apiErrorMessage(Object error) {
  final unwrapped = unwrapApiError(error);
  if (unwrapped is AppException) {
    return unwrapped.message;
  }
  return error.toString().replaceFirst('DioException [bad response]: ', '');
}
