# $Id$

module Slam::Visitor::PrettyPrint {

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		Parrot::IMPORT('Visitor::Combinator::Factory');
		
		my $class_name := 'Slam::Visitor::PrettyPrint';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Visitor::Combinator::Defined',
			'Slam::Visitor');
		NOTE("done");
	}

	################################################################
	
	method append(*@parts) {
		self.output.append(@parts);
	}

	method declarator(*@value)	{ self._ATTR('declarator', @value); }
	method declarators(*@value)	{ self._ATTR_ARRAY('declarators', @value); }
	method expression(*@value)	{ self._ATTR('expression', @value); }
	method expressions(*@value)	{ self._ATTR_ARRAY('expressions', @value); }
	
	method indent($value?) {
		unless Parrot::defined($value) { $value := 4; }
		self.indent_level(self.indent_level + $value); 
	}

	method description()		{ return 'Pretty-printing syntax tree'; }

	method finish() {
		NOTE(" ***** FINISHED ******");
		say(self.result);
	}

	method indent_level(*@value)	{ self._ATTR('indent_level', @value); }

	method init(@children, %attributes) {
		self.indent_level(0);
		
		# NB: Self provides a central store for indentation data
		# for begin/end
		self.definition(
			VisitOnce(
				Sequence(
					Slam::Visitor::PrettyPrint::BeginVisitor.new(self),
					All(self),
					Slam::Visitor::PrettyPrint::EndVisitor.new(self),
				),
			),
		);
	}

	method is_enabled() {
		return Registry<CONFIG>.query(Class::name_of(self), 'enabled');
	}
	
	method leader()			{ return String::repeat(' ', self.indent_level); }
	method output(*@value)		{ self._ATTR_ARRAY('output', @value); }
	method result()			{ return self.output.join; }
	method specifier(*@value)		{ self._ATTR('specifier', @value); }

	method stop_declarator() {
		my $result := self.declarator;
		self.declarator(self.declarators.pop);
		return $result;
	}

	method stop_expression() {
		my $result := self.expression;
		self.expression(self.expressions.pop);
		return $result;
	}
	
	method start_declarator($name) {
		self.declarators.push(self.declarator);
		self.declarator('' ~ $name);
	}
	
	method start_expression($name) {
		self.expressions.push(self.expression);
		self.expression('' ~ $name);
	}
	
	method undent($value?) { 
		unless Parrot::defined($value) { $value := 4; }
		self.indent_level(self.indent_level - $value); 
	}

}

################################################################

module Slam::Visitor::PrettyPrint::BeginVisitor {

	our $Symbols;
	
	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Visitor::PrettyPrint::BeginVisitor';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Visitor::Combinator');
		NOTE("Creating multisub 'visit'");
		Class::multi_method($class_name, 'visit', :starting_with('_visit_'));
		NOTE("done");
	}

	################################################################

	method central(*@value)		{ self._ATTR('central', @value); }
	method emit(*@args)		{ self.central.append(@args.join); }

	sub format_access_qualifiers($node) {
		my $quals := '';
		
		if $node.is_const { $quals := $quals ~ 'const '; }
		if $node.is_volatile { $quals := $quals ~ 'volatile '; }
		return $quals;
	}

	method indent()			{ self.central.indent(); }
	
	method init(@children, %attributes) {
		if +@children {
			self.central(@children.shift);
		}
		
		$Symbols := Registry<SYMTAB>;
	}
	
	method leader()			{ self.central.leader(); }
	
	method UNKNOWN($node) {
		self.emit("\n",
			self.leader,
			"/* Unknown node: ", $node, " */\n",
		);
		
		return $node;
	}
	
	################################################################

	method _visit_Slam_Literal($node) {
		NOTE("Visiting literal: ", $node);
		DUMP($node);
		my $expression := self.central.expression ~ $node.value;
		self.central.expression($expression);
		return $node;
	}
			
	method _visit_Slam_Scope_Function($node) {
		NOTE("Visiting function: ", $node);
		self.emit(self.leader, 'function scope: ', ~ $node, "\n");

		$Symbols.enter_scope($node);
		
		self.PASS;
		return $node;
	}

	method _visit_Slam_Scope_Local($node) {
		NOTE("Visiting Local: ", $node);
		self.emit(self.leader, "{\t// Local scope: ", ~$node, "\n");
		self.indent();

		$Symbols.enter_scope($node);
		
		self.PASS;
		return $node;
	}

	method _visit_Slam_Scope_Namespace($node) {
		DUMP($node);
		DIE("I did not expect to find a Namespace scope block in the tree.");
	}
	
	method _visit_Slam_Scope_NamespaceDefinition($node) {
		NOTE("Visiting namespace definition: ", $node);

		$Symbols.enter_scope($node);
		
		if our $outer_namespace_skipped {
			self.emit(self.leader, 'namespace ', ~ $node.delegate_to, 
				" {\t// ", $node.id, "\n");
			self.indent();
		}
		elsif $node.hll eq Registry<SYMTAB>.default_hll
				&& +$node.namespace == 0 {
			$node<outer_skipped> := 1;
			$outer_namespace_skipped := 1;
		}
		else {
			# If this is wrong, a *lot* of assumptions are probably wrong, too.
			DIE("Surprise! Outer namespace != default");
		}

		self.PASS;
		return $node;
	}

	method _visit_Slam_Scope_Parameter($node) {
		NOTE("Visiting parameter scope: ", $node);
		self.emit("(");

		$Symbols.enter_scope($node);
		
		self.PASS;
		return $node;
	}

	method _visit_Slam_Statement($node) {
		NOTE("Visiting statement: ", $node);
		return self.UNKNOWN($node);
	}
	
	method _visit_Slam_Statement_Return($node) {
		self.central.start_expression('');
		self.PASS;
		return $node;
	}

	method _visit_Slam_Symbol_Declaration($node) {
		NOTE("Declaring symbol.");
		self.central.start_declarator($node.name);
		self.central.start_expression('');
		self.central.specifier('');
		return $node;
	}

	method _visit_Slam_Symbol_Reference($node) {
		NOTE("Visiting symbol reference: ", $node);
		self.central.expression(self.central.expression ~ $node);
		return $node;
	}
	
	method _visit_Slam_Type_Array($node) {
		my $elements := $node.elements;
		
		unless Parrot::defined($elements) {
			$elements := ' ';
		}
		
		my $declarator := self.central.declarator ~ '[' ~ $elements ~ ']';
		self.central.declarator($declarator);
		return $node;
	}

	method _visit_Slam_Type_Function($node) {
		my $declarator := self.central.declarator ~ '(';
		$declarator := $declarator ~ ' /* need args, later. */ ';
		$declarator := $declarator ~ ')';
		self.central.declarator($declarator);
		return $node;
	}

	method _visit_Slam_Type_Hash($node) {
		my $declarator := self.central.declarator ~ '[ % ]';
		self.central.declarator($declarator);
		return $node;
	}

	method _visit_Slam_Type_MultiSub($node) {
		DIE("I have no idea what to do here.");
	}

	method _visit_Slam_Type_Pointer($node) {
		my $pointer		:= '*';
		
		if $node.has_access_qualifier {
			$pointer := '* ' ~ format_access_qualifiers($node);
		}
		
		my $declarator := $pointer ~ self.central.declarator;
		
		if $node.nominal.is_declarator && !node.nominal.is_pointer {
			$declarator := '(' ~ $declarator ~ ')';
		}
		
		self.central.declarator($declarator);
		return $node;
	}
	
	method _visit_Slam_Type_Specifier($node) {
		NOTE("Visiting type specifier: ", $node);
		my $specifier := format_access_qualifiers($node)
			~ $node.typename;
		$specifier := $specifier ~ String::repeat(' ', 8 - (String::length($specifier) % 8));
		self.central.specifier($specifier);
		return $node;
	}
}

