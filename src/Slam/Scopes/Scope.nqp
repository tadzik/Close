# $Id$

module Slam::Scope;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');

	NOTE("Declaring class Slam::Scope");
	my $class_name := 'Slam::Scope';
	Class::SUBCLASS($class_name, 
		'Slam::Block');
		
	Class::MULTISUB($class_name, 'attach', :starting_with('_attach_'));
}

method add_symbol($symbol) {
	ASSERT($symbol.isa(Slam::Symbol::Declaration), 
		'$symbol parameter must be a declaration');
	NOTE("Adding symbol ", $symbol, " to scope ", self);
	
	unless $symbol.storage_class {
		my $storage_class := self.default_storage_class;
		NOTE("Setting default storage class: ", $storage_class);
		$symbol.storage_class($storage_class);
	}
	
	self.symbol($symbol.name, :declaration($symbol));
}

method _attach_Slam_Node($node)		{ self.attach_UNEXPECTED($node); }

method _attach_Slam_Scope($scope) {
	ASSERT($scope.isa(Slam::Scope),
		'$scope must be some kind of Slam::Scope.');
	NOTE("Default attach for Slam::Scopes. Just push the nested Scope as a child.");
	self.push($scope);
}

method _attach_Slam_Scope_Parameter($node) { self.attach_ERROR($node); }
method _attach_Slam_Scope_Pervasive($node)	{ self.attach_ERROR($node); }

method _attach_Slam_Statement($node)	{ self.attach_UNEXPECTED($node); }
method _attach_Slam_Statement_Return($node) { self.attach_DEFAULT($node); }

method _attach_Slam_Statement_SymbolDeclarationList($decl_list) {
	ASSERT($decl_list.isa(Slam::Statement::SymbolDeclarationList),
		'$decl_list parameter must be a DeclarationList');
	
	for @($decl_list) {
		self.add_symbol($_);
		self.push($_);
	}
}

method attach_DEFAULT($node) {
	ASSERT($node.isa(Slam::Node),
		'$node must be some kind of Slam::Node, or things are horribly wrong.');
	NOTE("Default attach for Slam::Scope nodes. Just push the node as a child.");
	self.push($node);
}

method attach_ERROR($node) {
	NOTE("Invalid node type passed to attach. You can't attach that type of node here.");
	DUMP($node);
	DUMP(self);
	DIE("ERROR: Passed bogus node type to attach");
}

method attach_UNEXPECTED($node) {
	NOTE("Unexpected node type. Make sure there isn't special processing required, then explicitly address this type in Scopes/*.nqp");
	DUMP($node);
	DUMP(self);
	DIE("Unexpected node type passed to attach.");
}

method contains($reference, :&satisfies) {
	my $result := self.symbol($reference.name) 
		&& self.symbol($reference.name)<declaration>;
	
	unless &satisfies($result) {
		$result := Scalar::undef();
	}
	
	return $result;
}

method default_storage_class() {
	DIE("Subclass ", Class::name_of(self), " fails to implement this abstract method");
}

method lookup($reference, :&satisfies) {
	my $result := self.contains($reference, :satisfies(&satisfies));
	return $result;
}
