import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ubus/pages/DriverMapPage.dart';
import 'package:ubus/pages/SignInPage.dart';
import 'package:ubus/pages/UserMapPage.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool granted = false;



  @override
  void initState() {
    checkPermissionGPS();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0469ff),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              "assets/splash.png",
              fit: BoxFit.contain,
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 70,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.all(12)),
                    onPressed: () async {
                      if (granted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserMapPage(),
                          ),
                        );
                      } else {
                        await checkPermissionGPS();
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pin_drop_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                        FittedBox(
                          child: Text(
                            "Ir pro Mapa",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.all(12)),
                    onPressed: () async {
                      if (granted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScreenRouter(),
                          ),
                        );
                      } else {
                        await checkPermissionGPS();
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                        FittedBox(
                          child: Text(
                            "Motorista",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  checkPermissionGPS() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      return AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'O gps está desativado!',
        desc: 'Por favor ative o gps!',
        btnOkOnPress: () {},
      ).show();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) {
        return AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          title: 'O serviço de gps foi recusado!',
          desc: 'Por favor conceda permissão para o uso do serviço gps!',
          btnOkOnPress: () {},
        ).show();
      }
    }

    if (permission == LocationPermission.deniedForever && mounted) {
      return AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'O serviço de gps foi recusado permanentemente',
        desc: 'Por favor conceda a permissão nas configurações do aplicativo!',
        btnOkOnPress: () async {
          await Geolocator.openAppSettings();
        },
      ).show();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      setState(() {
        granted = true;
      });
    }
  }
}

class ScreenRouter extends StatelessWidget {
  const ScreenRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const DriverMapPage();
        } else {
          return const SignInPage();
        }
      },
    );
  }
}
