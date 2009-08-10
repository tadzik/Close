# $Id$

method statement($/, $key)              { PASSTHRU($/, $key); }

method extern_statement($/, $key) { PASSTHRU($/, $key); }

method null_statement($/) {
	my $past := PAST::Op.new(:node($/), :pasttype('null'));
	DUMP($past);
	make $past;
}

method expression_statement($/) {
	my $past := $<expression>.ast;
	DUMP($past);
	make $past;
}

method compound_statement($/, $key) {
	if $key eq 'open' {
		NOTE("Creating new block for compound_statement, pushing on scope stack");
		my $past := close::Compiler::Node::create('compound_statement');
		DUMP($past);
		close::Compiler::Scopes::push($past);
	}
	elsif $key eq 'close' {
		my $past := close::Compiler::Scopes::pop('compound_statement');
		NOTE("Popped compound_statement from scope stack");
		
		for $<statements> {
			$past.push($_.ast);
		}
		
		NOTE("Block has ", +@($past), " elements inside");
		DUMP($past);
		make $past;
		NOTE("Done here");
	} 
	else {
		DIE("Unexpected $key value: '", $key, "' in action method compound_statement");
	}
}

method conditional_statement($/) {
    my $keyw;
    $keyw := (substr($<kw>, 0, 2) eq 'if')
        ?? 'if'
        !! 'unless';

    my $past := PAST::Op.new(:node($/), :pasttype($keyw));
    $past.push($<expression>.ast);      # test
    $past.push($<then>.ast);            # then

    if $<else> {
        $past.push($<else>[0].ast);     # else
    }

    DUMP($past);
    make $past;
}

method declaration_statement($/, $key) { PASSTHRU($/, $key); }

method labeled_statement($/, $key) {
	my $past := PAST::Stmts.new(:name('labeled stmt'), :node($/));

	for $<label> {
		$past.push($_.ast);
	}

	$past.push($<local_statement>.ast);

	DUMP($past);
	make $past;
}

method label($/) {
	my $label := ~$<BAREWORD>;
	my $past := PAST::Op.new(
		:name('label: ' ~ $label),
		:node($/),
		:pasttype('inline'),
		:inline($label ~ ":\n"));
	DUMP($past);
	make $past;
}

method local_statement($/, $key) { PASSTHRU($/, $key); }

method jump_statement($/, $key) {
	my $past;

	if $key eq 'goto' {
		$past := PAST::Op.new(
			:name('goto ' ~ $<label>),
			:node($/),
			:pasttype('inline'),
			:inline('    goto ' ~ $<label>));
	}
	elsif $key eq 'return' {
		$past := PAST::Op.new(
			:name("return"),
			:node($/),
			:pasttype('pirop'),
			:pirop('return'));

		if $<retval> {
			$past.push($<retval>[0].ast);
		}
	}
	elsif $key eq 'tailcall' {
		my $call_past := $<retval>.ast;
		
		$past := PAST::Op.new(
			:name("tailcall"),
			:node($/),
			:pasttype('inline'));

		my $inline := '';
		
		my $arg_i := 0;
		
		if $call_past.pasttype() eq 'call' {
			if $call_past.name() {
				$inline := "    .tailcall '" ~ $call_past.name() ~ "'";
				$arg_i := 0;
			}
			else {
				$inline := "    .tailcall %0";
				$arg_i := 1;
			}
		}
		elsif $call_past.pasttype() eq 'callmethod' {
			if $call_past.name() {
				$inline := "    .tailcall %0.'" ~ $call_past.name() ~ "'";
				$arg_i := 1;
			}
			else {
				$inline := "    .tailcall %0.%1";
				$arg_i := 2;
			}
		}
		else {
			$/.panic("Invalid pasttype '" ~ $call_past.pasttype() ~ "' in tailcall");
		}

		$inline := $inline ~ '(';
		if $arg_i < +@($call_past) {
			$inline := $inline ~ '%' ~ $arg_i++;
		}
		
		while $arg_i < +@($call_past) {
			$inline := $inline ~ ', %' ~ $arg_i++;
		}

		$inline := $inline ~ ")\n";
		$past.inline($inline);
		DUMP($past);
	}
	else {
		$/.panic("Unanticipated type of jump statement: '"
			~ $key
			~ "' - you need to implement it!");
	}

	DUMP($past);
	make $past;
}

