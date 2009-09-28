# $Id$

module Slam::Type;

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
	Slam::Messages::add_error($node,
		Array::join('', @msg));
}

sub ADD_WARNING($node, *@msg) {
	Slam::Messages::add_warning($node,
		Array::join('', @msg));
}

sub NODE_TYPE($node) {
	return Slam::Node::type($node);
}

################################################################

=sub _onload

This code runs at initload, and explicitly creates this class as a subclass of
Node.

=cut

_onload();

sub _onload() {
	my $meta := Q:PIR {
		%r = new 'P6metaclass'
	};

	my $base := $meta.new_class('Slam::Type', 
		:parent('PCT::Node'),
	);
	$meta.new_class('Slam::Type::Specifier', :parent($base));
	$meta.new_class('Slam::Type::Declarator', :parent($base));
}

################################################################

method init(*@children, *%attributes) {
	NOTE("Creating specifier node");
	
	self<id>	:= Slam::Node::make_id(%attributes<node_type>);
	
	Slam::Node::set_attributes(self, %attributes);
	
	my %empty;
	%attributes := %empty;

	Q:PIR {
		.local pmc children, attributes
		children = find_lex '@children'
		attributes = find_lex '%attributes'
		$P0 = get_hll_global [ 'PCT' ; 'Node' ], 'init'
		self.$P0(children :flat, attributes :named :flat)
	};

	return self;
}

