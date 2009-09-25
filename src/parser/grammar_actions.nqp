# $Id$

class close::Grammar::Actions;

#method TOP($/, $key) { PASSTHRU($/, $key); }
method TOP($/, $key) { 
	my $past := $/{$key}.ast;
		
	unless in_include_file() {
		DUMP($past);

		if get_config('Compiler', 'PrettyPrint') {
			NOTE("Pretty-printing input");
			my $prettified := close::Compiler::PrettyPrintVisitor::print($past);
			NOTE("Pretty print done\n", $prettified);
		}

		NOTE("Collecting declarations");
		close::Compiler::DeclarationCollectionVisitor::collect_declarations($past);
		
		NOTE("Resolving types");
		close::Compiler::TypeResolutionVisitor::resolve_types($past);
			
		NOTE("Resolving symbols");
		close::Compiler::SymbolResolutionVisitor::resolve_symbols($past);

		NOTE("Setting scopes");
		close::Compiler::ScopeAssignmentVisitor::assign_scopes($past);

		NOTE("Displaying messages");
		close::Compiler::MessageVisitor::show_messages($past);

		$past := get_compilation_unit();
		
		NOTE("Rewriting tree for POSTing");
		$past := close::Compiler::TreeRewriteVisitor::rewrite_tree($past);
			
		NOTE("Cleaning up tree for POSTing");
		close::Compiler::PastCleanupVisitor::cleanup_past($past);

		DUMP($past);
	}	
	
	if get_config('Compiler', 'faketree') {
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
	
	NOTE("done");
	DUMP($past);
	make $past;
}

method namespace_definition($/, $key) {
	if $key eq 'open' {
		my $past := close::Compiler::Namespaces::fetch_namespace_of($<namespace_path>.ast);
		close::Compiler::Scopes::push($past);
		NOTE("Pushed ", NODE_TYPE($past), " block for ", $past<display_name>);
	}
	elsif $key eq 'close' {
		my $past := close::Compiler::Scopes::pop('namespace_definition');
		NOTE("Popped namespace_definition block: ", $past<display_name>);

		for $<declaration_sequence><decl> {
			$past.push($_.ast);
		}
		
		NOTE("done");
		DUMP($past);
		make $past;
	}
	else {
		$/.panic("Unexpected value '", $key, "' for $key parameter");
	}
}

method translation_unit($/, $key) {
	if $key eq 'open' {
		# If we're in an include file, there's nothing to do. 
		
		# Otherwise ...
		unless in_include_file() {
			close::Compiler::Config::read('close.cfg');
			
			# Calling this forces the init code to run. I'm not sure that matters.
			my $root_nsp := close::Compiler::Namespaces::fetch(Array::new('close'));
			close::Compiler::Scopes::push($root_nsp);
			DUMP($root_nsp);
		}
	}
	elsif $key eq 'close' {
		my $past;
		
		if in_include_file() {
			# NB: Don't pop, because this might be a #include
			NOTE("Not popping - this is a #include");
			$past := close::Compiler::Scopes::current();
		}
		else {
			NOTE("Popping namespace_definition block");
			$past := close::Compiler::Scopes::pop('namespace_definition');
		}
		
		NOTE("Adding declarations to translation unit context scope.");
		for $<declaration_sequence><decl> {
			$past.push($_.ast);
		}
		
		NOTE("done");
		DUMP($past);
		make $past;		
	}
	else {
		$/.panic("Unexpected value '", $key, "' for $key parameter");
	}
}

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
