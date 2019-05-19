const memoryDOM = document.getElementById('text-content');
const dataDOM = document.getElementById('data-content');
const stackDOM = document.getElementById('stack-content');


class MemoryUtils {
    static init() {
        memoryDOM.innerHTML = '';

        this.instructions = Spim.getUserText().split("\n").map(this.getInstructionDOM);
        this.instructions.forEach(e => memoryDOM.appendChild(e));

        this.update();
    }


    static update(address = 0x400000) {
        stackDOM.innerHTML = Spim.getUserStack();
        dataDOM.innerHTML = Spim.getUserData();
        this.highlight(address);
    }

    static highlight(address) {
        if (this.highlighted) this.highlighted.style.backgroundColor = null;
        this.highlighted = this.instructions[(address - 0x400000) / 4];
        if (!this.highlighted) return;
        this.highlighted.style.backgroundColor = 'yellow';
        this.highlighted.scrollIntoView(false);
    }

    static getInstructionDOM(instruction) {
        const node = document.createElement("pre");
        node.innerText = instruction.substring(0, 13) + instruction.substring(24);
        node.onclick = () => {
            const address = parseInt(node.innerText.substr(1, 10));
            console.log(address);
        };
        return node;
    }
}