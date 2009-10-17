# $Id: PastRewrite.nqp 180 2009-10-06 02:38:02Z austin_hastings@yahoo.com $

module Slam::Visitor::PastRewrite {
# extends Visitor::Combinator::Defined

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		Parrot::IMPORT('Visitor::Combinator::Factory');

		my $class_name := 'Slam::Visitor::PastRewrite';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Visitor::Combinator::Defined',
			'Slam::Visitor');
		
		NOTE("done");
	}

	################################################################

	method description()			{ return 'Rewriting tree for PAST compiler'; }

	method init(@children, %attributes) {
		my $impl := Slam::Visitor::PastRewrite::Impl.new(Identity());
		
		self.definition(
			Slam::Visitor::ScopeTracker::TopDown.new($impl),
		);
	}
}

################################################################

module Slam::Visitor::PastRewrite::Impl {
# extends Visitor::Combinator::Forward

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Visitor::PastRewrite::Impl';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Visitor::Combinator::Forward');
		
		Class::MULTISUB($class_name, 'visit', :starting_with('_visit_'));
		NOTE("done");
	}
}
