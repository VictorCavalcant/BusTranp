import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ubus/extra/linhas.dart';
import 'package:ubus/key/googleMapsKey.dart';
import 'package:ubus/models/Region.dart';
import 'package:ubus/models/Stop.dart';
import 'package:ubus/pages/HomePage.dart';
import 'package:ubus/providers/BusTrackingProvider.dart';
import 'package:ubus/services/DriverService.dart';
import 'dart:ui' as ui;
import 'package:battery_plus/battery_plus.dart';

import 'package:ubus/stores/StopStore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UserMapPage extends StatefulWidget {
  const UserMapPage({super.key});

  @override
  State<UserMapPage> createState() => _UserMapPageState();
}

class _UserMapPageState extends State<UserMapPage> {
  final stopStore = StopStore();
  loc.Location location = loc.Location();
  bool lowBattery = false;
  ValueNotifier<bool> lowBattery2 = ValueNotifier(false);
  dynamic activeBus;
  ValueNotifier<dynamic> activeBus2 = ValueNotifier(dynamic);
  final battery = Battery();
  List<Stop> stops = [];
  Stop stopDestination = const Stop('', LatLng(0.0, 0.0), '');
  List<Region> regions = [];
  List activeBuses = [];
  LatLng currentPosition = const LatLng(0.0, 0.0);
  bool haveRoute = false;
  ValueNotifier<bool> haveRoute2 = ValueNotifier(false);
  bool tracking = false;
  ValueNotifier<bool> tracking2 = ValueNotifier(false);
  int checkDistance = 0;
  ValueNotifier<int> checkDistance2 = ValueNotifier(0);
  int checkDistanceBus = 0;
  String locBus = "";
  String arriveTimeBus = "";
  ValueNotifier<String> arriveTimeBus2 = ValueNotifier("");
  String distanceBus2 = "";
  ValueNotifier<String> distanceBus = ValueNotifier("");
  DriverService driverService = DriverService();
  StreamController<QuerySnapshot<Object?>> _driverStreamController =
      StreamController<QuerySnapshot<Object?>>();
  StreamSubscription<QuerySnapshot>? _driverStreamSubscription;
  bool isArrived = false;
  ValueNotifier<bool> isArrived2 = ValueNotifier(false);
  bool auxArrived = false;
  bool routing = false;
  bool auxTrackTime = false;
  ValueNotifier<bool> auxTrackTime2 = ValueNotifier(false);
  bool auxTrackRoute = false;
  ValueNotifier<bool> auxTrackRoute2 = ValueNotifier(false);
  bool trackingBus = false;
  ValueNotifier<bool> trackingBus2 = ValueNotifier(false);
  Timer? trackTimer;
  bool renderBus = false;
  String distanceHolder = "";
  BuildContext? contextHolder;
  final GetIt getIt = GetIt.instance;
  List<String> linhasBus = [];

  Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  Map<PolylineId, Polyline> polylines = {};
  ValueNotifier<Map<PolylineId, Polyline>> polylines2 = ValueNotifier({});

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

  _customBusMarkerIcon() async {
    final Uint8List customIcon =
        await getBytesFromAssets("assets/bus_LocMark.png", 120);
    busMarkerIcon = BitmapDescriptor.fromBytes(customIcon);
  }

