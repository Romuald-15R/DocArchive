# 📄 DocArchive

**Application mobile et web de numérisation et d'archivage intelligent des documents administratifs**

---

## 📋 Table des matières

1. [Présentation](#présentation)
2. [Fonctionnalités](#fonctionnalités)
3. [Technologies utilisées](#technologies-utilisées)
4. [Architecture du projet](#architecture-du-projet)
5. [Installation](#installation)
6. [Configuration](#configuration)
7. [Lancement](#lancement)
8. [Déploiement](#déploiement)
9. [Structure du code](#structure-du-code)
10. [API Documentation](#api-documentation)
11. [Sécurité](#sécurité)
12. [Contributeurs](#contributeurs)
13. [Licence](#licence)

---

## 🎯 Présentation

**DocArchive** est une application complète permettant de **numériser**, **archiver** et **gérer** les documents administratifs de manière sécurisée et organisée.

### Problème résolu

| Problème | Solution |
|----------|----------|
| 📁 Documents papier perdus | 💾 Archivage numérique sécurisé |
| ⏱️ Recherche lente | 🔍 Recherche rapide par titre, date, catégorie ou OCR |
| 🗄️ Espace de stockage limité | ☁️ Stockage dans le cloud |
| 🔒 Manque de sécurité | 🛡️ Authentification JWT + bcrypt |
| 📋 Pas de traçabilité | 📜 Logs de toutes les actions |

---

## ✨ Fonctionnalités

### 🔐 Authentification
- Inscription avec choix du rôle (Admin / Employé)
- Connexion sécurisée (JWT)
- Gestion du profil
- Déconnexion

### 📷 Scan & Import
- 📸 Scanner un document avec l'appareil photo
- 📄 Importer un PDF
- 🖼️ Importer une image
- 🧠 OCR (Reconnaissance de texte) avec Google ML Kit

### 📦 Archivage
- 🏷️ Classement par catégorie personnalisée
- 🔢 Numéro d'archive unique automatique
- 💾 Sauvegarde sécurisée

### 🔎 Recherche avancée
- Par titre
- Par catégorie
- Par date
- Par contenu OCR

### 📖 Consultation
- 👁️ Visionneuse PDF (zoom, swipe)
- 🖼️ Visualisation d'images
- ⬇️ Téléchargement
- 📤 Partage

### 📊 Tableau de bord (Admin)
- 📈 Total des documents
- 📊 Documents par catégorie
- 🕐 Activités récentes

### 🔔 Notifications
- ✅ Archivage réussi
- 📢 Nouveaux documents

### 📜 Logs système (Admin)
- 👤 Toutes les actions des utilisateurs
- 🗂️ Filtrage par type d'action
- 📥 Export CSV

### 👥 Gestion utilisateurs (Admin)
- 📋 Liste des utilisateurs
- 🔒 Bloquer / Débloquer
- 🔄 Changer le rôle (Admin/Employé)
- 🗑️ Supprimer un utilisateur

---

## 🛠️ Technologies utilisées

### Frontend (Flutter)
| Technologie | Version | Utilisation |
|-------------|---------|-------------|
| Flutter | 3.x | Framework mobile/web |
| Provider | ^6.1.1 | Gestion d'état |
| http | ^1.2.0 | Requêtes API |
| flutter_secure_storage | ^9.0.0 | Stockage sécurisé des tokens |
| image_picker | ^1.0.7 | Capture / sélection d'images |
| google_ml_kit | ^0.16.3 | OCR (mobile) |
| file_picker | ^6.1.1 | Sélection de fichiers |
| flutter_pdfview | ^1.3.2 | Visionneuse PDF |
| share_plus | ^7.2.1 | Partage de documents |

### Backend (FastAPI)
| Technologie | Version | Utilisation |
|-------------|---------|-------------|
| FastAPI | ^0.104.1 | API REST |
| SQLAlchemy | ^2.0.23 | ORM |
| asyncpg | ^0.29.0 | Pilote PostgreSQL |
| python-jose | ^3.3.0 | JWT |
| bcrypt | ^4.0.1 | Hachage des mots de passe |
| Pydantic | ^2.5.0 | Validation des données |

### Base de données
| Technologie | Utilisation |
|-------------|-------------|
| PostgreSQL | Base de données relationnelle |

### Hébergement
| Technologie | Utilisation |
|-------------|-------------|
| Render | Hébergement du backend |
| Cloud | Stockage des documents |

---

## 🏗️ Architecture du projet
┌─────────────────────────────────────────────────────────────┐
│ APPLICATION MOBILE/WEB │
│ (Flutter) │
├─────────────────────────────────────────────────────────────┤
│ Provider (State Management) | HTTP Client | Image Picker │
│ Google ML Kit (OCR) | PDF Viewer | Share Plus │
└─────────────────────────────────────────────────────────────┘
│
│ HTTPS / JSON
▼
┌─────────────────────────────────────────────────────────────┐
│ API REST │
│ (FastAPI) │
├─────────────────────────────────────────────────────────────┤
│ SQLAlchemy ORM | Pydantic V2 | JWT Auth | Bcrypt │
│ Upload Files | Logs Service | Notification Service │
└─────────────────────────────────────────────────────────────┘
│
│ SQL
▼
┌─────────────────────────────────────────────────────────────┐
│ BASE DE DONNÉES │
│ (PostgreSQL) │
├─────────────────────────────────────────────────────────────┤
│ users | categories | documents | logs | notifications │
└─────────────────────────────────────────────────────────────┘

text

---

## 📦 Installation

### Prérequis

| Logiciel | Version | Téléchargement |
|----------|---------|----------------|
| Python | 3.10+ | [python.org](https://python.org) |
| Flutter | 3.x | [flutter.dev](https://flutter.dev) |
| PostgreSQL | 14+ | [postgresql.org](https://postgresql.org) |
| Git | - | [git-scm.com](https://git-scm.com) |

### 1️⃣ Cloner le projet

```bash
git clone https://github.com/votre-username/docarchive.git
cd docarchive
2️⃣ Backend (FastAPI)
bash
cd backend

# Créer un environnement virtuel
python -m venv venv

# Activer l'environnement (Windows)
venv\Scripts\activate

# Activer l'environnement (Mac/Linux)
source venv/bin/activate

# Installer les dépendances
pip install -r requirements.txt
3️⃣ Frontend (Flutter)
bash
cd frontend

# Installer les dépendances
flutter pub get

# Vérifier la configuration
flutter doctor
⚙️ Configuration
1️⃣ Variables d'environnement (.env)
Créez un fichier .env dans le dossier backend/ :

env
# Base de données
DATABASE_URL=postgresql+asyncpg://user:password@localhost/docarchive

# Sécurité JWT
SECRET_KEY=votre_cle_secrète_unique
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Environnement
ENV=development
DEBUG=True
2️⃣ Base de données (PostgreSQL)
sql
-- Créer la base de données
CREATE DATABASE docarchive;

-- Créer l'utilisateur (optionnel)
CREATE USER docarchive_user WITH PASSWORD 'mon_mot_de_passe';

-- Donner les droits
GRANT ALL PRIVILEGES ON DATABASE docarchive TO docarchive_user;
3️⃣ Configuration Flutter (constants.dart)
dart
import 'package:flutter/foundation.dart';

class Constants {
  static const String cloudUrl = 'https://docarchive-api.onrender.com/api';

  static String get apiBaseUrl {
    if (kReleaseMode) {
      return cloudUrl;  // Production
    } else {
      if (kIsWeb) {
        return 'http://localhost:8000/api';  // Web local
      } else {
        return 'http://192.168.1.100:8000/api';  // Android local
      }
    }
  }
}
🚀 Lancement
1️⃣ Backend
bash
cd backend
venv\Scripts\activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
2️⃣ Frontend
bash
cd frontend

# Web (Chrome)
flutter run -d chrome

# Android (émulateur ou physique)
flutter run

# Android (APK)
flutter build apk --release
📂 Structure du code
Backend (FastAPI)
text
backend/
├── app/
│   ├── main.py              # Point d'entrée, CORS, routers
│   ├── database.py          # Connexion PostgreSQL (SQLAlchemy)
│   ├── models.py            # Modèles SQLAlchemy (User, Document, etc.)
│   ├── schemas.py           # Schémas Pydantic
│   ├── auth.py              # JWT, bcrypt, authentification
│   ├── routers/
│   │   ├── auth.py          # Login / Register
│   │   ├── users.py         # Gestion utilisateurs
│   │   ├── documents.py     # CRUD documents
│   │   ├── categories.py    # CRUD catégories
│   │   ├── logs.py          # Historique des actions
│   │   ├── notifications.py # Notifications
│   │   └── dashboard.py     # Statistiques
│   ├── services/
│   │   ├── log_service.py   # Enregistrement des logs
│   │   └── notification_service.py # Envoi de notifications
│   └── utils/
│       └── archive_number.py # Génération numéro d'archive
├── uploads/                 # Documents stockés
├── requirements.txt         # Dépendances Python
└── .env                     # Variables d'environnement
Frontend (Flutter)
text
frontend/
├── lib/
│   ├── main.dart            # Point d'entrée
│   ├── models/              # Modèles (User, Document, Category, Notification)
│   ├── providers/           # State Management (Auth, Document, Category, Notification)
│   ├── screens/             # Écrans (Login, Register, Home, Dashboard, etc.)
│   ├── services/            # API Service
│   ├── widgets/             # Widgets réutilisables
│   └── utils/               # Utilitaires (constants.dart)
├── assets/                  # Images, icônes, etc.
├── pubspec.yaml             # Dépendances Flutter
└── android/                 # Code Android (APK)

📖 API Documentation
Une fois le backend lancé, la documentation automatique (Swagger) est disponible :

text
http://localhost:8000/docs
http://localhost:8000/redoc
Principaux endpoints
Méthode	Endpoint	             Description	Auth
POST	/api/auth/register	         Inscription	❌
POST	/api/auth/login             	Connexion	❌
GET	/api/users/me	           Profil utilisateur	✅
GET	/api/documents/	           Liste des documents	✅
POST	/api/documents/	      Ajouter un document	✅
GET	/api/documents/search	Rechercher un document	✅
GET	/api/categories/	    Liste des catégories	✅
POST	/api/categories/    	Créer une catégorie	✅ (Admin)
GET	/api/notifications/	  Liste des notifications	✅
GET	/api/logs/	           Historique des actions	✅ (Admin)
GET	/api/dashboard/stats	        Statistiques	✅ (Admin)
☁️ Déploiement
Render (Backend)
Créez un compte sur Render

Connectez votre dépôt GitHub

Sélectionnez "New Web Service"

Configurez :

Build Command : pip install -r requirements.txt

Start Command : uvicorn app.main:app --host 0.0.0.0 --port $PORT

Ajoutez les variables d'environnement

Cliquez sur "Create Web Service"

APK (Android)
bash
flutter build apk --release
Le fichier APK se trouve dans :

text
build/app/outputs/flutter-apk/app-release.apk
🔒 Sécurité
Mesures implémentées
Niveau	Technologie	Objectif
Authentification	JWT	Sessions sans état
Mots de passe	bcrypt	Hachage sécurisé
Autorisation	Middleware rôle	Admin vs Employé
Validation	Pydantic v2	Validation des données
CORS	FastAPI middleware	Accès contrôlé
Stockage	flutter_secure_storage	Token sécurisé
Rôles et permissions
Action	                       Employé	Admin
Consulter ses documents	           ✅	✅
Ajouter un document	               ✅	✅
Modifier son document            	✅	✅
Supprimer son document	            ✅	✅
Consulter tous les documents	    ❌	✅
Gérer les utilisateurs	            ❌	✅
Consulter les logs	               ❌	✅
Gérer les catégories	           ❌	✅