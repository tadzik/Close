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

sub hash() {
	my $decl := new_declarator(:is_hash(1), :value('hash of'));
	DUMP(:decl($decl));
	return $decl;
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
	NOTE("Checking if ", NODE_TYPE($object), " is a type");
	DUMP($object);
	ASSERT($object.isa(PAST::Var), 'Object must be a PAST::Var');
		
	my $result := 0;
	
	for @Type_attributes {
		NOTE("Checking type-attribute: ", $_, " (", $object{$_}, ")");
		$result := $result || $object{$_};
	}
	
	NOTE("Returning: ", $result);
	return $result;
}


our $Merge_specifier_fields := (
	'is_builtin',
	'is_const',
	'is_inline', 
	'is_method',
	'is_typedef',
	'is_volatile',
	'noun', 
	'storage_class', 
);

sub merge_specifiers($error_sink, $merge_into, $merge_from) {
	ASSERT(close::Compiler::Node::type($merge_from) eq 'type_specifier',
		'Merge_from argument must be a type specifier.');
		
	unless $merge_into {
		return $merge_from;
	}
	
	ASSERT(close::Compiler::Node::type($merge_into) eq 'type_specifier',
		'Merge_into argument must be a type specifier, if given.');
		
	for $Merge_specifier_fields {
		if $merge_from{$_} {
			if $merge_into{$_} {
				NOTE("Merge specifier conflict: field ", $_, " already has a value");
				# conflict - already set.
			}
			else {
				NOTE("Setting ", $_, " to ", $merge_from{$_});
				$merge_into{$_} := $merge_from{$_};
			}
		}
	}
	
	DUMP($merge_into);
	return $merge_into;
}

sub new_dclr_alias($alias) {
	DUMP(:alias($alias));
	return $alias;
}

sub new_declarator(*%attrs) {
	my $decl := PAST::Val.new();
	
	$decl<is_declarator> := 1;
	
	for %attrs {
		$decl{$_} := %attrs{$_};
	}
	
	DUMP(:decl($decl));
	return $decl;
}

sub pervasive_scope() {
	our $pervasive_scope;
	
	unless Scalar::defined($pervasive_scope) {
		NOTE("Creating pervasive scope block");
		
		# This is bogus. Can I use namespace root instead?
		
		my $scope := PAST::Block.new(
			:blocktype('immediate'),
			:hll('close'),
			:namespace(Scalar::undef()),
		);
		$scope<node_type> := 'pervasive scope';
		close::Compiler::Node::set_name($scope, 'pervasive types');
		$pervasive_scope := $scope;
	}
	
	return $pervasive_scope;
}
	
sub pointer() {
	my $decl := new_declarator(:is_pointer(1), :value('pointer to'));
	DUMP(:decl($decl));
	return $decl;
}

sub same_type($type1, $type2) {
	while $type1 && $type2 {
		if $type1 =:= $type2 {
			return 1;
		}
		elsif $type1<is_declarator> && $type2<is_declarator> {
			if $type1<is_array> && $type2<is_array> {
				if $type1<num_elements> != $type2<num_elements> {
					return 0;
				}
			}
			elsif $type1<is_function> && $type2<is_function> {
				# FIXME: Compare args, somehow.
				my $param := 0;
				
				while $type1<parameters>[$param] {
					unless $type2<parameters>[$param] {
						return 0;
					}
					
					unless same_type($type1<parameters>[$param]<type>,
						$type2<parameters>[$param]<type>) {
						return 0;
					}
				}
			}
			elsif $type1<is_hash> && $type2<is_hash> {
				# I got nothin', here.
			}
			elsif $type1<is_pointer> && $type2<is_pointer> {
				if $type1<is_const> != $type2<is_const>
					|| $type1<is_volatile> != $type2<is_volatile> {
					return 0;
				}
			}
		}
		elsif $type1<is_specifier> && $type2<is_specifier> {
			if $type1<noun> ne $type2<noun> {
				return 0;
			}
			elsif $type1<is_const> != $type2<is_const>
				|| $type1<is_volatile> != $type2<is_volatile> {
				return 0;
			}
		}
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
