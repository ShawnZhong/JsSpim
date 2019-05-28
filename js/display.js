class Display {
    static init() {
        RegisterUtils.init();
        Stack.init();
        InstructionUtils.init();
        DataSegment.init();
        Display.update();
    }

    static reset() {
        InstructionUtils.removeAllBreakpoints();
        Stack.init();
        DataSegment.init();
        Display.update();
    }

    static update() {
        Stack.update();
        DataSegment.update();
        RegisterUtils.update();
        InstructionUtils.highlightCurrentInstruction()
    }
}