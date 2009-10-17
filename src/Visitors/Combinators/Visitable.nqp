# $Id: $

module Visitor::Visitable;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');
	Class::NEW_CLASS('Visitor::Visitable');
}

method accept($visitor) {
	ASSERT($visitor.isa(Visitor),
		'$visitor parameter must be a Visitor');
	
	
	# For each subclass in the hierarchy, the accept method
	# should dispatch the visitor.visit_<classname> method.
	DIE("Not implemented");
	# NB: Return is important for modifying visitors.
	return $visitor.visit_visitable(self);
}

method count_children() {
	DIE("Not implemented");
	# NB: Return an array containing all the child nodes.
	return Array::empty();
}

method get_child_at($index) {
	DIE("Abstract method.");
}

method isa($type) {
	return self.HOW.isa(self, $type);
}

method set_child_at($index, $child) {
	DIE("Abstract method.");
}

}
	
