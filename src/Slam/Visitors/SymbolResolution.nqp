# $Id$

module Slam::Visitor::SymbolResolution {
# extends Visitor::Defined

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
	
		Parrot::IMPORT('Dumper');
		Parrot::IMPORT('Visitor::Combinator::Factory');
	
		NOTE("Creating Slam::Visitor::SymbolResolution");
		Class::SUBCLASS('Slam::Visitor::SymbolResolution', 
			'Visitor::Combinator::Defined',
			'Slam::Visitor');
		
		NOTE("done");
	}

	method description()			{ return 'Resolving symbols'; }
	
	method init(@children, %attributes) {
		my $impl := Slam::Visitor::SymbolResolution::Impl.new(Identity());
		
		self.definition(
			Slam::Visitor::ScopeTracker::TopDown.new($impl),
		);
	}
}

###########################################################################

module Slam::Visitor::SymbolResolution::Impl {
# extends Visitor::Combinator::Forward

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');

		my $class_name := 'Slam::Visitor::SymbolResolution::Impl';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Visitor::Combinator::Forward');
	
		Class::MULTISUB($class_name, 'visit', :starting_with('_visit_'));
		NOTE("done");
	}
	
	method _visit_Slam_Symbol_Reference($node) {
		NOTE("Looking up referent for: ", $node);
		my $ref := Registry<SYMTAB>.lookup($node);
		
		unless $node.referent && $ref =:= $node.referent {
			NOTE("Attaching referent-changed warning.");
			$node.warning(:message(
				"Symbol '", $node, "' resolves to a different target than initially expected."
			));

			$node.referent($ref);
		}
		
		self.PASS;
		return $node;
	}
}
