import 'package:google_maps_flutter/google_maps_flutter.dart';

class Stop {
  final String name;
  final LatLng coords;
  final String region;
  const Stop(this.name, this.coords, this.region);
}
