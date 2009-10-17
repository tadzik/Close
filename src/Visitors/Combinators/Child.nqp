# $Id: $

=item Child

A Child combinator invokes a 'test' visitor on a node. If that test passes, 
then a second 'action' visitor is applied to the _children_ of the original node.

Child(test, action) := Sequence(test, All(action))

=cut

module Visitor::Combinator::Child;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
		
	Parrot::IMPORT('Dumper', 'ASSERT DIE DUMP DUMP_ NOTE');
	say("Ohai!");
	#Parrot::IMPORT('Visitor::Combinator');
	say("Cheezburger");
	
	my $class_name := 'Visitor::Combinator::Child';
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name, 
		'Visitor::Combinator::Defined');
	
	NOTE("done");
	say("really done");
}

method init(*@children, *%attributes) {
	ASSERT(@children == 2,
		'Two parameters - test and action - must be provided');
	my $test	:= @children.shift;
	my $action	:= @children.shift;
	ASSERT($test.isa(Visitor::Combinator),
		'$test parameter must be a Visitor::Combinator');
	ASSERT($action.isa(Visitor::Combinator),
		'$action parameter must be a Visitor::Combinator');

	self.definition(
		Sequence_($test, All_($action))
	);
}
