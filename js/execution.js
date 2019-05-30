class Execution {
    static init(reset = false) {
        Execution.maxSpeed = Elements.speedSelector.max;
        Execution.speed = Elements.speedSelector.value;

        Execution.started = false;
        Execution.playing = false;
        Execution.skipBreakpoint = false;

        Elements.stepButton.disabled = false;
        Elements.playButton.disabled = false;
        Elements.playButton.innerHTML = (Execution.speed === Execution.maxSpeed) ? "Run" : "Play";

        Elements.output.innerHTML = '';
        Elements.log.innerHTML = '';

        Module.init();
        RegisterUtils.init();
        MemoryUtils.init();

        if (reset) {
            InstructionUtils.removeAllBreakpoints();
            InstructionUtils.highlightCurrentInstruction();
        } else {
            InstructionUtils.init();
            InstructionUtils.highlightCurrentInstruction();
        }
    }

    static step(stepSize = 1) {
        const result = Module.step(stepSize, Execution.playing ? Execution.skipBreakpoint : true);

        if (result === 0)  // finished
            Execution.finish();
        else if (result === -1) {  // break point encountered
            Execution.skipBreakpoint = true;
            Execution.playing = false;
            Elements.playButton.innerHTML = "Continue";
        } else if (result === 1) { // break point not encountered
            Execution.skipBreakpoint = false;
        }

        RegisterUtils.update();
        MemoryUtils.update();
        InstructionUtils.highlightCurrentInstruction();
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
        if (Execution.speed === Execution.maxSpeed) {
            Execution.step(0);
        } else {
            Execution.step();
            setTimeout(Execution.play, Execution.maxSpeed - Execution.speed);
        }
    }

    static finish() {
        Execution.playing = false;

        Elements.playButton.disabled = true;
        Elements.stepButton.disabled = true;

        Elements.playButton.innerHTML = (Execution.speed === Execution.maxSpeed) ? "Run" : "Play";
    }

    static setSpeed(newSpeed) {
        Execution.speed = newSpeed;
        if (Execution.started) return;
        Elements.playButton.innerHTML = (Execution.speed === Execution.maxSpeed) ? "Run" : "Play";
    }
}

Elements.resetButton.onclick = () => Execution.init(true);
Elements.stepButton.onclick = () => Execution.step(1);
Elements.playButton.onclick = () => Execution.togglePlay();