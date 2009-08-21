# $Id$

method TOP($/, $key) { PASSTHRU($/, $key); }

method translation_unit($/, $key) {
	if $key eq 'start' {
		my $config := close::Compiler::Config.new();
		$config.read('close.cfg');
		
		NOTE("Begin translation unit!");
		
		my $pervasive := close::Compiler::Node::create('translation_unit');
		close::Compiler::Scopes::push($pervasive);

		my @root_nsp_path := Array::new('close');
		my $root_nsp := close::Compiler::Namespaces::fetch(@root_nsp_path);
		close::Compiler::Scopes::push($root_nsp);
		
		close::Compiler::Scopes::print_symbol_table($pervasive);
	}
	else {
		my $default_nsp := close::Compiler::Scopes::pop('namespace_block');

		for $<extern_statement> {
			$default_nsp.push($_.ast);
		}
		
		my $past := close::Compiler::Scopes::pop('translation_unit');
		$past.push($default_nsp);
		
		close::Compiler::Scopes::dump_stack();

		if get_config('Compiler', 'PrettyPrint') {
			NOTE("Pretty-printing input");
				
			my $prettified := close::Compiler::PrettyPrintVisitor::print($past);
			
			NOTE("Pretty print done\n", $prettified);
		}

		NOTE("Resolving types");
		close::Compiler::TypeResolutionVisitor::resolve_types($past);
		
		NOTE("Resolving symbols");
		close::Compiler::SymbolResolutionVisitor::resolve_symbols($past);

		NOTE("Setting scopes");
		close::Compiler::ScopeAssignmentVisitor::assign_scopes($past);

		NOTE("Displaying messages");
		close::Compiler::MessageVisitor::show_messages($past);

		NOTE("done");
		DUMP($past);
		make $past;		
	}
}
