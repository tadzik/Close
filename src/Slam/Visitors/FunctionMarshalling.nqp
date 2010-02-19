# $Id: $

module Slam::Visitor::FunctionMarshalling {

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		Parrot::IMPORT('Visitor::Combinator::Factory');
		
		my $class_name := 'Slam::Visitor::FunctionMarshalling';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Visitor::Combinator::Defined',
			'Slam::Visitor');
		NOTE("done");
	}

	################################################################
	
	method description()		{ return 'Marshalling functions for code generation'; }
	method function_list(*@value)	{ self._ATTR('function_list', @value); }
	
	method init(@children, %attributes) {
		self.definition(
			TopDown(
				VisitOnce(
					Slam::Visitor::FunctionMarshalling::Impl.new(self)
				),
			),
		);
		
		self.function_list(Registry<FUNCLIST>);
	}
}

################################################################

module Slam::Visitor::FunctionMarshalling::Impl {

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Visitor::FunctionMarshalling::Impl';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Visitor::Combinator');
		NOTE("Creating multisub 'visit'");
		Class::multi_method($class_name, 'visit', :starting_with('_visit_'));
		NOTE("done");
	}

	################################################################

	method central(*@value)		{ self._ATTR('central', @value); }
	method init(@children, %attributes) {
		if +@children {
			self.central(@children.shift);
		}
	}
	
	method visit_default($node) {
		self.PASS;
		return $node;
	}

	method _visit_Slam_Scope_NamespaceDefinition($node) {
		our %Namespaces_seen;
		unless %Namespaces_seen{~ $node} {
			%Namespaces_seen{~ $node} := 1;
			my $init := $node.initload;
			NOTE("Adding namespace ", $node, " initload sub to function list.");
			DUMP($init);
			self.central.function_list.attach($init);
		}
		
		self.PASS;
		return $node;
	}
	
	method _visit_Slam_Type_Function($node) {
		if $node.definition {
			self.central.function_list.attach($node.definition);
		}
		
		self.PASS;
		return $node;
	}
}