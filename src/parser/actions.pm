# $Id$

=begin comments

close::Grammar::Actions - ast transformations for close

This file contains the methods that are used by the parse grammar
to build the PAST representation of an close program.
Each method below corresponds to a rule in F<src/parser/grammar.pg>,
and is invoked at the point where C<{*}> appears in the rule,
with the current match object as the first argument.  If the
line containing C<{*}> also has a C<#= key> comment, then the
value of the comment is passed as the second argument to the method.

Note that the order of routines here should be the same as that of L<grammar.pg>,
except that (1) some grammar rules have no corresponding method; and (2) any
'extra' routines in this file come at the end, corresponding to the 'Implementation'
pod section of the grammar.

=end comments

class close::Grammar::Actions;

method TOP($/, $key) {
	my $lstype := 'compilation unit';
	if $key eq 'start' {
		# I begin to suspect that this is useless.
		# But extra crap on the stack isn't toxic, so leave it for now.
		open_lexical_scope('compilation unit', $lstype);
	}
	else {
		close_lexical_scope($lstype);

		my $past := compilation_unit_past();
		#DUMP($past, "program");
		make $past;
	}
}

method hll_block($/, $key) {
	if $key eq 'open' {
		my $name := $<hllname> ?? $<hllname>.ast.name() !! 'close';
		open_hll($name);
	}
	else {
		my $past := close_hll();
	}
}

method namespace_block($/, $key) {
	if $key eq 'open' {
		my $past;

		if $<namespace_name> {
			$past := $<namespace_name>.ast;
		}
		else {
			$past := PAST::Block.new();
			$past.hll(current_hll_block().name());
		}

		open_namespace($past, 'extern');
	}
	else {
		my $past		:= close_namespace('extern');
		my @path		:= namespace_path_of_var($past);
		my $init_load	:= get_init_block_of_path(@path);

		#say("Closed namespace ", $past.name());
		$init_load.node($/);

		for $<declaration> {
			my $decl := $_.ast;

			if $decl.isa('PAST::Op') and $decl.pasttype() eq 'null' {
				#say("Skipping no-op code\n");
			}
			elsif $decl.isa('PAST::Block') {
				$past.push($decl);      # function definition
			}
			else {
				$init_load.push($decl);
			}
		}

		#DUMP($past, "namespace_block");
		#make $past;
	}
}

method namespace_name($/) {
	my @parts := new_array();

	for $<part> {
		@parts.push(~$_);
	}

	my $past := PAST::Var.new(:node($/));

	if $<root> and $<part> and +@($<part>) {
		$past<is_rooted> := 1;
		$past<hll> := @parts.unshift();
	}
	else {
		$past<hll> := current_hll_block().name();
	}

	$past.namespace(@parts);
	#DUMP($past, "namespace_name");
	make $past;
}

method long_ident($/) {
	my $past	:= PAST::Var.new(:node($/), :scope('register'));
	my @parts	:= new_array();

	for $<part> {
		@parts.push(~$_);
	}

	# Last part is the variable/class/function name. ::part1::name
	my $name := @parts.pop();
	$past.name($name);

	$past<is_rooted> := 0;
	$past<hll> := current_hll_block().name();
	
	if +$<root> {
		if +@parts {
			$past<is_rooted> := 1;
			$past<hll> := @parts.shift();
		}
		# else ::foo is just a ref to hll's empty nsp
		
		$past.namespace(@parts);
		$past.scope('package');
	}
	else {
		if +@parts {
			$past.namespace(@parts);
			$past.scope('package');
		}
		else {
			# Unrooted, w/ no namespace: looks like "foo"
			$past.namespace(current_namespace_block().namespace());
		}
	}

	# Look up symbol, set scope accordingly if seen.
	my $info := symbol_defined_anywhere($past);

	if $info and $info<decl> {
		$past<decl> := $info<decl>;

		if $info<decl>.isa('PAST::Var') {
			my $scope := $info<decl>.scope();

			if $scope eq 'parameter' {
				# See #701. Non-isdecl param ref must be lex
				$scope := 'lexical';
			}

			$past.scope($scope);
		}
	}

	#DUMP($past, "long_ident");
	make $past;
}

# 1. Declaring an uninitialized attribute:   attribute int foo;
#  - causes an add-attr entry in the class-init function, plus a symbol table entry
# for the class block.
# 2. Declaring an initialized attribute:  attribute int foo = 0;
#  - causes an add-attr entry in the class-init function, plus a symbol table entry
#  - for the class block, plus an initialization step in the _init or _new method,
#  - or however it's enacted.
# 3. Declaring a method: int foo() :method {...}
#  - causes an add-method entry in the class-init function, plus a symbol table
#  - entry for the class block.
# 4. Declaring a non-method: int foo() {...}
#  - causes an entry in the namespace, not the class. (?)
#

