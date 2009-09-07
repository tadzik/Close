# $Id$

=method declarator_name

Creates a PAST::Var node, and sets whatever attributes are provided. The 
resulting PAST::Var is not resolved.

=cut

method declarator_name($/) {
	my $past := assemble_qualified_path('declarator_name', $/);
	NOTE("Created declarator_name for ", $past<display_name>);
	
	# NOTE: Because the parser may decide to use a different parse of 
	# this symbol (for example, a symbol declaration and a function
	# definition are ambiguous until the ';' or '{' B<after> the 
	# parameter list) I use a temporary scope for declarations
	# and other stuff that will invoke this rule.
	close::Compiler::Scopes::add_declarator_to_current($past);
	# TODO: Maybe add a warning if it's already defined? "Repeated decl of name..."
	DUMP($past);
	make $past;
}

method label_name($/) {
	NOTE("Creating new label_name: ", ~ $<label>);
	my $past := close::Compiler::Node::create('label_name', 
		:name(~ $<label>), 
		:node($/));
	
	DUMP($past);
	make $past;
}

method namespace_name($/, $key) { PASSTHRU($/, $key); }

method namespace_path($/) {
	my $past := assemble_qualified_path('namespace_path', $/);
	NOTE("Created namespace_path for ", $past<display_name>);
	
	# Namespace might be empty for ::, or for single-element paths.
	unless $past.namespace() {
		$past.namespace(Array::empty());
	}
	
	# Name might be empty for hll-root only path.
	if $past.name() {
		$past.namespace().push($past.name());
	}

	DUMP($past);
	make $past;
}

method new_alias_name($/) {
	my $past := PAST::Var.new(:name($<alias>.ast.name()), :node($/));
	DUMP($past);
	make $past;
}

method qualified_identifier($/) {
	my $past := assemble_qualified_path('qualified_identifier', $/);
	NOTE("Created qualified_identifier for ", $past<display_name>);
	
	DUMP($past);
	make $past;
}

method simple_identifier($/) {
	my $past := PAST::Var.new(:name($<BAREWORD>.ast.value()), :node($/));
	NOTE("Found simple identifier: '", $past.name(), "'");
	DUMP($past);
	make $past;
}

our $Is_valid_type_name := 0;

method type_name($/) {
	my $past := $<qualified_identifier>.ast;
	NOTE("Checking for typename '", $past<display_name>, "'");
	
	$Is_valid_type_name := 0;
	my @matches := close::Compiler::Types::query_matching_types($past);
	
	if +@matches {
		NOTE("Found valid matching typename");
		$Is_valid_type_name := 1;
		$past<apparent_type> := @matches[0];
	}
	else {
		NOTE("No valid matching typename");
	}
		
	DUMP($past);
	make $past;
}
