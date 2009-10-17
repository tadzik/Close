# $Id: $

module Slam::Symbol::Namespace;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');

	my $class_name := 'Slam::Symbol::Namespace';
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name,
		'Slam::Stmts', 'Slam::Symbol::Name');
	
	Class::MULTISUB($class_name, 'attach', :starting_with('_attach_'));
	NOTE("done");
}

# FIXME: alias is hard for namespaces. 
method alias(*@value) {
	DIE("This code hasn't been written yet.");
}

method _attach_Slam_Symbol_Declaration($item) {
	self.push($item);
	# Need to add symbol name to backing namespace.
	self.namespace_scope.add_symbol($item);
}

method _attach_Slam_Statement_SymbolDeclarationList($list) {
	for @($list) {
		if $_.is_builtin || $_.has_qualified_name {
			NOTE("Asking symbol table to handle declaration of ", $_);
			Registry<SYMTAB>.declare($_);
		}
		else {
			NOTE("Attaching ", $_, " locally.");
			self.attach($_);
		}
	}
}


method build_display_name() {
	self.rebuild_display_name(0);

	my @path := Array::clone(self.namespace);
	
	if my $hll := self.hll {
		@path.unshift('hll:' ~ $hll ~ ' ');
	}
	elsif self.is_rooted {
		@path.unshift('');
	}
		
	return self.display_name(Array::join('::', @path));
}	

method init(*@children, *%attributes) {
	if %attributes<parts> {
		my @part_values := Array::empty();
		
		for %attributes<parts> {
			@part_values.push($_.value());
		}
		
		ASSERT( ! %attributes<name>, 
			'Cannot use :name() with :parts()');
		#NB: Not setting 'name' at all, here.
		# A namespace is all about the <namespace> setting.
		%attributes<namespace> := @part_values;
	}

	return Slam::Node::init_(self, @children, %attributes);
}

method is_namespace()		{ return 1; }

method name(*@value) {
	DIE("Namespace has no name.");
}

method namespace_scope(*@value)	{ self._ATTR('namespace_scope', @value); }
