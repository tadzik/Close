# $Id$

class close::Compiler::SymbolLookupVisitor;

sub ASSERT($condition, *@message) {
	close::Dumper::ASSERT(close::Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	close::Dumper::DIE(close::Dumper::info(), @msg);
}

sub DUMP(*@pos, *%what) {
	close::Dumper::DUMP(close::Dumper::info(), @pos, %what);
}

sub NOTE(*@parts) {
	close::Dumper::NOTE(close::Dumper::info(), @parts);
}

################################################################

our $Visitor_name := 'SymbolLookupVisitor';

sub update($past) {
	# Set up the scope stack
	my $pervasive := close::Compiler::Scopes::fetch_pervasive_scope();
	close::Compiler::Scopes::push($pervasive);
		
	my $visitor	:= close::Compiler::SymbolLookupVisitor.new();
	my $result	:= $visitor.visit($past);

	DUMP($result);
	return $result;
}

method visit($node) {
	# Don't visit twice.
	if $node<visited_by>{$Visitor_name} {
		NOTE("Already visited");
		DUMP($node);
		return $node;
	}
	
	$node<visited_by>{$Visitor_name} := 1;

	my $result;
	
	if	$node.isa(PAST::Block) {	$result := self.visit_block($node); }
	elsif	$node.isa(PAST::Op) {	$result := self.visit_op($node); }
	elsif	$node.isa(PAST::VarList) { $result := self.visit_varlist($node); }
	elsif	$node.isa(PAST::Var)
		&& $node.isdecl() {		$result := self.visit_vardecl($node); }
	elsif	$node.isa(PAST::Var) {	$result := self.visit_varref($node); }
	else {
		NOTE("Unrecognized node type. Passing through.");
		DUMP($node);
		
		self.visit_children($node);
		$result := $node;
	}
	
	DUMP($result);
	return $result;
}

method visit_block($node) {
	NOTE("Entering scope: ", $node.name());
	DUMP($node);
	close::Compiler::Scopes::push($node);
	
	self.visit_children($node);

	NOTE("Leaving scope: ", $node.name());
	close::Compiler::Scopes::pop($node<lstype>);
	return $node;
}

method visit_children($node) {
	my $count := +@($node);
	
	NOTE("Visit children: Node has ", $count, " children");
	while $count-- {
		my $kid := $node.shift();
		my $new_kid := self.visit($kid);
		$node.push($new_kid);
	}
	
	NOTE("Visit children: Finished, with ", +@($node), " children");
}

method visit_op($node) {
	NOTE("Visited PAST::Op: ", $node.name());
}

method visit_vardecl($node) {
	NOTE("Visited variable declaration: ", $node.name());
	
	# If scope has been set, there's nothing to do.
	if $node.scope() { return $node; }
	my $spec	:= close::Compiler::Types::get_specifier($node);
	unless $spec { DIE("No type specifier for var decl: " ~ $node.name()); }

	DUMP($spec);
	my $sc	:= $spec<storage_class>;
	
	if $sc {
		if	$sc eq 'extern' || $sc eq 'static'	{ $node.scope('package'); }
		elsif	$sc eq 'lexical'  || $sc eq 'dynamic' { $node.scope('lexical'); }
		elsif	$sc eq 'register' 			{ $node.scope('register'); }
		else { 
			DIE("Unrecognized storage class: ", $sc); 
		}
	}
	# Fixme: does not allow for alias.
	# If node is an immediate function, like extern int foo(), make it package
	elsif $node<type><is_function> {
		$node.scope('package');
	}
	else {
		#my $block := $node<scope>;
		my $block := close::Compiler::Scopes::current();
		DUMP($block);
		
		# Default linkage per block type.
		if $block<is_namespace>	{ $node.scope('package'); }
		elsif $block<is_class>	{ $node.scope('attribute'); }
		elsif $block<is_function>	{ $node.scope('register'); }
		else				{ DIE("Unrecognized containing block type: ", $block.name()); }
	}
	
	NOTE("Visiting children");
	self.visit_children($node);
	
	DUMP($node);
	return $node;
}

=method PAST::Node visit_varlist($node)

Visits a PAST::VarList node and fixes up the type name specifiers for 
non-builtin types. (Obviously, builtins don't need fixing up - we know
what they refer to.)

=cut

method visit_varlist($node) {
	NOTE("Visited variable declaration list: ", $node.name());
	my $spec := $node<specifier>;
	
	if $spec<is_builtin> {
		NOTE("Varlist is of builtin type: ", $spec<noun>, ". Nothing to fix up.");
	}
	else {
		if $spec<type_name> {
			$spec<type> := close::Compiler::Lookups::lookup_qualified_identifier($node, $spec<type_name>);
		}
	}
	
	self.visit_children($node);
	DUMP($node);
	return $node;
}

# FIXME: This is wrong. Should find decl, then take scope from decl.
method visit_varref($node) {
	NOTE("Visited variable reference: ", $node.name());
	my @results := close::Compiler::Lookups::lookup_qualified_identifier($node);
	if +@results {
		my $result := @results.shift();
		
		while $result<is_namespace> && +@results {
			$result := @results.shift();
		}
		
		if $result<is_namespace> {
			DIE("Only matching symbol is a namespace. WTF");
		}

		$node.scope($result.scope());
		DUMP($node);
	}
	else {
		close::Compiler::Messages::add_error($node, 
			'Reference to undeclared symbol');
	}
}
