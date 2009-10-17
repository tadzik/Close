# $Id$

module Slam::Visitor::PrettyPrint {

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Visitor::PrettyPrint';
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name, 
			'Visitor::Combinator::Defined',
			'Slam::Visitor');
		NOTE("done");
	}

	################################################################
	
	method append(*@parts) {
		Array::append(self.output, @parts);
	}

	method declarator(*@value)	{ self._ATTR('declarator', @value); }
	method expression(*@value)	{ self._ATTR('expression', @value); }
	
	method indent($value?) {
		unless Scalar::defined($value) { $value := 4; }
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
			Visitor::Combinator::VisitOnce.new(
				Visitor::Combinator::Sequence.new(
					Slam::Visitor::PrettyPrint::BeginVisitor.new(self),
					Visitor::Combinator::All.new(self),
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
	method result()			{ return Array::join('', self.output); }
	method specifier(*@value)		{ self._ATTR('specifier', @value); }

	method undent($value?) { 
		unless Scalar::defined($value) { $value := 4; }
		self.indent_level(self.indent_level - $value); 
	}

}

################################################################

module Slam::Visitor::PrettyPrint::BeginVisitor {

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
		Class::MULTISUB($class_name, 'visit', :starting_with('_visit_'));
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
		my $expression := self.central.expression ~ $node.value;
		self.central.expression($expression);
		return $node;
	}
			
	method _visit_Slam_Scope_Function($node) {
		NOTE("Visiting function: ", $node);
		self.emit(self.leader, 'function scope: ', ~ $node, "\n");

		self.PASS;
		return $node;
	}

	method _visit_Slam_Scope_Local($node) {
		NOTE("Visiting Local: ", $node);
		self.emit(self.leader, "{\t// Local scope: ", ~$node, "\n");
		self.indent();

		self.PASS;
		return $node;
	}

	method _visit_Slam_Scope_Namespace($node) {
		NOTE("Visiting namespace: ", $node);
		self.emit(self.leader, 'namespace ', ~ $node, " {\n");
		self.indent();

		self.PASS;
		return $node;
	}

	method _visit_Slam_Scope_Parameter($node) {
		NOTE("Visiting parameter scope: ", $node);
		self.emit("(");

		self.PASS;
		return $node;
	}

	method _visit_Slam_Statement($node) {
		NOTE("Visiting statement: ", $node);
		return self.UNKNOWN($node);
	}
	
	method _visit_Slam_Statement_Return($node) {
		self.central.expression('');
		self.PASS;
		return $node;
	}

	method _visit_Slam_Symbol_Declaration($node) {
		NOTE("Declaring symbol.");
		self.central.declarator($node.name);
		self.central.expression('');
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
		
		unless Scalar::defined($elements) {
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
		Class::MULTISUB($class_name, 'visit', :starting_with('_visit_'));
		NOTE("done");
	}

	################################################################

	method central(*@value)		{ self._ATTR('central', @value); }
	method emit(*@args)		{ self.central.append(@args.join); }

	method init(@children, %attributes) {
		if +@children {
			self.central(@children.shift);
		}
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
		self.undent();
		self.emit(self.leader, "}\n");

		self.PASS;
		return $node;
	}

	method _visit_Slam_Scope_Function($node) {
		NOTE("Closing out function scope: ", $node);
		
		self.PASS;
		return $node;
	}
	
	method _visit_Slam_Scope_Parameter($node) {
		NOTE("Visiting scope: ", $node);
		self.emit(")");

		self.PASS;
		return $node;
	}
	
	method _visit_Slam_Statement_Return($node) {
		self.PASS;
		self.emit(self.leader, 'return');
		
		if self.central.expression {
			self.emit(' ', self.central.expression);
		}
		
		self.emit(";\n");
			
		return $node;
	}

	method _visit_Slam_Symbol_Declaration($node) {
		NOTE("Done with symbol declaration of ", $node);
		
		self.emit(self.leader);
		self.emit($node.storage_class, ' ');
		self.emit(self.central.specifier, self.central.declarator);
		NOTE("Spec: '", self.central.specifier, "', Decl: '", self.central.declarator, "'");
		
		if $node.initializer {
			NOTE("Emitting initializer: ", self.central.expression);
			self.emit(' = ', self.central.expression);
		}
		
		unless $node.definition {
			self.emit(';');
		}
		
		self.emit("\n");
		self.PASS;
		return $node;
	}
	
}
