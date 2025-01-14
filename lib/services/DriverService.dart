import 'package:cloud_firestore/cloud_firestore.dart';

class DriverService {
  final CollectionReference drivers =
      FirebaseFirestore.instance.collection("drivers");

  Future<void> addUser(id, String numero) {
    print("id ----> $id");

    return drivers.doc(id).set({
      "id": id.toString(),
      "active": false,
      "coords": const GeoPoint(0.0, 0.0),
      "isArrived": false,
      "linha": numero
    }, SetOptions(merge: true));
  }

  Future<void> toggleActive(id, bool active) {
    if (active) {
      return drivers.doc(id).update({"active": true});
    } else {
      return drivers.doc(id).update({"active": false});
    }
  }

  Future<void> toggleIsArrived(id, bool isArrived) {
    if (isArrived) {
      return drivers.doc(id).update({"isArrived": true});
    } else {
      return drivers.doc(id).update({"isArrived": false});
    }
  }

  Future<void> resetCoords(id) {
    return drivers.doc(id).update({"coords": const GeoPoint(0.0, 0.0)});
  }

  Future<void> resetActive(id) {
    print("id reset --> $id");
    return drivers.doc(id).update({"active": false});
  }

  Future<void> resetIsArrived(id) {
    return drivers.doc(id).update({"isArrived": false});
  }

  Future<void> getCoords(id, double lat, double long) {
    return drivers.doc(id).update({"coords": GeoPoint(lat, long)});
  }

  Stream<QuerySnapshot> getActiveBuses() {
    final activeBusesStream =
        drivers.where("active", isEqualTo: true).snapshots();
    return activeBusesStream;
  }

  // Stream<QuerySnapshot> getFilterBuses(String stopName) {
  //   String nameStop = stopName.replaceAll(RegExp(r'\s+'), ' ');

  //   final filterBusesStream = drivers
  //       .where("routes", arrayContains: nameStop)
  //       .where("active", isEqualTo: true)
  //       .where("destination", isNotEqualTo: "")
  //       .snapshots();

  //   return filterBusesStream;
  // }
  Future<List<String>> getLinhas() async {
    try {
      // Obter todos os documentos
      QuerySnapshot snapshot = await drivers.get();

      // Mapear os valores do campo 'linha' para uma lista
      List<String> linhas = snapshot.docs
          .map((doc) => doc['linha']
              as String) // Certifique-se de que o campo 'linha' é do tipo String
          .toList();

      return linhas;
    } catch (e) {
      print('Erro ao buscar linhas: $e');
      return [];
    }
  }

  Stream<QuerySnapshot> getFilterBuses(String linha) {
    final filterBusesStream = drivers
        .where("linha", isEqualTo: linha)
        .where("active", isEqualTo: true)
        .snapshots();

    return filterBusesStream;
  }
}