method is_pointer_type() {
	return 0;
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

sub new_dclr_alias($alias) {
	DUMP(:alias($alias));
	return $alias;
}

method nominal($next) {
	if $next {
		self<nominal> := $next;
	}
	
	return self<nominal>;
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
		Slam::Node::set_name($scope, 'pervasive types');

		NOTE("Parsing internal types");
		# Attach types to scope
		Slam::Scopes::push($scope);
		Slam::Scopes::dump_stack();
		
		Slam::IncludeFile::parse_internal_file('internal/types');
		Slam::Scopes::pop(NODE_TYPE($scope));
		
		NOTE("Adding types to block");
		for @($scope) {
			ASSERT($_.isa(PAST::VarList), 
				'There should be nothing in this block but the declarations we just built');
			my $varlist := $_;
			for @($varlist) {
				Slam::Scopes::add_declarator_to($_, $scope);
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

method storage_class($value?) {
	if $value {
		self<storage_class> := $value;
	}
	
	return self<storage_class>;
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

################################################################

module Slam::Type::Declarator {

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
		Slam::Messages::add_error($node,
			Array::join('', @msg));
	}

	sub ADD_WARNING($node, *@msg) {
		Slam::Messages::add_warning($node,
			Array::join('', @msg));
	}

	sub NODE_TYPE($node) {
		return Slam::Node::type($node);
	}

	################################################################

	method add_specifier($specifier) {
		self<etype><type> := $specifier;
		self<etype> := $specifier;		
		DUMP(self);
	}
	
	sub array_of($node?, *%attributes) {
		NOTE("Creating array_of declarator");
		
		my $declarator := _new(%attributes,
			:declarator_type('array_of'),
			:is_array(1),
			:node($node),
			:node_type('declarator'),
		);

		NOTE("done");
		DUMP($declarator);
		return $declarator;
	}

	method attach(@others) {
		my $last := self;
		
		for @others {
			$last := $last.nominal($_);
		}
		
		return $last;
	}
	
	sub function_returning($node?, *%attributes) {
		NOTE("Creating function_returning declarator");
		
		my $params := Slam::Node::create('decl_varlist',
			:name('parameter list'),
		);
	
		my $declarator := _new(%attributes,
			:declarator_type('function_returning'),
			:is_function(1),
			:node($node),
			:node_type('declarator'),
			:parameters($params),
		);

		NOTE("done");
		DUMP($declarator);
		return $declarator;
	}

	sub hash_of($node?, *%attributes) {
		NOTE("Creating hash_of declarator");
		
		my $declarator := _new(%attributes,
			:declarator_type('hash_of'),
			:is_hash(1),
			:node($node),
			:node_type('declarator'),
		);

		NOTE("done");
		DUMP($declarator);
		return $declarator;
	}

	method is_pointer_type() {
		return self<is_pointer> || self<is_array>;
	}
	
	sub _new(%attrs, *@children, *%attributes) {
		NOTE("Creating new Slam::Type::Declarator");
		if %attributes<children> {
			Array::append(@children, %attributes<children>);
			Hash::delete(%attributes, 'children');
		}
		
		Hash::merge(%attributes, %attrs);
		
		my $declarator := Q:PIR {
			.local pmc children, attributes
			children = find_lex '@children'
			attributes = find_lex '%attributes'
			$P0 = get_hll_global [ 'close' ; 'Compiler' ; 'Type' ], 'Declarator'
			%r = $P0.'new'(children :flat, attributes :named :flat)
		};
		
		DUMP($declarator);
		return $declarator;
	}
	
	sub pointer_to($node?, *%attributes) {
		NOTE("Creating pointer_to declarator");
		
		my @qualifiers := %attributes<qualifiers>;
		Hash::delete(%attributes, 'qualifiers');
		
		my $declarator := _new(%attributes,
			# The :children hack replaces :flat.
			:children(@qualifiers), 
			:declarator_type('pointer_to'),
			:is_pointer(1),
			:node($node),
			:node_type('declarator'),
		);
	
		NOTE("done");
		DUMP($declarator);
		return $declarator;
	}
}

################################################################

module Slam::Type::Specifier {

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
		Slam::Messages::add_error($node,
			Array::join('', @msg));
	}

	sub ADD_WARNING($node, *@msg) {
		Slam::Messages::add_warning($node,
			Array::join('', @msg));
	}

	sub NODE_TYPE($node) {
		return Slam::Node::type($node);
	}

	################################################################
	
	sub _new(%attrs, *@children, *%attributes) {
		NOTE("Creating new Slam::Type::Specifier");
		if %attributes<children> {
			Array::append(@children, %attributes<children>);
			Hash::delete(%attributes, 'children');
		}
		
		Hash::merge(%attributes, %attrs);
		
		my $declarator := Q:PIR {
			.local pmc children, attributes
			children = find_lex '@children'
			attributes = find_lex '%attributes'
			$P0 = get_hll_global [ 'close' ; 'Compiler' ; 'Type' ], 'Specifier'
			%r = $P0.'new'(children :flat, attributes :named :flat)
		};
		
		DUMP($declarator);
		return $declarator;
	}
	
	sub access_qualifier($node?, *%attributes) {
		ASSERT(%attributes<name>, 'access_qualifiers must have a name');
		my $name := %attributes<name>;
		NOTE("Creating '", $name, "' access_qualifier");
		
		%attributes{'is_' ~ $name} := 1;
		my $declarator := _new(%attributes,
			:specifier_type('access_qualifier'),
			:is_qualifier(1),
			:node($node),
			:node_type('type_specifier'),
		);

		NOTE("done");
		DUMP($declarator);
		return $declarator;
	}

	method attach(@others) {
		for @others {
			self.merge_with($_);
		}
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

	method merge_with($merge_from) {
		ASSERT(NODE_TYPE($merge_from) eq 'type_specifier',
			'Merge_from argument must be a type specifier.');
		
		for $Merge_specifier_flags {
			if $merge_from{$_} {
				if self{$_} {
					NOTE("Adding redundant-specifier warning.");
					ADD_WARNING(self, 
						"Redundant storage class specifier '", 
						$merge_from.name(),
						"'");
				}
				else {
					NOTE("Setting ", $_, " to ", $merge_from{$_});
					self{$_} := $merge_from{$_};
				}
			}
		}

		my $new_sc := $merge_from<storage_class>;
		if $new_sc {
			my $old_sc := self<storage_class>;
			if $old_sc {
				if $old_sc eq $new_sc {
					NOTE("Adding redundant-storage class warning.");
					ADD_WARNING(self, 
					"Redundant storage class specifier '",
					$merge_from.name(),
					"'");
				}
				elsif $old_sc eq 'extern' && $new_sc eq 'lexical' {
					NOTE("extern+lexical is okay");
					self<storage_class> := $merge_from<storage_class>;
				}
				elsif $old_sc eq 'lexical' && $new_sc eq 'extern' {
					NOTE("lexical+extern is okay, but don't overwrite lexical");
				}
				else {
					NOTE("Adding conflicting storage class error.");
					ADD_ERROR(self,
						"Conflicting storage class specifiers '",
						$old_sc, "' and '", $new_sc, "'");
				}
			}
			else {
				self<storage_class> := $merge_from<storage_class>;
			}
		}
	
		if $merge_from<noun> {
			if self<noun> {
				NOTE("Adding conflicting type error.");
				ADD_ERROR(self,
					"Only one type name is allowed ",
					"(consider removing '",
					$merge_from<noun>.name(),
					"')");
			}
		}
		
		DUMP(self);
	}

	sub storage_class($node?, *%attributes) {
		ASSERT(%attributes<name>, 'storage_class specifiers must have a name');
		my $name := %attributes<name>;
		NOTE("Creating storage_class specifier for '", $name, "'");
		
		%attributes{'is_' ~ $name} := 1;
		my $declarator := _new(%attributes,
			:specifier_type('storage_class'),
			:storage_class($name),
			:is_storage_class(1),
			:node($node),
			:node_type('type_specifier'),
		);

		NOTE("done");
		DUMP($declarator);
		return $declarator;
	}

	method scope() {
		ASSERT(self<storage_class>, 
			'.scope() only works on storage_class specifiers');
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
		
		return %scopes{self<storage_class>};
	}

	sub type_specifier($node?, *%attributes) {
		ASSERT(%attributes<noun>, 'type_specifiers must have a noun');
		my $noun := %attributes<noun>;
		NOTE("Creating type_specifier for '", $noun.name(), "'");

		my $declarator := _new(%attributes,
			:specifier_type('type_specifier'),
			:is_type_specifier(1),
			:node($node),
			:node_type('type_specifier'),
			:noun($noun),
		);

		NOTE("done");
		DUMP($declarator);
		return $declarator;
	}
}
