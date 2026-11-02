import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'app/app.dart';
import 'core/notifications/fcm_service.dart';
import 'core/notifications/notification_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  const useEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );

  final functions = FirebaseFunctions.instanceFor(
    app: Firebase.app(),
    region: 'us-central1',
  );

  if (useEmulators) {
    debugPrint('Using Firebase emulators');

    await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
    functions.useFunctionsEmulator('10.0.2.2', 5001);
  }

  final fcmService = FcmService();
  await fcmService.initialize();
  final notificationHandler = NotificationHandler();

  runApp(
    PocketTogetherApp(
      functions: functions,
      notificationHandler: notificationHandler,
    ),
  );
}
