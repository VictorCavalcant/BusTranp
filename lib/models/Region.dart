import 'package:google_maps_flutter/google_maps_flutter.dart';

class Region {
  String name = '';
  List<LatLng> points = [];
  Region(this.name, this.points);
}
