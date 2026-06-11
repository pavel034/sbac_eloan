// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError('Firebase not configured for Windows.');
      case TargetPlatform.linux:
        throw UnsupportedError('Firebase not configured for Linux.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDGuK2WfI1vRJk-3C6xk-cJT2bSWlMIEu0',
    appId: '1:536852735979:web:63d132a5f2a0aa99e15bae',
    messagingSenderId: '536852735979',
    projectId: 'sbac-e-loan',
    authDomain: 'sbac-e-loan.firebaseapp.com',
    storageBucket: 'sbac-e-loan.firebasestorage.app',
    measurementId: 'G-7MXQ5ZPPS8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDE8aMaX1mdCV8b_Xh1k73MbEy8vW7_C1g',
    appId: '1:536852735979:android:c09e83fda1196293e15bae',
    messagingSenderId: '536852735979',
    projectId: 'sbac-e-loan',
    storageBucket: 'sbac-e-loan.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB9speGyAM4l_B_cMVUJSuXF9XQLPMqd_0',
    appId: '1:536852735979:ios:c7eb12bd0461a38fe15bae',
    messagingSenderId: '536852735979',
    projectId: 'sbac-e-loan',
    storageBucket: 'sbac-e-loan.firebasestorage.app',
    iosBundleId: 'com.sbac.eloan',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB9speGyAM4l_B_cMVUJSuXF9XQLPMqd_0',
    appId: '1:536852735979:ios:c7eb12bd0461a38fe15bae',
    messagingSenderId: '536852735979',
    projectId: 'sbac-e-loan',
    storageBucket: 'sbac-e-loan.firebasestorage.app',
    iosBundleId: 'com.sbac.eloan',
  );
}
