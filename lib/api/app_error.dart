// lib/api/app_error.dart
import 'package:dio/dio.dart';
import 'client.dart';
import 'model.dart';



class AppError {
  final String code;   
  final String message;  
  AppError(this.code, this.message);
}

AppError mapDioError(Object err) {
  
  AppError fallback(String code, String msg) => AppError(code, msg);

  if (err is DioException) {
    // Network/connectivity
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return fallback('NETWORK_TIMEOUT', 'The request timed out.');
    }
    if (err.type == DioExceptionType.connectionError) {
      return fallback('NETWORK_ERROR', 'Cannot reach the server.');
    }

    final status = err.response?.statusCode;
    final data = err.response?.data;

    
    if (data is Map<String, dynamic>) {
      final code = (data['code'] as String?)?.toUpperCase();
      final msg  = (data['message'] as String?) ?? '';
      if (code != null) return AppError(code, msg);
    } else if (data is String) {
      
      final s = data.toLowerCase();
      if (s.contains('room') && s.contains('not found')) {
        return fallback('ROOM_CODE_INVALID', 'Room not found');
      }
      if (s.contains('non unique')) {
        return fallback('NON_UNIQUE_USER', 'Multiple users matched');
      }
    }

    // Generic by status code
    switch (status) {
      case 400: return fallback('BAD_REQUEST', 'Bad request.');
      case 401: return fallback('UNAUTHORIZED', 'Please sign in again.');
      case 403: return fallback('FORBIDDEN', 'You don’t have permission.');
      case 404: return fallback('NOT_FOUND', 'Not found.');
      case 409: return fallback('CONFLICT', 'Conflict.');
      case 422: return fallback('VALIDATION_ERROR', 'Validation failed.');
      case 500: return fallback('SERVER_ERROR', 'Server error.');
      case 503: return fallback('SERVICE_UNAVAILABLE', 'Service unavailable.');
    }
  }

  return AppError('UNKNOWN', 'Something went wrong.');
}

String friendlyMessage(AppError e) {
  switch (e.code) {
    case 'ROOM_CODE_INVALID':
    case 'NOT_FOUND':
      return "That room code doesn’t look right.";
    case 'FORBIDDEN':
      return "You don’t have permission for that action.";
    case 'NON_UNIQUE_USER':
      return "Odd — we found more than one of you in our database. Please contact support.";
    case 'NETWORK_TIMEOUT':
      return "Hmm, that took too long. Check your connection and try again.";
    case 'NETWORK_ERROR':
      return "We can’t reach the server. Are you online?";
    case 'SERVER_ERROR':
    case 'SERVICE_UNAVAILABLE':
      return "We’re having trouble on our end. Please try again.";
    default:
      return "Something went wrong. Please try again.";
  }
}
