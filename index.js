const outputDOM = document.getElementById('output-content');
const regsDOM = document.getElementById('regs-content');
const memoryDOM = document.getElementById('memory-content');
const stepDOM = document.getElementById('step');
const runDOM = document.getElementById('run');

var Module = {
    preRun: [],
    postRun: [initSpim, main],
    print,
    printErr,
    totalDependencies: 0,
    monitorRunDependencies: function (left) {
        this.totalDependencies = Math.max(this.totalDependencies, left);
    },
};

let Spim;

function initSpim() {
    Spim = {
        get_user_text: cwrap('get_user_text', 'string'),
        get_kernel_text: cwrap('get_kernel_text', 'string'),
        get_user_stack: cwrap('get_user_stack', 'string'),
        get_all_regs: cwrap('get_all_regs', 'string'),
        get_reg: cwrap('get_reg', 'number', ['number']),
        run: cwrap('run', 'void'),
        step: cwrap('step', 'void'),
        init: cwrap('init', 'void', ['string']),
    }
}


async function main(fileInput = 'https://raw.githubusercontent.com/ShawnZhong/JsSpim/dev/Tests/fib.s') {
    let data = await loadData(fileInput);

    const stream = FS.open('input.s', 'w+');
    FS.write(stream, new Uint8Array(data), 0, data.byteLength, 0);
    FS.close(stream);

    Spim.init("input.s");

    // memoryDOM.innerText = Spim.get_user_text();
    regsDOM.innerText = Spim.get_all_regs();

    runDOM.onclick = () => Spim.run();
    stepDOM.onclick = () => Spim.step();
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