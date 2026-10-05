import 'auth_cookie_adapter.dart';

AuthCookieAdapter createAuthCookieAdapter() => _WebAuthCookieAdapter();

class _WebAuthCookieAdapter implements AuthCookieAdapter {
  @override
  String? get accessToken => null;

  @override
  Map<String, String> get requestHeaders => const {};

  @override
  void capture(Map<String, String> responseHeaders) {
    // Browsers intentionally hide Set-Cookie and HttpOnly cookies from Dart/JS.
  }

  @override
  void clear() {}
}
