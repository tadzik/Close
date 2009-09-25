# $Id$

class close::Compiler::Types;

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

sub NODE_TYPE($node) {
	close::Compiler::Node::type($node);
}

################################################################

our $Builtins := "
# Declaration of builtin types
typedef _builtin	auto	:register_class('X');
typedef _builtin	float	:register_class('N');
typedef _builtin	int	:register_class('I');
typedef _builtin	pmc	:register_class('P');
typedef _builtin	string	:register_class('S');
typedef _builtin	void	:register_class('v');
";

sub add_builtin_type($type) {
	NOTE("Adding builtin type: ", $type<display_name>);
	
	my $scope := close::Compiler::Types::pervasive_scope();
	close::Compiler::Scopes::add_declarator_to($type, $scope);
}

sub add_builtins($scope) {
	NOTE("Adding builtin types");
	DUMP($Builtins);
	my $index := String::index($Builtins, "typedef", :offset(0));
	
	while $index != -1 {
		$index	:= $index + String::length("typedef _builtin\t");
		my $pos	:= $index;
		my $end	:= String::find_cclass('WHITESPACE', $Builtins, :offset($index));
		my $name	:= String::substr($Builtins, $index, $end - $index);
		
		$index	:= String::index($Builtins, ":register_class('", :offset($index))
					+ String::length(":register_class('");
		my $register_class := String::substr($Builtins, $index, 1);
		$index := String::index($Builtins, "typedef", :offset($index));
		
		NOTE("Adding builtin type: '", $name, "'");

		my $symbol	:= close::Compiler::Node::create('declarator_name',
			:is_typedef(1),
			:parts(Array::new($name)),
			:pos($pos),
			:scope('builtin'),
			:source($Builtins)
		);
		
		my $spec	:= close::Compiler::Node::create('type_specifier',
			:is_builtin(1),
			:name($name),
			:pir_name('specifier for builtin type: ' ~ $name), 
			:register_class($register_class),
			:noun($symbol),
		);
		
		add_specifier_to_declarator($spec, $symbol);
		add_builtin_type($symbol);
		
		DUMP($symbol);
	}
	
	NOTE("Dumping item info:");
	DUMP($scope);
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

our %Storage_class;
%Storage_class<dynamic>	:= 'lexical';
%Storage_class<extern>	:= 'package';
%Storage_class<lexical>	:= 'lexical';
%Storage_class<register>	:= 'register';
%Storage_class<static>	:= 'package';
%Storage_class<typedef>	:= 'typedef';

sub specifier(*%attributes) {
	my $name := %attributes<name>;
	ASSERT($name, 'Every specifier must have a name');
	NOTE("Creating type specifier for ", $name);
	
	my $flag := 'is_' ~ $name;
	
	if $name eq '_builtin' {
		$flag := 'is_builtin';
	}
	
	%attributes{$flag} := 1;	# Set 'is_foo' flag
	
	if %Storage_class{$name} {
		%attributes<storage_class> := $name;
		%attributes<scope> := %Storage_class{$name};
	}
	
	my $specifier := close::Compiler::Node::create_from_hash('type_specifier', %attributes);
	
	NOTE("done");
	DUMP($specifier);
	return $specifier;
}

our @Type_attributes := (
	'is_builtin',
	'is_typedef',
	'is_class',
	'is_struct',
	'is_union',
	'is_enum'
);

sub is_pointer_type($type) {
	my $result := $type<is_pointer> || $type<is_array>;

	NOTE("Returning: ", $result);
	return $result;
}

sub is_type($object) {
	NOTE("Checking if ", NODE_TYPE($object), " is a type");
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
				$merge_into<scope> := $merge_from<scope>;
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
			$merge_into<scope> := $merge_from<scope>;
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
		
		# Attach types to scope
		close::Compiler::Scopes::push($scope);
		close::Compiler::IncludeFile::parse_internal_file('internal/types');
		
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
