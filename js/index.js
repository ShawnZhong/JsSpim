const outputDOM = document.getElementById('output-content');
const logDOM = document.getElementById('log-content');
const fileSelector = document.getElementById('file-selector');

const fileList = ['tt.core.s', 'fib.s', 'helloworld.s', 'change_data_seg.s'];
fileList.forEach(filename => {
    const option = document.createElement("option");
    option.text = filename;
    option.value = `Tests/${filename}`;
    fileSelector.add(option);
});

let Spim;

var Module = {
    postRun: [init, main],
    print: (text) => {
        outputDOM.innerHTML += text + "\n";
        outputDOM.scrollTop = outputDOM.scrollHeight;
    },
    printErr: (text) => {
        logDOM.innerHTML += text + "\n";
        logDOM.scrollTop = outputDOM.scrollHeight;
    }
};

function init() {
    Spim = {
        init: cwrap('init'),
        run: cwrap('run'),
        step: cwrap('step', 'bool'),
        getUserData: cwrap('getUserData', 'string'),
        getUserText: cwrap('getUserText', 'string'),
        getKernelText: cwrap('getKernelText', 'string'),
        getKernelData: cwrap('getKernelData', 'string'),
        getUserStack: cwrap('getUserStack', 'string'),
        addBreakpoint: cwrap('addBreakpoint', null, 'number'),
        deleteBreakpoint: cwrap('deleteBreakpoint', null, 'number'),
        getPC: cwrap('getPC', 'number'),
        getGeneralRegVals: cwrap('getGeneralRegVals', 'string'),
        getSpecialRegVals: cwrap('getSpecialRegVals', 'string'),
    };
}

async function main(fileInput = `Tests/${fileList[0]}`) {
    let data = await loadData(fileInput);

    const stream = FS.open('input.s', 'w+');
    FS.write(stream, new Uint8Array(data), 0, data.byteLength, 0);
    FS.close(stream);

    Execution.init();
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