import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBPqo48jpILx4yUT4QjVN5HLlLhxI4eklk',
    appId: '1:700995425658:ios:083f3abfe0260f7c7df2c3',
    messagingSenderId: '700995425658',
    projectId: 'falsoapp-43953',
    storageBucket: 'falsoapp-43953.firebasestorage.app',
    iosBundleId: 'com.falso.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBPqo48jpILx4yUT4QjVN5HLlLhxI4eklk',
    appId: '1:700995425658:android:083f3abfe0260f7c7df2c3',
    messagingSenderId: '700995425658',
    projectId: 'falsoapp-43953',
    storageBucket: 'falsoapp-43953.firebasestorage.app',
  );
}
