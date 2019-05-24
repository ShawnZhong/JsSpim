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
        Execution.playing = false;
        Execution.continueBreakpoint = false;

        stepButton.disabled = false;
        playButton.disabled = false;
        playButton.innerHTML = (speed === maxSpeed) ? "Run" : "Play";

        Spim.init();
        Display.init();
        Display.update();
        Display.update(); // to prevent highlight
    }

    static finish() {
        Execution.pause();

        playButton.disabled = true;
        stepButton.disabled = true;

        playButton.innerHTML = (speed === maxSpeed) ? "Run" : "Play";
    }

    static step(stepSize = 1) {
        const result = Spim.step(stepSize, Execution.playing ? Execution.continueBreakpoint : true);

        if (Execution.continueBreakpoint)
            Execution.continueBreakpoint = false;

        if (result === 1)  // finished
            Execution.finish();
        else if (result === 2) {  // break point encountered
            Execution.pause();
            if (Execution.playing)
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
            Execution.play();
            playButton.innerHTML = Execution.getLabel();
        }
    }

    static pause() {
        Execution.playing = false;
        Execution.paused = true;
        playButton.innerHTML = "Continue"
    }

    static play() {
        if (!Execution.playing) return;
        Execution.step();
        setTimeout(Execution.play, maxSpeed - speed);
    }


    static setSpeed(newSpeed) {
        speed = newSpeed;
        playButton.innerHTML = Execution.getLabel();
    }

    static getLabel() {
        if (Execution.playing) return "Pause";
        if (Execution.paused) return "Continue";
        return (speed === maxSpeed) ? "Run" : "Play";
    }
}

resetButton.onclick = Execution.init;
stepButton.onclick = () => Execution.step(1);
playButton.onclick = Execution.togglePlay;