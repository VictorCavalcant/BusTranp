import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:ubus/models/Stop.dart';
import 'package:ubus/pages/SignInPage.dart';
import 'package:ubus/services/AuthService.dart';
import 'package:ubus/services/DriverService.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:ui' as ui;

import 'package:ubus/stores/StopStore.dart';

class DriverMapPage extends StatefulWidget {
  const DriverMapPage({super.key});

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage> {
  Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  loc.Location location = loc.Location();
  List<Stop> stops = [];
  bool trackinStop = false;
  ValueNotifier<bool> trackinStop2 = ValueNotifier(false);
  Stop stopDestination = const Stop('', LatLng(0.0, 0.0), '');
  ValueNotifier<Stop> stopDestination2 =
      ValueNotifier(const Stop('', LatLng(0.0, 0.0), ''));
  int checkDistanceDestination = 0;
  ValueNotifier<int> checkDistanceDestination2 = ValueNotifier(0);
  final stopStore = StopStore();
  final battery = Battery();
  Timer checkBatteryTimer = Timer(Duration.zero, () {});
  bool lowBattery = false;
  LatLng currentPosition = const LatLng(0.0, 0.0);
  DriverService driverService = DriverService();
  String? currentDriverName = FirebaseAuth.instance.currentUser!.displayName;
  String currentDriverNameTemp = "";
  final _currentDriverId = FirebaseAuth.instance.currentUser!.uid;
  ValueNotifier<bool> active = ValueNotifier(false);
  ValueNotifier<bool> isArrived = ValueNotifier(false);
  bool checkIsArrived = false;
  ValueNotifier<bool> checkIsArrived2 = ValueNotifier(false);
  String currentDestination = '';
  ValueNotifier<String> currentDestination2 = ValueNotifier('');
  bool arriveStop = false;
  String distanceStop = '';
  ValueNotifier<String> distanceStop2 = ValueNotifier('');
  String timeStop = '';
  ValueNotifier<String> timeStop2 = ValueNotifier('');
  Map<PolylineId, Polyline> polylines = {};
  ValueNotifier<Map<PolylineId, Polyline>> polylines2 = ValueNotifier({});

  Future<void> _cameraToPosition() async {
    final GoogleMapController controller = await _mapController.future;
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentPosition, zoom: 17),
      ),
    );
  }

  BitmapDescriptor stopMarkerIcon = BitmapDescriptor.defaultMarker;

  Future<Uint8List> getBytesFromAssets(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  _customStopMarkerIcon() async {
    final Uint8List customIcon =
        await getBytesFromAssets("assets/Bus_marker.png", 120);
    stopMarkerIcon = BitmapDescriptor.fromBytes(customIcon);
  }

  getCurrentLocation() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always) {
      location.enableBackgroundMode(enable: true);
    }

    location.changeSettings(
      accuracy: loc.LocationAccuracy.navigation,
      distanceFilter: 8,
    );

    location.onLocationChanged.listen(
      (loc.LocationData currentLocation) async {
        currentPosition =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        await _cameraToPosition();
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
      await driverService.toggleIsArrived(_currentDriverId, false);
    }
  }

  toggleIsArrived() async {
    isArrived.value = !isArrived.value;
    if (isArrived.value) {
      await driverService.toggleIsArrived(_currentDriverId, isArrived.value);
    } else {
      await driverService.resetIsArrived(_currentDriverId);
    }
  }

  busArrived() async {
    await driverService.toggleIsArrived(_currentDriverId, true);
  }

  busNotArrived() async {
    await driverService.toggleIsArrived(_currentDriverId, false);
  }

  checkBatteryLevel() async {
    checkBatteryTimer = Timer.periodic(
      const Duration(seconds: 20),
      (timer) async {
        if (await battery.batteryLevel <= 40 && !lowBattery && mounted) {
          location.changeSettings(
            accuracy: loc.LocationAccuracy.powerSave,
            distanceFilter: 8,
          );
          setState(
            () {
              lowBattery = true;
            },
          );
        } else if (await battery.batteryLevel > 40 && lowBattery && mounted) {
          location.changeSettings(
            accuracy: loc.LocationAccuracy.navigation,
            distanceFilter: 8,
          );
          setState(
            () {
              lowBattery = false;
            },
          );
        }
      },
    );
  }

  getStops() async {
    stopStore.getStops();
  }

  Future<void> getUserName() async {
    currentDriverName = FirebaseAuth.instance.currentUser!.displayName;

    String email = FirebaseAuth.instance.currentUser!.email!;

    RegExp regExp = RegExp(r'\d+');

    Match? match = regExp.firstMatch(email);

    String numero = "";

    if (match != null) {
      numero = match.group(0)!; // O número encontrado
    }

    currentDriverNameTemp = "Van $numero";
  }

  @override
  void initState() {
    getUserName();
    checkBatteryLevel();
    getCurrentLocation();
    _cameraToPosition();
    _customStopMarkerIcon();
    driverService.resetActive(_currentDriverId);
    driverService.resetIsArrived(_currentDriverId);
    driverService.resetCoords(_currentDriverId);
    super.initState();
  }

  @override
  void dispose() {
    _mapController = Completer();
    driverService.resetActive(_currentDriverId);
    driverService.resetIsArrived(_currentDriverId);
    driverService.resetCoords(_currentDriverId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              title: Text(currentDriverName != null
                  ? currentDriverName!
                  : currentDriverNameTemp),
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
            ListTile(
              leading: const Icon(Icons.gps_fixed),
              title: const Text('Habilitar localização em plano de fundo'),
              onTap: () async {
                await Geolocator.openLocationSettings();
                await location.enableBackgroundMode(enable: true);
              },
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentPosition,
                zoom: 18,
              ),
              onMapCreated: ((GoogleMapController controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
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
