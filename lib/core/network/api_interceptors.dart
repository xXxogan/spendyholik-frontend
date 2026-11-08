import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/network/auth_tokens.dart';
import 'package:spendyholik/core/network/session_expiry.dart';
import 'package:spendyholik/core/network/token_storage.dart';

@lazySingleton
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(
    this._tokens,
    this._expiry,
    @Named(refreshDioName) this._plain,
  );

  static const refreshDioName = 'refreshDio';
  static const _refreshPath = 'auth/refresh/';
  static const _public = {'auth/login/', 'auth/register/', _refreshPath};

  /// Каким access ушёл запрос: по нему видно, обновили ли пару, пока он летел.
  static const _sentWith = 'auth.sentWith';

  final TokenStorage _tokens;
  final SessionExpiry _expiry;

  /// Dio без этого интерсептора: refresh и повтор через основной Dio
  /// снова попали бы в очередь onError, которую держит текущий вызов.
  final Dio _plain;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_public.contains(options.path)) {
      final tokens = await _tokens.read();
      if (tokens != null) _authorize(options, tokens.access);
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final tokens = await _tokens.read();
    if (err.response?.statusCode != 401 ||
        _public.contains(options.path) ||
        tokens == null) {
      return handler.next(err);
    }
    var access = tokens.access;
    // Очередь onError: следующий 401 приходит уже после refresh первого —
    // если пара сменилась, хватит повтора с новым access.
    if (options.extra[_sentWith] == tokens.access) {
      final AuthTokens fresh;
      try {
        fresh = await _refresh(tokens.refresh);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 401 || status == 422) {
          await _tokens.clear();
          _expiry.notify();
        }
        return handler.next(err);
      }
      await _tokens.write(fresh);
      access = fresh.access;
    }
    try {
      handler.resolve(await _plain.fetch<dynamic>(_authorize(options, access)));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<AuthTokens> _refresh(String refresh) async {
    final response = await _plain.post<Map<String, dynamic>>(
      _refreshPath,
      data: {'refresh_token': refresh},
    );
    final json = response.data!;
    return AuthTokens(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      accessExpiresAt: DateTime.parse(json['access_expires_at'] as String),
      refreshExpiresAt: DateTime.parse(json['refresh_expires_at'] as String),
    );
  }

  RequestOptions _authorize(RequestOptions options, String access) => options
    ..headers['Authorization'] = 'Bearer $access'
    ..extra[_sentWith] = access;
}
