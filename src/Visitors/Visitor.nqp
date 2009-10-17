# $Id: $

module Visitor;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');
	Class::NEW_CLASS('Visitor');
}

method visit($visitable) {
	ASSERT($visitable.isa(Visitor::Visitable),
		'$visitable parameter must be a Visitor::Visitable');

	DIE("Abstract method 'visit' must be overridden by child classes.");
}