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

        Display.update(reset);
    }

    static toggleInstructionBinary(showBinary) {
        Display.instructions.forEach(e => {
            e.showBinary = showBinary;
            e.element.innerHTML = e.getInnerHTML();
        });
        Display.highlightCode()
    }

    static toggleInstructionComment(showComment) {
        Display.instructions.forEach(e => {
            e.showComment = showComment;
            e.element.innerHTML = e.getInnerHTML();
        });
        Display.highlightCode()
    }

    static highlightCode() {
        const worker = new Worker('js/highlight.min.js');
        worker.onmessage = (event) => event.data.forEach((e, i) => Display.instructions[i].element.innerHTML = e);
        worker.postMessage(Display.instructions.map(e => e.element.innerHTML));
    }

    static update(computeDiff = true) {
        Elements.stack.innerHTML = Spim.getUserStack(computeDiff);
        Elements.data.innerHTML = Spim.getUserData(computeDiff);
        Elements.generalReg.innerHTML = Spim.getGeneralReg(computeDiff);
        Elements.specialReg.innerHTML = Spim.getSpecialReg(computeDiff);

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
        this.text = text;

        this.breakpoint = false;
        this.showBinary = false;
        this.showComment = true;
        this.showInstruction = true;

        this.address = text.substring(1, 11);
        this.element = this.getElement();
    }

    getInnerHTML() {
        const indexOfComma = this.text.indexOf(';');

        let result = `[${this.address}] `;

        if (this.showBinary)
            result += this.text.substring(13, 24);

        if (this.showInstruction)
            result += indexOfComma > 0 ? this.text.substring(24, indexOfComma) : this.text.substring(24);

        if (this.showComment && indexOfComma > 0)
            result += this.text.substring(indexOfComma);

        return result;
    }

    getElement() {
        const element = document.createElement("pre");
        element.innerHTML = this.getInnerHTML();
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