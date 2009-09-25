# $Id$

class close::Grammar::Actions;

=method cv_qualifier

Creates a type-specifier entry, with "is_<?>" set to 1. Type-specifier is used 
because a cv_qualifier is a valid type specifier by itself.

=cut

method cv_qualifier($/) {
	my $name := ~ $<token>;
	NOTE("Creating new cv qualifier: ", $name);
	my $past := close::Compiler::Node::create('type_specifier');
	$past{'is_' ~ $name} := 1;

	DUMP($past);
	make $past;
}

method dclr_adverb($/) {
	NOTE("Found declarator_adverb: ", ~$/);

	my $signature;
	
	if $<signature> {
		$signature := ~ $<signature>;
		NOTE("Got signature: ", $signature);
	}
	elsif $<register_class> {
		$signature := $<register_class>.ast.value();
	}
	
	my $past := close::Compiler::Node::create('adverb', 
		:node($/), 
		:name(~$<token>),
		:signature($signature),
		:value(~$<token>),
	);

	DUMP($past);
	make $past;
}

=method dclr_alias

Just another kind of declarator.

=cut

method dclr_alias($/) {
	my $past := close::Compiler::Types::new_dclr_alias($<alias>.ast);
	DUMP($past);
	make $past;
}
=method dclr_array_or_hash

