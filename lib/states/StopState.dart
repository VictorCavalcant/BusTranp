import 'package:ubus/models/Stop.dart';

sealed class StopState {}

class EmptyStopState implements StopState {}

class LoadingStopState implements StopState {}

class ErrorStopState implements StopState {
  final String message;

  ErrorStopState(this.message);
}

class SucessStopState implements StopState {
  final List<Stop> stops;

  SucessStopState(this.stops);
}
