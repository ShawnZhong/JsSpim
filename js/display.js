class Display {
    static init() {
        InstructionUtils.showInstructions();
        Display.update(false, true);
    }

    static reset() {
        InstructionUtils.removeAllBreakpoints();
        Display.update(true, true);
    }

    static update(compareDiff = true, forceUpdate = false) {
        Elements.stack.innerHTML = Spim.getUserStack(compareDiff);

        if (forceUpdate || Spim.isUserDataChanged())
            Elements.data.innerHTML = Spim.getUserData(compareDiff);

        Elements.generalReg.innerHTML = Spim.getGeneralReg(compareDiff);
        Elements.specialReg.innerHTML = Spim.getSpecialReg(compareDiff);

        InstructionUtils.highlightCurrentInstruction()
    }
}