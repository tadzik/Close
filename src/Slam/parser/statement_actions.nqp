# $Id$

module Slam::Grammar::Actions;

our $Symbols;

method _compound_statement_close($/) {
	my $past := $Symbols.current_scope;
	NOTE("Finishing up compound statement: ", $past);
	
	for ast_array($<statements>) {
		NOTE("Attaching statement: ", $_);
		$past.attach($_);
	}
	
	$Symbols.leave_scope('Slam::Scope::Local');
	MAKE($past);
}

method _compound_statement_open($/) {
	$Symbols.enter_local_scope(:node($/));
}

# NQP currently generates get_hll_global for functions. So qualify them all.
our %_cmpd_stmt;
%_cmpd_stmt<close> := Slam::Grammar::Actions::_compound_statement_close;
%_cmpd_stmt<open> := Slam::Grammar::Actions::_compound_statement_open;

method compound_statement($/, $key) { self.DISPATCH($/, $key, %_cmpd_stmt); }

method declaration_statement($/, $key) { PASSTHRU($/, $key); }

method extern_statement($/, $key) { PASSTHRU($/, $key); }

method local_statement($/, $key) { PASSTHRU($/, $key); }

method null_statement($/) {
	MAKE(Slam::Statement::Null.new(:node($/)));
}

method return_statement($/) {
	NOTE("Constructing return statement");
	my $past := Slam::Statement::Return.new(:node($/));
	
	if $<value> {
		NOTE("Adding value to return statement");
		$past.attach($<value>[0].ast);
	}
	
	MAKE($past);
}

method statement($/, $key)              { PASSTHRU($/, $key); }

################################################################
#####  Code above here is new, and probably doesn't work.
#####  Code below here is old, and probably doesn't work.
################################################################

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
		
		my $past := Slam::Node::create('foreach_statement', :node($/));
		Slam::Scopes::push($past);
		
		NOTE("Pushed foreach_statement on stack");
		DUMP($past)
	}
	elsif $key eq 'close' {
		my $past := Slam::Scopes::pop('foreach_statement');
		
		NOTE("Popped scope from stack: ", $past.name());

		$past<loop_var> := $<header><loop_var>.ast;
		
		if $past<loop_var><default> { # foreach (int i = 0 in array)
			$past<loop_var>.warning(
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
	my $past := Slam::Node::create('goto_statement', 
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

method while_do_statement($/) {
	my $past := PAST::Op.new(:name('while-do-loop'), :node($/));
	my $keyword := substr(~$<kw>, 0, 5);
	$past.pasttype($keyword);
	$past.push($<expression>.ast);
	$past.push($<local_statement>.ast);

	DUMP($past);
	make $past;
}
