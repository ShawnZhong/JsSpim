var Module = {
    onRuntimeInitialized: main,
    print: (text) => {
        outputDOM.innerHTML += text + "\n";
        outputDOM.scrollTop = outputDOM.scrollHeight;
    },
    printErr: (text) => {
        logDOM.innerHTML += text + "\n";
        logDOM.scrollTop = outputDOM.scrollHeight;
    },
    totalDependencies: 0,
    monitorRunDependencies: function (left) {
        this.totalDependencies = Math.max(this.totalDependencies, left);
    },
};


async function main(fileInput = 'https://raw.githubusercontent.com/ShawnZhong/JsSpim/dev/Tests/fib.s') {
    let data = await loadData(fileInput);

    const stream = FS.open('input.s', 'w+');
    FS.write(stream, new Uint8Array(data), 0, data.byteLength, 0);
    FS.close(stream);

    Module.init("input.s");

    outputDOM.innerHTML = "";
    RegisterUtils.init();
    MemoryUtils.init();
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