method declaration($/, $key) {
	my $lstype;
	my $decl_mode := 'ERROR: in declaration()';

	if $key eq 'body_open' {
		# Put PAST::Block back on stack as either function body
		# or class block.
		my $block := current_declaration();

		if $block<is_extern> {
			$/.panic("You cannot use 'extern' with a definition");
		}

		if $block<is_function> {
			$lstype := 'function body';
			$decl_mode := 'local';

			if $block<adverbs> && $block<adverbs><method>
				or $block<is_vtable> {
				# Create a 'self' lexical automatically.
				my $auto_self := PAST::Var.new(
					:isdecl(1),
					:name('self'),
					:node($/),
					:scope('register'));
				add_local_symbol($auto_self);
				# Don't lexify it. Just remember that it was declared.
				#$block[0].push($auto_self);
			}
		}
		elsif $block<is_class> {
			$lstype := 'class body';
			$decl_mode := 'class';
		}
		else {
			DUMP($block, "current_decl");
			$/.panic("Blocks can only be used "
				~ "in class and function definitions");

		}

		#say("Opening declaration of " ~ $lstype ~ " " ~ $block.name());
		open_decl_mode($decl_mode);
		$block<lstype> := $lstype;
		push_lexical_scope($block);

		if $block<is_class> {
			# Open namespace inside class decl. so methods
			# will be part of nsp block

			open_class($block);
		}
	}
	elsif $key eq 'body_close' {
		my $block := current_declaration();

		if $block<is_function> {
			$lstype := 'function body';
			$decl_mode := 'local';
		}
		elsif $block<is_class> {
			close_class();
			$lstype := 'class body';
			$decl_mode := 'class';
		}

		#say("Closing declaration of " ~ $lstype ~ " " ~ $block.name());
		close_decl_mode($decl_mode);
		close_lexical_scope($lstype);
	}
	else {
		# $key eq 'done'
		# This code has to deal with every single kind of declaration. Yikes.
		my $past := close_declaration();

		# One important thing is to establish the namespace for the
		# symbol. Use scope to determine what to do:
		if $past<scope> eq 'package' {
			if !$past<is_class> {
				add_global_symbol($past);
			}
			else {
				add_class_decl($past);
			}
		} elsif $past<scope> eq 'attribute' {
			# TODO: Do I pass initializer in here?
			add_class_attribute($past);
		}

		if $<initializer> {
			# FIXME: Is this wrong? Should this be an assignment ?
			$past.viviself($<initializer>[0].ast);
			$past.lvalue(1);
		}
		elsif $past<is_function> {
			# Definition or declaration?
			if $<compound_stmt> {
				$past.push($<compound_stmt>.ast);
			}
			else {
				$past<is_decl_only> := 1;
				$past := PAST::Op.new(
					:node($past),
					:name($past.name() ~ " (decl)"),
					:pasttype('null'));
			}
		}
		elsif $past<is_class> {
			if $<compound_stmt> {
				# Remove all method blocks - put them in the namespace
				my @path := namespace_path_of_var($past);
				my $namespace := get_past_block_of_path(@path);

				my $block := $<compound_stmt>.ast;
				my $num_items := +@($block);
				my $node;

				while $num_items-- {
					$node := $block.shift();

					if $node.isa(PAST::Block) {
						#say("Adding method ", $node.name(), " to nsp block ", $namespace.name());
						$namespace.push($node);
					}
					else {
						# FIXME: I don't know what to do with these.
						say("Recycling unknown node");
						$block.push($node);
					}
				}
			}

			$past := PAST::Op.new(:node($/), :pasttype('null'));
		}

		#DUMP($past, "declaration (now closed)");
		#say("Done with <declaration>: ", $past.name());
		make $past;
	}
}

method parameter_decl_list($/, $key) {
	my $lstype := 'parameter list';

	if $key eq 'open' {
		open_decl_mode('parameter');
		my $past := open_lexical_scope('(parameter_decl_list)', $lstype);
		$past.node($/);
		$past.push( PAST::Stmts.new(:name('local variables')) );
		$past<is_function> := 1;
		$past.blocktype('declaration');
		make $past;
	}
	else {
		close_decl_mode('parameter');
		my $past := close_lexical_scope($lstype);
		#DUMP($past, "parameter_decl_list");

		for $past<symtable> {
			$past.push($past<symtable>{$_}<decl>);
		}

		current_declaration()<params> := $past;
		make $past;
	}
}

method decl_specifiers($/) {
	my $past := open_declaration($/);

	### Storage specifier

	my $storage;

	if $<storage_spec> {
		$storage := ~$<storage_spec>[0];

		if $storage eq 'extern' {
			$past<is_extern> := 1;
			$storage := 'package';
		}
		elsif $storage eq 'static' {
			$past<is_static> := 1;
			$storage := 'package';
		}
	}
	else {
		$storage := get_default_storage_spec();
		#say("Using default storage spec: ", $storage);
	}

	$past.scope($storage);

	### Type qualifiers

	if $<type_qualifier> {
		my $tq := ~$<type_qualifier>;

		if $tq eq 'const' {
			$past<is_const> := 1;
		}
	}

	### Type specifier (not optional)

	my $type := ~$<type_spec>;
	#say("Type specifier: ", $type);
	$past<type> := $type;

	my $rtype;

	if $type eq 'class' { $rtype := "P"; $past<is_class> := 1; }
	elsif $type eq 'int'  { $rtype := "I"; }
	elsif $type eq 'num'  { $rtype := "N"; }
	elsif $type eq 'pmc'  { $rtype := "P"; }
	elsif $type eq 'str'  { $rtype := "S"; }
	elsif $type eq 'void' { $rtype := "v"; }
	else { $rtype := "P"; }
}