  checkBatteryLevel() async {
    Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        if (await battery.batteryLevel <= 40 && !lowBattery) {
          location.changeSettings(
            accuracy: loc.LocationAccuracy.powerSave,
            distanceFilter: 8,
          );
          setState(
            () {
              lowBattery = true;
            },
          );
        } else if (await battery.batteryLevel > 40 && lowBattery) {
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

  Future<void> _cameraToPosition({LatLng? busPosition}) async {
    final GoogleMapController controller = await _mapController.future;
    controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: busPosition ?? currentPosition, zoom: 17),
      ),
    );
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
      (loc.LocationData currentLocation) async {},
    );
  }

  Future<List<String>> getLinhas() async {
    return await driverService.getLinhas();
  }

  getAllBuses() async {
    await _driverStreamController.close();
    await _driverStreamSubscription?.cancel();

    _driverStreamController = StreamController<QuerySnapshot<Object?>>();

    _driverStreamSubscription = driverService.getActiveBuses().listen(
      (snapshot) {
        if (!_driverStreamController.isClosed) {
          _driverStreamController.add(snapshot);
        }
      },
    );

    setState(() {});
  }

  // void updateFilterBus(String linha) {
  //   filterBus = linha;
  //   setState(() {});
  //   getFilterBuses();
  // }

  // void resetAllBuses() {
  //   filterBus = "";
  //   getAllBuses();
  //   setState(() {});
  // }

  Future<void> openGoogleForm() async {
    const String googleFormUrl =
        "https://docs.google.com/forms/d/e/1FAIpQLSeYPfTp2uqsSpLdqEVf7193nGyn8AVXBWScACCSKS0nK6U0DA/viewform?usp=dialog";
    if (await canLaunchUrlString(googleFormUrl)) {
      await launchUrlString(googleFormUrl);
    } else {
      throw 'Não foi possível abrir o link: $googleFormUrl';
    }
  }

  // getFilterBuses() async {
  //   await _driverStreamController.close();
  //   await _driverStreamSubscription?.cancel();

  //   _driverStreamController = StreamController<QuerySnapshot<Object?>>();

  //   _driverStreamSubscription =
  //       driverService.getFilterBuses(filterBus).listen((snapshot) {
  //     if (!_driverStreamController.isClosed) {
  //       _driverStreamController.add(snapshot);
  //     }
  //   });
  //   setState(() {});
  // }

  BitmapDescriptor stopMarkerIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor busMarkerIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      getAllBuses();
      getLinhas();
    });
    checkBatteryLevel();
    getCurrentLocation();
    _cameraToPosition();
    _customStopMarkerIcon();
    _customBusMarkerIcon();
    super.initState();
  }

  @override
  void dispose() {
    _mapController = Completer();
    _driverStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BusTrackingProvider busTrackingProvider = getIt<BusTrackingProvider>();
    return ChangeNotifierProvider<BusTrackingProvider>.value(
      value: busTrackingProvider,
      child: Consumer<BusTrackingProvider>(
        builder: (context, busProvider, child) {
          return Scaffold(
            drawer: Drawer(
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
                  ),
                  ListTile(
                    leading: const Icon(Icons.manage_search),
                    title: const Text('Localizar ônibus'),
                    onTap: () async {
                      showModalBottomSheet(
                        backgroundColor: Colors.blue,
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, locSetState) => SizedBox(
                              width: MediaQuery.sizeOf(context).width,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Card(
                                  color: Colors.white,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/bus_Search2.png',
                                        width: 120,
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      const Text(
                                        "Selecione uma linha de ônibus para localizar",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(40.0),
                                        child: DropdownSearch<String>(
                                          onBeforePopupOpening:
                                              (selectedItem) async {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                            return true;
                                          },
                                          popupProps:
                                              PopupProps.modalBottomSheet(
                                            modalBottomSheetProps:
                                                ModalBottomSheetProps(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(0),
                                              ),
                                            ),
                                            fit: FlexFit.tight,
                                            showSelectedItems: true,
                                            showSearchBox: true,
                                            searchFieldProps: TextFieldProps(
                                              decoration: InputDecoration(),
                                            ),
                                          ),
                                          items: (filter, loadProps) =>
                                              getLinhas(),
                                          decoratorProps:
                                              DropDownDecoratorProps(
                                            decoration: InputDecoration(
                                                counterText: 'Teste'),
                                          ),
                                          onChanged: (value) {
                                            locBus = value!;
                                            setState(() {});
                                            locSetState(() {});
                                          },
                                          selectedItem: locBus,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 7,
                                      ),
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          "Ok",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.gps_fixed),
                    title:
                        const Text('Habilitar localização em plano de fundo'),
                    onTap: () async {
                      await Geolocator.openLocationSettings();
                      await location.enableBackgroundMode(enable: true);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('Formulário de Avaliação'),
                    onTap: () async {
                      await openGoogleForm();
                    },
                  ),
                ],
              ),
            ),
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
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: _driverStreamController.stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  // Não há dados, limpa o rastreamento
                  busProvider.toggleTracking(false);
                  busProvider.clearBuses();
                } else {
                  // Processa apenas as mudanças incrementais nos documentos
                  final docChanges = snapshot.data!.docChanges;

                  if (docChanges.isNotEmpty) {
                    for (var change in docChanges) {
                      if (change.type == DocumentChangeType.added) {
                        // Documento adicionado
                        busProvider.addBus(change.doc);
                      } else if (change.type == DocumentChangeType.modified) {
                        // Documento modificado
                        busProvider.updateBus(change.doc);
                      } else if (change.type == DocumentChangeType.removed) {
                        // Documento removido
                        busProvider.removeBus(change.doc);
                      }
                    }
                  }

                  // Atualiza o ônibus ativo, se necessário
                  if (busProvider.activeBus != null &&
                      busProvider.activeBuses.isNotEmpty &&
                      busProvider.tracking) {
                    dynamic actB = busProvider.activeBuses.firstWhere(
                      (aB) => busProvider.activeBus['id'] == aB['id'],
                      orElse: () => null,
                    );

                    if (actB != null) {
                      busProvider.updateActiveBus(actB);

                      // Verifica proximidade do ônibus
                      String distanceBusValue = busProvider.distanceBus;

                      if (!distanceBusValue.contains("km")) {
                        if (distanceBusValue.contains("m")) {
                          distanceBusValue =
                              distanceBusValue.replaceAll("m", "");
                        }

                        busProvider.checkArrival(distanceBusValue, context);
                      }

                      // Atualiza as linhas de rota periodicamente
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        fetchPolylinePointsBus(busProvider);
                      });
                    }
                  }
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
                                target: currentPosition, zoom: 18),
                            onMapCreated:
                                ((GoogleMapController controller) async {
                              if (!_mapController.isCompleted) {
                                _mapController.complete(controller);
                              }
                            }),
                            myLocationEnabled: true,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            markers: {
                              ...busTrackingProvider.activeBuses.map(
                                (actBus) {
                                  return Marker(
                                    markerId: const MarkerId("Ônibus"),
                                    position: LatLng(actBus['coords'].latitude,
                                        actBus['coords'].longitude),
                                    icon: busMarkerIcon,
                                    anchor: const Offset(0.5, 0.5),
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
                                                    'Van ${actBus['linha']}',
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const Divider(
                                                  color: Color.fromARGB(
                                                    255,
                                                    255,
                                                    255,
                                                    255,
                                                  ),
                                                  height: 25,
                                                  thickness: 1,
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      16.0),
                                                  child: SizedBox(
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton
                                                          .styleFrom(),
                                                      onPressed: () async {
                                                        if (!busTrackingProvider
                                                                .tracking &&
                                                            busTrackingProvider
                                                                    .activeBus !=
                                                                actBus) {
                                                          busTrackingProvider
                                                              .toggleTracking(
                                                                  true);
                                                          busTrackingProvider
                                                              .setActiveBus(
                                                                  actBus);

                                                          await fetchPolylinePointsBus(
                                                              busTrackingProvider);

                                                          if (mounted &&
                                                              context.mounted) {
                                                            Navigator.pop(
                                                                context);
                                                          }
                                                        } else {
                                                          busTrackingProvider
                                                              .toggleTracking(
                                                                  false);
                                                          busTrackingProvider
                                                              .setActiveBus(
                                                                  dynamic);
                                                          Navigator.pop(
                                                              context);
                                                        }
                                                        setState(() {});
                                                      },
                                                      icon: const Icon(
                                                          Icons.track_changes),
                                                      label: Text(!busTrackingProvider
                                                                  .tracking &&
                                                              busTrackingProvider
                                                                      .activeBus !=
                                                                  actBus
                                                          ? "Rastrear Ônibus"
                                                          : "Parar de Rastrear"),
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
                          busTrackingProvider.tracking
                              ? Positioned(
                                  top: 60,
                                  right: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: FloatingActionButton(
                                      onPressed: () async {
                                        _cameraToPosition(
                                          busPosition: LatLng(
                                              busTrackingProvider
                                                  .activeBus['coords'].latitude,
                                              busTrackingProvider
                                                  .activeBus['coords']
                                                  .longitude),
                                        );
                                      },
                                      tooltip: "Focar Ônibus",
                                      backgroundColor: Colors.blue,
                                      shape: const CircleBorder(),
                                      child: const Icon(
                                        Icons.directions_bus_filled_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Container()
                        ],
                      ),
                    ),
                    busTrackingProvider.tracking
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "assets/bus_icon.png",
                                      fit: BoxFit.contain,
                                      height: 80,
                                    ),
                                    const Flexible(
                                      child: Icon(
                                        Icons.signpost,
                                        size: 26,
                                      ),
                                    ),
                                    Flexible(
                                      flex: 3,
                                      child: Text(
                                        busTrackingProvider.distanceBus,
                                        style: const TextStyle(fontSize: 18),
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
            ),
          );
        },
      ),
    );
  }

  Future<List<LatLng>> fetchPolylinePointsBus(
      BusTrackingProvider busTrackingProvider) async {
    if (busTrackingProvider.executionCountTrack >=
        busTrackingProvider.executionLimitTrack) {
      busTrackingProvider
          .resetCounterTrackAfterDelay(const Duration(seconds: 2));
      return [];
    }

    final polylinePoints = PolylinePoints();

    String removeM = '';
    String removeK = '';

    String distanceBus = "";
    String arriveTimeBus = "";

    if (!busTrackingProvider.tracking) {
      busTrackingProvider.setDistance("");
    }

    if (busTrackingProvider.tracking &&
        busTrackingProvider.executionCountTrack <
            busTrackingProvider.executionLimitTrack) {
      try {
        if (busTrackingProvider.auxTrackRoute) {
          return [];
        }

        busTrackingProvider.setAuxTrackRoute(true);

        final result = await polylinePoints.getRouteBetweenCoordinates(
            googleMapsKey,
            PointLatLng(busTrackingProvider.activeBus['coords'].latitude,
                busTrackingProvider.activeBus['coords'].longitude),
            PointLatLng(currentPosition.latitude, currentPosition.longitude),
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
            busTrackingProvider.setDistance('$intValue m');
            // distanceBus2 = '$intValue m';
          } else {
            busTrackingProvider.setDistance(result.distance!);
            distanceBus2 = result.distance!;
          }
        } else if (!removeM.contains('m')) {
          busTrackingProvider.setDistance(result.distance!);
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
        busTrackingProvider.setAuxTrackRoute(false);
        // auxTrackRoute2.value = false;
        // setState(() {
        //   auxTrackRoute = false;
        // });
      }
    } else {
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

    // polylines2.value[id] = polyline;
    setState(
      () {
        polylines[id] = polyline;
      },
    );
  }
}
