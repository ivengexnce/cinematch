import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] generated from google-services.json for project cinematch-bymeet
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
    apiKey: 'AIzaSyBMiH9IJ-9u0GS-AS0PBQnYXq0G04MWdtg',
    appId: '1:551627410847:web:1b19b3dab7721dd0ec41aa',
    messagingSenderId: '551627410847',
    projectId: 'cinematch-bymeet',
    authDomain: 'cinematch-bymeet.firebaseapp.com',
    storageBucket: 'cinematch-bymeet.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMiH9IJ-9u0GS-AS0PBQnYXq0G04MWdtg',
    appId: '1:551627410847:android:1b19b3dab7721dd0ec41aa',
    messagingSenderId: '551627410847',
    projectId: 'cinematch-bymeet',
    storageBucket: 'cinematch-bymeet.firebasestorage.app',
  );
}