method declarator($/) {
	# Get name and other info from the identifier ast.
	my $symbol		:= $<name>.ast;

	my $decl			:= current_declaration();

	# If the declarator is a sub(), uplift the params block
	# to be the declarator past.
	if $decl<params> && $decl<params><is_function> {
		my $block		:= $decl<params>;
		#DUMP($block, "uplift block");
		# params<is_function> should be set by param_list
		#$block<is_function> := $decl<is_function>;
		$block.node($decl);
		$block<params> := 'uplifted';
		$block.pirflags($decl<pirflags>);
		$block<rtype>	:= $decl<rtype>;
		$block<scope>	:= $decl.scope();
		$decl		:= replace_current_declaration($block);
	}
	elsif $decl<is_class> {
		# Clone array to separate class namespace from enclosing nsp.
		# (Else "nsp X { class C {" modifies X.namespace() because the
		# long_ident inherits the nsp)
		$symbol.namespace(clone_array($symbol.namespace()));
		$symbol.namespace().push($symbol.name());

		my @path := namespace_path_of_var($symbol);
		my $block := get_class_info_of_path(@path);

		$block.node($decl);
		$block.pirflags($decl<pirflags>);
		$block<rtype>	:= $decl<rtype>;
		$block<scope>	:= $decl.scope();

		$decl		:= replace_current_declaration($block);
		#DUMP($decl, "class decl (after swap)");
	}

	$decl<is_rooted>	:= $symbol<is_rooted>;
	$decl<hll>		:= $symbol<hll>;
	$decl.name($symbol.name());
	$decl.namespace($symbol.namespace());

	# FIXME: I think this is wrong for pkg vars. Test?
	unless $decl<is_class> {
		# say("Saw declarator for ", $decl.name());
		add_local_symbol($decl);
	}

	make $decl;
}

method decl_suffix($/, $key) { PASSTHRU($/, $key); }

#~ method array_or_hash_decl($/, $key) {
#~ 	my $past := PAST::Var.new()
#~ }
#~ rule array_or_hash_decl {
#~ 	[ '%'				{*} #= hash
#~ 	| <expression>	{*} #= fixed_array
#~ 	| 				{*} #= resizable_array
#~ 	]
#~ }

our %adverb_arg_info;
# For each adverb, check args: min #args, errormsg, max #args, errormsg.
# If #args is below/above limit, print errormessage.
%adverb_arg_info<anon>	:= (0,	"", 0,	":anon takes no args");
%adverb_arg_info<init>	:= (0,	"", 0,	":init takes no args");
%adverb_arg_info<load>	:= (0,	"", 0,	":load takes no args");
%adverb_arg_info<main>	:= (0,	"", 0,	":main takes no args");
%adverb_arg_info<method> := (0,	"", 0,	":method takes no args");
%adverb_arg_info<multi>	:= (1,	"You must provide a signature for :multi(...)", 
	1, ":multi(...) requires an unquoted signature");
%adverb_arg_info<named> := (0, "",	1,	"Too many arguments for adverb :named(str)");
%adverb_arg_info<optional> := (0,	"", 0,	":optional takes no args");
%adverb_arg_info<opt_flag> := (0,	"", 0,	":opt_flag takes no args");
%adverb_arg_info<phylum> := (1,	"You must provide a phylum named for :phylum(str)",
	1, "Too many args for adverb :phylum(str)");
%adverb_arg_info<slurpy>	:= (0,	"", 0,	":slurpy takes no args");
%adverb_arg_info<vtable>	:= (0,	"", 1, "Too many args for adverb :vtable(str)");

sub check_adverb_args($/, $adverb, $num) {
	unless %adverb_arg_info{$adverb} {
		$/.panic("Unknown adverb: " ~ $adverb);
	}
	
	my $arg_info := %adverb_arg_info{$adverb};
	
	if $num < $arg_info[0] {
		$/.panic($arg_info[1]);
	}
	
	if $num > $arg_info[2] {
		$/.panic($arg_info[3]);
	}
}

our %adverb_aliases;
%adverb_aliases{'...'} := 'slurpy';
%adverb_aliases{'?'} := 'optional';

our %append_adverb_to_pirflags;
%append_adverb_to_pirflags<anon> := 1;
%append_adverb_to_pirflags<init> := 1;
%append_adverb_to_pirflags<load> := 1;
%append_adverb_to_pirflags<main> := 1;
%append_adverb_to_pirflags<method> := 1;
%append_adverb_to_pirflags<optional> := 1;
%append_adverb_to_pirflags<opt_flag> := 1;

