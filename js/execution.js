const playDOM = document.getElementById('play');
const speedDOM = document.getElementById('speed-selector');

const Status = {
    INITIAL: -1,
    STOPPED: 0,
    RUNNING: 1,
    FINISHED: 2,
};

const maxSpeed = parseInt(speedDOM.max);
let speed = parseInt(speedDOM.value);
let status = Status.FINISHED;


function setSpeed(newSpeed) {
    speed = parseInt(newSpeed);

    if (speed === 0) {
        status = Status.STOPPED;
        playDOM.innerHTML = "Step";
    } else if (speed === maxSpeed)
        playDOM.innerHTML = "Run ";
    else {
        console.log(status);
        if (status === Status.FINISHED)
            playDOM.innerHTML = "Play";
        else if (status === Status.STOPPED) {
            playDOM.innerHTML = "Continue";
        }
    }
}

function play() {
    console.log(status);
    if (status === Status.FINISHED) {
        playDOM.innerHTML = "Play";
        return;
    }

    if (speed === maxSpeed) {
        outputDOM.innerHTML = "";
        Module.run();
        status = Status.FINISHED;
        playDOM.innerHTML = "Run";
    } else {
        const finished = !Module.step();
        if (finished) status = Status.FINISHED;
    }

    RegisterUtils.update();
    MemoryUtils.update(RegisterUtils.getPC());

    if (status === Status.RUNNING)
        setTimeout(play, maxSpeed - speed);
}

playDOM.onclick = () => {
    if (status === Status.RUNNING) {
        status = Status.STOPPED;
        playDOM.innerHTML = "Continue";
        return;
    }

    if (status === Status.FINISHED) {
        status = Status.RUNNING;
        outputDOM.innerHTML = "";
        Module.init("input.s");
    } else if (status === Status.STOPPED && speed !== 0) {
        status = Status.RUNNING;
        playDOM.innerHTML = "Pause";
    }

    play();
};