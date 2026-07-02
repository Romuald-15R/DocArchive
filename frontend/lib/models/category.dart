class Category {
  final int id;
  final String nom;
  final String? description;
  final String couleur;

  Category({
    required this.id,
    required this.nom,
    this.description,
    required this.couleur,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      couleur: json['couleur'],
    );
  }
}