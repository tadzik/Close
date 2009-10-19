# $Id$
module Slam::Grammar::Actions;

=method declarator_name

Creates a PAST::Var node, and sets whatever attributes are provided. The 
resulting PAST::Var is not resolved.

=cut

method declarator_name($/) {
	NOTE("Creating declarator_name for ", $<path>[-1].ast.value);
	my $past := Slam::Symbol::Declaration.new(
		:hll($<hll_name> && ~ $<hll_name>[0]),
		:is_rooted($<root>),
		:node($/),
		:parts(ast_array($<path>)),
	);

	MAKE($past);
}

method label_name($/) {
	NOTE("Creating new label_name: ", ~ $<label>);
	my $past := Slam::Compiler::Node::create('label_name', 
		:name(~ $<label>), 
		:node($/));
	MAKE($past);
}

method namespace_name($/, $key) { PASSTHRU($/, $key); }

method namespace_path($/) {
	NOTE("Creating namespace path");
	my $past := Slam::Symbol::Namespace.new(
		:hll($<hll_name> && ~ $<hll_name>[0]),
		:is_rooted($<root>),
		:node($/),
		:parts(ast_array($<path>)),
	);
	
	MAKE($past);
}

method new_alias_name($/) {
	my $past := PAST::Var.new(:name($<alias>.ast.name()), :node($/));
	DUMP($past);
	make $past;
}

method qualified_identifier($/) {
	my $past := Slam::Symbol::Reference.new(
		:hll($<hll_name> && ~ $<hll_name>[0]),
		:is_rooted(+$<root>),
		:node($/),
		:parts(ast_array($<path>)),
	);
	MAKE($past);
}

method simple_identifier($/) {
	my $past := PAST::Var.new(:name($<BAREWORD>.ast.value()), :node($/));
	NOTE("Found simple identifier: '", $past.name(), "'");
	DUMP($past);
	make $past;
}

method type_name($/, $key) {
	our $Symbols;
	our $Is_valid_type;		# Global accessed by grammar rule.
	my $past := $/{$key}.ast;
	$Is_valid_type := $Symbols.lookup_type($past);
	$past.referent($Is_valid_type);
	MAKE($past);	
}
