import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ubus/pages/SignInPage.dart';
import 'package:ubus/services/AuthService.dart';
import 'package:ubus/services/DriverService.dart';

class DriverMapPage extends StatefulWidget {
  const DriverMapPage({Key? key}) : super(key: key);

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage>
    with WidgetsBindingObserver {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  bool onBackGround = false;
  StreamSubscription<Position>? positionStream;
  LatLng currentPosition = const LatLng(0.0, 0.0);
  LatLng initialPosition = const LatLng(0.0, 0.0);
  DriverService driverService = DriverService();
  final currentDriverName = FirebaseAuth.instance.currentUser!.displayName;
  final _currentDriverId = FirebaseAuth.instance.currentUser!.uid;
  ValueNotifier<bool> active = ValueNotifier(false);

  getInitialLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    initialPosition = LatLng(position.latitude, position.longitude);
  }

  Future<void> _cameraToPosition(Position position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(position.latitude, position.longitude), zoom: 17),
      ),
    );
  }

  getCurrentLocation() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 8,
    );

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) async {
        currentPosition = LatLng(position!.latitude, position.longitude);
        print("posição atual -----> $currentPosition");
        await _cameraToPosition(position);
        if (active.value) {
          await driverService.getCoords(_currentDriverId,
              currentPosition.latitude, currentPosition.longitude);
        }
      },
    );
  }

  toggleActive() async {
    active.value = !active.value;
    if (active.value) {
      await driverService.toggleActive(_currentDriverId, active.value);
      await driverService.getCoords(_currentDriverId, currentPosition.latitude,
          currentPosition.longitude);
    } else {
      await driverService.resetActive(_currentDriverId);
      await driverService.resetCoords(_currentDriverId);
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(seconds: 5), () async {
      final GoogleMapController controller = await _mapController.future;
      controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: initialPosition, zoom: 17),
        ),
      );
    });
    getInitialLocation();
    getCurrentLocation();
    driverService.resetActive(_currentDriverId);
    driverService.resetCoords(_currentDriverId);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    positionStream!.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      positionStream!.cancel;
      getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: GlobalKey(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 45,
        title: const Text(
          'ubus',
          style: TextStyle(
            fontFamily: 'Flix',
            color: Colors.white,
            fontSize: 37,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0057DA),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0469ff),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(currentDriverName!),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Sair"),
              onTap: () {
                AuthService().signOut(_currentDriverId);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignInPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 18,
              ),
              onMapCreated: ((GoogleMapController controller) {
                if (!_mapController.isCompleted) {
                  controller.animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(target: currentPosition, zoom: 18)));
                  _mapController.complete(controller);
                } else {}
              }),
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          ValueListenableBuilder(
            valueListenable: active,
            builder: (context, value, child) => Container(
              height: MediaQuery.sizeOf(context).height / 5,
              color: const Color(0xFF0057DA),
              child: Center(
                child: SizedBox(
                  height: 600,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: !value ? Colors.green : Colors.red),
                    onPressed: toggleActive,
                    child: Text(
                      !value ? 'INICIAR' : 'PARAR',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
