# $Id$

=method declarator_name

Creates a PAST::Var node, and sets whatever attributes are provided. The 
resulting PAST::Var IS NOT RESOLVED.

=cut

method declarator_name($/) {
	my $past	:= close::Compiler::Node::create('declarator_name', :node($/));
	
	# This stuff is too common to duplicate:
	assemble_qualified_path($past, $/);
	NOTE("Created declarator for: ", $past.name());
	
	# NOTE: Because the parser may decide to use a different parse of 
	# this symbol (for example, a symbol declaration and a function
	# definition are ambiguous until the ';' or '{' B<after> the 
	# parameter list) you must use a temporary scope for declarations
	# and other stuff that will invoke this rule.
	close::Compiler::Scopes::add_declarator_to_current($past);
	# TODO: Maybe add a warning if it's already defined? "Repeated decl of name..."
	DUMP($past);
	make $past;
}

method namespace_name($/, $key) { PASSTHRU($/, $key); }

method namespace_path($/) {
	my $past	:= close::Compiler::Node::create('namespace_path', :node($/));
	
	# This stuff is too common to duplicate:
	assemble_qualified_path($past, $/);

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
	NOTE("Found qualified_identifier");
	my $past	:= close::Compiler::Node::create('qualified_identifier', :node($/));
	# This stuff is too common to duplicate:
	assemble_qualified_path($past, $/);
	#$past<searchpath> := clone_current_scope();
	
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

method type_name($/, $key) {
	my $past := $<qualified_identifier>.ast;
	
	if $key eq 'check_typename' {
		$Is_valid_type_name := close::Compiler::Types::is_typename($past);
		NOTE("Checked for typename '", $past.name(), "', valid = ", $Is_valid_type_name);
		return 0;
	}
	else {
		DUMP($past);
		make $past;
	}
}
