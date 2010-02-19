# $Id$

module Slam::Visitor::TypeResolution {
# extends Visitor::Combinator

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		Parrot::IMPORT('Visitor::Combinator::Factory');
		
		my $class_name := 'Slam::Visitor::TypeResolution';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Visitor::Combinator::Defined',
			'Slam::Visitor');
		
		NOTE("done");
	}

	method description()				{ return 'Resolving types'; }
	
	method init(@children, %attributes) {
		my $impl := Slam::Visitor::TypeResolution::Impl.new(Identity());
		
		self.definition(
			Slam::Visitor::ScopeTracker::TopDown.new($impl),
		);
	}
}

###########################################################################

module Slam::Visitor::TypeResolution::Impl {
# extends Visitor::Combinator::Forward

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Visitor::TypeResolution::Impl';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Visitor::Combinator::Forward');
		
		Class::multi_method($class_name, 'visit', :starting_with('_visit_'));
		NOTE("done");
	}

	method _visit_Slam_Type_Specifier($visitable) {
		ASSERT($visitable.typename && $visitable.typename.referent,
			'Type Specifier typename should be defined, and initially resolved before now.');
			
		NOTE("Looking up specified type: ", $visitable.typename);
		my $type := Registry<SYMTAB>.lookup_type($visitable.typename);
		
		unless $type =:= $visitable.typename.referent {
			NOTE("Attaching type-resolution-changed warning");
			$visitable.warning(:message(
				"Type '", $visitable, "' resolves to a different target than initially expected."
			));
			
			$visitable.typename.referent($type);
		}
		
		self.PASS;
		return $visitable;
	}
}
