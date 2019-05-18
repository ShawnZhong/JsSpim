const outputDOM = document.getElementById('output-content');
const regsDOM = document.getElementById('regs-content');
const memoryDOM = document.getElementById('memory-content');
const stepDOM = document.getElementById('step');
const runDOM = document.getElementById('run');

var Module = {
    onRuntimeInitialized,
    print,
    printErr,
    totalDependencies: 0,
    monitorRunDependencies: function (left) {
        this.totalDependencies = Math.max(this.totalDependencies, left);
    },
};

const regularRegNames =
    ["r0", "at", "v0", "v1", "a0", "a1", "a2", "a3",
        "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7",
        "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7",
        "t8", "t9", "k0", "k1", "gp", "sp", "s8", "ra"];

const specialRegNames = ["PC", "EPC", "Cause", "BadVAddr", "Status", "HI", "LO",
    "FIR", "FCSR", "FCCR", "FEXR", "FENR"];


async function onRuntimeInitialized(fileInput = 'https://raw.githubusercontent.com/ShawnZhong/JsSpim/dev/Tests/tt.core.s') {
    let data = await loadData(fileInput);

    const stream = FS.open('input.s', 'w+');
    FS.write(stream, new Uint8Array(data), 0, data.byteLength, 0);
    FS.close(stream);

    Module.init("input.s");

    console.log(Module.getGeneralRegs());
    console.log(Module.getFloatRegs());
    console.log(Module.getDoubleRegs());
    console.log(Module.getSpecialRegs());
    
    runDOM.onclick = () => Module.run();
    stepDOM.onclick = () => Module.step();
}

async function loadData(fileInput) {
    if (fileInput instanceof File) { // local file
        const reader = new FileReader();
        return await new Promise((resolve) => {
            reader.onload = () => resolve(reader.result);
            reader.readAsArrayBuffer(fileInput);
        });
    } else { // remote file
        const response = await fetch(fileInput);
        return await response.arrayBuffer();
    }
}


function print(text) {
    console.log(text);
    outputDOM.innerHTML += text + "\n";
    outputDOM.scrollTop = outputDOM.scrollHeight; // focus on bottom
}

function printErr(text) {
    console.error(text);
}