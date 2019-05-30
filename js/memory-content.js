class MemoryLine {
    constructor(startAddress, parent) {
        this.wordList = [];
        for (let address = startAddress; address < startAddress + 0x10; address += 4)
            this.wordList.push(new MemoryWord(address, parent));

        this.element = document.createElement('span');
        this.element.innerHTML = `[<span class='hljs-attr'>${startAddress.toString(16)}</span>] `;

        this.wordList.forEach(e => {
            this.element.appendChild(e.valueElement);
            this.element.appendChild(document.createTextNode(' '));
        });
        this.wordList.forEach(e => this.element.appendChild(e.stringElement));
        this.element.appendChild(document.createTextNode('\n'));
    }

    updateValues() {
        this.wordList.forEach(e => e.updateValue());
    }
}

class MemoryWord {
    constructor(address, parent) {
        this.address = address;
        this.parent = parent;
        this.value = this.parent.getContent(this.address);

        this.valueElement = document.createElement('span');
        this.valueElement.classList.add('data-number');
        this.stringElement = document.createElement('span');

        this.valueElement.innerText = this.getValueInnerText();
        this.stringElement.innerText = this.getStringInnerText();
    }

    updateValue() {
        const newValue = this.parent.getContent(this.address);

        if (newValue === undefined) {
            this.valueElement.classList.add('unused');
            this.stringElement.classList.add('unused');
            return;
        }

        if (this.value === newValue) {
            this.valueElement.classList.remove('highlight', 'unused');
            this.stringElement.classList.remove('highlight', 'unused');
            return;
        }

        if (this.value !== undefined) {
            this.valueElement.classList.add('highlight');
            this.stringElement.classList.add('highlight');
        }


        this.value = newValue;
        this.valueElement.innerText = this.getValueInnerText();
        this.stringElement.innerText = this.getStringInnerText();
    }

    getValueInnerText() {
        if (this.parent.radix === 10) {
            const string = this.value === undefined ? '' : this.value.toString();
            return string.padStart(10, ' ');
        } else {
            if (this.value === undefined) return ''.padStart(8);
            return this.value.toString(16).padStart(8, '0');
        }
    }

    getStringInnerText() {
        if (this.value === undefined)
            return ''.padStart(4);

        const asciiArray = [
            this.value & 0xff,
            (this.value & 0xffff) >> 8,
            (this.value & 0xffffff) >> 16,
            this.value >> 24
        ];
        return asciiArray
            .map(e => e >= 32 && e < 127 ? e : 183)
            .map(e => String.fromCharCode(e)).join('');
    }
}