class Document {
  final int id;
  final String titre;
  final String? description;
  final String filePath;
  final String fileType;
  final String numeroArchive;
  final String? ocrText;
  final int tailleFichier;
  final DateTime dateScan;
  final DateTime dateArchivage;
  final int categorieId;
  final int userId;
  final String statut;

  Document({
    required this.id,
    required this.titre,
    this.description,
    required this.filePath,
    required this.fileType,
    required this.numeroArchive,
    this.ocrText,
    required this.tailleFichier,
    required this.dateScan,
    required this.dateArchivage,
    required this.categorieId,
    required this.userId,
    required this.statut,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      titre: json['titre'],
      description: json['description'],
      filePath: json['file_path'],
      fileType: json['file_type'],
      numeroArchive: json['numero_archive'],
      ocrText: json['ocr_text'],
      tailleFichier: json['taille_fichier'] ?? 0,
      dateScan: DateTime.parse(json['date_scan']),
      dateArchivage: DateTime.parse(json['date_archivage']),
      categorieId: json['categorie_id'],
      userId: json['user_id'],
      statut: json['statut'] ?? 'actif',
    );
  }
}