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
		#$spec<type> := lookup_qualified_identifier($node, $spec<type_name>);
		return $node;
	}
	
	# 
	my $typename := $spec<noun>;
}

method visit_vardecl($node) {
	say("Visited vardecl");
}

method visit_varref($node) {
	my @results := close::Grammar::Actions::lookup_qualified_identifier($node);
	close::Grammar::Actions::DUMP(@results, 'SymbolLookupVisitor::visit_varref');
}

method visit_op($node) {
	say("Visited op: ", $node.name());
}