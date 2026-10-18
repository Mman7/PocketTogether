import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app/app.dart';

Future<void> testLocalFunction(FirebaseFunctions functions) async {
  try {
    final callable = functions.httpsCallable('helloFromLocal');
    final result = await callable.call({'name': 'Flutter'});

    debugPrint('Function result: ${result.data}');
  } on FirebaseFunctionsException catch (e) {
    debugPrint('Function error code: ${e.code}');
    debugPrint('Function error message: ${e.message}');
    debugPrint('Function details: ${e.details}');
  } catch (e) {
    debugPrint('Unexpected error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  if (useEmulators) {
    await testLocalFunction(functions);
  }

  runApp(const PocketTogetherApp());
}
