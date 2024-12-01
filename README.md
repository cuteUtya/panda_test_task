# Robot Simulation Server
## Overview
WebSocket-based server for creating and controlling virtual robots in a 2D field.

## Endpoints

### POST `/robot/create`
#### Request Body
```json
{
  "position": {
    "x": 0-100,
    "y": 0-100
  },
  "speed": 0-200
}
```
#### Response
- Success: `sessionId: string`
- Error: `400 Bad Request`

### WebSocket `/robot/status`
#### Initialization
```json
{
  "type": "robot_init",
  "uid": "optional_session_id"
}
```

#### Commands
```json
{
  "type": "robot_start" | "robot_stop" | "robot_change_speed",
  "value": "optional_speed_0-200"
}
```

#### Response Types
- `new_state`: Current robot status
- `info`: Operational messages
- `error`: Error notifications
