import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _error;
  final ApiService _api = ApiService();

  final List<Color> _catColors = [
    Colors.blue, Colors.green, Colors.orange,
    const Color.fromARGB(255, 215, 210, 216), Colors.red, Colors.teal,
  ];

  final Map<String, IconData> _actionIcons = {
    'LOGIN': Icons.login,
    'REGISTER': Icons.person_add,
    'UPLOAD': Icons.upload_file,
    'VIEW': Icons.visibility,
    'UPDATE': Icons.edit,
    'DELETE': Icons.delete,
    'UPDATE_PROFILE': Icons.manage_accounts,
    'LOGOUT': Icons.logout,
  };

  final Map<String, Color> _actionColors = {
    'LOGIN': Colors.blue,
    'REGISTER': Colors.green,
    'UPLOAD': Colors.orange,
    'VIEW': Colors.teal,
    'UPDATE': const Color.fromARGB(255, 214, 204, 216),
    'DELETE': Colors.red,
    'UPDATE_PROFILE': Colors.indigo,
    'LOGOUT': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.get('dashboard/stats');
      setState(() {
        _stats = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Tsy afaka naka ny stats: $e';
        _loading = false;
      });
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadStats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Total documents
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.folder_copy, size: 32, color: Colors.blue.shade700),
                          ),
                          title: const Text('Total documents', style: TextStyle(fontWeight: FontWeight.w500)),
                          trailing: Text(
                            '${_stats['total_documents'] ?? 0}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Documents par catégorie
                      const Text('Documents par catégorie',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      (_stats['documents_by_category'] as List? ?? []).isEmpty
                          ? const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Aucune catégorie', style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : Column(
                              children: List.generate(
                                (_stats['documents_by_category'] as List).length,
                                (i) {
                                  final cat = _stats['documents_by_category'][i];
                                  final color = _catColors[i % _catColors.length];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        // ignore: deprecated_member_use
                                        backgroundColor: color.withOpacity(0.15),
                                        child: Icon(Icons.label, color: color),
                                      ),
                                      title: Text(cat['nom'] ?? ''),
                                      trailing: Chip(
                                        label: Text('${cat['count']}',
                                            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                                        // ignore: deprecated_member_use
                                        backgroundColor: color.withOpacity(0.1),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                      const SizedBox(height: 20),

                      // Activités récentes
                      const Text('Activités récentes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      (_stats['recent_activities'] as List? ?? []).isEmpty
                          ? const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Aucune activité', style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : Column(
                              children: (_stats['recent_activities'] as List).map<Widget>((activity) {
                                final action = activity['action'] as String? ?? '';
                                final color = _actionColors[action] ?? Colors.grey;
                                final icon = _actionIcons[action] ?? Icons.info_outline;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        // ignore: deprecated_member_use
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(icon, color: color, size: 20),
                                    ),
                                    title: Text(action, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
                                    subtitle: Text(_formatDate(activity['created_at'] ?? '')),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
    );
  }
}