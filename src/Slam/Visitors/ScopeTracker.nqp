# $Id: $

module Slam::Visitor::ScopeTracker::Enter {
# extends Visitor::Combinator

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Visitor::ScopeTracker::Enter';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Visitor::Combinator');

		Class::multi_method($class_name, 'visit', :starting_with('_visit_'));
		NOTE("done");
	}

	###########################################################################

	method _visit_Slam_Node($node) {
		self.PASS;
		return $node;
	}
	
	method _visit_Slam_Scope($node) {
		Registry<SYMTAB>.enter_scope($node);
		self.PASS;
		return $node;
	}
}

module Slam::Visitor::ScopeTracker::Leave {
# extends Visitor::Combinator

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Visitor::ScopeTracker::Leave';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Visitor::Combinator');
		
		Class::multi_method($class_name, 'visit', :starting_with('_visit_'));
		NOTE("done");
	}

	###########################################################################

	method _visit_Slam_Node($node) {
		self.PASS;
		return $node;
	}
	
	method _visit_Slam_Scope($node) {
		Registry<SYMTAB>.leave_scope($node.node_type);
		self.PASS;
		return $node;
	}
}

###########################################################################

module Slam::Visitor::ScopeTracker::TopDown {
# extends Visitor::Combinator::Defined

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		Parrot::IMPORT('Visitor::Combinator::Factory');
		
		my $class_name := 'Slam::Visitor::ScopeTracker::TopDown';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Visitor::Combinator::Defined');
		
		NOTE("done");
	}

	###########################################################################

	method init(@children, %opts) {
		unless +@children {
			DIE("You must specify a child visitor");
		}
		
		my $v := @children.shift;
		
		self.definition(
			Sequence(
				Slam::Visitor::ScopeTracker::Enter.new(),
				$v,
				All(self),
				Slam::Visitor::ScopeTracker::Leave.new(),
			),
		);
	}
}
