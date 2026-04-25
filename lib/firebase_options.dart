import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAy9SXyzxPB3X9eh_A_wWbnwoTaeH6CHPs',
    appId: '1:648245527320:android:b6d3424586913e8687946d',
    messagingSenderId: '648245527320',
    projectId: 'studentviolation-ac638',
  );
}
