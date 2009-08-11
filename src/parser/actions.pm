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

		NOTE("Pretty-printing input");
		my $prettified := close::Compiler::PrettyPrintVisitor::print($past);
		
		NOTE("Pretty print done\n", $prettified);
		
		# This should be a separate compiler phase. Later.
#		my $new_past := close::Compiler::SymbolLookupVisitor::update($past);
		
		DUMP($past);
		make $past;		
	}
}
