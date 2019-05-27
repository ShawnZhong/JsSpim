class RegisterUtils {
    static init() {
        const generalRegNames = [
            "r0", "at", "v0", "v1", "a0", "a1", "a2", "a3",
            "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7",
            "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7",
            "t8", "t9", "k0", "k1", "gp", "sp", "s8", "ra"]
            .map((name, index) => `R${index} (${name})`);
        const specialRegNames = [
            "PC", "EPC", "Cause", "BadVAddr", "Status", "HI", "LO",
            "FIR", "FCSR", "FCCR", "FEXR", "FENR"];
        const floatRegNames = Array(32).fill(0).map((_, i) => `FG${i}`);
        const doubleRegNames = Array(16).fill(0).map((_, i) => `FP${i}`);

        this.generalRegVals = Spim.getGeneralRegVals();
        this.specialRegVals = Spim.getSpecialRegVals();
        this.floatRegVals = Spim.getFloatRegVals();
        this.doubleRegVals = Spim.getDoubleRegVals();

        this.generalRegs = generalRegNames.map(name => new Register(name));
        this.specialRegs = specialRegNames.map(name => new Register(name));
        this.floatRegs = floatRegNames.map(name => new FloatRegister(name));
        this.doubleRegs = doubleRegNames.map(name => new FloatRegister(name));

        this.initElement();
        this.update();
    }

    static initElement() {
        Elements.generalReg.innerHTML = "";
        Elements.specialReg.innerHTML = "";
        Elements.floatReg.innerHTML = "";
        Elements.doubleReg.innerHTML = "";

        this.generalRegs.forEach(e => Elements.generalReg.appendChild(e.element));
        this.specialRegs.forEach(e => Elements.specialReg.appendChild(e.element));
        this.floatRegs.forEach(e => Elements.floatReg.appendChild(e.element));
        this.doubleRegs.forEach(e => Elements.doubleReg.appendChild(e.element));
    }

    static update() {
        this.specialRegVals = Spim.getSpecialRegVals();
        this.generalRegs.forEach((reg, i) => reg.updateValue(this.generalRegVals[i]));
        this.specialRegs.forEach((reg, i) => reg.updateValue(this.specialRegVals[i]));
        this.floatRegs.forEach((reg, i) => reg.updateValue(this.floatRegVals[i]));
        this.doubleRegs.forEach((reg, i) => reg.updateValue(this.doubleRegVals[i]));
    }
}

class Register {
    constructor(name, radix = 16) {
        this.name = name.padEnd(8);
        this.value = undefined;
        this.radix = radix;
        this.highlighted = false;

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
            if (this.highlighted) this.toggleHighlight();
            return;
        }

        this.value = newValue;
        this.valueElement.innerText = this.formatValue();
        this.toggleHighlight();
    }

    toggleHighlight() {
        if (this.highlighted)
            this.valueElement.style.backgroundColor = null;
        else
            this.valueElement.style.backgroundColor = 'yellow';
        this.highlighted = !this.highlighted;
    }

    formatValue() {
        return this.value.toString(this.radix).padStart(8, '0');
    }
}

class FloatRegister extends Register {
    formatValue() {
        return this.value.toPrecision(6);
    }
}