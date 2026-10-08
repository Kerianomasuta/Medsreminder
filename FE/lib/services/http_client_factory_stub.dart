import 'package:http/http.dart' as http;

import 'auth_cookie_adapter.dart';

http.Client createHttpClient() =>
    _CookieClient(http.Client(), AuthCookieAdapter());

class _CookieClient extends http.BaseClient {
  _CookieClient(this._inner, this._cookies);

  final http.Client _inner;
  final AuthCookieAdapter _cookies;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _cookies.requestHeaders.forEach((key, value) {
      request.headers.putIfAbsent(key, () => value);
    });
    final response = await _inner.send(request);
    _cookies.capture(response.headers);
    return response;
  }

  @override
  void close() => _inner.close();
}
