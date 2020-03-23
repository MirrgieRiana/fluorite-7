
{

  class Fluorite {

  }
  Fluorite.getLocationString = function(location) {
    return "L:" + location.start.line + ",C:" + location.start.column;
  };
  Fluorite.throwCompileError = function(location, message) {
    throw new FluoriteError(message + " (" + Fluorite.getLocationString(location) + ")");
  }

  class FluoriteError extends Error {

    constructor(...args) {
      super(...args);
      Object.defineProperty(this, 'name', {
        configurable: true,
        enumerable: false,
        value: this.constructor.name,
        writable: true,
      });
      if (Error.captureStackTrace) {
        Error.captureStackTrace(this, FluoriteError);
      }
    }

  }

  //

  class FluoriteParserContext {

    constructor() {
      this._nextConstantId = 0;
      this._nextVariableId = 0;
      this._constants = [];
      this._frameStack = [{}];

      this.loadAliases(); // TODO ここじゃなくてどこかで呼び出す
    }

    allocateConstantId() {
      var result = this._nextConstantId;
      this._nextConstantId++;
      return result;
    }

    allocateVariableId() {
      var result = this._nextVariableId;
      this._nextVariableId++;
      return result;
    }

    getConstant(constantId) {
      return this._constants[constantId];
    }

    setConstant(constantId, value) {
      this._constants[constantId] = value;
    }

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

    setAlias(key, value) {
      this.getFrame()[key] = value;
    }

    getAlias(location, key) {
      for (var i = this._frameStack.length - 1; i >= 0; i--) {
        var alias = this._frameStack[i][key];
        if (alias != undefined) {
          return alias;
        }
      }
      Fluorite.throwCompileError(location, "No such alias '" + key + "'");
    }

    getAliasOrUndefined(location, key) {
      for (var i = this._frameStack.length - 1; i >= 0; i--) {
        var alias = this._frameStack[i][key];
        if (alias != undefined) {
          return alias;
        }
      }
      return undefined;
    }

    createVirtualMachine() {
      return new FluoriteVirtualMachine(this._constants);
    }

    loadAliases() { // TODO どこかもってく
      var c = (key, value) => {
        var constantId = this.allocateConstantId();
        this.setAlias(key, new FluoriteAliasConstant(constantId));
        this.setConstant(constantId, value);
      };
      var m = (key, func) => {
        this.setAlias(key, new FluoriteAliasMacro(func));
      };
      var as2c = (pc, arg) => {
        if (arg instanceof FluoriteNodeMacro) {
          if (arg.getKey() === "_SEMICOLON") {
            return arg.getArguments()
              .filter(a => !(a instanceof FluoriteNodeVoid))
              .map(a => a.getCode(pc))
              .join(",");
          }
        }
        return arg.getCode(pc);
      };
      var as2c2 = (pc, arg) => {
        if (arg instanceof FluoriteNodeMacro) {
          if (arg.getKey() === "_ROUND") {
            if (arg.getArgument(0) instanceof FluoriteNodeMacro) {
              if (arg.getArgument(0).getKey() === "_SEMICOLON") {
                return arg.getArgument(0).getArguments()
                  .filter(a => !(a instanceof FluoriteNodeVoid))
                  .map(a => a.getCode(pc))
                  .join(",");
              }
            }
          }
        }
        return arg.getCode(pc);
      };
      c("PI", Math.PI);
      c("E", Math.E);
      c("TRUE", true);
      c("FALSE", false);
      c("NULL", null);
      c("RAND", new FluoriteLambda((vm, args) => {
        if (args.length == 0) {
          return Math.random();
        }
        if (args.length == 1) {
          var max = vm.toNumber(args[0]);
          return Math.floor(Math.random() * max);
        }
        if (args.length == 2) {
          var min = vm.toNumber(args[0]);
          var max = vm.toNumber(args[1]);
          return Math.floor(Math.random() * (max - min)) + min;
        }
        throw new Error("Illegal argument");
      }));
      c("ADD", new FluoriteLambda((vm, args) => {
        var stream = args[0];
        if (stream === undefined) throw new Error("Illegal argument");
        stream = vm.toStream(stream);

        var result = 0;
        while (true) {
          var next = stream.next();
          if (next === undefined) break;
          result += vm.toNumber(next);
        }
        return result;
      }));
      c("JOIN", new FluoriteLambda((vm, args) => {
        var delimiter = args[1];
        if (delimiter === undefined) delimiter = ",";
        delimiter = vm.toString(delimiter);

        var stream = args[0];
        if (stream === undefined) throw new Error("Illegal argument");
        stream = vm.toStream(stream);

        return stream.toArray().join(delimiter);
      }));
      c("REVERSE", new FluoriteLambda((vm, args) => {
        var stream = args[0];
        if (stream === undefined) throw new Error("Illegal argument");
        return vm.toStreamFromValues(vm.toStream(stream).toArray().reverse());
      }));
      m("_LITERAL_INTEGER", e => {
        if (!(e.node().getArgument(0) instanceof FluoriteNodeTokenInteger)) throw new Error("Illegal argument");
        return "(" + e.node().getArgument(0).getValue() + ")";
      });
      m("_LITERAL_BASED_INTEGER", e => {
        if (!(e.node().getArgument(0) instanceof FluoriteNodeTokenBasedInteger)) throw new Error("Illegal argument");
        return "(" + e.node().getArgument(0).getValue() + ")";
      });
      m("_LITERAL_FLOAT", e => {
        if (!(e.node().getArgument(0) instanceof FluoriteNodeTokenFloat)) throw new Error("Illegal argument");
        return "(" + e.node().getArgument(0).getValue() + ")";
      });
      m("_LITERAL_IDENTIFIER", e => {
        if (!(e.node().getArgument(0) instanceof FluoriteNodeTokenIdentifier)) throw new Error("Illegal argument");
        var key = e.node().getArgument(0).getValue();
        var alias = e.pc().getAliasOrUndefined(e.node().getLocation(), key);
        if (alias === undefined) return JSON.stringify(key); // throw new Error("No such alias '" + key + "'");
        return alias.getCode(e.pc(), e.node().getLocation());
      });
      m("_ROUND", e => e.code(0));
      m("_EMPTY_ROUND", e => "(vm.empty())");
      m("_SQUARE", e => "(vm.toStream(" + e.code(0) + ").toArray())");
      m("_EMPTY_SQUARE", e => "[]");
      m("_RIGHT_ROUND", e => "(vm.call(" + e.code(0) + ", [" + as2c(e.pc(), e.node().getArgument(1)) + "]))");
      m("_RIGHT_EMPTY_ROUND", e => "(vm.call(" + e.code(0) + ", []))");
      m("_RIGHT_SQUARE", e => "(vm.getFromArray(" + e.code(0) + "," + e.code(1) + "))");
      m("_RIGHT_EMPTY_SQUARE", e => "(vm.toStreamFromArray(" + e.code(0) + "))");
      m("_LEFT_PLUS", e => "(vm.toNumber(" + e.code(0) + "))");
      m("_LEFT_MINUS", e => "(-vm.toNumber(" + e.code(0) + "))");
      m("_LEFT_QUESTION", e => "(vm.toBoolean(" + e.code(0) + "))");
      m("_LEFT_EXCLAMATION", e => "(!vm.toBoolean(" + e.code(0) + "))");
      m("_LEFT_AMPERSAND", e => "(vm.toString(" + e.code(0) + "))");
      m("_CIRCUMFLEX", e => "(Math.pow(" + e.code(0) + "," + e.code(1) + "))");
      m("_ASTERISK", e => "(vm.mul(" + e.code(0) + "," + e.code(1) + "))");
      m("_SLASH", e => "(" + e.code(0) + "/" + e.code(1) + ")");
      m("_PERCENT", e => "(" + e.code(0) + "%" + e.code(1) + ")");
      m("_PLUS", e => "(vm.add(" + e.code(0) + "," + e.code(1) + "))");
      m("_MINUS", e => "(" + e.code(0) + "-" + e.code(1) + ")");
      m("_AMPERSAND", e => "(" + e.code(0) + ".toString()+" + e.code(1) + ")");
      m("_TILDE", e => "(vm.range(" + e.code(0) + "," + e.code(1) + "))");
      m("_LESS2", e => "(vm.curryLeft(" + e.code(0) + ",[" + as2c2(e.pc(), e.node().getArgument(1)) + "]))");
      m("_GREATER2", e => "(vm.curryRight(" + e.code(0) + ",[" + as2c2(e.pc(), e.node().getArgument(1)) + "]))");
      m("_AMPERSAND2", e => "(function(){var a=" + e.code(0) + ";return !vm.toBoolean(a)?a:" + e.code(1) + "}())");
      m("_PIPE2", e => "(function(){var a=" + e.code(0) + ";return vm.toBoolean(a)?a:" + e.code(1) + "}())");
      m("_TERNARY_QUESTION_COLON", e => "(vm.toBoolean(" + e.code(0) + ")?" + e.code(1) + ":" + e.code(2) + ")");
      m("_QUESTION_COLON", e => "(function(){var a=" + e.code(0) + ";return a!==null?a:" + e.code(1) + "}())");
      m("_MINUS_GREATER", e => {

        var args = undefined;
        if (e.node().getArgument(0) instanceof FluoriteNodeMacro) {
          if (e.node().getArgument(0).getKey() === "_LITERAL_IDENTIFIER") {
            if (e.node().getArgument(0).getArgument(0) instanceof FluoriteNodeTokenIdentifier) {
              args = [e.node().getArgument(0).getArgument(0).getValue()];
            }
          }
        }
        if (e.node().getArgument(0) instanceof FluoriteNodeMacro) {
          if (e.node().getArgument(0).getKey() === "_EMPTY_ROUND") {
            args = [];
          }
        }
        if (e.node().getArgument(0) instanceof FluoriteNodeMacro) {
          if (e.node().getArgument(0).getKey() === "_ROUND") {
            if (e.node().getArgument(0).getArgument(0) instanceof FluoriteNodeMacro) {
              if (e.node().getArgument(0).getArgument(0).getKey() === "_SEMICOLON") {
                args = [];
                var as = e.node().getArgument(0).getArgument(0).getArguments();
                for (var i = 0; i < as.length; i++) {
                  var a = as[i];
                  if (a instanceof FluoriteNodeMacro) {
                    if (a.getKey() === "_LITERAL_IDENTIFIER") {
                      if (a.getArgument(0) instanceof FluoriteNodeTokenIdentifier) {
                        args.push(a.getArgument(0).getValue());
                        continue;
                      }
                    }
                  }
                  throw new Error("Illegal lambda argument: " + a);
                }
              }
            }
          }
        }
        if (e.node().getArgument(0) instanceof FluoriteNodeMacro) {
          if (e.node().getArgument(0).getKey() === "_ROUND") {
            if (e.node().getArgument(0).getArgument(0) instanceof FluoriteNodeMacro) {
              if (e.node().getArgument(0).getArgument(0).getKey() === "_LITERAL_IDENTIFIER") {
                if (e.node().getArgument(0).getArgument(0).getArgument(0) instanceof FluoriteNodeTokenIdentifier) {
                  args = [e.node().getArgument(0).getArgument(0).getArgument(0).getValue()];
                }
              }
            }
          }
        }
        if (args === undefined) throw new Error("Illegal lambda argument: " + e.node().getArgument(0));

        var aliases = args.map(a => new FluoriteAliasVariable(e.pc().allocateVariableId()));

        var check = "if(args.length!=" + args.length + ")throw new Error(\"Number of lambda arguments do not match: \" + args.length + \" != " + args.length + "\");";

        var vars = aliases.map((a, i) => "var " + a.getRawCode(e.pc(), e.node().getLocation()) + "=args[" + i + "];").join("");

        e.pc().pushFrame();
        for (var i = 0; i < args.length; i++) {
          e.pc().getFrame()[args[i]] = aliases[i];
        }
        var body = e.code(1);
        e.pc().popFrame();

        return "(vm.createLambda((vm,args)=>{" + check + vars + "return " + body + ";}))";
      });
      m("_COMMA", e => {
        var nodes = [];
        var limit = e.node().getArgumentCount();
        for (var i = 0; i < limit; i++) {
          var node = e.node().getArgument(i);
          if (!(node instanceof FluoriteNodeVoid)) {
            nodes.push(node.getCode(e.pc()));
          }
        }
        return "(vm.toStreamFromValues([" + nodes.join(",") + "]))";
      });
      m("_PIPE", e => {
        var key = undefined;
        var stream = undefined;

        if (e.node().getArgument(0) instanceof FluoriteNodeMacro) {
          if (e.node().getArgument(0).getKey() === "_COLON") {
            if (e.node().getArgument(0).getArgument(0) instanceof FluoriteNodeMacro) {
              if (e.node().getArgument(0).getArgument(0).getKey() === "_LITERAL_IDENTIFIER") {
                if (e.node().getArgument(0).getArgument(0).getArgument(0) instanceof FluoriteNodeTokenIdentifier) {
                  key = e.node().getArgument(0).getArgument(0).getArgument(0).getValue();
                  stream = e.node().getArgument(0).getArgument(1).getCode(e.pc());
                }
              }
            }
          }
        }

        if (key === undefined) key = "_";
        if (stream === undefined) stream = e.code(0);

        var alias = new FluoriteAliasVariable(e.pc().allocateVariableId());

        e.pc().pushFrame();
        e.pc().getFrame()[key] = alias;
        var body = e.code(1);
        e.pc().popFrame();

        return "(vm.map(vm.toStream(" + stream + ")," + alias.getRawCode(e.pc(), e.node().getLocation()) + "=>" + body + "))";
      });
      m("_EQUAL_GREATER", e => "(vm.call(" + e.code(1) + ", [" + as2c2(e.pc(), e.node().getArgument(0)) + "]))");
    }

  }

  class FluoriteVirtualMachine {

    constructor(constants) {
      this.constants = constants;
    }

    empty() {
      return new FluoriteStreamEmpty();
    }

    range(start, end) {
      return new FluoriteStreamRange(this.toNumber(start), this.toNumber(end));
    }

    toStream(value) {
      if (value instanceof FluoriteStream) {
        return value;
      } else {
        return new FluoriteStreamScalar(value);
      }
    }

    toStreamFromArray(array) {
      if (!(array instanceof Array)) throw new Error("Illegal argument: " + array);
      return new FluoriteStreamValues(array);
    }

    toStreamFromValues(values) {
      return new FluoriteStreamValues(values);
    }

    map(stream, func) {
      return new FluoriteStreamMap(stream, func);
    }

    call(lambda, args) {
      if (!(lambda instanceof FluoriteLambda)) throw new Error("Cannot call a non-lambda object: " + lambda);
      return lambda.call(this, args);
    }

    toNumber(value) {
      if (Number.isFinite(value)) return value;
      if (value === null) return 0;
      if (value === true) return 1;
      if (value === false) return 0;
      if (value instanceof Array) {
        return value.length;
      }
      if (typeof value === 'string' || value instanceof String) {
        var result = Number(value);
        if (Number.isNaN(result)) throw new Error("Cannot convert to number: " + value);
        return result;
      }
      throw new Error("Cannot convert to number: " + value);
    }

    createLambda(func) {
      return new FluoriteLambda(func);
    }

    curryLeft(lambda, values) {
      if (!(lambda instanceof FluoriteLambda)) throw new Error("Cannot curry a non-lambda object: " + lambda);
      return lambda.curryLeft(values);
    }

    curryRight(lambda, values) {
      if (!(lambda instanceof FluoriteLambda)) throw new Error("Cannot curry a non-lambda object: " + lambda);
      return lambda.curryRight(values);
    }

    toString(value) {
      if (value === undefined) return super.toString(); // VMを文字列化する
      if (value === null) return "NULL";
      if (value === true) return "TRUE";
      if (value === false) return "FALSE";
      if (value instanceof Array) {
        return value.map(a => this.toString(a)).join(",");
      }
      return value.toString();
    }

    toBoolean(value) {
      if (value === 0) return false;
      if (value === null) return false;
      if (value === false) return false;
      if (value === "") return false;
      if (value instanceof Array) {
        if (value.length == 0) return false;
      }
      if (value instanceof FluoriteStream) {
        throw new Error("Cannot convert to boolean: " + value);
      }
      return true;
    }

    add(a, b) {
      if (Number.isFinite(a)) {
        return a + this.toNumber(b);
      }
      if (a instanceof Array) {
        if (b instanceof Array) {
          var result = [];
          Array.prototype.push.apply(result, a);
          Array.prototype.push.apply(result, b);
          return result;
        }
      }
      if (typeof a === 'string' || a instanceof String) {
        return a + this.toString(b);
      }
      throw new Error("Illegal argument: " + a + ", " + b);
    }

    mul(a, b) {
      if (Number.isFinite(a)) {
        return a * this.toNumber(b);
      }
      if (a instanceof Array) {
        var result = [];
        b = this.toNumber(b);
        for (var i = 0; i < b; i++) {
          Array.prototype.push.apply(result, a);
        }
        return result;
      }
      if (typeof a === 'string' || a instanceof String) {
        return a.repeat(this.toNumber(b));
      }
      throw new Error("Illegal argument: " + a + ", " + b);
    }

    getFromArray(array, index) {
      if (array instanceof Array) {
        return array[this.toNumber(index)];
      }
      throw new Error("Illegal argument: " + array + ", " + index);
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

    getCode(pc) {
      Fluorite.throwCompileError(this._location, "Not Implemented");
    }

    getTree(pc) {
      Fluorite.throwCompileError(this._location, "Not Implemented");
    }

  }

  class FluoriteNodeVoid extends FluoriteNode {

    constructor(location) {
      super(location);
    }

    getCode(pc) {
      Fluorite.throwCompileError(this._location, "Cannot stringify void node");
    }

    getTree(pc) {
      return "VOID";
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

    getCode(pc) {
      Fluorite.throwCompileError(this.getLocation(), "Tried to stringify raw token");
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
        Fluorite.throwCompileError(this.getLocation(), "Not enough arguments: " + (this._args.length) + " < " + (index + 1));
      } else {
        return this._args[index];
      }
    }

    getArgumentCount() {
      return this._args.length;
    }

    getCode(pc) {
      var alias = pc.getAlias(this.getLocation(), this._key);
      if (alias instanceof FluoriteAliasMacro) {
        var result;
        try {
          result = alias.getMacro()(new FluoriteMacroEnvironment(pc, this));
        } catch (e) {
          if (e instanceof FluoriteError) {
            throw e;
          } else {
            Fluorite.throwCompileError(this.getLocation(), "" + e.message + " in macro '" + this._key + "'");
          }
        }
        return result;
      }
      Fluorite.throwCompileError(this.getLocation(), "No such macro '" + this._key + "'");
    }

    getTree() {
      return this._key + "[" + this._args.map(a => a.getTree()).join(",") + "]";
    }

  }

  class FluoriteMacroEnvironment {

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

    code(index) {
      return this._node.getArgument(index).getCode(this._pc);
    }

  }

  //

  class FluoriteAlias {

    constructor() {

    }

    getCode(pc, location) {
      throw new Error("Not Implemented");
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

    getCode(pc, location) {
      throw new Error("Cannot stringify a macro alias");
    }

  }

  class FluoriteAliasVariable extends FluoriteAlias {

    constructor(variableId) {
      super();
      this._variableId = variableId;
    }

    getRawCode(pc, location) {
      return "v_" + this._variableId;
    }

    getCode(pc, location) {
      return "(v_" + this._variableId + ")";
    }

  }

  class FluoriteAliasConstant extends FluoriteAlias {

    constructor(constantId) {
      super();
      this._constantId = constantId;
    }

    getCode(pc, location) {
      return "(vm.constants[" + this._constantId + "])";
    }

  }

  //

  class FluoriteStream {

    toArray() {
      var result = [];
      while (true) {
        var item = this.next();
        if (item === undefined) break;
        result.push(item);
      }
      return result;
    }

    next() {
      throw new Error("Not Implemented");
    }

    toString() {
      return "[FluoriteStream]";
    }

  }

  class FluoriteStreamEmpty extends FluoriteStream {

    constructor() {
      super();
    }

    next() {
      return undefined;
    }

  }

  class FluoriteStreamRange extends FluoriteStream {

    constructor(start, end) {
      super();
      this._start = start;
      this._end = end;
      this._stepdown = end < start;
      this._i = start;
    }

    next() {
      var result = this._i;

      if (this._stepdown) {
        if (this._i < this._end) return undefined;
        this._i--;
      } else {
        if (this._i > this._end) return undefined;
        this._i++;
      }
      
      return result;
    }

  }

  class FluoriteStreamValues extends FluoriteStream {

    constructor(values) {
      super();
      this._values = values;
      this._i = 0;
      this._currentStream = undefined;
    }

    next() {
      while (true) {
        if (this._currentStream !== undefined) {
          var result = this._currentStream.next();
          if (result !== undefined) return result;
          this._currentStream = undefined;
        }

        if (this._i >= this._values.length) return undefined;

        var result = this._values[this._i];
        this._i++;
        if (result instanceof FluoriteStream) {
          this._currentStream = result;
          continue;
        }
        return result;
      }
    }

  }

  class FluoriteStreamMap extends FluoriteStream {

    constructor(stream, func) {
      super();
      this._stream = stream;
      this._func = func;
      this._currentStream = undefined;
    }

    next() {
      while (true) {
        if (this._currentStream !== undefined) {
          var result = this._currentStream.next();
          if (result !== undefined) return result;
          this._currentStream = undefined;
        }

        var result = this._stream.next();
        if (result === undefined) return undefined;
        result = this._func(result);
        if (result instanceof FluoriteStream) {
          this._currentStream = result;
          continue;
        }
        return result;
      }
    }

  }

  class FluoriteStreamScalar extends FluoriteStream {

    constructor(value) {
      super();
      this._value = value;
      this._used = false;
    }

    next() {
      if (this._used) return undefined;
      this._used = true;
      return this._value;
    }

  }

  //

  class FluoriteLambda {

    constructor(func) {
      this._func = func;
    }

    call(vm, args) {
      return this._func(vm, args);
    }

    curryLeft(values) {
      return new FluoriteLambda((vm, args) => {
        var newArgs = [];
        Array.prototype.push.apply(newArgs, values);
        Array.prototype.push.apply(newArgs, args);
        return this._func(vm, newArgs);
      });
    }

    curryRight(values) {
      return new FluoriteLambda((vm, args) => {
        var newArgs = [];
        Array.prototype.push.apply(newArgs, args);
        Array.prototype.push.apply(newArgs, values);
        return this._func(vm, newArgs);
      });
    }

    toString() {
      return "[FluoriteLambda]";
    }

  }

}

//////////////////////////////////////////////////////////////////

Root
  = _ main:Expression _ {

    var pc = new FluoriteParserContext();

    var code;
    try {
      code = main.getCode(pc);
    } catch (e) {
      return ["Compile Error", "" + e, main.getTree()];
    }

    var result;
    var resultString;
    try {
      var vm = pc.createVirtualMachine();
      result = vm.toStream(eval(code)).toArray();
      resultString = result.map(a => vm.toString(a) + "\n").join("");
    } catch (e) {
      return ["Runtime Error", "" + e, code, main.getTree()];
    }

    return ["OK", resultString, result, code, main.getTree()];
  }

//

_ "Comment"
  = ( [ \t\r\n]+
    / "#!" [^\r\n]*
    / "//" [^\r\n]*
  )*

TokenInteger "Integer"
  = [0-9] [0-9_]* { return new FluoriteNodeTokenInteger(location(), parseInt(text().replace(/_/g, ""), 10), text()); }

TokenBasedInteger "BasedInteger"
  = base:
      ( [0-9]+ { return parseInt(text(), 10); }
      / [bB] { return 2; }
      / [oO] { return 8; }
      / [hH] { return 16; }
    ) "#" body:([0-9a-zA-Z] [0-9a-zA-Z_]* { return text(); }) {
    if (base < 2) throw new Error("Illegal base: " + base);
    if (base > 36) throw new Error("Illegal base: " + base);
    var number = parseInt(body.replace(/_/g, ""), base);
    if (Number.isNaN(number)) throw Fluorite.throwCompileError(location(), "Illegal based integer body: '" + body + "' (base=" + base + ")");
    return new FluoriteNodeTokenBasedInteger(location(), number, text());
  }

TokenFloat "Float"
  = ( [0-9] [0-9_]* [.] [0-9] [0-9_]* [eE] [+-]? [0-9]+
    / [0-9] [0-9_]* [.] [0-9] [0-9_]*
    / [0-9] [0-9_]* [eE] [+-]? [0-9]+
  ) { return new FluoriteNodeTokenFloat(location(), parseFloat(text().replace(/_/g, "")), text()); }

TokenIdentifier "Identifier"
  = [a-zA-Z_] [a-zA-Z0-9_]* { return new FluoriteNodeTokenIdentifier(location(), text(), text()); }

//

LiteralInteger
  = main:TokenInteger { return new FluoriteNodeMacro(location(), "_LITERAL_INTEGER", [main]); }

LiteralBasedInteger
  = main:TokenBasedInteger { return new FluoriteNodeMacro(location(), "_LITERAL_BASED_INTEGER", [main]); }

LiteralFloat
  = main:TokenFloat { return new FluoriteNodeMacro(location(), "_LITERAL_FLOAT", [main]); }

LiteralIdentifier
  = main:TokenIdentifier { return new FluoriteNodeMacro(location(), "_LITERAL_IDENTIFIER", [main]); }

Literal
  = LiteralFloat
  / LiteralBasedInteger
  / LiteralInteger
  / LiteralIdentifier

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
    return new FluoriteNodeMacro(location(), key.getValue(), args);
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
  ) { return new FluoriteNodeMacro(main[0], main[1], main[2] != null ? [main[2]] : []); }

Factor
  = Literal
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
  ))* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i][1];
      result = new FluoriteNodeMacro(t[0], t[1], t[2] != null ? [result, t[2]] : [result]);
    }
    return result;
  }

