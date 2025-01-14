import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:ubus/firebase_options.dart';
import 'package:ubus/providers/BusTrackingProvider.dart';
import 'package:ubus/services/DriverService.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

class BackgroundService {
  Future<void> initService() async {
    final service = FlutterBackgroundService();

    await service.configure(
        iosConfiguration: IosConfiguration(),
        androidConfiguration: AndroidConfiguration(
            onStart: onStart, isForegroundMode: true, autoStart: true));

    service.startService();
  }

  static void onStart(ServiceInstance service) async {
    print("executando em plano de fundo");

    try {
      await Firebase.initializeApp();
      print("Firebase inicializado com sucesso no serviço em segundo plano.");
    } catch (e) {
      print("Erro ao inicializar o Firebase: $e");
    }

    if (!getIt.isRegistered<BusTrackingProvider>()) {
      getIt.registerSingleton<BusTrackingProvider>(BusTrackingProvider());
      print(
          "BusTrackingProvider registrado novamente no contexto de plano de fundo.");
    }

    final busTrackingProvider = getIt<BusTrackingProvider>();

    DriverService().getActiveBuses().listen((snapshot) {
      // Processar os dados ou manter o stream ativo
      processSnapshot(snapshot, busTrackingProvider);
    });
  }

  static void processSnapshot(
      QuerySnapshot snapshot, BusTrackingProvider busTrackingProvider) {
    // Processar as mudanças incrementais
    final docChanges = snapshot.docChanges;
    if (docChanges.isNotEmpty) {
      for (var change in docChanges) {
        if (change.type == DocumentChangeType.added) {
          busTrackingProvider.addBusBG(change.doc);
        } else if (change.type == DocumentChangeType.modified) {
          busTrackingProvider.updateBusBG(change.doc);
        } else if (change.type == DocumentChangeType.removed) {
          busTrackingProvider.removeBusBG(change.doc);
        }
      }

      if (busTrackingProvider.activeBus != null &&
          busTrackingProvider.activeBuses.isNotEmpty &&
          busTrackingProvider.tracking) {
        dynamic actB = busTrackingProvider.activeBuses.firstWhere(
          (aB) => busTrackingProvider.activeBus['id'] == aB['id'],
          orElse: () => null,
        );

        if (actB != null) {
          busTrackingProvider.updateActiveBusBG(actB);

          String distanceBusValue = busTrackingProvider.distanceBus;

          if (!distanceBusValue.contains("km")) {
            if (distanceBusValue.contains("m")) {
              distanceBusValue = distanceBusValue.replaceAll("m", "");
            }

            busTrackingProvider.checkArrivalNotification(distanceBusValue);
          }

          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            busTrackingProvider.fetchDistanceBackground();
          });
        }
      }
    }
  }
}
