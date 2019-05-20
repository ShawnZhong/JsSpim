const playButton = document.getElementById('play-button');
const resetButton = document.getElementById('reset-button');
const stepButton = document.getElementById('step-button');
const runButton = document.getElementById('run-button');
const speedSelector = document.getElementById('speed-selector');

const maxSpeed = speedSelector.max;
let speed = parseInt(speedSelector.value);

class Execution {
    static init() {
        outputDOM.innerHTML = "";
        logDOM.innerHTML = "";
        memoryDOM.innerHTML = '';

        Execution.finished = false;
        Execution.playing = false;

        runButton.disabled = false;
        stepButton.disabled = false;
        playButton.disabled = false;
        playButton.innerHTML = "Play";
        runButton.innerHTML = "Run";

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
        runButton.disabled = true;
        playButton.innerHTML = "Play";
        runButton.innerHTML = "Run";
    }

    static run() {
        runButton.innerHTML = "Continue";
        Execution.finished = !Spim.run();
        if (Execution.finished) Execution.finish();
        Display.update();
    }

    static step() {
        const result = Spim.step();

        if (result === 1)  // finished
            Execution.finish();
        else if (result === 2 && Execution.playing)  // break point encountered
            Execution.pause();

        Display.update();
    }

    static togglePlay() {
        if (Execution.playing) {
            Execution.pause();
        } else {
            Execution.playing = true;
            playButton.innerHTML = "Pause";
            Execution.play();
        }
    }

    static pause() {
        Execution.playing = false;
        playButton.innerHTML = "Continue";
    }

    static play() {
        if (!Execution.playing || Execution.finished) return;
        Execution.step();
        setTimeout(Execution.play, maxSpeed - speed);
    }
}
resetButton.onclick = Execution.init;
stepButton.onclick = Execution.step;
runButton.onclick = Execution.run;
playButton.onclick = Execution.togglePlay;