# $Id$

method additive_expr($/) { binary_expr_l2r($/); }

method arg_adverb($/) {
	my $past := make_token($<token>);
	DUMP($past);
	make $past;
}

method arg_expr($/) {
	my $past := $<expression>.ast;
	$past.node($/);

	if $<argname> {
		$past.named(~$<argname>[0].ast.name());
	}

	#if +@($<adverbs>.ast) {
	#	for @($<adverbs>.ast) {
	#		arg_expr_add_adverb($/, $past, $_);
	#	}
	#}
	
	DUMP($past);
	make $past;
}

method arg_list($/) {
	NOTE("Assembling arg_list");
	my $past := close::Compiler::Node::create('expr_call', :node($/));

	for $<arg> {
		$past.push($_.ast);
	}

	DUMP($past);
	make $past;
}

sub adverb_arg_named($/, $past) {
	$past.named($past<adverbs><named>);
}


sub arg_expr_add_adverb($/, $past, $adverb) {
	# Presently this is a no-op, since the only two valid adverbs are :flat and :named.
	my $name := adverb_unalias_name($adverb);
	
	check_adverb_args($/, $name, $adverb);		
	$past<adverbs>{$name} := adverb_args_storage($adverb);
	
	# There is no "decl" here, so special handlers all the way.
	if	$name eq 'flat'	{ $past.flat(1); }
	elsif	$name eq 'named'	{ adverb_arg_named($/, $past); }
	else {
		$/.panic("Unexpected adverb: '" ~ $adverb.name() ~ "' in arg-expression");
	}
	
	#DUMP($past, "argument-expression);
}

method asm_contents($/) {
	my $past := PAST::Val.new(:returns('String'), :value(substr(~$/, 2, -2)));
	NOTE("Got asm contents: ", $past.value());
	
	make $past;
}

method asm_expr($/) {
	my $past := close::Compiler::Node::create('expr_asm', 
		:inline($<asm>.ast.value()),
	);

	if $<arg_list> {
		for @($<arg_list>[0].ast) {
			$past.push($_);
		}
	}
	
	DUMP($past);
	make $past;
}

# Assembly routine for a whole bunch of left-to-right associative binary ops.
sub binary_expr_l2r($/) {
	NOTE("Assembling binary left-associative expression");
	my $past := $<term>.shift().ast;

	for $<op> {
		$past := close::Compiler::Node::create('expr_binary', 
			:operator(~$_),
			:left($past),
			:right($<term>.shift().ast),
			:node($<op>));
	}

	NOTE("done");
	DUMP($past);
	make $past;
}

method expression($/, $key) { PASSTHRU($/, $key); }

method mult_expr($/) { binary_expr_l2r($/); }

method postfix_expr($/) {
	my $past := $<term>.ast;

	for $<adjective> {
		#DUMP($past);
		say("Got adjective: ", $_.ast.name(), ", what to do?");
	}

	my $lhs;

	for $<postfix> {
		$lhs	:= $past;
		$past	:= $_.ast;

		$past.unshift($lhs);
		#postfixup($past);
	}

	#DUMP($past);
	make $past;
}

# Fixup postfix-op PAST tree
# 1- f() isn't a lookup of the contents of the 'f' symbol, then a call to those
# 	contents. (That'd be *f). It's a call to function 'f'.
# 2- a.b() isn't a "call", it's a "callmethod". Rewrite it.
#
sub postfixup($past) {
	#say("Fixup: ", $past.WHAT, ": ", $past.name());

	if $past.isa('PAST::Op') and $past.pasttype() eq 'call' {
		#DUMP($past);
		my $func := $past[0];

		if $func.isa('PAST::Var') {
			# Rewrite a.b() into (callmethod 'b', a, args)
			if $func.scope() eq 'attribute' {
				$past.pasttype('callmethod');
				close::Compiler::Node::set_name($past, $func.name());
				$past.shift();
				$past.unshift($func[0]);
			}
			# Rewrite f() into (call 'f', args)
			else {
				unless $func<decl> {
					DIE("No decl info stored for symbol '", $func.name(), "'");
				}

				if is_local_function($func) {
					close::Compiler::Node::set_name($past, $func.name());
					$past.shift();
				}
				# TODO: Need to fix up aliases, etc. here. For now, leave it be.
			}
		}
		DUMP($past);
	}
}

