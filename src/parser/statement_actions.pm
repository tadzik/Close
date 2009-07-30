method statement($/, $key)              { PASSTHRU($/, $key, 'statement'); }

method null_stmt($/) {
    my $past := PAST::Op.new(:node($/), :pasttype('null'));
    #DUMP($past, "null stmt");
    make $past;
}

method expression_stmt($/) {
    my $past := $<expression>.ast;
    #DUMP($past, "expression_stmt");
    make $past;
}

method compound_stmt($/) {
	my $past := PAST::Stmts.new(:node($/), :name("compound_stmt"));

	for $<item> {
		#DUMP($_.ast, "item in block");
		$past.push($_.ast);
	}

	make $past;
}

method conditional_stmt($/) {
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

    #DUMP($past, $keyw ~ " statement");
    make $past;
}

method declaration_statement($/) { PASSTHRU($/, 'declaration', 'declaration_statement'); }

method labeled_stmt($/, $key) {
	my $past := PAST::Stmts.new(:name('labeled stmt'), :node($/));

	for $<label> {
		$past.push($_.ast);
	}

	$past.push($<statement>.ast);

	#DUMP($past, "labeled stmt");
	make $past;
}

method label($/) {
	my $label := ~$<bareword>;
	my $past := PAST::Op.new(
		:name('label: ' ~ $label),
		:node($/),
		:pasttype('inline'),
		:inline($label ~ ":\n"));
	#DUMP($past, "label");
	make $past;
}

method jump_stmt($/, $key) {
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
		#DUMP($past, "tailcall");
	}
	else {
		$/.panic("Unanticipated type of jump statement: '"
			~ $key
			~ "' - you need to implement it!");
	}

	#DUMP($past, $key);
	make $past;
}

method iteration_statement($/, $key)         { PASSTHRU($/, $key, 'iteration_statement'); }

method foreach_stmt($/, $key) {
	if $key eq 'index' {
		open_decl_mode('parameter');
		return 0;
	}

	my $index_var := $<index>.ast;

	if $key eq 'open' {
		close_decl_mode('parameter');

		if $index_var.isdecl() {
			if $index_var.scope() eq 'parameter' {
				$index_var.scope('register');
			}

			add_local_symbol($index_var);
		}
		else {
			my $info := symbol_defined_locally($index_var);

			if !$info {
				$/.panic("Symbol '"
					~ $index_var.name()
					~ "' is not defined locally.");
			}
			else {
				$index_var.scope($info<decl>.scope());
			}
		}

		return 0;
	}

	my $index_ref;

	# Eventual past is { ... initialization ... while-loop }
	my $past := PAST::Stmts.new(:name('foreach-loop'), :node($/));

	if $index_var.isdecl() {
		$past.push($index_var);

		# Replace decl of  index var with new ref-only node.
		$index_var := PAST::Var.new(
			:lvalue(1),
			:name($index_var.name()),
			:node($index_var),
			:scope('register'));
	}

	my $iter_name	:= make_temporary_name('foreach_'
		~ $index_var.name() ~ '_iter');

	my $iterator	:= PAST::Op.new(
		:inline("    %r = iter %0"),
		:name('new-iterator'),
		:node($<index>),
		:pasttype('inline'));
	$iterator.push($<list>.ast);

	my $iter_temp	:= PAST::Var.new(
		:isdecl(1),
		:lvalue(1),
		:name($iter_name),
		:node($<list>),
		:scope('register'),
		:viviself($iterator));
	my $iter_read := PAST::Var.new(
		:name($iter_name),
		:node($<statement>),
		:scope('register'));

	# Store the iterator setup in the initialization part of the PAST
	$past.push($iter_temp);

	my $while := PAST::Op.new(
		:name('foreach-while'),
		:node($<statement>),
		:pasttype('while'));

	# While condition: while (iter) {...}
	$while.push($iter_read);

	# Insert a "index = shift iter" into while block
	my $body := PAST::Stmts.new(:node($<statement>));
	my $shift := PAST::Op.new(
		:node($<statement>),
		:pasttype('bind'));
	$shift.push($index_var);
	$shift.push(
		PAST::Op.new(
			:name('shift-iterator'),
			:node($<statement>),
			:pasttype('inline'),
			:inline('    %r = shift %0'),
			$iter_read));
	$body.push($shift);
	$body.push($<statement>.ast);
	$while.push($body);
	$past.push($while);

	#DUMP($past, "foreach-stmt");
	make $past;

}

method do_while_stmt($/) {
    my $past := PAST::Op.new(:name('do-while-loop'), :node($/));
    my $keyword := substr(~$<kw>, 0, 5);
    $past.pasttype('repeat_' ~ $keyword);
    $past.push($<expression>.ast);
    $past.push($<statement>.ast);
    #DUMP($past, $past.pasttype());
    make $past;
}

method while_do_stmt($/) {
	my $past := PAST::Op.new(:name('while-do-loop'), :node($/));
	my $keyword := substr(~$<kw>, 0, 5);
	$past.pasttype($keyword);
	$past.push($<expression>.ast);
	$past.push($<statement>.ast);

	#DUMP($past, $past.pasttype());
	make $past;
}

