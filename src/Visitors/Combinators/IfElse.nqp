# $Id: $

module Visitor::Combinator::IfElse;
_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
		
	Parrot::IMPORT('Dumper');

	my $class_name := 'Visitor::Combinator::IfElse';
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name, 
		'Visitor::Combinator::Composite');
	
	NOTE("done");
}


method visit($node) {
	ASSERT($node.isa(Visitor::Visitable),
		'$node parameter must be a Visitor::Visitable');
	ASSERT(self.components > 1,
		'A test and at least one branch must be provided before any nodes are visited.');

	NOTE("Visiting node: ", $node);
	my $result := self.use_result_of(self.components[0], $node);
	
	if self.success {
		NOTE("Test passed. Applying child visitor: ", self.components[1]);
		$result := self.use_result_of(self.components[1], $node);
	}
	elsif self.components > 2 {
		NOTE("Test failed. Applying child visitor: ", self.components[2]);
		$result := self.use_result_of(self.components[2], $node);
	}
	else {
		NOTE("Test failed. There is no 'else' branch to apply.");
	}

	NOTE("Success? ", self.success);
	return $result;
}
