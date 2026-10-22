import 'dart:async';

import 'package:http/http.dart' as http;

/// Retries one API request after renewing an expired cookie-based session.
///
/// The refresh operation is shared by every client instance so simultaneous
/// 401 responses do not rotate the same refresh token multiple times.
class SessionRefreshingClient extends http.BaseClient {
  SessionRefreshingClient(this._inner, {required this.refreshUri});

  final http.Client _inner;
  final Uri refreshUri;

  static Future<bool>? _refreshInFlight;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final snapshot = await _RequestSnapshot.from(request);
    final firstResponse = await _inner.send(snapshot.toRequest());

    if (firstResponse.statusCode != 401 || _isAuthRequest(request.url)) {
      return firstResponse;
    }

    // Drain the first response before issuing another browser request.
    final firstBody = await firstResponse.stream.toBytes();
    if (await _refreshSession()) {
      return _inner.send(snapshot.toRequest());
    }

    return _restoreResponse(firstResponse, firstBody);
  }

  bool _isAuthRequest(Uri uri) => uri.path.startsWith('/api/v1/auth/');

  Future<bool> _refreshSession() async {
    final pending = _refreshInFlight;
    if (pending != null) return pending;

    final refresh = _performRefresh();
    _refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) _refreshInFlight = null;
    }
  }

  Future<bool> _performRefresh() async {
    try {
      final request = http.Request('POST', refreshUri)
        ..headers['Content-Type'] = 'application/json; charset=utf-8'
        ..body = '{}';
      final response = await _inner.send(request);
      await response.stream.drain<void>();
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  http.StreamedResponse _restoreResponse(
    http.StreamedResponse response,
    List<int> body,
  ) => http.StreamedResponse(
    Stream<List<int>>.value(body),
    response.statusCode,
    contentLength: body.length,
    request: response.request,
    headers: response.headers,
    isRedirect: response.isRedirect,
    persistentConnection: response.persistentConnection,
    reasonPhrase: response.reasonPhrase,
  );

  @override
  void close() => _inner.close();
}

class _RequestSnapshot {
  const _RequestSnapshot({
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
    required this.followRedirects,
    required this.maxRedirects,
    required this.persistentConnection,
  });

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final List<int> body;
  final bool followRedirects;
  final int maxRedirects;
  final bool persistentConnection;

  static Future<_RequestSnapshot> from(http.BaseRequest request) async =>
      _RequestSnapshot(
        method: request.method,
        url: request.url,
        headers: Map<String, String>.from(request.headers),
        body: await request.finalize().toBytes(),
        followRedirects: request.followRedirects,
        maxRedirects: request.maxRedirects,
        persistentConnection: request.persistentConnection,
      );

  http.Request toRequest() => http.Request(method, url)
    ..followRedirects = followRedirects
    ..maxRedirects = maxRedirects
    ..persistentConnection = persistentConnection
    ..headers.addAll(headers)
    ..bodyBytes = body;
}
