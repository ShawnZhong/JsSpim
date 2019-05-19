const playButton = document.getElementById('play-button');
const resetButton = document.getElementById('reset-button');
const stepButton = document.getElementById('step-button');
const speedSelector = document.getElementById('speed-selector');

const maxSpeed = parseInt(speedSelector.max);
let speed = parseInt(speedSelector.value);

class Execution {
    static run() {
        Spim.run();
        Execution.finish();
        RegisterUtils.update();
        MemoryUtils.update(RegisterUtils.getPC());
    }

    static step() {
        if (!Spim.step()) Execution.finish();
        RegisterUtils.update();
        MemoryUtils.update(RegisterUtils.getPC());
    }

    static play() {
        if (speed === maxSpeed) {
            Execution.run();
        } else {
            Execution.step();
            setTimeout(Execution.play, maxSpeed - speed);
        }
    }

    static finish() {
        Execution.running = false;
        playButton.disabled = true;
        stepButton.disabled = true;
    }

    static init() {
        outputDOM.innerHTML = "";
        logDOM.innerHTML = "";

        Execution.running = false;
        playButton.disabled = false;
        stepButton.disabled = false;
        playButton.innerHTML = getButtonLabel();

        Spim.init();
        RegisterUtils.init();
        MemoryUtils.init();
    }
}


function getButtonLabel() {
    if (Execution.running) return "Pause";
    return speed === maxSpeed ? "Run" : "Play"
}

function setSpeed(newSpeed) {
    speed = parseInt(newSpeed);
    playButton.innerHTML = getButtonLabel();
}


resetButton.onclick = Execution.init;
stepButton.onclick = Execution.step;
playButton.onclick = () => {
    Execution.running = !Execution.running;
    Execution.play();
    playButton.innerHTML = getButtonLabel();
};