################################################################

module Slam::Visitor::PrettyPrint::EndVisitor {

	our $Symbols;
	
	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Visitor::PrettyPrint::EndVisitor';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Visitor::Combinator');
		NOTE("Creating multisub 'visit'");
		Class::multi_method($class_name, 'visit', :starting_with('_visit_'));
		NOTE("done");
	}

	################################################################

	method central(*@value)		{ self._ATTR('central', @value); }
	method emit(*@args)		{ self.central.append(@args.join); }

	method init(@children, %attributes) {
		if +@children {
			self.central(@children.shift);
		}
		
		$Symbols := Registry<SYMTAB>;
	}
	
	method leader()			{ self.central.leader(); }
	method undent()			{ self.central.undent(); }
	
	################################################################

	method _visit_Slam_Node($node) {
		NOTE("Default: nothing to do for ", 
			Class::name_of($node), " node: ", $node);
		
		self.PASS;
		return $node;
	}
	
	method _visit_Slam_Scope($node) {
		NOTE("Visiting scope: ", $node);
		
		$Symbols.leave_scope($node.node_type);
		
		unless $node<outer_skipped> {
			self.undent();
			self.emit(self.leader, "}\t// ", $node.id, "\n");
		}

		self.PASS;
		return $node;
	}

	method _visit_Slam_Scope_Function($node) {
		NOTE("Closing out function scope: ", $node);
		
		$Symbols.leave_scope($node.node_type);
		
		self.PASS;
		return $node;
	}
	
	method _visit_Slam_Scope_Parameter($node) {
		NOTE("Visiting scope: ", $node);
		self.emit(")");

		$Symbols.leave_scope($node.node_type);
		
		self.PASS;
		return $node;
	}
	
	method _visit_Slam_Statement_Return($node) {
		self.PASS;
		self.emit(self.leader, 'return');
		
		if my $result := self.central.stop_expression {
			self.emit(' ', $result);
		}
		
		self.emit(";\n");
			
		return $node;
	}

	method _visit_Slam_Symbol_Declaration($node) {
		NOTE("Done with symbol declaration of ", $node);
		
		self.emit(self.leader);
		if Registry<SYMTAB>.current_scope.default_storage_class ne $node.storage_class {
			self.emit($node.storage_class, ' ');
		}
		
		my $declarator := self.central.stop_declarator;
		self.emit(self.central.specifier, $declarator);
		NOTE("Spec: '", self.central.specifier, "', Decl: '", $declarator, "'");
		
		if $node.initializer {
			NOTE("Emitting initializer: ", self.central.expression);
			self.emit(' = ', self.central.expression);
		}
		
		unless $node.type.definition {
			self.emit(';');
		}
		
		self.emit("\n");
		self.PASS;
		return $node;
	}	
}
