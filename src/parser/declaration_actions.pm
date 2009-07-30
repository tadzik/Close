# $Id$

method declaration($/) {
	# Convert individual declarators into type-chains
	# Create Past Var entries for each declarator.
	# Lookup init values for types where no dclr_initializer is provided.
	# Set types for 'auto' decls with dclr_initializers.
	my $past := PAST::VarList.new();
	
	# Modify $specifier to reflect all the specifiers we saw. 
	# Attach errors to $past.
	for $<specifier> {
		$past<specifier> := merge_tspec_specifiers($past, $past<specifier>, $_.ast);
	}
	
	# Merge the specifier in to the declarator. Attach errors, etc.
	for $<dclr_init_list><item> {
		my $declarator := $_.ast;

		$declarator<etype><type> := $past<specifier>;
		$declarator<etype> := $past<specifier>;
		$past.push($_.ast);
	}

	DUMP($past, "declaration");
	make $past;
}

=method cv_qualifier

Creates a type-specifier entry, with "is_<?>" set to 1. Type-specifier is used 
because a cv_qualifier is a valid type specifier by itself.

=cut

method cv_qualifier($/) {
	my $past := new_tspec_type_specifier('is_' ~ $<token>, 1);
	$past.name(~$<token>);
	DUMP($past, "cv_qualifier");
	make $past;
}

=method dclr_array_or_hash

