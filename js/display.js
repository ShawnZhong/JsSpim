class Display {
    static init(reset = false) {
        Elements.output.innerHTML = '';
        Elements.log.innerHTML = '';

        if (reset) {
            Display.instructions.filter(e => e.breakpoint).forEach(e => e.removeBreakpoint());
        } else {
            Elements.text.innerHTML = '';

            Display.instructions = Spim.getUserText().split("\n").slice(0, -1).map(e => new Instruction(e));
            Display.instructions.forEach(e => Elements.text.appendChild(e.element));

            Display.highlightCode();
        }

        Display.update();
    }

    static highlightCode() {
        const worker = new Worker('js/highlight.min.js');
        worker.onmessage = (event) => event.data.forEach((e, i) => Display.instructions[i].element.innerHTML = e);
        worker.postMessage(Display.instructions.map(e => e.innerHTML));
    }

    static update() {
        Elements.stack.innerHTML = Spim.getUserStack();
        Elements.data.innerHTML = Spim.getUserData();
        Elements.generalReg.innerHTML = Spim.getGeneralReg();
        Elements.specialReg.innerHTML = Spim.getSpecialReg();

        // highlight instruction
        if (Display.highlighted)
            Display.highlighted.style.backgroundColor = null;

        const pc = Spim.getPC();
        const instruction = Display.instructions[pc === 0 ? 0 : (pc - 0x400000) / 4];
        if (!instruction) return;

        Display.highlighted = instruction.element;
        Display.highlighted.style.backgroundColor = 'yellow';
        Display.highlighted.scrollIntoView(false);
    }
}

class Instruction {
    constructor(text) {
        this.breakpoint = false;
        this.address = text.substring(1, 11);
        this.innerHTML = this.getInnerHTML(text);
        this.element = this.getElement();
    }

    getInnerHTML(text) {
        const indexOfComma = text.indexOf(';');
        const binary = text.substring(13, 23);
        const instruction = indexOfComma > 0 ? text.substring(25, indexOfComma) : text.substring(25);
        const comment = indexOfComma > 0 ? text.substring(indexOfComma) : "";

        return `[${this.address}] ${instruction} ${comment}`
    }

    getElement() {
        const element = document.createElement("pre");
        element.innerHTML = this.innerHTML;
        element.onclick = () => {
            this.breakpoint = !this.breakpoint;
            if (this.breakpoint)
                this.addBreakpoint();
            else
                this.removeBreakpoint();
        };

        return element;
    }

    addBreakpoint() {
        Spim.addBreakpoint(this.address);
        this.element.style.fontWeight = "bold";
    }

    removeBreakpoint() {
        Spim.deleteBreakpoint(this.address);
        this.element.style.fontWeight = null;
    }
}