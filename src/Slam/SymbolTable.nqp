# $Id: $

module Slam::SymbolTable;

#Parrot::IMPORT('Dumper');
	
################################################################

=sub _onload

This code runs at initload time, creating subclasses.

=cut

_onload();

sub _onload() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');
	
	my $base_name := 'Slam::SymbolTable';
	
	NOTE("Creating base class ", $base_name);
	Class::SUBCLASS($base_name, 'Slam::Node');
}

################################################################

method current_scope() {
	return self.stack[0];
}

method current_namespace() {
	for self.stack {
		if $_.is_namespace {
			return $_;
		}
	}
	
	DIE('No current namespace on stack.');
}

method declare($symbol) {
	NOTE("Declaring symbol ", $symbol);
	DUMP($symbol);

	my $scope;
	
	if $symbol.is_builtin {
		NOTE("Adding builtin symbol '", $symbol, "' to pervasive scope");
		$scope := self.pervasive_scope;
		
		if $symbol.has_qualified_name {
			NOTE("Error: qualified name not allowed in pervasive scope");
			$symbol.error(:message(
				"A qualified name may not be a builtin."));
			$symbol.hll(Scalar::undef());
			$symbol.namespace(Scalar::undef());
		}
		else {
			NOTE("In scope: ", $scope);
			$scope.declare($symbol);
		}
		DUMP(self.pervasive_scope);
	}
	else {
		if $symbol.has_qualified_name {
			NOTE("Fetching namespace");
			$scope := self._fetch_namespace_of($symbol);
		}
		else {
			NOTE("Using current scope");
			$scope := self.current_scope;
		}
		
		NOTE("In scope: ", $scope);
		$scope.declare($symbol);
	}
}

method default_hll(*@value)		{ self.ATTR('default_hll', @value); }

method enter_block_scope(:$node) {
	NOTE("Creating new compound_statement block");
	my $block := Slam::Statement::Block.new(:node($node));
	self.enter_scope($block);
}

method enter_namespace_scope($ns_path) {
	NOTE("Entering scope of namespace ", $ns_path);
	my $ns_scope := self._fetch_namespace_of($ns_path);
	DUMP($ns_scope);
	self.enter_scope($ns_scope);
}

method enter_scope($scope) {
	ASSERT($scope.isa(Slam::Scope), '$scope param must be a Scope');
	NOTE("Entering scope ", $scope);
	DUMP($scope);
	
	self.stack.unshift($scope);
	return $scope;
}

method _fetch_namespace_of($name) {
	ASSERT($name.isa(Slam::Symbol::Name),
		'$name parameter must be a symbol name');
	NOTE("Fetching namespace of ", $name);
	my $result;
	
	if $name.is_rooted {
		NOTE("Fetching absolute namespace");
		$result := self.namespace_root.fetch_child($name);
	}
	else {
		NOTE("Fetching relative namespace");
		$result := self.current_namespace.fetch_child($name);
	}
	
	NOTE("done");
	DUMP($result);
	return $result;
}

method init(*@children, *%attributes) {
	NOTE("Doing basic INIT");
	Slam::Node::init_(self, @children, %attributes);

	NOTE("Initializing scope stack");
	self.stack(Array::empty());
	
	NOTE("Creating pervasive scope");
	self.pervasive_scope(Slam::Scope.new(:display_name('<PERVASIVE>')));
		
	NOTE("Installing namespace root");
	self.namespace_root(Slam::Namespace::root());
	
	return self;
}

method leave_scope($node_type) {
	my $old_scope := self.stack.shift();
	NOTE("Leaving scope ", $old_scope);
	DUMP($old_scope);
	ASSERT($old_scope.node_type eq $node_type,
		"Scope stack mismatch. Popped '", $old_scope.node_type,
		"' but wanted '", $node_type, "'"
	);

	return $old_scope;
}

method lookup($reference, :&satisfies?) {
	ASSERT($reference.isa(Slam::Symbol::Name),
		'Can only look up Symbol::Names');
	NOTE("Looking up ", $reference);
	DUMP($reference);

	unless &satisfies { &satisfies := Slam::SymbolTable::lookup_true; }

	my $result;

	if $reference.is_namespace {
		NOTE("I don't know if this is right. How do I differentiate between fetch/query?");
		$result := self._fetch_namespace_of($reference);
	}
	elsif $reference.is_rooted {
		NOTE("Looking up rooted name");
		if my $nsp := self.namespace_root.query_child($reference.path) {
			$result := $nsp.lookup($reference, :satisfies(&satisfies));
		}
	}
	elsif ! ($result := self.pervasive_scope.lookup($reference, :satisfies(&satisfies))) {
		NOTE("Not in pervasive scope");
		for self.stack {
			NOTE("Looking in ", $_);
			unless $result {
				$result := $_.lookup($reference, :satisfies(&satisfies));
			}
		}
	}
	
	NOTE("Returning: ", $result);
	DUMP($result);
	return $result;
}

sub lookup_is_type($node) {
	my $result := $node.is_type;
	NOTE("Testing is_type of ", $node, ", returning ", $result);
	return $result;
}

sub lookup_true($node) {
	return 1;
}

method lookup_type($reference) {
	my $result := self.lookup($reference, 
		:satisfies(Slam::SymbolTable::lookup_is_type),
	);
	
	return $result;
}

method namespace_root(*@value)		{ self.ATTR('namespace_root', @value); }
method pervasive_scope(*@value)		{ self.ATTR('pervasive_scope', @value); }
method print_stack() {
	NOTE("Scope stack:");
	my $index := 0;
	for self.stack {
		NOTE($index, ": ", $_);
	}
}
		
method query_type_name($name) {
	ASSERT($name.isa(Slam::Symbol::Name),
		'Query_type_name requires a Symbol::Name parameter');
	NOTE("Looking for a type: ", $name);
	
	my $symbol := self.lookup($name);
	NOTE("Result:", $symbol);
	DUMP($symbol);
	unless $symbol && $symbol.is_typedef {
		NOTE("Found something not a type.");
		$symbol := Scalar::undef();
	}
	
	return $symbol;
}

method stack(*@value)		{ self.ATTR('stack', @value); }
	
################################################################

sub current_file() {
	my $filename := Q:PIR {
		%r = find_dynamic_lex '$?FILES'
	};
	
	return $filename;
}
sub print_symbol_table($block) {
	NOTE("printing...");
	
	for $block<child_sym> {
		for get_symbols($block, $_) {
			Slam::Symbols::print_symbol($_) ;
		}
		
		DUMP($block);
	}
	
	NOTE("finished");
}