method adverb($/) {
	my $decl := current_declaration();
	my $adverb := ~$<t_adverb><ident>;

	#say("Saw adverb -> ", $adverb);

	# Maybe rewrite adverb
	if %adverb_aliases{$adverb} {
		$adverb := %adverb_aliases{$adverb};
	}

	my @args := new_array();
	
	if $<signature> {
		@args.push(~$<signature>[0]);
	} 
	else {
		for $<args> {
			@args.push($_.ast<value>);
		}
	}

	if +@args {
		$decl<adverbs>{$adverb} := @args;
	}
	else {
		$decl<adverbs>{$adverb} := 1;
	}

	check_adverb_args($/, $adverb, +@args);
	
	if %append_adverb_to_pirflags{$adverb} {
		$decl<pirflags> := $decl<pirflags> ~ ' :' ~ $adverb;
	}
	elsif $adverb eq 'multi' {
		$decl<pirflags> := $decl<pirflags> ~ ' :' ~ $adverb
			~ '(' ~ @args[0] ~ ')';
	}
	elsif  $adverb eq 'named' {
		my $named := $decl.name();
		
		if +@args {
			$named := @args[0];
		}
		
		$decl.named($named);
	}
	elsif $adverb eq 'phylum' {
		$decl<phylum> := @args[0];
	}
	elsif $adverb eq 'slurpy' {
		$decl.slurpy(1);
	}
	elsif $adverb eq 'vtable' {
		$decl<is_vtable> := 1;
		my $vtable_name;
		
		if +@args {
			$vtable_name := @args[0];
		}
		else {
			$vtable_name := $decl.name();
		}
		
		$decl<pirflags> := $decl<pirflags> 
			~ ' :' ~ $adverb ~ "('" ~ $vtable_name ~ "')";
	}

	#DUMP($decl, "current_declaration[w/ adverb]");
}

method initializer($/, $key) { PASSTHRU($/, $key); }

method short_ident($/) {
	my $name := ~$<id>;
	my $past := PAST::Var.new(
		:name($name),
		:node($/));

	#DUMP($past, "short_ident");
	make $past;
}

method constant($/, $key)               { PASSTHRU($/, $key); }

method string_lit($/) {
	my $past := PAST::Val.new(
		:node($/),
		:returns('String'),
		:value($<string_literal>.ast));
	#DUMP($past, "string");
	make $past;
}

method integer_lit($/) {
    my $value := ~$/;

    if substr($value, 0, 1) eq '0'
        and my $second := substr($value, 1, 1)
        and $second ge '0' and $second le '9' {
        $/.panic("FATAL: Integer literals like "
            ~ $value
            ~ " are not interpreted as octal.\n"
            ~ "Use 0o"
            ~ substr($value, 1)
            ~ " for that, or remove the leading zero");
    }

    my $past := PAST::Val.new(
        :node($/),
        :returns('Integer'),
        :value($value));

    #DUMP($past, "integer");
    make $past;
}

method float_lit($/, $key) {
    my $past := PAST::Val.new(
        :node($/),
        :returns('Num'),
        :value(~$/));
    #DUMP($past, "number");
    make $past;
}

method statement($/, $key)              { PASSTHRU($/, $key); }

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
	$past := PAST::Op.new(
	:name("tailcall"),
	:node($/),
	:pasttype('pirop'),
	:pirop('tailcall'));

	$past.push($<retval>.ast);
	}
	else {
	$/.panic("Unanticipated type of jump statement: '"
	~ $key
	~ "' - you need to implement it!");
	}

	#DUMP($past, $key);
	make $past;
}

method iteration_stmt($/, $key)         { PASSTHRU($/, $key); }

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
		:inline("    %r = new 'Iterator', %0"),
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

##### Implementation helpers

sub DUMP($what, $name)
{
	PCT::HLLCompiler.dumper($what, $name);
}

sub PASSTHRU($/, $key) {
	my $past := $/{$key}.ast;
	#DUMP($past, "passing thru:" ~ $key);
	#DUMP($/, "match");
	make $past;
}

sub join($_delim, @parts) {
	my $result := '';
	my $delim := '';

	for @parts {
		$result := $result ~ $delim ~ $_;
		$delim := $_delim;
	}

	return $result;
}

sub die($msg) {
	PIR q:to: 'XXX' ;
		$P0 = find_lex '$msg'
		$S0 = $P0
		die $S0
XXX
}

sub set_subroutine_adjective($node, $adj) {
	#my $adj_name := $adj.name();

	# Nothing to do yet. Get list of :init, :load, etc. and see what's what.
	return set_adjective($node, $adj);
}

sub set_adjective($node, $adj) {
	$node<adjectives>{ $adj.name() } := $adj;
	return $node;
}

## Declaration mode stack is used to track declaration modes -- "extern", "local", "class", "param"

sub close_decl_mode($mode) {
	our @Decl_mode_stack;
	#DUMP(@Decl_mode_stack, "Decl mode stack (pre-pop)");
	my $last := @Decl_mode_stack.shift();

	if $last ne $mode {
		DUMP($last, "last");
		die("Decl mode mismatch on close: wanted "
			~ $mode ~ ", but got " ~ $last);
	}

	#say("Close declaration mode: '", $last, ", ",
	#	+@Decl_mode_stack, " now on stack");
	return $last;
}

sub current_decl_mode() {
	our @Decl_mode_stack;
	return @Decl_mode_stack[0];
}

our %default_storage_spec;
%default_storage_spec{'class'} := 'package';
%default_storage_spec{'extern'} := 'package';
%default_storage_spec{'local'} := 'register';
%default_storage_spec{'parameter'} := 'parameter';

sub get_default_storage_spec() {
	my $mode := current_decl_mode();
	return %default_storage_spec{$mode};
}

our %valid_decl_mode;
%valid_decl_mode<class> := 1;
%valid_decl_mode<extern> := 1;
%valid_decl_mode<local> := 1;
%valid_decl_mode<parameter> := 1;

