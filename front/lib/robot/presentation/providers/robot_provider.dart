import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panda_test_task/robot/Data/Model/robot_command.dart';
import 'package:panda_test_task/robot/Data/Model/robot_messages.dart';
import 'package:panda_test_task/robot/Data/Model/robot_state.dart';
import 'package:panda_test_task/robot/Data/Repositories/robot_repository.dart';

class RobotController extends StateNotifier<RobotState?> {
  final _repo = RobotRepository();

  final StreamController<RobotMessageInfo> _info = StreamController();
  Stream<RobotMessageInfo> get infoStream {
    return _info.stream;
  }

  final StreamController<RobotMessageError> _error = StreamController();
  Stream<RobotMessageError> get errorStream {
    return _error.stream;
  }

  RobotController({double? defaultSpeed, Offset? defaultPosition})
    : super(null) {
    _repo.createRobot(position: defaultPosition, speed: defaultSpeed).then((
      e,
    ) async {
      await _repo.summonRobot(robot: e);
      _listener();
    });
  }

  void _listener() async {
    var stream = await _repo.getMessagesStream();
    stream.listen((event) {
      if (event is RobotMessageState) {
        state = event.state;
      } else if (event is RobotMessageInfo) {
        _info.add(event);
      } else if (event is RobotMessageError) {
        _error.add(event);
      }
    });
  }

  void sendCommand(RobotCommand cmd) {
    _repo.sendMessage(cmd);
  }
}

StateNotifierProvider<RobotController, RobotState?> robotProvider({
  double? defaultSpeed,
  Offset? defaultPosition,
}) => StateNotifierProvider<RobotController, RobotState?>(
  (ref) => RobotController(
    defaultPosition: defaultPosition,
    defaultSpeed: defaultSpeed,
  ),
);
