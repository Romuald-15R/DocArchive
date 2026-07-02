import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/document_provider.dart';
import '../providers/category_provider.dart';

class DocumentAddScreen extends StatefulWidget {
  const DocumentAddScreen({super.key});

  @override
  State<DocumentAddScreen> createState() => _DocumentAddScreenState();
}

class _DocumentAddScreenState extends State<DocumentAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titreCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  String _fileType = 'image';
  int? _categorieId;
  String? _fileName;
  bool _isUploading = false;
  Uint8List? _webFileBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _webFileBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
          _fileType = _fileName!.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Fichier : $_fileName'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_webFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📁 Sélectionnez un fichier'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_categorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📂 Choisissez une catégorie'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      
      final success = await docProvider.addDocumentWeb(
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        fileType: _fileType,
        ocrText: '',
        categorieId: _categorieId!,
        fileBytes: _webFileBytes!,
        fileName: _fileName!,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Document archivé'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Échec archivage'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = Provider.of<CategoryProvider>(context);
    final categories = catProvider.categories;
    final isLoading = catProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un document'),
        elevation: 2,
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titreCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const LinearProgressIndicator()
            else if (categories.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Aucune catégorie. Créez-en une d\'abord.',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Catégorie *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
                value: _categorieId,
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('Sélectionner une catégorie')),
                  ...categories.map((c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Row(
                      children: [
                        const Icon(Icons.folder, size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(c.nom),
                      ],
                    ),
                  )),
                ],
                onChanged: (v) => setState(() => _categorieId = v),
                validator: (v) => v == null ? 'Choisissez une catégorie' : null,
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Importer fichier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                      color: _fileType == 'pdf' ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_fileName!)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      onPressed: () => setState(() {
                        _webFileBytes = null;
                        _fileName = null;
                      }),
                    ),
                  ],
                ),
              ),
            ],
            if (_webFileBytes != null && _fileType == 'image') ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_webFileBytes!, height: 150, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isUploading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Archiver le document', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}