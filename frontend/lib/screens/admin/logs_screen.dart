import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<dynamic> _logs = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;
  String _selectedAction = 'TOUS';
  final ApiService _api = ApiService();

  final Map<String, IconData> _actionIcons = {
    'LOGIN': Icons.login,
    'REGISTER': Icons.person_add,
    'LOGOUT': Icons.logout,
    'UPLOAD': Icons.upload_file,
    'VIEW': Icons.visibility,
    'UPDATE': Icons.edit,
    'DELETE': Icons.delete,
    'UPDATE_PROFILE': Icons.manage_accounts,
    'MANAGE_USER': Icons.admin_panel_settings,
    'DELETE_USER': Icons.person_remove,
  };

  final Map<String, Color> _actionColors = {
    'LOGIN': Colors.blue,
    'REGISTER': Colors.green,
    'LOGOUT': Colors.grey,
    'UPLOAD': Colors.orange,
    'VIEW': Colors.teal,
    'UPDATE': Colors.purple,
    'DELETE': Colors.red,
    'UPDATE_PROFILE': Colors.indigo,
    'MANAGE_USER': Colors.amber,
    'DELETE_USER': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.get('logs');
      setState(() {
        _logs = data;
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Tsy afaka naka logs: $e';
        _loading = false;
      });
    }
  }

  void _filterByAction(String action) {
    setState(() {
      _selectedAction = action;
      _filtered = action == 'TOUS'
          ? _logs
          : _logs.where((l) => l['action'] == action).toList();
    });
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  List<String> get _actionTypes {
    final types = _logs.map((l) => l['action'] as String).toSet().toList();
    types.sort();
    return ['TOUS', ...types];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs (${_filtered.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLogs,
            tooltip: 'Rafraîchir',
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
                        onPressed: _fetchLogs,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filtres responsifs avec Wrap (se mettent à la ligne)
                    if (_logs.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _actionTypes.map((action) {
                            final selected = _selectedAction == action;
                            final color = _actionColors[action] ?? Colors.grey;
                            return FilterChip(
                              label: Text(action),
                              selected: selected,
                              onSelected: (_) => _filterByAction(action),
                              // ignore: deprecated_member_use
                              selectedColor: color.withOpacity(0.2),
                              checkmarkColor: color,
                              labelStyle: TextStyle(
                                color: selected ? color : Colors.grey,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // Zone principale : responsive (GridView sur grand écran, ListView sur mobile)
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(
                              child: Text('Aucun log pour ce filtre', style: TextStyle(color: Colors.grey)),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchLogs,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Si la largeur > 600px, on utilise GridView (responsif)
                                  if (constraints.maxWidth > 600) {
                                    return GridView.builder(
                                      padding: const EdgeInsets.all(8),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 3.5,
                                      ),
                                      itemCount: _filtered.length,
                                      itemBuilder: (ctx, i) =>
                                          _buildLogCard(_filtered[i]),
                                    );
                                  } else {
                                    return ListView.separated(
                                      itemCount: _filtered.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (ctx, i) =>
                                          _buildListTile(_filtered[i]),
                                    );
                                  }
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  // Widget utilisé en mode ListView
  Widget _buildListTile(Map<String, dynamic> log) {
    final action = log['action'] as String? ?? '';
    final color = _actionColors[action] ?? Colors.grey;
    final icon = _actionIcons[action] ?? Icons.info_outline;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Row(
        children: [
          Text(action, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          if (log['document_id'] != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Doc #${log['document_id']}',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log['description_action'] != null)
            Text(log['description_action'], style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _formatDate(log['created_at'] ?? ''),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.computer, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                log['ip_address'] ?? '',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }

  // Widget utilisé en mode GridView (grand écran)
  Widget _buildLogCard(Map<String, dynamic> log) {
    final action = log['action'] as String? ?? '';
    final color = _actionColors[action] ?? Colors.grey;
    final icon = _actionIcons[action] ?? Icons.info_outline;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (log['document_id'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${log['document_id']}',
                      style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (log['description_action'] != null)
              Text(
                log['description_action'],
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatDate(log['created_at'] ?? ''),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.computer, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    log['ip_address'] ?? '',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}