import 'package:flutter/foundation.dart' show kDebugMode;

import '../constants/api_constants.dart';

final Uri _apiBase = Uri.parse(ApiConstants.baseUrl);

final Uri _origin = Uri(
  scheme: _apiBase.scheme,
  host: _apiBase.host,
  port: _apiBase.hasPort ? _apiBase.port : null,
  path: '/',
);

/// Makes an image or audio URL from the API reachable from this device.
String? resolveApiImageUrl(String? image) {
  final value = image?.trim();
  if (value == null || value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri == null) return null;

  // Relative path such as "/storage/4/photo.jpg": put it on the API server.
  if (!uri.hasScheme) {
    return _origin.resolve(value.startsWith('/') ? value : '/$value').toString();
  }

  // Leave data:, file: and other schemes alone.
  if (uri.scheme != 'http' && uri.scheme != 'https') return value;

  final isLoopback = _isLoopbackHost(uri.host);

  // Debug only: the PC address changes (emulator, phone, Wi-Fi), but files from our
  // own server always live under /storage/, so move them onto the current API host.
  final isOurStorage = kDebugMode && uri.path.startsWith('/storage/');

  if (!isLoopback && !isOurStorage) return value;

  return Uri(
    scheme: _apiBase.scheme,
    host: _apiBase.host,
    port: _apiBase.hasPort ? _apiBase.port : null,
    path: uri.path,
    query: uri.hasQuery ? uri.query : null,
    fragment: uri.hasFragment ? uri.fragment : null,
  ).toString();
}

bool _isLoopbackHost(String host) {
  final h = host.toLowerCase();
  return h == 'localhost' || h == '127.0.0.1' || h == '::1';
}