method foreach_statement($/) {
	NOTE("started");
	my $loop_var	:= $<header><loop_var>.ast;
	my $list		:= $<header><list>.ast;
	my $body		:= $<body>.ast;
	DUMP(:list($list), :loop_var($loop_var), :body($body));

	my $past := close::Compiler::Node::create('foreach_statement',
		:loop_var($loop_var),
		:list($list));
	$past.push($body);
		
	DUMP($past);
	make $past;
}

method foreach_statement2($/) {
	NOTE("started");
	my $iter	:= $<header><loop_var>.ast;
	DUMP($iter);
	my $list	:= $<header><list>.ast;
	DUMP($list);
	my $body	:= $<body>.ast;
	DUMP($body);

	my $iter_ref	:= $iter;
	
	if $iter.isa(PAST::VarList) {
		# Need to add this declaration to containing block.
		# FIXME: How to solve (finally) nested blocks problem?
		# Change this to a declaration in parent block, and a Var ref here.
		# Do that later?
		$iter_ref := PAST::Var.new(:name($iter.name()), :lvalue(1));
	}
	
	my $past := close::Compiler::Node::create('foreach', :node($/));
	
	my $iterator := PAST::Op.new(
		:inline("    %r = iter %0"),
		:name("new-iterator"),
		:node($<header><loop_var>),
		:pasttype("inline"));
	$iterator.push($list);
	my $iter_name := make_temporary_name('foreach_' ~ $iter_ref.name() ~ '_iter');
	# FIXME: This isn't enough. Need to do a bind, or assign, rather than a viviself, because
	# reusing vars should not trigger auto-vivification.
	my $iter_tempvar := PAST::Var.new(
		:isdecl(1),
		:lvalue(1),
		:name($iter_name),
		:node($<header><loop_var>),
		:scope('register'),
		:viviself($iterator));
	$past.push($iter_tempvar);

	# $past now looks like:
	# $P0 = <list>
	# it = iter $P0
	# .local pmc tempvar
	# tempvar = it
	
	my $while := PAST::Op.new(
		:name('foreach-while'),
		:node($<body>),
		:pasttype('while'));

	my $iter_read := PAST::Var.new(
		:name($iter_name),
		:node($<body>),
		:scope('register'));

	$while.push($iter_read);
	
	my $block := PAST::Stmts.new(:name('foreach-body'), :node($<body>));
	my $shift := PAST::Op.new(
		:node($<header><loop_var>),
		:pasttype('bind'));
	$shift.push($iter_tempvar);
	$shift.push(
		PAST::Op.new(
			:inline('    %r = shift %0'),
			:name('shift-iterator'),
			:node($<header><loop_var>),
			:pasttype('inline'),
			$iter_read));
	$block.push($shift);
	$block.push($body);
	$while.push($block);
	$past.push($while);

	NOTE("Foreach generates Stmts( init, while (condition, stmts( shift, block)))");
	DUMP($past);
	make $past;
}

method do_while_statement($/) {
    my $past := PAST::Op.new(:name('do-while-loop'), :node($/));
    my $keyword := substr(~$<kw>, 0, 5);
    $past.pasttype('repeat_' ~ $keyword);
    $past.push($<expression>.ast);
    $past.push($<local_statement>.ast);
    DUMP($past);
    make $past;
}

method while_do_statement($/) {
	my $past := PAST::Op.new(:name('while-do-loop'), :node($/));
	my $keyword := substr(~$<kw>, 0, 5);
	$past.pasttype($keyword);
	$past.push($<expression>.ast);
	$past.push($<local_statement>.ast);

	DUMP($past);
	make $past;
}
