import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';
import '../providers/category_provider.dart';
import '../providers/notification_provider.dart';
import 'dashboard_screen.dart';
import 'document_add_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'admin/user_list_screen.dart';
import 'admin/logs_screen.dart';
import '../widgets/document_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final docProv = Provider.of<DocumentProvider>(context, listen: false);
    final catProv = Provider.of<CategoryProvider>(context, listen: false);
    final notifProv = Provider.of<NotificationProvider>(context, listen: false);
    await Future.wait([
      docProv.fetchDocuments().catchError((e) => debugPrint('Doc error: $e')),
      catProv.fetchCategories().catchError((e) => debugPrint('Cat error: $e')),
      notifProv.fetchNotifications().catchError((e) => debugPrint('Notif error: $e')),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.currentUser?.role == 'admin';

    final List<Widget> screens = [
      const DashboardScreen(),
      const DocumentListScreen(),
      const SearchScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
      if (isAdmin) const UserListScreen(),
      if (isAdmin) const LogsScreen(),
      if (isAdmin) const CategoryScreen(),
    ];

    final List<String> menuTitles = [
      'Dashboard',
      'Mes docs',
      'Recherche',
      'Notifications',
      'Profil',
      if (isAdmin) 'Utilisateurs',
      if (isAdmin) 'Logs',
      if (isAdmin) 'Catégories',
    ];

    final List<IconData> menuIcons = [
      Icons.dashboard,
      Icons.folder,
      Icons.search,
      Icons.notifications,
      Icons.person,
      if (isAdmin) Icons.people,
      if (isAdmin) Icons.history,
      if (isAdmin) Icons.category,
    ];

    final safeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DocArchive'),
      ),
      // ==================== DRAWER (MENU HAMBURGER) ====================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      auth.currentUser?.nom.isNotEmpty == true
                          ? auth.currentUser!.nom[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auth.currentUser?.nom ?? 'Utilisateur',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    auth.currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Menus
            for (int i = 0; i < menuTitles.length; i++)
              ListTile(
                leading: Icon(menuIcons[i]),
                title: Text(menuTitles[i]),
                selected: i == safeIndex,
                selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                onTap: () {
                  setState(() {
                    _currentIndex = i;
                  });
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            // Déconnexion
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                auth.logout();
              },
            ),
          ],
        ),
      ),
      body: screens[safeIndex],
      // Le bouton + n'apparaît que sur l'onglet "Mes docs" (index 1)
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentAddScreen()),
                ).then((_) => _loadData());
              },
              tooltip: 'Ajouter un document',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ==================== DOCUMENT LIST ====================
class DocumentListScreen extends StatelessWidget {
  const DocumentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);
    if (docProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (docProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(docProvider.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => docProvider.fetchDocuments(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (docProvider.documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Aucun document', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('Appuyez sur + pour ajouter', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => docProvider.fetchDocuments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: docProvider.documents.length,
        itemBuilder: (ctx, i) => DocumentCard(docProvider.documents[i]),
      ),
    );
  }
}

// ==================== CATEGORY SCREEN (ADMIN) ====================
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = Provider.of<CategoryProvider>(context);
    final categories = catProvider.categories;
    final error = catProvider.error;

    if (catProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Erreur : $error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                catProvider.clearError();
                catProvider.fetchCategories();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Aucune catégorie', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context, catProvider),
              icon: const Icon(Icons.add),
              label: const Text('Créer une catégorie'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => catProvider.fetchCategories(),
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final cat = categories[i];
            final color = Color(int.parse(cat.couleur.replaceFirst('#', '0xFF')));
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(Icons.label, color: color),
              ),
              title: Text(cat.nom, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: cat.description != null ? Text(cat.description!) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDialog(context, catProvider, cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(context, catProvider, cat),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, catProvider),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle catégorie'),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, CategoryProvider catProvider) async {
    final nomCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    const couleur = '#3498db';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nomCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              final success = await catProvider.addCategory(
                nomCtrl.text.trim(),
                descCtrl.text.trim(),
                couleur,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? 'Catégorie créée' : 'Erreur création'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, CategoryProvider catProvider, dynamic cat) async {
    final nomCtrl = TextEditingController(text: cat.nom);
    final descCtrl = TextEditingController(text: cat.description ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nomCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              final success = await catProvider.updateCategory(
                cat.id,
                nomCtrl.text.trim(),
                descCtrl.text.trim(),
                cat.couleur,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? 'Catégorie modifiée' : 'Erreur modification'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CategoryProvider catProvider, dynamic cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer "${cat.nom}" ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await catProvider.deleteCategory(cat.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Catégorie supprimée' : 'Erreur suppression'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }
}