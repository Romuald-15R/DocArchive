import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/document_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isSearching = false;
  int? _selectedCategoryId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Charger les catégories si nécessaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedCategoryId == null && _startDate == null && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un critère de recherche'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      // Construction des paramètres de requête
      final params = <String, String>{};
      if (query.isNotEmpty) params['q'] = query;
      if (_selectedCategoryId != null) params['category_id'] = _selectedCategoryId.toString();
      if (_startDate != null) params['date_debut'] = _startDate!.toIso8601String();
      if (_endDate != null) params['date_fin'] = _endDate!.toIso8601String();

      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      // Appel à une méthode search avancée (à adapter selon votre API)
      final results = await docProvider.advancedSearch(params);
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isSearching = false;
        _results = [];
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategoryId = null;
      _startDate = null;
      _endDate = null;
      _results = [];
    });
    _performSearch();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<CategoryProvider>(context).categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche avancée'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _resetFilters,
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulaire de recherche (scrollable si nécessaire)
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Champ texte
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Titre ou contenu OCR',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 12),

                  // Filtre catégorie
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Toutes les catégories')),
                      ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom))),
                    ],
                    onChanged: (value) => setState(() => _selectedCategoryId = value),
                  ),
                  const SizedBox(height: 12),

                  // Plage de dates
                  InkWell(
                    onTap: _selectDateRange,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Période de scan',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _startDate != null && _endDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} → ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'Aucune période sélectionnée',
                          ),
                          Icon(Icons.date_range),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bouton rechercher
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _performSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('Rechercher'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Résultats
          Expanded(
            flex: 2,
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Aucun résultat', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('Modifiez vos critères de recherche', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _results.length,
      itemBuilder: (ctx, i) => DocumentCard(_results[i]),
    );
  }
}