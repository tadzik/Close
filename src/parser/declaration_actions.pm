# $Id$

our %Adverb_aliases;
%Adverb_aliases{'...'} := 'slurpy';
%Adverb_aliases{'?'} := 'optional';

sub adverb_unalias_name($adverb) {
	my $name := $adverb.value();
	NOTE("Unaliasing adverb: '", $name, "'");
	DUMP($adverb);
	
	if %Adverb_aliases{$name} {
		$name := %Adverb_aliases{$name};
	}
	elsif String::char_at($name, 0) eq ':' {
		$name := String::substr($name, 1);
	}
	
	ASSERT(String::length($name) > 0, 'Adverb name must have some value.');
	NOTE("Unaliased name is: '", $name, "'");
	return $name;
}

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
	NOTE("Found declarator_adverb: ", ~$<token>);
	my $past := make_token($<token>);	
	close::Compiler::Node::set_name($past, adverb_unalias_name($past));
	
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
	
=method dclr_alias_init($/)

=cut

method dclr_alias_init($/) {
	my $past := $<declarator>.ast;
	
	if $<initializer> {
		$past<initializer> := $<initializer>[0].ast;
	}
	
	DUMP($past);
	make $past;
}

=method dclr_pointer

Creates a token around the '*' in the pointer declarator, and attaches
any qualifiers as children of the node.

=cut

method dclr_pointer($/) {
	my $past := new_dclr_pointer();
	$past.node($/);
	close::Compiler::Node::set_name($past, ~$/);
	
	for $<cv_qualifier> {
		$past := close::Compiler::Types::merge_specifiers($past, $past, $_.ast);
	}

	DUMP($past);
	make $past;
}

=method dclr_postfix

Passes through the array, hash, or function declarator.

=cut

method dclr_postfix($/, $key) { PASSTHRU($/, $key); }

