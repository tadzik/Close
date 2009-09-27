# $Id$

module close::Compiler::Types;

sub ASSERT($condition, *@message) {
	Dumper::ASSERT(Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	Dumper::DIE(Dumper::info(), @msg);
}

sub DUMP(*@pos, *%what) {
	Dumper::DUMP(Dumper::info(), @pos, %what);
}

sub NOTE(*@parts) {
	Dumper::NOTE(Dumper::info(), @parts);
}

################################################################

sub ADD_ERROR($node, *@msg) {
	close::Compiler::Messages::add_error($node,
		Array::join('', @msg));
}

sub ADD_WARNING($node, *@msg) {
	close::Compiler::Messages::add_warning($node,
		Array::join('', @msg));
}

sub NODE_TYPE($node) {
	return close::Compiler::Node::type($node);
}

################################################################

# Runs at init time
_onload();

sub _onload() {
	my $meta := Q:PIR {
		%r = new 'P6metaclass'
	};

	my $base := $meta.new_class('close::Compiler::Type', :parent('PCT::Node'));
	$meta.new_class('close::Compiler::Type::Specifier', :parent($base));
	$meta.new_class('close::Compiler::Type::Declarator', :parent($base));
}

sub add_specifier_to_declarator($specifier, $declarator) {
	$declarator<etype><type> := $specifier;
	$declarator<etype> := $specifier;
	
	DUMP($declarator);
	return $declarator;
}

sub get_specifier($node) {
	my $spec := $node<type>;
	
	unless $spec {
		DIE("Don't know how to find linkage of symbol: ", $node.name());
	}
		
	while ! $spec<is_specifier> {
		unless $spec<type> {
			DIE("Cannot locate specifier of symbol: ", $node.name());
		}
			
		$spec := $spec<type>;
	}

	DUMP($spec);
	return $spec;
}

sub array_of(*%attributes) {
	my $elements := %attributes<elements>;
	NOTE("Creating declarator node for array of ", $elements);
	
	my $kind := 'array of';
	
	if Scalar::defined($elements) {
		$kind := $kind ~ ' ' ~ $elements;
	}
	
	my $declarator := create_declarator($kind, %attributes);

	NOTE("done");
	DUMP($declarator);
	return $declarator;
}

sub create_declarator($kind, %outer_attrs, *%attributes) {
	NOTE("Creating declarator node for '", $kind, "'");
	
	Hash::merge(%attributes, %outer_attrs);
	
	my $decl_type := String::split(' ', $kind).shift();
	
	%attributes{ 'is_' ~ $decl_type }	:= 1;
	%attributes<is_declarator>		:= 1;
	%attributes<declarator_type>	:= $kind;
	
	my $declarator := close::Compiler::Node::create_from_hash('declarator', %attributes);
	
	NOTE("done");
	DUMP($declarator);
	return $declarator;
}

sub function_returning(*%attributes) {
	NOTE("Creating declarator node for function returning");
	
	my $params := close::Compiler::Node::create('decl_varlist',
		:name('parameter list'),
	);
	
	%attributes<parameters>		:= $params;

	my $declarator := create_declarator('function returning', %attributes,
		:blocktype('immediate'),
		:default_scope('parameter'),
		:past_type(PAST::Block),		# Need block for parameters
	);

	$declarator.push($params);
	
	NOTE("done");
	DUMP($declarator);
	return $declarator;
}

sub hash_of(*%attributes) {
	NOTE("Creating declarator node for hash");
	
	my $declarator := create_declarator('hash of', %attributes);

	NOTE("done");
	DUMP($declarator);
	return $declarator;
}

sub pointer_to(*%attributes) {
	NOTE("Creating declarator node for hash");
	
	my $declarator := create_declarator('pointer to', %attributes);

	NOTE("done");
	DUMP($declarator);
	return $declarator;
}

sub scope_for_storage_class($class) {
	our %scopes;
	
	unless %scopes {
		%scopes := Hash::new(
			:dynamic(	'lexical'),
			:extern(	'package'),
			:lexical(	'lexical'),
			:parameter(	'lexical'),
			:register(	'register'),
			:static(	'package'),
			:typedef(	'typedef'),
		);
	}
	
	return %scopes{$class};
}

sub specifier(*%attributes) {
	my $name := %attributes<name>;
	ASSERT($name, 'Every specifier must have a name');
	NOTE("Creating type specifier for ", $name);
	
	my $flag := 'is_' ~ $name;
	
	if $name eq '_builtin' {
		$flag := 'is_builtin';
	}
	
	%attributes{$flag} := 1;	# Set 'is_foo' flag
	
	if scope_for_storage_class($name) {
		%attributes<storage_class> := $name;
	}
	
	my $specifier := close::Compiler::Node::create_from_hash('type_specifier', %attributes);
	
	NOTE("done");
	DUMP($specifier);
	return $specifier;
}

sub is_pointer_type($type) {
	my $result := $type<is_pointer> || $type<is_array>;

	NOTE("Returning: ", $result);
	return $result;
}

our @Type_attributes := (
	'is_builtin',
	'is_typedef',
	'is_class',
	'is_struct',
	'is_union',
	'is_enum'
);

sub is_type($object) {
	NOTE("Checking if ", NODE_TYPE($object), " '", $object<display_name>, "' is a type");
	DUMP($object);
	ASSERT($object.isa(PAST::Var), 'Object must be a PAST::Var');
		
	my $result := 0;
	
	for @Type_attributes {
		NOTE("Checking type-attribute: ", $_, " (", $object{$_}, ")");
		$result := $result || $object<type>{$_};
	}
	
	NOTE("Returning: ", $result);
	return $result;
}

our $Merge_specifier_flags := (
	'is_builtin',
	'is_const',
	'is_inline', 
	'is_method',
	'is_typedef',
	'is_volatile',
	'noun', 
	'storage_class', 
);

sub merge_specifiers($merge_into, $merge_from) {
	ASSERT(NODE_TYPE($merge_from) eq 'type_specifier',
		'Merge_from argument must be a type specifier.');
	ASSERT(NODE_TYPE($merge_into) eq 'type_specifier',
		'Merge_into argument must be a type specifier.');
		
	for $Merge_specifier_flags {
		if $merge_from{$_} {
			if $merge_into{$_} {
				NOTE("Adding redundant-specifier warning.");
				ADD_WARNING($merge_into, 
					"Redundant storage class specifier '", 
					$merge_from.name(),
					"'");
			}
			else {
				NOTE("Setting ", $_, " to ", $merge_from{$_});
				$merge_into{$_} := $merge_from{$_};
			}
		}
	}

	my $new_sc := $merge_from<storage_class>;
	if $new_sc {
		my $old_sc := $merge_into<storage_class>;
		if $old_sc {
			if $old_sc eq $new_sc {
				NOTE("Adding redundant-storage class warning.");
				ADD_WARNING($merge_into, 
					"Redundant storage class specifier '",
					$merge_from.name(),
					"'");
			}
			elsif $old_sc eq 'extern' && $new_sc eq 'lexical' {
				NOTE("extern+lexical is okay");
				$merge_into<storage_class> := $merge_from<storage_class>;
			}
			elsif $old_sc eq 'lexical' && $new_sc eq 'extern' {
				NOTE("lexical+extern is okay, but don't overwrite lexical");
			}
			else {
				NOTE("Adding conflicting storage class error.");
				ADD_ERROR($merge_into,
					"Conflicting storage class specifiers '",
					$old_sc, "' and '", $new_sc, "'");
			}
		}
		else {
			$merge_into<storage_class> := $merge_from<storage_class>;
		}
	}
	
	if $merge_from<noun> {
		if $merge_into<noun> {
			NOTE("Adding conflicting type error.");
			ADD_ERROR($merge_into,
				"Only one type name is allowed ",
				"(consider removing '",
				$merge_from<noun>.name(),
				"')");
		}
	}
	
	DUMP($merge_into);
	return $merge_into;
}

sub new() {
	our $init;
	unless $init {
		$init := 1;
		# Fixme: Is base class a hash, or a node?
		Q:PIR {
			.local pmc meta
			meta = new 'P6metaclass'
			meta.'new_class'('close::Compiler::Types', 'parent' => 'parrot::Hash')
		};
	}
	
	my %type;
	%type<type> := Scalar::undef();
	%type<etype> := %type;
	return %type;
}

sub new_dclr_alias($alias) {
	DUMP(:alias($alias));
	return $alias;
}

sub pervasive_scope() {
	our $scope;
	
	unless Scalar::defined($scope) {
		NOTE("Creating pervasive scope block");
		
		$scope := PAST::Block.new(
			:blocktype('immediate'),
			:namespace(Scalar::undef()),
		);
		
		$scope<node_type> := 'pervasive scope';
		close::Compiler::Node::set_name($scope, 'pervasive types');

		NOTE("Parsing internal types");
		# Attach types to scope
		close::Compiler::Scopes::push($scope);
		close::Compiler::Scopes::dump_stack();
		
		close::Compiler::IncludeFile::parse_internal_file('internal/types');
		close::Compiler::Scopes::pop(NODE_TYPE($scope));
		
		NOTE("Adding types to block");
		for @($scope) {
			ASSERT($_.isa(PAST::VarList), 
				'There should be nothing in this block but the declarations we just built');
			my $varlist := $_;
			for @($varlist) {
				close::Compiler::Scopes::add_declarator_to($_, $scope);
			}
		}
		
	}
	
	return $scope;
}

=sub same_type($type1, $type2, :relaxed(1)?, :allow_multi(1)?)

Compares C<$type1> and C<$type2> to determine if they are the same (or compatible,
if C<:relaxed(1)> is specified). The comparison checks I<types> only, and does
not check storage class. 

If C<:relaxed(1)> is given, the first level of the types are checked for pointer
compatibility, rather than exact equality. So an array of X is considered the 
same as a pointer to X, and different array element counts are ignored. All 
other levels of the type chain must still match exactly, and non-pointer types
at the top level must match exactly.

If C<:allow_multi(1)> is given, the first level of the types are checked for 
functions with :multi adverbs. If found, the parameters and return type are 
ignored and the comparison is considered a match. So a function:multi
is always the same as another function:multi, but not the same as another
function not :multi, and not the same as a variable.

=cut

sub same_type($type1, $type2, *%options) {
	if %options<relaxed> && is_pointer_type($type1) && is_pointer_type($type2) {
		$type1 := $type1<type>;
		$type2 := $type2<type>;
	}
	
	if %options<allow_multi> 
		&& $type1<is_function> && $type1<adverbs><multi>
		&& $type2<is_function> && $type2<adverbs><multi> {
		return 1;
	}
	
	while $type1 && $type2 {
		if $type1 =:= $type2 {
			return 1;
		}
		
		if NODE_TYPE($type1) ne NODE_TYPE($type2) {
			return 0;
		}
		
		if $type1<is_declarator> {
			if $type1<declarator_type> ne $type2<declarator_type> {
				return 0;
			}
			
			if $type1<is_array> && $type1<elements> != $type2<elements> {
				return 0;
			}
			
			if $type1<is_function> {
				if $type1<is_method> != $type2<is_method> {
					return 0;
				}
				
				if $type1<adverbs><multi> != $type2<adverbs><multi> {
					return 0;
				}
				
				# FIXME: This does not allow for named params in different order
				my $index := 0;
				
				while $type1<parameters>[$index] {
					unless $type2<parameters>[index] {
						return 0;
					}
					
					unless same_type($type1<parameters>[index], 
						$type2<parameters>[index], :relaxed(1)) {
						return 0;
					}
					
					$index++;
				}
			}
			
			if $type1<is_hash> {
				# I got nothing, here.
			}
			
			if $type1<is_pointer> {
				if $type1<is_const> != $type2<is_const>
					|| $type1<is_volatile> != $type2<is_volatile> {
					return 0;
				}
			}
		}
		elsif $type1<is_specifier> {
			if $type1<noun>.name() ne  $type2<noun>.name() {
				return 0;
			}
			
			if $type1<is_const> != $type2<is_const>
				|| $type1<is_volatile> != $type2<is_volatile> {
				return 0;
			}
		}
		else {
			DUMP($type1, $type2);
			ASSERT(0, 'Not reached unless types are horribly misconfigured');
		}
		
		$type1 := $type1<next>;
		$type2 := $type2<next>;
	}
	
	return 1;
}

sub type_to_string($type) {
	my $str := '';
	
	unless $type {
		return '(NULL)';
	}
	
	while $type {
		my $append;
		
		if $type<is_declarator> {
			if $type<is_array> { 
				$append := '[]';
				if $type<num_elements> {
					$append := '[' ~ $type<num_elements> ~ ']';
				}
			}
			elsif $type<is_function> {
				$append := '()';
			}
			elsif $type<is_hash> {
				$append := '[%]';
			}
			elsif $type<is_pointer> {
				$append := '*';
			}
			else {
				$append := '<<unrecognized declarator: ' ~ $type.value() ~ '>>';
			}
		}
		else {
			$append := $type<name>
				~ "\tS:" ~ substr($type<storage_class>, 0, 3)
				~ "\tR:" ~ $type<register_class>;
			
			if $type<is_extern> {
				$append := $append ~ ' extern';
			}
		}
		
		$str := $str ~ $append;
		$type := $type<type>;
	}
	
	return ($str);
}

=sub update_redefined_symbol(:original($sym), :redefinition($sym))

Returns the severity of the redefinition: 'error', 'harmless', or 'same'.

=cut

sub update_redefined_symbol(*%args) {
	my $original	:= %args<original>;
	my $update	:= %args<redefinition>;
	ASSERT($original && $update, ':original() and :redefinition() parameters are required.');
	ASSERT(same_type($original, $update), 'PRECONDITION');
	
	my $severity := 'ignore';
	
	my $orig_spec := $original<etype>;
	ASSERT($orig_spec<is_specifier>, 'Symbol etype must link to type specifier');
	my $upd_spec := $update<etype>;
	ASSERT($upd_spec<is_specifier>, 'Symbol etype must link to type specifier');

	# Check initializers
	my $init := $update<initializer>;
	if $init {
		if $original<initializer> {
			# FIXME: In theory if these both say 'int x = 3;' 
			# it would be okay, but I can't test that yet.
			ADD_ERROR($update,
				'A symbol may only have one initializer.');
			$severity := 'error';
		}
		else {
			$original<initializer> := $init;
		}
	}
	
	# Check storage classes.	
	if $original<is_typedef> != $update<is_typedef> {
		ADD_ERROR($update,
			'A typedef may not have the same name as a variable.');
		$severity := 'error';
	}

	my $sc1 := $orig_spec<storage_class>;
	ASSERT($sc1, 'Storage class should always be set on original.');
	my $sc2 := $upd_spec<storage_class>;
	ASSERT($sc2, 'Storage class should always be set on update.');
	
	if $sc1 ne $sc2 {
		my $add_generic_error := 0;
		
		# Sort them, to simplify checks
		if $sc2 lt $sc1 {
			my $temp := $sc1;
			$sc1 := $sc2;
			$sc2 := $temp;
		}
		
		if $sc1 eq 'extern' || $sc2 eq 'extern' {
			if $sc2 eq 'lexical' {
				if $original<initializer> || $update<initializer> {
					ADD_ERROR($update,
						"Extern-lexical symbol '", $update.name(), 
						"' may not use an initializer.");
				}
				else {
					ADD_WARNING($update,
						"Extern-lexical declarations for '",
						$update.name(),
						"' should be merged.");
				}
			}
			elsif $sc2 eq 'static' {
				# Gotcha: In C, order matters and extern, then static is illegal.
				ADD_WARNING($update,
					"Symbol '", $update.name(), "' declared static and extern.");
				$severity := 'harmless';
			}
			else {
				$add_generic_error++;
			}
		}
		elsif $sc1 eq 'parameter' || $sc2 eq 'parameter' {
			if $sc2 eq 'register' {
				ADD_ERROR($update,
					"Redeclaration of parameter '",
					$update.name(),
					"' is prohibited. You may use the 'register' keyword on the parameter ",
					" declaration to mark it as register-based.");
			}
			else {
				ADD_ERROR($update,
					"Redeclaration of parameter '",
					$update.name(),
					"' is prohibited.");
			}
		}
		else {
			$add_generic_error++;
		}
		
		if $add_generic_error {
			ADD_ERROR($update,
				"Redeclaration of '", $update.name(),
				"' with storage class '", $upd_spec<storage_class>,
				"' conflicts with prior declaration ",
				" with storage class '", $orig_spec<storage_class>,
				"'");
		}
	}
	else {
		if $sc1 eq 'parameter' {
			# No redeclaration of parameters!
			ADD_ERROR($update,
				"Duplicate parameter(s) '", $update.name(), "'");
			$severity := 'error';
		}
	}
}
