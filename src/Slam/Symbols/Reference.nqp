#  $Id: $

module Slam::Symbol::Reference;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');

	NOTE("Creating class Slam::Symbol::Reference");
	Class::SUBCLASS('Slam::Symbol::Reference', 
		'Slam::Var', 'Slam::Symbol::Name');
	
	NOTE("done");
}

method accept($visitor) {
	return $visitor.visit_SlamSymbolReference(self);
}

method init(@children, %attributes) {
	if %attributes<parts> {
		my @part_values := Array::empty();
		
		for %attributes<parts> {
			@part_values.push($_.value());
		}
		
		ASSERT( ! %attributes<name>,
			'Cannot use :name() with :parts()');
		
		%attributes<name> := @part_values.pop;

		# If rooted, use exactly @parts as namespace. 
		# If not rooted, use @parts as partial namespace only
		# if it is not empty. (An empty ns would mean rooted symbol).
		if %attributes<is_rooted> || +@part_values {
			%attributes<namespace> := @part_values;
		}
	}

	return Slam::Node::init_(self, @children, %attributes);
}

method isdecl(*@value)		{ return 0; }

method referent(*@value)		{ self._ATTR('referent', @value); }
