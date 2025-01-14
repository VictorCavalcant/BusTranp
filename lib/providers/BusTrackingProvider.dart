import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:ubus/key/googleMapsKey.dart';
import 'package:ubus/notifications/local_notifications.dart';
import 'package:ubus/services/MessageService.dart';
import 'package:location/location.dart' as loc;

class BusTrackingProvider extends ChangeNotifier {
  List<dynamic> activeBuses = [];
  bool auxTrackRoute = false;
  String snapShotStatus = "";
  bool haveRoute = false;

  dynamic activeBus;
  String arriveTimeBus = "";
  String distanceBus = "";
  bool tracking = false;
  bool isArrived = false;
  int _executionCount = 0;
  int executionCountTrack = 0;
  int _executionCountBG = 0;
  final int _executionLimit = 4;
  final int executionLimitTrack = 4;
  final int executionLimitBG = 4;
  bool limit = false;
  bool confirm = false;
  bool awaitConfirm = false;
  bool notificationSend = false;
  LatLng currentUserPosition = const LatLng(0.0, 0.0);

  void addBus(DocumentSnapshot doc) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dynamic docData = doc.data();

      if (!activeBuses.any((aB) => aB['id'] == doc['id']) ||
          activeBuses.isEmpty) {
        activeBuses.add(doc.data());
        notifyListeners();
      }
    });
  }

  void addBusBG(DocumentSnapshot doc) {
    print("executei addBG");

    dynamic docData = doc.data();

    if (!activeBuses.any((aB) => aB['id'] == doc['id']) ||
        activeBuses.isEmpty) {
      activeBuses.add(doc.data());
    }
  }

  void updateBus(DocumentSnapshot doc) async {
    if (_executionCount >= _executionLimit) {
      await resetCounterAfterDelay(const Duration(seconds: 2));
      return; // Não executa se o limite foi atingido
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      dynamic docData = doc.data();

      final index = activeBuses.indexWhere((bus) => bus['id'] == doc['id']);
      if (index != -1 &&
          (activeBuses[index]['coords'].latitude !=
                  docData['coords'].latitude &&
              activeBuses[index]['coords'].longitude !=
                  docData['coords'].latitude)) {
        activeBuses[index] = doc.data();
        notifyListeners();
        _executionCount++;
      }
    });
  }

  void updateBusBG(DocumentSnapshot doc) async {
    if (_executionCountBG >= _executionLimit) {
      await resetCounterBGAfterDelay(const Duration(seconds: 2));
      return; // Não executa se o limite foi atingido
    }

    dynamic docData = doc.data();

    final index = activeBuses.indexWhere((bus) => bus['id'] == doc['id']);
    if (index != -1 &&
        (activeBuses[index]['coords'].latitude != docData['coords'].latitude &&
            activeBuses[index]['coords'].longitude !=
                docData['coords'].latitude)) {
      activeBuses[index] = doc.data();
      notifyListeners();
      _executionCountBG++;
    }
  }

  void removeBus(DocumentSnapshot doc) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (activeBuses.isNotEmpty) {
        activeBuses.removeWhere((bus) => bus['id'] == doc['id']);
        notifyListeners();
      }
    });
  }

  void removeBusBG(DocumentSnapshot doc) {
    if (activeBuses.isNotEmpty) {
      activeBuses.removeWhere((bus) => bus['id'] == doc['id']);
    }
  }

  void updateActiveBuses(List<dynamic> buses) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      activeBuses = buses;
      notifyListeners();
    });
  }

  void updateActiveBusesBG(List<dynamic> buses) {
    activeBuses = buses;
  }

  void updateActiveBus(dynamic bus) async {
    if (_executionCount >= _executionLimit) {
      await resetCounterAfterDelay(const Duration(seconds: 2));
      return; // Não executa se o limite foi atingido
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      activeBus = bus;
      _executionCount++;
      notifyListeners();
    });
  }

  void updateActiveBusBG(dynamic bus) async {
    if (_executionCount >= _executionLimit) {
      await resetCounterAfterDelay(const Duration(seconds: 2));
      return; // Não executa se o limite foi atingido
    }

    activeBus = bus;
    _executionCount++;
  }

  void clearBuses() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setDistance("");
      if (activeBuses.isNotEmpty) {
        activeBuses.clear();
        activeBus = dynamic;
        resetExecutionCount();
        resetExecutionCountTrack();
        notifyListeners();
      }
    });
  }

  void clearBusesBG() {
    if (activeBuses.isNotEmpty) {
      activeBuses.clear();
      activeBus = dynamic;
      distanceBus = "";
      resetExecutionCount();
      resetExecutionCountTrack();
    }
  }

  void toggleTracking(bool value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tracking != value) {
        tracking = value;
        if (tracking == false) {
          isArrived = false;
          confirm = false;
          notificationSend = false;
          setDistance("");
        }
        notifyListeners();
      }
    });
  }

  void toggleTrackingBG(bool value) {
    if (tracking != value) {
      tracking = value;
      if (tracking == false) {
        isArrived = false;
        confirm = false;
        notificationSend = false;
      }
    }
  }

  void setActiveBus(dynamic bus) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      activeBus = bus;
      notifyListeners();
    });
  }

  void setActiveBusBG(dynamic bus) {
    activeBus = bus;
    notifyListeners();
  }

  void setAuxTrackRoute(bool aux) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      auxTrackRoute = aux;
      notifyListeners();
    });
  }

  void setAuxTrackRouteBG(bool aux) {
    auxTrackRoute = aux;
  }

  void sethaveRoute(bool hvRoute) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      haveRoute = hvRoute;
      notifyListeners();
    });
  }

  void sethaveRouteBG(bool hvRoute) {
    haveRoute = hvRoute;
    notifyListeners();
  }

  void checkArrivalNotification(String distance) async {
    print("executei!!!! notification");

    if (distance.isNotEmpty) {
      String removeM = '';
      String removeK = '';
      String distanceAux;

      removeM = distance.replaceAll('m', '');

      if (!removeM.contains("k")) {
        distanceAux = removeM;

        if (int.parse(distanceAux) <= 300 && !isArrived && tracking) {
          isArrived = true;

          if (!notificationSend) {
            await MessageService().sendNotification(
                title: "Ubus",
                body: "O ônibus está próximo!",
                distance: distanceAux);

            FirebaseMessaging.onMessage.listen((RemoteMessage message) {
              print(
                  'Mensagem recebida em primeiro plano: ${message.notification?.title}');
              LocalNotifications().showLocalNotification(message);
            });
            notificationSend = true;
          }
        } else if (int.parse(distanceAux) > 300 && isArrived && confirm) {
          isArrived = false;
          confirm = false;
          notificationSend = false;
        }
      }
    }
  }

  void checkArrival(String distance, BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (distance.isNotEmpty) {
        String removeM = '';
        String removeK = '';
        String distanceAux;

        removeM = distance.replaceAll('m', '');

        if (!removeM.contains("k")) {
          distanceAux = removeM;

          if (int.parse(distanceAux) <= 300 && !isArrived && tracking) {
            isArrived = true;

            if (!notificationSend) {
              await MessageService().sendNotification(
                  title: "Ubus",
                  body: "O ônibus está próximo!",
                  distance: distanceAux);

              FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
                print(
                    'Mensagem recebida em primeiro plano: ${message.notification?.title}');
                await LocalNotifications().showLocalNotification(message);
              });
              notificationSend = true;
              notifyListeners();
            }

            if (context.mounted) {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.info,
                title: "O Ônibus está próximo a você!",
                btnOkOnPress: () {},
              ).show().then((value) => {confirm = true, notifyListeners()});
            }
          } else if (int.parse(distanceAux) > 300 && isArrived && confirm) {
            print("else if checkArrival ");
            isArrived = false;
            confirm = false;
            notificationSend = false;
            notifyListeners();
          }
        }
      }
    });
  }

  void getDistanceAndTime(String distance, String time) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      distanceBus = distance;
      arriveTimeBus = time;

      notifyListeners();
    });
  }

  void getDistanceAndTimeBG(String distance, String time) {
    distanceBus = distance;
    arriveTimeBus = time;
  }

  void setDistance(String distance) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      distanceBus = distance;
      notifyListeners();
    });
  }

  void setDistanceBG(String distance) {
    distanceBus = distance;
  }

  Future<void> resetCounterAfterDelay(Duration delay) async {
    await Future.delayed(delay);
    resetExecutionCount();
  }

  void resetExecutionCount() {
    _executionCount = 0; // Método para resetar o contador, se necessário
  }

  Future<void> resetCounterTrackAfterDelay(Duration delay) async {
    await Future.delayed(delay);
    resetExecutionCountTrack();
  }

  Future<void> resetCounterBGAfterDelay(Duration delay) async {
    await Future.delayed(delay);
    resetExecutionCountBG();
  }

  void resetExecutionCountTrack() {
    executionCountTrack = 0; // Método para resetar o contador, se necessário
  }

  void resetExecutionCountBG() {
    _executionCountBG = 0; // Método para resetar o contador, se necessário
  }

  void incrementExecutionCountTrack() {
    executionCountTrack++;
    notifyListeners();
  }

  void incrementExecutionCountBG() {
    _executionCountBG++;
  }

  void getUserPosition(LatLng position) {
    if (currentUserPosition != position) {
      currentUserPosition = position;
    }
  }

  void getCurrentLocation() async {
    LocationPermission permission;

    loc.Location location = loc.Location();

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always) {
      location.enableBackgroundMode(enable: true);
    }

    location.changeSettings(
      accuracy: loc.LocationAccuracy.navigation,
      distanceFilter: 8,
    );

    location.onLocationChanged.listen((loc.LocationData currentLocation) async {
      currentUserPosition =
          LatLng(currentLocation.latitude!, currentLocation.longitude!);
    });
  }

  Future<List<LatLng>> fetchDistanceBackground() async {
    if (_executionCountBG >= executionLimitBG) {
      resetCounterBGAfterDelay(const Duration(seconds: 2));
      return [];
    }

    final polylinePoints = PolylinePoints();
    String distanceBus2 = "";
    String removeM = '';
    String removeK = '';

    String distanceBus = "";
    String arriveTimeBus = "";

    if (tracking && executionCountTrack < executionLimitBG) {
      try {
        if (auxTrackRoute) {
          return [];
        }

        setAuxTrackRouteBG(true);

        final result = await polylinePoints.getRouteBetweenCoordinates(
            googleMapsKey,
            PointLatLng(
                activeBus['coords'].latitude, activeBus['coords'].longitude),
            PointLatLng(
                currentUserPosition.latitude, currentUserPosition.longitude),
            travelMode: TravelMode.transit);

        distanceBus = result.distance!;

        arriveTimeBus = result.duration!;

        // busTrackingProvider.arriveTimeBus = result.duration!;

        // busTrackingProvider.distanceBus = result.distance!;

        removeM = distanceBus.replaceAll('m', '');

        if (removeM.contains('k')) {
          removeK = removeM.replaceAll('k', '');
          double doubleValue = double.parse(removeK);
          int intValue = (doubleValue * 1000).toInt();
          if (doubleValue < 1) {
            setDistanceBG('$intValue m');
            // distanceBus2 = '$intValue m';
          } else {
            setDistanceBG(result.distance!);
            distanceBus2 = result.distance!;
          }
        } else if (!removeM.contains('m')) {
          setDistanceBG(result.distance!);
          // distanceBus2 = result.distance!;
        }

        if (result.points.isNotEmpty) {
          return result.points
              .map(
                (p) => LatLng(p.latitude, p.longitude),
              )
              .toList();
        } else {
          debugPrint(result.errorMessage);
          return [];
        }
      } catch (e) {
        print("error ----> ${e.toString()}");
        return [];
      } finally {
        setAuxTrackRouteBG(false);
        // auxTrackRoute2.value = false;
        // setState(() {
        //   auxTrackRoute = false;
        // });
      }
    } else {
      return [];
    }
  }
}
