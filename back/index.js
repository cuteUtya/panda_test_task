const express = require('express');
const expressWs = require('express-ws');
const bodyParser = require('body-parser');
const uuidv4 = require("uuid").v4;

const app = express();
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
        speed: defaultSpeed ?? generateRandom(1, 10),
        battery: 100,
        temperature: TEMPERATURE_MIN,
    };
}

const FIELD_SIZE_X = 100;
const FIELD_SIZE_Y = 100;
const SPEED_MAX = 15;
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

    var isRunning = false;
    var inited = false;
    var movingAngle = generateRandom(0, 360);

    var status = undefined;
    const intervalId = setInterval(() => {
        if (status) {
            if (status.temperature >= TEMPERATURE_MAX && isRunning) {
                isRunning = false;
                sendInfo('Robot was stopped due to overheating');
            }

            if (status.battery <= 0 && isRunning) {
                isRunning = false;
                sendInfo('Robot was stopped due to low power');
            }

            if (isRunning) {
                // Speed under 5 does not use battery
                // Speed 5-10 use 1% battery each second
                // 10-15 use 2% battery each second
                status.battery = clamp(status.battery - Math.floor(status.speed / 5), 0, 100);
                status.temperature = clamp(status.temperature + Math.floor(status.speed / 5), TEMPERATURE_MIN, TEMPERATURE_MAX);

                // lets say our speed is units per minute our robot is moving
                const speedPerSecond = status.speed / 60;
                const deltaX = speedPerSecond * Math.cos(movingAngle);
                const deltaY = speedPerSecond * Math.sin(movingAngle);

                //Even though it wasn't specified in task i really want  
                //to make robot movement kinda of realistic 
                status.position.x = (status.position.x + deltaX + FIELD_SIZE_X) % FIELD_SIZE_X;
                status.position.y = (status.position.y + deltaY + FIELD_SIZE_Y) % FIELD_SIZE_Y;
            } else {
                status.battery = clamp(status.battery + 1, 0, 100);
                status.temperature = clamp(status.temperature - 1, TEMPERATURE_MIN, TEMPERATURE_MAX);
            }

            sendState(status);
        }
    }, 1000);

    ws.on('message', (message) => {
        try {
            const command = JSON.parse(message);
            console.log(command);

            if (command.type != 'robot_init' && !inited) {
                sendError('Please, init the robot');
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
                            sendInfo('Success');
                            return;
                        } else {
                            sendError('Session is invalid');
                        }
                    }

                    //Create default robot
                    status = createRobot();
                    inited = true;
                    break;

                case 'robot_start':
                    isRunning = true;
                    break;

                case 'robot_stop':
                    isRunning = false;
                    break;

                case 'robot_change_speed':
                    status.speed = clamp(command.value, 0, SPEED_MAX);
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