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

our @system_include_paths := Array::new(
	'include',
);

our %Include_search_paths;
%Include_search_paths<system> := @system_include_paths;
%Include_search_paths<user> := Array::new('.');

method include_file($/) {
	NOTE("Processing include file: ", ~ $<file>);
	my $file := $<file>.ast;
	my $search_path := %Include_search_paths<user>;
	
	if $file<type> eq 'system' {
		$search_path := %Include_search_paths<system>;
	}

	my $path := File::find_first($file<path>, $search_path);
	NOTE("Found path: ", $path);
	my $past := $file;
	
	if $path {
		push_include_file();
		
		my $content := File::slurp($path);
		$file<contents> := $content;
		DUMP($file);

		close::Compiler::Scopes::push($past);
		
		# Don't capture this to $past - the translation_unit rule
		# knows to store included nodes into the current $past.
		Q:PIR {
			.local pmc parser
			parser = compreg 'close'
			
			.local string source
			$P0 = find_lex '$content'
			source = $P0
			%r = parser.'compile'(source, 'target' => 'past')
		};
		
		close::Compiler::Scopes::pop('include_file');
		pop_include_file();
	}
	else {
		NOTE("Bogus include file - not found");
		ADD_ERROR($past, "Include file ",
			$file.name(), " not found.");
	}
	
	NOTE("done");
	DUMP($past);
	make $past;
}

=method include_system

Process a 'system' include file. Currently there is no difference between system
and user include files, other than default search path.

=cut

method include_system($/) {
	NOTE("Parsed system include file");
	
	my $past := close::Compiler::Node::create('include_file',
		:name(~ $/),
		:node($/),
		:quote('<>'),
		:include_type('system'),
		:path($<string_literal>.ast),
	);
	
	DUMP($past);
	make $past;
}

=method include_user

Process a 'user' include file. Currently there is no difference between system
and user include files, other than default search path.

=cut

method include_user($/) {
	NOTE("Parsed user include file");
	my $qlit := $<QUOTED_LIT>.ast;
	
	my $past := close::Compiler::Node::create('include_file',
		:name(~ $/),
		:node($/),
		:quote($qlit<quote>),
		:include_type('user'),
		:path($qlit.value()),
	);
	
	DUMP($past);
	make $past;
}

method namespace_definition($/, $key) {
	if $key eq 'open' {
		my $past := close::Compiler::Namespaces::fetch_namespace_of($<namespace_path>.ast);
		NOTE("Pushed ", NODE_TYPE($past), " block for ", $past<display_name>);
		close::Compiler::Scopes::push($past);
	}
	elsif $key eq 'close' {
		NOTE("Popping namespace_definition block");
		my $past := close::Compiler::Scopes::pop('namespace_definition');

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
		my $config := close::Compiler::Config.new();
		$config.read('close.cfg');
		NOTE("Read config file");
		
		# Calling this forces the init code to run. I'm not sure that matters.
		my $context := close::Compiler::Scopes::current();
		DUMP($context);
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
	$sub.lexical(0);
	$sub :=PAST::Stmts.new();
	$sub<id> := "compilation_unit";
	
	my $sub2 := PAST::Block.new(:blocktype('declaration'), :name('foo'));
	$sub2.lexical(0);
	$sub.push($sub2);
	
	$sub2 := PAST::Block.new(:blocktype('declaration'), :name('bar'));
	$sub2.lexical(0);
	$sub.push($sub2);

	return $sub;
}
