class Display {
    static init() {
        RegisterUtils.init();
        Stack.init();
        InstructionUtils.init();
        Display.update(false, true);
    }

    static reset() {
        InstructionUtils.removeAllBreakpoints();
        Stack.init();
        Display.update(true, true);
    }

    static update(compareDiff = true, forceUpdate = false) {
        Stack.update();

        if (forceUpdate || Spim.isUserDataChanged())
            Elements.data.innerHTML = Spim.getUserData(compareDiff);

        RegisterUtils.update();
        InstructionUtils.highlightCurrentInstruction()
    }
}