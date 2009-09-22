# $Id$
class close::Grammar::Actions;

method statement($/, $key)              { PASSTHRU($/, $key); }

method extern_statement($/, $key) { PASSTHRU($/, $key); }

method null_statement($/) {
	my $past := PAST::Op.new(:node($/), :pasttype('null'));
	DUMP($past);
	make $past;
}

method compound_statement($/, $key) {
	if $key eq 'open' {
		NOTE("Creating new compound_statement, pushing on scope stack");
		my $past := close::Compiler::Node::create('compound_statement');
		close::Compiler::Scopes::push($past);
		DUMP($past);
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

method do_while_statement($/) {
    my $past := PAST::Op.new(:name('do-while-loop'), :node($/));
    my $keyword := substr(~$<kw>, 0, 5);
    $past.pasttype('repeat_' ~ $keyword);
    $past.push($<expression>.ast);
    $past.push($<local_statement>.ast);
    DUMP($past);
    make $past;
}

method expression_statement($/) {
	my $past := $<expression>.ast;
	DUMP($past);
	make $past;
}

method foreach_statement($/, $key) {
	if $key eq 'open' {
		NOTE('Begin foreach statement');
		
		my $past := close::Compiler::Node::create('foreach_statement', :node($/));
		close::Compiler::Scopes::push($past);
		
		NOTE("Pushed foreach_statement on stack");
		DUMP($past)
	}
	elsif $key eq 'close' {
		my $past := close::Compiler::Scopes::pop('foreach_statement');
		
		NOTE("Popped scope from stack: ", $past.name());

		$past<loop_var> := $<header><loop_var>.ast;
		
		if $past<loop_var><default> { # foreach (int i = 0 in array)
			ADD_WARNING($past<loop_var>,
				"Useless initializer in foreach loop variable ",
				$past<display_name>);
		}
		
		# TODO: Add some more checks for inappropriate specifiers, etc.
		
		$past<list> := $<header><list>.ast;
		$past.push($<body>.ast);
		
		NOTE("done");
		DUMP($past);
		make $past;
	}
	else {
		$/.panic('Unrecognized $key in action dclr_param_list: ' ~ $key);
	}
}

method goto_statement($/) {
	my $past := close::Compiler::Node::create('goto_statement', 
		:node($/),
		:label(~ $<label>));
		
	NOTE("done");
	DUMP($past);
	make $past;
}

method jump_statement($/, $key) {
	my $past;

	if $key eq 'tailcall' {
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

method labeled_statement($/, $key) {
	my $past := $<statement>.ast;
	
	if $<labels> {
		NOTE("Attaching labels to statement");
		
		$past<labels> := Array::empty();
		
		for $<labels> {
			$past<labels>.push($_.ast);
		}
	}
	
	DUMP($past);
	make $past;
}

method local_statement($/, $key) { PASSTHRU($/, $key); }

method return_statement($/) {
	my $past := close::Compiler::Node::create('return_statement',
		:node($/));
	
	if $<value> {
		NOTE("Adding value to return statement");
		$past.push($<value>[0].ast);
	}
	
	NOTE("done");
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
