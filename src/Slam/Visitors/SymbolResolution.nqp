# $Id$

module Slam::Visitor::SymbolResolution;

Parrot::IMPORT('Dumper');

################################################################

_onload();

sub _onload() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	Slam::Visitor::_onload();
	
	NOTE("Creating Slam::Visitor::SymbolResolution");
	Class::SUBCLASS('Slam::Visitor::SymbolResolution', 'Slam::Visitor');
	
	NOTE("done");
}

################################################################

method description()			{ return 'Resolving symbols'; }

method init(@children, %attributes) {
	self.init_(@children, %attributes);
	
	self.method_dispatch(Hash::new(
		:SlamSymbolReference(
					Slam::Visitor::SymbolResolution::vm_SymbolReference),
	));
	
	DUMP(self);
}

method vm_SymbolDeclaration($node) {
	# Fixme: Need to resolve types, or no?
}

method vm_SymbolReference($node) {
	NOTE("Looking up referent for: ", $node);
	my $ref := Registry<SYMTAB>.lookup($node);
	
	unless $ref =:= $node.referent {
		NOTE("Attaching referent-changed warning.");
		$node.warning(:message(
			"Symbol '", $node, "' resolves to a different target than initially expected."
		));
		
		$node.referent($ref);
	}	
}
