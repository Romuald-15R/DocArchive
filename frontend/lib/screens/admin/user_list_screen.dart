import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<User> _users = [];
  bool _loading = true;
  String? _error;
  final ApiService _api = ApiService();
  final _addUserFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.get('users');
      setState(() {
        _users = (data as List).map((json) => User.fromJson(json)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Tsy afaka naka users: $e';
        _loading = false;
      });
    }
  }

  // Ajout d'un utilisateur par l'admin
  Future<void> _showAddUserDialog() async {
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'employee';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter un utilisateur'),
        content: Form(
          key: _addUserFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom *'),
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Mot de passe *'),
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'employee', child: Text('Employé')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                  ],
                  onChanged: (v) => selectedRole = v!,
                  decoration: const InputDecoration(labelText: 'Rôle'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!_addUserFormKey.currentState!.validate()) return;
              Navigator.pop(context);
              try {
                await _api.post('auth/register', {
                  'nom': nomCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'password': passwordCtrl.text,
                  'role': selectedRole,
                });
                await _fetchUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Utilisateur créé'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  // Changer le rôle
  Future<void> _changeRole(User user, String newRole) async {
    if (user.role == newRole) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Changer le rôle de ${user.nom} ?'),
        content: Text('Passer de "${user.role}" à "$newRole"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      // Appel à une route backend dédiée (à créer)
      await _api.put('users/${user.id}/role', {'role': newRole});
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rôle de ${user.nom} mis à jour'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Bloquer / Débloquer
  Future<void> _toggleStatus(User user) async {
    final newStatus = user.statut == 'actif' ? 'bloque' : 'actif';
    final action = newStatus == 'bloque' ? 'Bloquer' : 'Débloquer';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$action ${user.nom}?'),
        content: Text(newStatus == 'bloque' ? 'Izy tsy afaka miditra intsony.' : 'Afaka miditra indray izy.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: newStatus == 'bloque' ? Colors.red : Colors.green),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.put('users/${user.id}/status?statut=$newStatus', {});
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.nom} — $newStatus'), backgroundColor: newStatus == 'bloque' ? Colors.red : Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nisy olana: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Supprimer
  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hamafa an\'i ${user.nom}?'),
        content: const Text('Tsy azo averina io fandravana io.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.delete('users/${user.id}');
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user.nom} voafafa')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tsy afaka namafa: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _roleBadge(String role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.purple.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAdmin ? Colors.purple : Colors.blue),
      ),
      child: Text(role, style: TextStyle(fontSize: 11, color: isAdmin ? Colors.purple : Colors.blue, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statutBadge(String statut) {
    final isActif = statut == 'actif';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isActif ? Icons.check_circle : Icons.block, size: 14, color: isActif ? Colors.green : Colors.red),
        const SizedBox(width: 4),
        Text(statut, style: TextStyle(fontSize: 12, color: isActif ? Colors.green : Colors.red)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Utilisateurs (${_users.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
          IconButton(icon: const Icon(Icons.person_add), onPressed: _showAddUserDialog, tooltip: 'Ajouter'),
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
                      ElevatedButton.icon(onPressed: _fetchUsers, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(child: Text('Tsy misy user', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _fetchUsers,
                      child: ListView.separated(
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final u = _users[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: u.role == 'admin' ? Colors.purple.shade100 : Colors.blue.shade100,
                              child: Text(u.nom.isNotEmpty ? u.nom[0].toUpperCase() : '?',
                                  style: TextStyle(color: u.role == 'admin' ? Colors.purple : Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                            title: Row(
                              children: [
                                Text(u.nom, style: const TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                _roleBadge(u.role),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.email, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 2),
                                _statutBadge(u.statut),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: u.role == 'admin'
                                ? null
                                : isSmallScreen
                                    ? PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (value) {
                                          if (value == 'toggle') _toggleStatus(u);
                                          if (value == 'delete') _deleteUser(u);
                                          if (value == 'role') _showRoleDialog(u);
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'toggle', child: Text('Bloquer/Débloquer')),
                                          const PopupMenuItem(value: 'role', child: Text('Changer rôle')),
                                          const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                                        ],
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Changer rôle (dropdown direct)
                                          DropdownButton<String>(
                                            value: u.role,
                                            items: const [
                                              DropdownMenuItem(value: 'employee', child: Text('Employé')),
                                              DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                            ],
                                            onChanged: (newRole) => _changeRole(u, newRole!),
                                            underline: Container(),
                                            icon: const Icon(Icons.arrow_drop_down),
                                          ),
                                          IconButton(
                                            icon: Icon(u.statut == 'actif' ? Icons.block : Icons.check_circle,
                                                color: u.statut == 'actif' ? Colors.orange : Colors.green),
                                            tooltip: u.statut == 'actif' ? 'Bloquer' : 'Débloquer',
                                            onPressed: () => _toggleStatus(u),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            tooltip: 'Supprimer',
                                            onPressed: () => _deleteUser(u),
                                          ),
                                        ],
                                      ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showRoleDialog(User user) async {
    String newRole = user.role;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Changer rôle de ${user.nom}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Employé'),
                value: 'employee',
                groupValue: newRole,
                onChanged: (v) => setState(() => newRole = v!),
              ),
              RadioListTile<String>(
                title: const Text('Administrateur'),
                value: 'admin',
                groupValue: newRole,
                onChanged: (v) => setState(() => newRole = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () {
            Navigator.pop(context);
            _changeRole(user, newRole);
          }, child: const Text('Valider')),
        ],
      ),
    );
  }
}