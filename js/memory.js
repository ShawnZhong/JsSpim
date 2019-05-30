class Memory {
    static changeRadix(radixStr) {
        this.radix = Number.parseInt(radixStr);
        for (const line of this.lines) {
            for (const word of line.wordList) {
                word.radix = this.radix;
                word.valueElement.innerText = word.getValueInnerText()
            }
        }
    }
}

class DataSegment extends Memory {
    static init() {
        Elements.userData.innerHTML = '';
        Elements.kernelData.innerHTML = '';

        this.radix = 16;

        // user data
        this.userData = Module.getUserData();
        this.userLines = [];
        for (let i = 0; i < DataSegment.userData.length / 16; i++) {
            const addr = 0x10000000 + i * 0x10;
            if (this.isUserLineEmpty(addr)) continue;
            const newLine = new UserDataMemoryLine(addr);
            newLine.updateValues();
            Elements.userData.append(newLine.element);
            this.userLines.push(newLine);
        }


        // kernel data
        this.kernelData = Module.getKernelData();
        this.kernelLines = [];
        for (let i = 0; i < DataSegment.kernelData.length / 16; i++) {
            const addr = 0x90000000 + i * 0x10;
            if (this.isKernelLineEmpty(addr)) continue;
            const newLine = new KernelDataMemoryLine(addr);
            newLine.updateValues();
            Elements.kernelData.append(newLine.element);
            this.kernelLines.push(newLine);
        }

        this.lines = [...this.userLines, ...this.kernelLines];
    }

    static update() {
        this.userData = Module.getUserData();
        this.userLines.forEach(e => e.updateValues());
    }

    static isKernelLineEmpty(addr) {
        for (let i = addr; i < addr + 0x10; i += 4)
            if (this.getKernelDataContent(i) !== 0) return false;
        return true;
    }

    static isUserLineEmpty(addr) {
        for (let i = addr; i < addr + 0x10; i += 4)
            if (this.getUserDataContent(i) !== 0) return false;
        return true;
    }

    static getUserDataContent(addr) {
        return DataSegment.userData[(addr - 0x10000000) >> 2];
    }

    static getKernelDataContent(addr) {
        return DataSegment.kernelData[(addr - 0x90000000) >> 2];
    }

    static toggleKernelData(shoeKernelData) {
        if (shoeKernelData)
            Elements.kernelDataContainer.style.display = null;
        else
            Elements.kernelDataContainer.style.display = 'none';
    }

}


class Stack extends Memory {
    static init() {
        Elements.stack.innerHTML = '';
        this.radix = 16;
        this.stack = Module.getStack();
        this.lines = [];
        this.addNewLines(0x80000000);
        this.update();
    }

    static addNewLines(endAddr) {
        for (; endAddr >= RegisterUtils.getSP(); endAddr -= 0x10) {
            const newLine = new StackMemoryLine(endAddr - 0x10);
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

    static getStackContent(addr) {
        if (RegisterUtils.getSP() > addr) return undefined;
        const index = Stack.stack.length - (0x80000000 - addr) / 4;
        return Stack.stack[index];
    }
}


class AbstractMemoryLine {
    constructor(startAddress) {
        this.wordList = [];
        for (let address = startAddress; address < startAddress + 0x10; address += 4)
            this.wordList.push(this.createMemoryWord(address));

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

    createMemoryWord(address) {
        return new AbstractMemoryWord(address);
    }
}

class UserDataMemoryLine extends AbstractMemoryLine {
    createMemoryWord(address) {
        return new UserDataMemoryWord(address);
    }
}

class KernelDataMemoryLine extends AbstractMemoryLine {
    createMemoryWord(address) {
        return new KernelDataMemoryWord(address);
    }
}

class StackMemoryLine extends AbstractMemoryLine {
    createMemoryWord(address) {
        return new StackMemoryWord(address);
    }
}

class AbstractMemoryWord {
    constructor(address) {
        this.address = address;
        this.radix = this.getRadix();

        this.valueElement = document.createElement('span');
        this.valueElement.classList.add('data-number');
        this.stringElement = document.createElement('span');

        this.valueElement.innerText = this.getValueInnerText();
        this.stringElement.innerText = this.getStringInnerText();
    }

    updateValue() {
        const newValue = this.getContent(this.address);

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
            .map(e => e >= 32 && e < 127 ? e : 183)
            .map(e => String.fromCharCode(e)).join('');
    }

    getContent(addr) {
        return 0;
    }

    getRadix() {
        return 16;
    }
}

class UserDataMemoryWord extends AbstractMemoryWord {
    getContent(addr) {
        return DataSegment.getUserDataContent(addr);
    }

    getRadix() {
        return DataSegment.radix;
    }
}

class KernelDataMemoryWord extends AbstractMemoryWord {
    getContent(addr) {
        return DataSegment.getKernelDataContent(addr);
    }

    getRadix() {
        return DataSegment.radix;
    }
}

class StackMemoryWord extends AbstractMemoryWord {
    getContent(addr) {
        return Stack.getStackContent(addr);
    }

    getRadix() {
        return Stack.radix;
    }
}