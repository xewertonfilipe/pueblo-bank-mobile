import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB3-aJCmyAkmzRHblE1qj0RNnAViify70w',
    appId: '1:212215922284:web:3da1392194224cd0e5a249',
    messagingSenderId: '212215922284',
    projectId: 'pueblo-bank--mobile',
    authDomain: 'pueblo-bank--mobile.firebaseapp.com',
    storageBucket: 'pueblo-bank--mobile.firebasestorage.app',
    measurementId: 'G-9GWVVVEDPQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD99x9QdjgkfKqUv_aea0jcFEjFB3BrL3w',
    appId: '1:212215922284:android:4ee9e70077e27508e5a249',
    messagingSenderId: '212215922284',
    projectId: 'pueblo-bank--mobile',
    storageBucket: 'pueblo-bank--mobile.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAxseWC1k9jI1UBjsXDfL_t9VI76JDR7Lo',
    appId: '1:212215922284:ios:a706e54477389475e5a249',
    messagingSenderId: '212215922284',
    projectId: 'pueblo-bank--mobile',
    storageBucket: 'pueblo-bank--mobile.firebasestorage.app',
    iosBundleId: 'com.example.imageGalleryApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAxseWC1k9jI1UBjsXDfL_t9VI76JDR7Lo',
    appId: '1:212215922284:ios:a706e54477389475e5a249',
    messagingSenderId: '212215922284',
    projectId: 'pueblo-bank--mobile',
    storageBucket: 'pueblo-bank--mobile.firebasestorage.app',
    iosBundleId: 'com.example.imageGalleryApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB3-aJCmyAkmzRHblE1qj0RNnAViify70w',
    appId: '1:212215922284:web:b4d55574968cdc00e5a249',
    messagingSenderId: '212215922284',
    projectId: 'pueblo-bank--mobile',
    authDomain: 'pueblo-bank--mobile.firebaseapp.com',
    storageBucket: 'pueblo-bank--mobile.firebasestorage.app',
    measurementId: 'G-WR43V60TEH',
  );
}
