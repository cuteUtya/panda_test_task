import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:panda_test_task/env.dart';
import 'package:panda_test_task/robot/Data/Model/robot_command.dart';
import 'package:panda_test_task/robot/Data/Model/robot_messages.dart';
import 'package:panda_test_task/robot/Data/Model/robot_session.dart';
import 'package:panda_test_task/robot/Datasource/robot_datasource_interface.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RobotWebRemoteDatasource implements RobotDatasourceInterface {
  late WebSocketChannel ws;
  late Future<void> _connectionCompleter;

  RobotWebRemoteDatasource() {
    _connect();
  }

  void _connect() async {
    ws = WebSocketChannel.connect(Uri.parse(websocketEndPoint));
    _connectionCompleter = ws.ready;
  }

  @override
  Future<Stream<RobotMessage>> getMessagesStream() async {
    await _connectionCompleter;

    return ws.stream.map((e) => RobotMessage.fromJson(jsonDecode(e)));
  }

  @override
  Future<void> sendCommand(RobotCommand command) async {
    await _connectionCompleter;
    ws.sink.add(jsonEncode(command.toJson()));
  }

  @override
  Future<RobotSession> createRobot({Offset? position, double? speed}) async {
    var d = Dio();
    var request = await d.post(
      configEndPoint,
      data: {
        if (position != null) 'position': {'x': position.dx, 'y': position.dy},
        'speed': speed,
      },
    );

    return RobotSession(request.data);
  }

  @override
  void dispose() {
    ws.sink.close();
  }
}
