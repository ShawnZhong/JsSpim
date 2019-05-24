const maxSpeed = Elements.speedSelector.max;
let speed = Elements.speedSelector.value;

class Execution {
    static init() {
        Execution.started = false;
        Execution.playing = false;
        Execution.skipBreakpoint = false;

        Elements.stepButton.disabled = false;
        Elements.playButton.disabled = false;
        Elements.playButton.innerHTML = (speed === maxSpeed) ? "Run" : "Play";

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
            Elements.playButton.innerHTML = "Continue";
        } else { // break point not encountered
            Execution.skipBreakpoint = false;
        }

        Display.update();
    }

    static togglePlay() {
        Execution.started = true;
        if (Execution.playing) {
            Execution.playing = false;
            Elements.playButton.innerHTML = "Continue"
        } else {
            Execution.playing = true;
            Elements.playButton.innerHTML = "Pause";
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

        Elements.playButton.disabled = true;
        Elements.stepButton.disabled = true;

        Elements.playButton.innerHTML = (speed === maxSpeed) ? "Run" : "Play";
    }

    static setSpeed(newSpeed) {
        speed = newSpeed;
        if (Execution.started) return;
        Elements.playButton.innerHTML = (speed === maxSpeed) ? "Run" : "Play";
    }
}

Elements.resetButton.onclick = Execution.init;
Elements.stepButton.onclick = () => Execution.step(1);
Elements.playButton.onclick = Execution.togglePlay;