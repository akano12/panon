.pragma library

// Absolute path of the package's contents directory.
const contentsRoot = decodeURIComponent(Qt.resolvedUrl("..").toString().replace(/^file:\/\//, '').replace(/\/$/, ''))

// Absolute path of a file inside the package's contents directory.
function packagePath(relativePath) {
    return contentsRoot + '/' + relativePath
}

// Where the python modules live.
const scriptsRoot = packagePath("scripts")

function shellQuote(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'"
}

// Returns a shell command running the python module inside contents/scripts.
function pythonCommand(module, args) {
    return 'cd ' + shellQuote(scriptsRoot) + ' && exec python3 -m ' + module
        + (args || []).map(arg => ' ' + shellQuote(arg)).join('')
}

function random(seed) {
    var x = Math.sin(seed*1000) * 10000;
    return x - Math.floor(x);
}
