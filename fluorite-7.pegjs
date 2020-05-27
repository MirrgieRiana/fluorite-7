
{

  function isNumber(value) {
    return typeof value === "number";
  }

  function isString(value) {
    return typeof value === "string" || value instanceof String;
  }

  var fl7c = (() => {

    function getLocationString(location) {
      return "L:" + location.start.line + ",C:" + location.start.column;
    }

    function throwCompileError(location, message) {
      throw new FluoriteCompileError(message + " (" + getLocationString(location) + ")");
    }

    class FluoriteCompileError extends Error { // TODO -> FluoriteSyntaxError, FluoriteRuntimeError

      constructor(...args) {
        super(...args);
        Object.defineProperty(this, 'name', {
          configurable: true,
          enumerable: false,
          value: this.constructor.name,
          writable: true,
        });
        if (Error.captureStackTrace) {
          Error.captureStackTrace(this, FluoriteCompileError);
        }
      }

    }

    //

    class Environment { // TODO 全体の pc -> env; rename: -> CompilerContext

      constructor() {
        this._nextConstantId = 0;
        this._nextVariableId = 0;
        this._constants = [];
        this._frameStack = [{}];
        this._labelFrameStackStack = [[{}]];
      }

      //

      // TODO システムの刷新
      // REQUIRE関数の挙動の為にコンパイル後に呼び出してはならない
      // 同じ構成の環境では、コンパイル時に同じ定数が同じ順序で並んでいなければならない
      allocateConstantId() {
        var result = this._nextConstantId;
        this._nextConstantId++;
        return result;
      }

      //

      allocateVariableId() {
        var result = this._nextVariableId;
        this._nextVariableId++;
        return result;
      }

      //

      getConstants() {
        return this._constants;
      }

      getConstant(constantId) {
        return this._constants[constantId];
      }

      setConstant(constantId, value) {
        this._constants[constantId] = value;
      }

      //

      pushFrame() {
        this._frameStack.push({});
      }

      popFrame() {
        this._frameStack.pop();
      }

      getFrameStack() {
        return this._frameStack;
      }

      setFrameStack(frameStack) {
        this._frameStack = frameStack;
      }

      getFrame() {
        return this._frameStack[this._frameStack.length - 1];
      }

      //

      setAlias(key, value) {
        this.getFrame()[key] = value;
      }

      getAlias(location, key) {
        for (var i = this._frameStack.length - 1; i >= 0; i--) {
          var alias = this._frameStack[i][key]; // TODO own property
          if (alias !== undefined) {
            return alias;
          }
        }
        throwCompileError(location, "No such alias '" + key + "'");
      }

      getAliasOrUndefined(location, key) {
        for (var i = this._frameStack.length - 1; i >= 0; i--) {
          var alias = this._frameStack[i][key]; // TODO own property
          if (alias !== undefined) {
            return alias;
          }
        }
        return undefined;
      }

      //

      pushLabelFrame() {
        this.getLabelFrameStack().push({});
      }

      popLabelFrame() {
        this.getLabelFrameStack().pop();
      }

      nextLabelFrame() {
        this._labelFrameStackStack.push([{}]);
      }

      prevLabelFrame() {
        this._labelFrameStackStack.pop();
      }

      getLabelFrameStack() {
        return this._labelFrameStackStack[this._labelFrameStackStack.length - 1];
      }

      getLabelFrame() {
        return this.getLabelFrameStack()[this.getLabelFrameStack().length - 1];
      }

      //

      getLabelAliasOrUndefined(location, key) {
        for (var i = this.getLabelFrameStack().length - 1; i >= 0; i--) {
          var labelAlias = this.getLabelFrameStack()[i][key]; // TODO own property
          if (labelAlias !== undefined) {
            return labelAlias;
          }
        }
        return undefined;
      }

    }

    //

    class FluoriteNode {

      constructor(location) {
        this._location = location;
      }

      getLocation() {
        return this._location;
      }

      getCode(pc) { // TODO delete
        throwCompileError(this._location, "Not Implemented");
      }

      /**
       * @return [codeLines : string, codeFormula : string]
       * Example:
       *   ["", "(50)"]
       *   ["const v_1 = (20);\n", "(v_1)"]
       *   ["return (v_7);\n", "(null)"]
       */
      getCodeGetter(pc) { // TODO throw error
        return [
          "",
          this.getCode(pc),
        ];
      }

      /**
       * @param funcCode (codeFormula : string) => (codeLines : string)
       * @return [codeLines : string]
       */
      getCodeIterator(pc, funcCode) {
        var codes = this.getCodeGetter(pc);
        return [
          codes[0] +
          funcCode(codes[1]),
        ];
      }

      /**
       * @param code (codeFormula : string)
       * @return [codeLines : string]
       * Example:
       *   ["v_5 = " + code + ";\n"]
       *   ["util.setArrayValue(v_5, " + code + ");\n"]
       */
      getCodeSetter(pc, code) {
        throwCompileError(this._location, "Cannot get setter code this node: " + this);
      }

      getTree(pc) {
        throwCompileError(this._location, "Not Implemented");
      }

    }

    class FluoriteNodeVoid extends FluoriteNode {

      constructor(location) {
        super(location);
      }

      getCode(pc) { // TODO delete
        throwCompileError(this._location, "Cannot stringify void node");
      }

      getCodeGetter(pc) {
        throwCompileError(this._location, "Cannot stringify void node");
      }

      getTree(pc) {
        return "VOID"; // TODO void演算子
      }

    }

    class FluoriteNodeToken extends FluoriteNode {

      constructor(location, value, source) {
        super(location);
        this._value = value;
        this._source = source;
      }

      getValue() {
        return this._value;
      }

      getCode(pc) { // TODO delete
        throwCompileError(this.getLocation(), "Tried to stringify raw token");
      }

      getCodeGetter(pc) {
        throwCompileError(this.getLocation(), "Tried to stringify raw token");
      }

      getCodeSetter(pc, code) {
        throwCompileError(this.getLocation(), "Tried to stringify raw token");
      }

      getTree() {
        return this._source;
      }

    }

    class FluoriteNodeTokenInteger extends FluoriteNodeToken {

      constructor(location, value, source) {
        super(location, value, source);
      }

    }

    class FluoriteNodeTokenBasedInteger extends FluoriteNodeToken {

      constructor(location, value, source) {
        super(location, value, source);
      }

    }

    class FluoriteNodeTokenFloat extends FluoriteNodeToken {

      constructor(location, value, source) {
        super(location, value, source);
      }

    }

    class FluoriteNodeTokenIdentifier extends FluoriteNodeToken {

      constructor(location, value, source) {
        super(location, value, source);
      }

    }

    class FluoriteNodeTokenString extends FluoriteNodeToken {

      constructor(location, value, source) {
        super(location, value, source);
      }

    }

    class FluoriteNodeTokenPattern extends FluoriteNodeToken {

      constructor(location, value, option, source) {
        super(location, value, source);
        this._option = option;
      }

      getOption() {
        return this._option;
      }

    }

    class FluoriteNodeTokenFormat extends FluoriteNodeToken {

      constructor(location, value, source) {
        super(location, value, source);
      }

    }

    class FluoriteNodeMacro extends FluoriteNode {

      constructor(location, key, args) {
        super(location);
        this._key = key;
        this._args = args;
      }

      getKey() {
        return this._key;
      }

      getArguments() {
        return this._args;
      }

      getArgument(index) {
        if (index >= this._args.length) {
          throwCompileError(this.getLocation(), "Not enough arguments: " + (this._args.length) + " < " + (index + 1));
        } else {
          return this._args[index];
        }
      }

      getArgumentCount() {
        return this._args.length;
      }

      getCode(pc) { // TODO delete
        var alias = pc.getAlias(this.getLocation(), this._key);
        if (alias instanceof FluoriteAliasMacro) {
          var result;
          try {
            result = alias.getMacro()(new FluoriteMacroEnvironment(pc, this));
          } catch (e) {
            if (e instanceof FluoriteCompileError) {
              throw e;
            } else {
              throwCompileError(this.getLocation(), "" + e.message + " in macro '" + this._key + "'");
            }
          }
          return result;
        }
        throwCompileError(this.getLocation(), "No such macro '" + this._key + "'");
      }

      getCodeGetter(pc) {
        var alias = pc.getAliasOrUndefined(this.getLocation(), this._key);
        if (alias instanceof FluoriteAliasMacro) {
          var codes;
          try {
            codes = alias.getMacro()(new FluoriteMacroEnvironment(pc, this));
          } catch (e) {
            if (e instanceof FluoriteCompileError) {
              throw e;
            } else {
              throwCompileError(this.getLocation(), "" + e.message + " in macro '" + this._key + "'");
            }
          }
          if (!(codes instanceof Array)) { // TODO delete
            codes = [
              "",
              codes,
            ];
          }
          return codes;
        }
        throwCompileError(this.getLocation(), "No such macro '" + this._key + "'");
      }

      getCodeIterator(pc, funcCode) {
        var alias = pc.getAliasOrUndefined(this.getLocation(), "_ITERATE" + this._key);
        if (alias instanceof FluoriteAliasMacro) {
          var codes;
          try {
            codes = alias.getMacro()(new FluoriteMacroEnvironment(pc, this), funcCode);
          } catch (e) {
            if (e instanceof FluoriteCompileError) {
              throw e;
            } else {
              throwCompileError(this.getLocation(), "" + e.message + " in macro '" + this._key + "'");
            }
          }
          return codes;
        }
        return super.getCodeIterator(pc, funcCode);
      }

      getCodeSetter(pc, code) {
        var alias = pc.getAliasOrUndefined(this.getLocation(), "_SET" + this._key);
        if (alias instanceof FluoriteAliasMacro) {
          var codes;
          try {
            codes = alias.getMacro()(new FluoriteMacroEnvironment(pc, this), code);
          } catch (e) {
            if (e instanceof FluoriteCompileError) {
              throw e;
            } else {
              throwCompileError(this.getLocation(), "" + e.message + " in macro '" + this._key + "'");
            }
          }
          return codes;
        }
        throwCompileError(this.getLocation(), "No such macro '" + this._key + "'");
      }

      getTree() {
        return this._key + "[" + this._args.map(a => a.getTree()).join(",") + "]";
      }

    }

    class FluoriteMacroEnvironment { // TODO 名称変更 場所をマクロローダーに

      constructor(pc, node) {
        this._pc = pc;
        this._node = node;
      }

      pc() {
        return this._pc;
      }

      node() {
        return this._node;
      }

      arg(index) {
        return this._node.getArgument(index);
      }

      code(index) { // TODO delete
        return this._node.getArgument(index).getCode(this._pc);
      }

    }

    //

    class FluoriteAlias {

      constructor() {

      }

      getCode(pc, location) { // TODO delete
        throw new Error("Not Implemented"); // TODO 全箇所でエラークラスを独自に
      }

      getCodeGetter(pc, location) {
        return [
          "",
          this.getCode(pc, location), // TODO throw error
        ];
      }

    }

    class FluoriteAliasMacro extends FluoriteAlias {

      constructor(func) {
        super();
        this._func = func;
      }

      getMacro() {
        return this._func;
      }

      getCode(pc, location) { // TODO delete
        throw new Error("Cannot stringify a macro alias");
      }

      getCodeGetter(pc, location) {
        throw new Error("Cannot stringify a macro alias");
      }

    }

    // TODO すべての変数名ハードコーディングはこのクラスのメソッドを呼び出すように
    class FluoriteAliasVariable extends FluoriteAlias {

      constructor(variableId) {
        super();
        this._variableId = variableId;
      }

      getRawCode(pc, location) { // TODO rename -> getCode(void)
        return "v_" + this._variableId;
      }

      getCode(pc, location) { // TODO delete
        return "(v_" + this._variableId + ")";
      }

      getCodeGetter(pc, location) {
        return [
          "",
          "(v_" + this._variableId + ")",
        ];
      }

    }

    class FluoriteAliasVariableSettable extends FluoriteAliasVariable {

      constructor(variableId) {
        super(variableId);
      }

      getCodeSetter(pc, location, code) {
        return [
          "v_" + this._variableId + " = " + code + ";\n",
        ];
      }

    }

    class FluoriteAliasConstant extends FluoriteAlias {

      constructor(constantId) {
        super();
        this._constantId = constantId;
      }

      getCode(pc, location) { // TODO delete
        return "(constants[" + this._constantId + "])";
      }

      getCodeGetter(pc, location) {
        return [
          "",
          "(constants[" + this._constantId + "])",
        ];
      }

    }

    class FluoriteAliasMember extends FluoriteAlias {

      constructor(variableId, key) {
        super();
        this._variableId = variableId;
        this._key = key;
      }

      getCode(pc, location) { // TODO delete
        return "(util.getOwnValueFromObject(v_" + this._variableId + "," + JSON.stringify(this._key) + "))";
      }

      getCodeGetter(pc, location) {
        return [
          "",
          "(util.getOwnValueFromObject(v_" + this._variableId + ", " + JSON.stringify(this._key) + "))",
        ];
      }

    }

    //

    class FluoriteLabelAlias {

      constructor(labelId, variableId) {
        this._labelId = labelId;
        this._variableId = variableId;
      }

      getCode() {
        return "l_" + this._labelId;
      }

      getCodeResponse() {
        return "v_" + this._variableId;
      }

    }

    //

    var util = {

      indent: function(code) {
        return "  " + code.replace(/\n(?<!$)/g, "\n  ");
      },

    };

    return {
      FluoriteCompileError,
      Environment,
      FluoriteNode,
      FluoriteNodeVoid,
      FluoriteNodeToken,
      FluoriteNodeTokenInteger,
      FluoriteNodeTokenBasedInteger,
      FluoriteNodeTokenFloat,
      FluoriteNodeTokenIdentifier,
      FluoriteNodeTokenString,
      FluoriteNodeTokenPattern,
      FluoriteNodeTokenFormat,
      FluoriteNodeMacro,
      FluoriteAlias,
      FluoriteAliasMacro,
      FluoriteAliasVariable,
      FluoriteAliasVariableSettable,
      FluoriteAliasConstant,
      FluoriteAliasMember,
      FluoriteLabelAlias,
      util,
    };
  })();

  //

  var fl7 = (() => {

    class FluoriteRuntimeError extends Error {

      constructor(...args) {
        super(...args);
        Object.defineProperty(this, 'name', {
          configurable: true,
          enumerable: false,
          value: this.constructor.name,
          writable: true,
        });
        if (Error.captureStackTrace) {
          Error.captureStackTrace(this, FluoriteRuntimeError);
        }
      }

    }

    //

    class FluoriteValue {

      toNumber() {
        return undefined;
      }

      toBoolean() {
        return undefined;
      }

      toString() {
        return undefined;
      }

      toJSON() {
        return this.toString();
      }

      getStream() {
        throw new Error("Illegal operation: getStream of '" + this + "'");
      }

      equals(actual) {
        return actual === this;
      }

      plus(b) {
        return undefined;
      }

      minus(b) {
        return undefined;
      }

      asterisk(b) {
        return undefined;
      }

      slash(b) {
        return undefined;
      }

      setValue(index, value) {
        throw new FluoriteRuntimeError("Not Implemented");
      }

      match(value) {
        throw new FluoriteRuntimeError("Not Implemented");
      }

      call(args) {
        throw new FluoriteRuntimeError("Not Implemented");
      }

      getType() {
        return "UNKNOWN";
      }

    }

    //

    class FluoriteStreamer extends FluoriteValue {

      constructor() {
        super();
      }

      start() {
        throw new FluoriteRuntimeError("Not Implemented");
      }

      toArray() {
        var result = [];
        var stream = this.start();
        while (true) {
          var item = stream.next();
          if (item === undefined) break;
          result.push(item);
        }
        return result;
      }

      toNumber() {
        var t = 0;
        this.toArray().forEach(value => t += util.toNumber(value));
        return t;
      }

      toBoolean() {
        var stream = this.start();
        while (true) {
          var item = stream.next();
          if (item === undefined) break;
          if (util.toBoolean(item)) return true;
        }
        return false;
      }

      toString() {
        return this.toArray().map(value => util.toString(value)).join("\n");
      }

      toJSON() {
        throw new Error("Cannot convert streamer to json ");
      }

      equals(actual) {
        var streamExpected = this.start();
        var streamActual = util.toStream(actual).start();
        while (true) {
          var nextExpected = streamExpected.next();
          var nextActual = streamActual.next();
          if ((nextActual === undefined) !== (nextExpected === undefined)) return false;
          if (nextExpected === undefined) break;
          if (!util.equal(nextActual, nextExpected)) return false;
        }
        return true;
      }

      getType() {
        return "STREAMER";
      }

    }

    class FluoriteStreamerEmpty extends FluoriteStreamer {

      constructor() {
        super();
      }

      start() {
        return this;
      }

      next() {
        return undefined;
      }

    }
    FluoriteStreamerEmpty.instance = new FluoriteStreamerEmpty();

    class FluoriteStreamerRange extends FluoriteStreamer {

      constructor(start, end, closed) {
        super();
        this._start = start;
        this._end = end;
        this._stepdown = end < start;
        this._closed = closed;
      }

      start() {
        var i = this._start;
        if (this._closed) {
          if (this._stepdown) {
            return {
              next: () => {
                if (i < this._end) return undefined;
                return i--;
              },
            };
          } else {
            return {
              next: () => {
                if (i > this._end) return undefined;
                return i++;
              },
            };
          }
        } else {
          if (this._stepdown) {
            return {
              next: () => {
                if (i <= this._end) return undefined;
                return i--;
              },
            };
          } else {
            return {
              next: () => {
                if (i >= this._end) return undefined;
                return i++;
              },
            };
          }
        }
      }

    }

    class FluoriteStreamerValues extends FluoriteStreamer {

      constructor(values) {
        super();
        this._values = values;
      }

      start() {
        var i = 0;
        var currentStream = undefined;
        return {
          next: () => {
            while (true) {
              if (currentStream !== undefined) {
                var result = currentStream.next();
                if (result !== undefined) return result;
                currentStream = undefined;
              }

              if (i >= this._values.length) return undefined;

              var result = this._values[i];
              i++;
              if (result instanceof FluoriteStreamer) {
                currentStream = result.start();
                continue;
              }
              return result;
            }
          },
        };
      }

    }

    class FluoriteStreamerMap extends FluoriteStreamer {

      constructor(streamer, func) {
        super();
        this._streamer = streamer;
        this._func = func;
      }

      start() {
        var stream = this._streamer.start();
        var currentStream = undefined;
        return {
          next: () => {
            while (true) {
              if (currentStream !== undefined) {
                var result = currentStream.next();
                if (result !== undefined) return result;
                currentStream = undefined;
              }

              var result = stream.next();
              if (result === undefined) return undefined;
              result = this._func(result);
              if (result instanceof FluoriteStreamer) {
                currentStream = result.start();
                continue;
              }
              return result;
            }
          },
        };
      }

    }

    class FluoriteStreamerGrep extends FluoriteStreamer {

      constructor(streamer, func) {
        super();
        this._streamer = streamer;
        this._func = func;
      }

      start() {
        var stream = this._streamer.start();
        return {
          next: () => {
            while (true) {
              var result = stream.next();
              if (result === undefined) return undefined;
              if (this._func(result)) {
                return result;
              }
            }
          },
        };
      }

    }

    class FluoriteStreamerScalar extends FluoriteStreamer {

      constructor(value) {
        super();
        this._value = value;
      }

      start() {
        var used = false;
        return {
          next: () => {
            if (used) return undefined;
            used = true;
            return this._value;
          },
        };
      }

    }

    //

    class FluoriteFunction extends FluoriteValue { // TODO 関数は独自クラスではなくネイティブ関数を使う

      constructor(func) {
        super();
        this._func = func;
      }

      call(args) {
        return this._func(args);
      }

      bind(value) {
        return new FluoriteFunction(args => {
          var newArgs = [value];
          Array.prototype.push.apply(newArgs, args);
          return this._func(newArgs);
        });
      }

      bindLeft(values) {
        return new FluoriteFunction(args => {
          var newArgs = [];
          Array.prototype.push.apply(newArgs, values);
          Array.prototype.push.apply(newArgs, args);
          return this._func(newArgs);
        });
      }

      bindRight(values) {
        return new FluoriteFunction(args => {
          var newArgs = [];
          Array.prototype.push.apply(newArgs, args);
          Array.prototype.push.apply(newArgs, values);
          return this._func(newArgs);
        });
      }

      toString() {
        return "[FluoriteFunction]";
      }

      getType() {
        return "FUNCTION";
      }

    }

    //

    // TODO FluoriteObjectの変数をprivateに
    class FluoriteObject extends FluoriteValue {

      constructor(parent, map) {
        super();
        this.parent = parent;
        this.map = map;
      }

      initialize(object) {
        for (var key in this.map) {
          if (this.map[key] instanceof FluoriteObjectInitializer) {
            this.map[key] = this.map[key].get();
          }
        }
      }

      toNumber() {
        var res = util.getValueFromObject(this, "TO_NUMBER");
        if (res !== null) return util.toNumber(util.call(res, [this]));
        return undefined;
      }

      toBoolean() {
        var res = util.getValueFromObject(this, "TO_BOOLEAN");
        if (res !== null) return util.toBoolean(util.call(res, [this]));
        return true;
      }

      toString() {
        var res = util.getValueFromObject(this, "TO_STRING");
        if (res !== null) return util.toString(util.call(res, [this]));

        var strings = [];
        for (var key in this.map) {
          strings.push(key + ":" + util.toString(this.map[key]));
        }
        return "{" + strings.join(";") + "}";
      }

      toJSON() {
        var res = util.getValueFromObject(this, "TO_JSON");
        if (res !== null) return util.toJSON(util.call(res, [this]));
        return this.map;
      }

      getStream() {
        var array = [];
        for (var key in this.map) {
          array.push(new FluoriteObject(null, {
            "key": key,
            "value": this.map[key],
          }));
        }
        return util.toStreamFromValues(array);
      }

      equals(actual) {
        var res = util.getValueFromObject(this, "EQUALS");
        if (res !== null) return util.toBoolean(util.call(res, [this, actual]));
        if (actual instanceof FluoriteObject) {
          if (actual.parent !== this.parent) return false;
          var keysExpected = Object.getOwnPropertyNames(this.map).sort();
          var keysActual = Object.getOwnPropertyNames(actual.map).sort();
          if (keysActual.length !== keysExpected.length) return false;
          for (var i = 0; i < keysExpected.length; i++) {
            if (keysActual[i] !== keysExpected[i]) return false;
          }
          for (var i = 0; i < keysExpected.length; i++) {
            var key = keysExpected[i];
            if (!util.equal(actual.map[key], this.map[key])) return false;
          }
          return true;
        }
        return false;
      }

      plus(b) {
        var res = util.getValueFromObject(this, "PLUS");
        if (res !== null) return util.call(res, [this, b]);
        return super.plus(b);
      }

      minus(b) {
        var res = util.getValueFromObject(this, "MINUS");
        if (res !== null) return util.call(res, [this, b]);
        return super.minus(b);
      }

      asterisk(b) {
        var res = util.getValueFromObject(this, "ASTERISK");
        if (res !== null) return util.call(res, [this, b]);
        return super.asterisk(b);
      }

      slash(b) {
        var res = util.getValueFromObject(this, "SLASH");
        if (res !== null) return util.call(res, [this, b]);
        return super.slash(b);
      }

      setValue(index, value) {
        this.map[util.toString(index)] = value;
      }

      match(value) {
        var res = util.getValueFromObject(this, "MATCH");
        if (res !== null) return util.call(res, [this, value]);
        return super.match(value);
      }

      call(args) {
        var res = util.getValueFromObject(this, "CALL");
        if (res !== null) {
          var args2 = [this];
          Array.prototype.push.apply(args2, args);
          return util.call(res, args2);
        }
        return super.call(args);
      }

      getType() {
        return "OBJECT";
      }

    }

    class FluoriteObjectInitializer {

      constructor(func) {
        this._func = func;
      }

      get() {
        return this._func();
      }

    }

    //

    class FluoriteRegExpProvider extends FluoriteValue {

      constructor(pattern, option) {
        super();
        this._pattern = pattern;
        this._option = option;
      }

      create() {
        var option = "";
        if (this._option.includes("i")) option += "i";
        if (this._option.includes("s")) option += "s";
        if (this._option.includes("m")) option += "m";
        if (this._option.includes("u")) option += "u";
        if (this._option.includes("g")) option += "g";
        return new RegExp(this._pattern, option);
      }

      isGlobal() {
        return this._option.includes("g");
      }

      match(value) {
        value = util.toString(value);
        var regexp = this.create();
        if (!this.isGlobal()) {
          return regexp.exec(value);
        } else {
          class FluoriteStreamerFindAll extends FluoriteStreamer {

            constructor () {
              super();
            }

            start() {
              return {
                next: () => {
                  var res = regexp.exec(value);
                  if (res === null) return undefined;
                  return res;
                },
              };
            }

          }
          return new FluoriteStreamerFindAll();
        }
      }

      toString() {
        return "" + this._pattern;
      }

      getType() {
        return "REGEXP";
      }

    }

    //

    var util = {

      toNumberOrUndefined: function(value) {
        if (value === null) return 0;
        if (isNumber(value)) return value;
        if (value === true) return 1;
        if (value === false) return 0;
        if (isString(value)) {
          var result = Number(value);
          if (!Number.isNaN(result)) return result;
        }
        if (value instanceof Array) return value.length;
        if (value instanceof FluoriteValue) {
          var result = value.toNumber();
          if (result !== undefined) return result;
        }
        return undefined;
      },

      toNumber: function(value) {
        var result = util.toNumberOrUndefined(value);
        if (result !== undefined) return result;
        throw new FluoriteRuntimeError("Cannot convert to number: " + value);
      },

      toBooleanOrUndefined: function(value) {
        if (value === null) return false;
        if (value === 0) return false;
        if (value === false) return false;
        if (isString(value)) return value.length > 0;
        if (value instanceof Array) return value.length > 0;
        if (value instanceof FluoriteValue) {
          var result = value.toBoolean();
          if (result !== undefined) return result;
        }
        return undefined;
      },

      toBoolean: function(value) {
        var result = util.toBooleanOrUndefined(value);
        if (result !== undefined) return result;
        return true; // TODO その他の一般オブジェクトではエラー
      },

      toStringOrUndefined: function(value) {
        if (value === null) return "NULL";
        if (value === true) return "TRUE";
        if (value === false) return "FALSE";
        if (value instanceof Array) return value.map(a => util.toString(a)).join(",");
        if (value instanceof FluoriteValue) {
          var result = value.toString();
          if (result !== undefined) return result;
        }
        return undefined;
      },

      toString: function(value) {
        var result = util.toStringOrUndefined(value);
        if (result !== undefined) return result;
        return value.toString(); // TODO その他の一般オブジェクトではエラー
      },

      toJSON: function(value) {
        if (value.toJSON) return value.toJSON();
        return value;
      },

      toStream: function(value) { // TODO toStreamer
        if (value instanceof FluoriteStreamer) return value;
        return new FluoriteStreamerScalar(value);
      },

      toStreamer: function(value) {
        return util.toStream(value);
      },

      plus: function(a, b) {
        if (isNumber(a)) {
          return a + util.toNumber(b);
        }
        if (a instanceof Array) {
          if (b instanceof Array) {
            var result = [];
            Array.prototype.push.apply(result, a);
            Array.prototype.push.apply(result, b);
            return result;
          }
        }
        if (isString(a)) {
          return a + util.toString(b);
        }
        if (a instanceof FluoriteValue) {
          var result = a.plus(b);
          if (result !== undefined) return result;
        }
        throw new Error("Illegal argument: " + a + ", " + b);
      },

      minus: function(a, b) {
        if (isNumber(a)) {
          return a - util.toNumber(b);
        }
        if (a instanceof FluoriteValue) {
          var result = a.minus(b);
          if (result !== undefined) return result;
        }
        throw new Error("Illegal argument: " + a + ", " + b);
      },

      asterisk: function(a, b) {
        if (isNumber(a)) {
          return a * util.toNumber(b);
        }
        if (a instanceof Array) {
          b = util.toNumber(b);
          var result = [];
          for (var i = 0; i < b; i++) {
            Array.prototype.push.apply(result, a);
          }
          return result;
        }
        if (isString(a)) {
          return a.repeat(util.toNumber(b));
        }
        if (a instanceof FluoriteValue) {
          var result = a.asterisk(b);
          if (result !== undefined) return result;
        }
        throw new Error("Illegal argument: " + a + ", " + b);
      },

      slash: function(a, b) {
        if (isNumber(a)) {
          return a / util.toNumber(b);
        }
        if (a instanceof FluoriteValue) {
          var result = a.slash(b);
          if (result !== undefined) return result;
        }
        throw new Error("Illegal argument: " + a + ", " + b);
      },

      slice: function(value, start, end) {
        start = start === null ? 0 : Math.trunc(util.toNumber(start));
        end = end === null ? undefined : Math.trunc(util.toNumber(end));
        if (value instanceof Array) {
          return value.slice(start, end);
        }
        if (isString(value)) {
          if (start < 0) start = value.length + start;
          if (end < 0) end = value.length + end;
          if (start > end) return "";
          return value.substring(start, end);
        }
        throw new Error("Illegal argument: " + value + ", " + start + ", " + end);
      },

      getLength: function(value) {
        if (value instanceof Array) {
          return value.length;
        }
        if (isString(value)) {
          return value.length;
        }
        throw new Error("Illegal argument: " + value);
      },

      format: function(format, value) {

        var sign = undefined;
        var body;
        if (format.conversion === "d") {
          value = util.toNumber(value);

          if (Math.sign(value) === -1) {
            sign = "-";
            body = Number.prototype.toFixed.call(Math.round(-value), 0);
          } else {
            sign = "";
            body = Number.prototype.toFixed.call(Math.round(value), 0);
          }
        } else if (format.conversion === "f") {
          value = util.toNumber(value);

          var precision = format.precision;
          if (precision === undefined) precision = 6;

          if (Math.sign(value) === -1) {
            sign = "-";
            body = Number.prototype.toFixed.call(-value, precision);
          } else {
            sign = "";
            body = Number.prototype.toFixed.call(value, precision);
          }
        } else if (format.conversion === "s") {
          value = util.toString(value);

          sign = "";
          body = value;
        } else {
          throw new Error("Unknown conversion: " + format.conversion);
        }
        var lengthSign = sign.length;
        var lengthBody = body.length;

        if (lengthSign + lengthBody >= format.width) {
          return sign + body;
        }

        var charFiller = format.zero ? "0" : " ";
        var filler =  charFiller.repeat(format.width - lengthSign - lengthBody);

        if (format.left) {
          return sign + body + filler;
        } else {
          if (format.zero) {
            return sign + filler + body;
          } else {
            return filler + sign + body;
          }
        }
      },

      compare: function(a, b)  { // TODO
        //if (isNumber(a)) {
        //  if (isNumber(b)) {
        if (a > b) return 1;
        if (a < b) return -1
        return 0;
        //  }
        //}
        //throw new Error("Illegal argument: " + a + ", " + b);
      },

      equal: function(actual, expected)  {
        if (actual === expected) return true;
        if (expected === null) return actual === null;
        if (isNumber(expected)) {
          return util.toNumberOrUndefined(actual) === expected;
        }
        if (expected === true) return util.toBoolean(actual) === true;
        if (expected === false) return util.toBoolean(actual) === false;
        if (isString(expected)) {
          return util.toString(actual) === expected;
        }
        if (expected instanceof Array) {
          if (!(actual instanceof Array)) return false;
          if (actual.length !== expected.length) return false;
          for (var i = 0; i < expected.length; i++) {
            if (!util.equal(actual[i], expected[i])) return false;
          }
          return true;
        }
        if (expected instanceof FluoriteValue) {
          return expected.equals(actual);
        }
        return actual === expected;
      },

      equalStict: function(actual, expected) {
        return actual === expected;
      },

      contained: function(item, container) {
        if (container instanceof Array) {
          for (var i = 0; i < container.length; i++) {
            if (util.equal(item, container[i])) return true;
          }
          return false;
        }
        if (container instanceof FluoriteObject) {
          item = util.toString(item);
          var values = Object.values(container.map);
          for (var i = 0; i < values.length; i++) {
            if (util.equal(item, values[i])) return true;
          }
          return false;
        }
        if (isString(container)) {
          item = util.toString(item);
          return container.includes(item);
        }
        if (isNumber(container)) {
          item = util.toString(item);
          return String(container).includes(item);
        }
        throw new Error("Illegal argument: " + item + ", " + container);
      },

      containedKey: function(item, container) {
        if (container instanceof Array) {
          item = util.toNumber(item);
          return item >= 0 && item < container.length;
        }
        if (container instanceof FluoriteObject) {
          item = util.toString(item);
          return Object.getOwnPropertyDescriptor(container.map, item) !== undefined;
        }
        if (isString(container)) {
          item = util.toNumber(item);
          return item >= 0 && item < container.length;
        }
        if (isNumber(container)) {
          item = util.toNumber(item);
          return item >= 0 && item < String(container).length;
        }
        throw new Error("Illegal argument: " + item + ", " + container);
      },

      match: function(value, predicate) {
        if (isString(predicate)) {
          return new FluoriteRegExpProvider(predicate, "").match(value);
        }
        if (predicate instanceof FluoriteValue) {
          return predicate.match(value);
        }
        throw new Error("Illegal argument: " + value + ", " + predicate);
      },

      //

      empty: function() {
        return FluoriteStreamerEmpty.instance;
      },

      rangeOpened: function(start, end) {
        return new FluoriteStreamerRange(util.toNumber(start), util.toNumber(end), false);
      },

      rangeClosed: function(start, end) {
        return new FluoriteStreamerRange(util.toNumber(start), util.toNumber(end), true);
      },

      toStreamFromValues: function(values) { // TODO 名称変更
        return new FluoriteStreamerValues(values);
      },

      map: function(streamer, func) { // TODO 仕様変更対応：第一引数はstreamではなくstreamer
        return new FluoriteStreamerMap(streamer, func);
      },

      grep: function(streamer, func) {
        return new FluoriteStreamerGrep(streamer, func);
      },

      //

      toStreamFromArray: function(array) { // TODO 名称変更
        if (array instanceof Array) {
          return new FluoriteStreamerValues(array);
        }
        if (array instanceof FluoriteValue) {
          return array.getStream();
        }
        if (isNumber(array)) {
          array = String(array);
          return util.toStreamFromArray(array.split(""));
        }
        if (isString(array)) {
          return util.toStreamFromArray(array.split(""));
        }
        throw new Error("Illegal argument: " + array); // TODO utilの中のエラーを全部FluRuErrに
      },

      getFromArray: function(array, index) { // TODO 名称変更
        if (array instanceof Array) {
          index = util.toNumber(index);
          if (index < 0) index = array.length + index;
          var result = array[index];
          if (result === undefined) return null;
          return result;
        }
        if (isString(array)) {
          index = util.toNumber(index);
          if (index < 0) index = array.length + index;
          return array.charAt(index);
        }
        if (array instanceof FluoriteObject) {
          return util.getOwnValueFromObject(array, util.toString(index));
        }
        throw new Error("Illegal argument: " + array + ", " + index);
      },

      setToArray: function(array, index, value) { // TODO 名称変更
        if (array instanceof Array) {
          index = util.toNumber(index);
          if (index < 0) index = array.length + index;
          if (index < 0) throw new Error("Invalid array index: " + index);
          if (index > array.length) {
            for (var i = array.length; i < index; i++) {
              array[i] = null;
            }
          }
          array[index] = value;
          return;
        }
        /* // TODO 実装
        if (isString(array)) {
          index = util.toNumber(index);
          if (index < 0) index = array.length + index;
          return array.charAt(index);
        }
        */
        if (array instanceof FluoriteObject) {
          return array.setValue(index, value);
        }
        throw new Error("Illegal argument: " + array + ", " + index);
      },

      //

      createLambda: function(func) { // TODO -> createFunction
        return new FluoriteFunction(func);
      },

      call: function(func, args) {
        if (func instanceof Array) {
          var array = func;
          func = new FluoriteFunction(args => {
            var func2 = array[args.length];
            if (func2 === undefined) throw new Error("Can not resolve function: obj=" + func + ", length=" + args.length);
            return util.call(func2, args);
          });
        }
        if (func instanceof FluoriteValue) {
          return func.call(args);
        }
        throw new Error("Cannot call a non-function object: " + func);
      },

      bind: function(func, value) { // TODO -> bindLeft
        if (func instanceof Array) {
          var array = func;
          func = new FluoriteFunction(args => {
            var func2 = array[args.length];
            if (func2 === undefined) throw new Error("Can not resolve function: obj=" + func + ", length=" + args.length);
            return util.call(func2, args);
          });
        }
        if (func instanceof FluoriteFunction) {
          return func.bind(value);
        }
        throw new Error("Cannot bind a non-function object: " + func);
      },

      curryLeft: function(func, values) { // TODO -> bindLeft
        if (func instanceof Array) {
          var array = func;
          func = new FluoriteFunction(args => {
            var func2 = array[args.length];
            if (func2 === undefined) throw new Error("Can not resolve function: obj=" + func + ", length=" + args.length);
            return util.call(func2, args);
          });
        }
        if (func instanceof FluoriteFunction) {
          return func.bindLeft(values);
        }
        throw new Error("Cannot bind a non-function object: " + func);
      },

      curryRight: function(func, values) { // TODO -> bindRight
        if (func instanceof Array) {
          var array = func;
          func = new FluoriteFunction(args => {
            var func2 = array[args.length];
            if (func2 === undefined) throw new Error("Can not resolve function: obj=" + func + ", length=" + args.length);
            return util.call(func2, args);
          });
        }
        if (func instanceof FluoriteFunction) {
          return func.bindRight(values);
        }
        throw new Error("Cannot bind a non-function object: " + func);
      },

      //

      createObject: function(parent, map) {
        if (parent === null) {
          return new FluoriteObject(null, map);
        }
        if (parent instanceof FluoriteObject) {
          return new FluoriteObject(parent, map);
        }
        throw new Error("Illegal argument: " + parent + ", " + map);
      },
      
      createObjectFromEntries: function(parent, entries) {
        var map = {};
        if (entries instanceof Array) {
          for (var i in entries) {
            var entry = entries[i];
            if (entry instanceof FluoriteObject) {
              var key = util.toString(entry.map.key);
              var value = entry.map.value;
              if (key === undefined) throw new Error("Illegal entry: " + key + ", " + value);
              if (value === undefined) throw new Error("Illegal entry: " + key + ", " + value);
              map[key] = value;
              continue;
            }
            throw new Error("Illegal entry: " + entry + " ([" + i + "])");
          }
          return util.createObject(parent, map);
        }
        throw new Error("Illegal argument: " + parent + ", " + entries);
      },

      initializer: function(func) {
        return new FluoriteObjectInitializer(func);
      },

      getOwnValueFromObject: function(object, key) {
        if (object instanceof FluoriteObject) {
          var descriptor = Object.getOwnPropertyDescriptor(object.map, key);
          if (descriptor !== undefined) {
            if (descriptor.value instanceof FluoriteObjectInitializer) {
              descriptor.value = descriptor.value.get();
            }
            return descriptor.value;
          }
          return null;
        }
        throw new Error("Illegal argument: " + object + ", " + key);
      },

      getValueFromObject: function(object, key) {

        var objectClass;
        if (object instanceof Array) {
          objectClass = this.objects.ARRAY;
        } else if (object instanceof FluoriteObject) {
          objectClass = object;
        } else {
          throw new Error("Illegal argument: " + object + ", " + key);
        }

        while (objectClass !== null) {
          var descriptor = Object.getOwnPropertyDescriptor(objectClass.map, key);
          if (descriptor !== undefined) {
            if (descriptor.value instanceof FluoriteObjectInitializer) {
              descriptor.value = descriptor.value.get();
            }
            return descriptor.value;
          }
          objectClass = objectClass.parent;
        }
        return null;
      },

      getDelegate: function(object, key) {

        var objectClass;
        if (object instanceof Array) {
          objectClass = this.objects.ARRAY;
        } else if (object instanceof FluoriteObject) {
          objectClass = object;
        } else {
          throw new Error("Illegal argument: " + object + ", " + key); // TODO エラーが起こったら引数をログに出す
        }

        while (objectClass !== null) {
          var descriptor = Object.getOwnPropertyDescriptor(objectClass.map, key);
          if (descriptor !== undefined) {
            if (descriptor.value instanceof FluoriteObjectInitializer) {
              descriptor.value = descriptor.value.get();
            }
            return util.bind(descriptor.value, object);
          }
          objectClass = objectClass.parent;
        }
        throw new Error("No such method: " + key + " of " + object);
      },

    };

    return {
      FluoriteRuntimeError,
      FluoriteValue,
      FluoriteStreamer,
      FluoriteStreamerEmpty,
      FluoriteStreamerRange,
      FluoriteStreamerValues,
      FluoriteStreamerMap,
      FluoriteStreamerScalar,
      FluoriteFunction,
      FluoriteObject,
      FluoriteRegExpProvider,
      util,
    };
  })();

  //

  // TODO FluoriteFunction廃止

  function loadAliases(env, objects) { // TODO
    {
      var util = fl7.util;
      var c = (key, value) => {
        var constantId = env.allocateConstantId();
        env.setAlias(key, new fl7c.FluoriteAliasConstant(constantId));
        env.setConstant(constantId, value);
      };
      var m = (key, func) => {
        env.setAlias(key, new fl7c.FluoriteAliasMacro(func));
      };
      var inline = code => ["", code];
      var wrap = (pc, node, func) => {
        var codes = node.getCodeGetter(pc);
        return [
          codes[0],
          func(codes[1]),
        ];
      };
      var wrap2 = (pc, node1, node2, func) => {
        var codes1 = node1.getCodeGetter(pc);
        var codes2 = node2.getCodeGetter(pc);
        return [
          codes1[0] +
          codes2[0],
          func(codes1[1], codes2[1]),
        ];
      };
      var wrap_0 = (e, func) => {
        return wrap(e.pc(), e.arg(0), func);
      };
      var wrap2_01 = (e, func) => {
        return wrap2(e.pc(), e.arg(0), e.arg(1), func);
      };
      var as2c = (pc, node) => {
        if (node instanceof fl7c.FluoriteNodeMacro) {
          if (node.getKey() === "_SEMICOLON") {
            var codesHeader = [];
            var codesBody = [];
            for (var i = 0; i < node.getArgumentCount(); i++) {
              var node2 = node.getArguments()[i];
              if (!(node2 instanceof fl7c.FluoriteNodeVoid)) {
                var codes = node2.getCodeGetter(pc);
                codesHeader.push(codes[0]);
                codesBody.push(codes[1]);
              }
            }
            return [
              codesHeader.join(""),
              codesBody.join(", "),
            ];
          }
        }
        return node.getCodeGetter(pc);
      };
      var as2c2 = (pc, node) => {
        if (node instanceof fl7c.FluoriteNodeMacro) {
          if (node.getKey() === "_ROUND") {
            if (node.getArgument(0) instanceof fl7c.FluoriteNodeMacro) {
              if (node.getArgument(0).getKey() === "_SEMICOLON") {
                var codesHeader = [];
                var codesBody = [];
                for (var i = 0; i < node.getArgument(0).getArgumentCount(); i++) {
                  var node2 = node.getArgument(0).getArguments()[i];
                  if (!(node2 instanceof fl7c.FluoriteNodeVoid)) {
                    var codes = node2.getCodeGetter(pc);
                    codesHeader.push(codes[0]);
                    codesBody.push(codes[1]);
                  }
                }
                return [
                  codesHeader.join(""),
                  codesBody.join(", "),
                ];
              }
            }
          }
        }
        return node.getCodeGetter(pc);
      };
      var getCodeToCreateFluoriteObject = (pc, nodeParent, nodeMap) => {

        // 親オブジェクトの計算
        var codesParent;
        if (nodeParent === null) {
          codesParent = ["", "null"];
        } else {
          codesParent = nodeParent.getCodeGetter(pc);
        }

        var fromInitializer = function(nodesEntry) {
          
          // エントリー列の変換
          var keys = []; // [key : string...]
          var entries = []; // [[key : string, node : Node, delay : boolean]...]
          for (var i = 0; i < nodesEntry.length; i++) {
            var nodeEntry = nodesEntry[i];

            // 宣言文
            if (nodeEntry instanceof fl7c.FluoriteNodeMacro) {
              if (nodeEntry.getKey() === "_COLON") {

                var nodeKey = nodeEntry.getArgument(0);
                var key = undefined;
                if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
                  if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
                    if (nodeKey.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
                      key = nodeKey.getArgument(0).getValue();
                    }
                  }
                }
                if (key === undefined) throw new Error("Illegal object key");

                var nodeValue = nodeEntry.getArgument(1);

                keys.push(key);
                entries.push([key, nodeValue, true]);
                continue;
              }
            }

            // 代入文
            if (nodeEntry instanceof fl7c.FluoriteNodeMacro) {
              if (nodeEntry.getKey() === "_EQUAL") {

                var nodeKey = nodeEntry.getArgument(0);
                var key = undefined;
                if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
                  if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
                    if (nodeKey.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
                      key = nodeKey.getArgument(0).getValue();
                    }
                  }
                }
                if (key === undefined) throw new Error("Illegal object key");

                var nodeValue = nodeEntry.getArgument(1);

                entries.push([key, nodeValue, false]);
                continue;
              }
            }

            // 即席代入文
            if (nodeEntry instanceof fl7c.FluoriteNodeMacro) {
              if (nodeEntry.getKey() === "_LITERAL_IDENTIFIER") {
                if (nodeEntry.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
                  entries.push([nodeEntry.getArgument(0).getValue(), nodeEntry, false]);
                  continue;
                }
              }
            }

            // 空文
            if (nodeEntry instanceof fl7c.FluoriteNodeVoid) {
              continue;
            }

            throw new Error("Illegal object pair");
          }

          var variableIdMap = pc.allocateVariableId();
          var variableMap = "v_" + variableIdMap;
          var variableIdObject = pc.allocateVariableId();
          var variableObject = "v_" + variableIdObject;

          pc.pushFrame();
          for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            pc.getFrame()[key] = new fl7c.FluoriteAliasMember(variableIdObject, key);
          }
          var codesEntries = [];
          for (var i = 0; i < entries.length; i++) {
            var entry = entries[i];
            var codesEntry = entry[1].getCodeGetter(pc);
            if (entry[2]) {
              codesEntries.push(
                "" + variableMap + "[" + JSON.stringify(entry[0]) + "] = util.initializer(function() {\n" +
                fl7c.util.indent(
                  codesEntry[0] +
                  "return " + codesEntry[1] + ";\n"
                ) +
                "});\n"
              );
            } else {
              codesEntries.push(
                codesEntry[0] +
                "" + variableMap + "[" + JSON.stringify(entry[0]) + "] = " + codesEntry[1] + ";\n"
              );
            }
          }
          pc.popFrame();

          return [
            codesParent[0] +
            "const " + variableMap + " = {};\n" +
            "const " + variableObject + " = util.createObject(" + codesParent[1] + ", " + variableMap + ");\n" +
            codesEntries.join("") +
            "" + variableObject + ".initialize();\n",
            "(" + variableObject + ")",
          ];
        };
        var fromStream = function(nodeStreamer) {
          var codesStreamer = nodeStreamer.getCodeGetter(pc);
          return [
            codesParent[0] +
            codesStreamer[0],
            "(util.createObjectFromEntries(" + codesParent[1] + ", util.toStream(" + codesStreamer[1] + ").toArray()))",
          ];
        };
        var fromStreamEmpty = function() {
          return [
            codesParent[0],
            "(util.createObjectFromEntries(" + codesParent[1] + ", []))",
          ];
        };

        //

        if (nodeMap === null) {
          return fromInitializer([]);
        }
        if (nodeMap instanceof fl7c.FluoriteNodeMacro) {
          if (nodeMap.getKey() === "_SEMICOLON") {
            return fromInitializer(nodeMap.getArguments());
          }
          if (nodeMap.getKey() === "_SQUARE") {
            return fromStream(nodeMap.getArgument(0));
          }
          if (nodeMap.getKey() === "_EMPTY_SQUARE") {
            return fromStreamEmpty();
          }
        }
        return fromInitializer([nodeMap]);
      };
      var functionUnpackStreamer = (pc, codeItemOrStreamer, funcCode) => {
        var variableItemOrStreamer = "v_" + pc.allocateVariableId();
        var variableStream = "v_" + pc.allocateVariableId();
        var variableItem = "v_" + pc.allocateVariableId();

        pc.pushFrame();
        var codeOnStreamer = funcCode(pc, variableItem);
        pc.popFrame();

        pc.pushFrame();
        var codeOnNotStreamer = funcCode(pc, variableItemOrStreamer);
        pc.popFrame();

        return (
          "let " + variableItemOrStreamer + " = " + codeItemOrStreamer + ";\n" +
          "if (!(" + variableItemOrStreamer + " instanceof fl7.FluoriteStreamer)) {\n" +
          fl7c.util.indent(
            "" + variableItemOrStreamer + " = new fl7.FluoriteStreamerScalar(" + variableItemOrStreamer + ");\n"
          ) +
          "}\n" +
          "let " + variableStream + " = " + variableItemOrStreamer + ".start();\n" +
          "while (true) {\n" +
          fl7c.util.indent(
            "let " + variableItem + " = " + variableStream + ".next();\n" +
            "if (" + variableItem + " === undefined) break;\n" +
            codeOnStreamer
          ) +
          "}\n"
        );
      };
      c("PI", Math.PI);
      c("E", Math.E);
      c("NAN", NaN);
      c("INFINITY", Infinity);
      c("FLOOR", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return Math.floor(util.toNumber(args[0]));
        }
        throw new Error("Illegal argument");
      }));
      c("CEIL", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return Math.ceil(util.toNumber(args[0]));
        }
        throw new Error("Illegal argument");
      }));
      c("EXP", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return Math.exp(util.toNumber(args[0]));
        }
        throw new Error("Illegal argument");
      }));
      c("SQRT", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return Math.sqrt(util.toNumber(args[0]));
        }
        throw new Error("Illegal argument");
      }));
      c("ABS", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return Math.abs(util.toNumber(args[0]));
        }
        throw new Error("Illegal argument");
      }));
      c("SIN", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return Math.sin(util.toNumber(args[0]));
        }
        throw new Error("Illegal argument");
      }));
      c("COS", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return Math.cos(util.toNumber(args[0]));
        }
        throw new Error("Illegal argument");
      }));
      c("TAN", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return Math.tan(util.toNumber(args[0]));
        }
        throw new Error("Illegal argument");
      }));
      c("LOG", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return Math.log(util.toNumber(args[0]));
        }
        if (args.length == 2) {
          return Math.log(util.toNumber(args[0])) / Math.log(util.toNumber(args[1]));
        }
        throw new Error("Illegal argument");
      }));
      c("OUT", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          var stream = util.toStream(args[0]).start();
          while (true) {
            var next = stream.next();
            if (next === undefined) break;
            console.log(util.toString(next));
          }
          return null;
        }
        throw new Error("Illegal argument");
      }));
      c("TRUE", true);
      c("FALSE", false);
      c("NULL", null);
      c("RAND", new fl7.FluoriteFunction(args => {
        if (args.length == 0) {
          return Math.random();
        }
        if (args.length == 1) {
          var max = util.toNumber(args[0]);
          return Math.floor(Math.random() * max);
        }
        if (args.length == 2) {
          var min = util.toNumber(args[0]);
          var max = util.toNumber(args[1]);
          return Math.floor(Math.random() * (max - min)) + min;
        }
        throw new Error("Illegal argument");
      }));
      c("ADD", new fl7.FluoriteFunction(args => {
        var stream = args[0];
        if (stream === undefined) throw new Error("Illegal argument");
        stream = util.toStream(stream).start();
        var result = 0;
        while (true) {
          var next = stream.next();
          if (next === undefined) break;
          result += util.toNumber(next);
        }
        return result;
      }));
      c("MUL", new fl7.FluoriteFunction(args => {
        var stream = args[0];
        if (stream === undefined) throw new Error("Illegal argument");
        stream = util.toStream(stream).start();
        var result = 1;
        while (true) {
          var next = stream.next();
          if (next === undefined) break;
          result *= util.toNumber(next);
        }
        return result;
      }));
      objects.ARRAY = fl7.util.createObject(null, {
        CALL: new fl7.FluoriteFunction(args => {
          var value = args[1];
          if (value === undefined) throw new Error("Illegal argument");
          return util.toStream(value).toArray();
        }),
        remove:  new fl7.FluoriteFunction(args => {
          if (args.length != 2) throw new Error("Illegal argument count: " + args.length);
          var array = args[0];
          if (!(array instanceof Array)) throw new Error("Illegal argument type: " + array);
          var index = args[1];
          index = util.toNumber(index);

          if (array.length < 1) throw new Error("Illegal array length: " + array.length);
          if (index < 0) index += array.length;
          if (index < 0) throw new Error("Illegal index: " + index + " < " + 0);
          if (index >= array.length) throw new Error("Illegal index: " + index + " >= " + array.length);

          var value = array[index];
          array.splice(index, 1);
          return value;
        }),
        removeFirst:  new fl7.FluoriteFunction(args => {
          if (args.length != 1) throw new Error("Illegal argument count: " + args.length);
          var array = args[0];
          if (!(array instanceof Array)) throw new Error("Illegal argument type: " + array);

          if (array.length < 1) throw new Error("Illegal array length: " + array.length);

          var index = 0;
          var value = array[index];
          array.splice(index, 1);
          return value;
        }),
        removeLast:  new fl7.FluoriteFunction(args => {
          if (args.length != 1) throw new Error("Illegal argument count: " + args.length);
          var array = args[0];
          if (!(array instanceof Array)) throw new Error("Illegal argument type: " + array);

          if (array.length < 1) throw new Error("Illegal array length: " + array.length);

          var index = array.length - 1;
          var value = array[index];
          array.splice(index, 1);
          return value;
        }),
        removeRandom:  new fl7.FluoriteFunction(args => {
          if (args.length != 1) throw new Error("Illegal argument count: " + args.length);
          var array = args[0];
          if (!(array instanceof Array)) throw new Error("Illegal argument type: " + array);

          if (array.length < 1) throw new Error("Illegal array length: " + array.length);

          var index = Math.floor(Math.random() * array.length);
          var value = array[index];
          array.splice(index, 1);
          return value;
        }),
      });
      c("ARRAY", objects.ARRAY);
      c("STRING", new fl7.FluoriteFunction(args => {
        var value = args[0];
        if (value === undefined) throw new Error("Illegal argument");
        return util.toString(value);
      }));
      c("NUMBER", new fl7.FluoriteFunction(args => {
        var value = args[0];
        if (value === undefined) throw new Error("Illegal argument");
        return util.toNumber(value);
      }));
      c("BOOLEAN", new fl7.FluoriteFunction(args => {
        var value = args[0];
        if (value === undefined) throw new Error("Illegal argument");
        return util.toBoolean(value);
      }));
      c("JOIN", new fl7.FluoriteFunction(args => {
        var delimiter = args[1];
        if (delimiter === undefined) delimiter = ",";
        delimiter = util.toString(delimiter);

        var stream = args[0];
        if (stream === undefined) throw new Error("Illegal argument");
        stream = util.toStream(stream);

        return stream.toArray().join(delimiter);
      }));
      c("SPLIT", new fl7.FluoriteFunction(args => {

        var string = args[0];
        if (string === undefined) throw new Error("Illegal argument");
        string = util.toString(string);

        var delimiter = args[1];
        if (delimiter === undefined) delimiter = ",";
        if (delimiter instanceof fl7.FluoriteRegExpProvider) {
          delimiter = delimiter.create();
        } else {
          delimiter = util.toString(delimiter);
        }

        var limit = args[2];

        return util.toStreamFromValues(string.split(delimiter, limit));
      }));
      c("MAX", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var comparator = args[1];
        if (comparator === undefined) comparator = null;

        var max = undefined;
        var stream = streamer.start();
        while (true) {
          var item = stream.next();
          if (item === undefined) break;
          if (max === undefined) {
            max = item;
          } else {
            var i = comparator !== null ? util.toNumber(util.call(comparator, [item, max])) : util.compare(item, max);
            if (i > 0) {
              max = item;
            }
          }
        }

        return max === undefined ? null : max;
      }));
      c("MAX_BY", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var keySelector = args[1];
        if (keySelector === undefined) keySelector = null;

        var max = undefined;
        var maxKey = undefined;
        var stream = streamer.start();
        while (true) {
          var item = stream.next();
          if (item === undefined) break;
          if (maxKey === undefined) {
            max = item;
            maxKey = keySelector !== null ? util.call(keySelector, [item]) : item;
          } else {
            var key = keySelector !== null ? util.call(keySelector, [item]) : item;
            if (util.compare(key, maxKey) > 0) {
              max = item;
              maxKey = key;
            }
          }
        }

        return max === undefined ? null : max;
      }));
      c("MIN", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var comparator = args[1];
        if (comparator === undefined) comparator = null;

        var max = undefined;
        var stream = streamer.start();
        while (true) {
          var item = stream.next();
          if (item === undefined) break;
          if (max === undefined) {
            max = item;
          } else {
            var i = comparator !== null ? util.toNumber(util.call(comparator, [item, max])) : util.compare(item, max);
            if (i < 0) {
              max = item;
            }
          }
        }

        return max === undefined ? null : max;
      }));
      c("MIN_BY", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var keySelector = args[1];
        if (keySelector === undefined) keySelector = null;

        var max = undefined;
        var maxKey = undefined;
        var stream = streamer.start();
        while (true) {
          var item = stream.next();
          if (item === undefined) break;
          if (maxKey === undefined) {
            max = item;
            maxKey = keySelector !== null ? util.call(keySelector, [item]) : item;
          } else {
            var key = keySelector !== null ? util.call(keySelector, [item]) : item;
            if (util.compare(key, maxKey) < 0) {
              max = item;
              maxKey = key;
            }
          }
        }

        return max === undefined ? null : max;
      }));
      c("SORT", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var comparator = args[1];
        if (comparator === undefined) comparator = null;

        var array = streamer.toArray().map((item, i) => [i, item]);
        array = array.sort((a, b) => {
          var i = comparator !== null ? util.toNumber(util.call(comparator, [a[1], b[1]])) : util.compare(a[1], b[1]);
          if (i > 0) return 1;
          if (i < 0) return -1;
          if (a[0] > b[0]) return 1;
          if (a[0] < b[0]) return -1;
          return 0;
        });

        return util.toStreamFromValues(array.map(item => item[1]));
      }));
      c("SORT_BY", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var keySelector = args[1];
        if (keySelector === undefined) keySelector = null;

        var array = streamer.toArray().map((item, i) => [i, item, undefined]);
        array = array.sort((a, b) => {
          if (a[2] === undefined) a[2] = keySelector !== null ? util.call(keySelector, [a[1]]) : a[1];
          if (b[2] === undefined) b[2] = keySelector !== null ? util.call(keySelector, [b[1]]) : b[1];
          var i = util.compare(a[2], b[2]);
          if (i > 0) return 1;
          if (i < 0) return -1;
          if (a[0] > b[0]) return 1;
          if (a[0] < b[0]) return -1;
          return 0;
        });

        return util.toStreamFromValues(array.map(item => item[1]));
      }));
      c("SORTR", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var comparator = args[1];
        if (comparator === undefined) comparator = null;

        var array = streamer.toArray().map((item, i) => [i, item]);
        array = array.sort((a, b) => {
          var i = comparator !== null ? util.toNumber(util.call(comparator, [a[1], b[1]])) : util.compare(a[1], b[1]);
          if (i < 0) return 1;
          if (i > 0) return -1;
          if (a[0] > b[0]) return 1;
          if (a[0] < b[0]) return -1;
          return 0;
        });

        return util.toStreamFromValues(array.map(item => item[1]));
      }));
      c("SORTR_BY", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var keySelector = args[1];
        if (keySelector === undefined) keySelector = null;

        var array = streamer.toArray().map((item, i) => [i, item, undefined]);
        array = array.sort((a, b) => {
          if (a[2] === undefined) a[2] = keySelector !== null ? util.call(keySelector, [a[1]]) : a[1];
          if (b[2] === undefined) b[2] = keySelector !== null ? util.call(keySelector, [b[1]]) : b[1];
          var i = util.compare(a[2], b[2]);
          if (i < 0) return 1;
          if (i > 0) return -1;
          if (a[0] > b[0]) return 1;
          if (a[0] < b[0]) return -1;
          return 0;
        });

        return util.toStreamFromValues(array.map(item => item[1]));
      }));
      c("GROUP", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var matcher = args[1];
        if (matcher === undefined) matcher = null;

        var array = [];
        var stream = streamer.start();
        a:
        while (true) {
          var next = stream.next();
          if (next === undefined) break;
          for (var i = 0; i < array.length; i++) {
            var array2 = array[i];
            var a = array2[0];
            var b = next;
            if (matcher != null ? util.call(matcher, [a, b]) : util.equal(b, a)) {
              array2[array2.length] = next;
              continue a;
            }
          }
          array[array.length] = [next];
        }

        return util.toStreamFromValues(array);
      }));
      c("GROUP_BY", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var keySelector = args[1];
        if (keySelector === undefined) throw new Error("Illegal argument");

        var array = [];
        var stream = streamer.start();
        a:
        while (true) {
          var next = stream.next();
          if (next === undefined) break;
          for (var i = 0; i < array.length; i++) {
            var array2 = array[i];
            var a = util.call(keySelector, [array2[0]]);
            var b = util.call(keySelector, [next]);
            if (util.equal(b, a)) {
              array2[array2.length] = next;
              continue a;
            }
          }
          array[array.length] = [next];
        }

        return util.toStreamFromValues(array);
      }));
      c("JSON", new fl7.FluoriteFunction(args => {

        var value = args[0];
        if (value === undefined) throw new Error("Illegal argument");

        var indent = args[1];
        if (indent === undefined) {
          indent = null;
        } else if (isNumber(indent)) {
        } else if (isString(indent)) {
        } else {
          throw new Error("Illegal argument");
        }

        return JSON.stringify(value, null, indent);
      }));
      c("FROM_JSON", new fl7.FluoriteFunction(args => {
        var value = args[0];
        if (value === undefined) throw new Error("Illegal argument");
        return JSON.parse(util.toString(value), (k, v) => {
          if (typeof v === "object" && v !== null && !Array.isArray(v)) return util.createObject(null, v);
          return v;
        });
      }));
      c("REVERSE", new fl7.FluoriteFunction(args => {
        var stream = args[0];
        if (stream === undefined) throw new Error("Illegal argument");
        return util.toStreamFromValues(util.toStream(stream).toArray().reverse());
      }));
      c("CHARCODES", new fl7.FluoriteFunction(args => {
        var string = args[0];
        string = util.toString(string);
        var result = [];
        for (var i = 0; i < string.length; i++) {
          result[i] = string.charCodeAt(i);
        }
        return result;
      }));
      c("FROM_CHARCODES", new fl7.FluoriteFunction(args => {
        var array = args[0];
        if (!(array instanceof Array)) throw new Error("Illegal argument");
        return String.fromCharCode.apply(null, array);
      }));
      c("YN", new fl7.FluoriteFunction(args => {
        return util.toBoolean(args[0]) ? "Yes" : "No";
      }));
      c("TRIM", new fl7.FluoriteFunction(args => {
        if (args[0] === undefined) throw new Error("Illegal argument");
        return util.toString(args[0]).trim();
      }));
      c("ENTRY", new fl7.FluoriteFunction(args => {
        if (args[0] === undefined) throw new Error("Illegal argument");
        if (args[1] === undefined) throw new Error("Illegal argument");
        return new fl7.FluoriteObject(null, {
          key: args[0],
          value: args[1],
        });
      }));
      c("KEYS", new fl7.FluoriteFunction(args => {
        if (args[0] instanceof fl7.FluoriteObject) {
          return util.toStreamFromValues(Object.keys(args[0].map));
        }
        throw new Error("Illegal argument");
      }));
      c("VALUES", new fl7.FluoriteFunction(args => {
        if (args[0] instanceof fl7.FluoriteObject) {
          return util.toStreamFromValues(Object.values(args[0].map));
        }
        throw new Error("Illegal argument");
      }));
      c("UC", new fl7.FluoriteFunction(args => {
        if (args.length != 1) throw new Error("Illegal argument");
        return util.toString(args[0]).toUpperCase();
      }));
      c("LC", new fl7.FluoriteFunction(args => {
        if (args.length != 1) throw new Error("Illegal argument");
        return util.toString(args[0]).toLowerCase();
      }));
      c("UNIT_d", new fl7.FluoriteFunction(args => {
        var count;
        var faces;
        if (args.length == 1) {
          count = util.toNumber(args[0]);
          faces = 6;
        } else if (args.length == 2) {
          count = util.toNumber(args[0]);
          faces = util.toNumber(args[1]);
        } else {
          throw new Error("Illegal argument");
        }

        var j = 0;
        for (var i = 0; i < count; i++) {
          j += Math.floor(Math.random() * faces) + 1;
        }
        return j;
      }));
      c("TYPE", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          var value = args[0];
          if (value === null) return "NULL";
          if (isNumber(value)) return "NUMBER";
          if (isString(value)) return "STRING";
          if (typeof value === 'boolean') return "BOOLEAN";
          if (value instanceof Array) return "ARRAY";
          if (value instanceof fl7.FluoriteValue) return value.getType();
          return "UNKNOWN";
        }
        throw new Error("Illegal argument");
      }));
      m("_LITERAL_INTEGER", e => {
        if (e.arg(0) instanceof fl7c.FluoriteNodeTokenInteger) {
          return inline("(" + e.arg(0).getValue() + ")");
        }
        throw new Error("Illegal argument");
      });
      m("_LITERAL_BASED_INTEGER", e => {
        if (e.arg(0) instanceof fl7c.FluoriteNodeTokenBasedInteger) {
          return inline("(" + e.arg(0).getValue() + ")");
        }
        throw new Error("Illegal argument");
      });
      m("_LITERAL_FLOAT", e => {
        if (e.arg(0) instanceof fl7c.FluoriteNodeTokenFloat) {
          return inline("(" + e.arg(0).getValue() + ")");
        }
        throw new Error("Illegal argument");
      });
      m("_LITERAL_IDENTIFIER", e => {
        var nodeKey = e.arg(0);
        if (nodeKey instanceof fl7c.FluoriteNodeTokenIdentifier) {
          var key = nodeKey.getValue();
          var alias = e.pc().getAliasOrUndefined(e.node().getLocation(), key);
          if (alias === undefined) return JSON.stringify(key); // throw new Error("No such alias '" + key + "'");
          return alias.getCodeGetter(e.pc(), e.node().getLocation());
        }
        throw new Error("Illegal argument");
      });
      m("_SET_LITERAL_IDENTIFIER", (e, code) => {
        var nodeKey = e.arg(0);
        if (nodeKey instanceof fl7c.FluoriteNodeTokenIdentifier) {
          var key = nodeKey.getValue();
          var alias = e.pc().getAliasOrUndefined(e.node().getLocation(), key);
          if (alias === undefined) throw new Error("No such alias: name=" + key);
          if (alias instanceof fl7c.FluoriteAliasVariableSettable) {
            return [
              "" + alias.getCode() + " = " + code + ";\n",
            ];
          }
          throw new Error("Cannot assign: variable=" + alias);
        }
        throw new Error("Illegal argument");
      });
      m("_LITERAL_PATTERN_STRING", e => {
        if (e.arg(0) instanceof fl7c.FluoriteNodeTokenPattern) {
          return inline("(new fl7.FluoriteRegExpProvider(" + JSON.stringify(e.arg(0).getValue()) + ", " + JSON.stringify(e.arg(0).getOption()) + "))");
        }
        throw new Error("Illegal argument");
      });
      m("_LITERAL_STRING", e => {
        if (e.arg(0) instanceof fl7c.FluoriteNodeTokenString) {
          return inline("(" + JSON.stringify(e.arg(0).getValue()) + ")");
        }
        throw new Error("Illegal argument");
      });
      m("_LITERAL_EMBEDDED_STRING", e => {
        var codesHeader = [];
        var codesBody = [];
        var nodes = e.node().getArguments();
        for (var i = 0; i < nodes.length; i++) {
          var node = nodes[i];
          if (node instanceof fl7c.FluoriteNodeTokenString) {
            codesBody.push(JSON.stringify(node.getValue()));
          } else {
            var codes = node.getCodeGetter(e.pc());
            codesHeader.push(codes[0]);
            codesBody.push("util.toString(" + codes[1] + ")");
          }
        }
        if (codesBody.length !== 0) {
          return [
            codesHeader.join(""),
            "(" + codesBody.join(" + ") + ")",
          ];
        } else {
          return [
            codesHeader.join(""),
            "(\"\")",
          ];
        }
      });
      m("_LITERAL_HERE_DOCUMENT", e => {
        if (e.arg(0) instanceof fl7c.FluoriteNodeTokenString) {
          return inline("(" + JSON.stringify(e.arg(0).getValue()) + ")");
        }
        throw new Error("Illegal argument");
      });
      m("_STRING_FORMAT", e => {

        var format = undefined;
        if (e.arg(0) instanceof fl7c.FluoriteNodeTokenFormat) {
          format = e.arg(0).getValue();
        }
        if (format === undefined) throw new Error("Illegal argument");

        var node = e.arg(1);

        return wrap(e.pc(), node, c => "(util.format(" + JSON.stringify(format) + ", " + c + "))");
      });
      m("_COMPOSITE", e => {

        var count = e.node().getArgumentCount();
        if (count < 1) throw new Error("Illegal argument count: " + count);

        var getCodeGetterOfNumber = node => {
          if (node instanceof fl7c.FluoriteNodeTokenInteger) {
            return inline("(" + node.getValue() + ")");
          }
          if (node instanceof fl7c.FluoriteNodeTokenFloat) {
            return inline("(" + node.getValue() + ")");
          }
          throw new Error("Illegal argument of number: " + node);
        };
        var getCodeGetterOfIdentifier = node => {
          if (node instanceof fl7c.FluoriteNodeTokenIdentifier) {
            a:
            {
              var key = "UNIT_" + node.getValue();
              var alias = e.pc().getAliasOrUndefined(node.getLocation(), key);
              if (alias === undefined) break a;
              return alias.getCodeGetter(e.pc(), node.getLocation());
            }
            a:
            {
              var key = node.getValue();
              var alias = e.pc().getAliasOrUndefined(node.getLocation(), key);
              if (alias === undefined) break a;
              return alias.getCodeGetter(e.pc(), node.getLocation());
            }
            throw new Error("No such alias '" + key + "'");
          }
          throw new Error("Illegal argument of identifier: " + node);
        };
        var call = (codeFunction, codesArg) => {
          return [
            codeFunction[0] +
            codesArg.map(code => code[0]).join(""),
            "(util.call(" + codeFunction[1] + ", [" + codesArg.map(code => code[1]).join(", ") + "]))",
          ];
        };

        var codeResult = getCodeGetterOfNumber(e.node().getArgument(0));

        for (var i = 1; i < count; i += 2) {
          if (i + 1 >= count) {
            var codeBody = getCodeGetterOfIdentifier(e.node().getArgument(i));
            codeResult = call(codeBody, [codeResult]);
          } else {
            var codeBody = getCodeGetterOfIdentifier(e.node().getArgument(i));
            var codeTail = getCodeGetterOfNumber(e.node().getArgument(i + 1));
            codeResult = call(codeBody, [codeResult, codeTail]);
          }
        }

        return codeResult;
      });
      m("_ROUND", e => {

        var variable = "v_" + e.pc().allocateVariableId();

        e.pc().pushFrame();
        var codes = e.arg(0).getCodeGetter(e.pc());
        e.pc().popFrame();

        return [
          "let " + variable + " = null;\n" +
          "{\n" +
          fl7c.util.indent(
            codes[0] +
            "" + variable + " = " + codes[1] + ";\n"
          ) +
          "}\n",
          "(" + variable + ")",
        ];
      });
      m("_ITERATE_ROUND", (e, funcCode) => {

        e.pc().pushFrame();
        var codes = e.arg(0).getCodeIterator(e.pc(), funcCode);
        e.pc().popFrame();

        return [
          "{\n" +
          fl7c.util.indent(
            codes[0]
          ) +
          "}\n",
        ];
      });
      m("_EMPTY_ROUND", e => inline("(util.empty())"));
      m("_SQUARE", e => {

        var nodeElements = e.arg(0);

        var nodesElement = [];
        a:
        {

          if (nodeElements instanceof fl7c.FluoriteNodeMacro) {
            if (nodeElements.getKey() === "_SEMICOLON") {
              for (var i = 0; i < nodeElements.getArgumentCount(); i++) {
                nodesElement.push(nodeElements.getArgument(i));
              }
              break a;
            }
          }

          nodesElement.push(nodeElements);
        }

        var nodesStreamer = [];
        var entriesAssignment = [];
        for (var i = 0; i < nodesElement.length; i++) {
          var nodeElement = nodesElement[i];

          if (nodeElement instanceof fl7c.FluoriteNodeMacro) {
            if (nodeElement.getKey() === "_COLON") {
              var nodeKey = nodeElement.getArgument(0);
              var nodeValue = nodeElement.getArgument(1);
              if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
                if (nodeKey.getKey() === "_LITERAL_INTEGER") {
                  if (nodeKey.getArgument(0) instanceof fl7c.FluoriteNodeTokenInteger) {
                    entriesAssignment.push([nodeKey.getArgument(0).getValue(), nodeValue]);
                    continue;
                  }
                }
              }
              throw new Error("Illegal array assignment element key: " + nodeKey);
            }
          }

          if (nodeElement instanceof fl7c.FluoriteNodeMacro) { // TODO
            if (nodeElement.getKey() === "_EQUAL") {
              throw new Error("Illegal array element: " + nodeElement);
            }
          }

          if (nodeElement instanceof fl7c.FluoriteNodeVoid) {
            continue;
          }

          nodesStreamer.push(nodeElement);
        }

        var variable = "v_" + e.pc().allocateVariableId();
        return [
          "const " + variable + " = [];\n" +
          nodesStreamer.map(nodeStreamer => {
            return nodeStreamer.getCodeIterator(e.pc(), codeItemOrStreamer => {
              return functionUnpackStreamer(e.pc(), codeItemOrStreamer, (pc, codeItem) => {
                return "" + variable + "[" + variable + ".length] = " + codeItem + ";\n";
              });
            })[0];
          }).join("") +
          entriesAssignment.map(entryAssignment => {
            var code = entryAssignment[1].getCodeGetter(e.pc());
            return (
              code[0] +
              "util.setToArray(" + variable + ", " + entryAssignment[0] + ", " + code[1] + ");\n"
            );
          }).join(""),
          "(" + variable + ")",
        ];
      });
      m("_EMPTY_SQUARE", e => inline("([])"));
      m("_CURLY", e => getCodeToCreateFluoriteObject(e.pc(), null, e.arg(0)));
      m("_EMPTY_CURLY", e => getCodeToCreateFluoriteObject(e.pc(), null, null));
      m("_PERIOD", e => {

        var nodeObject = e.arg(0);
        var nodeKey = e.arg(1);

        var key = undefined;
        if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
          if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
            if (nodeKey.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
              key = nodeKey.getArgument(0).getValue();
            }
          }
        }
        if (key === undefined) throw new Error("Illegal member access key");

        return wrap(e.pc(), nodeObject, c => "(util.getValueFromObject(" + c + ", " + JSON.stringify(key) + "))");
      });
      m("_SET_PERIOD", (e, code) => {

        var codesLeft = e.arg(0).getCodeGetter(e.pc());

        var nodeKey = e.arg(1);
        var key = undefined;
        if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
          if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
            if (nodeKey.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
              key = nodeKey.getArgument(0).getValue();
            }
          }
        }
        if (key === undefined) throw new Error("Illegal member access key");

        return [
          codesLeft[0] +
          "util.setToArray(" + codesLeft[1] + ", " + JSON.stringify(key) + ", " + code + ");\n",
        ];
      });
      m("_COLON2", e => {

        var nodeObject = e.arg(0);
        var nodeKey = e.arg(1);

        var key = undefined;
        if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
          if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
            if (nodeKey.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
              key = nodeKey.getArgument(0).getValue();
            }
          }
        }
        if (key === undefined) throw new Error("Illegal member access key");

        return wrap(e.pc(), nodeObject, c => "(util.getDelegate(" + c + ", " + JSON.stringify(key) + "))");
      });
      m("_RIGHT_ROUND", e => {
        var codesFunction = e.arg(0).getCodeGetter(e.pc());
        var codesArguments = as2c(e.pc(), e.node().getArgument(1));
        return [
          codesFunction[0] +
          codesArguments[0],
          "(util.call(" + codesFunction[1] + ", [" + codesArguments[1] + "]))",
        ];
      });
      m("_RIGHT_EMPTY_ROUND", e => wrap_0(e, c => "(util.call(" + c + ", []))"));
      m("_RIGHT_SQUARE", e => {

        {
          var nodeRight = e.arg(1);
          if (nodeRight instanceof fl7c.FluoriteNodeMacro) {
            if (nodeRight.getKey() == "_SEMICOLON") {
              if (nodeRight.getArgumentCount() == 2) {
                var nodeStart = nodeRight.getArgument(0);
                var nodeEnd = nodeRight.getArgument(1);

                var codesStart = undefined;
                if (nodeStart instanceof fl7c.FluoriteNodeVoid) {
                  codesStart = inline("(null)");
                } else {
                  codesStart = nodeStart.getCodeGetter(e.pc());
                }

                var codesEnd = undefined;
                if (nodeEnd instanceof fl7c.FluoriteNodeVoid) {
                  codesEnd = inline("(null)");
                } else {
                  codesEnd = nodeEnd.getCodeGetter(e.pc());
                }

                var codesLeft = e.arg(0).getCodeGetter(e.pc());
                return [
                  codesLeft[0] +
                  codesStart[0] +
                  codesEnd[0],
                  "(util.slice(" + codesLeft[1] + ", " + codesStart[1] + ", " + codesEnd[1] + "))",
                ];
              }
            }
          }
        }

        var codesLeft = e.arg(0).getCodeGetter(e.pc());
        var codesRight = e.arg(1).getCodeGetter(e.pc());
        return [
          codesLeft[0] +
          codesRight[0],
          "(util.getFromArray(" + codesLeft[1] + ", " + codesRight[1] + "))",
        ];
      });
      m("_SET_RIGHT_SQUARE", (e, code) => {

        // TODO 部分配列への代入
        /*
        {
          var nodeRight = e.arg(1);
          if (nodeRight instanceof fl7c.FluoriteNodeMacro) {
            if (nodeRight.getKey() == "_SEMICOLON") {
              if (nodeRight.getArgumentCount() == 2) {
                var nodeStart = nodeRight.getArgument(0);
                var nodeEnd = nodeRight.getArgument(1);

                var codesStart = undefined;
                if (nodeStart instanceof fl7c.FluoriteNodeVoid) {
                  codesStart = inline("(null)");
                } else {
                  codesStart = nodeStart.getCodeGetter(e.pc());
                }

                var codesEnd = undefined;
                if (nodeEnd instanceof fl7c.FluoriteNodeVoid) {
                  codesEnd = inline("(null)");
                } else {
                  codesEnd = nodeEnd.getCodeGetter(e.pc());
                }

                var codesLeft = e.arg(0).getCodeGetter(e.pc());
                return [
                  codesLeft[0] + codesStart[0] + codesEnd[0],
                  "(util.slice(" + codesLeft[1] + ", " + codesStart[1] + ", " + codesEnd[1] + "))",
                ];
              }
            }
          }
        }
        */

        var codesLeft = e.arg(0).getCodeGetter(e.pc());
        var codesRight = e.arg(1).getCodeGetter(e.pc());
        return [
          codesLeft[0] +
          codesRight[0] +
          "util.setToArray(" + codesLeft[1] + ", " + codesRight[1] + ", " + code + ");\n",
        ];
      });
      m("_RIGHT_EMPTY_SQUARE", e => wrap_0(e, c => "(util.toStreamFromArray(" + c + "))"));
      m("_RIGHT_CURLY", e => getCodeToCreateFluoriteObject(e.pc(), e.arg(0), e.node().getArgument(1)));
      m("_RIGHT_EMPTY_CURLY", e => getCodeToCreateFluoriteObject(e.pc(), e.arg(0), null));
      m("_LEFT_PLUS", e => wrap_0(e, c => "(util.toNumber(" + c + "))"));
      m("_LEFT_MINUS", e => wrap_0(e, c => "(-util.toNumber(" + c + "))"));
      m("_LEFT_QUESTION", e => wrap_0(e, c => "(util.toBoolean(" + c + "))"));
      m("_LEFT_EXCLAMATION", e => wrap_0(e, c => "(!util.toBoolean(" + c + "))"));
      m("_LEFT_AMPERSAND", e => wrap_0(e, c => "(util.toString(" + c + "))"));
      m("_LEFT_ASTERISK", e => {
        var codesLeft = e.arg(0).getCodeGetter(e.pc());
        var codesAlias = e.pc().getAlias(e.node().getLocation(), "_").getCodeGetter(e.pc(), e.node().getLocation());
        return [
          codesLeft[0] +
          codesAlias[0],
          "(util.call(" + codesLeft[1] + ",[" + codesAlias[1] + "]))",
        ];
      });
      m("_LEFT_BACKSLASH", e => {
        var alias = new fl7c.FluoriteAliasVariable(e.pc().allocateVariableId());

        e.pc().pushFrame();
        e.pc().nextLabelFrame();
        e.pc().getFrame()["_"] = alias;
        var codes = e.arg(0).getCodeGetter(e.pc());
        e.pc().prevLabelFrame();
        e.pc().popFrame();

        var codeBody =
          "if (args.length != 1) throw new Error(\"Number of lambda arguments do not match: \" + args.length + \" != 1\");\n" +
          "const " + alias.getRawCode(e.pc(), e.node().getLocation()) + " = args[0];\n" +
          codes[0] +
          "return " + codes[1] + ";";

        return inline(
          "(util.createLambda(function(args) {\n" +
          fl7c.util.indent(
            codeBody
          ) +
          "\n}))"
        );
      });
      m("_LEFT_DOLLAR_HASH", e => wrap_0(e, c => "(util.getLength(" + c + "))"));
      m("_CIRCUMFLEX", e => wrap2_01(e, (c0, c1) => "(Math.pow(" + c0 + ", " + c1 + "))"));
      m("_ASTERISK", e => wrap2_01(e, (c0, c1) => "(util.asterisk(" + c0 + ", " + c1 + "))"));
      m("_SLASH", e => wrap2_01(e, (c0, c1) => "(util.slash(" + c0 + ", " + c1 + "))"));
      m("_PERCENT", e => wrap2_01(e, (c0, c1) => "(" + c0 + " % " + c1 + ")"));
      m("_PLUS", e => wrap2_01(e, (c0, c1) => "(util.plus(" + c0 + ", " + c1 + "))"));
      m("_MINUS", e => wrap2_01(e, (c0, c1) => "(util.minus(" + c0 + ", " + c1 + "))"));
      m("_AMPERSAND", e => wrap2_01(e, (c0, c1) => "(util.toString(" + c0 + ") + util.toString(" + c1 + "))"));
      m("_TILDE", e => wrap2_01(e, (c0, c1) => "(util.rangeOpened(" + c0 + ", " + c1 + "))"));
      m("_PERIOD2", e => wrap2_01(e, (c0, c1) => "(util.rangeClosed(" + c0 + ", " + c1 + "))"));
      m("_LESS2", e => {
        var codesLeft = e.arg(0).getCodeGetter(e.pc());
        var codesRight = as2c2(e.pc(), e.arg(1));
        return [
          codesLeft[0] +
          codesRight[0],
          "(util.curryLeft(" + codesLeft[1] + ", [" + codesRight[1] + "]))",
        ];
      });
      m("_GREATER2", e => {
        var codesLeft = e.arg(0).getCodeGetter(e.pc());
        var codesRight = as2c2(e.pc(), e.arg(1));
        return [
          codesLeft[0] +
          codesRight[0],
          "(util.curryRight(" + codesLeft[1] + ", [" + codesRight[1] + "]))",
        ];
      });
      m("_LESS_EQUAL_GREATER", e => wrap2_01(e, (c0, c1) => "(util.compare(" + c0 + ", " + c1 + "))"));
      m("_GREATER_EQUAL", e => wrap2_01(e, (c0, c1) => "(util.compare(" + c0 + ", " + c1 + ") >= 0)")); // TODO 同時評価
      m("_LESS_EQUAL", e => wrap2_01(e, (c0, c1) => "(util.compare(" + c0 + ", " + c1 + ") <= 0)"));
      m("_GREATER", e => wrap2_01(e, (c0, c1) => "(util.compare(" + c0 + ", " + c1 + ") > 0)"));
      m("_LESS", e => wrap2_01(e, (c0, c1) => "(util.compare(" + c0 + ", " + c1 + ") < 0)"));
      m("_EQUAL2", e => wrap2_01(e, (c0, c1) => "(util.equal(" + c0 + ", " + c1 + "))"));
      m("_EXCLAMATION_EQUAL", e => wrap2_01(e, (c0, c1) => "(!util.equal(" + c0 + ", " + c1 + "))"));
      m("_EQUAL3", e => wrap2_01(e, (c0, c1) => "(util.equalStict(" + c0 + ", " + c1 + "))"));
      m("_EXCLAMATION_EQUAL2", e => wrap2_01(e, (c0, c1) => "(!util.equalStict(" + c0 + ", " + c1 + "))"));
      m("_EQUAL_TILDE", e => wrap2_01(e, (c0, c1) => "(util.match(" + c0 + ", " + c1 + "))"));
      m("_ATSIGN2", e => wrap2_01(e, (c0, c1) => "(util.containedKey(" + c0 + ", " + c1 + "))"));
      m("_ATSIGN", e => wrap2_01(e, (c0, c1) => "(util.contained(" + c0 + ", " + c1 + "))"));
      m("_AMPERSAND2", e => {
        var variable = "v_" + e.pc().allocateVariableId();
        var codesLeft = e.arg(0).getCodeGetter(e.pc());

        e.pc().pushFrame();
        var codesRight = e.arg(1).getCodeGetter(e.pc());
        e.pc().popFrame();

        return [
          codesLeft[0] + 
          "let " + variable + " = " + codesLeft[1] + ";\n" +
          "if (util.toBoolean(" + variable + ")) {\n" +
          fl7c.util.indent(
            codesRight[0] +
            variable + " = " + codesRight[1] + ";\n"
          ) +
          "}\n",
          "(" + variable + ")",
        ];
      });
      m("_PIPE2", e => {
        var variable = "v_" + e.pc().allocateVariableId();
        var codesLeft = e.arg(0).getCodeGetter(e.pc());

        e.pc().pushFrame();
        var codesRight = e.arg(1).getCodeGetter(e.pc());
        e.pc().popFrame();

        return [
          codesLeft[0] + 
          "let " + variable + " = " + codesLeft[1] + ";\n" +
          "if (!util.toBoolean(" + variable + ")) {\n" +
          fl7c.util.indent(
            codesRight[0] +
            variable + " = " + codesRight[1] + ";\n"
          ) +
          "}\n",
          "(" + variable + ")",
        ];
      });
      m("_TERNARY_QUESTION_COLON", e => {
        var variable = "v_" + e.pc().allocateVariableId();
        var codesLeft = e.arg(0).getCodeGetter(e.pc());

        e.pc().pushFrame();
        var codesCenter = e.arg(1).getCodeGetter(e.pc());
        e.pc().popFrame();

        e.pc().pushFrame();
        var codesRight = e.arg(2).getCodeGetter(e.pc());
        e.pc().popFrame();

        return [
          codesLeft[0] + 
          "let " + variable + " = " + codesLeft[1] + ";\n" +
          "if (util.toBoolean(" + variable + ")) {\n" +
          fl7c.util.indent(
            codesCenter[0] +
            variable + " = " + codesCenter[1] + ";\n"
          ) +
          "} else {\n" +
          fl7c.util.indent(
            codesRight[0] +
            variable + " = " + codesRight[1] + ";\n"
          ) +
          "}\n",
          "(" + variable + ")",
        ];
      });
      m("_QUESTION_COLON", e => {
        var variable = "v_" + e.pc().allocateVariableId();
        var codesLeft = e.arg(0).getCodeGetter(e.pc());

        e.pc().pushFrame();
        var codesRight = e.arg(1).getCodeGetter(e.pc());
        e.pc().popFrame();

        return [
          codesLeft[0] + 
          "let " + variable + " = " + codesLeft[1] + ";\n" +
          "if (" + variable + " === null) {\n" +
          fl7c.util.indent(
            codesRight[0] +
            variable + " = " + codesRight[1] + ";\n"
          ) +
          "}\n",
          "(" + variable + ")",
        ];
      });
      m("_COMMA", e => {

        var codesHeader = [];
        var codesBody = [];
        for (var i = 0; i < e.node().getArgumentCount(); i++) {
          var node = e.node().getArgument(i);
          if (!(node instanceof fl7c.FluoriteNodeVoid)) {
            var codes = node.getCodeGetter(e.pc());
            codesHeader.push(codes[0]);
            codesBody.push(codes[1]);
          }
        }

        return [
          codesHeader.join(""),
          "(util.toStreamFromValues([" + codesBody.join(", ") + "]))",
        ];
      });
      m("_ITERATE_COMMA", (e, funcCode) => {

        var codes = [];
        for (var i = 0; i < e.node().getArgumentCount(); i++) {
          var node = e.node().getArgument(i);
          if (!(node instanceof fl7c.FluoriteNodeVoid)) {
            codes.push(node.getCodeIterator(e.pc(), funcCode)[0]);
          }
        }

        return [
          codes.join(""),
        ];
      });
      m("_MINUS_GREATER", e => {

        // 引数部全体を括弧で囲んでもよい
        var nodeArgs = e.node().getArgument(0);
        if (nodeArgs instanceof fl7c.FluoriteNodeMacro) {
          if (nodeArgs.getKey() === "_ROUND") {
            nodeArgs = nodeArgs.getArgument(0);
          }
        }

        // 引数部はコロン、セミコロン、空括弧であってもよい
        var nodesArg = undefined;
        if (nodeArgs instanceof fl7c.FluoriteNodeMacro) {
          if (nodeArgs.getKey() === "_SEMICOLON") {
            nodesArg = nodeArgs.getArguments();
          } else if (nodeArgs.getKey() === "_COMMA") {
            nodesArg = nodeArgs.getArguments();
          } else if (nodeArgs.getKey() === "_EMPTY_ROUND") {
            nodesArg = [];
          } else {
            nodesArg = [nodeArgs];
          }
        }
        if (nodesArg === undefined) throw new Error("Illegal lambda argument");

        // 引数は識別子でなければならない
        var args = [];
        for (var i = 0; i < nodesArg.length; i++) {
          var nodeArg = nodesArg[i];
          if (nodeArg instanceof fl7c.FluoriteNodeMacro) {
            if (nodeArg.getKey() === "_LITERAL_IDENTIFIER") {
              if (nodeArg.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
                args.push(nodeArg.getArgument(0).getValue());
                continue;
              }
            }
          }
          throw new Error("Illegal lambda argument: " + nodeArg);
        }

        var aliases = args.map(a => new fl7c.FluoriteAliasVariable(e.pc().allocateVariableId()));

        e.pc().pushFrame();
        e.pc().nextLabelFrame();
        for (var i = 0; i < args.length; i++) {
          e.pc().getFrame()[args[i]] = aliases[i];
        }
        var codes = e.arg(1).getCodeGetter(e.pc());
        e.pc().prevLabelFrame();
        e.pc().popFrame();

        var codeBody =
          "if (args.length != " + args.length + ") throw new Error(\"Number of lambda arguments do not match: \" + args.length + \" != " + args.length + "\");\n" +
          aliases.map((a, i) => "const " + a.getRawCode(e.pc(), e.node().getLocation()) + " = args[" + i + "];\n").join("") +
          codes[0] +
          "return " + codes[1] + ";\n";

        return inline(
          "(util.createLambda(function(args) {\n" +
          fl7c.util.indent(
            codeBody
          ) +
          "}))"
        );
      });
      m("_COLON_EQUAL", e => {

        var key = undefined;
        if (e.arg(0) instanceof fl7c.FluoriteNodeMacro) {
          if (e.arg(0).getKey() === "_LITERAL_IDENTIFIER") {
            if (e.arg(0).getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
              key = e.arg(0).getArgument(0).getValue();
            }
          }
        }
        if (key === undefined) throw new Error("Illegal label: " + e.arg(0));

        var labelAlias = e.pc().getLabelAliasOrUndefined(e.node().getLocation(), key);
        if (labelAlias === undefined) throw new Error("No such label alias: " + key);

        var codes = e.arg(1).getCodeGetter(e.pc());

        return [
          codes[0] +
          "" + labelAlias.getCodeResponse() + " = " + codes[1] + ";\n" +
          "break " + labelAlias.getCode() + ";\n",
          "(null)",
        ];

      });
      m("_COLON", e => {

        var key = undefined;
        if (e.arg(0) instanceof fl7c.FluoriteNodeMacro) {
          if (e.arg(0).getKey() === "_LITERAL_IDENTIFIER") {
            if (e.arg(0).getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
              key = e.arg(0).getArgument(0).getValue();
            }
          }
        }
        if (key === undefined) throw new Error("Illegal label: " + e.arg(0));

        var variableId = e.pc().allocateVariableId();
        var variable = "v_" + variableId;
        var alias = new fl7c.FluoriteAliasVariableSettable(variableId);
        var labelAlias = new fl7c.FluoriteLabelAlias(variableId, variableId);

        e.pc().getFrame()[key] = alias;

        e.pc().pushFrame();
        e.pc().pushLabelFrame();
        e.pc().getLabelFrame()[key] = labelAlias;
        var codes = e.arg(1).getCodeGetter(e.pc());
        e.pc().popLabelFrame();
        e.pc().popFrame();

        return [
          "let " + variable + " = null;\n" +
          "" + labelAlias.getCode() + ": {\n" +
          fl7c.util.indent(
            codes[0] +
            "" + variable + " = " + codes[1] + ";\n"
          ) +
          "}\n",
          "(" + variable + ")",
        ];
      });
      m("_EQUAL", e => {
        var variable = "v_" + e.pc().allocateVariableId();
        var codesRight = e.arg(1).getCodeGetter(e.pc());
        var codesLeft = e.arg(0).getCodeSetter(e.pc(), "(" + variable + ")");
        return [
          codesRight[0] +
          "const " + variable + " = " + codesRight[1] + ";\n" +
          codesLeft[0],
          "(" + variable + ")",
        ];
      });
      m("_LEFT_COLON_EQUAL", e => { // TODO returnできるか否かの判定
        var codes = e.arg(0).getCodeGetter(e.pc());
        return [
          codes[0] +
          "return " + codes[1] + ";\n",
          "(null)",
        ];
      });
      var functionExtractPipeArguments = (node) => {
        var key = undefined;
        var nodesLeft = undefined;
        var iterate = undefined;

        if (node instanceof fl7c.FluoriteNodeMacro) {
          if (node.getKey() === "_COLON") {
            if (node.getArgument(0) instanceof fl7c.FluoriteNodeMacro) {
              if (node.getArgument(0).getKey() === "_LITERAL_IDENTIFIER") {
                if (node.getArgument(0).getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
                  key = node.getArgument(0).getArgument(0).getValue();
                  nodesLeft = node.getArgument(1);
                  iterate = true;
                }
              }
            }
          }
          if (node.getKey() === "_EQUAL") {
            if (node.getArgument(0) instanceof fl7c.FluoriteNodeMacro) {
              if (node.getArgument(0).getKey() === "_LITERAL_IDENTIFIER") {
                if (node.getArgument(0).getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
                  key = node.getArgument(0).getArgument(0).getValue();
                  nodesLeft = node.getArgument(1);
                  iterate = false;
                }
              }
            }
          }
        }

        if (key === undefined) key = "_";
        if (nodesLeft === undefined) nodesLeft = node;
        if (iterate === undefined) iterate = true;

        return {key, nodesLeft, iterate};
      };
      m("_PIPE", e => {

        var args = functionExtractPipeArguments(e.arg(0));
        var codesLeft = args.nodesLeft.getCodeGetter(e.pc());

        var variableId = e.pc().allocateVariableId();
        var variable = "v_" + variableId;
        var alias = new fl7c.FluoriteAliasVariable(variableId);

        if (args.iterate) {

          e.pc().pushFrame();
          e.pc().nextLabelFrame();
          e.pc().getFrame()[args.key] = alias;
          var codesRight = e.arg(1).getCodeGetter(e.pc());
          e.pc().prevLabelFrame();
          e.pc().popFrame();

          return [
            codesLeft[0], // TODO 内部でreturnすると　　　　　↓この関数が反応する問題
            "(util.map(util.toStream(" + codesLeft[1] + "), function(" + variable + ") {\n" +
            fl7c.util.indent(
              codesRight[0] +
              "return " + codesRight[1] + ";\n"
            ) +
            "}))",
          ];
        } else {

          e.pc().pushFrame();
          e.pc().getFrame()[args.key] = alias;
          var codesRight = e.arg(1).getCodeGetter(e.pc());
          e.pc().popFrame();

          return [
            codesLeft[0] +
            "const " + variable + " = " + codesLeft[1] + ";\n" +
            codesRight[0],
            codesRight[1],
          ];
        }
      });
      m("_ITERATE_PIPE", (e, funcCode) => {

        var args = functionExtractPipeArguments(e.arg(0));

        if (args.iterate) {
          return [
            args.nodesLeft.getCodeIterator(e.pc(), codeItemOrStreamer => {
              return functionUnpackStreamer(e.pc(), codeItemOrStreamer, (pc, codeItem) => {

                var variableId = e.pc().allocateVariableId();
                var variable = "v_" + variableId;
                var alias = new fl7c.FluoriteAliasVariable(variableId);

                e.pc().pushFrame();
                e.pc().getFrame()[args.key] = alias;
                var codesRight = e.arg(1).getCodeGetter(pc);
                e.pc().popFrame();

                return (
                  "const " + variable + " = " + codeItem + ";\n" +
                  codesRight[0] +
                  funcCode(codesRight[1])
                );
              });
            })[0],
          ];
        } else {

          var variableId = e.pc().allocateVariableId();
          var variable = "v_" + variableId;
          var alias = new fl7c.FluoriteAliasVariable(variableId);

          var codesLeft = args.nodesLeft.getCodeGetter(e.pc());

          e.pc().pushFrame();
          e.pc().getFrame()[args.key] = alias;
          var codesRight = e.arg(1).getCodeGetter(e.pc());
          e.pc().popFrame();

          return [
            codesLeft[0] +
            "const " + variable + " = " + codesLeft[1] + ";\n" +
            codesRight[0] +
            funcCode(codesRight[1]),
          ];
        }
      });
      m("_QUESTION_PIPE", e => {

        var args = functionExtractPipeArguments(e.arg(0));
        var codesLeft = args.nodesLeft.getCodeGetter(e.pc());

        var variableId = e.pc().allocateVariableId();
        var variable = "v_" + variableId;
        var alias = new fl7c.FluoriteAliasVariable(variableId);

        if (args.iterate) {

          e.pc().pushFrame();
          e.pc().nextLabelFrame();
          e.pc().getFrame()[args.key] = alias;
          var codesRight = e.arg(1).getCodeGetter(e.pc());
          e.pc().prevLabelFrame();
          e.pc().popFrame();

          return [ // TODO パイプ内でreturnできるように
            codesLeft[0], // TODO 内部でreturnすると　　　　　↓この関数が反応する問題
            "(util.grep(util.toStream(" + codesLeft[1] + "), function(" + variable + ") {\n" +
            fl7c.util.indent(
              codesRight[0] +
              "return util.toBoolean(" + codesRight[1] + ");\n"
            ) +
            "}))",
          ];
        } else {

          e.pc().pushFrame();
          e.pc().getFrame()[args.key] = alias;
          var codesRight = e.arg(1).getCodeGetter(e.pc());
          e.pc().popFrame();

          return [
            codesLeft[0] +
            "const " + variable + " = " + codesLeft[1] + ";\n" +
            codesRight[0],
            "(util.toBoolean(" + codesRight[1] + ") ? util.toStreamFromValues([" + variable + "]) : util.empty())",
          ];
        }
      });
      m("_ITERATE_QUESTION_PIPE", (e, funcCode) => {

        var args = functionExtractPipeArguments(e.arg(0));

        if (args.iterate) {
          return [
            args.nodesLeft.getCodeIterator(e.pc(), codeItemOrStreamer => {
              return functionUnpackStreamer(e.pc(), codeItemOrStreamer, (pc, codeItem) => {

                var variableId = e.pc().allocateVariableId();
                var variable = "v_" + variableId;
                var alias = new fl7c.FluoriteAliasVariable(variableId);

                e.pc().pushFrame();
                e.pc().getFrame()[args.key] = alias;
                var codesRight = e.arg(1).getCodeGetter(pc);
                e.pc().popFrame();

                return (
                  "const " + variable + " = " + codeItem + ";\n" +
                  codesRight[0] +
                  "if (util.toBoolean(" + codesRight[1] + ")) {\n" +
                  fl7c.util.indent(
                    funcCode(variable)
                  ) +
                  "}\n"
                );
              });
            })[0],
          ];
        } else {

          var variableId = e.pc().allocateVariableId();
          var variable = "v_" + variableId;
          var alias = new fl7c.FluoriteAliasVariable(variableId);

          var codesLeft = args.nodesLeft.getCodeGetter(e.pc());

          e.pc().pushFrame();
          e.pc().getFrame()[args.key] = alias;
          var codesRight = e.arg(1).getCodeGetter(e.pc());
          e.pc().popFrame();

          return [
            codesLeft[0] +
            "const " + variable + " = " + codesLeft[1] + ";\n" +
            codesRight[0] +
            "if (util.toBoolean(" + codesRight[1] + ")) {\n" +
            fl7c.util.indent(
              funcCode(variable)
            ) +
            "}\n",
          ];
        }
      });
      m("_EXCLAMATION_PIPE", e => {

        var args = functionExtractPipeArguments(e.arg(0));
        var codesLeft = args.nodesLeft.getCodeGetter(e.pc());

        var variableId = e.pc().allocateVariableId();
        var variable = "v_" + variableId;
        var alias = new fl7c.FluoriteAliasVariable(variableId);

        if (args.iterate) {

          e.pc().pushFrame();
          e.pc().nextLabelFrame();
          e.pc().getFrame()[args.key] = alias;
          var codesRight = e.arg(1).getCodeGetter(e.pc());
          e.pc().prevLabelFrame();
          e.pc().popFrame();

          return [ // TODO パイプ内でreturnできるように
            codesLeft[0], // TODO 内部でreturnすると　　　　　↓この関数が反応する問題
            "(util.grep(util.toStream(" + codesLeft[1] + "), function(" + variable + ") {\n" +
            fl7c.util.indent(
              codesRight[0] +
              "return !util.toBoolean(" + codesRight[1] + ");\n"
            ) +
            "}))",
          ];
        } else {

          e.pc().pushFrame();
          e.pc().getFrame()[args.key] = alias;
          var codesRight = e.arg(1).getCodeGetter(e.pc());
          e.pc().popFrame();

          return [
            codesLeft[0] +
            "const " + variable + " = " + codesLeft[1] + ";\n" +
            codesRight[0],
            "(!util.toBoolean(" + codesRight[1] + ") ? util.toStreamFromValues([" + variable + "]) : util.empty())",
          ];
        }
      });
      m("_ITERATE_EXCLAMATION_PIPE", (e, funcCode) => {

        var args = functionExtractPipeArguments(e.arg(0));

        if (args.iterate) {
          return [
            args.nodesLeft.getCodeIterator(e.pc(), codeItemOrStreamer => {
              return functionUnpackStreamer(e.pc(), codeItemOrStreamer, (pc, codeItem) => {

                var variableId = e.pc().allocateVariableId();
                var variable = "v_" + variableId;
                var alias = new fl7c.FluoriteAliasVariable(variableId);

                e.pc().pushFrame();
                e.pc().getFrame()[args.key] = alias;
                var codesRight = e.arg(1).getCodeGetter(pc);
                e.pc().popFrame();

                return (
                  "const " + variable + " = " + codeItem + ";\n" +
                  codesRight[0] +
                  "if (!util.toBoolean(" + codesRight[1] + ")) {\n" +
                  fl7c.util.indent(
                    funcCode(variable)
                  ) +
                  "}\n"
                );
              });
            })[0],
          ];
        } else {

          var variableId = e.pc().allocateVariableId();
          var variable = "v_" + variableId;
          var alias = new fl7c.FluoriteAliasVariable(variableId);

          var codesLeft = args.nodesLeft.getCodeGetter(e.pc());

          e.pc().pushFrame();
          e.pc().getFrame()[args.key] = alias;
          var codesRight = e.arg(1).getCodeGetter(e.pc());
          e.pc().popFrame();

          return [
            codesLeft[0] +
            "const " + variable + " = " + codesLeft[1] + ";\n" +
            codesRight[0] +
            "if (!util.toBoolean(" + codesRight[1] + ")) {\n" +
            fl7c.util.indent(
              funcCode(variable)
            ) +
            "}\n",
          ];
        }
      });
      m("_EQUAL_GREATER", e => {
        var codesLeft = as2c2(e.pc(), e.arg(0));
        var codesRight = e.arg(1).getCodeGetter(e.pc());
        return [
          codesLeft[0] + codesRight[0],
          "(util.call(" + codesRight[1] + ", [" + codesLeft[1] + "]))",
        ];
      });
      m("_SEMICOLON", e => {

        var nodes = [];
        var nodeLast = null;
        for (var i = 0; i < e.node().getArgumentCount(); i++) {
          var node = e.arg(i);
          if (!(node instanceof fl7c.FluoriteNodeVoid)) {
            if (i == e.node().getArgumentCount() - 1) {
              nodeLast = node;
            } else {
              nodes.push(node);
            }
          }
        }

        var codeHeader = nodes.map(node => {
          return node.getCodeIterator(e.pc(), codeItemOrStreamer => {
            return functionUnpackStreamer(e.pc(), codeItemOrStreamer, (pc, codeItem) => {
              return "" + codeItem + ";\n";
            });
          })[0];
        }).join("");
        var codesLast = nodeLast === null ? null : nodeLast.getCodeGetter(e.pc());

        if (codesLast === null) {
          return [
            codeHeader,
            "(util.empty())",
          ];
        } else {
          return [
            codeHeader +
            codesLast[0],
            "(" + codesLast[1] +")",
          ];
        }
      });
      m("_EMPTY_ROOT", e => inline("(util.empty())"));
    }
  }

}