sub open_decl_mode($mode) {
	our @Decl_mode_stack;

	unless @Decl_mode_stack {
		@Decl_mode_stack := new_array();
	}

	unless %valid_decl_mode{$mode} {
		die("Invalid decl_mode: " ~ $mode);
	}

	@Decl_mode_stack.unshift($mode);
	#DUMP(@Decl_mode_stack, "Decl mode_stack (post-push)");
	#say("Opened declaration mode: ", $mode, ", ",
	#	+@Decl_mode_stack, " now on stack");
	return $mode;
}

##################################################################

=head4 Declaration tracking

There is a stack used to track the symbol currently being declared. This is needed for
nested declarations -- functions within classes, complex parameters inside a 
function parameter list.

=cut 

sub close_declaration() {
	our @Declaration_stack;
	my $last := @Declaration_stack.shift();
	#say("Close declaration of '", $last.name(), "', ",
	#    +@Declaration_stack, " now on stack");
	return $last;
}

sub current_declaration() {
	our @Declaration_stack;
	return @Declaration_stack[0];
}

sub open_declaration($/) {
	our @Declaration_stack;

	unless @Declaration_stack {
		@Declaration_stack := new_array();
	}

	my $decl := PAST::Var.new(
		:isdecl(1),
		:node($/));
	$decl<pirflags> := '';

	@Declaration_stack.unshift($decl);
	#say("Open declaration of '", ~$/, "', ",
	#    +@Declaration_stack, " now on stack");
	return $decl;
}

sub replace_current_declaration($new_decl) {
	our @Declaration_stack;
	@Declaration_stack[0] := $new_decl;
	#say("Replaced current declaration with '", $new_decl.name(), "'");
	return $new_decl;
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

	#DUMP($past, "binary-expr");
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

	#DUMP($past, "binary_op:" ~ $pirop);
	make $past;
}


sub symbol_defined_locally($past) {
	my $name := $past.name();
	return current_lexical_scope().symbol($name);
}

sub symbol_defined_anywhere($past) {
	if $past.scope() ne 'package' {
		our @Outer_scopes;

		my $name := $past.name();
		my $def;

		for @Outer_scopes {
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
					die("Unexpected data item");
				}

				return $def;
			}
		}
	}

	# Not any kind of local variable, parameter, etc. Try global.
	return get_global_symbol_info($past);
}

#########

##### Legacy code - deprecated.

method Xlogical_op($/, $key) {
	my $op := ~$/;
	my $pasttype;

	if $op eq '&&' {
		$pasttype := 'unless';
	}
	elsif $op eq '||' {
		$pasttype := 'if';
	}
	else {
		$/.panic("Unexpected value: '" ~ $op ~ "' for logical operator.");
	}

	my $past := PAST::Op.new(
		:name($op),
		:node($/),
		:pasttype($pasttype),
	);
	make $past;
	#DUMP($past, "LOP");
}

sub clone_array(@ary) {
	my @new := new_array();

	for @ary {
		@new.push($_);
	}

	return @new;
}

sub new_array() {
	my @ary := Q:PIR { %r = new 'ResizablePMCArray' };
	return (@ary);
}

sub block2stmts($block) {
	my $past := PAST::Stmts.new(
		:name($block.name()),
		:node($block));

	# copy attributes

	# copy children
	for @($block) {
		unless ($_.isa('PAST::Op') and $_.pasttype() eq 'null') {
			$past.push($_);
		}
	}

	say("Block2stmts: ", $past.name(), ", with ", +@($past), " items left");

	unless +@($past) {
		$past := PAST::Op.new(:pasttype('null'));
		say("Nulled out block");
	}

	return $past;
}

sub merge_lexical_scopes($outer, $inner) {
    # Check for conflicting symbol names, fail if any exist.
	say("Merging lexical scopes");
	DUMP($outer, "outer");
	DUMP($inner, "inner");

    for $inner<symtable> {
        if $outer.symbol($_) {
            return $inner;
        }
    }

    # Merge the symbol tables.
    for $inner<symtable> {
        $outer<symtable>{$_} := $inner.symbol($_);
    }

    # Merge the blocks
    my $new_inner := PAST::Stmts.new();
    $new_inner.name($inner.name());
    #$new_inner.namespace($inner.namespace());
    #$new_inner.node($inner.node());
    $new_inner<rtype> := $inner<rtype>;

    for @($inner) {
        $new_inner.push($_);
    }

    my $found := 0;
    my $index := 0;

    for @($outer) {
        if $_.isa('PAST::Block') and $_ =:= $inner {
            $found := 1;
            $outer[$index] := $new_inner;
        }

        $index ++;
    }

    if !$found {
        die("Tried to merge two non-nested scopes. WTF?");
    }

    return $new_inner;
}

##################################################################

=head4 Function block management

Functions are the basic coding units in Close. Each function is parsed as a
PAST::Block. The very first child of a function's ast will be a PAST::Stmts
block for storing local variable declarations.

Functions declared with the :vtable, :vtable(...), and :method modifiers will
have access to the 'self' built-in automatically.

=cut

##################################################################

=head4 Local symbol table management

