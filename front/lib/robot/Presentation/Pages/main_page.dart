import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panda_test_task/robot/Data/Model/robot_command.dart';
import 'package:panda_test_task/robot/Data/Model/robot_state.dart';
import 'package:panda_test_task/robot/Presentation/Providers/robot_provider.dart';
import 'package:panda_test_task/robot/Presentation/Widgets/context_tooltip.dart';
import 'package:panda_test_task/robot/Presentation/Widgets/info_card.dart';
import 'package:panda_test_task/robot/Presentation/Widgets/robot_state_drawer.dart';

import 'dart:ui' as ui;

import 'package:panda_test_task/robot/Presentation/Widgets/temperature_indicator.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState {
  Offset? mousePosition;
  Offset? robotPinPosition;

  Offset? oldPosition;

  MainPageStateMachine inputState = MainPageStateMachine.waitingForUserOptions;

  StateNotifierProvider<RobotController, RobotState?>?
  currentRobotStateProvider;
  RobotState? robotState;

  double initialSpeed = 0;

  double workingArea = 0;

  Future<ui.Image> _load(String path) async {
    final ByteData assetImageByteData = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      assetImageByteData.buffer.asUint8List(),
      targetHeight: 50,
      targetWidth: 50,
    );
    return (await codec.getNextFrame()).image;
  }

  Offset getRelativeMousePosition(Offset mousePosition) =>
      mousePosition / workingArea * 100;

  String pinPositionToString(double workingArea) {
    if (robotPinPosition == null) {
      return 'Please click where you want your robot';
    }

    var relativePosition = getRelativeMousePosition(robotPinPosition!);
    return 'x: ${relativePosition.dx.toStringAsFixed(2)}, y: ${relativePosition.dy.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (currentRobotStateProvider != null) {
      ref.listen(currentRobotStateProvider!, (oldState, newState) {
        oldPosition = oldState?.position;
        setState(() => robotState = newState);
      });
    }

    var screenH = MediaQuery.of(context).size.height;
    workingArea = screenH;

    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: _controllingPanel(context),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => robotPinPosition = mousePosition),
            child: Stack(
              children: [
                FutureBuilder(
                  future: _load('images/tank_green.png'),
                  builder:
                      (_, data) =>
                          !data.hasData
                              ? SizedBox()
                              : SizedBox(
                                width: screenH,
                                height: screenH,
                                child: CustomPaint(
                                  size: Size(screenH, screenH),
                                  painter: RobotStateDrawer(
                                    robotState: robotState,
                                    tankImage: data.data,
                                    oldPosition: oldPosition,
                                  ),
                                ),
                              ),
                ),
                if (mousePosition != null)
                  Positioned(
                    bottom: mousePosition!.dy,
                    left: mousePosition!.dx,
                    child: ContextTooltip(
                      text:
                          'x: ${(mousePosition!.dx / workingArea * 100).toStringAsFixed(2)}\n'
                          'y: ${(mousePosition!.dy / workingArea * 100).toStringAsFixed(2)}',
                    ),
                  ),
                if (robotPinPosition != null &&
                    inputState == MainPageStateMachine.waitingForUserOptions)
                  Positioned(
                    bottom: robotPinPosition!.dy - 8,
                    left: robotPinPosition!.dx - 8,
                    child: Container(
                      height: 16,
                      width: 16,
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        border: Border.all(color: Colors.black),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.precise,
                    onExit: (e) => setState(() => mousePosition = null),
                    onHover: (hover) {
                      setState(
                        () =>
                            mousePosition = Offset(
                              hover.localPosition.dx,
                              screenH - hover.localPosition.dy,
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                if (currentRobotStateProvider != null)
                  StreamBuilder(
                    stream:
                        ref
                            .read(currentRobotStateProvider!.notifier)
                            .infoStream,
                    builder:
                        (_, e) =>
                            !e.hasData
                                ? SizedBox.shrink()
                                : InfoCard(
                                  title: 'Information',
                                  body: e.data!.info,
                                  icon: Icons.info,
                                  color: Theme.of(context).primaryColor,
                                ),
                  ),

                if (currentRobotStateProvider != null)
                  StreamBuilder(
                    stream:
                        ref
                            .read(currentRobotStateProvider!.notifier)
                            .errorStream,
                    builder:
                        (_, e) =>
                            !e.hasData
                                ? SizedBox.shrink()
                                : InfoCard(
                                  color: Colors.red,
                                  title: 'Error!',
                                  body: e.data!.error,
                                  icon: Icons.error,
                                ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controllingPanel(BuildContext context) =>
      currentRobotStateProvider == null
          ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Initial position: ${pinPositionToString(workingArea)}'),
              const SizedBox(height: 16),
              Text(
                'Initial robot speed: ${(initialSpeed * 200).toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              Slider(
                padding: EdgeInsets.zero,
                value: initialSpeed,
                onChanged: (v) => setState(() => initialSpeed = v),
              ),
              Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: () => createRobot(context),
                  child: Text('Create robot'),
                ),
              ),
            ],
          )
          : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Robot speed: ${robotState?.speed.toStringAsFixed(2)}'),
              Slider(
                padding: EdgeInsets.zero,
                value: (robotState?.speed ?? 0) / 200,
                onChanged: (v) => setSpeed(v * 200),
              ),
              const SizedBox(height: 32),
              Text('Robot temperature: ${robotState?.temperature}°'),
              TemperatureIndicator(temperature: robotState?.temperature),
              const SizedBox(height: 32),
              RichText(
                text: TextSpan(
                  text: 'Robot status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text:
                          (robotState?.isActive ?? false)
                              ? 'Working'
                              : 'Inactive',
                      style: TextStyle(
                        color:
                            robotState != null
                                ? (robotState!.isActive
                                    ? Colors.green
                                    : Colors.red)
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Row(
                children: [
                  ElevatedButton(onPressed: () => stop(), child: Text('Stop')),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () => start(),
                    child: Text('Start'),
                  ),
                ],
              ),
            ],
          );

  void setSpeed(double v) => ref
      .read(currentRobotStateProvider!.notifier)
      .sendCommand(RobotCommandChangeSpeed(value: v));

  void start() => ref
      .read(currentRobotStateProvider!.notifier)
      .sendCommand(RobotCommandStart());

  void stop() => ref
      .read(currentRobotStateProvider!.notifier)
      .sendCommand(RobotCommandStop());

  void createRobot(BuildContext context) {
    currentRobotStateProvider = robotProvider(
      defaultSpeed: initialSpeed * 200,
      defaultPosition:
          robotPinPosition == null
              ? null
              : getRelativeMousePosition(robotPinPosition!),
    );
    ref
        .read(currentRobotStateProvider!.notifier)
        .sendCommand(RobotCommandStart());

    robotPinPosition = null;

    setState(() => inputState = MainPageStateMachine.ready);
  }
}

enum MainPageStateMachine { waitingForUserOptions, ready }
