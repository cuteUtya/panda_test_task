import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:panda_test_task/robot/Data/Model/robot_command.dart';
import 'package:panda_test_task/robot/Data/Model/robot_messages.dart';
import 'package:panda_test_task/robot/Data/Model/robot_session.dart';
import 'package:panda_test_task/robot/Datasource/robot_datasource_interface.dart';
import 'package:panda_test_task/robot/Datasource/robot_web_remote_datasource.dart';

class RobotRepository {
  late RobotDatasourceInterface _datasource;

  RobotRepository() {
    if (kIsWeb) {
      _datasource = RobotWebRemoteDatasource();
      return;
    }

    throw Exception('App is running in unsupported platform');
  }

  Future<void> summonRobot({RobotSession? robot}) async {
    await _datasource.sendCommand(RobotCommandInit(uid: robot?.id));
  }

  void sendMessage(RobotCommand command) {
    _datasource.sendCommand(command);
  }

  Future<Stream<RobotMessage>> getMessagesStream() {
    return _datasource.getMessagesStream();
  }

  void dispose() {
    _datasource.dispose();
  }

  Future<RobotSession> createRobot({Offset? position, double? speed}) =>
      _datasource.createRobot(position: position, speed: speed);
}
