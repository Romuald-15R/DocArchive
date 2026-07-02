import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // ✅ Misy slash farany
      final data = await _api.get('categories/');
      _categories = (data as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'Tsy afaka naka categories: $e';
      _categories = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCategory(String nom, String description, String couleur) async {
    try {
      // ✅ Misy slash farany
      await _api.post('categories/', {
        'nom': nom,
        'description': description,
        'couleur': couleur,
      });
      await fetchCategories();
      return true;
    } catch (e) {
      _error = 'Tsy afaka nanampy category: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(int id, String nom, String description, String couleur) async {
    try {
      // ✅ Misy slash farany
      await _api.put('categories/$id/', {
        'nom': nom,
        'description': description,
        'couleur': couleur,
      });
      await fetchCategories();
      return true;
    } catch (e) {
      _error = 'Tsy afaka nanova category: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      // ✅ Misy slash farany
      await _api.delete('categories/$id/');
      _categories.removeWhere((cat) => cat.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Tsy afaka namafa category: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}