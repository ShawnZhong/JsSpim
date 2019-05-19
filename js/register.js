class RegisterUtils {
    static init() {
        this.generalRegDOM = document.getElementById('general-regs');
        this.specialRegDOM = document.getElementById('special-regs');

        this.getGeneralRegVals = cwrap('getGeneralRegVals', 'string');
        this.getSpecialRegVals = cwrap('getSpecialRegVals', 'string');
        this.getPC = cwrap('getPC', 'number');


        this.update();
    }

    static update() {
        this.generalRegDOM.innerHTML = this.getGeneralRegVals();
        this.specialRegDOM.innerHTML = this.getSpecialRegVals();
    }
}