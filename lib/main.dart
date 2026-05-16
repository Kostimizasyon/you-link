import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';
import 'package:you_link/fcm_page/fcm_page.dart';
import 'package:you_link/user_provider/user_provider.dart';
import 'package:you_link/workers/fcm_workers.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    @pragma('vm:entry-point')
    void callbackDispatcher() {
      Workmanager().executeTask((task, inputData) async {
        switch (task) {
          case 'update-fcm':
          // get fresh DriveApi without needing provider
            debugPrint("Hello $task");
            final driveApi = await UserProvider.getWorkerDriveApi();
            if (driveApi == null) return Future.value(false);

            bool result = await sendFCM();

            if (!result) return Future.value(false);
            break;
        }
        return Future.value(true);
      });
    }
    return Future.value(true);
  });
}

// 1. Make main() asynchronous
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final url = message.data['url'];
    if (url != null) {
      launchUrl(Uri.parse(url));
    }
  });

  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final url = initialMessage.data['url'];
    if (url != null) {
      launchUrl(Uri.parse(url));
    }
  }

  Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    'weekly-fcm',
    'update-fcm',
    frequency: Duration(days: 7),
    initialDelay: Duration(seconds: 1),
    constraints: Constraints(networkType: NetworkType.connected),
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: Duration(minutes: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  await UserProvider.initialize();

  // try silent auth first, prompt sign in if no cached session
  final driveApi = await UserProvider.getWorkerDriveApi();
  if (driveApi == null) {
    final provider = UserProvider();
    await provider.signIn();  // prompts Google sign in UI
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. Define your auth state variable (you'll likely manage this with a state manager later)
    return MaterialApp(
      theme: ThemeData(
        // 5. Fix the ColorScheme syntax
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // 6. Fix the const placement and ternary operator
      home: FcmPage(),
    );
  }
}
