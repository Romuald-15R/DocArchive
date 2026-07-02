class User {
  final int id;
  final String nom;
  final String email;
  final String role;
  final String? telephone;
  final String statut;
  final String? photoProfil;

  User({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.telephone,
    required this.statut,
    this.photoProfil,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nom: json['nom'],
      email: json['email'],
      role: json['role'],
      telephone: json['telephone'],
      statut: json['statut'],
      photoProfil: json['photo_profil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'role': role,
      'telephone': telephone,
      'statut': statut,
      'photo_profil': photoProfil,
    };
  }
}