import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ubus/key/googleMapsKey.dart';
import 'package:ubus/models/Region.dart';
import 'package:ubus/models/Stop.dart';
import 'package:ubus/pages/HomePage.dart';
import 'package:ubus/providers/StopProvider.dart';
import 'package:ubus/services/DriverService.dart';
import 'package:ubus/services/RegionService.dart';
import 'package:ubus/states/StopState.dart';
import 'dart:ui' as ui;

import 'package:ubus/stores/StopStore.dart';

class UserMapPage extends StatefulWidget {
  const UserMapPage({super.key});

  @override
  State<UserMapPage> createState() => _UserMapPageState();
}

class _UserMapPageState extends State<UserMapPage> {
  final stopStore = StopStore();
  List<Stop> stops = [];
  List<Region> regions = [];
  List activeBuses = [];
  LatLng currentPosition = const LatLng(0.0, 0.0);
  LatLng initialPosition = const LatLng(0.0, 0.0);
  bool haveRoute = false;
  int checkDistance = 0;
  BuildContext? currentContext;
  StreamSubscription<Position>? positionStream;
  DriverService driverService = DriverService();
  final StreamController<QuerySnapshot<Object?>> _driverStreamController =
      StreamController<QuerySnapshot<Object?>>();

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  Map<PolylineId, Polyline> polylines = {};

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
    setState(() {});
  }

  _customBusMarkerIcon() async {
    final Uint8List customIcon =
        await getBytesFromAssets("assets/bus_LocMark.png", 120);
    busMarkerIcon = BitmapDescriptor.fromBytes(customIcon);
    setState(() {});
  }

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
            target: LatLng(position.latitude, position.longitude), zoom: 18),
      ),
    );
  }

  getCurrentLocation() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) async {
        currentPosition = LatLng(position!.latitude, position.longitude);
        await _cameraToPosition(position);

        if (haveRoute) {
          await initializeRoutes();
        }
      },
    );
  }

  BitmapDescriptor stopMarkerIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor busMarkerIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      driverService.getActiveBuses().listen((snapshot) {
        if (!_driverStreamController.isClosed) {
          _driverStreamController.add(snapshot);
        }
      });
      stopStore.getStops();
      regions = await RegionService().getRegions();
    });
    Future.delayed(
      const Duration(seconds: 5),
      () async {
        final GoogleMapController controller = await _mapController.future;
        controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: initialPosition, zoom: 18),
          ),
        );
      },
    );
    getInitialLocation();
    getCurrentLocation();
    _customStopMarkerIcon();
    _customBusMarkerIcon();
    super.initState();
  }

  Future<void> initializeRoutes() async {
    final coordinates = await fetchPolylinePoints();
    if (haveRoute) {
      generatePolylineFromPoints(coordinates);
    }
  }

  @override
  void dispose() {
    positionStream!.cancel();
    _driverStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StopProvider>(
      builder: (context, stopProv, child) => Scaffold(
        drawer: !stopProv.isNearStopsVisible && !stopProv.isStopInfoVisible
            ? Drawer(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Menu Principal'),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                        );
                      },
                    )
                  ],
                ),
              )
            : null,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarHeight: 45,
          title: const Text(
            'ubus',
            style: TextStyle(
                fontFamily: 'Flix', color: Colors.white, fontSize: 37),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0057DA),
          leading: stopProv.isNearStopsVisible && !stopProv.isStopInfoVisible
              ? IconButton(
                  onPressed: () {
                    stopProv.hideNearStops();
                    setState(() {
                      polylines.clear();
                      haveRoute = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                )
              : !stopProv.isNearStopsVisible && stopProv.isStopInfoVisible
                  ? IconButton(
                      onPressed: () async {
                        stopProv.hideStopInfo();
                        setState(() {
                          polylines.clear();
                          haveRoute = false;
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                    )
                  : null,
        ),
        body: ListenableBuilder(
          listenable: stopStore,
          builder: (_, child) {
            Widget body = Container();
            final state = stopStore.state;
            if (state is LoadingStopState) {
              body = const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is ErrorStopState) {
              body = const Center(
                child: Text("Falha ao resgatar dados"),
              );
            } else if (state is EmptyStopState) {
              body = const Center(
                child: Text("Não há dados"),
              );
            } else if (state is SucessStopState) {
              stops = state.stops;
              body = StreamBuilder<QuerySnapshot>(
                stream: _driverStreamController.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    activeBuses.clear();
                  }

                  if (snapshot.hasData) {
                    activeBuses = snapshot.data!.docs;
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                  target: initialPosition, zoom: 18),
                              onMapCreated: ((GoogleMapController controller) {
                                if (!_mapController.isCompleted) {
                                  _mapController.complete(controller);
                                } else {}
                              }),
                              myLocationEnabled: true,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              markers: {
                                ...stops.map(
                                  (stp) {
                                    return Marker(
                                      markerId: MarkerId(stp.name),
                                      position: stp.coords,
                                      icon: stopMarkerIcon,
                                      onTap: () {
                                        showModalBottomSheet(
                                          backgroundColor: Colors.blue,
                                          context: context,
                                          builder: (context) {
                                            return SizedBox(
                                              width: MediaQuery.sizeOf(context)
                                                  .width,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.bus_alert,
                                                    size: 120,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                  FittedBox(
                                                    child: Text(
                                                      stp.name,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  const Text(
                                                    'Rua tal num sei o que la',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromARGB(
                                                        255, 255, 255, 255),
                                                    height: 25,
                                                    thickness: 1,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16.0),
                                                    child: SizedBox(
                                                      child:
                                                          ElevatedButton.icon(
                                                        style: ElevatedButton
                                                            .styleFrom(),
                                                        onPressed: () async {
                                                          setState(() {
                                                            haveRoute = true;
                                                          });
                                                          stopProv.showStopInfo(
                                                              stp);
                                                          await initializeRoutes();
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        icon: const Icon(
                                                            Icons.directions),
                                                        label: const Text(
                                                            "Traçar Rota"),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                                ...activeBuses.map(
                                  (actBus) {
                                    return Marker(
                                        markerId: const MarkerId("Ônibus"),
                                        position: LatLng(
                                            actBus['coords'].latitude,
                                            actBus['coords'].longitude),
                                        icon: busMarkerIcon);
                                  },
                                )
                              },
                              polylines: Set<Polyline>.of(polylines.values),
                              polygons: {
                                ...regions.map(
                                  (rp) {
                                    return Polygon(
                                      polygonId: PolygonId(rp.name),
                                      points: rp.points,
                                      fillColor:
                                          const Color.fromARGB(5, 2, 139, 252),
                                      strokeColor:
                                          const Color.fromARGB(10, 0, 0, 0),
                                      strokeWidth: 1,
                                    );
                                  },
                                )
                              },
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: FloatingActionButton(
                                  onPressed: () async {
                                    setState(() {
                                      haveRoute = true;
                                    });
                                    await stopProv.showNearStops(
                                        regions, stops, currentPosition);
                                    await initializeRoutes();
                                  },
                                  tooltip: "Paradas próximas",
                                  backgroundColor: Colors.blue,
                                  shape: const CircleBorder(),
                                  child: const Icon(
                                    Icons.near_me,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      stopProv.isNearStopsVisible && !stopProv.isStopInfoVisible
                          ? Container(
                              width: MediaQuery.sizeOf(context).width,
                              height: MediaQuery.sizeOf(context).height / 2.5,
                              color: const Color(0xFF0057DA),
                              child: stopProv.nearStops.isNotEmpty
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              ...stopProv.nearStops.map(
                                                (stp) {
                                                  bool isFirst =
                                                      stopProv.nearStops[0] ==
                                                          stp;
                                                  if (isFirst) {
                                                    return Card(
                                                      color: Colors.white,
                                                      child: SizedBox(
                                                        width: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Text(
                                                                "Rota mais próxima"),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceEvenly,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Image.asset(
                                                                  "assets/bus_stop-icon_t.png",
                                                                  fit: BoxFit
                                                                      .contain,
                                                                  height: 70,
                                                                ),
                                                                Flexible(
                                                                  flex: 5,
                                                                  child: Text(
                                                                    softWrap:
                                                                        true,
                                                                    stp.name,
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            20),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                  ),
                                                                ),
                                                                const Flexible(
                                                                  child: Icon(
                                                                    Icons
                                                                        .directions_walk,
                                                                    size: 26,
                                                                  ),
                                                                ),
                                                                Flexible(
                                                                  flex: 5,
                                                                  child: Text(
                                                                    stopProv
                                                                        .distance,
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            18),
                                                                  ),
                                                                ),
                                                                const Flexible(
                                                                  child: Icon(
                                                                    Icons.timer,
                                                                    size: 26,
                                                                  ),
                                                                ),
                                                                Flexible(
                                                                  flex: 5,
                                                                  child: Text(
                                                                    stopProv
                                                                        .duration,
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            18),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    return Card(
                                                      color: Colors.white,
                                                      child: SizedBox(
                                                        width: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceAround,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Image.asset(
                                                              "assets/bus_stop-icon_t.png",
                                                              fit: BoxFit
                                                                  .contain,
                                                              height: 80,
                                                            ),
                                                            Flexible(
                                                              flex: 4,
                                                              child: Text(
                                                                softWrap: true,
                                                                stp.name,
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            20),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Flexible(
                                                              flex: 4,
                                                              child: InkWell(
                                                                onTap: () {
                                                                  AwesomeDialog(
                                                                    context:
                                                                        context,
                                                                    dialogType:
                                                                        DialogType
                                                                            .question,
                                                                    title:
                                                                        "Deseja traçar essa rota?",
                                                                    btnOkOnPress:
                                                                        () async {
                                                                      stopProv
                                                                          .showStopInfo(
                                                                              stp);
                                                                      await initializeRoutes();
                                                                    },
                                                                    btnCancelOnPress:
                                                                        () {},
                                                                  ).show();
                                                                },
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50),
                                                                child:
                                                                    const Icon(
                                                                  Icons
                                                                      .directions,
                                                                  color: Colors
                                                                      .blue,
                                                                  size: 35,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                            )
                          : !stopProv.isNearStopsVisible &&
                                  stopProv.isStopInfoVisible
                              ? Container(
                                  width: MediaQuery.sizeOf(context).width,
                                  height: MediaQuery.sizeOf(context).height / 5,
                                  color: const Color(0xFF0057DA),
                                  child: Card(
                                    color: Colors.white,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            "assets/bus_stop-icon_t.png",
                                            fit: BoxFit.contain,
                                            height: 80,
                                          ),
                                          Flexible(
                                            flex: 4,
                                            child: Text(
                                              softWrap: true,
                                              stopProv.selectedStop!.name,
                                              style:
                                                  const TextStyle(fontSize: 20),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const Flexible(
                                            child: Icon(
                                              Icons.directions_walk,
                                              size: 26,
                                            ),
                                          ),
                                          Flexible(
                                            flex: 3,
                                            child: Text(
                                              stopProv.distance,
                                              style:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                          ),
                                          const Flexible(
                                            child: Icon(
                                              Icons.timer,
                                              size: 26,
                                            ),
                                          ),
                                          Flexible(
                                            flex: 2,
                                            child: Text(
                                              stopProv.duration,
                                              style:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Container()
                    ],
                  );
                },
              );
            }
            return body;
          },
        ),
      ),
    );
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    final stopProv = context.read<StopProvider>();
    String removeM = '';
    final polylinePoints = PolylinePoints();

    final result = await polylinePoints.getRouteBetweenCoordinates(
        googleMapsKey,
        PointLatLng(currentPosition.latitude, currentPosition.longitude),
        PointLatLng(stopProv.selectedStop!.coords.latitude,
            stopProv.selectedStop!.coords.longitude),
        travelMode: TravelMode.walking);

    stopProv.getDistanceAndDuration(result.distance!, result.duration!);

    if (!stopProv.distance.contains("km")) {
      removeM = stopProv.distance.replaceAll('m', '');
      setState(() {
        checkDistance = int.parse(removeM);
      });
    }

    if (mounted && checkDistance <= 10) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        title: 'Você está próximo do seu destino!',
        btnOkOnPress: () {
          if (stopProv.isStopInfoVisible) {
            stopProv.hideStopInfo();
          }
          setState(() {
            haveRoute = false;
            polylines.clear();
          });
        },
        dismissOnBackKeyPress: false,
        dismissOnTouchOutside: false,
      ).show();
    }

    if (result.points.isNotEmpty) {
      return result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } else {
      debugPrint(result.errorMessage);
      return [];
    }
  }

  Future<void> generatePolylineFromPoints(
      List<LatLng> polylineCoordinates) async {
    const id = PolylineId('polyline');

    final polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 8,
    );

    setState(() {
      polylines[id] = polyline;
    });
  }
}
