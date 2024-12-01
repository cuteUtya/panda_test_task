const express = require('express');
const expressWs = require('express-ws');
const bodyParser = require('body-parser');
const uuidv4 = require("uuid").v4;
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.static("public"));
expressWs(app);
app.use(bodyParser.json());

function clamp(num, min, max) {
    return num <= min
        ? min
        : num >= max
            ? max
            : num
}
const generateRandom = (min, max) => Math.random() * (max - min) + min;
function createRobot(defaultPosition, defaultSpeed) {
    return {
        position: defaultPosition ?? {
            x: 50,
            y: 50,
        },
        speed: defaultSpeed ?? generateRandom(40, 100),
        battery: 100,
        temperature: TEMPERATURE_MIN,
        isActive: true,
    };
}

const FIELD_SIZE_X = 100;
const FIELD_SIZE_Y = 100;
const SPEED_MAX = 200;
const TEMPERATURE_MAX = 100;
const TEMPERATURE_MIN = 25;

let sessions = {};

// Function to create custom robot session 
app.post('/robot/create', (request, responce) => {
    bodyParser.raw({ type: "application/json" });
    const {
        position,
        speed,
    } = request.body;

    if (position) {
        if (position.x > FIELD_SIZE_X || position.x < 0) {
            responce.status(400).send(`position.x out of range 0...${FIELD_SIZE_X}`);
            return;
        }

        if (position.y > FIELD_SIZE_Y || position.y < 0) {
            responce.status(400).send(`position.y out of range 0...${FIELD_SIZE_Y}`);
            return;
        }
    }

    if (speed) {
        if (speed > SPEED_MAX || speed < 0) {
            responce.status(400).send(`speed is out of range 0...${SPEED_MAX}`);
            return;
        }
    }

    var id = uuidv4();
    sessions[id] = createRobot(position, speed);
    responce.status(200).json(id);


    setTimeout(() => {
        if (sessions[id]) {
            sessions[id] = undefined;
            console.log(`Session ${id} was deleted, due to user inactivity`);
        }
        //Session is valid for 30 seconds, 
        //If user not gonna connect for 30 seconds 
        //We simple delete the created session
    }, 30 * 1000);
})

app.ws('/robot/status', (ws) => {
    function sendData(data) {
        ws.send(JSON.stringify(data));
    }

    function sendState(state) {
        sendData({
            'type': 'new_state',
            'state': state,
        });
    }

    function sendInfo(info) {
        sendData({
            'type': 'info',
            'info': info
        });
    }

    function sendError(error) {
        sendData({
            'type': 'error',
            'error': error,
        });
    }

    var inited = false;

    var status = undefined;
    var movingAngle = [0, 180, 90][Math.floor(generateRandom(0, 2))];
    const intervalId = setInterval(() => {
        if (status) {
            if (status.temperature >= TEMPERATURE_MAX && status.isActive) {
                status.isActive = false;
                sendInfo('Robot was stopped due to overheating');
            }

            if (status.battery <= 0 && status.isActive) {
                status.isActive = false;
                sendInfo('Robot was stopped due to low power');
            }

            if (status.isActive) {
                movingAngle += [12.25, 0, -12.25][Math.floor(generateRandom(0, 3))];

                status.battery = clamp(status.battery - Math.floor(status.speed / 50), 0, 100);
                status.temperature = clamp(status.temperature + Math.floor(status.speed / 50), TEMPERATURE_MIN, TEMPERATURE_MAX);

                // lets say our speed is units per minute our robot is moving
                const speedPerSecond = status.speed / 60;
                const deltaX = speedPerSecond * Math.sin(movingAngle * 3.14 / 180);
                const deltaY = speedPerSecond * Math.cos(movingAngle * 3.14 / 180);

                //Even though it wasn't specified in task i really want  
                //to make robot movement kinda of realistic 
                status.position.x = (status.position.x + deltaX + FIELD_SIZE_X) % FIELD_SIZE_X;
                status.position.y = (status.position.y + deltaY + FIELD_SIZE_Y) % FIELD_SIZE_Y;
            } else {
                status.battery = clamp(status.battery + 0.5, 0, 100);
                status.temperature = clamp(status.temperature - 1, TEMPERATURE_MIN, TEMPERATURE_MAX);
            }

            sendState(status);
        }
    }, 1000);

    ws.on('message', (message) => {
        try {
            const command = JSON.parse(message);

            if (command.type != 'robot_init' && !inited) {
                return;
            }
            switch (command.type) {
                case 'robot_init':
                    if (inited) {
                        sendError('Robot already inited');
                        return;
                    }
                    //If session was created via REST we use it 
                    if (command.uid) {
                        if (sessions[command.uid]) {
                            status = sessions[command.uid];
                            inited = true;
                            sessions[command.uid] = undefined;
                            sendInfo('Robot succesfully created');
                            return;
                        } else {
                            sendError('Session is invalid');
                        }
                    }

                    //Create default robot
                    status = createRobot();
                    inited = true;
                    sendInfo('Robot succesfully created');
                    break;

                case 'robot_start':
                    status.isActive = true;
                    sendInfo('Robot started');
                    break;

                case 'robot_stop':
                    status.isActive = false;
                    sendInfo('Robot stopped');
                    break;

                case 'robot_change_speed':
                    status.speed = clamp(command.value, 0, SPEED_MAX);
                    sendInfo('Speed succesfully changed');
                    break;
            }
        } catch (e) {
            sendError(e.toString());
        }
    });

    ws.on('close', () => {
        console.log('Connection was closed');
        clearInterval(intervalId);
    });
});

app.listen(3000, () => {
    console.log('Server is running');
})