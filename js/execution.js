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

        Spim.init();
        Display.init();
        Display.update();
        Display.update(); // to prevent highlight
    }


    static run() {
        Execution.finished = !Spim.run();
        if (Execution.finished) Execution.finish();
        Display.update();
    }

    static step() {
        Execution.finished = !Spim.step();
        if (Execution.finished) Execution.finish();
        Display.update();
    }

    static play() {
        Execution.playing = !Execution.playing;
        Execution.playHandler();
        playButton.innerHTML = Execution.finished ? "Play" : " Pause";
    }

    static playHandler() {
        if (!Execution.playing || Execution.finished) return;
        Execution.step();
        setTimeout(Execution.playHandler, maxSpeed - speed);
    }

    static finish() {
        Execution.playing = false;
        Execution.finished = true;
        playButton.disabled = true;
        stepButton.disabled = true;
        runButton.disabled = true;
    }
}
resetButton.onclick = Execution.init;
stepButton.onclick = Execution.step;
runButton.onclick = Execution.run;
playButton.onclick = Execution.play;