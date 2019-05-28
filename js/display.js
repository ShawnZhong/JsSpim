class Display {
    static init() {
        RegisterUtils.init();
        MemoryUtils.init();
        InstructionUtils.init();
        Display.update(false, true);
    }

    static reset() {
        InstructionUtils.removeAllBreakpoints();
        MemoryUtils.init();
        Display.update(true, true);
    }

    static update(compareDiff = true, forceUpdate = false) {
        MemoryUtils.update();

        if (forceUpdate || Spim.isUserDataChanged())
            Elements.data.innerHTML = Spim.getUserData(compareDiff);

        RegisterUtils.update();
        InstructionUtils.highlightCurrentInstruction()
    }
}