const fileList = ['tt.core.s', 'fib.s', 'read.s', 'data_seg.s'];
fileList.forEach(filename => {
    const option = document.createElement("option");
    option.text = filename;
    option.value = `Tests/${filename}`;
    Elements.fileSelector.add(option);
});

let Spim;

var Module = {
    postRun: [initSpim, main],
    print: (text) => {
        Elements.output.innerHTML += text + "\n";
        Elements.output.scrollTop = Elements.output.scrollHeight;
    },
    printErr: (text) => {
        Elements.log.innerHTML += text + "\n";
        Elements.log.scrollTop = Elements.output.scrollHeight;
    }
};


let stack1, stack2, stack3;
function initSpim() {
    Spim = {
        init: cwrap('init'),
        step: cwrap('step', 'number', ['number', 'boolean']),
        getUserText: cwrap('getUserText', 'string', ['boolean']),
        getKernelText: cwrap('getKernelText', 'string'),
        getUserData: Module.getUserData,
        getSpecialRegVals: Module.getSpecialRegVals,
        getGeneralRegVals: Module.getGeneralRegVals,
        getFloatRegVals: Module.getFloatRegVals,
        getDoubleRegVals: Module.getDoubleRegVals,
        getStack: Module.getStack,
        addBreakpoint: Module.addBreakpoint,
        deleteBreakpoint: Module.deleteBreakpoint,
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
        return new Promise((resolve) => {
            reader.onload = () => resolve(reader.result);
            reader.readAsArrayBuffer(fileInput);
        });
    } else { // remote file
        const response = await fetch(fileInput);
        return response.arrayBuffer();
    }
}