//////////////////////////////////////////////////////////////////

RootDemonstration
  = main:
    ( _ main:Expression _ { return main; }
    / _ { return new fl7c.FluoriteNodeMacro(location(), "_EMPTY_ROOT", []); }
  ) {

    var pc = new fl7c.Environment();

    var objects = {};
    loadAliases(pc, objects);

    var code;
    try {
      var codes = main.getCodeGetter(pc);
      code = "(function() {\n" + fl7c.util.indent(codes[0] + "return " + codes[1] + ";\n") + "}())";
    } catch (e) {
      var result = ["Compile Error", "" + e, main.getTree()];
      console.log(result);
      return result;
    }

    var result;
    var resultString;
    try {
      function Util() {
      }
      Util.prototype = fl7.util;
      var util = new Util();
      util.objects = objects;
      var constants = pc.getConstants();
      result = util.toStream(eval(code)).toArray();
      resultString = result.map(a => util.toString(a) + "\n").join("");
    } catch (e) {
      var result = ["Runtime Error", "" + e, code, main.getTree()];
      console.log(result);
      return result;
    }
    var result = ["OK", resultString, result, code, main.getTree()];
    console.log(result);
    return result;
  }

Root
  = main:
    ( _ main:Expression _ { return main; }
    / _ { return new fl7c.FluoriteNodeMacro(location(), "_EMPTY_ROOT", []); }
  ) { return {
    fl7,
    fl7c,
    loadAliases,
    node: main,
  }; }

