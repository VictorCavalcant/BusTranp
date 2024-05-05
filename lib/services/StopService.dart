import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ubus/models/Stop.dart';

class StopService {
  final collectionStopsGroup =
      FirebaseFirestore.instance.collectionGroup('stops');

  Future<List<Stop>> getStops() async {
    List dataList = [];
    List<Stop> stops = [];
    try {
      await collectionStopsGroup.get().then((QuerySnapshot snapshot) {
        final docs = snapshot.docs;
        for (var data in docs) {
          dataList.add(data.data());
        }
      });

      for (var data in dataList) {
        stops.add(
          Stop(
            data['name'],
            LatLng(data['coords'].latitude, data['coords'].longitude),
            data['region'],
          ),
        );
      }

      return stops;
    } catch (e) {
      print(e.toString());
      throw Exception("Failed to get stop data");
    }
  }
}
