import 'package:firebase_core/firebase_core.dart';
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
        return linux;
      case TargetPlatform.fuchsia:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYDo2AuEIoByPUrtEekBWPqFs5hsanzOY',
    appId: '1:874011756891:web:341dd4eb4c11ff3ac5b27e',
    messagingSenderId: '874011756891',
    projectId: 'lingoocall',
    authDomain: 'lingoocall.firebaseapp.com',
    storageBucket: 'lingoocall.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYDo2AuEIoByPUrtEekBWPqFs5hsanzOY',
    appId: '1:874011756891:android:341dd4eb4c11ff3ac5b27e',
    messagingSenderId: '874011756891',
    projectId: 'lingoocall',
    storageBucket: 'lingoocall.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBYDo2AuEIoByPUrtEekBWPqFs5hsanzOY',
    appId: '1:874011756891:ios:341dd4eb4c11ff3ac5b27e',
    messagingSenderId: '874011756891',
    projectId: 'lingoocall',
    storageBucket: 'lingoocall.firebasestorage.app',
    iosBundleId: 'com.example.lingoocall',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBYDo2AuEIoByPUrtEekBWPqFs5hsanzOY',
    appId: '1:874011756891:ios:341dd4eb4c11ff3ac5b27e',
    messagingSenderId: '874011756891',
    projectId: 'lingoocall',
    storageBucket: 'lingoocall.firebasestorage.app',
    iosBundleId: 'com.example.lingoocall',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBYDo2AuEIoByPUrtEekBWPqFs5hsanzOY',
    appId: '1:874011756891:web:341dd4eb4c11ff3ac5b27e',
    messagingSenderId: '874011756891',
    projectId: 'lingoocall',
    storageBucket: 'lingoocall.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyBYDo2AuEIoByPUrtEekBWPqFs5hsanzOY',
    appId: '1:874011756891:web:341dd4eb4c11ff3ac5b27e',
    messagingSenderId: '874011756891',
    projectId: 'lingoocall',
    storageBucket: 'lingoocall.firebasestorage.app',
  );
}
