# $Id: $

module Visitor::Combinator::Fail;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
		
	Parrot::IMPORT('Dumper');
	
	my $class_name := 'Visitor::Combinator::Fail';
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name, 
		'Visitor::Combinator');
	
	NOTE("done");
}

method visit($visitable) {
	NOTE("This one failed, too!");
	self.FAIL;
	return $visitable;
}
