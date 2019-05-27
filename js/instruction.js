const worker = new Worker('js/highlight.min.js');
worker.onmessage = (event) => event.data.forEach((e, i) => InstructionUtils.instructions[i].instructionElement.innerHTML = e);

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
            .forEach(e => {
                e.isBreakpoint = false;
                e.element.style.fontWeight = null;
            });
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
        worker.postMessage(InstructionUtils.instructions.map(e => e.instructionElement.innerHTML));
    }

    static toggleInstructionBinary(showBinary) {
        InstructionUtils.instructions.forEach(e => {
            e.showBinary = showBinary;
            e.binaryElement.innerText = e.getBinaryInnerText();
        });
    }

    static toggleInstructionComment(showComment) {
        InstructionUtils.instructions.forEach(e => {
            e.showComment = showComment;
            e.commentElement.innerText = e.getCommentInnerText();
        });
    }
}

class Instruction {
    constructor(text) {
        this.text = text;

        this.isBreakpoint = false;
        this.showBinary = false;
        this.showComment = true;

        this.address = this.text.substring(3, 11);

        this.initElement()
    }

    initElement() {
        this.element = document.createElement("pre");

        this.indexOfComma = this.text.indexOf(';');

        this.element.innerHTML = `[<span class="hljs-attr">${this.address}</span>] `;

        this.binaryElement = document.createElement("span");
        this.binaryElement.innerText = this.getBinaryInnerText();
        this.binaryElement.classList.add("hljs-number");
        this.element.appendChild(this.binaryElement);

        this.instructionElement = document.createElement("span");
        this.instructionElement.innerText = this.getInstructionInnerText();
        this.element.appendChild(this.instructionElement);

        this.commentElement = document.createElement("span");
        this.commentElement.classList.add("hljs-comment");
        this.commentElement.innerText = this.getCommentInnerText();
        this.element.appendChild(this.commentElement);

        this.element.onclick = () => this.toggleBreakpoint();
        return this.element;
    }

    getBinaryInnerText() {
        return this.showBinary ? this.text.substring(13, 24) : "";
    }

    getCommentInnerText() {
        return (this.showComment && this.indexOfComma > 0) ? this.text.substring(this.indexOfComma) : "";
    }

    getInstructionInnerText() {
        return this.indexOfComma > 0 ? this.text.substring(24, this.indexOfComma) : this.text.substring(24);
    }

    toggleBreakpoint() {
        this.isBreakpoint = !this.isBreakpoint;
        if (this.isBreakpoint) {
            Spim.addBreakpoint(Number.parseInt(this.address, 16));
            this.element.style.fontWeight = "bold";
        } else {
            Spim.deleteBreakpoint(Number.parseInt(this.address, 16));
            this.element.style.fontWeight = null;
        }
    }
}