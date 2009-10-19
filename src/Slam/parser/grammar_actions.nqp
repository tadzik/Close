# $Id$

module Slam::Grammar::Actions;

our $Symbols;

method TOP($/, $key) { 
	my $past := $/{$key}.ast;
		
	unless Slam::IncludeFile::in_include_file() {
		NOTE("Creating compilation unit");

		DUMP($past);
		
		for (	Slam::Visitor::PrettyPrint,
			Slam::Visitor::TypeResolution,
			Slam::Visitor::SymbolResolution,
			Slam::Visitor::Message,
		) {
			my $visitor := $_.new();
			NOTE("Considering ", Class::name_of($visitor));
			
			if $visitor.is_enabled {
				NOTE($visitor.description);
				$visitor.visit($past);
				$visitor.finish;
			}
			else {
				NOTE("Skipped: ", $visitor.description,
					" because it is not enabled.");
			}
		}

		DUMP($past);
		
		NOTE("Replacing tree with function list for POSTing");
		$past := Registry<FUNCLIST>;
		
		my $visitor := Slam::Visitor::PastRewrite.new();
		$visitor.visit($past);
		
		# Maybe chuck it all and replace it.
		$past := faketree($past);
		
		NOTE("Post-processing complete.");
		DUMP($past);
	}

	make $past;
}

method declarative_statement($/, $key) { PASSTHRU($/, $key); }

=sub faketree($past)

Replaces the generated tree with a fake one, if a config switch is set. Used 
to test arbitrary PAST structures, either because I'm bug-hunting or to 
understand how they work. Not a "real" part of the compiler in any way. 

=cut

sub faketree($past) {
	if Registry<CONFIG>.query('Compiler', 'faketree') {
		NOTE("Replacing compiled tree with faketree() results");
	
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
		
		$past := $sub;
	}
	
	return $past;
}

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
	my $past := $Symbols.current_scope();
	
	for ast_array($<declaration_sequence><decl>) {
		$past.attach($_);
	}
	
	$Symbols.leave_scope('Slam::Scope::NamespaceDefinition');
	
	MAKE($past);
}

method _namespace_definition_open($/) {
	$Symbols.enter_namespace_definition_scope($<namespace>.ast);
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
		NOTE("Attaching ", $_);
		$past.attach($_);
	}
	
	unless Slam::IncludeFile::in_include_file() {
		NOTE("Popping namespace_definition block");
		$past := $Symbols.leave_scope('Slam::Scope::NamespaceDefinition');
	}

	MAKE($past);
}

method _translation_unit_open($/) {
	global_setup();
}

# NQP currently generates get_hll_global for functions. So qualify them all.
our %_translation_unit;
%_translation_unit<close>		:= Slam::Grammar::Actions::_translation_unit_close;
%_translation_unit<open>		:= Slam::Grammar::Actions::_translation_unit_open;

method translation_unit($/, $key) { self.DISPATCH($/, $key, %_translation_unit); }
