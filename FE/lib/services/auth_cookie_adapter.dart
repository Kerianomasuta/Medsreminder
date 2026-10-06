import 'auth_cookie_adapter_stub.dart'
    if (dart.library.js_interop) 'auth_cookie_adapter_web.dart'
    as platform;

abstract interface class AuthCookieAdapter {
  factory AuthCookieAdapter() => platform.createAuthCookieAdapter();

  Map<String, String> get requestHeaders;
  String? get accessToken;

  void capture(Map<String, String> responseHeaders);
  void clear();
}
