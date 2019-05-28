const fileList = [
    'fibonacci.s',
    'test_core.s',
    'test_le.s',
    'test_sys_call.s',
    'hello_world.s',
    'read_string.s',
    'timing.s',
    'timer_interrupt.s'
];
fileList.forEach(filename => {
    const option = document.createElement("option");
    option.text = filename;
    option.value = `Tests/${filename}`;
    Elements.fileSelector.add(option);
});

var Module = {
    postRun: [main],
    print: (text) => {
        Elements.output.innerHTML += text + "\n";
        Elements.output.scrollTop = Elements.output.scrollHeight;
    },
    printErr: (text) => {
        Elements.log.innerHTML += text + "\n";
        Elements.log.scrollTop = Elements.output.scrollHeight;
    }
};

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