//

NestedComment
  = "/+" (NestedComment / (!("+/" / "/+") .))+ "+/"
// TODO /+++ +++/ 的なの

_ "Comment"
  = ( [ \t\r\n]+
    / "#" [^\r\n]*
    / "//" [^\r\n]*
    / "/*" (!"*/" .)* "*/"
    / NestedComment
  )*

LB
  = "\r\n"
  / "\r"
  / "\n"

CharacterIdentifierHead
  = [a-zA-Z_\u0080-\uFFFF]

CharacterIdentifierBody
  = [a-zA-Z_0-9\u0080-\uFFFF]

CharacterIdentifierNonNumber
  = [a-zA-Z_\u0080-\uFFFF]

Identifier
  = $(CharacterIdentifierHead CharacterIdentifierBody*)

//

TokenInteger "Integer"
  = [0-9] [0-9_]* { return new fl7c.FluoriteNodeTokenInteger(location(), parseInt(text().replace(/_/g, ""), 10), text()); }

TokenBasedInteger "BasedInteger"
  = base:
      ( [0-9]+ { return parseInt(text(), 10); }
      / [bB] { return 2; }
      / [oO] { return 8; }
      / [hH] { return 16; }
    ) "#" body:$([0-9a-zA-Z] [0-9a-zA-Z_]*) {
    if (base < 2) throw new Error("Illegal base: " + base);
    if (base > 36) throw new Error("Illegal base: " + base);
    var number = parseInt(body.replace(/_/g, ""), base);
    if (Number.isNaN(number)) throw new Error(location(), "Illegal based integer body: '" + body + "' (base=" + base + ")");
    return new fl7c.FluoriteNodeTokenBasedInteger(location(), number, text());
  }

