class RegisterUtils {
    static init() {
        this.radix = 16;

        const generalRegNames = [
            "r0", "at", "v0", "v1", "a0", "a1", "a2", "a3",
            "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7",
            "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7",
            "t8", "t9", "k0", "k1", "gp", "sp", "s8", "ra"]
            .map((name, index) => `R${index} (${name})`);
        const specialRegNames = ["PC", "EPC", "Cause", "BadVAddr", "Status", "HI", "LO"];
        const specialFloatRegNames = ["FIR", "FCSR", "FCCR", "FEXR", "FENR"];
        const floatRegNames = Array(32).fill(0).map((_, i) => `FG${i}`);
        const doubleRegNames = Array(16).fill(0).map((_, i) => `FP${i}`);

        this.specialRegVals = Module.getSpecialRegVals();
        this.generalRegVals = Module.getGeneralRegVals();
        this.floatRegVals = Module.getFloatRegVals();
        this.doubleRegVals = Module.getDoubleRegVals();

        this.generalRegs = generalRegNames.map(name => new Register(name));
        this.specialIntRegs = specialRegNames.map(name => new Register(name));
        this.specialFloatRegs = specialFloatRegNames.map(name => new Register(name));
        this.floatRegs = floatRegNames.map(name => new FloatRegister(name));
        this.doubleRegs = doubleRegNames.map(name => new FloatRegister(name));

        this.initElement();
        this.update();
    }

    static initElement() {
        Elements.generalReg.innerHTML = "";
        Elements.specialIntReg.innerHTML = "";
        Elements.specialFloatReg.innerHTML = "";
        Elements.floatReg.innerHTML = "";
        Elements.doubleReg.innerHTML = "";

        this.generalRegs.forEach(e => Elements.generalReg.appendChild(e.element));
        this.specialIntRegs.forEach(e => Elements.specialIntReg.appendChild(e.element));
        this.specialFloatRegs.forEach(e => Elements.specialFloatReg.appendChild(e.element));
        this.floatRegs.forEach(e => Elements.floatReg.appendChild(e.element));
        this.doubleRegs.forEach(e => Elements.doubleReg.appendChild(e.element));
    }

    static update() {
        // values in special registers needs to be refreshed
        this.specialRegVals = Module.getSpecialRegVals();
        this.specialIntRegs.forEach((reg, i) => reg.updateValue(this.specialRegVals[i]));
        this.specialFloatRegs.forEach((reg, i) => reg.updateValue(this.specialRegVals[i + 7]));


        this.generalRegs.forEach((reg, i) => reg.updateValue(this.generalRegVals[i]));
        this.floatRegs.forEach((reg, i) => reg.updateValue(this.floatRegVals[i]));
        this.doubleRegs.forEach((reg, i) => reg.updateValue(this.doubleRegVals[i]));
    }

    static changeRadix(radix) {
        this.radix = Number.parseInt(radix);
        this.generalRegs.forEach(e => e.valueElement.innerText = e.formatValue());
        this.specialIntRegs.forEach(e => e.valueElement.innerText = e.formatValue());
        this.specialFloatRegs.forEach(e => e.valueElement.innerText = e.formatValue());
    }

    static getSP() {
        return this.generalRegVals[29];
    }

    static getPC() {
        return this.specialRegVals[0];
    }
}

class Register {
    constructor(name) {
        this.name = name.padEnd(8);
        this.value = undefined;

        // init element
        this.element = document.createElement("div");

        const nameElement = document.createElement('span');
        nameElement.classList.add('hljs-string');
        nameElement.innerText = this.name;
        this.element.appendChild(nameElement);

        this.element.appendChild(document.createTextNode(' = '));

        this.valueElement = document.createElement('span');
        this.valueElement.classList.add("hljs-number");
        this.element.appendChild(this.valueElement);
    }

    updateValue(newValue) {
        if (this.value === newValue) {
            this.valueElement.classList.remove('highlight');
            return;
        }

        if (this.value !== undefined)
            this.valueElement.classList.add('highlight');

        this.value = newValue;
        this.valueElement.innerText = this.formatValue();
    }

    formatValue() {
        switch (RegisterUtils.radix) {
            case 2:
                const str = this.value.toString(RegisterUtils.radix).padStart(32, '0');
                return `\n${str.substr(0, 8)} ${str.substr(8, 8)}\n${str.substr(16, 8)} ${str.substr(24, 8)}`;
            case 16:
                return this.value.toString(RegisterUtils.radix).padStart(8, '0');
            default:
                return this.value.toString(RegisterUtils.radix);
        }
    }
}

class FloatRegister extends Register {
    formatValue() {
        return this.value.toPrecision(6);
    }
}