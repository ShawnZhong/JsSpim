class MemoryUtils {
    static init() {
        this.DOM = document.getElementById('memory-content');
        this.DOM.innerHTML = '';

        this.instructions = Module.getUserText().split("\n").map(e => new Instruction(e));
        this.instructions.forEach(e => this.DOM.appendChild(e.DOM));

        this.update();
    }

    static update(address = 0x400000) {
        if (this.highlighted) this.highlighted.style.backgroundColor = null;
        this.highlighted = this.instructions[(address - 0x400000) / 4].DOM;
        this.highlighted.style.backgroundColor = 'yellow';
        this.highlighted.scrollIntoView(false);
    }

}

class Instruction {
    constructor(instruction) {
        this.instruction = instruction;
        this.DOM = document.createElement("pre");
        this.DOM.innerText = instruction;
        this.id = "mem" + Number.parseInt(instruction.substr(1, 10), 16).toString(16);
        this.DOM.id = this.id;
    }
}