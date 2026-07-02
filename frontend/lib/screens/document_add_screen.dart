// Ce fichier exporte la bonne version selon la plateforme
export 'document_add_screen_stub.dart'
    if (dart.library.html) 'document_add_screen_web.dart';