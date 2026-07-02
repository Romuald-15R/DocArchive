import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
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
  String _ocrText = '';
  String? _fileName;
  bool _isProcessing = false;
  bool _isUploading = false;

  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImageWithOCR() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      setState(() {
        _selectedFile = File(image.path);
        _fileName = image.name;
        _fileType = 'image';
        _isProcessing = true;
        _ocrText = '';
      });

      final inputImage = InputImage.fromFile(_selectedFile!);
      final textRecognizer = GoogleMlKit.vision.textRecognizer();

      try {
        final recognised = await textRecognizer.processImage(inputImage);
        if (mounted) {
          setState(() {
            _ocrText = recognised.text;
            _isProcessing = false;
          });

          if (_titreCtrl.text.trim().isEmpty && _ocrText.isNotEmpty) {
            String firstLine = _ocrText.split('\n').first;
            if (firstLine.length > 50) {
              firstLine = firstLine.substring(0, 50);
            }
            _titreCtrl.text = firstLine;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Texte extrait'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Erreur OCR : $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        textRecognizer.close();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur caméra : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _fileType = _fileName!.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image';
          _ocrText = '';
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

    if (_selectedFile == null) {
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
      
      final success = await docProvider.addDocument(
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        fileType: _fileType,
        ocrText: _ocrText,
        categorieId: _categorieId!,
        filePath: _selectedFile!.path,
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
    final busy = _isProcessing || _isUploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un document'),
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : _pickImageWithOCR,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scanner + OCR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Importer fichier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isProcessing) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.abc, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Traitement OCR...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
            if (_fileName != null) ...[
              const SizedBox(height: 8),
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
                        _selectedFile = null;
                        _fileName = null;
                        _ocrText = '';
                      }),
                    ),
                  ],
                ),
              ),
            ],
            if (_selectedFile != null && _fileType == 'image') ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_selectedFile!, height: 150, fit: BoxFit.cover),
              ),
            ],
            if (_ocrText.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Texte OCR :', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Text(_ocrText, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: busy ? null : _submit,
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