Constructs an immediate token to represent the type-declarator,
and attaches any attributes required (array #elements).

=cut

method dclr_array_or_hash($/, $key) {
	my $past := close::Compiler::Node::create($key, :node($/));
	
	if $<size> {
		$past<elements> := $<size>.ast;
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
	my $past := close::Compiler::Types::pointer_to(
		:name(~ $/),
		:node($/), 
	);
	
	for $<cv_qualifier> {
		$past := close::Compiler::Types::merge_specifiers($past, $_.ast);
	}

	DUMP($past);
	make $past;
}

=method dclr_postfix

Passes through the array, hash, or function declarator.

=cut

method dclr_postfix($/, $key) { PASSTHRU($/, $key); }

method declaration($/) {
	my $past	:= close::Compiler::Node::create('decl_varlist');
	my $specs	:= $<specifier_list>.ast;
	
	NOTE("Processing declarators");
	
	for $<symbol> {
		my $declarator := $_.ast;
		
		if $declarator<definition> {
			NOTE("Replacing declarator with definition");
			$declarator := $declarator<definition>;
		}

		NOTE("Merging specifier with declarator '", $declarator.name(), "'");
		$declarator := 
			close::Compiler::Types::add_specifier_to_declarator($specs, $declarator);
			
		# FIXME: Is this needed? Should this be a separate pass?
		#NOTE("Adding declarator to its scope");
		#close::Compiler::Scopes::add_declarator($declarator);
		
		NOTE("Adding declarator to decl-varlist");
		$past.push($declarator);
	}

	NOTE("done");
	DUMP($past);
	make $past;
}

method declarator($/) {	
	my $past := $<dclr_atom>.ast;
	NOTE("Processing declarator: ", $past.name());
	DUMP($past);
	
	my $last_dclr := $past<etype>;

	for $<dclr_postfix> {
		NOTE("Adding postfix declarator: ", $_.ast.name());
		$last_dclr<type> := $_.ast;
		$last_dclr := $_.ast;
	}
	
	$past<etype> := $last_dclr;

	# Reverse the chain of pointer declarators:
	# int *const *volatile X;  becomes
	# X -> *volatile -> *const -> int
	my $pointer_chain;
	$last_dclr := Scalar::undef();
	
	for $<dclr_pointer> {
		$_.ast<type> := $pointer_chain;
		$pointer_chain := $_.ast;
		
		unless $last_dclr {
			$last_dclr := $pointer_chain;
		}
	}
	
	# Append pointer chain to declarators
	# X -> array of -> pointer to...
	if $last_dclr {
		$past<etype><type> := $pointer_chain;
		$past<etype> := $last_dclr;
	}
	
	NOTE("Declarator fixed up (specifiers not added yet)");
	DUMP($past);
	make $past;
}

method declarator_part($/, $key) {
	if $key eq 'close_block' {
		# Now there is a block.
		Q:PIR {{
			$P0 = box 1
			set_hll_global ['close';'Grammar'], '$!Decl_block', $P0
		}};
		
		NOTE("Closing decl block");
		my $past := close::Compiler::Scopes::pop('function_definition');
		
		# Merge the <body> block with $past
		close::Compiler::Node::copy_block($<body>[0].ast, $past);
		$past<using_namespaces> := $<body>[0].ast<using_namespaces>;
	}
	elsif $key eq 'declarator' {
		my $past := $<declarator>.ast;
		NOTE("Assembling declarator ", $past.name());
		
		# int '$x' alias x; say(x);
		# $x is the pirname, x is the alias, x is the name
		if $<dclr_alias> {
			$past<alias> := $<dclr_alias>[0].ast;
			$past<pirname> := $past.name();
			close::Compiler::Node::set_name($past, $past<alias>.name());
		}
		
		for $<adverbs> {
			close::Compiler::Node::set_adverb($past, $_.ast);
		}

		# So far, there is no block.
		Q:PIR {{
			$P0 = box 0
			set_hll_global ['close';'Grammar'], '$!Decl_block', $P0
		}};
	}
	elsif $key eq 'initializer' {
		my $initializer := $<initializer>[0].ast;
		NOTE("Adding initializer");
		DUMP($initializer);
		my $past := $<declarator>.ast;
		$past<initializer> := $initializer;
	}
	elsif $key eq 'open_block' {
		NOTE("Opening decl block");
		# Push the params block on stack
		my $declarator := $<declarator>.ast;
		# This won't be true when struct's get added.
		ASSERT(NODE_TYPE($declarator<type>) eq 'decl_function_returning',
			'Open block should only happen for functions');
		
		if $declarator<type><is_function> {
			NOTE("Block is function definition. Pushing new block on stack.");
			
			my $definition := close::Compiler::Node::create('function_definition',
				:from($declarator),
			);
			$declarator<definition> := $definition;
			close::Compiler::Scopes::push($definition);
		}
		else {
			DIE("NOT REACHED"); # Struct, class, etc.
		}
	} 
	elsif $key eq 'done' {
		my $past := $<declarator>.ast;
		NOTE("done");
		DUMP($past);
		make $past;
	}
	else {
		$/.panic("Invalid $key '", $key, "' passed to declarator_part()");
	}
}

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

method param_adverb($/) {
	NOTE("Creating parameter adverb from: ", $/);

	my $named;
	
	if $<named> {
		my $param_name := $<named>[0].ast;
		DUMP($param_name);
		$named := $param_name.value();
	}
	
	my $past := close::Compiler::Node::create('adverb', 
		:node($/), 
		:name(~$<token>),
		:named($named),
		:value(~$<token>),
	);
	
	DUMP($past);
	make $past;
}

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
	my $past := close::Compiler::Node::create('parameter_declaration', 
		:from($<parameter>.ast),
	);
	
	my $specs	:= $<specifier_list>.ast;
	close::Compiler::Types::add_specifier_to_declarator($specs, $past);
	
	for $<adverbs> {
		NOTE("Adding adverb '", $_.ast.name(), "'");
		close::Compiler::Node::set_adverb($past, $_.ast);
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

method parameter_list($/, $key) {
	if $key eq 'open' {
		NOTE("Creating new parameter list");
		my $past := close::Compiler::Types::function_returning(:node($/));
		close::Compiler::Scopes::push($past);
		
		NOTE("Pushed new scope on stack: ", $past.name());
		DUMP($past);
	}
	elsif $key eq 'close' {
		NOTE("Popping parameter list from stack");
		my $past	:= close::Compiler::Scopes::pop('declarator');
		my $params	:= $past<parameters>;
		my $slurpy	:= 0;
		
		for ast_array($<param_list>) {
			$params.push($_);
			close::Compiler::Scopes::add_declarator_to($_, $past);
			
			if $_<adverbs><slurpy> {
				$slurpy := 1;
			}
		}
		
		unless $slurpy {
			$past.arity(+@($params));
		}
		
		NOTE('End function parameter list: ', +@($past), ' parameters');
		DUMP($past);
		make $past;
	}
	else {
		$/.panic('Unrecognized $key in action dclr_param_list: ' ~ $key);
	}
}

method specifier($/, $key) { PASSTHRU($/, $key); }

method specifier_list($/) {
	NOTE("Assembling specifier list");
	
	my @specs := ast_array($<specifier>);
	ASSERT(+@specs, 'Specifier list requires at least one item');
	my $past := @specs.shift();

	for @specs {
		$past := close::Compiler::Types::merge_specifiers($past, $_);
	}
	
	NOTE("done");
	DUMP($past);
	make $past;
}

=method tspec_builtin_type

Creates a type specifier with noun set to the type name.

=cut

method tspec_builtin_type($/) {
	my $name := ~ $<token>;
	NOTE("Creating new type specifier for builtin type: ", $name);
	
	my $type_name := close::Compiler::Node::create('qualified_identifier', 
		:parts(Array::new($name)),
		:node($/),
	);

	DUMP($type_name);
	my @matches := close::Compiler::Lookups::query_matching_types($type_name);
	DUMP(@matches);
	ASSERT(+@matches == 1, 
		'query_matching_types should always be able to find exactly one matching builtin type');
		
	$type_name<apparent_type>  := @matches.shift();
	my $past := close::Compiler::Node::create('type_specifier',
		:noun($type_name));
	
	DUMP($past);
	make $past;
}

=method tspec_function_attr

Creates a type specifier around the keyword.

=cut

method tspec_function_attr($/) {
	my $name := ~ $<token>;
	NOTE("Creating new function attribute specifier: ", $name);
	my $past := close::Compiler::Node::create('type_specifier');
	$past{'is_' ~ $name} := 1;

	DUMP($past);
	make $past;
}

=method tspec_storage_class

Creates a token around the keyword.

=cut

method tspec_storage_class($/) {
	my $name := ~ $<token>;
	NOTE("Creating new storage class specifier: ", $name);

	my $past := close::Compiler::Types::specifier(:name($name), :node($/));
		
	DUMP($past);
	make $past;
}

method tspec_type_specifier($/, $key) { PASSTHRU($/, $key); }

method tspec_type_name($/) {
	my $type_name := $<type_name>.ast;
	my $name	:= $type_name.name();
	NOTE("Creating new specifier for type_name: ", $name);

	ASSERT($type_name<apparent_type>,
		'Type_name lookup sets apparent type to current resolution of name');
		
	my $past := close::Compiler::Node::create('type_specifier',
		:noun($type_name));

	DUMP($past);
	make $past;
}

method using_namespace_directive($/) {
	my $using_nsp := $<namespace>.ast;
	NOTE("Using ", NODE_TYPE($using_nsp), " namespace ", $using_nsp.name());
	ASSERT(NODE_TYPE($using_nsp) eq 'namespace_path',
		'Namespace paths must be namespace_name tokens');

	# Resolve using-nsp to absolute value.
	$using_nsp := close::Compiler::Namespaces::fetch_namespace_of($using_nsp);
	
	my $past := close::Compiler::Node::create('using_directive',
		:name('using namespace'),
		:node($/),
		:using_namespace($using_nsp),
	);

	my $block := close::Compiler::Scopes::current();
	close::Compiler::Scopes::add_using_namespace($block, $past);
	
	NOTE("Added namespace ", $using_nsp<display_name>, " to using list of block: ", $block.name());
	DUMP($past);
	make $past;
}