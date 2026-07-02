import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'employee'; // ✅ par défaut employé

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
            ),
            const SizedBox(height: 12),
            // ✅ Dropdown pour choisir le rôle (selon UML)
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: 'Rôle'),
              items: const [
                DropdownMenuItem(value: 'employee', child: Text('Employé')),
                DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
              ],
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final success = await auth.register(
                  _nomController.text.trim(),
                  _emailController.text.trim(),
                  _passwordController.text,
                  _selectedRole, // ✅ envoi du rôle
                );
                if (success && mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inscription réussie, connectez-vous')),
                  );
                } else if (mounted) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de l\'inscription')),
                  );
                }
              },
              child: const Text('S\'inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}