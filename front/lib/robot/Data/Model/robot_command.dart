class RobotCommand {
  late final String type;

  Map<String, dynamic> toJson() {
    return {'type': type};
  }
}

class RobotCommandInit extends RobotCommand {
  @override
  String get type {
    return 'robot_init';
  }

  final String? uid;

  RobotCommandInit({this.uid});

  @override
  Map<String, dynamic> toJson() {
    var j = super.toJson();
    j['uid'] = uid;

    return j;
  }
}

class RobotCommandStart extends RobotCommand {
  @override
  String get type {
    return 'robot_start';
  }
}

class RobotCommandStop extends RobotCommand {
  @override
  String get type {
    return 'robot_stop';
  }
}

class RobotCommandChangeSpeed extends RobotCommand {
  @override
  String get type {
    return 'robot_change_speed';
  }

  final double value;

  RobotCommandChangeSpeed({required this.value});

  @override
  Map<String, dynamic> toJson() {
    var j = super.toJson();
    j['value'] = value;

    return j;
  }
}
