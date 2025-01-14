import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ubus/key/googleMapsKey.dart';
import 'package:ubus/models/Region.dart';
import 'package:ubus/models/Stop.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mpt;

class StopProvider extends ChangeNotifier {
  StopProvider(
      {this.isNearStopsVisible = false,
      this.isStopInfoVisible = false,
      this.selectedStop,
      this.distance = "",
      this.duration = ""});

  bool isInTheArea = false;
  bool nearEdge = false;
  bool isNearStopsVisible;
  bool isStopInfoVisible;
  Stop? selectedStop;
  List<Stop> stopsRegion = [];
  List<Stop> nearStops = [];
  String distance;
  String duration;

  showNearStops(
      List<Region> regions, List<Stop> stops, LatLng currentPosition) async {
    isStopInfoVisible = false;
    isNearStopsVisible = true;
    getStopsRegion(regions, stops, currentPosition);
    nearStops = await getNearStopPoints(stopsRegion, currentPosition);
    selectedStop = nearStops[0];

    notifyListeners();
  }

  hideNearStops() {
    isNearStopsVisible = false;
    notifyListeners();
  }

  showStopInfo(Stop stp) {
    isNearStopsVisible = false;
    isStopInfoVisible = true;
    selectedStop = stp;
    notifyListeners();
  }

  hideStopInfo() {
    isStopInfoVisible = false;
    selectedStop = const Stop("", LatLng(0.0, 0.0), "");
    distance = "";
    duration = "";
    notifyListeners();
  }

  getStopsRegion(
      List<Region> regions, List<Stop> stops, LatLng currentPosition) {
    stopsRegion = [];
    for (var i = 0; i < regions.length; i++) {
      List<mpt.LatLng> convertedPolygonPoints = regions[i]
          .points
          .map((p) => mpt.LatLng(p.latitude, p.longitude))
          .toList();

      isInTheArea = mpt.PolygonUtil.containsLocation(
          mpt.LatLng(currentPosition.latitude, currentPosition.longitude),
          convertedPolygonPoints,
          false);

      if (isInTheArea) {
        stopsRegion =
            stops.where((stp) => stp.region == regions[i].name).toList();
        break;
      }
    }

    if (stopsRegion.isEmpty) {
      stopsRegion = checkNearRegion(regions, stops, currentPosition);
    }


    notifyListeners();
  }

  List<Stop> checkNearRegion(
      List<Region> regions, List<Stop> stops, LatLng currentPosition) {
    int tol = 300;
    int i = 0;
    List<Stop> stopsNearEdge = [];

    while (true) {
      List<mpt.LatLng> convertedPolygonPoints = regions[i]
          .points
          .map((p) => mpt.LatLng(p.latitude, p.longitude))
          .toList();

      nearEdge = mpt.PolygonUtil.isLocationOnEdge(
          mpt.LatLng(currentPosition.latitude, currentPosition.longitude),
          convertedPolygonPoints,
          false,
          tolerance: tol);

      if (nearEdge) {
        stopsNearEdge =
            stops.where((stp) => stp.region == regions[i].name).toList();
        return stopsNearEdge;
      }
      i++;
      if (i >= regions.length) {
        i = 0;
      }
      tol += 100;
    }
  }

  getDistanceAndDuration(String distanceValue, String durationValue) {
    duration = durationValue;
    String removeM = '';
    String removeK = '';

    removeM = distanceValue.replaceAll('m', '');

    if (removeM.contains('k')) {
      removeK = removeM.replaceAll('k', '');
      double doubleValue = double.parse(removeK);
      int intValue = (doubleValue * 1000).toInt();
      if (doubleValue < 1) {
        distance = '$intValue m';
      } else {
        distance = distanceValue;
      }
    } else if (!removeM.contains('m')) {
      distance = distanceValue;
    }

    notifyListeners();
  }
}

Future<List<Stop>> getNearStopPoints(
    List<Stop> stps, LatLng currentPosition) async {
  List<Stop> nearStopPoints = [];
  List<Map<String, dynamic>> values = [];
  Set<double> clearDistances = {};
  String removeM = '';
  String removeK = '';
  String removeMins = '';
  String removeMin = '';
  double distanceDouble = 0.0;
  int durationInt = 0;

  for (var stp in stps) {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleMapsKey,
      PointLatLng(currentPosition.latitude, currentPosition.longitude),
      PointLatLng(stp.coords.latitude, stp.coords.longitude),
      travelMode: TravelMode.walking,
    );

    removeM = result.distance!.replaceAll('m', '');

    if (removeM.contains('k')) {
      removeK = removeM.replaceAll('k', '');
      distanceDouble = double.parse(removeK) * 10000;
    } else if (!removeM.contains('m')) {
      distanceDouble = double.parse(removeM);
    }

    removeMins = result.duration!.replaceAll('mins', '');

    if (removeMins.contains('min')) {
      removeMin = result.duration!.replaceAll('min', '');
    }

    if (removeMin == '') {
      durationInt = int.parse(removeMins);
    } else {
      durationInt = int.parse(removeMin);
    }

    values.add(
      {
        "stopName": stp.name,
        "coords": stp.coords,
        "region": stp.region,
        "distance": distanceDouble,
        "duration": durationInt,
      },
    );
  }

  values.sort(
    (a, b) {
      if (a["distance"] != b["distance"]) {
        return a["distance"].compareTo(b["distance"]);
      } else {
        return a["duration"].compareTo(b["duration"]);
      }
    },
  );

  values.removeWhere(
    (element) {
      if (clearDistances.contains(element["distance"])) {
        return true;
      } else {
        clearDistances.add(element["distance"]);
        return false;
      }
    },
  );

  for (var i = 0; i < 3; i++) {
    nearStopPoints.add(
      Stop(
        values[i]['stopName'],
        values[i]['coords'],
        values[i]['region'],
      ),
    );
  }

  return nearStopPoints;
}
