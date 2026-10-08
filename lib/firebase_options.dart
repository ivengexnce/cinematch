import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] generated from google-services.json
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCT5dv2OYANLu1562FmjqCu2opq4LYreKA',
    appId: '1:403444605586:web:d035398d51019b4a503c4b',
    messagingSenderId: '403444605586',
    projectId: 'movie-recommendation-sys-c374e',
    authDomain: 'movie-recommendation-sys-c374e.firebaseapp.com',
    storageBucket: 'movie-recommendation-sys-c374e.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCT5dv2OYANLu1562FmjqCu2opq4LYreKA',
    appId: '1:403444605586:android:d035398d51019b4a503c4b',
    messagingSenderId: '403444605586',
    projectId: 'movie-recommendation-sys-c374e',
    storageBucket: 'movie-recommendation-sys-c374e.firebasestorage.app',
  );
}