method declaration($/, $key) {
	if $key eq 'specifiers' {
		NOTE("Processing specifiers");
		# Create a temporary block on scope stack, so symbol names
		# are visible to later declarations in this same structure.
		# e.g., typedef int X, X* PX; // X must be visible after comma
		my $block	:= close::Compiler::Node::create('decl_temp',
			:name('temporary declaration scope')
		);
		close::Compiler::Scopes::push($block);
		
		my $past	:= $block<varlist>;
		
		for $<specifier> {
			$past<specifier> := close::Compiler::Types::merge_specifiers($past, $past<specifier>, $_.ast);
		}
		
		NOTE("Pushed temporary varlist scope on stack.");
		DUMP($block);
	}
	elsif $key eq 'declarators' {
		# When the declaration is complete (now), discard the 
		# decl_temp block. Move the individual declarations up
		# to the containing block.
		
		my $block	:= close::Compiler::Scopes::pop('decl_temp');
		ASSERT(+@($block) == 0,
			'No statements should be added to temporary decl_temp scope block.');
		my $past	:= $block<varlist>;
		
		NOTE("Processing declarators");
		for $<symbol> {
			my $declarator := $_.ast;	
			
			NOTE("Merging specifier with declarator '", $declarator.name(), "'");
			$declarator := 
				close::Compiler::Types::add_specifier_to_declarator($past<specifier>, $declarator);
				
			# FIXME: What does "extern OtherNamespace::X" do to
			# the local namespace? Add X? 
			# FIXME: Am I handling aliases/pirnames correctly?
			# FIXME: What about function definitions?
			# FIXME: Should there be/must there be some kind of add-to-function
			# call, nstead of current? Maybe things can nest that prevent declarator
			# being added high enough?
			close::Compiler::Scopes::add_declarator_to_current($declarator);
			
			# If it's a function definition, add it to current block.
			if $declarator<type><is_function> {
				#close::Compiler::Scopes::current().push($declarator<type><function_definition>);
				$past.push($declarator<type>);
			}
			else {
				# FIXME: Need to decide when not to add this?
				$past.push($declarator);
			}
		}

		NOTE("done");
		DUMP($past);
		make $past;
	}
	else {
		$/.panic('Unrecognized $key in action declaration: ' ~ $key);
	}
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
		NOTE("Closing decl block");
		close::Compiler::Scopes::pop('decl_function_returning');
	}
	elsif $key eq 'open_block' {
		NOTE("Opening decl block");
		# Push the params block on stack
		my $declarator := $<declarator>.ast;
		# This won't be true when struct's get added.
		ASSERT(NODE_TYPE($declarator<type>) eq 'decl_function_returning',
			'Open block should only happen for functions');
			
		close::Compiler::Scopes::push($declarator<type>);
		
	} 
	elsif $key eq 'done' {
		my $past := $<declarator>.ast;
		NOTE("Assembling declarator ", $past.name());
		
		if $<dclr_alias> {
			$past<alias> := $<dclr_alias>[0].ast;
		}
		
		for $<adverbs> {
			my $adv := $_.ast;
			$past<adverbs>{$adv.name()} := $adv;
		}
		
		if $<initializer> {
			NOTE("Adding initializer");
			my $initializer := $<initializer>[0].ast;

			DUMP($initializer);
			$past<initializer> := $initializer;
		}
		
		if $<body> {
			# NB: This assert isn't permanent.
			ASSERT($past<type><is_function>, 
				"It's a function, unless it's a class or something.");
			
			if $past<type><is_function> {
				# FIXME: I'm grabbing hll and namespace here, but I'm not storing them
				# in the declarator_name -- that waits for the resolution phase. 
				# It seems like I should do both at the same time, but I have the feeling 
				# that there are some cases where this isn't the right approach. Maybe
				# with templates, maybe with nested functions. I need to think about it
				# some more.
				my $current_nsp := close::Compiler::Scopes::fetch_current_namespace();
				DUMP($current_nsp);
				my $definition := close::Compiler::Node::create('function_definition',
					:from($<body>[0].ast),
					:hll($current_nsp.hll()),
					:name($past.name()),
					:namespace($current_nsp.namespace()),
				);
				
				NOTE("Node type is ", NODE_TYPE($past<type>));
				ASSERT(NODE_TYPE($past<type>) eq 'decl_function_returning',
					'is_function should only be true on decl_function_returning nodes, I think');
					
				$past<type><is_defined> := 1;
				$past<type><definition> := $definition;
				$past<type>.push($definition);
			}
		}
		
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

method namespace_definition($/, $key) {
	if $key eq 'open' {
		# FIXME: This should be a function, maybe part of the namespace_path target.
 		my $path	:= $<namespace_path>.ast;
		my @namespace_path;
		
		if $path<is_rooted> {
			@namespace_path	:= $path.namespace();
			@namespace_path.unshift($path<hll>);
		}
		else {
			my $parent		:= close::Compiler::Scopes::fetch_current_namespace();
			@namespace_path	:= Array::concat($parent<path>, $path.namespace());
		}

		NOTE("Opening namespace: hll: ", Array::join(' :: ', @namespace_path));
		my $namespace := close::Compiler::Namespaces::fetch(@namespace_path);
		close::Compiler::Scopes::push($namespace);
	}
	else { # $key eq 'close'
		my $past := close::Compiler::Scopes::pop('namespace_block');
		
		for $<extern_statement> {
			$past.push($_.ast);
		}
		
		DUMP($past);
		make $past;
	}
}

method param_adverb($/) {
	my $past := make_token($<token>);
	close::Compiler::Node::set_name($past, adverb_unalias_name($past));
	
	DUMP($past);
	make $past;
}

=method parameter_declaration

Matches the declaration of a I<single> declarator, with a limited set of 
specifiers. When completed, pushes the declared symbol on to the current
lexical scope. (Note that C<declarator_name> will add the name to the 
scope's symtable by default.) Returns a C<parameter_declaration> node, which is
constructed from the C<declarator> node returned by the C<declarator_name> rule.

Supports the adverbs appropriate to parameters, including C<named>, C<slurpy>,
and C<optional>.

=cut

method parameter_declaration($/) {
	my $index := close::Compiler::Scopes::current()<num_parameters>++;
	my $past := close::Compiler::Node::create('parameter_declaration', 
		:from($<parameter>.ast),
		:index($index),
	);
	
	my $specifier;

	for $<specifier> {
		$specifier := close::Compiler::Types::merge_specifiers($past, $specifier, $_.ast);
	}

	close::Compiler::Types::add_specifier_to_declarator($specifier, $past);
	
	for $<adverbs> {
		my $adv := $_.ast;
		$past<adverbs>{$adv.name()} := $adv;
	}
	
	if $<default> {
		$past<default> := $<default>.ast;
	}
	
	# Declare object in current scope, which should be a parameter block.
	ASSERT(
		close::Compiler::Scopes::get_symbol(
			close::Compiler::Scopes::current(), $past.name()) =:= $past,
		'Expected current scope would already have this parameter declared (by <declarator_name>)');

	# Insert declaration into current scope.
	#my $scope := close::Compiler::Scopes::current();
	#NOTE("Pushing parameter declaration of ", $past.name(), " into current scope: ", $scope.name());
	#$scope.push($past);
	
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
		NOTE('Begin function parameter list');
		
		my $past := close::Compiler::Node::create('decl_function_returning',
			:node($/));
		
		close::Compiler::Scopes::push($past);

		NOTE("Pushed new scope on stack: ", $past.name());
		DUMP($past);
	}
	elsif $key eq 'close' {
		my $past := close::Compiler::Scopes::pop('decl_function_returning');
		NOTE("Popped scope from stack: ", $past.name());

		my $params := close::Compiler::Node::create('decl_varlist',
			:name('parameter_list'),
			:node($/),
		);
		
		for $<param_list> {
			$params.push($_.ast);
		}
		
		$past.push($params);
		$past<param_list> := $params;
		
		NOTE('End function parameter list: ', +@($past), ' parameters');
		DUMP($past);
		make $past;
	}
	else {
		$/.panic('Unrecognized $key in action dclr_param_list: ' ~ $key);
	}
}

method specifier($/, $key) { PASSTHRU($/, $key); }

=method tspec_builtin_type

Creates a type specifier with noun set to the type name.

=cut

method tspec_builtin_type($/) {
	my $name := ~ $<token>;
	NOTE("Creating new type specifier for builtin type: ", $name);
	
	my $type_name := close::Compiler::Node::create('qualified_identifier', 
		:name($name),
		:display_name($name),
		:node($/),
	);

	my @matches := close::Compiler::Types::query_matching_types($type_name);
	ASSERT(+@matches == 1, 
		'query_matching_types should always be able to find a builtin type');
		
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
	my $past := close::Compiler::Node::create('type_specifier',
		:storage_class($name));
		
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
	
	my $current_nsp := close::Compiler::Scopes::fetch_current_namespace();
	$using_nsp := close::Compiler::Namespaces::fetch_relative_namespace_of($current_nsp, $using_nsp);

	my $block := close::Compiler::Scopes::current();
	close::Compiler::Scopes::add_using_namespace($block, $using_nsp);
	
	my $past := close::Compiler::Node::create('using_directive',
		:name('using namespace'),
		:using_namespace($using_nsp),
		:node($/),
	);

	NOTE("Added namespace ", $using_nsp.name(), " to using list of block: ", $block.name());
	DUMP($past);
	make $past;
}