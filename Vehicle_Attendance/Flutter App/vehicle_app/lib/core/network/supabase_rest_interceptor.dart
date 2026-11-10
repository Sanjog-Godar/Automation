import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Transparent interceptor routing `/api/attendance`, `/api/fuel-bills`, and
/// `/api/auth` calls directly to the live Supabase PostgREST & GoTrue backends.
///
/// Benefits:
/// 1. Native CORS support across all browsers (Chrome Web, Edge, Safari).
/// 2. Instant database synchronization with zero Vercel cold-starts.
/// 3. Transparent backward-compatibility: repositories, models, and mock tests
///    continue targeting `/api/*` routes without any breaking changes.
class SupabaseRestInterceptor extends Interceptor {
  final Dio _supabaseDio;

  SupabaseRestInterceptor({Dio? customSupabaseDio})
      : _supabaseDio = customSupabaseDio ??
            Dio(
              BaseOptions(
                baseUrl: '${AppConfig.supabaseUrl}/rest/v1',
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                headers: {
                  'apikey': AppConfig.supabaseAnonKey,
                  'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                  'Content-Type': 'application/json',
                },
              ),
            );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // When direct Supabase backend is active, handle endpoints directly
    if (AppConfig.useSupabaseDirect) {
      try {
        final handledResponse = await _handleRequest(options);
        if (handledResponse != null) {
          return handler.resolve(handledResponse);
        }
      } catch (e) {
        debugPrint('[SupabaseRestInterceptor] Error handling ${options.path}: $e');
        // Let it fall through to handler.next(options) if unhandled
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If Next.js proxy request failed with connection/CORS error, fallback to Supabase directly
    final isConnectionOrCors = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.unknown ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);

    if (isConnectionOrCors) {
      try {
        final handledResponse = await _handleRequest(err.requestOptions);
        if (handledResponse != null) {
          debugPrint('[SupabaseRestInterceptor] Successfully resolved ${err.requestOptions.path} via Supabase fallback.');
          return handler.resolve(handledResponse);
        }
      } catch (fallbackError) {
        debugPrint('[SupabaseRestInterceptor] Fallback failed for ${err.requestOptions.path}: $fallbackError');
      }
    }

    super.onError(err, handler);
  }

