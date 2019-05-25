const worker = new Worker('js/highlight.min.js');
worker.onmessage = (event) => event.data.forEach((e, i) => InstructionUtils.instructions[i].element.innerHTML = e);

class InstructionUtils {
    static showInstructions() {
        Elements.text.innerHTML = '';

        InstructionUtils.instructions = Spim.getUserText().split("\n").slice(0, -1).map(e => new Instruction(e));
        InstructionUtils.instructions.forEach(e => Elements.text.appendChild(e.element));

        InstructionUtils.formatCode();
    }

    static removeAllBreakpoints() {
        InstructionUtils.instructions
            .filter(e => e.isBreakpoint)
            .forEach(e => e.element.style.fontWeight = null);
    }

    static highlightCurrentInstruction() {
        if (InstructionUtils.highlighted)
            InstructionUtils.highlighted.style.backgroundColor = null;

        const pc = Spim.getPC();
        const instruction = InstructionUtils.instructions[pc === 0 ? 0 : (pc - 0x400000) / 4];
        if (!instruction) return;

        InstructionUtils.highlighted = instruction.element;
        InstructionUtils.highlighted.style.backgroundColor = 'yellow';
        InstructionUtils.highlighted.scrollIntoView(false);
    }

    static formatCode() {
        worker.postMessage(InstructionUtils.instructions.map(e => e.element.innerHTML));
    }

    static toggleInstructionBinary(showBinary) {
        Display.instructions.forEach(e => {
            e.showBinary = showBinary;
            e.element.innerHTML = e.getInnerHTML();
        });
        Display.formatCode()
    }

    static toggleInstructionComment(showComment) {
        Display.instructions.forEach(e => {
            e.showComment = showComment;
            e.element.innerHTML = e.getInnerHTML();
        });
        Display.formatCode()
    }
}

class Instruction {
    constructor(text) {
        this.text = text;

        this.isBreakpoint = false;
        this.showBinary = false;
        this.showComment = true;
        this.showInstruction = true;

        this.address = text.substring(1, 11);
        this.element = this.getElement();
    }

    getElement() {
        const element = document.createElement("pre");
        element.innerHTML = this.getInnerHTML();
        element.onclick = () => {
            if (this.isBreakpoint)
                this.removeBreakpoint();
            else
                this.addBreakpoint();
        };

        return element;
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

    addBreakpoint() {
        this.isBreakpoint = true;
        Spim.addBreakpoint(this.address);
        this.element.style.fontWeight = "bold";
    }

    removeBreakpoint() {
        this.isBreakpoint = false;
        Spim.deleteBreakpoint(this.address);
        this.element.style.fontWeight = null;
    }
}