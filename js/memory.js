class MemoryUtils {
    static init() {
        Elements.stack.innerHTML = '';
        this.stack = Spim.getStack();
        this.memoryLines = [];
        this.addNewLines(0x80000000);
        this.update();
    }

    static addNewLines(endAddress) {
        for (; endAddress >= Spim.generalRegVals[29]; endAddress -= 0x10) {
            const newLine = new MemoryLine(endAddress);
            Elements.stack.prepend(newLine.element);
            this.memoryLines.push(newLine);
        }
        this.minLineAddress = Spim.generalRegVals[29] & 0xfffffff0;
    }

    static update() {
        if (Spim.generalRegVals[29] < this.minLineAddress)
            this.addNewLines(this.minLineAddress);
        this.memoryLines.forEach(e => e.updateValues());
    }

    static getStackContent(address) {
        if (Spim.generalRegVals[29] > address) return undefined;
        const index = this.stack.length - (0x80000000 - address) / 4;
        return this.stack[index];
    }
}

class MemoryLine {
    constructor(endAddress) {
        const startAddress = endAddress - 0x10;

        this.wordList = [];
        for (let address = startAddress; address < endAddress; address += 4)
            this.wordList.push(new MemoryWord(address));

        this.element = document.createElement('div');
        this.element.innerHTML = `[<span class='hljs-attr'>${startAddress.toString(16)}</span>] `;

        this.wordList.forEach(e => this.element.appendChild(e.valueElement));
        this.wordList.forEach(e => this.element.appendChild(e.stringElement));
    }

    updateValues() {
        this.wordList.forEach(e => e.updateValue());
    }
}

class MemoryWord {
    constructor(address) {
        this.address = address;

        this.valueElement = document.createElement('span');
        this.valueElement.classList.add('data-number');
        this.stringElement = document.createElement('span');

        this.valueElement.innerText = this.getValueInnerText();
        this.stringElement.innerText = this.getStringInnerText();
    }

    updateValue() {
        const newValue = MemoryUtils.getStackContent(this.address);

        if (this.value === newValue) {
            this.valueElement.classList.remove('highlight');
            this.stringElement.classList.remove('highlight');
            return;
        }

        this.value = newValue;

        this.valueElement.classList.add('highlight');
        this.stringElement.classList.add('highlight');

        this.valueElement.innerText = this.getValueInnerText();
        this.stringElement.innerText = this.getStringInnerText();
    }

    getValueInnerText() {
        if (this.value === undefined)
            return "        ";

        return this.value.toString(16).padStart(8, '0');
    }

    getStringInnerText() {
        if (this.value === undefined)
            return "    ";

        const asciiArray = [
            this.value & 0xff,
            (this.value & 0xffff) >> 8,
            (this.value & 0xffffff) >> 16,
            this.value >> 24
        ];
        return asciiArray
            .map(e => e >= 32 && e < 127 ? e : -3)
            .map(e => String.fromCharCode(e)).join('');
    }
}