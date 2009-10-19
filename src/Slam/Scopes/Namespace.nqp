# $Id$

=module Slam::Scope::Namespace

This is a 'simple' namespace scope. It is used by the SymbolTable to hold the 
"real" namespace symbols. But this does not get used by the parser. See 
Slam::Scope::NamespaceDefinition for that class, which delegates much
work back to this one.

=cut

module Slam::Scope::Namespace {
#	extends Slam::Scope::Local

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;

		Parrot::IMPORT('Dumper');

		my $class_name := 'Slam::Scope::Namespace';
		NOTE("Declaring class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Slam::Scope::Local');
	}

	################################################################

	method add_child($name) {
		my $child := Slam::Scope::Namespace.new(
			:hll(self.hll),
			:name($name),
			:namespace(self.namespace.clone),
		);
		
		return self.child($name, $child);
	}
	
	method build_display_name() {
		self.rebuild_display_name(0);

		my $display_name := self.format_hll
			~ ' ' ~ self.format_namespace
			~ '::' ~ self.format_name;

		self.display_name($display_name);
		
		NOTE("Display name set to: ", self);
		return self.display_name;
	}

	method child($name, *@value) {
		if +@value {
			self.child_namespaces{$name} := @value.shift;
		}
		
		return self.child_namespaces{$name};
	}

	method child_namespaces(*@value)	{ self._ATTR_HASH('child_namespaces', @value); }
	method default_storage_class()		{ return 'extern'; }

	method fetch_child($name) {
		unless my $child := self.has_child($name) {
			$child := self.add_child($name);
		}
		
		return $child;
	}
	
	method fetch_namespace($name) {
		ASSERT($name.isa(Slam::Symbol::Name),
			'$name parameter must be a subclass of Slam::Symbol::Name');
		NOTE("Namespace '", self, "' looking up namespace: ", $name);
		
		my @path	:= $name.path;
		my $nsp	:= self;
		
		for @path {
			$nsp := $nsp.fetch_child(~ $_);
		}
		
		NOTE("done");
		DUMP($nsp);
		return $nsp;
	}

	method format_hll() {
		return 'hll:' ~ self.hll;
	}

	method format_name() {
		return self.name;
	}
	
	method format_namespace() {
		my $result := self.namespace.join('::');
		if $result {
			$result := '::' ~ $result;
		}
		
		return $result;
	}

	method has_child($name) {
		my $child := self.child($name);
		return $child;
	}
	
	method init(@children, %attributes) {
		unless %attributes<hll> && Scalar::defined(%attributes<namespace>) {
			DIE("Namespaces must be created with :hll() and :namespace()");
		}
		
		return self.init_(@children, %attributes);
	}

	method initload(*@value) {
		my $initload := self._ATTR('initload', @value);
		
		unless $initload {
			$initload := self.initload(
				Slam::Scope::Function.new(
					:name('_namespace_initload'),
				)
			);
		}
		
		return $initload;
	}
	
	method is_namespace()		{ return 1; }

	method query_namespace($name) {
		ASSERT($name.isa(Slam::Symbol::Name),
			'$name parameter must be a subclass of Slam::Symbol::Name');
		NOTE("Namespace ", self, " looking up child: ", $name);
		
		my @path	:= $name.path;
		my $nsp	:= self;
		
		for @path {
			if my $child := $nsp.has_child(~ $_) {
				$nsp := $child;
			}
			else {
				return $child;
			}
		}
		
		return $nsp;
				
	}
}

################################################################

=module Slam::Scope::GlobalRoot

This is a 'root' namespace scope. There should only be one instance of this 
class, at the top of the namespace tree. It behaves slightly differently from 
the Namespace and HllRoot scopes.

=cut

module Slam::Scope::GlobalRoot {
#	extends Slam::Scope::HllRoot

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;

		Parrot::IMPORT('Dumper');

		my $class_name := 'Slam::Scope::GlobalRoot';
		NOTE("Declaring class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Slam::Scope::HllRoot');
	}

	################################################################

	method add_child($name) {
		my $child := Slam::Scope::HllRoot.new(
			:name($name),
		);

		NOTE("Added child: ", $name);
		DUMP($child);
		return self.child($name, $child);
	}
	
	method build_display_name() {
		self.display_name(self.name);
		NOTE("Display name set to: ", self);
		return self.display_name;
	}

	method init(@children, %attributes) {
		self.init_(@children, %attributes);
		
		self._ATTR('hll',		Array::new(Scalar::undef()));
		self._ATTR('name',		Array::new('<GLOBAL ROOT>'));
		self._ATTR('namespace',	Array::new(Scalar::undef()));
		
		DUMP(self);
		return self;
	}
	
	method new(*@children, *%attributes) {
		if +@children {
			DIE("This class accepts no children.");
		}
		
		if our $Instance {
			return $Instance;
		}
		
		return Class::call_method_(self, 
			Class::BaseBehavior::new, 
			Array::empty(), 
			%attributes);
	}
}

################################################################

=module Slam::Scope::HllRoot

This is an 'hll root' namespace scope. It behaves pretty much like a common 
Namespace scope, but the rules for adding children and naming are changed a 
bit.

An HLL root namespace has an hll set - obviously - and has a namespace that 
is an empty array. That is, this is the namespace you are in when you code (in
PIR): 
    .HLL 'foo'
    .namespace []

The 'name' of this namespace is the hll name, so that the global root can
add a child named 'foo' and have the right thing happen. (The global root's
children are all hllroot namespace scopes.) 

=cut

module Slam::Scope::HllRoot {
#	extends Slam::Scope::Namespace


	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;

		Parrot::IMPORT('Dumper');

		my $class_name := 'Slam::Scope::HllRoot';
		NOTE("Declaring class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Slam::Scope::Namespace');
	}

	################################################################

	method build_display_name() {
		self.rebuild_display_name(0);
		self.display_name(self.format_hll);
		NOTE("Display name set to: ", self);
		return self.display_name;
	}

	method hll(*@value)			{ self._ATTR_CONST('hll', @value); }
	
	method init(@children, %attributes) {
		unless %attributes.contains('name') {
			DIE("You must provide a :name() for new HllRoot objects");
		}
		
		self._ATTR('name',		Array::new(%attributes<name>));
		%attributes.delete('name');
		self._ATTR('hll',		Array::new(self.name));
		self._ATTR('namespace',	Array::new(Array::empty()));
		
		self.init_(@children, %attributes);		
	}
		
	method name(*@value)		{ self._ATTR_CONST('name', @value); }
	method namespace(*@value)	{ self._ATTR_CONST('namespace', @value); }
}