Local symbols (parameters, registers, and lexical scope vars) are defined
where they occur, but they need to be added to the block's symbol table.

=cut

sub add_local_symbol($past) {
	my $name := $past.name();
	my $block := current_lexical_scope();
	$block.symbol($name, :decl($past));
}

##################################################################

=head4 Global symbol table management

Global symbols are stored in set of PAST::Blocks maintained separately from
PAST tree output by the parser.

These blocks are organized in a tree that mirrors the Parrot namespace tree.
The topmost, root level of the blocks is stored in C<our $Symbol_table>.

Within the blocks, each child namespace is stored as a symbol entry. The
symbol hash associated with each name is populated with these keys:

	my $info := $block.symbol($name);

=over 4

=item * C<< $info<past> >> is the PAST block that will be output by the parser for
this namespace. If a user closes and then re-opens a namespace using the
namespace directive, all follow-on declarations should be added to the same
block.

=item * C<< $info<symbols> >> is the PAST block that contains info about child
namespaces. This is the continuation of the symbol table tree. Thus,

     my $child := $block.symbol($name)<symbols>;

=item * C<< $info<class> >> will be something to do with classes. Duh.

=item * C<< $info<init> >> is a PAST block representing a namespace init function.

=back

=cut

sub add_global_symbol($sym) {
	my @path := namespace_path_of_var($sym);
	my $block := get_past_block_of_path(@path);

	#say("Found block: ", $block.name());

	my $name	:= $sym.name();
	my $info	:= $block.symbol($name);

	$block.symbol($name, :decl($sym));
}

sub _find_block_of_path(@_path) {
	our $Symbol_table;

	unless $Symbol_table {
		$Symbol_table := PAST::Block.new(:name(""));
		$Symbol_table<path> := '$';
	}

	my @path := clone_array(@_path);

	my $block	:= $Symbol_table;
	my $child	:= $Symbol_table;

	#DUMP(@path, "find block of path");
	while @path {
		my $segment := @path.shift();

		unless $block.symbol($segment) {
			my $new_child := PAST::Block.new(:name($segment));
			$new_child<path> := $block<path> ~ "/" ~ $segment;
			$block.symbol($segment, :namespace($new_child));
		}

		$child := $block.symbol($segment);
		$block := $child<namespace>;
	}

	#say("Found block: ", $block<path>);
	return $child;
}

sub _get_namespaces_below($block, @results) {
	for $block<symtable> {
		#say("Child: ", $_);
		my $child := $block.symbol($_);

		if $child<past> {
			@results.push($child<past>);
			#DUMP($child<past>, "past");
		}

		_get_namespaces_below($child<namespace>, @results);
	}
}

sub get_all_namespaces() {
	our $Symbol_table;

	my @results := new_array();

	if $Symbol_table {
		_get_namespaces_below($Symbol_table, @results);
	}

	return @results;
}

# Given a past symbol, return the symbol hash.
sub get_global_symbol_info($sym) {
	my @path := namespace_path_of_var($sym);
	my $block := get_past_block_of_path(@path);

	#say("Found block: ", $block.name());
	my $name := $sym.name();
	return $block.symbol($name);
}

sub _get_keyed_block_of_path(@_path, $key) {
	#say("Get keyed block of path: ", join("::", @_path), ", key = ", $key);
	my $block	:= _find_block_of_path(@_path);
	my $result	:= $block{$key};

	unless $result {
		# Provide some defaults
		my @path := clone_array(@_path);
		my $name := '';

		$result := PAST::Block.new();
		$result.blocktype('immediate');
		$result.hll(@path.shift());

		# This wierd order is for hll root namespaces, which
		# will have a hll, but no name and no path.
		if +@path {
			$name := @path.pop();
			@path.push($name);
		}

		$result.name($name);
		$result.namespace(@path);
		$result<init_done> := 0;
		$result<block_type> := $key;

		$block{$key} := $result;
	}

	return $result;
}

sub get_class_info_if_exists(@path) {
	my $block	:= _find_block_of_path(@path);
	return $block<class>;
}

sub get_class_info_of_path(@path) {
	my $class := _get_keyed_block_of_path(@path, 'class');

	unless $class<init_done> {
		$class.blocktype('declaration');
		$class.pirflags(":init :load");
		$class<is_class> := 1;
		$class<phylum> := 'close';
		$class<init_done> := 1;
		#DUMP($class, "class");
	}

	return $class;
}

sub get_class_init_of_path(@path) {
	my $block := _get_keyed_block_of_path(@path, 'class_init');

	unless $block<init_done> {
		$block.blocktype('declaration');
		$block.name('_init_class_' ~ $block.name());
		#$block.pirflags(':init :load');
		$block<init_done> := 1;
		#DUMP($block, "class init");
	}

	return $block;
}

sub get_init_block_of_path(@_path) {
	my $block := _get_keyed_block_of_path(@_path, 'init');

	unless $block<init_done> {
		$block.blocktype('declaration');
		$block.name('_init_namespace_' ~ $block.name());
		$block.pirflags(":anon :init :load");
		$block<init_done> := 1;
		#DUMP($block, "namespace init block");
	}

	return $block;
}

