
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
		self.declaration_done($/);
	}
}

# Called by 'declaration' when end of decl is reached.
method declaration_done($/) {
	my $lstype;
	my $decl_mode := 'ERROR: in declaration()';
	
	# This code has to deal with every single kind of declaration. Yikes.
	my $past := close_declaration();

	# Got any adverbs?
	if +@($<adverbs>.ast) {
		for @($<adverbs>.ast) {
			decl_add_adverb($/, $past, $_);
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
	elsif $type eq 'str' || $type eq 'string'  { $rtype := "S"; }
	elsif $type eq 'void' { $rtype := "v"; }
	else { $rtype := "P"; }
}

method declarator($/) {
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

method initializer($/, $key) { PASSTHRU($/, $key); }

