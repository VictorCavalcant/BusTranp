import 'package:flutter/material.dart';
import 'package:ubus/services/StopService.dart';
import 'package:ubus/states/StopState.dart';

class StopStore extends ChangeNotifier {
  final service = StopService();

  StopState state = EmptyStopState();

  getStops() async {
    state = LoadingStopState();
    notifyListeners();

    try {
      final stops = await service.getStops();
      state = SucessStopState(stops);
      notifyListeners();
    } catch (e) {
      state = ErrorStopState(e.toString());
      notifyListeners();
    }
  }
}