sub get_past_block_of_path(@_path) {
	my $block := _get_keyed_block_of_path(@_path, 'past');

	unless $block<init_done> {
		$block<init_done> := 1;
	}

	#DUMP($block, "namespace past");
	return $block;
}

sub namespace_path_of_var($var) {
	my @path := clone_array($var.namespace());
	@path.unshift($var<hll>);
	return @path;
}

sub is_local_function($fdecl) {
	my @p1 := namespace_path_of_var($fdecl);
	my @p2 := namespace_path_of_var(current_namespace_block());

	return join('::', @p1) eq join('::', @p2);
}

##################################################################

=head4 Class handling

Classes can be part of different phyla. (Aka Meta-Object-Protocols.) These will
have different behaviors wrt namespace pollution, etc.

=cut

sub add_class_attribute($attr) {
	my $class := find_lexical_block_with_attr('is_class');

	$class.symbol($attr.name(), :decl($attr));

	if !$class<is_extern> {
		add_class_init_code($class);

#~ 		my $name := $attr.name();
#~ 		my $past := PAST::Op.new(
#~ 			:name('class add-attribute for ' ~ $attr.name()),
#~ 			:node($class),
#~ 			:pasttype('inline'),
#~ 			:inline("\t" ~ "addattribute the_class, '" ~ $name ~ "'\n"));
	}


	if $attr.viviself() {
		# Need to stuff init value someplace.
		# This probably has to go in __init_object method
		# (autogen sth before 'new'? 'init'?)
	}
}

# A class has been declared. So what?
sub add_class_decl($class) {
	if $class<phylum> eq 'P6object' {
		add_class_decl_p6object($class);
	}
	else {
		die("Unrecognized phylum '" ~ $class<phylum>
			~ "' for class '" ~ $class.name() ~ "'");
	}
}

# P6object classes create a var with the same name. (extern pmc)
sub add_class_decl_p6object($class) {
	my @nsp := clone_array($class.namespace());
	@nsp.pop();

	my $past := PAST::Var.new(
		:name($class.name()),
		:namespace(@nsp),
		:node($class),
		:scope('package'));
	$past<hll> := $class<hll>;
	$past.isdecl(1);

	#DUMP($past, "proto object");
	# Add symbol declaration to namespace.
	my @path		:= namespace_path_of_var($past);
	my $ns_block	:= get_past_block_of_path(@path);
	$ns_block.push($past);
	$ns_block.symbol($past.name(), :decl($past));
}


# FIXME: This should (maybe) vary by phylum.
sub add_class_init_code($class) {
	my $past := PAST::Op.new(
		:name('class-init code for ' ~ $class.name()),
		:node($class.node()),
		:pasttype('inline'),
		:inline("\t" ~ "# Lookup class, create it if not found\n"));
	$class.push($past);
}

sub make_init_class_sub($class) {
	my $init_class_sub;

	if $class<phylum> eq 'P6object' {
		$init_class_sub := make_init_class_sub_p6object($class);
	}
	else {
		die("Unrecognized phylum '" ~ $class<phylum>
			~ "' for class '" ~ $class.name() ~ "'");
	}

	return $init_class_sub;
}

sub make_init_class_sub_p6object($class) {
	my @path		:= namespace_path_of_var($class);
	my $ns_block	:= get_past_block_of_path(@path);

	my $init_class_sub := get_class_init_of_path(@path);
	$init_class_sub.node($ns_block);

	my $hll := @path.shift();
	#if $hll ne 'close' {
	#	die("I don't know what to do about classes in a different HLL");
	#}

	my $class_name := join('::', @path);
	@path.unshift($hll);
	my $parent_class := "";

	if $class<parent> {
		$parent_class := ", 'parent' => '" ~ $class<parent> ~ "'";
	}

	my $attributes := "";

	if $class<symboltable> {
		my $delim := '';

		for $class<symboltable> {
			$attributes := $attributes ~ $delim ~ $_;
			$delim := ' ';
		}

		if $attributes ne '' {
			$attributes := ", 'attr' => '" ~ $attributes ~ "'";
		}
	}

	my $inline_code := "\tload_bytecode 'P6object.pbc'\n"
		~ "\t.local pmc p6meta, cproto\n"
		~ "\tp6meta = new 'P6metaclass'\n"
		~ "\tcproto = p6meta.'new_class'("
			~ "'" ~ $class_name ~ "'"
			~ $parent_class
			~ $attributes
		~ ")\n";

	$init_class_sub.push(PAST::Op.new(
		:name('Standard P6object preliminary'),
		:node($class),
		:pasttype('inline'),
		:inline($inline_code)));

	# Add a call to the namespace init block.
	my $ns_init	:= get_init_block_of_path(@path);
	$ns_init.push(PAST::Op.new(
		:name($init_class_sub.name()),
		:node($class),
		:pasttype('call')));

	return $init_class_sub;
}

##################################################################

=head4 PAST Generation

Because of the way namespaces are processed, we don't return a tree of blocks
as part of the TOP method. Instead, separate processing extracts them after
everything wraps up.

=cut

