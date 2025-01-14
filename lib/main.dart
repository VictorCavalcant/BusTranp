import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:ubus/firebase_options.dart';
import 'package:ubus/notifications/local_notifications.dart';
import 'package:ubus/providers/BusTrackingProvider.dart';
import 'package:ubus/providers/StopProvider.dart';
import 'package:ubus/services/MessageService.dart';
import 'package:ubus/splash/SplashScreen.dart';
import 'package:ubus/stores/StopStore.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data.containsKey('distance')) {
    LocalNotifications().showLocalNotification(message);
  }

  // Essa função será chamada quando o app estiver em plano de fundo
  print("Mensagem recebida em plano de fundo: ${message.notification?.title}");
}

final GetIt getIt = GetIt.instance;

void setup() {
  getIt.registerSingleton<BusTrackingProvider>(BusTrackingProvider());
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Aguarde a inicialização do Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) => () async {
        await MessageService().initNotification();
      });

  // Inicialize o serviço de mensagens após o Firebase

  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    // Force Hybrid Composition mode.
    mapsImplementation.useAndroidViewSurface = true;
  }

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  Animate.restartOnHotReload = true;

  setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ChangeNotifierProvider(
        //   create: (context) => BusTrackingProvider(),
        // ),
        ChangeNotifierProvider(
          create: (context) => StopStore(),
        ),
        ChangeNotifierProvider(
          create: (context) => StopProvider(),
        )
      ],
      child: MaterialApp(
        title: 'Ubus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
