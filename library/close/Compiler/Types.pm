# $Id$

class close::Compiler::Types;

sub ASSERT($condition, *@message) {
	close::Dumper::ASSERT(close::Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	close::Dumper::DIE(close::Dumper::info(), @msg);
}

sub DUMP(*@pos, *%what) {
	close::Dumper::DUMP(close::Dumper::info(), @pos, %what);
}

sub NOTE(*@parts) {
	close::Dumper::NOTE(close::Dumper::info(), @parts);
}

################################################################

our %Builtin_register_types;
%Builtin_register_types<auto>	:= 'X';
%Builtin_register_types<float>	:= 'N';
%Builtin_register_types<int>	:= 'I';
%Builtin_register_types<pmc>	:= 'P';
%Builtin_register_types<string>	:= 'S';
%Builtin_register_types<void>	:= 'v';

sub add_builtins($block) {
	for %Builtin_register_types {
		my $type := new_specifier(
			:name('builtin type ' ~ $_), 
			:noun($_), 
			:register_class(%Builtin_register_types{$_}), 
			:value($_),
		);
		
		my $builtin := close::Compiler::Symbols::new(~$_, $type, $block);
	}

	DUMP(:block($block));
}

sub add_specifier_to_declarator($specifier, $declarator) {
	$declarator<etype><type> := $specifier;
	$declarator<etype> := $specifier;
	
	DUMP($declarator);
	return $declarator;
}

sub array_of($elements) {
	my $decl := new_declarator(:is_array(1), :value('array of'));
	
	if $elements {
		$decl<num_elements> := $elements;
		$decl.value('array of ' ~ $elements);
	}
	
	DUMP($decl);
	return $decl;
}

sub function_returning() {
	NOTE("Creating a function-returning declarator");
	
	my $block := close::Compiler::Scopes::new('function parameter');
	$block.name('function parameter');
	
	my $decl := new_declarator(
		:is_function(1), 
		:name('function parameter block'),
		:value('function returning'));
	$decl<parameter_scope> := $block;
	$block<function_decl> := $decl;
	
	DUMP($decl);
	return $decl;
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

my @Type_attributes := (
	'is_typedef',
	'is_class',
	'is_struct',
	'is_union',
	'is_enum'
);

sub is_type($object) {
	DUMP($object);
	ASSERT($object.isa(PAST::Var), 'Object must be a PAST::Var');
		
	for @Type_attributes {
		if $object{$_} {
			return 1;
		}
	}
	
	return 0;
}

=sub Boolean is_typename($past)

Checks the current lexical stack for a type definition matching C<$past>. If 
C<$past> is a rooted identifier, looks for a class with that name. Else looks for
any kind of typedef -- a class, a typedef record, etc.

Returns 1 if a matching type name is found, 0 otherwise.

=cut

sub is_typename($past) {
	NOTE("Checking if '", $past.name(), "' is a defined type");
	DUMP($past);
	
	my @results := lookup_type_name($past);
	
	DUMP(@results);
	
	if +@results {
		NOTE("Returning true");
		return 1;
	}
	
	NOTE("Returning false");
	return 0;
}

=sub lookup_type_name($past)

Searches for type names that match C<$past>. Handles un-rooted qualified paths 
by searching (but not creating) below the scopes in the current stack.

=cut

sub lookup_type_name($past) {
	NOTE("Looking up type name '", $past.name(), "'");
	DUMP($past);
	ASSERT($past.isa(PAST::Var), 'Parameter must be a PAST::Var.');
	
	my %namespaces;
	my @results		:= Array::empty();
	my $name		:= $past.name();

	# This loop does some redundant work if the identifier is rooted,
	# but the %namespaces flag prevents duplicate namespace entries.
	
	for close::Compiler::Scopes::get_search_list() {
		NOTE("Looking in '", $_<lstype>, "' namespace ", $_.name());
		my $nsp	:= close::Compiler::Namespaces::query_relative_namespace_of($_, $past);
				
		if $nsp {
			my $object	:= close::Compiler::Scopes::get_object($nsp, $name);
		
			if $object && is_type($object) {
				unless %namespaces{$nsp} {
					@results.push($object);
					%namespaces{$nsp} := 1;
				}
			}
		}
	}
	
	DUMP(@results);
	return @results;
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
	unless $merge_into {
		return ($merge_from);
	}
	
	for $Merge_specifier_fields {
		if $merge_from{$_} {
			if $merge_into{$_} {
				say("Merge specifier conflict: field ", $_, " already has a value");
				# conflict - already set.
			}
			else {
				say("Setting ", $_, " to ", $merge_from{$_});
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

sub new_specifier(*%attrs) {
	my $spec := PAST::Val.new();
	$spec<is_specifier> := 1;
	
	for %attrs {
		$spec{$_} := %attrs{$_};
	}
	
	DUMP(:spec($spec));
	return $spec;
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
