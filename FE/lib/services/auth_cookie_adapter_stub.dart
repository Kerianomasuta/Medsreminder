import 'dart:async';

import 'package:flutter/services.dart';

import 'auth_cookie_adapter.dart';

final AuthCookieAdapter _sharedCookieAdapter = _NativeAuthCookieAdapter();

AuthCookieAdapter createAuthCookieAdapter() => _sharedCookieAdapter;

class _NativeAuthCookieAdapter implements AuthCookieAdapter {
  static const _channel = MethodChannel('com.medsreminder/auth_session');
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
  Future<void> restore() async {
    try {
      final values = await _channel.invokeMapMethod<String, String>(
        'restoreTokens',
      );
      _accessToken = values?['accessToken'];
      _refreshToken = values?['refreshToken'];
    } on MissingPluginException {
      // Tests and unsupported desktop platforms do not install this channel.
    } on PlatformException {
      // A corrupted/locked keystore should fall back to a fresh login.
    }
  }

  @override
  void capture(Map<String, String> responseHeaders) {
    final setCookie = responseHeaders['set-cookie'];
    if (setCookie == null) return;

    _accessToken = _cookieValue(setCookie, 'accessToken') ?? _accessToken;
    _refreshToken = _cookieValue(setCookie, 'refreshToken') ?? _refreshToken;
    unawaited(
      _channel
          .invokeMethod<void>('saveTokens', {
            'accessToken': _accessToken,
            'refreshToken': _refreshToken,
          })
          .catchError((_) {}),
    );
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
    unawaited(_channel.invokeMethod<void>('clearTokens').catchError((_) {}));
  }
}
