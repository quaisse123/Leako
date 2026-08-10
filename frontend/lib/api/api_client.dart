// 🌐 ApiClient — Wrapper HTTP centralisé
// Teste la connexion internet AVANT chaque requête API.
// Si pas de connexion → attend que la connexion revienne (le ConnectivityGate
// affiche alors le dialogue global "Aucune connexion internet").
// Cela évite les faux positifs du ping périodique et garantit que le test
// n'a lieu que lorsqu'une requête est réellement envoyée.

import 'dart:async';
import 'dart:convert';
import 'package:frontend/services/connectivity_service.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Attend que la connexion soit disponible avant d'exécuter la requête.
  Future<void> _ensureConnected() async {
    await ConnectivityService().waitForConnection();
  }

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    await _ensureConnected();
    return http.get(url, headers: headers);
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    await _ensureConnected();
    return http.post(url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    await _ensureConnected();
    return http.put(url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    await _ensureConnected();
    return http.patch(url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    await _ensureConnected();
    return http.delete(url, headers: headers, body: body, encoding: encoding);
  }
}
