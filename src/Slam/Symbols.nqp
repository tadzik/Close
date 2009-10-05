# $Id$

module Slam::Symbol::Name {

	Parrot::IMPORT('Dumper');
		
	################################################################

=sub _onload

This code runs at initload, and explicitly creates classes with parents.

=cut

	_onload();

	sub _onload() {
		NOTE("Creating class Slam::Symbol::Name");
		my $base := Class::SUBCLASS('Slam::Symbol::Name', 'Slam::Node');

		NOTE("Creating class Slam::Symbol::Reference");
		Class::SUBCLASS('Slam::Symbol::Reference', 
			'Slam::Var', $base);
		
		NOTE("Creating class Slam::Symbol::Declaration");
		Class::SUBCLASS('Slam::Symbol::Declaration', 
			'Slam::Var', $base);
		
		NOTE("Creating class Slam::Symbol::Namespace");
		Class::SUBCLASS('Slam::Symbol::Namespace', 
			'Slam::Symbol::Declaration');
	}

	################################################################

	method build_display_name() {
		self.rebuild_display_name(0);

		my @path := Array::clone(self.namespace);
		@path.push(self.name);
		
		if my $hll := self.hll {
			@path.unshift('hll:' ~ $hll ~ ' ');
		}
		elsif self.is_rooted {
			@path.unshift('');
		}
			
		return self.display_name(Array::join('::', @path));
	}
	
	method has_qualified_name()	{ return self.hll || self.namespace; }
	
	method hll(*@value) {
		if+@value {
			self.rebuild_display_name(1);
		}
		
		return self.ATTR('hll', @value); 
	}
	
	method is_namespace()		{ return 0; }
	method is_rooted(*@value)		{ self.ATTR('is_rooted', @value); }
	method parts(*@value)		{ return 'parts'; }
	
=method path

Returns an array containing the hll and namespace elements, for use by the 
namespace functions.

=cut

	method path(*@value) {
		my @path := Array::clone(self.namespace);
		
		if self.hll {
			@path.unshift(self.hll);
		}
		
		return @path;
	}
	
	method pir_name(*@value) {
		return self.ATTR('pir_name', @value)
			|| self.name;
	}
}

################################################################

module Slam::Symbol::Declaration {

	Parrot::IMPORT('Dumper');
		
	################################################################

	method add_type_info($type) {
		ASSERT($type.isa(Slam::Type));
		NOTE("Adding type info: ", $type, " to symbol: ", self);
		
		if self.type {
			self.last_type(self.last_type.attach($type))
		}
		else {
			self.last_type(self.type($type));
		}
		
		if $type.is_specifier {
			$type.update_symbol(self);
		}
	}
	
	method alias(*@value) {
		if +@value {
			self.name(@value[0].name);
		}
		
		return self.ATTR('alias', @value);
	}
	
	method attach_to($parent) {
		ASSERT($parent.isa(Slam::Statement::SymbolDeclarationList),
			'If not a declaration list, then what?');
			
		$parent.push(self);
	}

	# Function def, CUES sub-symbol block
	method definition(*@value)		{ self.ATTR('definition', @value); }
	
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

	method initializer(*@value)		{ self.ATTR('initializer', @value); }

	method is_implicit(*@value)	{ self.ATTR('is_implicit', @value); }
	method is_duplicate(*@value)	{ self.ATTR('is_duplicate', @value); }
	method is_builtin(*@value)		{ self.ATTR('is_builtin', @value); }
	method is_const(*@value)		{ self.ATTR('is_const', @value); }
	method is_extern(*@value)		{ self.ATTR('is_extern', @value); }
	
	method is_function() {
		unless self.type {
			DIE("Cannot call is_function() before type is set.");
		}
		
		return self.type.is_function;
	}
			
	method is_inline(*@value)		{ self.ATTR('is_inline', @value); }
	
	method is_method(*@value) {
		unless self.type {
			DIE("Cannot call is_method() before type is set.");
		}

		my $value := @value.shift;
		return self.type.is_method($value);
	}

	method is_type() {
		return self.is_typedef;
	}
	
	method is_typedef()			{ self.storage_class eq 'typedef'; }
	method is_volatile(*@value)		{ self.ATTR('is_volatile', @value); }

	method isdecl(*@value)		{ return 1; }	
	method last_type(*@value)		{ self.ATTR('last_type', @value); }
	
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
	
	method storage_class(*@value)	{ self.ATTR('storage_class', @value); }
	method type(*@value)			{ self.ATTR('type', @value); }



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
}

module Slam::Symbol::Namespace {

	#Parrot::IMPORT('Dumper');
		
	################################################################
	
}

module Slam::Symbol::Reference {

	#Parrot::IMPORT('Dumper');
		
	################################################################
	
	method init(*@children, *%attributes) {
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

	method isdecl(*@value)		{ return 0; }

	method referent(*@value)		{ self.ATTR('referent', @value); }
}
