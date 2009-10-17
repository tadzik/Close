# $Id$

module Slam::Grammar::Actions;

=method access_qualifier

Creates a type-specifier entry, to be attached to a declarator or specifier.

=cut

method access_qualifier($/, $key)	{ PASSTHRU($/, $key); }

method dclr_adverb($/, $key)	{ PASSTHRU($/, $key); }

=method dclr_alias

Just another kind of declarator.

=cut

method dclr_alias($/) {
	my $past := Slam::Type::new_dclr_alias($<alias>.ast);
	DUMP($past);
	make $past;
}
=method dclr_array_or_hash

Constructs an immediate token to represent the type-declarator,
and attaches any attributes required (array #elements).

=cut

method dclr_array_or_hash($/, $key) {
	my $past;
	
	if $key eq 'hash' {
		NOTE("Building Hash declarator");
		$past := Slam::Type::Hash.new(:node($/));
	}
	elsif $key eq 'array' {
		NOTE("Building Array declarator");
		$past := Slam::Type::Array.new(:node($/),
			:elements($<size>.ast));
	}
	else {
		$/.panic("Unexpected $key value '", $key, "'");
	}
	
	DUMP($past);
	make $past;
}

method dclr_atom($/, $key) { PASSTHRU($/, $key); }
	
=method dclr_pointer

Creates a token around the '*' in the pointer declarator, and attaches
any qualifiers as children of the node.

=cut

method dclr_pointer($/) {
	NOTE("Creating pointer declarator");
	my $past := Slam::Type::Pointer.new(:name(~ $/), :node($/));
	$past.qualify(ast_array($<access_qualifier>));
	
	DUMP($past);
	make $past;
}

=method dclr_postfix

Passes through the array, hash, or function declarator.

=cut

method dclr_postfix($/, $key) { PASSTHRU($/, $key); }

method declarator($/) {	
	my $symbol := $<dclr_atom>.ast;
	ASSERT($symbol.isa(Slam::Symbol::Declaration),
		"A symbol at the heart of every declarator!");
	NOTE("Processing declarator: ", $symbol);
	DUMP($symbol);

	# Postfix declarators go on in order: X()[][%] is
	# a function returning an array of hash.
	my @postfix_dclrs := ast_array($<dclr_postfix>);

	NOTE(+@postfix_dclrs, " postfix declarators");
	for @postfix_dclrs {
		$symbol.attach($_);
	}
	
	# Prefix declarators go on in reverse order: *volatile *const X
	# is a const pointer to volatile pointer 
	my @prefix_dclrs := Array::reverse(ast_array($<dclr_pointer>));
	
	NOTE(+@prefix_dclrs, " prefix declarators");
	for @prefix_dclrs {
		$symbol.attach($_);
	}

	NOTE("Declarator fixed up (specifiers not added yet)");
	DUMP($symbol);
	make $symbol;
}

method _declarator_part_after_declarator($/) {
	my $symbol := $<declarator>.ast;
	NOTE("Assembling type and alias info for ", $symbol.name);
	
	# int '$x' alias x;
	# $x is the pirname, x is the alias, x is the name
	if $<dclr_alias> {
		$symbol.alias($<dclr_alias>[0].ast);
		NOTE("Aliased to ", $symbol.name);
	}
	
	for $<adverbs> {
		$symbol.add_adverb($_.ast);
	}

	# So far, there is no block.
	Q:PIR {{
		$P0 = box 0
		set_hll_global [ 'Slam' ; 'Grammar' ], '$!Decl_block', $P0
	}};
	
	DUMP($symbol);
	# No make here. See _done
}

method _declarator_part_block_close($/) {
	our $Symbols;
	my $declarator := $<declarator>.ast;
	
	if $declarator.type.isa(Slam::Type::Function) {
		NOTE("Closing function-definition block");
		my $block := $Symbols.leave_scope('Slam::Scope::Function');
		$declarator.attach($block);
		$block.attach($<body>[0].ast);
	}
	else {
		# Currently no support for aggregate types.
		DIE("NOT REACHED");
	}
		
	NOTE("Flagging last declaration as semicolon-optional.");
	Q:PIR {{
		$P0 = box 1
		set_hll_global [ 'Slam' ;'Grammar'], '$!Decl_block', $P0
	}};
}

method _declarator_part_block_open($/) {
	our $Symbols;
	NOTE("Opening declaration block");
	my $declarator := $<declarator>.ast;
	
	if $declarator.type.isa(Slam::Type::Function) {
		NOTE("Creating new definition block for code");
		my $definition := Slam::Scope::Function.new(
			:node($/),
			:parameter_scope($declarator.type.parameter_scope),
		);
		
		NOTE("Pushing new block on stack.");
		$Symbols.enter_scope($definition);
	}
	else {
		DIE("NOT REACHED"); # Struct, class, etc.
	}
}
	
method _declarator_part_done($/) {
	my $past := $<declarator>.ast;
	MAKE($past);
}

method _declarator_part_initializer($/) {
	my $initializer := $<initializer>[0].ast;
	NOTE("Adding initializer");
	DUMP($initializer);
	my $past := $<declarator>.ast;
	$past<initializer> := $initializer;
}

# NQP currently generates get_hll_global for functions. So qualify them all.
our %_decl_part;
%_decl_part<after_declarator>	:= Slam::Grammar::Actions::_declarator_part_after_declarator;
%_decl_part<block_close>		:= Slam::Grammar::Actions::_declarator_part_block_close;
%_decl_part<block_open>		:= Slam::Grammar::Actions::_declarator_part_block_open;
%_decl_part<done>			:= Slam::Grammar::Actions::_declarator_part_done;
%_decl_part<initializer>		:= Slam::Grammar::Actions::_declarator_part_initializer;

method declarator_part($/, $key) { self.DISPATCH($/, $key, %_decl_part); }

=method namespace_alias_declaration

Edits the enclosing block of this node, creating an alias for the namespace
name given.

=cut

method namespace_alias_declaration($/) {
	my $ns_name := $<namespace>.ast;
	my $past := $<alias>.ast;

	$past.isdecl(1);
	$past<is_alias> := 1;
	$past<alias_for> := $ns_name;
	
	DUMP($past);
	make $past;
}

method param_adverb($/, $key)	{ PASSTHRU($/, $key); }

=method parameter_declaration

Matches the declaration of a I<single> declarator, with a limited set of 
specifiers. When completed, pushes the declared symbol on to the current
lexical scope. (Note that C<declarator_name> will add the name to the 
scope's symbol table by default.) Returns a C<parameter_declaration> node, which is
constructed from the C<declarator> node returned by the C<declarator_name> rule.

Supports the adverbs appropriate to parameters, including C<named>, C<slurpy>,
and C<optional>.

=cut

method parameter_declaration($/) {
	NOTE("Assembling parameter_declaration");
	my $past := Slam::Node::create('parameter_declaration', 
		:from($<parameter>.ast),
	);
	
	my $specs	:= $<specifier_list>.ast;
	Slam::Type::add_specifier_to_declarator($specs, $past);
	
	for $<adverbs> {
		NOTE("Adding adverb '", $_.ast.name(), "'");
		Slam::Node::set_adverb($past, $_.ast);
	}
	
	if $<default> {
		NOTE("Adding default value");
		my $default := $<default>.ast;
		$past<default> := $default;
		$past.viviself($default);
	}
	
	DUMP($past);
	make $past;
}

=method parameter_list

Creates a function-returning declarator, which is set as the PAST result of 
the rule. The declarator contains a PAST::Block to represent the function's 
parameter scope.

=cut

method _parameter_list_close($/) {
	our $Symbols;

	my $slurpy	:= 0;
	
	for ast_array($<param_list>) {
		$Symbols.declare($_);

		if $_.adverbs<slurpy> {
			$slurpy := 1;
		}
	}

	NOTE("Popping parameter list from stack");
	my $params := $Symbols.leave_scope('Slam::Scope::Parameter');
	$params.arity(+@($params));
	
	NOTE("Creating function-returning declarator");
	my $past := Slam::Type::Function.new(:node($/), 
		:parameter_scope($params),
	);
	MAKE($past);
}

method _parameter_list_open($/) {
	our $Symbols;
	NOTE("Creating new parameter list scope");
	my $scope := Slam::Scope::Parameter.new(:node($/));
	$Symbols.enter_scope($scope);
	DUMP($scope);
}

our %_param_list := Hash::new(
	:close(	Slam::Grammar::Actions::_parameter_list_close),
	:open(	Slam::Grammar::Actions::_parameter_list_open),
);

method parameter_list($/, $key) { self.DISPATCH($/, $key, %_param_list); }

method specifier_list($/) {
	NOTE("Assembling specifier list");	
	my @specs := ast_array($<specs>);
	ASSERT(+@specs, 'Specifier list requires at least one item');

	my $past := @specs.shift;
	for @specs {
		$past := $past.attach($_);
	}
	
	MAKE($past);
}

=method symbol_declaration_list

Attaches specifier_list to each symbol's declarator. Declares symbols
within their respective scopes.

=cut

method symbol_declaration_list($/) {
	my $past	:= Slam::Statement::SymbolDeclarationList.new();
	my $specs	:= $<specifier_list>.ast;
	
	NOTE("Collecting declared symbols");
	
	for ast_array($<symbol>) {
		NOTE($_);
		DUMP($specs);
		$_.attach($specs);
		$past.attach($_);
	}
	
	MAKE($past);
}

method tspec_basic_type($/) {
	our $Symbols;
	
	my $typename := $<type>.ast;
	NOTE("Creating new builtin specifier: ", $typename.name);
	
	unless $Symbols.pervasive_scope.symbol($typename.name) {
		DIE("Basic type '", $typename.name, "' not in pervasive scope.");
	}
	
	my $past := Slam::Type::Specifier.new(
		:is_builtin(1),
		:node($/),
		:typename($typename),
	);

	MAKE($past);
}

method tspec_builtin($/) {
	my $name := ~ $<token>;
	NOTE("Creating new builtin specifier: ", $name);
	
	my $typename := PAST::Val.new(:name($name), :node($/));
	my $past := Slam::Type::Specifier.new(
		:node($/),
		:is_builtin(1),
		:typename($typename),
	);
	
	DUMP($past);
	make $past;
}


=method tspec_function_attr

Creates a type specifier around the keyword.

=cut

method tspec_function_attr($/) {
	my $name := ~ $<token>;
	NOTE("Creating new function attribute specifier: ", $name);
	
	my $past := Slam::Type::Specifier::access_qualifier($/,
		:name($name),
	);

	DUMP($past);
	make $past;
}

method tspec_not_type($/, $key) { PASSTHRU($/, $key); }

=method tspec_storage_class

Creates a token around the keyword.

=cut

method tspec_storage_class($/) {
	my $name := ~ $<token>;
	NOTE("Creating new storage class specifier: ", $name);
	
	my $past := Slam::Type::Specifier.new(
		:node($/),
		:storage_class($name),
		:name($name),
	);
	
	DUMP($past);
	make $past;
}

method tspec_type_specifier($/, $key) { PASSTHRU($/, $key); }

method tspec_type_name($/) {
	my $type := $<type_name>.ast;
	NOTE("Creating new specifier for type name: ", $type);
	my $past := Slam::Type::Specifier.new(:typename($type));
	MAKE($past);
}

method using_namespace_directive($/) {
	my $using_nsp := $<namespace>.ast;
	ASSERT($using_nsp.node_type eq 'namespace_path',
		'Namespace paths must be namespace_pathtokens');
	NOTE("Using  namespace ", $using_nsp);

	my $past := Slam::Statement::UsingNamespace.new(:node($/),
		:using_namespace($using_nsp),
	);

	make $past;
}