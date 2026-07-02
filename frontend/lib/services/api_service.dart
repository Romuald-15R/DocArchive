import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const Duration _timeout = Duration(seconds: 30);

  /// Récupère le token JWT stocké
  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  /// Construit les en-têtes HTTP
  Future<Map<String, String>> _headers() async {
    String? token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== REQUÊTES JSON ====================

  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Constants.apiBaseUrl}/$endpoint'),
            headers: await _headers(),
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('${Constants.apiBaseUrl}/$endpoint'),
            headers: await _headers(),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final response = await http
          .put(
            Uri.parse('${Constants.apiBaseUrl}/$endpoint'),
            headers: await _headers(),
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${Constants.apiBaseUrl}/$endpoint'),
            headers: await _headers(),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  // ==================== UPLOAD FICHIER (mobile) ====================

  Future<dynamic> uploadFile(
    String endpoint,
    Map<String, String> fields,
    String filePath,
    String fileFieldName,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.apiBaseUrl}/$endpoint'),
      );
      request.headers.addAll(await _headers());
      request.fields.addAll(fields);
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, filePath),
      );
      final response = await request.send().timeout(_timeout);
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('Upload failed: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw _handleException(e);
    }
  }

  // ==================== UPLOAD BYTES (web) ====================

  Future<dynamic> uploadBytes(
    String endpoint,
    Map<String, String> fields,
    Uint8List fileBytes,
    String fileName,
    String fileFieldName,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.apiBaseUrl}/$endpoint'),
      );
      request.headers.addAll(await _headers());
      request.fields.addAll(fields);
      request.files.add(
        http.MultipartFile.fromBytes(
          fileFieldName,
          fileBytes,
          filename: fileName,
        ),
      );
      final response = await request.send().timeout(_timeout);
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('Upload bytes failed: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw _handleException(e);
    }
  }

  // ==================== GESTION DES RÉPONSES ====================

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== GESTION DES ERREURS RÉSEAU ====================

  Exception _handleException(dynamic e) {
    if (e is http.ClientException) {
      return Exception('Erreur réseau : Vérifiez votre connexion Internet');
    } else if (e is SocketException) {
      return Exception('Impossible de joindre le serveur');
    } else if (e is TimeoutException) {
      return Exception('La requête a expiré (serveur trop long à répondre)');
    }
    return Exception('Erreur : $e');
  }
}