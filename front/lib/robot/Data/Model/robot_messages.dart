import 'package:panda_test_task/robot/Data/Model/robot_state.dart';

abstract class RobotMessage {
  factory RobotMessage.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'new_state':
        return RobotMessageState.fromJson(json);

      case 'info':
        return RobotMessageInfo.fromJson(json);

      case 'error':
        return RobotMessageError.fromJson(json);
    }

    throw Exception('Undefined message type');
  }
}

class RobotMessageError implements RobotMessage {
  final String error;

  RobotMessageError({required this.error});

  factory RobotMessageError.fromJson(Map<String, dynamic> json) {
    return RobotMessageError(error: json['error']);
  }
}

class RobotMessageInfo implements RobotMessage {
  final String info;

  RobotMessageInfo({required this.info});

  factory RobotMessageInfo.fromJson(Map<String, dynamic> json) {
    return RobotMessageInfo(info: json['info']);
  }
}

class RobotMessageState implements RobotMessage {
  final RobotState state;

  RobotMessageState({required this.state});

  factory RobotMessageState.fromJson(Map<String, dynamic> json) {
    return RobotMessageState(state: RobotState.fromJson(json['state']));
  }
}
