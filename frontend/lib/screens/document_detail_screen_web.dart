import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import '../models/document.dart';
import '../providers/document_provider.dart';
import '../utils/constants.dart';

class DocumentDetailScreen extends StatefulWidget {
  final Document document;
  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _isDownloading = false;

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _getFileExtension() {
    if (widget.document.fileType == 'pdf') {
      return 'pdf';
    } else {
      final path = widget.document.filePath;
      if (path.contains('.')) {
        return path.split('.').last.toLowerCase();
      }
      return 'jpg';
    }
  }

  String _getMimeType() {
    if (widget.document.fileType == 'pdf') {
      return 'application/pdf';
    }
    return 'image/jpeg';
  }

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final token = await docProvider.api.getToken();
      if (token == null) throw Exception('Non authentifié');

      final downloadUrl = '${Constants.apiBaseUrl}/documents/${widget.document.id}/download';
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode != 200) throw Exception('Téléchargement impossible');

      // WEB : téléchargement via blob et anchor element
      final blob = html.Blob([response.bodyBytes], _getMimeType());
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${widget.document.numeroArchive}.${_getFileExtension()}')
        ..style.display = 'none';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Téléchargement lancé'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _shareDocument() async {
    try {
      final downloadUrl = '${Constants.apiBaseUrl}/documents/${widget.document.id}/download';
      final shareText = '📄 ${widget.document.titre}\n'
          '📅 ${_formatDate(widget.document.dateArchivage)}\n'
          '🔖 ${widget.document.numeroArchive}\n'
          '📎 $downloadUrl';
      
      await Share.share(shareText);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Lien partagé'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur partage : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, DocumentProvider docProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce document?'),
        content: Text('« ${widget.document.titre} » sera supprimé définitivement.'),
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
    
    final success = await docProvider.deleteDocument(widget.document.id);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Document supprimé'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Échec suppression'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, DocumentProvider docProvider) async {
    final titreCtrl = TextEditingController(text: widget.document.titre);
    final descCtrl = TextEditingController(text: widget.document.description ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titreCtrl, decoration: const InputDecoration(labelText: 'Titre')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await docProvider.updateDocument(
                widget.document.id,
                titre: titreCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '✅ Document modifié' : '❌ Échec modification'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) setState(() {});
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    final isImage = widget.document.fileType == 'image';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.titre),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(context, docProvider)),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(context, docProvider)),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareDocument),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.archive, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    widget.document.numeroArchive,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '${Constants.apiBaseUrl}/documents/${widget.document.id}/file',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image, size: 50)),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 50, color: Colors.red.shade700),
                      const SizedBox(height: 8),
                      Text('Document PDF', style: TextStyle(color: Colors.red.shade700)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _infoRow(Icons.description, 'Description', widget.document.description ?? 'Aucune'),
                    const Divider(),
                    _infoRow(Icons.insert_drive_file, 'Type', widget.document.fileType),
                    const Divider(),
                    _infoRow(Icons.storage, 'Taille', _formatSize(widget.document.tailleFichier)),
                    const Divider(),
                    _infoRow(Icons.calendar_today, 'Date archivage', _formatDate(widget.document.dateArchivage)),
                    const Divider(),
                    _infoRow(Icons.scanner, 'Date scan', _formatDate(widget.document.dateScan)),
                  ],
                ),
              ),
            ),
            if (widget.document.ocrText != null && widget.document.ocrText!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Texte OCR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(widget.document.ocrText!, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _download,
                    icon: _isDownloading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download),
                    label: const Text('Télécharger'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareDocument,
                    icon: const Icon(Icons.share),
                    label: const Text('Partager'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}