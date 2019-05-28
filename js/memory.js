class Data {
    static init() {
    }
}

class Stack {
    static init() {
        Elements.stack.innerHTML = '';
        this.stack = Spim.getStack();
        this.lines = [];
        this.addNewLines(0x80000000);
        this.update();
    }

    static addNewLines(endAddress) {
        for (; endAddress >= RegisterUtils.getSP(); endAddress -= 0x10) {
            const newLine = new MemoryLine(endAddress);
            Elements.stack.prepend(newLine.element);
            this.lines.push(newLine);
        }
        this.minLineAddress = RegisterUtils.getSP() & 0xfffffff0;
    }

    static update() {
        if (RegisterUtils.getSP() < this.minLineAddress)
            this.addNewLines(this.minLineAddress);
        this.lines.forEach(e => e.updateValues());
    }

    static getContent(address) {
        if (RegisterUtils.getSP() > address) return undefined;
        const index = this.stack.length - (0x80000000 - address) / 4;
        return this.stack[index];
    }

    static changeRadix(radixStr) {
        const radix = Number.parseInt(radixStr);
        for (const line of this.lines) {
            for (const word of line.wordList) {
                word.radix = radix;
                word.valueElement.innerText = word.getValueInnerText()
            }
        }
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
        this.radix = 16;

        this.valueElement = document.createElement('span');
        this.valueElement.classList.add('data-number');
        this.stringElement = document.createElement('span');

        this.valueElement.innerText = this.getValueInnerText();
        this.stringElement.innerText = this.getStringInnerText();
    }

    updateValue() {
        const newValue = Stack.getContent(this.address);

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
        if (this.radix === 10) {
            const string = this.value === undefined ? '' : this.value.toString();
            return string.padStart(10, ' ');
        } else {
            if (this.value === undefined) return ''.padStart(8);
            return this.value.toString(16).padStart(8, '0');
        }
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