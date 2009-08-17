# $Id$

method built_in($/, $key)                { PASSTHRU($/, $key); }

method builtin_clone($/) {
	my $past := PAST::Op.new(
		:name('clone'),
		:node($/),
		:pasttype('inline'),
		:inline('    %r = clone %0'));
	$past.push($<obj>.ast);
	#DUMP($past);
	make $past;
}

method builtin_concat($/) {
	my $past := PAST::Op.new(
		:name('concat'),
		:node($/),
		:pasttype('inline'));

	my $argnum	:= 1;
	my $inline		:= "    %r = concat %0, %1\n";
	$past.push($<str>.ast);

	for $<val> {
		$past.push($_.ast);

		if $argnum > 1 {
			# First one is a special case, above
			$inline := $inline ~ "    concat %r, %" ~ $argnum ~ "\n";
		}

		$argnum++;
		if $argnum >= 10 {
			$/.panic("Too many arguments to builtin 'concat'");
		}
	}

	$past.inline($inline);
	#DUMP($past);
	make $past;
}

method builtin_elements($/) {
	my $past := PAST::Op.new(
		:name('builtin-elements'),
		:node($/),
		:pasttype('pirop'),
		:pirop('elements IP'),
		$<arr>.ast);
	#DUMP($past);
	make $past;
}

method builtin_exists($/) {
	my $past := PAST::Op.new(
		:name('builtin-exists'),
		:node($/),
		:pasttype('inline'),
		:inline("\t$I0 = exists %0[%1]\n"
			~ "\t%r = box $I0\n"));
	
	my $index := $<index>.ast;
	
	unless $index.isa(PAST::Var) && $index.scope() eq 'keyed' {
		$/.panic("Builtin 'exists' requires a postfix index expression");
	}
	
	$past.push($index[0]);
	$past.push($index[1]);
	
	#DUMP($past);
	make $past;
}

method builtin_find_caller_lex($/) {
	my $past := PAST::Op.new(
		:name('builtin-find_caller_lex'),
		:node($/),
		:pasttype('pirop'),
		:pirop('find_caller_lex PS'));
	
	$past.push($<name>.ast);
	
	#DUMP($past);
	make $past;
}

method builtin_isa($/) {
	my $past := PAST::Op.new(
		:name('isa'),
		:node($/),
		:pasttype('pirop'),
		:pirop('isa'));

	# FIXME: Need to convert class.ast into a lookup of the class whatever-it-is.
	# E.g., look up a hll-global-symbol, with get_global (p6) or with get_class,
	# get that result in a pmc register, then use that to pass to isa.
	# isa 'string' may work, but I need to know more about when exactly.
	# (Probably for PMCs, maybe for some kind of 'a::b' paths?)
	$past.push($<obj>.ast);
	
	my $nsp := Array::clone($<class>.ast.namespace());
	$nsp.push($<class>.ast.name());
	
	if  $<class>.ast<is_rooted> {
		$nsp.unshift($<class>.ast<hll>);
	} 
	else {
		$nsp.unshift(close::Compiler::Scopes::fetch_current_hll());
	}
		
	my $class_key := Array::join('::', $nsp);
	my $class := PAST::Op.new(
		:node($<class>),
		:pasttype('inline'),
		:inline("\t$P0 = split '::', '" ~ $class_key ~ "'\n"
			~ "\t%r = get_root_namespace $P0\n"));
	$past.push($class);
	#DUMP($past);
	make $past;
}

method builtin_isntsame($/) {
	my $past := PAST::Op.new(
		:name('isntsame'),
		:node($/),
		:pasttype('pirop'),
		:pirop('isntsame IPP'));
	$past.push($<arg1>.ast);
	$past.push($<arg2>.ast);
	#DUMP($past);
	make $past;
}

method builtin_isnull($/) {
	my $past := PAST::Op.new(
		:name('isnull'),
		:node($/),
		:pasttype('pirop'),
		:pirop('isnull'));

	$past.push($<expression>.ast);
	#DUMP($past);
	make $past;
}

method builtin_issame($/) {
	my $past := PAST::Op.new(
		:name('isntsame'),
		:node($/),
		:pasttype('pirop'),
		:pirop('issame IPP'));
	$past.push($<arg1>.ast);
	$past.push($<arg2>.ast);
	#DUMP($past);
	make $past;
}