TokenFloat "Float"
  = ( [0-9] [0-9_]* [.] [0-9] [0-9_]* [eE] [+-]? [0-9]+
    / [0-9] [0-9_]* [.] [0-9] [0-9_]*
    / [0-9] [0-9_]* [eE] [+-]? [0-9]+
  ) { return new fl7c.FluoriteNodeTokenFloat(location(), parseFloat(text().replace(/_/g, "")), text()); }

TokenIdentifier "Identifier"
  = Identifier { return new fl7c.FluoriteNodeTokenIdentifier(location(), text(), text()); }

TokenPatternStringCharacter
  = [^/\\]
  / "\\" (!"/") { return "\\"; }
  / "\\" "/" { return "/"; }

TokenPatternString "PatternString"
  = "/" main:TokenPatternStringCharacter* "/" option:$[a-z]* { return new fl7c.FluoriteNodeTokenPattern(location(), main.join(""), option, text()); }

TokenStringCharacter
  = [^'\\]
  / "\\" main:. { return main; }

TokenString "String"
  = "'" main:TokenStringCharacter* "'" { return new fl7c.FluoriteNodeTokenString(location(), main.join(""), text()); }

TokenEmbeddedStringCharacter
  = [^"\\$]
  / "\\" "\\" { return "\\"; }
  / "\\" "\"" { return "\""; }
  / "\\" "\'" { return "\'"; }
  / "\\" "$" { return "$"; }
  / "\\" "b" { return "\x08"; }
  / "\\" "f" { return "\x0C"; }
  / "\\" "n" { return "\x0A"; }
  / "\\" "r" { return "\x0D"; }
  / "\\" "t" { return "\x09"; }
  / "\\" "0" { return "\x00"; }
  / "\\" "x" main:$([0-9a-fA-f] [0-9a-fA-f]) { return String.fromCharCode(parseInt(main, 16)); }
  / "\\" "u" main:$([0-9a-fA-f] [0-9a-fA-f] [0-9a-fA-f] [0-9a-fA-f]) { return String.fromCharCode(parseInt(main, 16)); }

TokenEmbeddedStringFormat
  = "%" left:
    ( "0" { return result => result.zero = true;}
    / "-" { return result => result.left = true;}
  )* width:
    ( width:$([1-9] [0-9]*) { return result => result.width = parseInt(width, 10) }
  )? precision:
    ( "." precision:$("0" / [1-9] [0-9]*) { return result => result.precision = parseInt(precision, 10);}
  )? conversion:
    ( "d"
    / "s"
    / "f"
  ) {
    var result = {
      conversion,
    };
    left.forEach(flag => flag(result));
    if (width !== null) width(result);
    if (precision !== null) precision(result);
    return new fl7c.FluoriteNodeTokenFormat(location(), result, "%" + text());
  }

TokenEmbeddedStringSection
  = main:TokenEmbeddedStringCharacter+ { return new fl7c.FluoriteNodeTokenString(location(), main.join(""), "\"" + text() + "\""); }
  / "$" main:RightWithoutComment { return main; }
  / "\\" "(" _ main:Expression _ ")" { return main; }
  / "\\" format:TokenEmbeddedStringFormat "(" _ main:Expression _ ")" {
    return new fl7c.FluoriteNodeMacro(location(), "_STRING_FORMAT", [format, main]);
  }

TokenEmbeddedString
  = "\"" main:TokenEmbeddedStringSection* "\"" { return main; }

TokenHereDocument "HereDocument"
  = "<<" _ "'" delimiter:Identifier "'" lb:LB
    main:(
      !(LB delimiter2:Identifier (ex:$[^\r\n]* &{ return ex === ""; }) &{ return delimiter === delimiter2; }) main:. { return main; }
    )*
    (LB delimiter2:Identifier (ex:$[^\r\n]* &{ return ex === ""; }) &{ return delimiter === delimiter2; })
  { return new fl7c.FluoriteNodeTokenString(location(), main.join(""), text() + lb); }

//

LiteralInteger
  = main:TokenInteger { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_INTEGER", [main]); }

LiteralBasedInteger
  = main:TokenBasedInteger { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_BASED_INTEGER", [main]); }

LiteralFloat
  = main:TokenFloat { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_FLOAT", [main]); }

LiteralIdentifier
  = main:TokenIdentifier { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_IDENTIFIER", [main]); }

LiteralPatternString
  = main:TokenPatternString { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_PATTERN_STRING", [main]); }

LiteralString
  = main:TokenString { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_STRING", [main]); }

LiteralEmbeddedString
  = main:TokenEmbeddedString { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_EMBEDDED_STRING", main); }

LiteralHereDocument
  = main:TokenHereDocument { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_HERE_DOCUMENT", [main]); }

Literal
  = LiteralFloat
  / LiteralBasedInteger
  / LiteralInteger
  / LiteralIdentifier
  / LiteralPatternString
  / LiteralString
  / LiteralEmbeddedString
  / LiteralHereDocument

//

ExecutionArguments
  = "[" (_ ",")* _ "]" { return []; }
  / "[" (_ ",")* _ head:ExecutionExpression tail:((_ ",")+ _ ExecutionExpression)* (_ ",")* _ "]" {
    var result = [head];
    tail.forEach(t => result.push(t[2]));
    return result;
  }

ExecutionExpression
  = TokenFloat
  / TokenBasedInteger
  / TokenInteger
  / key:TokenIdentifier _ args:ExecutionArguments {
    return new fl7c.FluoriteNodeMacro(location(), key.getValue(), args);
  }
  / TokenIdentifier
  / "{" _ main:ExecutionExpression _ "}" { return main; }
  / "(" _ main:Expression _ ")" { return main; }

Execution
  = "!!" _ main:ExecutionExpression { return main; }

Brackets
  = main:
    ( "(" _ main:Expression _ ")" { return [location(), "_ROUND", main]; }
    / "[" _ main:Expression _ "]" { return [location(), "_SQUARE", main]; }
    / "{" _ main:Expression _ "}" { return [location(), "_CURLY", main]; }
    / "(" _ ")" { return [location(), "_EMPTY_ROUND", null]; }
    / "[" _ "]" { return [location(), "_EMPTY_SQUARE", null]; }
    / "{" _ "}" { return [location(), "_EMPTY_CURLY", null]; }
  ) { return new fl7c.FluoriteNodeMacro(main[0], main[1], main[2] != null ? [main[2]] : []); }

TokenCompositeSectionInteger
  = [0-9]+ { return new fl7c.FluoriteNodeTokenInteger(location(), parseInt(text(), 10), text()); }

TokenCompositeSectionFloat
  = [0-9]+ [.] [0-9]+ { return new fl7c.FluoriteNodeTokenFloat(location(), parseFloat(text()), text()); }

TokenCompositeSectionIdentifier
  = main:$CharacterIdentifierNonNumber+ & { return main !== "e" && main !== "E"; } {
    return new fl7c.FluoriteNodeTokenIdentifier(location(), text(), text());
  }

Composite "Composite"
  = head:(
    (TokenCompositeSectionFloat / TokenCompositeSectionInteger)
    TokenCompositeSectionIdentifier
  )
  body:(
    (TokenCompositeSectionFloat / TokenCompositeSectionInteger)
    TokenCompositeSectionIdentifier
  )*
  tail:(
    (TokenCompositeSectionFloat / TokenCompositeSectionInteger)
  )? {
    var result = [];
    Array.prototype.push.apply(result, head);
    for (var i = 0; i < body.length; i++) {
      Array.prototype.push.apply(result, body[i]);
    }
    if (tail != null) result.push(tail);
    return new fl7c.FluoriteNodeMacro(location(), "_COMPOSITE", result);
  }

Factor
  = Composite
  / Literal
  / Brackets
  / Execution

//

Right
  = head:Factor tail:(_
    ( "(" _ main:Expression _ ")" { return [location(), "_RIGHT_ROUND", main]; }
    / "[" _ main:Expression _ "]" { return [location(), "_RIGHT_SQUARE", main]; }
    / "{" _ main:Expression _ "}" { return [location(), "_RIGHT_CURLY", main]; }
    / "(" _ ")" { return [location(), "_RIGHT_EMPTY_ROUND", null]; }
    / "[" _ "]" { return [location(), "_RIGHT_EMPTY_SQUARE", null]; }
    / "{" _ "}" { return [location(), "_RIGHT_EMPTY_CURLY", null]; }
    / "." _ main:Factor { return [location(), "_PERIOD", main]; }
    / "::" _ main:Factor { return [location(), "_COLON2", main]; }
  ))* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i][1];
      result = new fl7c.FluoriteNodeMacro(t[0], t[1], t[2] != null ? [result, t[2]] : [result]);
    }
    return result;
  }

RightWithoutComment
  = head:Factor tail:
    ( "(" _ main:Expression _ ")" { return [location(), "_RIGHT_ROUND", main]; }
    / "[" _ main:Expression _ "]" { return [location(), "_RIGHT_SQUARE", main]; }
    / "{" _ main:Expression _ "}" { return [location(), "_RIGHT_CURLY", main]; }
    / "(" _ ")" { return [location(), "_RIGHT_EMPTY_ROUND", null]; }
    / "[" _ "]" { return [location(), "_RIGHT_EMPTY_SQUARE", null]; }
    / "{" _ "}" { return [location(), "_RIGHT_EMPTY_CURLY", null]; }
    / "." _ main:Factor { return [location(), "_PERIOD", main]; }
    / "::" _ main:Factor { return [location(), "_COLON2", main]; }
  )* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[0], t[1], t[2] != null ? [result, t[2]] : [result]);
    }
    return result;
  }

Left
  = Right
  / head:
    ( "+" { return [location(), "_LEFT_PLUS"]; }
    / "-" { return [location(), "_LEFT_MINUS"]; }
    / "?" { return [location(), "_LEFT_QUESTION"]; }
    / "!" !"!" { return [location(), "_LEFT_EXCLAMATION"]; }
    / "&" { return [location(), "_LEFT_AMPERSAND"]; }
    / "*" { return [location(), "_LEFT_ASTERISK"]; }
    / "\\" { return [location(), "_LEFT_BACKSLASH"]; }
    / "$#" { return [location(), "_LEFT_DOLLAR_HASH"]; }
  ) _ tail:Left {
    return new fl7c.FluoriteNodeMacro(head[0], head[1], [tail]);
  }

Pow
  = head:(Left _
    ( "^" { return [location(), "_CIRCUMFLEX"]; }
    / "**" { return [location(), "_ASTERISK2"]; }
  ) _)* tail:Left {
    var result = tail;
    for (var i = head.length - 1; i >= 0; i--) {
      var h = head[i];
      result = new fl7c.FluoriteNodeMacro(h[2][0], h[2][1], [h[0], result]);
    }
    return result;
  }

Mul
  = head:Pow tail:(_
    ( "*" { return [location(), "_ASTERISK"]; }
    / "/" { return [location(), "_SLASH"]; }
    / "%" { return [location(), "_PERCENT"]; }
  ) _ Pow)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Add
  = head:Mul tail:(_
    ( "+" { return [location(), "_PLUS"]; }
    / "-" { return [location(), "_MINUS"]; }
  ) _ Mul)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Join
  = head:Add tail:(_
    ( "&" !"&" { return [location(), "_AMPERSAND"]; }
  ) _ Add)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Range
  = head:Join tail:(_
    ( "~" { return [location(), "_TILDE"]; }
    / ".." { return [location(), "_PERIOD2"]; }
  ) _ Join)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Shift
  = head:Range tail:(_
    ( ">>" { return [location(), "_GREATER2"]; }
    / "<<" { return [location(), "_LESS2"]; }
  ) _ Range)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Spaceship
  = head:Shift tail:(_
    ( "<=>" { return [location(), "_LESS_EQUAL_GREATER"]; }
  ) _ Shift)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result
  }

Compare
  = head:Spaceship tail:(_
    ( ">=" { return [location(), "_GREATER_EQUAL"]; }
    / "<=" { return [location(), "_LESS_EQUAL"]; }
    / ">" { return [location(), "_GREATER"]; }
    / "<" { return [location(), "_LESS"]; }
    / "===" { return [location(), "_EQUAL3"]; }
    / "==" { return [location(), "_EQUAL2"]; }
    / "!==" { return [location(), "_EXCLAMATION_EQUAL2"]; }
    / "!=" { return [location(), "_EXCLAMATION_EQUAL"]; }
    / "=~" { return [location(), "_EQUAL_TILDE"]; }
    / "@@" { return [location(), "_ATSIGN2"]; }
    / "@" { return [location(), "_ATSIGN"]; }
  ) _ Spaceship)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

And
  = head:Compare tail:(_
    ( "&&" { return [location(), "_AMPERSAND2"]; }
  ) _ Compare)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Or
  = head:And tail:(_
    ( "||" { return [location(), "_PIPE2"]; }
  ) _ And)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Condition
  = head:Or _ op:("?" { return location(); }) _ a:Condition _ ":" _ b:Condition {
    return new fl7c.FluoriteNodeMacro(op, "_TERNARY_QUESTION_COLON", [head, a, b]);
  }
  / head:Or _ op:("?:" { return location(); }) _ b:Condition {
    return new fl7c.FluoriteNodeMacro(op, "_QUESTION_COLON", [head, b]);
  }
  / Or

Stream
  = head:(Condition _)? "," tail:
    ( _ main:Condition _ "," { return main; }
    / _ "," { return null; }
  )* last:(_ Condition)? {
    var result = [];
    result.push(head != null ? head[0] : new fl7c.FluoriteNodeVoid(location()));
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result.push(t != null ? t : new fl7c.FluoriteNodeVoid(location()));
    }
    result.push(last != null ? last[1] : new fl7c.FluoriteNodeVoid(location()));
    return new fl7c.FluoriteNodeMacro(location(), "_COMMA", result);
  }
  / Condition

Assignment
  = head:(Stream _
    ( "->" { return [location(), "_MINUS_GREATER"]; }
    / "::=" { return [location(), "_COLON2_EQUAL"]; }
    / ":=" { return [location(), "_COLON_EQUAL"]; }
    / ":" { return [location(), "_COLON"]; }
    / "=" !">" { return [location(), "_EQUAL"]; }
  ) _)* tail:Stream {
    var result = tail;
    for (var i = head.length - 1; i >= 0; i--) {
      var h = head[i];
      result = new fl7c.FluoriteNodeMacro(h[2][0], h[2][1], [h[0], result]);
    }
    return result;
  }

LeftAssignment
  = Assignment
  / head:
    ( ":=" { return [location(), "_LEFT_COLON_EQUAL"]; }
  ) _ tail:LeftAssignment {
    return new fl7c.FluoriteNodeMacro(head[0], head[1], [tail]);
  }

Pipe
  = head:(LeftAssignment _
    ( "|" { return [location(), "_PIPE"]; }
    / "?|" { return [location(), "_QUESTION_PIPE"]; }
    / "!|" { return [location(), "_EXCLAMATION_PIPE"]; }
  ) _)* tail:LeftAssignment {
    var result = tail;
    for (var i = head.length - 1; i >= 0; i--) {
      var h = head[i];
      result = new fl7c.FluoriteNodeMacro(h[2][0], h[2][1], [h[0], result]);
    }
    return result;
  }

Arrow
  = head:Pipe tail:
    ( _ ("=>" { return [location(), "_EQUAL_GREATER"]; }) _ Assignment
    / _ ("|" { return [location(), "_PIPE"]; }) _ Pipe
  )* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Arguments
  = head:(Arrow _)? ";" tail:
    ( _ main:Arrow _ ";" { return main; }
    / _ ";" { return null; }
  )* last:(_ Arrow)? {
    var result = [];
    result.push(head != null ? head[0] : new fl7c.FluoriteNodeVoid(location()));
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result.push(t != null ? t : new fl7c.FluoriteNodeVoid(location()));
    }
    result.push(last != null ? last[1] : new fl7c.FluoriteNodeVoid(location()));
    return new fl7c.FluoriteNodeMacro(location(), "_SEMICOLON", result);
  }
  / Arrow

//

Expression
  = Arguments
