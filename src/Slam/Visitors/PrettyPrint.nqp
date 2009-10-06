# $Id$

module Slam::Visitor::PrettyPrint;

Parrot::IMPORT('Dumper');

################################################################

_onload();

sub _onload() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	Slam::Visitor::_onload();
	
	NOTE("Creating Slam::Visitor::PrettyPrint");
	Class::SUBCLASS('Slam::Visitor::PrettyPrint', 'Slam::Visitor');
	
	NOTE("done");
}

################################################################

method append(*@parts) {
	self.output.push(Array::join('', @parts));
}

method declarator(*@value)	{ self.ATTR('declarator', @value); }

method description()		{ return 'Pretty-printing syntax tree'; }

method enabled() {
	return Registry<CONFIG>.query(Class::name_of(self), 'enabled');
}
	
method finish() {
	NOTE(" ***** FINISHED ******");
	say(self.result);
}

sub format_access_qualifiers($node) {
	my $quals := '';
	
	if $node.is_const { $quals := $quals ~ 'const '; }
	if $node.is_volatile { $quals := $quals ~ 'volatile '; }
	return $quals;
}

method indent($value?) {
	unless Scalar::defined($value) { $value := 4; }
	self.indent_level(self.indent_level + $value); 
}

method indent_level(*@value)	{ self.ATTR('indent_level', @value); }

method init(@children, %attributes) {
	self.init_(@children, %attributes);
	
	self.indent_level(0);
	
	self.method_dispatch(Hash::new(
		:DEFAULT(		Slam::Visitor::PrettyPrint::vm_DEFAULT),
		:SlamLiteralInteger(	Slam::Visitor::PrettyPrint::vm_Literal),
		:SlamScopeNamespace(	
					Slam::Visitor::PrettyPrint::vm_Namespace),
		:SlamStatementSymbolDeclarationList(
					Slam::Visitor::PrettyPrint::vm_DeclarationList),
		:SlamSymbolDeclaration(
					Slam::Visitor::PrettyPrint::vm_SymbolDeclaration),
		:SlamTypeArray(	Slam::Visitor::PrettyPrint::vm_ArrayDeclarator),
		:SlamTypeFunction(	Slam::Visitor::PrettyPrint::vm_FunctionDeclarator),
		:SlamTypeHash(	Slam::Visitor::PrettyPrint::vm_HashDeclarator),
		:SlamTypeMultiSub(	Slam::Visitor::PrettyPrint::vm_MultiSubDeclarator),
		:SlamTypePointer(	Slam::Visitor::PrettyPrint::vm_PointerDeclarator),
		:SlamTypeSpecifier(	Slam::Visitor::PrettyPrint::vm_TypeSpecifier),
	));
	
	self.output(Array::empty());
}

method leader()			{ return String::repeat(' ', self.indent_level); }
method output(*@value)		{ self.ATTR('output', @value); }
method result()			{ return Array::join('', self.output); }
method specifier(*@value)		{ self.ATTR('specifier', @value); }

method undent($value?) { 
	unless Scalar::defined($value) { $value := 4; }
	self.indent_level(self.indent_level - $value); 
}

################################################################

method vm_DEFAULT($node) {
	NOTE("Unrecognized node type: ", Class::of($node));
	DUMP($node);
	my $result := "\n" ~ self.leader
		~ "/* Prettyprint: Unknown node: " ~ Class::of($node) 
		~ ", id = " ~ $node.id ~ "  */\n";
	return $result;
}

method vm_ArrayDeclarator($node) {
	my $declarator := self.declarator ~ '[';
	
	if Scalar::defined($node.elements) {
		$declarator := $declarator ~ $node.elements;
	}
	else {
		$declarator := $declarator ~ ' ';
	}
	
	$declarator := $declarator ~ ']';
	self.declarator($declarator);
}

method vm_DeclarationList($node) {
	NOTE("Doing nothing - let the decls handle it.");
	DUMP($node);
}

method vm_FunctionDeclarator($node) {
	my $declarator := self.declarator ~ '(';
	$declarator := $declarator ~ ' /* need args, later. */ ';
	$declarator := $declarator ~ ')';
	self.declarator($declarator);
}

method vm_HashDeclarator($node) {
	my $declarator := self.declarator ~ '[ % ]';
	self.declarator($declarator);
}

method vm_Literal($node) {
	self.append($node.value);
}
		
method vm_Namespace($node, :$start?, :$end?) {
	if $start {
		NOTE("Entering namespace ", $node);
		DUMP($node);
		self.append(self.leader, 'namespace ', $node, " {\n");
		self.indent();
	}
	elsif $end {
		NOTE("Leaving namespace ", $node);
		self.undent();
		self.append(self.leader, "}\n");
	}
	else {
		DIE("Must pass :start(1) or :end(1) to visit.");
	}
}

method vm_MultiSubDeclarator($node) {
	DIE("I have no idea what to do here.");
}

method vm_PointerDeclarator($node) {
	my $pointer		:= '*';
	
	if $node.has_access_qualifier {
		$pointer := '* ' ~ format_access_qualifiers($node);
	}
	
	my $declarator := $pointer ~ self.declarator;
	
	if $node.nominal.is_declarator && !node.nominal.is_pointer {
		$declarator := '(' ~ $declarator ~ ')';
	}
}

method vm_SymbolDeclaration($node, :$start?, :$end?) {
	NOTE("Declaring symbol.");
	self.declarator($node.name);
	
	# Have to call this explicitly - symbols don't traverse type by default.
	$node.type.accept_visitor(self);

	self.append(self.leader);
	
	if $node.storage_class ne Registry<SYMTAB>.current_scope.default_storage_class {
		self.append($node.storage_class, ' ');
	}
	
	self.append(self.specifier, self.declarator);
	
	if $node.initializer {
		self.append(' = ');
		$node.initializer.accept_visitor(self);
	}
	
	self.append(";\n");
}

method vm_TypeSpecifier($node) {
	my $specifier := format_access_qualifiers($node)
		~ $node.typename;
	$specifier := $specifier ~ String::repeat(' ', 8 - (String::length($specifier) % 8));
	self.specifier($specifier);
}
