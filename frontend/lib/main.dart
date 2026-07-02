import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/document_provider.dart';
import 'providers/category_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'DocArchive',
        debugShowCheckedModeBanner: false, 
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true, // Optionnel : style Material 3
        ),
        home: Consumer<AuthProvider>(
          builder: (ctx, auth, _) => auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
        ),
      ),
    );
  }
}