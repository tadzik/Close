# $Id$

method TOP($/, $key) { PASSTHRU($/, $key); }

method translation_unit($/, $key) {
	if $key eq 'start' {
		NOTE("Starting translation unit parse.");
		
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
		NOTE("Done parsing translation unit.");
		
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

		NOTE("Rewriting tree for POSTing");
		$past := close::Compiler::TreeRewriteVisitor::rewrite_tree($past);
		
		NOTE("Cleaning up tree for POSTing");
		close::Compiler::PastCleanupVisitor::cleanup_past($past);
		
		DUMP($past);
		
		#$past := faketree();
		
		NOTE("done");
		DUMP($past);
		make $past;		
	}
}

sub faketree() {
	my $tree := PAST::Stmts.new(
		PAST::Block.new(
		#	:blocktype('declaration'),
			:hll('close'),
			:name('fake'),
			:namespace(Array::new('std')),
			PAST::VarList.new(
				PAST::Var.new(
					:isdecl(1),
					:name('args'),
					:scope('parameter'),
				),
			),
			PAST::Block.new(
				:name(undef),
				:namespace(undef),
				:hll(undef),
				:blocktype('immediate'),
			),
		),
	);
	
	DUMP($tree, 'Tree');
	return $tree;	
}
