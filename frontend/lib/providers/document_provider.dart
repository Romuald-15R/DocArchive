import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../services/api_service.dart';
import '../models/document.dart';
import '../utils/constants.dart';

class DocumentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Document> _documents = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  String? _error;

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // Getter public pour accéder à l'API (ex: token, upload)
  ApiService get api => _api;

  // ==================== FETCH (avec pagination) ====================
  Future<void> fetchDocuments({bool refresh = false}) async {
    if (refresh) {
      _documents.clear();
      _currentPage = 0;
      _hasMore = true;
    }
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final offset = _currentPage * _pageSize;
      final data = await _api.get('documents/?limit=$_pageSize&offset=$offset');
      final List<Document> newDocs = (data as List)
          .map((json) => Document.fromJson(json))
          .toList();

      if (newDocs.length < _pageSize) _hasMore = false;
      _documents.addAll(newDocs);
      _currentPage++;
    } catch (e) {
      _error = 'Erreur chargement: $e';
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDocuments() async {
    await fetchDocuments(refresh: true);
  }

  // ==================== RECHERCHE SIMPLE ====================
  Future<List<Document>> searchDocuments(String query) async {
    try {
      final data = await _api.get('documents/search?q=$query');
      return (data as List).map((json) => Document.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== RECHERCHE AVANCÉE ====================
  Future<List<Document>> advancedSearch(Map<String, String> params) async {
    try {
      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final data = await _api.get('documents/search?$queryString');
      return (data as List).map((json) => Document.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Recherche avancée échouée: $e');
    }
  }

  // ==================== GET ONE ====================
  Future<Document?> getDocument(int id) async {
    try {
      final data = await _api.get('documents/$id');
      return Document.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // ==================== UPLOAD MOBILE ====================
  Future<bool> addDocument({
    required String titre,
    String? description,
    required String fileType,
    required String ocrText,
    required int categorieId,
    required String filePath,
  }) async {
    final fields = {
      'titre': titre,
      'description': description ?? '',
      'file_type': fileType,
      'ocr_text': ocrText,
      'categorie_id': categorieId.toString(),
    };
    try {
      await _api.uploadFile('documents/', fields, filePath, 'file');
      await refreshDocuments();
      return true;
    } catch (e) {
      _error = 'Upload échoué: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== UPLOAD WEB ====================
  Future<bool> addDocumentWeb({
    required String titre,
    String? description,
    required String fileType,
    required String ocrText,
    required int categorieId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final token = await _api.getToken();
      if (token == null) throw Exception('Non authentifié');

      final uri = Uri.parse('${Constants.apiBaseUrl}/documents/');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['titre'] = titre;
      request.fields['description'] = description ?? '';
      request.fields['file_type'] = fileType;
      request.fields['ocr_text'] = ocrText;
      request.fields['categorie_id'] = categorieId.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      final response = await request.send();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await refreshDocuments();
        return true;
      } else {
        _error = 'Upload web échoué (${response.statusCode})';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Upload web error: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== UPDATE ====================
  Future<bool> updateDocument(int id, {
    String? titre,
    String? description,
    int? categorieId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (titre != null) body['titre'] = titre;
      if (description != null) body['description'] = description;
      if (categorieId != null) body['categorie_id'] = categorieId;
      await _api.put('documents/$id', body);
      await refreshDocuments();
      return true;
    } catch (e) {
      _error = 'Update échoué: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== DELETE (soft ou hard) ====================
  Future<bool> deleteDocument(int id, {bool hard = false}) async {
    try {
      final endpoint = hard ? 'documents/$id?hard=true' : 'documents/$id';
      await _api.delete(endpoint);
      if (!hard) {
        // Suppression logique : on la retire de la liste locale
        _documents.removeWhere((doc) => doc.id == id);
        notifyListeners();
      } else {
        // Suppression physique : on recharge toute la liste
        await refreshDocuments();
      }
      return true;
    } catch (e) {
      _error = 'Suppression échouée: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== UTILITAIRES ====================
  void clearError() {
    _error = null;
    notifyListeners();
  }
}