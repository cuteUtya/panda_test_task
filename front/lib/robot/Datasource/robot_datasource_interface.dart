import 'dart:ui';

import 'package:panda_test_task/robot/Data/Model/robot_command.dart';
import 'package:panda_test_task/robot/Data/Model/robot_messages.dart';
import 'package:panda_test_task/robot/Data/Model/robot_session.dart';

abstract class RobotDatasourceInterface {
  Future<void> sendCommand(RobotCommand command);
  Future<Stream<RobotMessage>> getMessagesStream();
  Future<RobotSession> createRobot({Offset? position, double? speed});
  void dispose();
}
