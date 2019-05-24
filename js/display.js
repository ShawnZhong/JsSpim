class Display {
    static init() {
        Elements.output.innerHTML = '';
        Elements.log.innerHTML = '';
        Elements.text.innerHTML = '';

        Display.instructions = Spim.getUserText().split("\n").map(e => new Instruction(e));
        Display.instructions.forEach(e => Elements.text.appendChild(e.node));
    }

    static update() {
        Elements.stack.innerHTML = Spim.getUserStack();
        Elements.data.innerHTML = Spim.getUserData();
        Elements.generalReg.innerHTML = Spim.getGeneralReg();
        Elements.specialReg.innerHTML = Spim.getSpecialReg();
        Display.highlightInstruction();
    }

    static highlightInstruction() {
        if (Display.highlighted)
            Display.highlighted.style.backgroundColor = null;

        const pc = Spim.getPC();
        const instruction = Display.instructions[pc === 0 ? 0 : (pc - 0x400000) / 4];
        if (!instruction) return;

        Display.highlighted = instruction.node;
        Display.highlighted.style.backgroundColor = 'yellow';
        Display.highlighted.scrollIntoView(false);
    }
}

class Instruction {
    constructor(instruction) {
        this.instruction = instruction;
        this.address = instruction.substr(1, 10);
        this.breakpoint = false;

        this.node = document.createElement("pre");
        this.node.innerText = instruction.substring(0, 12) + instruction.substring(24);
        this.node.onclick = () => {
            this.breakpoint = !this.breakpoint;
            if (this.breakpoint) {
                Spim.addBreakpoint(this.address);
                this.node.style.fontWeight = "bold";
            } else {
                Spim.deleteBreakpoint(this.address);
                this.node.style.fontWeight = null;
            }
        };
    }
}