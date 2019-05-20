const playButton = document.getElementById('play-button');
const resetButton = document.getElementById('reset-button');
const stepButton = document.getElementById('step-button');
const speedSelector = document.getElementById('speed-selector');

const maxSpeed = speedSelector.max;
let speed = speedSelector.value;

class Execution {
    static init() {
        outputDOM.innerHTML = "";
        logDOM.innerHTML = "";
        memoryDOM.innerHTML = '';

        Execution.paused = false;
        Execution.finished = false;
        Execution.playing = false;
        Execution.continueBreakpoint = false;

        stepButton.disabled = false;
        playButton.disabled = false;
        playButton.innerHTML = Execution.getLabel();

        Spim.init();
        Display.init();
        Display.update();
        Display.update(); // to prevent highlight
    }

    static finish() {
        Execution.playing = false;
        Execution.finished = true;

        playButton.disabled = true;
        stepButton.disabled = true;

        playButton.innerHTML = Execution.getLabel();
    }

    static step(stepSize = 1) {
        const result = Spim.step(stepSize, Execution.playing ? Execution.continueBreakpoint : true);

        if (Execution.continueBreakpoint) Execution.continueBreakpoint = false;

        if (result === 1)  // finished
            Execution.finish();
        else if (result === 2 && Execution.playing) {  // break point encountered
            Execution.pause();
            Execution.continueBreakpoint = true;
        }

        Display.update();
    }

    static togglePlay() {
        if (speed === maxSpeed) {
            Execution.step(0);
        } else if (Execution.playing) {
            Execution.pause();
        } else {
            Execution.playing = true;
            Execution.setSpeed();
            Execution.play();
        }
    }

    static pause() {
        Execution.playing = false;
        Execution.paused = true;
        playButton.innerHTML = Execution.getLabel();
    }

    static play() {
        if (!Execution.playing || Execution.finished) return;
        Execution.step();
        setTimeout(Execution.play, maxSpeed - speed);
    }


    static setSpeed(newSpeed = speed) {
        speed = newSpeed;
        playButton.innerHTML = Execution.getLabel();
    }

    static getLabel() {
        if (Execution.playing) return "Pause";
        if (Execution.paused) return "Continue";
        if (speed === maxSpeed) return "Run";
        return "Play";
    }
}

resetButton.onclick = Execution.init;
stepButton.onclick = () => Execution.step(1);
playButton.onclick = Execution.togglePlay;