document.getElementById('file-choice1').click();

const outputDOM = document.getElementById('output-content');
const regsDOM = document.getElementById('regs-content');
const memoryDOM = document.getElementById('memory-content');
const stepDOM = document.getElementById('step');
const runDOM = document.getElementById('run');

var Module = {
    preRun: [],
    postRun: [() => ready = true, main],
    print,
    printErr,
    totalDependencies: 0,
    monitorRunDependencies: function (left) {
        this.totalDependencies = Math.max(this.totalDependencies, left);
    },
};

let ready;
let data;

async function loadFile(fileInput) {
    if (fileInput instanceof File) { // local file
        const reader = new FileReader();
        reader.onload = () => data = reader.result;
        reader.readAsArrayBuffer(fileInput);
    } else { // remote file
        const response = await fetch(fileInput);
        data = await response.arrayBuffer();
    }

    main();
}

function main() {
    if (!data || !ready) return;


    const stream = FS.open('input.s', 'w+');
    FS.write(stream, new Uint8Array(data), 0, data.byteLength, 0);
    FS.close(stream);

    const get_user_text = cwrap('get_user_text', 'string');
    const get_kernel_text = cwrap('get_kernel_text', 'string');
    const get_user_stack = cwrap('get_user_stack', 'string');
    const get_all_regs = cwrap('get_all_regs', 'string');
    const get_reg = cwrap('get_reg', 'number', ['number']);
    const init = cwrap('init', 'void', ['string']);
    const run = cwrap('run', 'void');
    const step = cwrap('step', 'void');

    init("input.s");

    regsDOM.innerText = get_all_regs();
    memoryDOM.innerText = get_user_text();

    runDOM.onclick = () => run();
    stepDOM.onclick = () => step();
}


function print(text) {
    console.log(text);
    outputDOM.innerHTML += text + "\n";
    outputDOM.scrollTop = outputDOM.scrollHeight; // focus on bottom
}

function printErr(text) {
    console.error(text);
}