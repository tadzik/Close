# $Id$

module Slam::Grammar::Actions;

our $Symbols;

#method TOP($/, $key) { PASSTHRU($/, $key); }
method TOP($/, $key) { 
	my $past := $/{$key}.ast;
		
	unless Slam::IncludeFile::in_include_file() {
		DUMP($past);

		NOTE("Pretty-printing input");
		my $prettified := Slam::PrettyPrintVisitor::print($past);
		NOTE("Pretty print done\n", $prettified);

		NOTE("Collecting declarations");
		Slam::DeclarationCollectionVisitor::collect_declarations($past);
		
		NOTE("Resolving types");
		Slam::TypeResolutionVisitor::resolve_types($past);
			
		NOTE("Resolving symbols");
		Slam::SymbolResolutionVisitor::resolve_symbols($past);

		NOTE("Setting scopes");
		Slam::ScopeAssignmentVisitor::assign_scopes($past);

		NOTE("Displaying messages");
		Slam::MessageVisitor::show_messages($past);

		$past := get_compilation_unit();
		
		NOTE("Rewriting tree for POSTing");
		$past := Slam::TreeRewriteVisitor::rewrite_tree($past);
			
		NOTE("Cleaning up tree for POSTing");
		Slam::PastCleanupVisitor::cleanup_past($past);

		DUMP($past);
	}	
	
	if Registry<CONFIG>.query('Compiler', 'faketree') {
		NOTE("Replacing compiled tree with faketree() results");
		$past := faketree();
	}
	
	make $past;
}

method declarative_statement($/, $key) { PASSTHRU($/, $key); }

=method include_file

Processes an included file. The compiled PAST subtree is used as the result of 
this expression.

=cut

method include_directive($/) {
	NOTE("Processing include file: ", ~ $<file>);
	my $past := parse_include_file($<file>.ast);
	MAKE($past);
}

method _namespace_definition_close($/) {
	my $past := $Symbols.leave_scope('Slam::Namespace');

	for ast_array($<declaration_sequence><decl>) {
		$_.attach_to($past);
	}
	
	MAKE($past);
}

method _namespace_definition_open($/) {
	$Symbols.enter_namespace_scope($<namespace_path>.ast);
}

# NQP currently generates get_hll_global for functions. So qualify them all.
our %_namespace_definition;
%_namespace_definition<close>		:= Slam::Grammar::Actions::_namespace_definition_close;
%_namespace_definition<open>		:= Slam::Grammar::Actions::_namespace_definition_open;

method namespace_definition($/, $key)	{ self.DISPATCH($/, $key, %_namespace_definition); }

method _translation_unit_close($/) {
	my $past := $Symbols.current_scope();
	
	NOTE("Adding declarations to translation unit context scope.");
	for ast_array($<declaration_sequence><decl>) {
		$_.attach_to($past);
	}
	
	unless Slam::IncludeFile::in_include_file() {
		NOTE("Popping namespace_definition block");
		$past := $Symbols.leave_scope('Slam::Namespace');
	}

	MAKE($past);
}

method _translation_unit_open($/) {
	NOTE("Running global setup");
	global_setup();
	
	unless Slam::IncludeFile::in_include_file() {
		NOTE("Not in an include file");
	}
}

# NQP currently generates get_hll_global for functions. So qualify them all.
our %_translation_unit;
%_translation_unit<close>		:= Slam::Grammar::Actions::_translation_unit_close;
%_translation_unit<open>		:= Slam::Grammar::Actions::_translation_unit_open;

method translation_unit($/, $key) { self.DISPATCH($/, $key, %_translation_unit); }

sub faketree() {
	my $sub := PAST::Block.new(:blocktype('declaration'), :name('compilation_unit'));
	$sub.push(
		PAST::Op.new(:pasttype('call'),
			PAST::Var.new(:name('say'), :scope('package')),
			PAST::Op.new(
				:lvalue(1),
				:name('prefix:++'),
				:pasttype('pirop'), 
				:pirop('inc 0*'), 
				PAST::Var.new(:scope('lexical'), :name('x')),
			),
		),
	);
		
	return $sub;
}
