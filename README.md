# JsSpim
[JsSpim](https://shawnzhong.github.io/JsSpim/) is an online MIPS32 simulator based on Prof. James Larus's [Spim](http://spimsimulator.sourceforge.net/).

> *Spim* is a self-contained simulator that runs MIPS32 programs. It reads and executes assembly language programs written for this processor. *Spim* also provides a simple debugger and minimal set of operating system services. *Spim* does not execute binary (compiled) programs.
>
> *Spim* implements almost the entire MIPS32 assembler-extended instruction set. (It omits most floating point comparisons and rounding modes and the memory system page tables.) The MIPS architecture has several variants that differ in various ways (e.g., the MIPS64 architecture supports 64-bit integers and addresses), which means that *Spim* will not run programs for all MIPS processors.

The source code is published at [GitHub](https://github.com/ShawnZhong/JsSpim/)

## Screenshot

![image-20190530030929768](screenshot.png)

## Screen Record

<img src="screenrecord.gif" width="100%">

## Features

- Click on an instruction to toggle **breakpoint**
- Use the range slider to **control the execution speed**
- **Highlight** on changed registers, data segment, and stack
- **Radix** support for all values

## Built With

- [Spim](http://spimsimulator.sourceforge.net/) - The original simulator written in C++
- [Emscripten](https://emscripten.org/) - Toolchain to compile C++ source code to WebAssembly using the LLVM IR.
- [Bootstrap](https://getbootstrap.com/)  - Using the CSS library to build the UI
- [highlight.js](https://highlightjs.org/) - For highlighting the source code

