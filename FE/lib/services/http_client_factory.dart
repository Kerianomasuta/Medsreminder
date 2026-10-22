import 'package:http/http.dart' as http;

import 'api_base_url.dart';
import 'http_client_factory_stub.dart'
    if (dart.library.js_interop) 'http_client_factory_web.dart'
    as platform;
import 'session_refreshing_client.dart';

http.Client createHttpClient() => SessionRefreshingClient(
  platform.createHttpClient(),
  refreshUri: Uri.parse('$apiBaseUrl/api/v1/auth/refreshToken'),
);
