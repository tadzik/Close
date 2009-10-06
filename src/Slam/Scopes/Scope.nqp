# $Id$

module Slam::Scope;

#Parrot::IMPORT('Dumper');
	
################################################################

=sub _onload

This code runs at initload, and explicitly creates this class.

=cut

_onload();

sub _onload() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');

	NOTE("Declaring class Slam::Scope");
	my $base := Class::SUBCLASS('Slam::Scope', 
		'Slam::Block');
	
	Slam::Scope::Namespace::_onload();
	Slam::Scope::Pervasive::_onload();
}

################################################################

method add_symbol($symbol) {
	NOTE("Adding symbol ", $symbol, " to scope ", self);
	unless $symbol.storage_class {
		NOTE("Defaulting storage_class to: ", self.default_storage_class);
		$symbol.storage_class(self.default_storage_class);
	}
	
	self.symbol($symbol.name, :declaration($symbol));
}

method contains($reference, :&satisfies) {
	my $result := self.symbol($reference.name) 
		&& self.symbol($reference.name)<declaration>;
	
	unless &satisfies($result) {
		$result := Scalar::undef();
	}
	
	return $result;
}

method default_storage_class() {
	DIE("Subclass ", Class::name_of(self), " fails to implement this abstract method");
}

method lookup($reference, :&satisfies) {
	my $result := self.contains($reference, :satisfies(&satisfies));
	return $result;
}
