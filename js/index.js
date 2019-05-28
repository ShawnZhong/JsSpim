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

function initSpim() {
    Spim = {
        init: cwrap('init'),
        step: cwrap('step', 'number', ['number', 'boolean']),

        isUserDataChanged: cwrap('isUserDataChanged', 'boolean'),

        getPC: Module.getPC,
        getSpecialRegVals: Module.getSpecialRegVals,

        generalRegVals: Module.getGeneralRegVals(),
        floatRegVals: Module.getFloatRegVals(),
        doubleRegVals: Module.getDoubleRegVals(),

        getStack: Module.getStack,

        getUserData: cwrap('getUserData', 'string', ['boolean']),
        getUserText: cwrap('getUserText', 'string', ['boolean']),
        getKernelData: cwrap('getKernelData', 'string'),
        getKernelText: cwrap('getKernelText', 'string'),
        getUserStack: cwrap('getUserStack', 'string', ['boolean']),
        addBreakpoint: cwrap('addBreakpoint', null, ['number']),
        deleteBreakpoint: cwrap('deleteBreakpoint', null, ['number']),
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