Constructs an immediate token to represent the type-declarator,
and attaches any attributes required (array #elements).

=cut

method dclr_array_or_hash($/) {
	my $past;
	
	if $<hash> {
		$past := new_dclr_hash();
	}
	elsif $<expression> {
		$past := immediate_token("FixedArray");
		$past<num_elements> := $<expression>.ast;
	}
	else {
		$past := immediate_token("Array");
	}
	$past.node($/);
	
	DUMP($past, "array_or_hash_decl");
	make $past;
}

# method declarator_name($/)
# This method is defined in name_actions.pm

=method dclr_atom

Passes through the PAST of the C<declarator_name> or of the 
nested C<declarator>.

=cut

method dclr_atom($/) {
	if $<declarator_name> {
		make $<declarator_name>.ast;
	}
	else {
		make $<declarator>.ast;
	}
}

method dclr_declarator($/) {	
	my $past := $<dclr_atom>.ast;
	
	unless $past<etype> {
		$past<etype> := $past;
	}
	
	my $last_dclr := $past<etype>;
	
	# Merge postfix declarator mods (array, function, hash) in to 
	# $past - the inner declarator or symbol name. Postfix declarators
	# read left to right, so foo()[] is a function returning an array. 
	# The declarator chain here should be 'foo'->function->array.
	for $<dclr_postfix> {
		$last_dclr<type> := $_.ast;
		$last_dclr := $_.ast;
	}
	
	$past<etype> := $last_dclr;
	
	# Merge prefix declarator mods (pointer) in to $past.
	# Prefix declarators read from right to left, making 
	# C< *v *c foo> a "const pointer to volatile pointer".
	# The declarator chain should be foo -> *c -> *v.	
	$last_dclr := $past<etype><type>;
	
	for $<dclr_pointer> {
		# Reverse pointers by "inserting" them in at back of list.
		$_.ast<type> := $past<etype><type>;
		$past<etype><type> := $_.ast;
		
		if !$last_dclr {
			$last_dclr := $_.ast;
		}
	}

	if $last_dclr {
		$past<etype> := $last_dclr;
	}
	
	DUMP($past, "declarator");
	make $past;
}
	
method declarator2($/) {
	# Get name and other info from the identifier ast.
	my $symbol		:= $<name>.ast;
	my $decl		:= current_declaration();

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
		# long-ident inherits the nsp)
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

=method dclr_init($/)

=cut

method dclr_init($/) {
	my $past := $<dclr_declarator>.ast;
	
	if $<dclr_initializer> {
		$past<dclr_initializer> := $<dclr_initializer>.ast;
	}
	
	DUMP($past, "dclr_init");
	make $past;
}

# method dclr_init_list
# does not exist. See L<#declaration>.

=method dclr_initializer($/)

Passes through the C<expression>.

=cut

method dclr_initializer($/) { PASSTHRU($/, 'expression', 'dclr_initializer'); }

=method dclr_param_list

Creates a PAST::Block to serve as the function container. Adds all the parameter
declarations to the block. Returns the block.

=cut

method dclr_param_list($/) {
	my $past := new_dclr_function();
	$past.node($/);
	
	for $<param_list> {
		$past.push($_.ast);
	}
	
	DUMP($past, "parameter_decl_list");	
	make $past;
}

=method dclr_pointer

Creates a token around the '*' in the pointer declarator, and attaches
any qualifiers as children of the node.

=cut

method dclr_pointer($/) {
	my $past := new_dclr_pointer();
	$past.node($/);
	$past.name(~$/);
	
	for $<cv_qualifier> {
		$past := merge_tspec_specifiers($past, $past, $_.ast);
	}

	DUMP($past, 'dclr_pointer');
	make $past;
}

=method dclr_postfix

Passes through the array, hash, or function declarator PAST.

=cut

method dclr_postfix($/, $key) { PASSTHRU($/, $key, 'dclr_postfix'); }

method specifier($/, $key) { PASSTHRU($/, $key, 'specifier'); }

=method tspec_builtin_type

Creates a type specifier with noun set to the type name.

=cut

method tspec_builtin_type($/) {
	my $past := new_tspec_type_specifier('noun', ~$<token>);
	DUMP($past, "builtin_type");
	make $past;
}

=method tspec_function_attr

Creates a token around the keyword.

=cut

method tspec_function_attr($/) {
	my $past := new_tspec_type_specifier('is_' ~ $<token>, 1);
	DUMP($past, "tspec_function_attr");
	make $past;
}

=method tspec_storage_class

Creates a token around the keyword.

=cut

method tspec_storage_class($/) {
	my $past := new_tspec_type_specifier('storage_class', ~$<token>);
	DUMP($past, "tspec_storage_class");
	make $past;
}

method tspec_type_specifier($/, $key) { PASSTHRU($/, $key, 'tspec_type_specifier'); }

################################################################

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

method declaration2($/, $key) {
	my $lstype;
	my $dclr_mode := 'ERROR: in declaration()';

	if $key eq 'body_open' {
		# Put PAST::Block back on stack as either function body
		# or class block.
		my $block := current_declaration();

		if $block<is_extern> {
			$/.panic("You cannot use 'extern' with a definition");
		}

		if $block<is_function> {
			$lstype := 'function body';
			$dclr_mode := 'local';

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
			$dclr_mode := 'class';
		}
		else {
			DUMP($block, "current_decl");
			$/.panic("Blocks can only be used "
				~ "in class and function definitions");

		}

		#say("Opening declaration of " ~ $lstype ~ " " ~ $block.name());
		open_decl_mode($dclr_mode);
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
			$dclr_mode := 'local';
		}
		elsif $block<is_class> {
			close_class();
			$lstype := 'class body';
			$dclr_mode := 'class';
		}

		#say("Closing declaration of " ~ $lstype ~ " " ~ $block.name());
		close_decl_mode($dclr_mode);
		close_lexical_scope($lstype);
	}
	else {
		self.declaration_done($/);
	}
}

# Called by 'declaration' when end of decl is reached.
method declaration_done($/) {
	my $lstype;
	my $dclr_mode := 'ERROR: in declaration()';
	
	# This code has to deal with every single kind of declaration. Yikes.
	my $past := close_declaration();

	# Got any adverbs?
	if +@($<adverbs>.ast) {
		for @($<adverbs>.ast) {
			dclr_add_adverb($/, $past, $_);
		}
	}
	
	# FIXME: This is wrong, for classes at least. Need to insert declaring name
	# into parent namespace before block open, so block guts can refer to it.
	
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
		# TODO: Do I pass dclr_initializer in here?
		add_class_attribute($past);
	}

	if $<dclr_initializer> {
		# FIXME: Is this wrong? Should this be an assignment ?
		$past.viviself($<dclr_initializer>[0].ast);
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
		
		#DUMP($past, "function: " ~ $past.name);
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

method specifiers($/) {
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
	elsif $type eq 'str' || $type eq 'string'  { $rtype := "S"; }
	elsif $type eq 'void' { $rtype := "v"; }
	else { $rtype := "P"; }
}
