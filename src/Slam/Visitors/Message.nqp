# $Id$

module Slam::Visitor::Message {
# extends Visitor::Combinator::Defined

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		Parrot::IMPORT('Visitor::Combinator::Factory');

		my $class_name := 'Slam::Visitor::Message';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Visitor::Combinator::Defined',
			'Slam::Visitor');
		
		NOTE("done");
	}

	################################################################

	method description()			{ return 'Emitting messages'; }
	
	method init(@children, %attributes) {
		my $impl := Slam::Visitor::Message::Impl.new(Identity());
		
		self.definition(
			Slam::Visitor::ScopeTracker::TopDown.new($impl),
		);
	}
}

################################################################

module Slam::Visitor::Message::Impl {
# extends Visitor::Combinator::Forward

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Visitor::Message::Impl';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Visitor::Combinator::Forward');
		
		Class::multi_method($class_name, 'visit', :starting_with('_visit_'));
		NOTE("done");
	}


	method show_messages($node) {
		say($node.format());
		self.PASS;
		return $node;
	}

	method _visit_Slam_Error($node)		{ self.show_messages($node); }
	method _visit_Slam_Message($node)		{ self.show_messages($node); }
	method _visit_Slam_Warning($node)		{ self.show_messages($node); }

}
