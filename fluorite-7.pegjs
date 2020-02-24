{
	function range(start, end) {
    	return Array.from({length: (end - start) + 1}, (_, i) => start + i);
    }
    function v_add(a) {
    	return a.reduce((prev, current, i, arr) => prev + current);
    }
}
Root = main:Expression { return [main, eval(main)]; }
Number = main:[0-9]+ { return main.join(""); }
Identifier = main:[a-z_]+ { return main.join(""); }
Variable = main:Identifier { return "v_" + main; }
Bracket = '(' main:Expression ')' { return main; }
Factor = Number / Variable / Bracket
Mul = head:Factor tails:([*~] Factor)* {
    tails.map(tail => {
    	if (tail[0] == "~") {
    		head = "(range(" + head + ", " + tail[1] + "))";
        } else {
        	head = "(" + head + " " + tail[0] + " " + tail[1] + ")";
        }
    });
	return head;
}
Map = name:Identifier '=' list:Mul ':' content:Map {
	return "(" + list + ".map(v_" + name + " => " + content + "))";
}
	/ list:Mul ':' content:Map {
	return "(" + list + ".map(v__ => " + content + "))";
}
	/ Mul
Pipe = head:Map tails:([|] Map)* {
    tails.map(tail => head = "(" + tail[1] + "(" + head + "))");
	return head;
}
Expression = Pipe
