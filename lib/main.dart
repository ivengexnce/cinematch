import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/firebase_storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Boot the UI immediately without blocking on network handshakes
  runApp(const CineMatchApp());

  // Initialize Firebase in the background
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((_) {
    FirebaseStorageService().markInitialized(true);
    debugPrint('Firebase initialized in background.');
  }).catchError((e) {
    debugPrint('Firebase background init fallback: $e');
  });
}

class CineMatchApp extends StatelessWidget {
  const CineMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineMatch - Movie Recommendation System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
