const playButton = document.getElementById('play-button');
const resetButton = document.getElementById('reset-button');
const stepButton = document.getElementById('step-button');
const speedSelector = document.getElementById('speed-selector');

const maxSpeed = speedSelector.max;
let speed = speedSelector.value;

class Execution {
    static init() {
        outputDOM.innerHTML = '';
        logDOM.innerHTML = '';
        memoryDOM.innerHTML = '';

        Execution.started = false;
        Execution.playing = false;
        Execution.skipBreakpoint = false;

        stepButton.disabled = false;
        playButton.disabled = false;
        playButton.innerHTML = (speed === maxSpeed) ? "Run" : "Play";

        Spim.init();
        Display.init();
        Display.update();
        Display.update(); // to prevent highlight
    }

    static step(stepSize = 1) {
        const result = Spim.step(stepSize, Execution.playing ? Execution.skipBreakpoint : true);

        if (result === 1)  // finished
            Execution.finish();
        else if (result === 2) {  // break point encountered
            Execution.skipBreakpoint = true;
            Execution.playing = false;
            playButton.innerHTML = "Continue";
        } else { // break point not encountered
            Execution.skipBreakpoint = false;
        }

        Display.update();
    }

    static togglePlay() {
        Execution.started = true;
        if (Execution.playing) {
            Execution.playing = false;
            playButton.innerHTML = "Continue"
        } else {
            Execution.playing = true;
            playButton.innerHTML = "Pause";
            Execution.play();
        }
    }

    static play() {
        if (!Execution.playing) return;
        if (speed === maxSpeed) {
            Execution.step(0);
        } else {
            Execution.step();
            setTimeout(Execution.play, maxSpeed - speed);
        }
    }

    static finish() {
        Execution.playing = false;

        playButton.disabled = true;
        stepButton.disabled = true;

        playButton.innerHTML = (speed === maxSpeed) ? "Run" : "Play";
    }

    static setSpeed(newSpeed) {
        speed = newSpeed;
        if (Execution.started) return;
        playButton.innerHTML = (speed === maxSpeed) ? "Run" : "Play";
    }
}

resetButton.onclick = Execution.init;
stepButton.onclick = () => Execution.step(1);
playButton.onclick = Execution.togglePlay;