sub compilation_unit_past()
{
	our $Symbol_table;
	my @ns_list := get_all_namespaces();
	my $past := PAST::Stmts.new();

	say("Got ", +@ns_list, " namespaces");
	for @ns_list {
		#say("Codegen namespace: ", $_.name());
		#DUMP($_.namespace(), "namespace");
		my @path	:= namespace_path_of_var($_);
		# Do class first because it might create init_namespace code.
		my $class	:= get_class_info_if_exists(@path);

		if $class {
			$_.push(make_init_class_sub($class));
		}

		my $init	:= get_init_block_of_path(@path);
		# Despite producing "null" values, this is required for PAST
		# generation to work on the init sub. (Seriously.)
		$init.node($_);

		if +@($init) {
			#say("Adding initializer ", $init.name());
			$_.unshift($init);
			#DUMP($init, "init function");
		}

		# Add all the blocks inside.
		for @($_) {
			if $_.isa('PAST::Block') && !$_<is_namespace> {
				#say("Adding: ", $_.name());
				$past.push($_);
			}
		}
	}

	return $past;
}

#################################################################

=head4 Lexical Stack

There is a stack of lexical elements. Each element is expected to be a
PAST::Block, although it may be transformed after it leaves the stack.

=cut

sub close_lexical_scope($lstype) {
	our @Outer_scopes;

	my $old := @Outer_scopes.shift();

	unless $lstype eq $old<lstype> {
		DUMP($old, "popped");
		DUMP(@Outer_scopes, "Outer_scopes");
		die("Stack mismatch. Popped '" ~ $old<lstype>
			~ "' but expected '" ~ $lstype ~ "'");
	}

	#say("Close ", $lstype, " scope. Before ", +@Outer_scopes, " on stack");
	#DUMP($old, "last lex scope");
	return $old;
}

sub current_lexical_scope() {
	our @Outer_scopes;
	return @Outer_scopes[0];
}

sub find_lexical_block_with_attr($name) {
	our @Outer_scopes;

	if @Outer_scopes {
		for @Outer_scopes {
			if $_{$name} {
				return $_;
			}
		}
	}

	return undef;
}

sub open_lexical_scope($name, $lstype) {
	my $new_scope := PAST::Block.new(
		:blocktype('immediate'),
		:name($name));

	$new_scope<lstype> := $lstype;

	my $hll := current_hll_block();

	if $hll {
		$new_scope.hll($hll.name());
	}

	my $namespace := current_namespace_block();

	if $namespace {
		$new_scope.namespace($namespace.namespace());
	}

	push_lexical_scope($new_scope);
	return $new_scope;
}

sub push_lexical_scope($scope) {
	our @Outer_scopes;

	if !@Outer_scopes {
		@Outer_scopes := new_array();
	}

	unless $scope.isa(PAST::Block) {
		DUMP($scope, "bogus");
		die("Attempt to push non-Block on lexical scope stack.");
	}

	@Outer_scopes.unshift($scope);
	#say("Open ", $scope<lstype>, " scope: ", $scope.name(),
	#	" Now ", +@Outer_scopes, " on stack");
}

#################################################################

=head4 HLL

=cut

our $Current_hll;

sub close_hll() {
	#my $past := close_lexical_scope('hll');
	#say("Closed HLL block: ", $past.name());
	my $hll := $Current_hll;
	$Current_hll := undef;
	return $hll;
}

sub current_hll_block() {
	#return find_lexical_block_with_attr("is_hll");
	return $Current_hll;
}

sub open_hll($hll) {
	#say("Setting HLL to ", $hll);

	my $block 	:= PAST::Block.new(:blocktype('immediate'), :name($hll));
	$block.hll($hll);
	$block<is_hll> := 1;
	$block<lstype> := 'hll';
	$block.name($hll);

	#push_lexical_scope($block);
	$Current_hll := $block;
	return $block;
}

#################################################################

=head4 Namespaces

Namespace blocks are implied by a C<hll> directive -- the implied namespace is
the empty, hll-root namespace.

The user may specify a namespace explicitly by the C<namespace> directive.
At the outermost level, specifying C<namespace NAME;> creates a namespace block
that continues until EOF, or the next C<hll> or C<namespace> directive.

At any level, the user may create a namespace block by enclosing statements or
declarations in curly braces:

	namespace NAME {
		# declarations or statements
	}

=cut

# Close the namespace that a class block inserted on stack
sub close_class() {
	return close_namespace('class');
}

# Close the namespace currently on the stack.
sub close_namespace($decl_mode) {
	close_decl_mode($decl_mode);
	my $past := close_lexical_scope('namespace');
	#say("Closed namespace: ", $past.name());
	return $past;
}

sub current_namespace_block() {
	return find_lexical_block_with_attr("is_namespace");
}

sub open_namespace($past, $decl_mode) {
	my @path	:= namespace_path_of_var($past);
	my $block	:= get_past_block_of_path(@path);
	#say("Opening namespace: ", join('::', @path));
	#DUMP($block, "namespace block");

	$block<is_namespace> := 1;
	$block<lstype> := 'namespace';

	push_lexical_scope($block);
	open_decl_mode($decl_mode);
	return $block;
}

sub open_class($class) {
	my $block := open_namespace($class, 'class');
	return $block;
}

#################################################################

=head4 Temporary variables

Some operations need temporary variables to store internal constructs,
temporary results, and the like.

=cut

our $Temporary_index := 0;

sub make_temporary_name($format) {
	return $format ~ substr('0000' ~  $Temporary_index++, -4);
}
