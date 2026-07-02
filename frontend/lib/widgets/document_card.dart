import 'package:flutter/material.dart';
import '../models/document.dart';
import '../screens/document_detail_screen.dart';

class DocumentCard extends StatelessWidget {
  final Document document;

  const DocumentCard(this.document);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.description),
        title: Text(document.titre),
        subtitle: Text('${document.numeroArchive}\n${document.dateArchivage.toLocal()}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: document)),
          );
        },
      ),
    );
  }
}