# a++ or a--
# Leads to: Op.inline. Need [0]=a
method postfix_xcrement($/) {
	my $x_crement := "    inc %0\n";

	if ~$<op> eq '--' {
		$x_crement := "    dec %0\n";
	}

	my $past := PAST::Op.new(
		:name('postfix:' ~ $<op>),
		:node($/),
		:pasttype('inline'),
		:inline("    ## inline postfix:" ~ $<op> ~ "\n"
			~   "    clone %r, %0\n"
			~   $x_crement));
	$past.lvalue(1);
	#DUMP($past);
	make $past;
}

# a.b
# Leads to: var(b).scope(attribute). Need [0]=a
method postfix_member($/) {
	my $past := $<member>.ast;
	$past.isdecl(0);
	$past.node($/);
	$past.scope('attribute');
	#DUMP($past);
	make $past;
}

# a(b,c) or a()
# Leads to: Op.call(b,c). Need unshift [0]=a
method postfix_call($/) {
	my $past := $<arg_list>.ast;
	$past.node($/);
	#DUMP($past);
	make $past;
}

# a[x]
# Leads to Var.keyed(x). Need unshift [0]=a
method postfix_index($/) {
	my $past := PAST::Var.new(
		:name('indexed lookup'),
		:node($/),
		:scope('keyed'));
	$past.push($<index>.ast);
	#DUMP($past);
	make $past;
}


our %prefix_opcode;
%prefix_opcode{'++'} := 'inc';
%prefix_opcode{'--'} := 'dec';
%prefix_opcode{'-'} := 'neg';
%prefix_opcode{'!'} := 'not';
%prefix_opcode{'not'} := 'not';

our %prefix_lvalue;
%prefix_lvalue{'++'} := 1;
%prefix_lvalue{'--'} := 1;

method prefix_expr($/, $key)      {
	my $past := $/{$key}.ast;

	if $key eq 'prefix_expr' {
		my $op := ~$<prefix_op>;

		if $op ne '+' {
			my $oppast := PAST::Op.new(
				:name('prefix:' ~ $op),
				:node($<prefix_op>),
				:pasttype('pirop'));
			$oppast.pirop(%prefix_opcode{$op});
			$oppast.push($past);
			$past := $oppast;
		}

		if %prefix_lvalue{$op} {
			$past.lvalue(%prefix_lvalue{$op});
		}
	}

	make $past;
}

method bitwise_expr($/, $key) { binary_expr_l2r($/); }
method compare_expr($/) { binary_expr_l2r($/); }
method logical_expr($/) { binary_expr_l2r($/); }

method conditional_expr($/) {
	my $past;

	if $<if> {
		$past := PAST::Op.new(
			:name('? :'),
			:node($/),
			:pasttype('if'),
			$<test>.ast,
			$<if>[0].ast,
			$<else>[0].ast);
	}
	else {
		$past := $<test>.ast;
	}

	make $past;
}

method term($/, $key)     { PASSTHRU($/, $key); }

our %assign_opcodes;
%assign_opcodes{'+='}	:= 'add';
%assign_opcodes{'-='}	:= 'sub';
%assign_opcodes{'<<='}	:= 'shl';
%assign_opcodes{'>>='}	:= 'shr';
%assign_opcodes{'*='}	:= 'mul';
%assign_opcodes{'/='}	:= 'div';
%assign_opcodes{'%='}	:= 'mod';
%assign_opcodes{'&='}	:= 'band';
%assign_opcodes{'|='}	:= 'bor';
%assign_opcodes{'^='}	:= 'bxor';
%assign_opcodes{'and='}	:= 'and';
%assign_opcodes{'&&='}	:= 'and';
%assign_opcodes{'or='}	:= 'or';
%assign_opcodes{'||='}	:= 'or';

method assign_expr($/, $key) {
	if $key eq 'single' {
		PASSTHRU($/, $key);
	}
	else {
		my $lhpast	:= $<lhs>.ast;
		my $rhpast	:= $<rhs>.ast;
		my $op		:= ~$<op>;
		my $past		:= PAST::Op.new(
			:name($op),
			:node($/),
			:pasttype('bind'));
		$lhpast.lvalue(1);
		$past.push($lhpast);

		if $op ne '=' {
			my $opname := %assign_opcodes{$op};

			my $oppast := PAST::Op.new(
				:name($opname ~ " (compute)"),
				:node($/),
				:pasttype('pirop'),
				:pirop($opname));
			$oppast.push($lhpast);
			$oppast.push($rhpast);

			$rhpast := $oppast;
		}

		$past.push($rhpast);

		#DUMP($past);
		make $past;
	}
}