sub symbol_defined_anywhere($past) {
	if $past.scope() ne 'package' {
		my $name := $past.name();
		my $def;

		for get_stack() {
			$def := $_.symbol($name);

			if $def {
				if $def<decl>.HOW.can($def<decl>, "scope") {
					#say("--- FOUND: ", $def<decl>.scope());
				}
				elsif $def<decl>.isa("PAST::Block") {
					#say("--- FOUND: Block");
				}
				else {
					#say("--- FOUND in unrecognized object:");
					#DUMP($def<decl>, "Declaration");
					DIE("Unexpected data item");
				}

				return $def;
			}
		}
	}

	# Not any kind of local variable, parameter, etc. Try global.
	return get_global_symbol_info($past);
}

# NB: This operator gives precedence to variable names over class names.
# If you create a variable called 'Iterator', you won't be able to create a new
# Iterator (class) object in that scope. Sucks for you.

method builtin_new($/) {
	my $past := PAST::Op.new(
		:name('new-expr'),
		:node($/),
		:pasttype('inline'),
		:inline('    %r = new %0'));

	my $class := $<classname>.ast;

	if !$class<adjectives><class> && symbol_defined_anywhere($class) {
		$past.inline("\t%r = new '%0'\n");
		$past.push($class);
	}
	else {
		# Not a var - convert it to a literal.
		my $lit := PAST::Val.new(
			:name('class name: ' ~ $<identifier>),
			:node($class),
			:returns('String'),
			:value($class.name()));
		$past.push($lit);
	}

	if $<args1> {
		$past.inline('    %r = new %0, %1');
		$past.push($<args1>[0].ast);
	}

	#DUMP($past);
	make $past;
}

method builtin_null($/) {
	my $past := PAST::Op.new(
		:name('null'),
		:node($/),
		:pasttype('inline'),
		:inline('    null %r'));

	make $past;
}

method builtin_pop($/) {
	my $past := PAST::Op.new(
		:name('builtin-pop'),
		:node($/),
		:pasttype('inline'),
		:inline('    %r = pop %0'));
	$past.push($<arr>.ast);

	#DUMP($past);
	make $past;
}

method builtin_push($/) {
	my $past := PAST::Op.new(
		:name('builtin-push'),
		:node($/),
		:pasttype('inline'));
	$past.push($<arr>.ast);

	my $argnum := 1;
	my $inline := "";

	for $<val> {
		$past.push($_.ast);
		$inline := $inline ~ "\t" ~ 'push %0, %' ~ $argnum ~ "\n";

		$argnum++;
		if $argnum > 10 {
			$/.panic("Too many arguments to builtin 'push'");
		}
	}

	$past.inline($inline);
	make $past;
}

# TODO - Need some way to shift/unshift a list. (List expressions for call/return)
method builtin_shift($/) {
	my $past := PAST::Op.new(
		:name('builtin-shift'),
		:node($/),
		:pasttype('inline'),
		:inline('    %r = shift %0'),
		$<arr>.ast);
	#$past.push($<arr>.ast);

	#DUMP($past);
	make $past;
}

method builtin_split($/) {
	my $past := PAST::Op.new(
		:name('builtin-split'),
		:node($/),
		:pasttype('pirop'),
		:pirop('split Pss'));
	$past.push($<delim>.ast);
	$past.push($<str>.ast);
	#DUMP($past);
	make $past;
}

method builtin_typeof($/) {
	my $obj := $<obj>.ast;
	my $past := PAST::Op.new(
		:name('builtin-typeof'),
		:node($/),
		:pasttype('pirop'),
		:pirop('typeof SP'));
	$past.push($obj);
	#DUMP($past);
	make $past;
}

method builtin_unshift($/) {
	my $arr := $<arr>.ast;
	my $past := PAST::Stmts.new(
		:name('unshift-multiple'),
		:node($/));

	for $<val> {
		my $op := PAST::Op.new(
			:name('builtin-unshift'),
			:node($/),
			:pasttype('inline'),
			:inline('    unshift %0, %1'),
			$arr,
			$_.ast);
		$past.push($op);
	}

	if +@($past) == 1 {
		$past := $past.pop();
	}

	#DUMP($past);
	make $past;
}

