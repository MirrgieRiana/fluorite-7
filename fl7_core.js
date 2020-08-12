const fs = require("fs");
const path = require("path");
const child_process = require("child_process");
const parser = require(process.env.app_dir + "/fluorite-7.js");
const heapdump = require("heapdump");
let globalResult;
const cacheUse = new Map();
function parse(source, startRule, scriptFile) {
  const result = parser.parse(source, {
    startRule: startRule,
  });
  const constantIdsScript = [];
  const env = new result.fl7c.Environment();
  var objects = {};
  result.loadAliases(env, objects);
  const c = (key, value) => {
    var constantId = env.allocateConstantId();
    env.setAlias(key, new result.fl7c.FluoriteAliasConstant(constantId));
    env.setConstant(constantId, value);
    return constantId;
  };
  function loadStringUtf8(fd) {
    var buffers = [];
    var length = 0;
    while (true) {
      var buffer = new Buffer.alloc(4096);
      var bytesRead;
      while (true) {
        try {
          bytesRead = fs.readSync(fd, buffer, 0, 4096, null);
        } catch (e) {
          if (e.code === "EAGAIN") {
            continue;
          } else {
            throw e;
          }
        }
        break;
      }
      if (bytesRead === 0) break;
      buffers.push(buffer.subarray(0, bytesRead));
      length += bytesRead;
    }
    return Buffer.concat(buffers, length).toString('utf8', 0, length);
  }
  c("RESOLVE", new result.fl7.FluoriteFunction(args => {
    if (args.length < 1) throw new Error("Illegal Argument");
    var pathes = result.fl7.util.toStream(args[0]).toArray();
    return path.resolve.apply(null, pathes);
  }));
  c("IN", (function(){
    class FluoriteStreamerStdin extends result.fl7.FluoriteStreamer {
      constructor () {
        super();
      }
      start() { // TODO 徐々に読み込む
        const fd = process.stdin.fd;
        const input = loadStringUtf8(fd);
        //fs.closeSync(fd); // IN後にEXECするとエラーになる問題対策
        const inputs = input.split("\n");
        var i = 0;
        return {
          next: () => {
            if (i >= inputs.length) return undefined;
            if (i == inputs.length - 1) {
              if (inputs[i] === "") {
                i++;
                return undefined;
              }
            }
            var result = inputs[i];
            i++;
            return result;
          },
        };
      }
    }
    return new FluoriteStreamerStdin();
  })());
  c("READ", (function(){
    class FluoriteStreamerRead extends result.fl7.FluoriteStreamer {
      constructor (filename) {
        super();
        this._filename = filename;
      }
      start() { // TODO 徐々に読み込む
        const fd = fs.openSync(this._filename, "r");
        const input = loadStringUtf8(fd);
        fs.closeSync(fd);
        const inputs = input.split("\n");
        var i = 0;
        return {
          next: () => {
            if (i >= inputs.length) return undefined;
            if (i == inputs.length - 1) {
              if (inputs[i] === "") {
                i++;
                return undefined;
              }
            }
            var result = inputs[i];
            i++;
            return result;
          },
        };
      }
    }
    return new result.fl7.FluoriteFunction(args => {
      var filename = args[0];
      if (filename === undefined) throw new Error("Illegal argument");
      return new FluoriteStreamerRead(result.fl7.util.toString(filename));
    });
  })());
  c("WRITE", (function(){
    return new result.fl7.FluoriteFunction(args => {
      var filename = args[0];
      if (filename === undefined) throw new Error("Illegal argument");
      filename = result.fl7.util.toString(filename);
      var streamer = args[1];
      if (streamer === undefined) throw new Error("Illegal argument");
      streamer = result.fl7.util.toStream(streamer);
      const fd = fs.openSync(filename, "w");
      const stream = streamer.start();
      while (true) {
        const next = stream.next();
        if (next === undefined) break;
        fs.writeSync(fd, result.fl7.util.toString(next));
        fs.writeSync(fd, "\n");
      }
      fs.closeSync(fd);
      return null;
    });
  })());
  c("LS", new result.fl7.FluoriteFunction(args => {
    if (args.length != 1) throw new Error("Illegal argument");
    return result.fl7.util.toStreamFromArray(fs.readdirSync(result.fl7.util.toString(args[0])));
  }));
  c("EXEC", new result.fl7.FluoriteFunction(args => {

    let filename = args[0];
    if (filename === undefined) throw new Error("Illegal argument");
    filename = result.fl7.util.toString(filename);

    let argsExec = [];
    {

      let streamer = args[1];
      if (streamer === undefined) streamer = null;
      if (streamer === null) streamer = result.fl7.util.empty();
      streamer = result.fl7.util.toStream(streamer);

      const stream = streamer.start();
      while (true) {
        const next = stream.next();
        if (next === undefined) break;
        argsExec[argsExec.length] = result.fl7.util.toString(next);
      }
    }

    let stdin = args[2];
    if (stdin === undefined) stdin = null;
    if (stdin === null) stdin = "";
    stdin = result.fl7.util.toString(stdin);

    let env = process.env;
    {
      let extraEnv = args[3];
      if (extraEnv === undefined) extraEnv = null;
      if (extraEnv === null) {
      } else if (extraEnv instanceof result.fl7.FluoriteObject) {
        env = {
          ...env,
          ...extraEnv.map,
        };
      } else {
        throw new Error("Illegal argument");
      }
    }

    const stringOut = child_process.execFileSync(filename, argsExec, {
      input: stdin,
      encoding: "utf8",
      maxBuffer: 64 * 1024 * 1024,
      env: env,
    });
    const arrayOut = stringOut.split("\n");
    if (arrayOut[arrayOut.length - 1] === "") arrayOut.pop();
    return result.fl7.util.toStreamFromArray(arrayOut);
  }));
  c("EVAL", (function(){
    return new result.fl7.FluoriteFunction(args => {
      var source = args[0];
      if (source === undefined) throw new Error("Illegal argument");
      source = result.fl7.util.toString(source);
      const result2 = parse(source, "Root", path.resolve(scriptFile, "../<eval>"));
      const fl7 = globalResult.fl7;
      const util = globalResult.fl7.util;
      const constants = Array.from(globalResult.env.getConstants());
      for (let i = 0; i < globalResult.constantIdsScript.length; i++) {
        constants[globalResult.constantIdsScript[i]] = result2.env.getConstants()[globalResult.constantIdsScript[i]];
      }
      return eval(result2.code);
    });
  })());
  c("REQUIRE", (function(){
    return new result.fl7.FluoriteFunction(args => {
      var filename = args[0];
      if (filename === undefined) throw new Error("Illegal argument");
      filename = result.fl7.util.toString(filename);
      const fd = fs.openSync(filename, "r");
      const input = loadStringUtf8(fd);
      fs.closeSync(fd);
      const result2 = parse(input, "Root", path.resolve(scriptFile, "..", filename));
      const fl7 = globalResult.fl7;
      const util = globalResult.fl7.util;
      const constants = Array.from(globalResult.env.getConstants());
      for (let i = 0; i < globalResult.constantIdsScript.length; i++) {
        constants[globalResult.constantIdsScript[i]] = result2.env.getConstants()[globalResult.constantIdsScript[i]];
      }
      return eval(result2.code);
    });
  })());
  c("USE", (function(){
    return new result.fl7.FluoriteFunction(args => {
      var filename = args[0];
      if (filename === undefined) throw new Error("Illegal argument");
      filename = result.fl7.util.toString(filename);
      let res = cacheUse.get(filename);
      if (res === undefined) {
        const fd = fs.openSync(filename, "r");
        const input = loadStringUtf8(fd);
        fs.closeSync(fd);
        const result2 = parse(input, "Root", path.resolve(scriptFile, "..", filename));
        const fl7 = globalResult.fl7;
        const util = globalResult.fl7.util;
        const constants = Array.from(globalResult.env.getConstants());
        for (let i = 0; i < globalResult.constantIdsScript.length; i++) {
          constants[globalResult.constantIdsScript[i]] = result2.env.getConstants()[globalResult.constantIdsScript[i]];
        }
        res = eval(result2.code);
	cacheUse.set(filename, res);
      }
      return res;
    });
  })());
  constantIdsScript.push(c("FILE", path.resolve(scriptFile)));
  c("ARGV", process.argv.slice(1));
  c("ENV", (function() {
    const map = {};
    const names = Object.getOwnPropertyNames(process.env);
    for (let i = 0; i < names.length; i++) {
      map[names[i]] = String(Object.getOwnPropertyDescriptor(process.env, names[i]).value);
    }
    return new result.fl7.FluoriteObject(null, map);
  })());
  c("PID", process.pid);
  c("PPID", process.ppid);
  c("MEMORY_USAGE", new result.fl7.FluoriteFunction(args => {
    return new result.fl7.FluoriteObject(null, process.memoryUsage());
  }));
  c("GC", new result.fl7.FluoriteFunction(args => global.gc()));
  c("HEAPDUMP", new result.fl7.FluoriteFunction(args => {
    if (args[0] !== undefined) {
      heapdump.writeSnapshot(result.fl7.util.toString(args[0]));
    } else {
      heapdump.writeSnapshot();
    }
  }));
  c("EXIT", new result.fl7.FluoriteFunction(args => {
    const code = args[0] === undefined ? 0 : result.fl7.util.toNumber(args[0]);
    process.exit(code);
  }));
  const codes = result.node.getCodeGetter(env);
  const code = "(function() {\n" + result.fl7c.util.indent(codes[0] + "return " + codes[1] + ";\n") + "}())";
  return {
    fl7: result.fl7,
    objects: objects,
    env: env,
    code: code,
    constantIdsScript: constantIdsScript,
  };
}
let result = parse(process.env.exec, process.env.embedded_fluorite !== "0" ? "RootEmbeddedFluorite" : "Root", process.env.script_file);
globalResult = result;
if (process.env.compile !== "0") {
  console.log(result.code);
} else {
  const fl7 = result.fl7;
  function Util() {
  }
  Util.prototype = result.fl7.util;
  const util = new Util();
  util.objects = result.objects;
  const constants = result.env.getConstants();
  const stream = util.toStreamer(eval(result.code)).start();
  if (process.env.output_json !== "0") {
    while (true) {
      const next = stream.next();
      if (next === undefined) break;
      console.log(JSON.stringify(next));
    }
  } else {
    while (true) {
      const next = stream.next();
      if (next === undefined) break;
      console.log(util.toString(next));
    }
  }
}
