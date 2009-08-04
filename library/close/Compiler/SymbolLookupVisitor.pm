class close::Compiler::SymbolLookupVisitor;

our $Visitor_name := 'SymbolLookupVisitor';

method visit($node) {
	# Don't visit twice.
	if $node<visited_by>{$Visitor_name} {
		return $node;
	}
	
	$node<visited_by>{$Visitor_name} := 1;
	
	# Visit the children first.
	for @($node) {
		self.visit($_);
	}
	
	# Update the node and return it.
	self.dispatch_node($node);
}

method dispatch_node($node) {
	if $node.isa(PAST::VarList) {	return self.visit_varlist($node);	}
	elsif $node.isa(PAST::Var) 
		&& $node.isdecl() {		return self.visit_vardecl($node); }
	elsif $node.isa(PAST::Var) {	return self.visit_varref($node);	}
	elsif $node.isa(PAST::Op) {	return self.visit_op($node); }
}

=method PAST::Node visit_varlist($node)

Visits a PAST::VarList node and fixes up the type name specifiers.

=cut

method visit_varlist($node) {
	my $spec := $node<specifier>;
	
	if $spec<is_builtin> {
		return $node;
	}

	if $spec<type_name> {
		$spec<type> := lookup_qualified_identifier($node, $spec<type_name>);
		return $node;
	}
	
	# 
	my $typename := $spec<noun>;
}

sub get_type_specifier_of_node($node) {
	my $spec := $node<type>;
	
	unless $spec {
		die("Don't know how to find linkage of symbol: ", $node.name());
	}
		
	while ! $spec<is_specifier> {
		unless $spec<type> {
			die("Cannot locate specifier of symbol: ", $node.name());
		}
			
		$spec := $spec<type>;
	}

	close::Grammar::Actions::DUMP($spec, 'SymbolLookupVisitor::get_type_specifier_of_node');
	return $spec;
}

method visit_vardecl($node) {
	if $node.scope() {
		return $node;		# Nothing to do here.
	}
	
	my $spec	:= get_type_specifier_of_node($node);
	my $sc	:= $spec<storage_class>;
	
	if $sc {
		if	$sc eq 'extern' or $sc eq 'static' {
			$node.scope('package'); 
		}
		elsif	$sc eq 'lexical' or $sc eq 'dynamic' { 
			$node.scope('lexical'); 
		}
		elsif	$sc eq 'register' {
			$node.scope('register'); 
		}
		else { 
			die("Unrecognized storage class: ", $sc); 
		}
	}
	elsif $node<type><is_function> {
			$node.scope('package');
	}
	else {
		my $block := $node<block>;
		
		# Default linkage per block type.
		if $block<is_namespace> { $node.scope('package'); }
		elsif $block<is_class> { $node.scope('attribute'); }
		elsif $block<is_function> { $node.scope('register'); }
		else				{ die("Unrecognized containing block type: ", $block.name()); }
	}
	
	close::Grammar::Actions::DUMP($node, 'SymbolLookupVisitor::visit_vardecl');
	return $node;
}

# FIXME: This is wrong. Should find decl, then take scope from decl.
method visit_varref($node) {
	my @results := close::Grammar::Actions::lookup_qualified_identifier($node);
	if +@results {
		my $result := @results.shift();
		
		while $result<is_namespace> && +@results {
			$result := @results.shift();
		}
		
		if $result<is_namespace> {
			close::Grammar::Actions::die("Only matching symbol is a namespace. WTF");
		}

		$node.scope($result.scope());
		close::Grammar::Actions::DUMP($node, 'SymbolLookupVisitor::visit_varref');
	}
	else {
		close::Grammar::Actions::add_error($node, 
			'Reference to undeclared symbol');
	}
}

method visit_op($node) {
	say("Visited op: ", $node.name());
}