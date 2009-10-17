# $Id: $

module Slam::Symbol::Declaration;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');

	my $class_name := 'Slam::Symbol::Declaration';
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name, 
		'Slam::Var', 'Slam::Symbol::Name');
	
	Class::MULTISUB($class_name, 'attach', :starting_with('_attach_'));
	
	NOTE("done");
}

method _attach_Slam_Scope_Function($definition) {
	self.definition($definition);
	$definition.hll(self.hll);
	$definition.namespace(self.namespace);
	$definition.name(self.name);
}

method _attach_Slam_Type($type) {
	NOTE("Attaching type info: ", $type, " to symbol: ", self);
	
	if self.last_type {
		self.last_type(self.last_type.attach($type));
	}
	else {
		self.last_type(self.type($type));
	}

	if $type.isa(Slam::Type::Specifier) {
		ASSERT( ! self.specifier, 
			'A symbol cannot have two specifiers');
		
		self.specifier($type);
		
		if $type.storage_class {
			self.storage_class($type.storage_class);
		}
		
		if $type.is_extern {
			self.is_extern(1);
		}
	}
	
	return $type;
}

method alias(*@value) {
	if +@value {
		self.name(@value[0].name);
	}
	
	return self._ATTR('alias', @value);
}

# Function def, CUES sub-symbol block
method definition(*@value)		{ self._ATTR('definition', @value); }

method init(*@children, *%attributes) {
	%attributes := @children.shift;
	
	if %attributes<parts> {
		my @part_values := Array::empty();
		
		for %attributes<parts> {
			@part_values.push($_.value());
		}
		
		ASSERT( ! %attributes<name>,
			'Cannot use :name() with :parts()');
		
		%attributes<name> := @part_values.pop;

		# If rooted, use exactly @parts as namespace. 
		# If not rooted, use @parts as partial namespace only
		# if it is not empty. (An empty ns would mean rooted symbol).
		if %attributes<is_rooted> || +@part_values {
			%attributes<namespace> := @part_values;
		}
	}
			
	return Slam::Node::init_(self, @children, %attributes);
}

method initializer(*@value)		{ self._ATTR('initializer', @value); }

method is_implicit(*@value)	{ self._ATTR('is_implicit', @value); }
method is_duplicate(*@value)	{ self._ATTR('is_duplicate', @value); }
method is_builtin(*@value)	{ self.specifier.is_builtin; }
method is_const(*@value)		{ self.type.is_const; }
method is_extern(*@value)		{ self._ATTR('is_extern', @value); }

method is_function() {
	unless self.type {
		DIE("Cannot call is_function() before type is set.");
	}
	
	return self.type.is_function;
}
		
method is_inline(*@value)		{ self.specifier.is_inline; }
method is_method(*@value)	{ self.specifier.is_method; }

method is_type() {
	return self.is_typedef;
}

method is_typedef()			{ self.storage_class eq 'typedef'; }
method is_volatile(*@value)	{ self.type.is_volatile; }
method isdecl(*@value)		{ return 1; }	
method last_type(*@value)		{ self._ATTR('last_type', @value); }

# args is moved to .type().args(), I guess
#level - scope backlink for some reasons

method name(*@value) {
	my $name;
	
	if +@value {
		$name := Slam::Node::name(self, @value.shift);
		self.pir_name();	# Force pickup if not set.
	}
	else {
		$name := Slam::Node::name(self);
	}
	
	return $name;
}
		
method scope() {
	unless our %scopes {
		NOTE("Initializing storage_class -> scope mapping");
		
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
	
	return %scopes{self.storage_class};
}

method specifier(*@value)		{ self._ATTR('specifier', @value); }
method storage_class(*@value)	{ self._ATTR('storage_class', @value); }
method type(*@value)		{ self._ATTR('type', @value); }





# Make a symbol reference from a declarator.
sub make_reference_to($node) {
	ASSERT($node.node_type eq 'declarator_name', 
		'You can only make a reference to a declarator');
		
	my $past := Slam::Node::create('qualified_identifier', 
		:declarator($node),
		:hll($node<hll>),
		:is_rooted($node<is_rooted>),
		:name($node<name>),
		:namespace($node<namespace>),
		:node($node),
		:scope($node.scope()),
	);

	return $past;
}

sub print_aggregate($agg) {
	say(substr($agg<kind> ~ "        ", 0, 8),
		substr($agg<tag> ~ "                  ", 0, 18));
	
	for $agg<symtable> {
		# FIXME: No more .symbols
		print_symbol($agg.symbol($_)<decl>);
	}
}

sub print_symbol($sym) {
	NOTE("Printing symbol: ", $sym.name());
	if $sym<is_alias> {
		say(substr($sym.name() ~ "                  ", 0, 18),
			" ",
			substr("is an alias for: " ~ "                  ", 0, 18),
			" ",
			substr($sym<alias_for><block> ~ '::' 
				~ $sym<alias_for>.name() ~ "                              ", 0, 30));
	}
	else {
		say(substr($sym.name() ~ "                  ", 0, 18),
			" ",
			substr($sym<pir_name> ~ "                  ", 0, 18),
			" ",
			$sym<block>, 
			" ",
			Slam::Type::type_to_string($sym<type>));
	}
}
