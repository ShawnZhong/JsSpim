const memoryDOM = document.getElementById('text-content');
const dataDOM = document.getElementById('data-content');
const stackDOM = document.getElementById('stack-content');
const generalRegDOM = document.getElementById('general-regs');
const specialRegDOM = document.getElementById('special-regs');


class Display {
    static init() {
        this.instructions = Spim.getUserText().split("\n").map(e => new Instruction(e));
        this.instructions.forEach(e => memoryDOM.appendChild(e.DOM));
    }


    static update() {
        stackDOM.innerHTML = Spim.getUserStack();
        dataDOM.innerHTML = Spim.getUserData();
        generalRegDOM.innerHTML = Spim.getGeneralRegVals();
        specialRegDOM.innerHTML = Spim.getSpecialRegVals();
        this.highlightInstruction();
    }

    static highlightInstruction() {
        if (this.highlighted) this.highlighted.style.backgroundColor = null;
        const pc = Spim.getPC();
        const instruction = this.instructions[pc === 0 ? 0 : (pc - 0x400000) / 4];
        if (!instruction) return;
        this.highlighted = instruction.DOM;
        this.highlighted.style.backgroundColor = 'yellow';
        this.highlighted.scrollIntoView(false);
    }
}

class Instruction {
    constructor(instruction) {
        this.address = instruction.substr(1, 10);
        this.breakpoint = false;

        this.DOM = document.createElement("pre");
        this.DOM.innerText = instruction.substring(0, 12) + instruction.substring(24);
        this.DOM.onclick = () => {
            this.breakpoint = !this.breakpoint;
            if (this.breakpoint) {
                Spim.addBreakpoint(this.address);
                this.DOM.style.fontWeight = "bold";
            } else {
                Spim.deleteBreakpoint(this.address);
                this.DOM.style.fontWeight = null;
            }
        };
    }
}