const worker = new Worker('js/highlight.min.js');
worker.onmessage = (event) => event.data.forEach((e, i) => InstructionUtils.instructionList[i].instructionElement.innerHTML = e);

class InstructionUtils {
    static init() {
        Elements.userTextContent.innerHTML = '';
        Elements.kernelTextContent.innerHTML = '';

        const userText = Module.getUserText().split("\n").slice(0, -1).map(e => new Instruction(e));
        userText.forEach(e => Elements.userTextContent.appendChild(e.element));

        const kernelText = Module.getKernelText().split("\n").slice(0, -1).map(e => new Instruction(e));
        kernelText.forEach(e => Elements.kernelTextContent.appendChild(e.element));

        InstructionUtils.instructionList = [...userText, ...kernelText];

        InstructionUtils.instructionDict = {};
        userText.forEach(e => InstructionUtils.instructionDict[e.address] = e);
        kernelText.forEach(e => InstructionUtils.instructionDict[e.address] = e);

        InstructionUtils.formatCode();
    }

    static removeAllBreakpoints() {
        InstructionUtils.instructionList
            .filter(e => e.isBreakpoint)
            .forEach(e => {
                e.isBreakpoint = false;
                e.element.style.fontWeight = null;
            });
    }

    static highlightCurrentInstruction() {
        if (InstructionUtils.highlighted)
            InstructionUtils.highlighted.style.backgroundColor = null;

        const pc = RegisterUtils.getPC();
        const instruction = InstructionUtils.instructionDict[pc];
        if (!instruction) return;

        InstructionUtils.highlighted = instruction.element;
        InstructionUtils.highlighted.style.backgroundColor = 'yellow';
        InstructionUtils.highlighted.scrollIntoView({block: "nearest"});
    }

    static formatCode() {
        worker.postMessage(this.instructionList.map(e => e.instructionElement.innerHTML));
    }

    static toggleBinary(showBinary) {
        InstructionUtils.instructionList.forEach(e => {
            e.showBinary = showBinary;
            e.binaryElement.innerText = e.getBinaryInnerText();
        });
    }

    static toggleSourceCode(showSourceCode) {
        InstructionUtils.instructionList.forEach(e => {
            e.showSourceCode = showSourceCode;
            e.sourceCodeElement.innerText = e.getSourceCodeInnerText();
        });
    }

    static toggleKernelText(shoeKernelText) {
        if (shoeKernelText)
            Elements.kernelTextContainer.style.display = null;
        else
            Elements.kernelTextContainer.style.display = 'none';
    }
}

class Instruction {
    constructor(text) {
        this.text = text;

        this.isBreakpoint = false;
        this.showBinary = false;
        this.showSourceCode = true;

        this.addressString = this.text.substring(3, 11);
        this.address = Number.parseInt(this.addressString, 16);

        this.initElement()
    }

    initElement() {
        this.element = document.createElement("div");

        this.indexOfComma = this.text.indexOf(';');

        // address
        this.element.innerHTML = `[<span class="hljs-attr">${this.addressString}</span>] `;

        // instruction value
        this.binaryElement = document.createElement("span");
        this.binaryElement.innerText = this.getBinaryInnerText();
        this.binaryElement.classList.add("hljs-number");
        this.element.appendChild(this.binaryElement);

        // instruction
        this.instructionElement = document.createElement("span");
        this.instructionElement.innerText = this.getInstructionInnerText();
        this.element.appendChild(this.instructionElement);

        // source code
        this.sourceCodeElement = document.createElement("span");
        this.sourceCodeElement.classList.add("hljs-comment");
        this.sourceCodeElement.innerText = this.getSourceCodeInnerText();
        this.element.appendChild(this.sourceCodeElement);

        // add event listener
        this.element.onclick = () => this.toggleBreakpoint();
        return this.element;
    }

    getBinaryInnerText() {
        return this.showBinary ? this.text.substring(15, 24) : "";
    }

    getSourceCodeInnerText() {
        return (this.showSourceCode && this.indexOfComma > 0) ? this.text.substring(this.indexOfComma) : "";
    }

    getInstructionInnerText() {
        return this.indexOfComma > 0 ? this.text.substring(25, this.indexOfComma) : this.text.substring(25);
    }

    toggleBreakpoint() {
        this.isBreakpoint = !this.isBreakpoint;
        if (this.isBreakpoint) {
            Module.addBreakpoint(this.address);
            this.element.style.fontWeight = "bold";
        } else {
            Module.deleteBreakpoint(this.address);
            this.element.style.fontWeight = null;
        }
    }
}