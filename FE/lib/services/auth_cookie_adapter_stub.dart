import 'auth_cookie_adapter.dart';

final AuthCookieAdapter _sharedCookieAdapter = _NativeAuthCookieAdapter();

AuthCookieAdapter createAuthCookieAdapter() => _sharedCookieAdapter;

class _NativeAuthCookieAdapter implements AuthCookieAdapter {
  static String? _accessToken;
  static String? _refreshToken;

  @override
  String? get accessToken => _accessToken;

  @override
  Map<String, String> get requestHeaders {
    final cookies = <String>[
      if (_accessToken != null) 'accessToken=$_accessToken',
      if (_refreshToken != null) 'refreshToken=$_refreshToken',
    ];
    return cookies.isEmpty ? const {} : {'Cookie': cookies.join('; ')};
  }

  @override
  void capture(Map<String, String> responseHeaders) {
    final setCookie = responseHeaders['set-cookie'];
    if (setCookie == null) return;

    _accessToken = _cookieValue(setCookie, 'accessToken') ?? _accessToken;
    _refreshToken = _cookieValue(setCookie, 'refreshToken') ?? _refreshToken;
  }

  String? _cookieValue(String header, String name) {
    final match = RegExp('(?:^|[,;]\\s*)$name=([^;,]*)').firstMatch(header);
    if (match == null) return null;
    final value = match.group(1);
    return value == null || value.isEmpty ? null : value;
  }

  @override
  void clear() {
    _accessToken = null;
    _refreshToken = null;
  }
}
