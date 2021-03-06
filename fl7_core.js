const fs = require("fs");
const path = require("path");
const child_process = require("child_process");
const parser = require(process.env.app_dir + "/fluorite-7.js");
const heapdump = require("heapdump");
const syncRequest = require("sync-request");
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
  function createUtf8LineReader(fd, size, doClose) {

    let closed = false;
    let buffers = [];
    let buffer;
    let start = 0;
    let length = 0;
    let afterCR = false;

    return {
      next: () => {
        while (true) {

          // 既に閉じている場合は何も返さない
          if (closed) return undefined;

          // 前回の残りがないなら新しく読み込む
          if (start >= length) {
            while (true) {
              try {
                buffer = Buffer.alloc(size);
                start = 0;
                length = fs.readSync(fd, buffer, 0, buffer.length, null);
              } catch (e) {
                if (e.code === "EAGAIN") {
                  continue;
                } else {
                  throw e;
                }
              }
              break;
            }
          }

          // ファイルの終端に来た場合はこれまでにたまっていたバッファをくっつけて返す
          // ただし何も貯まっていない場合は何も返さない
          if (length === 0) {
            closed = true;
            if (doClose) fs.closeSync(fd);
            if (buffers.length === 0) {
              return undefined;
            } else {
              return Buffer.concat(buffers).toString("utf8");
            }
          }

          // CRの直後のLFは無視する
          if (afterCR) {
            if (buffer[start] === 10) {
              start++;
              afterCR = false;
              continue;
            }
          }

          // 改行文字が出る位置を探す
          let index = -1;
          for (let i = start; i < length; i++) {
            if (buffer[i] === 10) {
              index = i;
              afterCR = false;
              break;
            } else if (buffer[i] === 13) {
              index = i;
              afterCR = true;
              break;
            }
          }

          // 改行文字があった場合、これまでにたまっていたバッファとこのバッファをくっつけたバッファを返す
          if (index !== -1) {
            if (buffers.length === 0) {
              const result = buffer.subarray(start, index);
              start = index + 1;
              return result.toString("utf8");
            } else {
              const result = Buffer.concat([...buffers, buffer.subarray(start, index)]);
              buffers = [];
              start = index + 1;
              return result.toString("utf8");
            }
          }

          // 改行文字が見つからなかった場合、このバッファをためる
          buffers.push(buffer.subarray(start, length));
          start = length;

        }
      },
    };
  }
  function createBufferReader(fd, size, doClose) {

    let closed = false;

    return {
      next: () => {
        while (true) {

          // 既に閉じている場合は何も返さない
          if (closed) return undefined;

          // 新しく読み込む
          let buffer;
          let length;
          while (true) {
            try {
              buffer = Buffer.alloc(size);
              length = fs.readSync(fd, buffer, 0, buffer.length, null);
            } catch (e) {
              if (e.code === "EAGAIN") {
                continue;
              } else {
                throw e;
              }
            }
            break;
          }

          // ファイルの終端に来た場合は終了する
          if (length === 0) {
            closed = true;
            if (doClose) fs.closeSync(fd);
            return undefined;
          }

          return Array.from(buffer.subarray(0, length));
        }
      },
    };
  }
  c("RESOLVE", new result.fl7.FluoriteFunction(args => {
    if (args.length !== 1) throw new Error("Illegal Argument");
    var pathes = result.fl7.util.toStream(args[0]).toArray();
    return path.resolve.apply(null, pathes);
  }));
  c("MODULE", new result.fl7.FluoriteFunction(args => {
    let baseFiles;
    let moduleName;
    let moduleScript;
    if (args.length == 2) {
      baseFiles = result.fl7.util.toStream(args[0]).toArray();
      moduleName = result.fl7.util.toString(args[1]);
      moduleScript = "main.fl7";
    } else if (args.length == 3) {
      baseFiles = result.fl7.util.toStream(args[0]).toArray();
      moduleName = result.fl7.util.toString(args[1]);
      moduleScript = result.fl7.util.toString(args[2]);
    } else {
      throw new Error("Illegal Argument");
    }

    for (let baseFile of baseFiles) {
      let modulePath = path.resolve(baseFile, "../fl7_modules", "_" + encodeURIComponent(moduleName)
        .replace(/\-/g, "%2D")
        .replace(/\./g, "%2E")
        .replace(/\!/g, "%21")
        .replace(/\~/g, "%7E")
        .replace(/\*/g, "%2A")
        .replace(/\'/g, "%27")
        .replace(/\(/g, "%28")
        .replace(/\)/g, "%29"));
      let stat = fs.statSync(modulePath, {throwIfNoEntry: false});
      if (stat !== undefined && stat.isDirectory()) {
        return path.resolve(modulePath, moduleScript);
      }
    }
    throw new Error("No such module: " + moduleName);
  }));
  c("INC", result.fl7.util.toStreamFromArray([
    "./fl7_modules",
    path.resolve(process.env.HOME, ".fl7/fl7_modules"),
    path.resolve(process.env.app_dir, "fl7_modules"),
  ]));
  c("UTF8", new result.fl7.FluoriteFunction(args => {
    if (args.length == 1) {
      return Array.from(Buffer.from(result.fl7.util.toString(args[0])));
    }
    throw new Error("Illegal argument");
  }));
  c("FROM_UTF8", new result.fl7.FluoriteFunction(args => {
    if (args.length == 1) {
      if (args[0] instanceof Array) {
        return Buffer.from(args[0]).toString();
      }
    }
    throw new Error("Illegal argument");
  }));
  c("IN", (function(){
    class FluoriteStreamerStdin extends result.fl7.FluoriteStreamer {
      constructor () {
        super();
      }
      start() {
        return createUtf8LineReader(process.stdin.fd, 4096, false);
      }
    }
    return new FluoriteStreamerStdin();
  })());
  c("INB", (function(){
    class FluoriteStreamerStdin extends result.fl7.FluoriteStreamer {
      constructor () {
        super();
      }
      start() {
        return createBufferReader(process.stdin.fd, 4096, false);
      }
    }
    return new FluoriteStreamerStdin();
  })());
  c("OUTB", new result.fl7.FluoriteFunction(args => {
    if (args.length == 1) {
      var stream = result.fl7.util.toStream(args[0]).start();
      while (true) {
        var next = stream.next();
        if (next === undefined) break;
        if (next instanceof Array) {
          process.stdout.write(Buffer.from(next))
        } else if (typeof next === "string") {
          process.stdout.write(next);
        } else {
          throw new Error("Illegal argument");
        }
      }
      return args[0];
    }
    throw new Error("Illegal argument");
  }));
  c("ERR", new result.fl7.FluoriteFunction(args => {
    if (args.length == 1) {
      var stream = result.fl7.util.toStream(args[0]).start();
      while (true) {
        var next = stream.next();
        if (next === undefined) break;
        console.error("%s", result.fl7.util.toString(next));
      }
      return args[0];
    }
    throw new Error("Illegal argument");
  }));
  c("ERRB", new result.fl7.FluoriteFunction(args => {
    if (args.length == 1) {
      var stream = result.fl7.util.toStream(args[0]).start();
      while (true) {
        var next = stream.next();
        if (next === undefined) break;
        if (next instanceof Array) {
          process.stderr.write(Buffer.from(next))
        } else if (typeof next === "string") {
          process.stderr.write(next);
        } else {
          throw new Error("Illegal argument");
        }
      }
      return args[0];
    }
    throw new Error("Illegal argument");
  }));
  c("READ", (function(){
    class FluoriteStreamerRead extends result.fl7.FluoriteStreamer {
      constructor (filename) {
        super();
        this._filename = filename;
      }
      start() {
        return createUtf8LineReader(fs.openSync(this._filename, "r"), 4096, true);
      }
    }
    return new result.fl7.FluoriteFunction(args => {
      var filename = args[0];
      if (filename === undefined) throw new Error("Illegal argument");
      return new FluoriteStreamerRead(result.fl7.util.toString(filename));
    });
  })());
  c("READB", (function(){
    class FluoriteStreamerRead extends result.fl7.FluoriteStreamer {
      constructor (filename) {
        super();
        this._filename = filename;
      }
      start() {
        return createBufferReader(fs.openSync(this._filename, "r"), 4096, true);
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
  c("WRITEB", (function(){
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
        if (next instanceof Array) {
          fs.writeSync(fd, Buffer.from(next));
        } else if (typeof next === "string") {
          fs.writeSync(fd, next);
        } else {
          throw new Error("Illegal argument");
        }
      }
      fs.closeSync(fd);
      return null;
    });
  })());
  c("LS", new result.fl7.FluoriteFunction(args => {
    if (args.length === 0) {
      return result.fl7.util.toStreamFromArray(fs.readdirSync("."));
    } else if (args.length === 1) {
      return result.fl7.util.toStreamFromArray(fs.readdirSync(result.fl7.util.toString(args[0])));
    } else {
      throw new Error("Illegal argument");
    }
  }));
  c("STAT", new result.fl7.FluoriteFunction(args => {
    if (args.length != 1) throw new Error("Illegal argument");
    let stats;
    try { // 旧バージョンnodeでエラーになる対策
      stats = fs.statSync(result.fl7.util.toString(args[0]), {throwIfNoEntry: false});
    } catch (e) {
      if (e.code === "ENOENT") {
        return null;
      } else {
        throw e;
      }
    }
    if (stats === undefined) return null;
    return new result.fl7.FluoriteObject(null, {
      is_blockDevice: new result.fl7.FluoriteFunction(args => stats.isBlockDevice()),
      is_characterDevice: new result.fl7.FluoriteFunction(args => stats.isCharacterDevice()),
      is_directory: new result.fl7.FluoriteFunction(args => stats.isDirectory()),
      is_fifo: new result.fl7.FluoriteFunction(args => stats.isFIFO()),
      is_file: new result.fl7.FluoriteFunction(args => stats.isFile()),
      is_socket: new result.fl7.FluoriteFunction(args => stats.isSocket()),
      is_symbolicLink: new result.fl7.FluoriteFunction(args => stats.isSymbolicLink()),
      dev: stats.dev,
      ino: stats.ino,
      mode: stats.mode,
      nlink: stats.nlink,
      uid: stats.uid,
      gid: stats.gid,
      rdev: stats.rdev,
      size: stats.size,
      blksize: stats.blksize,
      blocks: stats.blocks,
      atime: stats.atimeMs,
      mtime: stats.mtimeMs,
      ctime: stats.ctimeMs,
      birthtime: stats.birthtimeMs,
      TO_NUMBER: new result.fl7.FluoriteFunction(args => stats.size),
      LENGTH: new result.fl7.FluoriteFunction(args => stats.size),
    });
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
    if (stdin instanceof Array) {
      stdin = Buffer.from(stdin);
    } else {
      stdin = result.fl7.util.toString(stdin);
    }

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
  c("EXECB", new result.fl7.FluoriteFunction(args => {

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
    if (stdin instanceof Array) {
      stdin = Buffer.from(stdin);
    } else {
      stdin = Buffer.from(result.fl7.util.toString(stdin));
    }

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

    return Array.from(child_process.execFileSync(filename, argsExec, {
      input: stdin,
      encoding: "buffer",
      maxBuffer: 64 * 1024 * 1024,
      env: env,
    }));
  }));
  c("SHELL", new result.fl7.FluoriteFunction(args => {

    let script = args[0];
    if (script === undefined) throw new Error("Illegal argument");
    script = result.fl7.util.toString(script);

    const stringOut = child_process.execFileSync(process.env.SHELL, [], {
      input: script,
      encoding: "utf8",
      maxBuffer: 64 * 1024 * 1024,
      env: process.env,
    });
    const arrayOut = stringOut.split("\n");
    if (arrayOut[arrayOut.length - 1] === "") arrayOut.pop();
    return result.fl7.util.toStreamFromArray(arrayOut);
  }));
  c("SHELLB", new result.fl7.FluoriteFunction(args => {

    let script = args[0];
    if (script === undefined) throw new Error("Illegal argument");
    script = Buffer.from(result.fl7.util.toString(script));

    return Array.from(child_process.execFileSync(process.env.SHELL, [], {
      input: script,
      encoding: "buffer",
      maxBuffer: 64 * 1024 * 1024,
      env: process.env,
    }));
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
  c("ARGS", result.fl7.util.toStreamFromArray(process.argv.slice(2)));
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
  c("HTTP", new result.fl7.FluoriteFunction(args => {
    if (args.length !== 1) throw new Error("Illegal argument");
    const url = result.fl7.util.toString(args[0]);
    const response = syncRequest("GET", url);
    if (response.statusCode < 200 || response.statusCode >= 300) throw new Error("HTTP Error: " + response.statusCode);
    const stringOut = response.body.toString("utf8");
    const arrayOut = stringOut.split("\n");
    if (arrayOut[arrayOut.length - 1] === "") arrayOut.pop();
    return result.fl7.util.toStreamFromArray(arrayOut);
  }));
  c("HTTPB", new result.fl7.FluoriteFunction(args => {
    if (args.length !== 1) throw new Error("Illegal argument");
    const url = result.fl7.util.toString(args[0]);
    const response = syncRequest("GET", url);
    if (response.statusCode < 200 || response.statusCode >= 300) throw new Error("HTTP Error: " + response.statusCode);
    return Array.from(response.body);
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
