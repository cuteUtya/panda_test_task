# Robot Flutter Frontend

## Features
- Platform-specific robot datasource management
- WebSocket-based robot communication
- Robot session creation and control
- Stream-based message handling

## Architecture
This repository follows the principles of clean architecture, ensuring separation of concerns and scalability. Here's the directory structure and key components:
### 1. Data layer
Model
Handles the robot's data and communication with external sources
- `RobotCommand`: Command structures for robot actions
- `RobotMessages`: Handles incoming robot communication
- `RobotSession`: Represents a robot session
- `RobotState`: Represent robot state

Repository
- `RobotRepository`: Acts as the central interface for managing robot data and delegating tasks to the appropriate datasource

Datasource
- `RobotDataSourceInterface`: Abstracts data operations
- `RobotWebRemoteDatasource`: Implements the interface for WebSocket-based communication

### 2. Presentation Layer
Providers 
- `RobotProvider`: A `StateNotifier` from `flutter_riverpod` to manage and expose the robot's state

Pages
Main page that utilizes RobotProvider and provides business logic to the UI.

