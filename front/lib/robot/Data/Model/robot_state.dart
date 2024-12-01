import 'package:flutter/cupertino.dart';

class RobotState {
  final Offset position;
  final double speed;
  final double battery;
  final double temperature;
  final bool isActive;

  RobotState({
    required this.battery,
    required this.position,
    required this.speed,
    required this.temperature,
    required this.isActive,
  });

  factory RobotState.fromJson(Map<String, dynamic> json) {
    return RobotState(
      battery: json['battery'] as double,
      position: Offset(json['position']['x'], json['position']['y']),
      speed: json['speed'],
      temperature: json['temperature'],
      isActive: json['isActive'],
    );
  }
}
