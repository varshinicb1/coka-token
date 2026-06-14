import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // COKA Billing Firebase Configuration
  //
  // === SECURITY WARNING ===
  // Before production launch, RESTRICT this API key in Firebase Console:
  //   1. Go to https://console.cloud.google.com/apis/credentials
  //   2. Click the API key "AIzaSyBpM3SRRfdHyYnFqTh0H6h91xkvNuRqGnE"
  //   3. Under "Application restrictions", choose "Android apps" or "HTTP referers"
  //   4. For Android: add your app's package name and SHA-1 fingerprint
  //   5. For Web: add your domain
  //   6. Under "API restrictions", restrict to "Firebase Authentication" and "Cloud Firestore"
  //
  // === GETTING THE VALUES ===
  // The admin SDK key only gives the project_id. To get the remaining values:
  //   1. Go to https://console.firebase.google.com/project/coka-token/settings/general
  //   2. Scroll down to "Your apps" section
  //   3. For Web app: copy the apiKey, authDomain, projectId, storageBucket, messagingSenderId, appId
  //   4. For Android: download google-services.json and copy the values
  //
  // For now the app runs in offline/local mode. Fill in these values to enable Firebase.

  static const String apiKey = 'AIzaSyBpM3SRRfdHyYnFqTh0H6h91xkvNuRqGnE';
  static const String authDomain = 'coka-token.firebaseapp.com';
  static const String projectId = 'coka-token';
  static const String storageBucket = 'coka-token.firebasestorage.app';
  static const String messagingSenderId = '277395706746';
  static const String appId = '1:277395706746:web:74376ff0130f5ee1a57cc3';
  static const String measurementId = 'G-YY63EWMNV4';
  
  // Web client ID for Google Sign-In (from Google Cloud Console > Credentials)
  // To get this: https://console.cloud.google.com/apis/credentials > OAuth 2.0 Web Client
  static const String webClientId = 'YOUR_WEB_CLIENT_ID';

  // Check if Firebase is configured (not using placeholder values)
  static bool get isConfigured => !appId.contains('YOUR_');

  // Android client ID for Google Sign-In (from google-services.json)
  static const String androidClientId = '277395706746-9h3vnlf7ano0b0gu593i2ocrs4ipj7gc.apps.googleusercontent.com';

  // iOS client ID for Google Sign-In
  static const String iosClientId = 'YOUR_IOS_CLIENT_ID';

  static FirebaseOptions toOptions() => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain,
    storageBucket: storageBucket,
  );
}
