import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  File? _imageFile;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nomController = TextEditingController(text: user?.nom ?? '');
    _telephoneController = TextEditingController(text: user?.telephone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (_nomController.text != (user?.nom ?? '')) {
      _nomController.text = user?.nom ?? '';
    }
    if (_telephoneController.text != (user?.telephone ?? '')) {
      _telephoneController.text = user?.telephone ?? '';
    }
    if (_emailController.text != (user?.email ?? '')) {
      _emailController.text = user?.email ?? '';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
      // ignore: use_build_context_synchronously
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await _uploadProfilePhoto(auth);
    }
  }

  Future<void> _uploadProfilePhoto(AuthProvider auth) async {
    if (_imageFile == null) return;
    setState(() => _isUploading = true);
    try {
      final token = await auth.api.getToken();
      if (token == null) throw Exception('Non authentifié');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.apiBaseUrl}/users/me/photo'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('photo', _imageFile!.path),
      );
      final response = await request.send();
      if (response.statusCode == 200) {
        await auth.fetchCurrentUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo mise à jour'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Upload échoué: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur photo: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isUploading = false);
      _imageFile = null;
    }
  }

  void _showImageSourceDialog(AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(AuthProvider auth) {
    final user = auth.currentUser;
    final photoUrl = user?.photoProfil;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage('${Constants.apiBaseUrl}/$photoUrl'),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.blue.shade100,
      child: Text(
        user?.nom.isNotEmpty == true ? user!.nom[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    _syncControllers();

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        _buildAvatar(auth),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18),
                              onPressed: _isUploading ? null : () => _showImageSourceDialog(auth),
                              tooltip: 'Changer photo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    enabled: false,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telephoneController,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final success = await auth.updateProfile({
                          'nom': _nomController.text.trim(),
                          'telephone': _telephoneController.text.trim(),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Profil mis à jour' : 'Erreur lors de la mise à jour'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Enregistrer'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => auth.logout(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Déconnexion'),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}