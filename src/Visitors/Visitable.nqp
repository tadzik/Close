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
	ASSERT($visitor.isa('Visitor'),
		'$visitor parameter must be a Visitor');
		
	my $visit_method := 'visit_' ~ Class::name_of(self, :delimiter(''));
	return Class::call_method($visitor, $visit_method, self);
}
