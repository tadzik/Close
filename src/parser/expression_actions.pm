# $Id$

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
	my $past := PAST::Op.new(:pasttype('call'), :node($/));

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

method asm_expr($/, $key) {
	my $past;

    if $<arg_list> {
        $past := $<arg_list>[0].ast;
    }
    else {
        $past := PAST::Op.new(:node($/));
    }

    $past.pasttype('inline');
    $past.inline($<asm>.ast.value());

	#DUMP($past);
	make $past;
}

method asm_contents($/) {
	my $past := PAST::Val.new(:returns('String'), :value(substr(~$/, 2, -2)));
	make $past;
}

method expression($/, $key) { PASSTHRU($/, $key); }

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
				$past.name($func.name());
				$past.shift();
				$past.unshift($func[0]);
			}
			# Rewrite f() into (call 'f', args)
			else {
				unless $func<decl> {
					DIE("No decl info stored for symbol '", $func.name(), "'");
				}

				if is_local_function($func) {
					$past.name($func.name());
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

method mult_expr($/, $key) { binary_expr_l2r($/); }
#method mult_op($/, $key) { binary_op($/, ~$/); }
method additive_expr($/, $key) { binary_expr_l2r($/); }
#method additive_op($/, $key) { binary_op($/, ~$/); }
method bitwise_expr($/, $key) { binary_expr_l2r($/); }
#method bitwise_op($/, $key) { binary_op($/, $key); }
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

# Assembly routine for a whole bunch of left-to-right associative binary ops.
sub binary_expr_l2r($/) {
	my $past := $<term>.shift().ast;

	for $<op> {
		my $op := binary_op($_);
		$op.push($past);
		$op.push($<term>.shift().ast);
		$past := $op;
	}

	#DUMP($past);
	make $past;
}

our %binary_pastops;
%binary_pastops{'&&'} := 'if';
%binary_pastops{'and'} := 'if';
%binary_pastops{'||'} := 'unless';
%binary_pastops{'or'} := 'unless';
%binary_pastops{'xor'} := 'xor';

our %binary_pirops;
%binary_pirops{'+'}  := 'add';
%binary_pirops{'-'}  := 'sub';
%binary_pirops{'*'}  := 'mul',
%binary_pirops{'/'}  := 'div',
%binary_pirops{'%'}  := 'mod',
%binary_pirops{'<<'}  := 'shl',
%binary_pirops{'>>'}  := 'shr',
%binary_pirops{'&'}  := 'band',
%binary_pirops{'band'}  := 'band',
%binary_pirops{'|'}  := 'bor',
%binary_pirops{'bor'}  := 'bor',
%binary_pirops{'^'}  := 'bxor',
%binary_pirops{'bxor'}  := 'bxor',

our %binary_inline;
%binary_inline{'=='} := "iseq";
%binary_inline{'!='} := "isne";
%binary_inline{'<'}  := "islt";
%binary_inline{'<='}  := "isle";
%binary_inline{'>'}  := "isgt";
%binary_inline{'>='}  := "isge";

# Create a "run this pir op" node for binary expressions.
sub binary_op($/) {
	my $opname   := ~$/;

	my $past := PAST::Op.new(:name($opname), :node($/));

	if %binary_pastops{$opname} {
		$past.pasttype(%binary_pastops{$opname});
	}
	elsif %binary_pirops{$opname} {
		$past.pasttype('pirop');
		$past.pirop(%binary_pirops{$opname});
	}
	elsif %binary_inline{$opname} {
		$past.pasttype('inline');
		my $inline := "\t$I0 = " ~ %binary_inline{$opname} ~ " %0, %1\n"
			~ "\t%r = new 'Integer'\n"
			~ "\t%r = $I0\n";
		$past.inline($inline);
	}

	#DUMP($past);
	make $past;
}

method term($/, $key)     { PASSTHRU($/, $key); }

