
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
        return "  " + code.replace(/\n(?!$)/g, "\n  ");
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

      getLength() {
        throw new FluoriteRuntimeError("Not Implemented");
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

      getStream() {
        return new FluoriteStreamerMap(this, value => {
          return util.toStreamFromArray(value);
        });
      }

      getLength() {
        var result = 0;
        var stream = this.start();
        while (true) {
          var item = stream.next();
          if (item === undefined) break;
          result += util.getLength(item);
        }
        return result;
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

      call(args) {
        return new FluoriteStreamerMap(this, value => {
          return util.call(value, args);
        });
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

      isInstanceOf(clazz) {
        var o = this;
        while (o !== null) {
          if (o == clazz) return true;
          o = o.parent;
        }
        return false;
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

      getLength() {
        var res = util.getValueFromObject(this, "LENGTH");
        if (res !== null) return util.toJSON(util.call(res, [this]));
        return super.getLength();
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

      setValues(object) {
        var names = Object.getOwnPropertyNames(object.map);
        for (var i = 0; i < names.length; i++) {
          this.map[names[i]] = object.map[names[i]];
        }
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
          var res = regexp.exec(value);
          if (res === null) return null;
          var map = {};
          var match = res[0];
          map[0] = match;
          for (var i = 0; i < res.length - 1; i++) {
            map[i + 1] = res[i + 1];
          }
          map.count = res.length - 1;
          map.offset = res.index;
          map.input = res.input;
          map.TO_STRING = new fl7.FluoriteFunction(args => {
            return match;
          });
          map.LENGTH = new fl7.FluoriteFunction(args => {
            return res.length;
          });
          return new fl7.FluoriteObject(null, map);
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
                  var map = {};
                  var match = res[0];
                  map[0] = match;
                  for (var i = 0; i < res.length - 1; i++) {
                    map[i + 1] = res[i + 1];
                  }
                  map.count = res.length - 1;
                  map.offset = res.index;
                  map.input = res.input;
                  map.TO_STRING = new fl7.FluoriteFunction(args => {
                    return match;
                  });
                  map.LENGTH = new fl7.FluoriteFunction(args => {
                    return res.length;
                  });
                  return new fl7.FluoriteObject(null, map);
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

      call(args) {
        if (args.length != 1) throw new Error("ArgumentException: args.length = " + args.length + " (expected: 1)");
        return this.match(args[0]);
      }

    }

    //

    var util = {

      isStreamer: function(value) {
        return value instanceof FluoriteStreamer;
      },

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
        if (Number.isNaN(value)) return false;
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
        if (value === Infinity) return "INFINITY";
        if (value === -Infinity) return "-INFINITY";
        if (Number.isNaN(value)) return "NAN";
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

      mount: function(oldPath, resolver) {
        if (resolver instanceof FluoriteFunction) {
          return new FluoriteFunction(args => {
            if (args.length != 2) throw new Error("Illegal argument");
            var result = util.call(resolver, args);
            if (result !== args[0]) {
              return result;
            } else {
              return util.call(oldPath, args);
            }
          });
        } else if (resolver instanceof FluoriteObject) {
          return new FluoriteFunction(args => {
            if (args.length != 2) throw new Error("Illegal argument");
            var name = util.toString(args[1]);
            if (util.containedKey(name, resolver)) {
              return util.getOwnValueFromObject(resolver, name);
            } else {
              return util.call(oldPath, args);
            }
          });
        }
        throw new Error("Cannot mount: " + resolver);
      },

      resolve: function(path, name) {
        var pass = new FluoriteObject(null, {});
        var res = util.call(path, [pass, name]);
        if (res === pass) {
          throw new Error("Can not resolve: name = " + name);
        }
        return res;
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
        if (isString(a)) {
          var delimiter;
          if (b instanceof fl7.FluoriteRegExpProvider) {
            delimiter = b.create();
          } else {
            delimiter = util.toString(b);
          }
          return util.toStreamFromValues(a.split(delimiter));
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
        if (value instanceof FluoriteValue) {
          return value.getLength();
        }
        throw new Error("Illegal argument: " + value);
      },

      format: function(format, value) {

        if (format instanceof FluoriteObject) {
          format = {
            conversion: format.map.conversion,
            precision: format.map.precision,
            width: format.map.width,
            zero: format.map.zero,
            left: format.map.left,
          };
        }

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
        if (array instanceof FluoriteStreamer) {
          return new FluoriteStreamerMap(array, value => {
            return util.getFromArray(value, index);
          });
        }
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
          if (isNumber(index)) {
            var res = util.getValueFromObject(array, "GET");
            if (res !== null) return util.call(res, [array, index]);
            return util.getValueFromObject(array, String(index));
          } else {
            return util.getOwnValueFromObject(array, util.toString(index));
          }
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

        if (isNumber(key)) {
          return util.getFromArray(object, key);
        }

        var objectClass;
        if (object instanceof Array) {
          objectClass = this.objects.ARRAY;
        } else if (object instanceof FluoriteObject) {
          objectClass = object;
        } else if (object instanceof FluoriteStreamer) {
          return new FluoriteStreamerMap(object, value => {
            return util.getValueFromObject(value, key);
          });
        } else {
          throw new Error("Illegal argument: " + object + ", " + key);
        }

        key = util.toString(key);

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

      setValuesToObject: function(object, object2) {
        if (!(object instanceof FluoriteObject)) throw new Error("Illegal argument");
        if (!(object2 instanceof FluoriteObject)) throw new Error("Illegal argument");
        object.setValues(object2);
        return object;
      },

      getDelegate: function(object, key) {

        var objectClass;
        if (object instanceof Array) {
          objectClass = this.objects.ARRAY;
        } else if (object instanceof FluoriteObject) {
          objectClass = object;
        } else if (object instanceof FluoriteStreamer) {
          return new FluoriteStreamerMap(object, value => {
            return util.getDelegate(value, key);
          });
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
            const nodeEntry = nodesEntry[i];

            // 宣言文
            if (nodeEntry instanceof fl7c.FluoriteNodeMacro) {
              if (nodeEntry.getKey() === "_COLON") {

                const nodeKey = nodeEntry.getArgument(0);
                var key = undefined;
                if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
                  if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
                    if (nodeKey.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
                      key = pc => [
                        "",
                        JSON.stringify(nodeKey.getArgument(0).getValue()),
                      ];
                      keys.push(nodeKey.getArgument(0).getValue());
                    }
                  } else {
                    key = pc => nodeKey.getCodeGetter(pc);
                  }
                }
                if (key === undefined) throw new Error("Illegal object key");

                var nodeValue = nodeEntry.getArgument(1);

                entries.push([key, nodeValue, true]);
                continue;
              }
            }

            // 代入文
            if (nodeEntry instanceof fl7c.FluoriteNodeMacro) {
              if (nodeEntry.getKey() === "_EQUAL") {

                const nodeKey = nodeEntry.getArgument(0);
                var key = undefined;
                if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
                  if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
                    if (nodeKey.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
                      key = pc => [
                        "",
                        JSON.stringify(nodeKey.getArgument(0).getValue()),
                      ];
                    }
                  } else {
                    key = pc => nodeKey.getCodeGetter(pc);
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
                  entries.push([pc => [
                    "",
                    JSON.stringify(nodeEntry.getArgument(0).getValue()),
                  ], nodeEntry, false]);
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

          var variableIdParent = pc.allocateVariableId();
          var variableParent = "v_" + variableIdParent;
          var variableIdMap = pc.allocateVariableId();
          var variableMap = "v_" + variableIdMap;
          var variableIdObject = pc.allocateVariableId();
          var variableObject = "v_" + variableIdObject;

          pc.pushFrame();
          pc.getFrame()["_PARENT"] = new fl7c.FluoriteAliasVariable(variableIdParent);
          pc.getFrame()["_OBJECT"] = new fl7c.FluoriteAliasVariable(variableIdObject);
          for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            pc.getFrame()[key] = new fl7c.FluoriteAliasMember(variableIdObject, key);
          }
          var codesEntries = [];
          for (var i = 0; i < entries.length; i++) {
            var entry = entries[i];
            var codesKey = entry[0](pc);
            var codesEntry = entry[1].getCodeGetter(pc);
            if (entry[2]) {
              codesEntries.push(
                codesKey[0] +
                "" + variableMap + "[util.toString(" + codesKey[1] + ")] = util.initializer(function() {\n" +
                fl7c.util.indent(
                  codesEntry[0] +
                  "return " + codesEntry[1] + ";\n"
                ) +
                "});\n"
              );
            } else {
              codesEntries.push(
                codesKey[0] +
                codesEntry[0] +
                "" + variableMap + "[util.toString(" + codesKey[1] + ")] = " + codesEntry[1] + ";\n"
              );
            }
          }
          pc.popFrame();

          return [
            codesParent[0] +
            "const " + variableParent + " = " + codesParent[1] + ";\n" +
            "const " + variableMap + " = {};\n" +
            "const " + variableObject + " = util.createObject(" + variableParent + ", " + variableMap + ");\n" +
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
      c("PATH", new fl7.FluoriteFunction(args => {
        if (args.length != 2) throw new Error("Illegal argument");
        return args[1];
      }));
      c("STRICT", new fl7.FluoriteFunction(args => {
        if (args.length != 2) throw new Error("Illegal argument");
        throw new Error("No such alias: name=" + args[1]);
      }));
      c("DIV", new fl7.FluoriteFunction(args => {
        if (args.length == 2) {
          return Math.trunc(util.toNumber(args[0]) / util.toNumber(args[1]));
        }
        throw new Error("Illegal argument");
      }));
      c("TRUNC", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return Math.trunc(util.toNumber(args[0]));
        }
        throw new Error("Illegal argument");
      }));
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
      c("FACT", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          var n = util.toNumber(args[0]);
          if (n < 0) throw new Error("Illegal argument: " + n);
          var t = 1;
          for (var i = 2; i <= n; i++) {
            t *= i;
          }
          return t;
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
      c("HEX", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return util.toNumber(args[0]).toString(16);
        }
        throw new Error("Illegal argument");
      }));
      c("FROM_HEX", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return parseInt(util.toString(args[0]), 16);
        }
        throw new Error("Illegal argument");
      }));
      c("BASE", new fl7.FluoriteFunction(args => {
        if (args.length == 2) {
          return util.toNumber(args[0]).toString(util.toNumber(args[1]));
        }
        throw new Error("Illegal argument");
      }));
      c("FROM_BASE", new fl7.FluoriteFunction(args => {
        if (args.length == 2) {
          return parseInt(util.toString(args[0]), util.toNumber(args[1]));
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
          return args[0];
        }
        throw new Error("Illegal argument");
      }));
      c("THROW", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          throw args[0];
        }
        throw new Error("Illegal argument");
      }));
      c("ERROR", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          throw new Error(util.toString(args[0]));
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
      c("HEAD", new fl7.FluoriteFunction(args => {
        let stream;
        let limit;
        if (args.length === 1) {
          stream = util.toStream(args[0]).start();
          limit = 1;
        } else if (args.length === 2) {
          stream = util.toStream(args[0]).start();
          limit = util.toNumber(args[1]);
        } else {
          throw new Error("Illegal argument");
        }
        class FluoriteStreamerImpl extends fl7.FluoriteStreamer {

          constructor() {
            super();
          }

          start() {
            let consumed = 0;
            return {
              next: () => {
                if (consumed >= limit) return undefined;
                consumed++;
                return stream.next();
              },
            };
          }

        }
        return new FluoriteStreamerImpl();
      }));
      c("SKIP", new fl7.FluoriteFunction(args => {
        if (args.length === 2) {
          const stream = util.toStream(args[0]).start();
          const limit = util.toNumber(args[1]);
          class FluoriteStreamerImpl extends fl7.FluoriteStreamer {

            constructor() {
              super();
            }

            start() {
              let skipped = false;
              return {
                next: () => {
                  if (!skipped) {
                    skipped = true;
                    for (let i = 0; i < limit; i++) {
                      const item = stream.next();
                      if (item === undefined) return undefined;
                    }
                  }
                  return stream.next();
                },
              };
            }

          }
          return new FluoriteStreamerImpl();
        }
        throw new Error("Illegal argument");
      }));
      c("TAIL", new fl7.FluoriteFunction(args => {
        let stream;
        let limit;
        if (args.length === 1) {
          stream = util.toStream(args[0]).start();
          limit = 1;
        } else if (args.length === 2) {
          stream = util.toStream(args[0]).start();
          limit = util.toNumber(args[1]);
        } else {
          throw new Error("Illegal argument");
        }
        class FluoriteStreamerImpl extends fl7.FluoriteStreamer {

          constructor() {
            super();
          }

          start() {
            const buffer = [];
            let skipped = false;
            let i = 0;
            return {
              next: () => {
                if (!skipped) {
                  skipped = true;
                  while (true) {
                    const item = stream.next();
                    if (item === undefined) break;
                    buffer.push(item);
                    if (buffer.length > limit) buffer.shift();
                  }
                }
                if (i >= buffer.length) return undefined;
                const item = buffer[i];
                i++;
                return item;
              },
            };
          }

        }
        return new FluoriteStreamerImpl();
      }));
      c("BODY", new fl7.FluoriteFunction(args => {
        let stream;
        let skip;
        let count;
        if (args.length === 2) {
          stream = util.toStream(args[0]).start();
          skip = util.toNumber(args[1]);
          count = 1;
        } else if (args.length === 3) {
          stream = util.toStream(args[0]).start();
          skip = util.toNumber(args[1]);
          count = util.toNumber(args[2]);
        } else {
          throw new Error("Illegal argument");
        }
        class FluoriteStreamerImpl extends fl7.FluoriteStreamer {

          constructor() {
            super();
          }

          start() {
            let skipped = false;
            let consumed = 0;
            return {
              next: () => {
                if (!skipped) {
                  skipped = true;
                  for (let i = 0; i < skip; i++) {
                    const item = stream.next();
                    if (item === undefined) return undefined;
                  }
                }
                if (consumed >= count) return undefined;
                consumed++;
                return stream.next();
              },
            };
          }

        }
        return new FluoriteStreamerImpl();
      }));
      c("REDUCE", new fl7.FluoriteFunction(args => {
        let stream;
        let reducer;
        let value;
        if (args.length == 2) {
          stream = util.toStream(args[0]).start();
          reducer = args[1];
          value = undefined;
        } else if (args.length == 3) {
          stream = util.toStream(args[0]).start();
          reducer = args[1];
          value = args[2];
        } else {
          throw new Error("Illegal argument");
        }
        if (value === undefined) {
          value = stream.next();
          if (value === undefined) return null;
        }

        while (true) {
          const next = stream.next();
          if (next === undefined) break;
          value = util.call(reducer, [value, next]);
        }
        return value;
      }));
      c("ADD", new fl7.FluoriteFunction(args => {
        let result = 0;
        for (let i = 0; i < args.length; i++) {
          const stream = util.toStream(args[i]).start();
          while (true) {
            const next = stream.next();
            if (next === undefined) break;
            result += util.toNumber(next);
          }
        }
        return result;
      }));
      c("MUL", new fl7.FluoriteFunction(args => {
        let result = 1;
        for (let i = 0; i < args.length; i++) {
          const stream = util.toStream(args[i]).start();
          while (true) {
            const next = stream.next();
            if (next === undefined) break;
            result *= util.toNumber(next);
          }
        }
        return result;
      }));
      c("COUNT", new fl7.FluoriteFunction(args => {
        let result = 0;
        for (let i = 0; i < args.length; i++) {
          const stream = util.toStream(args[i]).start();
          while (true) {
            const next = stream.next();
            if (next === undefined) break;
            result++;
          }
        }
        return result;
      }));
      c("AVERAGE", new fl7.FluoriteFunction(args => {
        let sum = 0;
        let count = 0;
        for (let i = 0; i < args.length; i++) {
          const stream = util.toStream(args[i]).start();
          while (true) {
            const next = stream.next();
            if (next === undefined) break;
            sum += util.toNumber(next);
            count++;
          }
        }
        return sum / count;
      }));
      objects.ARRAY = fl7.util.createObject(null, {
        CALL: new fl7.FluoriteFunction(args => {
          var value = args[1];
          if (value === undefined) throw new Error("Illegal argument");
          return util.toStream(value).toArray();
        }),
        remove: new fl7.FluoriteFunction(args => {
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
        removeFirst: new fl7.FluoriteFunction(args => {
          if (args.length != 1) throw new Error("Illegal argument count: " + args.length);
          var array = args[0];
          if (!(array instanceof Array)) throw new Error("Illegal argument type: " + array);

          if (array.length < 1) throw new Error("Illegal array length: " + array.length);

          var index = 0;
          var value = array[index];
          array.splice(index, 1);
          return value;
        }),
        removeLast: new fl7.FluoriteFunction(args => {
          if (args.length != 1) throw new Error("Illegal argument count: " + args.length);
          var array = args[0];
          if (!(array instanceof Array)) throw new Error("Illegal argument type: " + array);

          if (array.length < 1) throw new Error("Illegal array length: " + array.length);

          var index = array.length - 1;
          var value = array[index];
          array.splice(index, 1);
          return value;
        }),
        removeRandom: new fl7.FluoriteFunction(args => {
          if (args.length != 1) throw new Error("Illegal argument count: " + args.length);
          var array = args[0];
          if (!(array instanceof Array)) throw new Error("Illegal argument type: " + array);

          if (array.length < 1) throw new Error("Illegal array length: " + array.length);

          var index = Math.floor(Math.random() * array.length);
          var value = array[index];
          array.splice(index, 1);
          return value;
        }),
        splice: [
          null,
          null,
          null,
          new fl7.FluoriteFunction(args => {
            if (args.length != 3) throw new Error("Illegal argument count: " + args.length);
            var array = args[0];
            if (!(array instanceof Array)) throw new Error("Illegal argument type: " + array);
            var start = util.toNumber(args[1]);
            if (start < 0) start += array.length;
            if (start < 0) throw new Error("Illegal start: " + start + " < 0");
            if (start > array.length) throw new Error("Illegal start: " + start + " > " + array.length);
            var count = util.toNumber(args[2]);
            if (count < 0) throw new Error("Illegal count: " + count + " < 0");
            if (count + start > array.length) throw new Error("Illegal count: " + count + " + " + start + " > " + array.length);

            return array.splice(start, count);
          }),
          new fl7.FluoriteFunction(args => {
            if (args.length != 4) throw new Error("Illegal argument count: " + args.length);
            var array = args[0];
            if (!(array instanceof Array)) throw new Error("Illegal argument type: " + array);
            var start = util.toNumber(args[1]);
            if (start < 0) start += array.length;
            if (start < 0) throw new Error("Illegal start: " + start + " < 0");
            if (start > array.length) throw new Error("Illegal start: " + start + " > " + array.length);
            var count = util.toNumber(args[2]);
            if (count < 0) throw new Error("Illegal count: " + count + " < 0");
            if (count + start > array.length) throw new Error("Illegal count: " + count + " + " + start + " > " + array.length);
            var array2 = args[3];
            if (!(array2 instanceof Array)) throw new Error("Illegal argument type: array2 : " + array2);

            var args2 = [start, count];
            Array.prototype.push.apply(args2, array2);
            return Array.prototype.splice.apply(array, args2);
          }),
        ],
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
      c("REGEXP", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          return new fl7.FluoriteRegExpProvider(util.toString(args[0]), "");
        } else if (args.length == 2) {
          return new fl7.FluoriteRegExpProvider(util.toString(args[0]), util.toString(args[1]));
        }
        throw new Error("Illegal argument");
      }));
      c("GREP", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var predicate = args[1];

        var funcPredicate;
        if (predicate === undefined) {
          funcPredicate = a => util.toBoolean(a);
        } else if (predicate instanceof fl7.FluoriteRegExpProvider) {
          funcPredicate = a => util.match(util.toString(a), predicate)　!== null;
        } else {
          funcPredicate = a => util.toBoolean(util.call(predicate, [a]));
        }

        var array = [];
        var stream = streamer.start();
        while (true) {
          var next = stream.next();
          if (next === undefined) break;
          if (funcPredicate(next)) {
            array[array.length] = next;
          }
        }
        return util.toStreamFromValues(array);
      }));
      c("JOIN", new fl7.FluoriteFunction(args => {
        var delimiter = args[1];
        if (delimiter === undefined) delimiter = ",";
        delimiter = util.toString(delimiter);

        var stream = args[0];
        if (stream === undefined) throw new Error("Illegal argument");
        stream = util.toStream(stream);

        return stream.toArray().map(value => util.toString(value)).join(delimiter);
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
        if (limit !== undefined) limit = util.toNumber(limit);

        return util.toStreamFromValues(string.split(delimiter, limit));
      }));
      c("REPLACE", new fl7.FluoriteFunction(args => {

        var string = args[0];
        if (string === undefined) throw new Error("Illegal argument");
        string = util.toString(string);

        var matcher = args[1];
        if (matcher === undefined) throw new Error("Illegal argument");
        if (matcher instanceof fl7.FluoriteRegExpProvider) {
          matcher = matcher.create();
        } else {
          matcher = util.toString(matcher);
        }

        var replacer = args[2];
        if (replacer === undefined) throw new Error("Illegal argument");

        if (replacer instanceof fl7.FluoriteFunction) {
          return string.replace(matcher, function() {
            var map = {};
            var match = arguments[0];
            map[0] = match;
            for (var i = 0; i < arguments.length - 3; i++) {
              map[i + 1] = arguments[i + 1];
            }
            map.count = arguments.length - 3;
            map.offset = arguments[arguments.length - 2];
            map.input = arguments[arguments.length - 1];
            map.TO_STRING = new fl7.FluoriteFunction(args => {
              return match;
            });
            map.LENGTH = new fl7.FluoriteFunction(args => {
              return arguments.length - 2;
            });
            return util.toString(util.call(replacer, [new fl7.FluoriteObject(null, map)]));
          });
        } else if (isString(replacer)) {
          replacer = util.toString(replacer);
          return string.replace(matcher, replacer);
        } else {
          throw new Error("Illegal argument");
        }
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
      c("RANDOM", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var array = streamer.toArray();
        return array.length == 0 ? util.empty() : array[Math.floor(Math.random() * array.length)];
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
      c("UNIQ", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var matcher = args[1];
        if (matcher === undefined) matcher = null;

        var array = [];
        var last = undefined;
        var stream = streamer.start();
        a:
        while (true) {
          var next = stream.next();
          if (next === undefined) break;
          if (last !== undefined) {
            if (matcher != null ? util.call(matcher, [last, next]) : util.equal(next, last)) {
              continue;
            }
          }
          array[array.length] = next;
          last = next;
        }

        return util.toStreamFromValues(array);
      }));
      c("UNIQ_BY", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var keySelector = args[1];
        if (keySelector === undefined) throw new Error("Illegal argument");

        var array = [];
        var last = undefined;
        var stream = streamer.start();
        a:
        while (true) {
          var next = stream.next();
          if (next === undefined) break;
          if (last !== undefined) {
            var a = util.call(keySelector, [last]);
            var b = util.call(keySelector, [next]);
            if (util.equal(b, a)) {
              continue;
            }
          }
          array[array.length] = next;
          last = next;
        }

        return util.toStreamFromValues(array);
      }));
      c("DISTINCT", new fl7.FluoriteFunction(args => {

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
            var a = array[i];
            var b = next;
            if (matcher != null ? util.call(matcher, [a, b]) : util.equal(b, a)) {
              continue a;
            }
          }
          array[array.length] = next;
        }

        return util.toStreamFromValues(array);
      }));
      c("DISTINCT_BY", new fl7.FluoriteFunction(args => {

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
            var a = util.call(keySelector, [array[i]]);
            var b = util.call(keySelector, [next]);
            if (util.equal(b, a)) {
              continue a;
            }
          }
          array[array.length] = next;
        }

        return util.toStreamFromValues(array);
      }));
      c("SLICE", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var number = args[1];
        if (number === undefined) number = 10;
        number = util.toNumber(number);
        if (number < 1) throw new Error("Illegal argument: number = " + number);

        var array = [];
        var stream = streamer.start();
        a:
        while (true) {
          var array2 = [];
          for (var i = 0; i < number; i++) {
            var next = stream.next();
            if (next === undefined) {
              if (array2.length > 0) array[array.length] = array2;
              break a;
            }
            array2[array2.length] = next;
          }
          array[array.length] = array2;
        }

        return util.toStreamFromValues(array);
      }));
      c("SHUFFLE", new fl7.FluoriteFunction(args => {

        var streamer = args[0];
        if (streamer === undefined) throw new Error("Illegal argument");
        streamer = util.toStream(streamer);

        var array = Array.from(streamer.toArray());
        for (let i = array.length - 1; i >= 0; i--) {
          const j = Math.floor(Math.random() * (i + 1));
          [array[i], array[j]] = [array[j], array[i]];
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

        if (value instanceof fl7.FluoriteStreamer) {
          return util.map(value, item => {
            return JSON.stringify(item, null, indent);
          });
        } else {
          return JSON.stringify(value, null, indent);
        }
      }));
      c("FROM_JSON", new fl7.FluoriteFunction(args => {

        var value = args[0];
        if (value === undefined) throw new Error("Illegal argument");

        if (value instanceof fl7.FluoriteStreamer) {
          return util.map(value, item => {
            return JSON.parse(util.toString(item), (k, v) => {
              if (typeof v === "object" && v !== null && !Array.isArray(v)) return util.createObject(null, v);
              return v;
            });
          });
        } else {
          return JSON.parse(util.toString(value), (k, v) => {
            if (typeof v === "object" && v !== null && !Array.isArray(v)) return util.createObject(null, v);
            return v;
          });
        }
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
      c("CHARCODE", new fl7.FluoriteFunction(args => {
        var string = args[0];
        string = util.toString(string);
        if (string.length < 1) throw new Error("Illegal argument: string.length=" + string.length + " < 1");
        return string.charCodeAt(0);
      }));
      c("FROM_CHARCODE", new fl7.FluoriteFunction(args => {
        var charcode = args[0];
        charcode = util.toNumber(charcode);
        return String.fromCharCode.apply(null, [charcode]);
      }));
      c("URI", new fl7.FluoriteFunction(args => {
        if (args.length != 1) throw new Error("Illegal argument");
        var string = args[0];
        string = util.toString(string);
        return encodeURIComponent(string);
      }));
      c("CR", new fl7.FluoriteFunction(args => {
        if (args.length != 1) throw new Error("Illegal argument");
        var string = args[0];
        string = util.toString(string);
        return string.replace(/\r\n?|\n/g, replacement => "\r");
      }));
      c("LF", new fl7.FluoriteFunction(args => {
        if (args.length != 1) throw new Error("Illegal argument");
        var string = args[0];
        string = util.toString(string);
        return string.replace(/\r\n?|\n/g, replacement => "\n");
      }));
      c("CRLF", new fl7.FluoriteFunction(args => {
        if (args.length != 1) throw new Error("Illegal argument");
        var string = args[0];
        string = util.toString(string);
        return string.replace(/\r\n?|\n/g, replacement => "\r\n");
      }));
      c("FROM_URI", new fl7.FluoriteFunction(args => {
        if (args.length != 1) throw new Error("Illegal argument");
        var string = args[0];
        string = util.toString(string);
        return decodeURIComponent(string);
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
      c("LOOP", (function() {
        class FluoriteStreamerLoop extends fl7.FluoriteStreamer {

          constructor() {
            super();
          }

          start() {
            return {
              next: () => {
                return null;
              },
            };
          }

        }
        return new FluoriteStreamerLoop();
      }()));
      c("WHILE", new fl7.FluoriteFunction(args => {
        if (args.length != 1 && args.length != 2) throw new Error("Illegal argument");
        var func = args[0];
        var funcUpdate = args[1];
        class FluoriteStreamerLoop extends fl7.FluoriteStreamer {

          constructor() {
            super();
          }

          start() {
            var first = true;
            return {
              next: () => {
                if (first) {
                  first = false;
                } else {
                  if (funcUpdate !== undefined) util.call(funcUpdate, []);
                }
                var a = util.call(func, []);
                if (!util.toBoolean(a)) return undefined;
                return a;
              },
            };
          }

        }
        return new FluoriteStreamerLoop();
      }));
      c("UNTIL", new fl7.FluoriteFunction(args => {
        if (args.length != 1 && args.length != 2) throw new Error("Illegal argument");
        var func = args[0];
        var funcUpdate = args[1];
        class FluoriteStreamerLoop extends fl7.FluoriteStreamer {

          constructor() {
            super();
          }

          start() {
            var first = true;
            return {
              next: () => {
                if (first) {
                  first = false;
                } else {
                  if (funcUpdate !== undefined) util.call(funcUpdate, []);
                }
                var a = util.call(func, []);
                if (util.toBoolean(a)) return undefined;
                return a;
              },
            };
          }

        }
        return new FluoriteStreamerLoop();
      }));
      c("FOR", new fl7.FluoriteFunction(args => {
        if (args.length != 3) throw new Error("Illegal argument");
        var funcInit = args[0];
        var funcCond = args[1];
        var funcUpdate = args[2];
        class FluoriteStreamerLoop extends fl7.FluoriteStreamer {

          constructor() {
            super();
          }

          start() {
            var first = true;
            var i;
            return {
              next: () => {
                if (first) {
                  first = false;
                  i = util.call(funcInit, []);
                } else {
                  if (funcUpdate !== undefined) i = util.call(funcUpdate, [i]);
                }
                if (!util.toBoolean(util.call(funcCond, [i]))) return undefined;
                return i;
              },
            };
          }

        }
        return new FluoriteStreamerLoop();
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
      c("IS", new fl7.FluoriteFunction(args => {
        if (args.length == 2) {
          var object = args[0];
          var clazz = args[1];
          if (!(clazz instanceof fl7.FluoriteObject)) throw new Error("Illegal argument");
          if (!(object instanceof fl7.FluoriteObject)) return false;
          return object.isInstanceOf(clazz);
        }
        throw new Error("Illegal argument");
      }));
      c("FORMAT", new fl7.FluoriteFunction(args => {
        if (args.length == 2) {
          var format = args[0];
          var value = args[1];
          return util.format(format, value);
        }
        throw new Error("Illegal argument");
      }));
      c("PARENT", new fl7.FluoriteFunction(args => {
        if (args.length == 1) {
          var object = args[0];
          if (!(object instanceof fl7.FluoriteObject)) throw new Error("Illegal argument");
          return object.parent;
        }
        throw new Error("Illegal argument");
      }));
      c("NOW", new fl7.FluoriteFunction(args => {
        return Date.now();
      }));
      var createDateObject = date => {
        return new fl7.FluoriteObject(null, {
          utcYear: date.getUTCFullYear(),
          utcMonth: date.getUTCMonth() + 1,
          utcDay: date.getUTCDate(),
          utcHour: date.getUTCHours(),
          utcMinute: date.getUTCMinutes(),
          utcSecond: date.getUTCSeconds(),
          utcMillisecond: date.getUTCMilliseconds(),
          utcWeekday: date.getUTCDay(),
          year: date.getFullYear(),
          month: date.getMonth() + 1,
          day: date.getDate(),
          hour: date.getHours(),
          minute: date.getMinutes(),
          second: date.getSeconds(),
          millisecond: date.getMilliseconds(),
          weekday: date.getDay(),
          epochMillisecond: date.getTime(),
          timezoneOffset: date.getTimezoneOffset(),
          TO_NUMBER: new fl7.FluoriteFunction(args => date.getTime()),
          TO_STRING: new fl7.FluoriteFunction(args => {
            var pad = number => number < 10 ? "0" + number : number;
            return date.getFullYear() +
              "-" + pad(date.getMonth() + 1) +
              "-" + pad(date.getDate()) +
              "T" + pad(date.getHours()) +
              ":" + pad(date.getMinutes()) +
              ":" + pad(date.getSeconds()) +
              "." + (date.getMilliseconds() / 1000).toFixed(3).slice(2, 5);
          }),
        });
      };
      c("DATE", new fl7.FluoriteFunction(args => {
        if (args.length == 0) {
          var date = new Date();
          return createDateObject(date);
        }
        if (args.length == 1) {
          var date = new Date();
          date.setTime(util.toNumber(args[0]));
          return createDateObject(date);
        }
        throw new Error("Illegal argument");
      }));
      c("LOCAL", new fl7.FluoriteFunction(args => {
        if (args.length == 3) {
          var date = new Date(
            util.toNumber(args[0]),
            util.toNumber(args[1] - 1),
            util.toNumber(args[2]));
          return createDateObject(date);
        }
        if (args.length == 6) {
          var date = new Date(
            util.toNumber(args[0]),
            util.toNumber(args[1] - 1),
            util.toNumber(args[2]),
            util.toNumber(args[3]),
            util.toNumber(args[4]),
            util.toNumber(args[5]));
          return createDateObject(date);
        }
        if (args.length == 7) {
          var date = new Date(
            util.toNumber(args[0]),
            util.toNumber(args[1] - 1),
            util.toNumber(args[2]),
            util.toNumber(args[3]),
            util.toNumber(args[4]),
            util.toNumber(args[5]));
          date.setMilliseconds(util.toNumber(args[6]));
          return createDateObject(date);
        }
        throw new Error("Illegal argument");
      }));
      c("UTC", new fl7.FluoriteFunction(args => {
        if (args.length == 3) {
          var date = new Date();
          date.setTime(Date.UTC(
            util.toNumber(args[0]),
            util.toNumber(args[1] - 1),
            util.toNumber(args[2])));
          return createDateObject(date);
        }
        if (args.length == 6) {
          var date = new Date();
          date.setTime(Date.UTC(
            util.toNumber(args[0]),
            util.toNumber(args[1] - 1),
            util.toNumber(args[2]),
            util.toNumber(args[3]),
            util.toNumber(args[4]),
            util.toNumber(args[5])));
          return createDateObject(date);
        }
        if (args.length == 7) {
          var date = new Date();
          date.setTime(Date.UTC(
            util.toNumber(args[0]),
            util.toNumber(args[1] - 1),
            util.toNumber(args[2]),
            util.toNumber(args[3]),
            util.toNumber(args[4]),
            util.toNumber(args[5])));
          date.setUTCMilliseconds(util.toNumber(args[6]));
          return createDateObject(date);
        }
        throw new Error("Illegal argument");
      }));
      var setDateUnitFunction = (name, unit) => {
        c(name, new fl7.FluoriteFunction(args => {
          if (args[0] === undefined) throw new Error("Illegal argument");
          if (args.length > 2) throw new Error("Illegal argument");
          var right = args[1] === undefined ? 0 : util.toNumber(args[1]);
          return util.toNumber(args[0]) * unit + right;
        }));
      };
      setDateUnitFunction("UNIT_D", 1000 * 60 * 60 * 24);
      setDateUnitFunction("UNIT_H", 1000 * 60 * 60);
      setDateUnitFunction("UNIT_M", 1000 * 60);
      setDateUnitFunction("UNIT_S", 1000);
      setDateUnitFunction("UNIT_MS", 1);
      setDateUnitFunction("DAYS", 1000 * 60 * 60 * 24);
      setDateUnitFunction("HOURS", 1000 * 60 * 60);
      setDateUnitFunction("MINUTES", 1000 * 60);
      setDateUnitFunction("SECONDS", 1000);
      setDateUnitFunction("MILLISECONDS", 1);
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
          if (alias === undefined) {
            var aliasPath = e.pc().getAliasOrUndefined(e.node().getLocation(), "PATH");
            if (aliasPath !== undefined) {
              var codePath = aliasPath.getCodeGetter(e.pc(), e.node().getLocation());
              return [
                codePath[0],
                "(util.resolve(" + codePath[1] + ", " + JSON.stringify(key) + "))",
              ];
              return JSON.stringify(key);
            }
            throw new Error("No such alias '" + key + "'");
          }
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
      m("_LITERAL_DOLLAR", e => { // TODO delete
        var alias = e.pc().getAliasOrUndefined(e.node().getLocation(), "_OBJECT");
        if (alias === undefined) throw new Error("No such alias: name=" + "_OBJECT");
        return alias.getCodeGetter(e.pc(), e.node().getLocation());
      });
      m("_LITERAL_DOLLAR2", e => {
        var alias = e.pc().getAliasOrUndefined(e.node().getLocation(), "_OBJECT");
        if (alias === undefined) throw new Error("No such alias: name=" + "_OBJECT");
        return alias.getCodeGetter(e.pc(), e.node().getLocation());
      });
      m("_LITERAL_CIRCUMFLEX", e => {
        var alias = e.pc().getAliasOrUndefined(e.node().getLocation(), "_PARENT");
        if (alias === undefined) throw new Error("No such alias: name=" + "_PARENT");
        return alias.getCodeGetter(e.pc(), e.node().getLocation());
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

        var variable = "v_" + e.pc().allocateVariableId();
        codesHeader.push("const " + variable + " = [];\n");

        var nodes = e.node().getArguments();
        for (var i = 0; i < nodes.length; i++) {
          var node = nodes[i];
          if (node instanceof fl7c.FluoriteNodeTokenString) {
            codesHeader.push("" + variable + "[" + variable + ".length] = " + JSON.stringify(node.getValue()) + ";\n");
          } else {
            var variable2 = "v_" + e.pc().allocateVariableId();
            codesHeader.push("let " + variable2 + " = true;\n");
            codesHeader.push(node.getCodeIterator(e.pc(), codeItemOrStreamer => {
              return functionUnpackStreamer(e.pc(), codeItemOrStreamer, (pc, codeItem) => {
                return (
                  "if (" + variable2 + ") {\n" +
                  fl7c.util.indent(
                    "" + variable2 + " = false;\n"
                  ) +
                  "} else {\n" +
                  fl7c.util.indent(
                    "" + variable + "[" + variable + ".length] = \"\\n\";\n"
                  ) +
                  "}\n" +
                  "" + variable + "[" + variable + ".length] = util.toString(" + codeItem + ");\n"
                );
              });
            })[0]);
          }
        }

        return [
          codesHeader.join(""),
          "(" + variable + ".join(\"\"))",
        ];
      });
      m("_LITERAL_HERE_DOCUMENT", e => {
        if (e.arg(0) instanceof fl7c.FluoriteNodeTokenString) {
          return inline("(" + JSON.stringify(e.arg(0).getValue()) + ")");
        }
        throw new Error("Illegal argument");
      });
      m("_LITERAL_EMBEDDED_HERE_DOCUMENT", e => {
        var codesHeader = [];

        var variable = "v_" + e.pc().allocateVariableId();
        codesHeader.push("const " + variable + " = [];\n");

        var nodes = e.node().getArguments();
        for (var i = 0; i < nodes.length; i++) {
          var node = nodes[i];
          if (node instanceof fl7c.FluoriteNodeTokenString) {
            codesHeader.push("" + variable + "[" + variable + ".length] = " + JSON.stringify(node.getValue()) + ";\n");
          } else {
            var variable2 = "v_" + e.pc().allocateVariableId();
            codesHeader.push("let " + variable2 + " = true;\n");
            codesHeader.push(node.getCodeIterator(e.pc(), codeItemOrStreamer => {
              return functionUnpackStreamer(e.pc(), codeItemOrStreamer, (pc, codeItem) => {
                return (
                  "if (" + variable2 + ") {\n" +
                  fl7c.util.indent(
                    "" + variable2 + " = false;\n"
                  ) +
                  "} else {\n" +
                  fl7c.util.indent(
                    "" + variable + "[" + variable + ".length] = \"\\n\";\n"
                  ) +
                  "}\n" +
                  "" + variable + "[" + variable + ".length] = util.toString(" + codeItem + ");\n"
                );
              });
            })[0]);
          }
        }

        return [
          codesHeader.join(""),
          "(" + variable + ".join(\"\"))",
        ];
      });
      m("_LITERAL_EMBEDDED_FLUORITE", e => {
        var codesHeader = [];

        var variable = "v_" + e.pc().allocateVariableId();
        codesHeader.push("const " + variable + " = [];\n");

        var nodes = e.node().getArguments();
        for (var i = 0; i < nodes.length; i++) {
          var node = nodes[i];
          if (node instanceof fl7c.FluoriteNodeTokenString) {
            codesHeader.push("" + variable + "[" + variable + ".length] = " + JSON.stringify(node.getValue()) + ";\n");
          } else {
            codesHeader.push(node.getCodeIterator(e.pc(), codeItemOrStreamer => {
              return functionUnpackStreamer(e.pc(), codeItemOrStreamer, (pc, codeItem) => {
                return (
                  "" + variable + "[" + variable + ".length] = util.toString(" + codeItem + ");\n"
                );
              });
            })[0]);
          }
        }

        return [
          codesHeader.join(""),
          "(" + variable + ".join(\"\"))",
        ];
      });
      m("_LITERAL_EMBED", e => {
        return e.arg(0).getCodeGetter(e.pc());
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
      m("_EMBED_ENUMERATE", e => {
        var codesHeader = [];

        var variable = "v_" + e.pc().allocateVariableId();
        codesHeader.push("const " + variable + " = [];\n");

        var nodes = e.node().getArguments();
        for (var i = 0; i < nodes.length; i++) {
          var node = nodes[i];
          if (node instanceof fl7c.FluoriteNodeTokenString) {
            codesHeader.push("" + variable + "[" + variable + ".length] = " + JSON.stringify(node.getValue()) + ";\n");
          } else {
            codesHeader.push(node.getCodeIterator(e.pc(), codeItemOrStreamer => {
              return functionUnpackStreamer(e.pc(), codeItemOrStreamer, (pc, codeItem) => {
                return (
                  "" + variable + "[" + variable + ".length] = " + codeItem + ";\n"
                );
              });
            })[0]);
          }
        }
        
        return [
          codesHeader.join(""),
          "util.toStreamFromValues(" + variable + ")",
        ];
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
            a:
            {
              var key = "UNIT_" + node.getValue();
              var aliasPath = e.pc().getAliasOrUndefined(node.getLocation(), "PATH");
              if (aliasPath === undefined) break a;
              var codePath = aliasPath.getCodeGetter(e.pc(), node.getLocation());
              return [
                codePath[0],
                "util.resolve(" + codePath[1] + ", " + JSON.stringify(key) + ")",
              ];
            }
            a:
            {
              var key = node.getValue();
              var aliasPath = e.pc().getAliasOrUndefined(node.getLocation(), "PATH");
              if (aliasPath === undefined) break a;
              var codePath = aliasPath.getCodeGetter(e.pc(), node.getLocation());
              return [
                codePath[0],
                "util.resolve(" + codePath[1] + ", " + JSON.stringify(key) + ")",
              ];
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

        var i = count - 1;

        var codeRight;
        if (count % 2 == 0) {
          var codeLeft = getCodeGetterOfNumber(e.node().getArgument(i - 1));
          var codeIdentifier = getCodeGetterOfIdentifier(e.node().getArgument(i));
          codeRight = call(codeIdentifier, [codeLeft]);
          i -= 2;
        } else {
          codeRight = getCodeGetterOfNumber(e.node().getArgument(i));
          i--;
        }

        while (i >= 0) {
          var codeLeft = getCodeGetterOfNumber(e.node().getArgument(i - 1));
          var codeIdentifier = getCodeGetterOfIdentifier(e.node().getArgument(i));
          codeRight = call(codeIdentifier, [codeLeft, codeRight]);
          i -= 2;
        }

        return codeRight;
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

        var codeObject = nodeObject.getCodeGetter(e.pc());

        if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
          if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
            if (nodeKey.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
              return [
                codeObject[0],
                "(util.getValueFromObject(" + codeObject[1] + ", " + "(" + JSON.stringify(nodeKey.getArgument(0).getValue()) + ")" + "))",
              ];
            }
          } else if (nodeKey.getKey() === "_CURLY") {
            var codeKey = nodeKey.getCodeGetter(e.pc());
            return [
              codeObject[0] +
              codeKey[0],
              "(util.setValuesToObject(" + codeObject[1] + ", " + codeKey[1] + "))",
            ];
          } else if (nodeKey.getKey() === "_EMPTY_CURLY") {
            var codeKey = nodeKey.getCodeGetter(e.pc());
            return [
              codeObject[0] +
              codeKey[0],
              "(util.setValuesToObject(" + codeObject[1] + ", " + codeKey[1] + "))",
            ];
          }
        }

        var codeKey = nodeKey.getCodeGetter(e.pc());
        return [
          codeObject[0] +
          codeKey[0],
          "(util.getValueFromObject(" + codeObject[1] + ", " + codeKey[1] + "))",
        ];
      });
      m("_SET_PERIOD", (e, code) => {

        var nodeObject = e.arg(0);
        var nodeKey = e.arg(1);

        var codeObject = nodeObject.getCodeGetter(e.pc());

        var codeKey = undefined;
        if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
          if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
            if (nodeKey.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
              codeKey = [
                "",
                "(" + JSON.stringify(nodeKey.getArgument(0).getValue()) + ")",
              ];
            }
          }
        }
        if (codeKey === undefined) codeKey = nodeKey.getCodeGetter(e.pc());

        return [
          codeObject[0] +
          codeKey[0] +
          "util.setToArray(" + codeObject[1] + ", " + codeKey[1] + ", " + code + ");\n",
        ];
      });
      m("_COLON2", e => {

        var nodeObject = e.arg(0);
        var nodeKey = e.arg(1);

        if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
          if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
            if (nodeKey.getArgument(0) instanceof fl7c.FluoriteNodeTokenIdentifier) {
              var key = nodeKey.getArgument(0).getValue();
              return wrap(e.pc(), nodeObject, c => "(util.getDelegate(" + c + ", " + JSON.stringify(key) + "))");
            }
          } else if (nodeKey.getKey() === "_ROUND") {
              var codeObject = nodeObject.getCodeGetter(e.pc());
              var codeKey = nodeKey.getCodeGetter(e.pc());
              return [
                codeObject[0] +
                codeKey[0],
                "(util.bind(" + codeKey[1] + ", " + codeObject[1] + "))",
              ];
          }
        }
        throw new Error("Illegal member access key");
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
          "(util.call(" + codesLeft[1] + ", [" + codesAlias[1] + "]))",
        ];
      });
      m("_LEFT_BACKSLASH", e => {
        var alias1 = new fl7c.FluoriteAliasVariable(e.pc().allocateVariableId());
        var alias2 = new fl7c.FluoriteAliasVariable(e.pc().allocateVariableId());

        e.pc().pushFrame();
        e.pc().nextLabelFrame();
        e.pc().getFrame()["_"] = alias1;
        e.pc().getFrame()["__"] = alias2;
        var codes = e.arg(0).getCodeGetter(e.pc());
        e.pc().prevLabelFrame();
        e.pc().popFrame();

        var variableObject = "v_" + e.pc().allocateVariableId();
        var variable1 = "v_" + e.pc().allocateVariableId();
        return inline(
          "(util.createLambda(function(args) {\n" +
          fl7c.util.indent(
            "const " + alias1.getRawCode(e.pc(), e.node().getLocation()) + " = args.length >= 1 ? args[0] : null;\n" +
            "const " + variableObject + " = {\n" +
            fl7c.util.indent(
              "LENGTH: util.createLambda(function(args2) {\n" +
              fl7c.util.indent(
                "return args.length;\n"
              ) +
              "}),\n"
            ) +
            "};\n" +
            "for (let i = 0; i < args.length; i++) {\n" +
            fl7c.util.indent(
              "" + variableObject + "[i] = args[i];\n"
            ) +
            "}\n" +
            "const " + alias2.getRawCode(e.pc(), e.node().getLocation()) + " = util.createObject(null, " + variableObject + ");\n" +
            codes[0] +
            "return " + codes[1] + ";"
          ) +
          "\n}))"
        );
      });
      m("_LEFT_DOLLAR_HASH", e => wrap_0(e, c => "(util.getLength(" + c + "))"));
      m("_LEFT_ATSIGN", e => {

        // 項を評価
        var nodeMain = e.arg(0);
        var codeMain = nodeMain.getCodeGetter(e.pc());
        var variableMain = "v_" + e.pc().allocateVariableId();

        // 古いPATHを取得
        var aliasOldPath = e.pc().getAliasOrUndefined(e.node().getLocation(), "PATH");
        if (aliasOldPath === undefined) throw new Error("No such alias: PATH");
        var codeOldPath = aliasOldPath.getCodeGetter(e.pc(), e.node().getLocation());
        var variableOldPath = "v_" + e.pc().allocateVariableId();

        // PATHを更新
        var variableIdNewPath = e.pc().allocateVariableId();
        var variableNewPath = "v_" + variableIdNewPath;
        var aliasNewPath = new fl7c.FluoriteAliasVariableSettable(variableIdNewPath);
        e.pc().getFrame()["PATH"] = aliasNewPath;

        return [
          codeMain[0] +
          "const " + variableMain +" = " + codeMain[1] + ";\n" +
          codeOldPath[0] +
          "const " + variableOldPath +" = " + codeOldPath[1] + ";\n" +
          "const " + variableNewPath +" = util.mount(" + variableOldPath + ", " + variableMain + ");\n",
          "" + variableMain,
        ];
      });
      m("_LEFT_BACKQUOTES", e => {
        var codesFunction = e.arg(0).getCodeGetter(e.pc());
        var codesRight = e.arg(1).getCodeGetter(e.pc());
        return [
          codesRight[0] +
          codesFunction[0],
          "(util.call(" + codesFunction[1] + ", [" + codesRight[1] + "]))",
        ];
      });
      m("_BACKQUOTES", e => {
        var codesLeft = e.arg(0).getCodeGetter(e.pc());
        var codesFunction = e.arg(1).getCodeGetter(e.pc());
        var codesRight = e.arg(2).getCodeGetter(e.pc());
        return [
          codesLeft[0] +
          codesRight[0] +
          codesFunction[0],
          "(util.call(" + codesFunction[1] + ", [" + codesLeft[1] + ", " + codesRight[1] + "]))",
        ];
      });
      m("_CIRCUMFLEX", e => wrap2_01(e, (c0, c1) => "(Math.pow(" + c0 + ", " + c1 + "))"));
      m("_ASTERISK", e => wrap2_01(e, (c0, c1) => "(util.asterisk(" + c0 + ", " + c1 + "))"));
      m("_SLASH", e => wrap2_01(e, (c0, c1) => "(util.slash(" + c0 + ", " + c1 + "))"));
      m("_PERCENT", e => wrap2_01(e, (c0, c1) => "(" + c0 + " % " + c1 + ")"));
      m("_PERCENT2", e => wrap2_01(e, (c0, c1) => "(" + c0 + " % " + c1 + " === 0)"));
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
      m("_EXCLAMATION_COLON", e => {
        var variable = "v_" + e.pc().allocateVariableId();
        var codesLeft = e.arg(0).getCodeGetter(e.pc());

        e.pc().pushFrame();
        var codesRight = e.arg(1).getCodeGetter(e.pc());
        e.pc().popFrame();

        return [
          codesLeft[0] + 
          "let " + variable + " = " + codesLeft[1] + ";\n" +
          "if (" + variable + " !== null) {\n" +
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

        if (e.arg(0) instanceof fl7c.FluoriteNodeMacro) {
          if (e.arg(0).getKey() === "_COMMA") {

            var getNodes = node => {
              var args = node.getArguments();
              var nodes = [];
              for (var i = 0; i < args.length; i++) {
                var arg = args[i];
                if (!(arg instanceof fl7c.FluoriteNodeVoid)) {
                  nodes.push(arg);
                }
              }
              return nodes;
            };

            var nodesLeft = getNodes(e.arg(0));

            var nodesRight = undefined;
            if (e.arg(1) instanceof fl7c.FluoriteNodeMacro) {
              if (e.arg(1).getKey() === "_COMMA") {
                nodesRight = getNodes(e.arg(1));
              }
            }
            if (nodesRight === undefined) throw new Error("Illegal right term: " + e.arg(1));

            if (nodesLeft.length !== nodesRight.length) throw new Error("Argument count does not match: " + nodesLeft.length + " !== " + nodesRight.length);

            var codes1 = [];
            var codes2 = [];
            for (var i = 0; i < nodesLeft.length; i++) {
              var variable = "v_" + e.pc().allocateVariableId();
              var codeRight = nodesRight[i].getCodeGetter(e.pc());
              var codeLeft = nodesLeft[i].getCodeSetter(e.pc(), "(" + variable + ")");
              codes1.push(codeRight[0]);
              codes1.push("const " + variable + " = " + codeRight[1] + ";\n");
              codes2.push(codeLeft[0]);
            }

            return [
              codes1.join("") +
              codes2.join(""),
              "(util.empty())",
            ];
          }
        }

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
        var keyIndex = undefined;
        var nodesLeft = undefined;
        var iterate = undefined;
        var object = undefined;

        if (node instanceof fl7c.FluoriteNodeMacro) {
          if (node.getKey() === "_COLON") {
            var nodeLeft = node.getArgument(0);
            if (nodeLeft instanceof fl7c.FluoriteNodeMacro) {
              if (nodeLeft.getKey() === "_LITERAL_IDENTIFIER") {
                var nodeLeftIdentifier = nodeLeft.getArgument(0);
                if (nodeLeftIdentifier instanceof fl7c.FluoriteNodeTokenIdentifier) {
                  key = nodeLeftIdentifier.getValue();
                  keyIndex = null;
                  nodesLeft = node.getArgument(1);
                  iterate = true;
                  object = false;
                }
              }
              if (nodeLeft.getKey() === "_COMMA") {
                if (nodeLeft.getArgumentCount() == 2) {
                  var nodeKeyIndex = nodeLeft.getArgument(0);
                  var nodeKey = nodeLeft.getArgument(1);
                  if (nodeKeyIndex instanceof fl7c.FluoriteNodeMacro) {
                    if (nodeKeyIndex.getKey() === "_LITERAL_IDENTIFIER") {
                      var nodeKeyIndexIdentifier = nodeKeyIndex.getArgument(0);
                      if (nodeKeyIndexIdentifier instanceof fl7c.FluoriteNodeTokenIdentifier) {
                        if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
                          if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
                            var nodeKeyIdentifier = nodeKey.getArgument(0);
                            if (nodeKeyIdentifier instanceof fl7c.FluoriteNodeTokenIdentifier) {
                              key = nodeKeyIdentifier.getValue();
                              keyIndex = nodeKeyIndexIdentifier.getValue();
                              nodesLeft = node.getArgument(1);
                              iterate = true;
                              object = false;
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
              if (nodeLeft.getKey() === "_SQUARE" || nodeLeft.getKey() === "_CURLY") {
                var nodeColon = nodeLeft.getArgument(0);
                if (nodeColon instanceof fl7c.FluoriteNodeMacro) {
                  if (nodeColon.getKey() === "_COLON") {
                    var nodeKeyIndex = nodeColon.getArgument(0);
                    var nodeKey = nodeColon.getArgument(1);
                    if (nodeKeyIndex instanceof fl7c.FluoriteNodeMacro) {
                      if (nodeKeyIndex.getKey() === "_LITERAL_IDENTIFIER") {
                        var nodeKeyIndexIdentifier = nodeKeyIndex.getArgument(0);
                        if (nodeKeyIndexIdentifier instanceof fl7c.FluoriteNodeTokenIdentifier) {
                          if (nodeKey instanceof fl7c.FluoriteNodeMacro) {
                            if (nodeKey.getKey() === "_LITERAL_IDENTIFIER") {
                            var nodeKeyIdentifier = nodeKey.getArgument(0);
                              if (nodeKeyIdentifier instanceof fl7c.FluoriteNodeTokenIdentifier) {
                                key = nodeKeyIdentifier.getValue();
                                keyIndex = nodeKeyIndexIdentifier.getValue();
                                nodesLeft = node.getArgument(1);
                                iterate = true;
                                object = false;
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          if (node.getKey() === "_EQUAL") {
            var nodeLeft = node.getArgument(0);
            if (nodeLeft instanceof fl7c.FluoriteNodeMacro) {
              if (nodeLeft.getKey() === "_LITERAL_IDENTIFIER") {
                var nodeLeftIdentifier = nodeLeft.getArgument(0);
                if (nodeLeftIdentifier instanceof fl7c.FluoriteNodeTokenIdentifier) {
                  key = nodeLeftIdentifier.getValue();
                  keyIndex = null;
                  nodesLeft = node.getArgument(1);
                  iterate = false;
                  object = false;
                }
              }
            }
          }
        }

        if (key === undefined) key = "_";
        if (keyIndex === undefined) keyIndex = null;
        if (nodesLeft === undefined) nodesLeft = node;
        if (iterate === undefined) iterate = true;
        if (object === undefined) object = false;

        return {key, keyIndex, nodesLeft, iterate, object};
      };
      var functionPipe = function(e, functionCodeFilter) {

        var args = functionExtractPipeArguments(e.arg(0));
        var codesLeft = args.nodesLeft.getCodeGetter(e.pc());

        var variableId = e.pc().allocateVariableId();
        var variable = "v_" + variableId;
        var alias = new fl7c.FluoriteAliasVariable(variableId);
        var variableIdIndex = e.pc().allocateVariableId();
        var variableIndex = "v_" + variableIdIndex;
        var aliasIndex = new fl7c.FluoriteAliasVariable(variableIdIndex);

        if (args.iterate) {

          e.pc().pushFrame();
          e.pc().nextLabelFrame();
          if (args.keyIndex !== null) e.pc().getFrame()[args.keyIndex] = aliasIndex;
          e.pc().getFrame()[args.key] = alias;
          var codesRight = e.arg(1).getCodeGetter(e.pc());
          e.pc().prevLabelFrame();
          e.pc().popFrame();

          var variableIdFunction = "v_" + e.pc().allocateVariableId();
          var variableIdValue = "v_" + e.pc().allocateVariableId();
          var variableIdResult = "v_" + e.pc().allocateVariableId();
          var variableIdFilterFunctionArgument = "v_" + e.pc().allocateVariableId();

          return [
            codesLeft[0] +
            "let " + variableIndex + " = -1;\n" +
            "const " + variableIdFunction + " = function(" + variable + ") {\n" +
            fl7c.util.indent(
              "" + variableIndex + "++;\n" +
              codesRight[0] +
              "return " + codesRight[1] + ";\n"
            ) +
            "};\n" +
            "const " + variableIdValue + " = " + codesLeft[1] + ";\n" +
            "let " + variableIdResult + ";\n" +
            "if (util.isStreamer(" + variableIdValue + ")) {\n" +
            fl7c.util.indent(
              functionCodeFilter !== null ? (
                "" + variableIdResult + " = util.map(util.grep(" + variableIdValue + ", " + variableIdFilterFunctionArgument + " => " + functionCodeFilter(variableIdFilterFunctionArgument) + "), " + variableIdFunction + ");\n"
              ) : (
                "" + variableIdResult + " = util.map(" + variableIdValue + ", " + variableIdFunction + ");\n"
              )
            ) +
            "} else {\n" +
            fl7c.util.indent(
              functionCodeFilter !== null ? (
                "if (" + functionCodeFilter(variableIdValue) + ") {\n" + 
                fl7c.util.indent(
                  "" + variableIdResult + " = " + variableIdFunction + "(" + variableIdValue + ");\n"
                ) +
                "} else {\n" + 
                fl7c.util.indent(
                  "" + variableIdResult + " = util.empty();\n"
                ) +
                "}\n"
              ) : (
                "" + variableIdResult + " = " + variableIdFunction + "(" + variableIdValue + ");\n"
              )
            ) +
            "}\n",
            "(" + variableIdResult + ")",
          ];
        } else {

          e.pc().pushFrame();
          e.pc().getFrame()[args.key] = alias;
          var codesRight = e.arg(1).getCodeGetter(e.pc());
          e.pc().popFrame();

          var variableIdResult = "v_" + e.pc().allocateVariableId();

          return [
            codesLeft[0] +
            "const " + variable + " = " + codesLeft[1] + ";\n" +
            "let " + variableIdResult + ";\n" +
            (
              "if (" + (functionCodeFilter === null ? "true" : functionCodeFilter(variable)) + ") {\n" + 
              fl7c.util.indent(
                codesRight[0]+
                "" + variableIdResult + " = " + codesRight[1] + ";\n"
              ) +
              "} else {\n" + 
              fl7c.util.indent(
                "" + variableIdResult + " = util.empty();\n"
              ) +
              "}\n"
            ),
            "(" + variableIdResult + ")",
          ];
        }
      };
      var functionIteratePipe = function(e, funcCode, functionCodeFilter) {

        var args = functionExtractPipeArguments(e.arg(0));

        var variableIdIndex = e.pc().allocateVariableId();
        var variableIndex = "v_" + variableIdIndex;
        var aliasIndex = new fl7c.FluoriteAliasVariable(variableIdIndex);

        if (args.iterate) {
          return [
            "let " + variableIndex + " = -1;\n" +
            args.nodesLeft.getCodeIterator(e.pc(), codeItemOrStreamer => {
              return functionUnpackStreamer(e.pc(), codeItemOrStreamer, (pc, codeItem) => {

                var variableId = e.pc().allocateVariableId();
                var variable = "v_" + variableId;
                var alias = new fl7c.FluoriteAliasVariable(variableId);

                e.pc().pushFrame();
                if (args.keyIndex !== null) e.pc().getFrame()[args.keyIndex] = aliasIndex;
                e.pc().getFrame()[args.key] = alias;
                var codesRight = e.arg(1).getCodeGetter(pc);
                e.pc().popFrame();

                var variableIdItem = "v_" + e.pc().allocateVariableId();

                return (
                  "" + variableIndex + "++;\n" +
                  "const " + variableIdItem + " = " + codeItem + ";\n" +
                  "if (" + (functionCodeFilter === null ? "true" : functionCodeFilter(variableIdItem)) + ") {\n" +
                  fl7c.util.indent(
                    "const " + variable + " = " + variableIdItem + ";\n" +
                    codesRight[0] +
                    funcCode(codesRight[1])
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
            "if (" + (functionCodeFilter === null ? "true" : functionCodeFilter(variable)) + ") {\n" +
            fl7c.util.indent(
              codesRight[0] +
              funcCode(codesRight[1])
            ) +
            "}\n",
          ];
        }
      };
      m("_PIPE", e => functionPipe(e, null));
      m("_ITERATE_PIPE", (e, funcCode) => functionIteratePipe(e, funcCode, null));
      m("_QUESTION_PIPE", e => functionPipe(e, code => code + " !== null"));
      m("_EXCLAMATION_QUESTION", e => {

        var variableResult = "v_" + e.pc().allocateVariableId();

        var variableIdError = e.pc().allocateVariableId();
        var variableError = "v_" + variableIdError;
        var aliasError = new fl7c.FluoriteAliasVariable(variableIdError);

        e.pc().pushFrame();
        var codesLeft = e.arg(0).getCodeGetter(e.pc());
        e.pc().popFrame();
        e.pc().pushFrame();
        e.pc().getFrame()["_"] = aliasError;
        var codesRight = e.arg(1).getCodeGetter(e.pc());
        e.pc().popFrame();

        return [
          "let " + variableResult + ";\n" +
          "try {\n" +
          fl7c.util.indent(
            codesLeft[0] +
            variableResult + " = " + codesLeft[1] + ";\n"
          ) +
          "} catch (" + variableError + ") {\n" +
          fl7c.util.indent(
          variableError + " = " + variableError + ".toString();\n" +
            codesRight[0] +
            variableResult + " = " + codesRight[1] + ";\n"
          ) +
          "}\n",
          "(" + variableResult + ")",
        ];
      });
      m("_ITERATE_QUESTION_PIPE", (e, funcCode) => functionIteratePipe(e, funcCode, code => code + " !== null"));
      m("_EXCLAMATION_PIPE", e => functionPipe(e, code => code + " === null"));
      m("_ITERATE_EXCLAMATION_PIPE", (e, funcCode) => functionIteratePipe(e, funcCode, code => code + " === null"));
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
            codesLast[1],
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

RootEmbeddedFluorite
  = main:
    ( main:TokenEmbeddedFluoriteContents { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_EMBEDDED_FLUORITE", main); }
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

TokenEmbedFormat
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

TokenEmbedEnumerateSection
  = main:[a-zA-Z_0-9\u0080-\uFFFF,\-./]+ { return new fl7c.FluoriteNodeTokenString(location(), main.join(""), JSON.stringify(main.join(""))); }
  / LiteralString
  / LiteralEmbeddedString
  / LiteralEmbeddedFluorite
  / "$" main:LiteralIdentifier { return main; }
  / LiteralEmbed
  / Brackets

TokenEmbed
  = "$" "(" _ main:Expression _ ")" { return main; }
  / "$" format:TokenEmbedFormat "(" _ main:Expression _ ")" {
    return new fl7c.FluoriteNodeMacro(location(), "_STRING_FORMAT", [format, main]);
  }
  / "$" "{" _ main:
    ( main:TokenEmbedEnumerateSection _ { return main; }
    )* "}" { return new fl7c.FluoriteNodeMacro(location(), "_EMBED_ENUMERATE", main); }

TokenEmbeddedString
  = "\""
    main:
    ( main:TokenEmbeddedStringCharacter+ { return new fl7c.FluoriteNodeTokenString(location(), main.join(""), "\"" + text() + "\""); }
    / "$$" { return new fl7c.FluoriteNodeTokenString(location(), "$", "\"$\""); }
    / "$" main:LiteralIdentifier { return main; }
    / TokenEmbed
    / "\\" "(" _ main:Expression _ ")" { return main; }
    / "\\" format:TokenEmbedFormat "(" _ main:Expression _ ")" {
      return new fl7c.FluoriteNodeMacro(location(), "_STRING_FORMAT", [format, main]);
    }
    )*
    "\""
  { return main; }

TokenHereDocument "HereDocument"
  = "<<" _ delimiter:
    ( "'" main:Identifier "'" { return main; }
    / Identifier
    ) lb:LB
    main:(
      !(LB [ \t]* delimiter2:Identifier (ex:$[^\r\n]* &{ return ex === ""; }) &{ return delimiter === delimiter2; }) main:. { return main; }
    )*
    (LB [ \t]* delimiter2:Identifier (ex:$[^\r\n]* &{ return ex === ""; }) &{ return delimiter === delimiter2; })
  { return new fl7c.FluoriteNodeTokenString(location(), main.join(""), text() + lb); }

TokenEmbeddedHereDocument "EmbeddedHereDocument"
  = "<<" _ "\"" delimiter:Identifier "\"" lb:LB
    main:
    ( main:(
        !(LB [ \t]* delimiter2:Identifier (ex:$[^\r\n]* &{ return ex === ""; }) &{ return delimiter === delimiter2; }) main:[^$] { return main; }
      )+ { return new fl7c.FluoriteNodeTokenString(location(), main.join(""), text() + lb); }
    / "$$" { return new fl7c.FluoriteNodeTokenString(location(), "$", "\"$\""); }
    / "$" main:LiteralIdentifier { return main; }
    / TokenEmbed
    )*
    (LB [ \t]* delimiter2:Identifier (ex:$[^\r\n]* &{ return ex === ""; }) &{ return delimiter === delimiter2; })
  { return main; }

TokenEmbeddedFluoriteContents
  = ( main:
      ( !"<%" main:. { return main; }
      / "<%%" { return "<%"; }
      / "<%#" (!"%>" .)* "%>" { return ""; }
      )+ { return new fl7c.FluoriteNodeTokenString(location(), main.join(""), JSON.stringify(main.join(""))); }
    / "<%=" _ main:Expression _ "%>" { return main; }
    )*

TokenEmbeddedFluorite "EmbeddedFluorite"
  = "%>" main:TokenEmbeddedFluoriteContents "<%" { return main; }

//

LiteralInteger
  = main:TokenInteger { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_INTEGER", [main]); }

LiteralBasedInteger
  = main:TokenBasedInteger { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_BASED_INTEGER", [main]); }

LiteralFloat
  = main:TokenFloat { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_FLOAT", [main]); }

LiteralIdentifier
  = main:TokenIdentifier { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_IDENTIFIER", [main]); }

LiteralDollar
  = "$$" { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_DOLLAR2", []); }
  / "$" !("#" / "(" / "%" / "{") { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_DOLLAR", []); } // TODO delete

LiteralCircumflex
  = "^" { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_CIRCUMFLEX", []); }

LiteralPatternString
  = main:TokenPatternString { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_PATTERN_STRING", [main]); }

LiteralString
  = main:TokenString { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_STRING", [main]); }

LiteralEmbeddedString
  = main:TokenEmbeddedString { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_EMBEDDED_STRING", main); }

LiteralHereDocument
  = main:TokenHereDocument { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_HERE_DOCUMENT", [main]); }

LiteralEmbeddedHereDocument
  = main:TokenEmbeddedHereDocument { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_EMBEDDED_HERE_DOCUMENT", main); }

LiteralEmbeddedFluorite
  = main:TokenEmbeddedFluorite { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_EMBEDDED_FLUORITE", main); }

LiteralEmbed
  = main:TokenEmbed { return new fl7c.FluoriteNodeMacro(location(), "_LITERAL_EMBED", [main]); }

LiteralNotDot
  = LiteralBasedInteger
  / LiteralInteger
  / LiteralIdentifier
  / LiteralDollar
  / LiteralCircumflex
  / LiteralPatternString
  / LiteralString
  / LiteralEmbeddedString
  / LiteralHereDocument
  / LiteralEmbeddedHereDocument
  / LiteralEmbeddedFluorite
  / LiteralEmbed

Literal
  = LiteralFloat
  / LiteralBasedInteger
  / LiteralInteger
  / LiteralIdentifier
  / LiteralDollar
  / LiteralCircumflex
  / LiteralPatternString
  / LiteralString
  / LiteralEmbeddedString
  / LiteralHereDocument
  / LiteralEmbeddedHereDocument
  / LiteralEmbeddedFluorite
  / LiteralEmbed

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
  = main:$CharacterIdentifierNonNumber+ & { return main.match(/^(_+|[eE])$/) === null; } {
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

FactorNotDot
  = Composite
  / LiteralNotDot
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
    / "." _ main:FactorNotDot { return [location(), "_PERIOD", main]; }
    / "::" _ main:FactorNotDot { return [location(), "_COLON2", main]; }
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
    ( "+" { return [location(), "_LEFT_PLUS", []]; }
    / "-" { return [location(), "_LEFT_MINUS", []]; }
    / "?" { return [location(), "_LEFT_QUESTION", []]; }
    / "!" !"!" { return [location(), "_LEFT_EXCLAMATION", []]; }
    / "&" { return [location(), "_LEFT_AMPERSAND", []]; }
    / "*" { return [location(), "_LEFT_ASTERISK", []]; }
    / "\\" { return [location(), "_LEFT_BACKSLASH", []]; }
    / "$#" { return [location(), "_LEFT_DOLLAR_HASH", []]; }
    / "@" { return [location(), "_LEFT_ATSIGN", []]; }
    / "`" main:Right "`" { return [location(), "_LEFT_BACKQUOTES", [main]]; }
  ) _ tail:Left {
    var args = [];
    Array.prototype.push.apply(args, head[2]);
    args[args.length] = tail;
    return new fl7c.FluoriteNodeMacro(head[0], head[1], args);
  }

Backquotes
  = head:Left tail:(_
    ( "`" main:Right "`" { return [location(), "_BACKQUOTES", main]; }
  ) _ Left)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new fl7c.FluoriteNodeMacro(t[1][0], t[1][1], [result, t[1][2], t[3]]);
    }
    return result;
  }

Pow
  = head:(Backquotes _
    ( "^" { return [location(), "_CIRCUMFLEX"]; }
    / "**" { return [location(), "_ASTERISK2"]; }
  ) _)* tail:Backquotes {
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
    / "%%" { return [location(), "_PERCENT2"]; }
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
  / head:Or _ op:("!:" { return location(); }) _ b:Condition {
    return new fl7c.FluoriteNodeMacro(op, "_EXCLAMATION_COLON", [head, b]);
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
    / "!?" { return [location(), "_EXCLAMATION_QUESTION"]; }
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
