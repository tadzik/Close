# $Id$

module Slam::Visitor::TypeResolution;

Parrot::IMPORT('Dumper');

################################################################

_onload();

sub _onload() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	Slam::Visitor::_onload();
	
	NOTE("Creating Slam::Visitor::TypeResolution");
	Class::SUBCLASS('Slam::Visitor::TypeResolution', 'Slam::Visitor');
	
	NOTE("done");
}

################################################################

method description()			{ return 'Resolving types'; }

method init(@children, %attributes) {
	self.init_(@children, %attributes);
	
	self.method_dispatch(Hash::new(
		:SlamTypeSpecifier(	Slam::Visitor::TypeResolution::vm_TypeSpecifier),
		:SlamSymbolDeclaration(
					Slam::Visitor::TypeResolution::vm_SymbolDeclaration),
	));
	
	DUMP(self);
}

method vm_SymbolDeclaration($node) {
	# Have to call this explicitly - symbols don't traverse their type info  by default.
	$node.type.accept_visitor(self);
}

method vm_TypeSpecifier($node) {
	ASSERT($node.typename && $node.typename.referent,
		'Type Specifier typename should be defined, and initially resolved before now.');
		
	NOTE("Looking up specified type: ", $node.typename);
	my $type := Registry<SYMTAB>.lookup_type($node.typename);
	
	unless $type =:= $node.typename.referent {
		NOTE("Attaching type-resolution-changed warning");
		$node.warning(:message(
			"Type '", $node, "' resolves to a different target than initially expected."
		));
		
		$node.typename.referent($type);
	}
}
