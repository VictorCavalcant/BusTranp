import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ubus/models/Region.dart';

class RegionService {
  final CollectionReference collectionRegions =
      FirebaseFirestore.instance.collection("stop-regions");

  Future<List<Region>> getRegions() async {
    List dataList = [];
    List<Region> regions = [];
    try {
      await collectionRegions.get().then(
        (snapshot) {
          final docs = snapshot.docs;
          for (var data in docs) {
            dataList.add(data.data());
          }
        },
      );

      for (var data in dataList) {
        List<LatLng> points = [];
        List pointsData = data['points'] as List;

        for (var point in pointsData) {
          points.add(LatLng(point.latitude, point.longitude));
        }

        regions.add(Region(data['name'], points));
      }

      return regions;
    } catch (e) {
      print(e.toString());
      throw Exception("Failed to get regions");
    }
  }
}
