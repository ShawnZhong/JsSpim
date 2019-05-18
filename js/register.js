class RegisterUtils {
    static init() {
        const generalRegDOM = document.getElementById('general-regs');
        const specialRegDOM = document.getElementById('special-regs');

        generalRegDOM.innerHTML = "";
        specialRegDOM.innerHTML = "";

        const generalRegNames = ["r0", "at", "v0", "v1", "a0", "a1", "a2", "a3", "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "t8", "t9", "k0", "k1", "gp", "sp", "s8", "ra"];
        const specialRegNames = ["PC", "EPC", "Cause", "BadVAddr", "Status", "HI", "LO", "FIR", "FCSR", "FCCR", "FEXR", "FENR"];

        const generalRegVals = Module.getGeneralRegVals();
        const specialRegVals = Module.getSpecialRegVals();


        this.generalRegs = generalRegNames.map((name, i) => new Register(name, generalRegVals[i]));
        this.specialRegs = specialRegNames.map((name, i) => new Register(name, specialRegVals[i]));

        this.generalRegs.forEach(e => generalRegDOM.appendChild(e.DOM));
        this.specialRegs.forEach(e => specialRegDOM.appendChild(e.DOM));
    }

    static update() {
        const generalRegVals = Module.getGeneralRegVals();
        const specialRegVals = Module.getSpecialRegVals();

        this.generalRegs.forEach((reg, i) => reg.updateValue(generalRegVals[i]));
        this.specialRegs.forEach((reg, i) => reg.updateValue(specialRegVals[i]));
    }

    static getPC() {
        return this.specialRegs[0].value;
    }
}

class Register {
    constructor(name, value) {
        this.name = name;
        this.value = value;
        this.highlighted = false;
        this.DOM = document.createElement("pre");
        this.DOM.innerText = `${this.name}: ${this.value.toString(16)}`;
    }

    updateValue(newValue) {
        if (this.value === newValue) {
            if (this.highlighted) this.DOM.style.backgroundColor = null;
            return;
        }

        this.value = newValue;
        this.DOM.innerText = `${this.name}: ${this.value.toString(16)}`;
        this.DOM.style.backgroundColor = 'yellow';
        this.highlighted = true;
    }
}