  Future<Response<dynamic>?> _handleRequest(RequestOptions options) async {
    final path = options.path;
    final method = options.method.toUpperCase();

    // 1. /api/attendance
    if (path == '/api/attendance' || path.endsWith('/api/attendance')) {
      if (method == 'GET') {
        final month = options.queryParameters['month'] as String?;
        if (month != null && month.contains('-')) {
          final parts = month.split('-');
          final y = int.tryParse(parts[0]) ?? 2026;
          final m = int.tryParse(parts[1]) ?? 1;

          final monthStart = DateTime.utc(y, m, 1).toIso8601String().substring(0, 10);
          final monthEnd = DateTime.utc(y, m + 1, 0).toIso8601String().substring(0, 10);

          final res = await _supabaseDio.get(
            '/attendance_logs',
            queryParameters: {
              'log_date': 'gte.$monthStart',
              'and': '(log_date.lte.$monthEnd)',
              'order': 'log_date.asc',
            },
          );

          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {'data': res.data},
          );
        }
      } else if (method == 'POST') {
        final res = await _supabaseDio.post(
          '/attendance_logs',
          options: Options(
            headers: {
              'Prefer': 'resolution=merge-duplicates,return=representation',
            },
          ),
          data: options.data,
        );
        final list = res.data is List ? res.data as List : [res.data];
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {'data': list.isNotEmpty ? list.first : options.data},
        );
      } else if (method == 'DELETE') {
        final logDate = options.queryParameters['log_date'];
        await _supabaseDio.delete(
          '/attendance_logs',
          queryParameters: {'log_date': 'eq.$logDate'},
        );
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {'success': true},
        );
      }
    }

    // 2. /api/fuel-bills
    if (path == '/api/fuel-bills' || path.endsWith('/api/fuel-bills')) {
      if (method == 'GET') {
        final type = options.queryParameters['type'];
        if (type == 'last-date') {
          final res = await _supabaseDio.get(
            '/last_fuel_bill_date',
            queryParameters: {
              'select': 'last_bill_date',
              'id': 'eq.1',
            },
          );
          final list = res.data as List;
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': list.isNotEmpty ? list.first : {'last_bill_date': null}
            },
          );
        } else {
          final res = await _supabaseDio.get(
            '/fuel_bills',
            queryParameters: {
              'select': '*',
              'order': 'end_date.desc',
            },
          );
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {'data': res.data},
          );
        }
      } else if (method == 'POST') {
        final body = Map<String, dynamic>.from(options.data as Map);
        final res = await _supabaseDio.post(
          '/fuel_bills',
          options: Options(
            headers: {
              'Prefer': 'return=representation',
            },
          ),
          data: body,
        );
        final list = res.data is List ? res.data as List : [res.data];
        final created = list.first as Map<String, dynamic>;

        final endDate = body['end_date'] as String?;
        if (endDate != null && endDate.isNotEmpty) {
          try {
            await _supabaseDio.patch(
              '/last_fuel_bill_date',
              queryParameters: {'id': 'eq.1'},
              data: {
                'last_bill_date': endDate,
                'updated_at': DateTime.now().toIso8601String(),
              },
            );
          } catch (e) {
            debugPrint('[SupabaseRestInterceptor] Error syncing last_fuel_bill_date: $e');
          }
        }

        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {'data': created},
        );
      } else if (method == 'PATCH') {
        final body = Map<String, dynamic>.from(options.data as Map);
        final lastBillDate = body['last_bill_date'] as String?;

        if (lastBillDate != null) {
          final res = await _supabaseDio.patch(
            '/last_fuel_bill_date',
            queryParameters: {'id': 'eq.1'},
            options: Options(
              headers: {
                'Prefer': 'return=representation',
              },
            ),
            data: {
              'last_bill_date': lastBillDate,
              'updated_at': DateTime.now().toIso8601String(),
            },
          );
          final list = res.data is List ? res.data as List : [res.data];
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': list.isNotEmpty ? list.first : {'last_bill_date': lastBillDate}
            },
          );
        }

        final id = body['id'];
        if (id != null) {
          final updates = Map<String, dynamic>.from(body)..remove('id');
          final res = await _supabaseDio.patch(
            '/fuel_bills',
            queryParameters: {'id': 'eq.$id'},
            options: Options(
              headers: {
                'Prefer': 'return=representation',
              },
            ),
            data: updates,
          );
          final list = res.data is List ? res.data as List : [res.data];

          final endDate = body['end_date'] as String?;
          if (endDate != null) {
            try {
              await _supabaseDio.patch(
                '/last_fuel_bill_date',
                queryParameters: {'id': 'eq.1'},
                data: {
                  'last_bill_date': endDate,
                  'updated_at': DateTime.now().toIso8601String(),
                },
              );
            } catch (e) {
              debugPrint('[SupabaseRestInterceptor] Error syncing last_fuel_bill_date: $e');
            }
          }

          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {'data': list.isNotEmpty ? list.first : updates},
          );
        }
      }
    }

    // 3. /api/auth/login
    if (path == '/api/auth/login' || path.endsWith('/api/auth/login')) {
      if (method == 'POST') {
        final body = Map<String, dynamic>.from(options.data as Map);
        final email = (body['email'] as String?)?.trim() ?? '';
        final password = body['password'] as String? ?? '';

        final authDio = Dio(
          BaseOptions(
            baseUrl: '${AppConfig.supabaseUrl}/auth/v1',
            headers: {
              'apikey': AppConfig.supabaseAnonKey,
              'Content-Type': 'application/json',
            },
          ),
        );

        final res = await authDio.post(
          '/token',
          queryParameters: {'grant_type': 'password'},
          data: {
            'email': email,
            'password': password,
          },
        );

        final userObj = res.data['user'] as Map<String, dynamic>? ?? {};
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'message': 'Login successful',
            'user': {
              'id': userObj['id'] ?? 'unknown',
              'email': userObj['email'] ?? email,
            },
          },
        );
      }
    }

    // 4. /api/auth/logout
    if (path == '/api/auth/logout' || path.endsWith('/api/auth/logout')) {
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'message': 'Logged out'},
      );
    }

    return null;
  }
}