Left
  = Right
  / head:
    ( "+" { return [location(), "_LEFT_PLUS"]; }
    / "-" { return [location(), "_LEFT_MINUS"]; }
    / "?" { return [location(), "_LEFT_QUESTION"]; }
    / "!" { return [location(), "_LEFT_EXCLAMATION"]; }
    / "&" { return [location(), "_LEFT_AMPERSAND"]; }
  ) _ tail:Left {
    return new FluoriteNodeMacro(head[0], head[1], [tail]);
  }

Pow
  = head:(Left _
    ( "^" { return [location(), "_CIRCUMFLEX"]; }
    / "**" { return [location(), "_ASTERISK2"]; }
  ) _)* tail:Left {
    var result = tail;
    for (var i = head.length - 1; i >= 0; i--) {
      var h = head[i];
      result = new FluoriteNodeMacro(h[2][0], h[2][1], [h[0], result]);
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
      result = new FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
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
      result = new FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
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
      result = new FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
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
      result = new FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Shift
  = head:Range tail:(_
    ( "<<" { return [location(), "_LESS2"]; }
    / ">>" { return [location(), "_GREATER2"]; }
  ) _ Range)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

And
  = head:Shift tail:(_
    ( "&&" { return [location(), "_AMPERSAND2"]; }
  ) _ Shift)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
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
      result = new FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Condition
  = head:Or _ op:("?" { return location(); }) _ a:Condition _ ":" _ b:Condition {
    return new FluoriteNodeMacro(op, "_TERNARY_QUESTION_COLON", [head, a, b]);
  }
  / head:Or _ op:("?:" { return location(); }) _ b:Condition {
    return new FluoriteNodeMacro(op, "_QUESTION_COLON", [head, b]);
  }
  / Or

Lambda
  = head:(Condition _
    ( "->" { return [location(), "_MINUS_GREATER"]; }
  ) _)* tail:Condition {
    var result = tail;
    for (var i = head.length - 1; i >= 0; i--) {
      var h = head[i];
      result = new FluoriteNodeMacro(h[2][0], h[2][1], [h[0], result]);
    }
    return result;
  }

Stream
  = head:(Lambda _)? "," tail:
    ( _ main:Lambda _ "," { return main; }
    / _ "," { return null; }
  )* last:(_ Lambda)? {
    var result = [];
    result.push(head != null ? head[0] : new FluoriteNodeVoid(location()));
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result.push(t != null ? t : new FluoriteNodeVoid(location()));
    }
    result.push(last != null ? last[1] : new FluoriteNodeVoid(location()));
    return new FluoriteNodeMacro(location(), "_COMMA", result);
  }
  / Lambda

Pair
  = head:Stream tail:(_
    ( ":" { return [location(), "_COLON"]; }
  ) _ Stream)* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {//
      var t = tail[i];
      result = new FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Pipe
  = head:(Pair _
    ( "|" { return [location(), "_PIPE"]; }
  ) _)* tail:Pair {
    var result = tail;
    for (var i = head.length - 1; i >= 0; i--) {
      var h = head[i];
      result = new FluoriteNodeMacro(h[2][0], h[2][1], [h[0], result]);
    }
    return result;
  }

Arrow
  = head:Pipe tail:
    ( _ ("=>" { return [location(), "_EQUAL_GREATER"]; }) _ Pair
    / _ ("|" { return [location(), "_PIPE"]; }) _ Pipe
  )* {
    var result = head;
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result = new FluoriteNodeMacro(t[1][0], t[1][1], [result, t[3]]);
    }
    return result;
  }

Arguments
  = head:(Arrow _)? ";" tail:
    ( _ main:Arrow _ ";" { return main; }
    / _ ";" { return null; }
  )* last:(_ Arrow)? {
    var result = [];
    result.push(head != null ? head[0] : new FluoriteNodeVoid(location()));
    for (var i = 0; i < tail.length; i++) {
      var t = tail[i];
      result.push(t != null ? t : new FluoriteNodeVoid(location()));
    }
    result.push(last != null ? last[1] : new FluoriteNodeVoid(location()));
    return new FluoriteNodeMacro(location(), "_SEMICOLON", result);
  }
  / Arrow

//

Expression
  = Arguments

