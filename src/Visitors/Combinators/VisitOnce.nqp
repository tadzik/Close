# $Id: $

module Visitor::Combinator::VisitOnce;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
		
	Parrot::IMPORT('Dumper');

	my $class_name := 'Visitor::Combinator::VisitOnce';
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name,
		'Visitor::Combinator::Defined');
	
	NOTE("done");
}

method visit_cache(*@value)	{ self._ATTR_HASH('visit_cache', @value); }

method visit($node) {
	NOTE("Visitor ", ~self, " is visiting ", Class::name_of($node), 
		" node: ", $node);
	
	self.PASS;
	my $result := self.visit_cache{Parrot::get_address_of($node)};
	
	if Scalar::defined($result) {
		NOTE("Already visited. Skipping.");
	}
	else {
		NOTE("Visiting for the first time.");
		$result := self.use_result_of(self.definition, $node);
		self.visit_cache{Parrot::get_address_of($node)} := $result;
	}

	NOTE("Success? ", self.success);
	return $result;
}
