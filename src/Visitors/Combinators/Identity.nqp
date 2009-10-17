# $Id: $

module Visitor::Combinator::Identity;
# implements Visitor

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
		
	Parrot::IMPORT('Dumper');
	
	my $class_name := 'Visitor::Combinator::Identity';
	NOTE("Creating ", $class_name);
	Class::SUBCLASS($class_name, 
		'Visitor::Combinator');
	
	NOTE("done");
}

method visit($visitable) {
	NOTE("This one passed, too!");
	self.PASS;
	return $visitable;
}	
