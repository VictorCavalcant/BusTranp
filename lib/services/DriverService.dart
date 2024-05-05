import 'package:cloud_firestore/cloud_firestore.dart';

class DriverService {
  final CollectionReference drivers =
      FirebaseFirestore.instance.collection("drivers");

  Future<void> addUser(id) {
    return drivers.doc(id).set(
        {"active": false, "coords": const GeoPoint(0.0, 0.0)},
        SetOptions(merge: true));
  }

  Future<void> toggleActive(id, bool active) {
    if (active) {
      return drivers.doc(id).update({"active": true});
    } else {
      return drivers.doc(id).update({"active": false});
    }
  }

  Future<void> resetCoords(id) {
    return drivers.doc(id).update({"coords": const GeoPoint(0.0, 0.0)});
  }

  Future<void> resetActive(id) {
    return drivers.doc(id).update({"active": false});
  }

  Future<void> getCoords(id, double lat, double long) {
    return drivers.doc(id).update({"coords": GeoPoint(lat, long)});
  }
  
   Stream<QuerySnapshot> getActiveBuses() {
    final activeBusesStream =
        drivers.where("active", isEqualTo: true).snapshots();
    return activeBusesStream;
  }


}
