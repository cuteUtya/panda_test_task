# Robot Repository

## Features
- Platform-specific robot datasource management
- WebSocket-based robot communication
- Robot session creation and control
- Stream-based message handling

## Architecture
- `RobotRepository`: Central management class
- Supports web platform datasource
- Throws exception for unsupported platforms

## Key Methods
- `summonRobot()`: Initialize robot session
- `sendMessage()`: Send robot commands
- `getMessagesStream()`: Receive robot messages
- `createRobot()`: Create new robot session
- `dispose()`: Clean up resources


## Platform Support
- Web ✓
- Others ✗ (Unsupported)
