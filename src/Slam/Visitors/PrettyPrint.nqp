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

sub format_access_qualifiers($node) {
	my $quals := '';
	
	if $node.is_const { $quals := $quals ~ 'const '; }
	if $node.is_volatile { $quals := $quals ~ 'volatile '; }
	return $quals;
}

method indent($value)		{ self.indent_level(self.indent_level + $value); }
method indent_level(*@value)	{ self.ATTR('indent_level', @value); }

method init(@children, %attributes) {
	self.init_(@children, %attributes);
	
	self.indent_level(0);
	
	self.method_dispatch(Hash::new(
		:DEFAULT(		Slam::Visitor::PrettyPrint::pp_DEFAULT),
		:SlamLiteralInteger(	Slam::Visitor::PrettyPrint::pp_Literal),
		:SlamNamespace(	Slam::Visitor::PrettyPrint::pp_Namespace),
		:SlamStatementSymbolDeclarationList(
					Slam::Visitor::PrettyPrint::pp_DeclarationList),
		:SlamSymbolDeclaration(
					Slam::Visitor::PrettyPrint::pp_SymbolDeclaration),
		:SlamTypeArray(	Slam::Visitor::PrettyPrint::pp_ArrayDeclarator),
		:SlamTypePointer(	Slam::Visitor::PrettyPrint::pp_FunctionDeclarator),
		:SlamTypePointer(	Slam::Visitor::PrettyPrint::pp_HashDeclarator),
		:SlamTypePointer(	Slam::Visitor::PrettyPrint::pp_PointerDeclarator),
		:SlamTypeSpecifier(	Slam::Visitor::PrettyPrint::pp_TypeSpecifier),
	));
	
	self.output(Array::empty());
}

method leader()			{ return String::repeat(' ', self.indent_level); }
method output(*@value)		{ self.ATTR('output', @value); }
method result()			{ return Array::join('', self.output); }
method specifier(*@value)		{ self.ATTR('specifier', @value); }
method undent($value)		{ self.indent_level(self.indent_level - $value); }

################################################################

method pp_DEFAULT($node) {
	NOTE("Unrecognized node type: ", Class::of($node));
	DUMP($node);
	my $result := "\n" ~ self.leader
		~ "/* Prettyprint: Unknown node: " ~ Class::of($node) 
		~ ", id = " ~ $node.id ~ "  */\n";
	return $result;
}

method pp_ArrayDeclarator($node) {
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

method pp_DeclarationList($node) {
	NOTE("Doing nothing - let the decls handle it.");
	DUMP($node);
}

method pp_FunctionDeclarator($node) {
	my $declarator := self.declarator ~ '(';
	$declarator := $declarator ~ ' /* need args, later. */ ';
	$declarator := $declarator ~ ')';
	self.declarator($declarator);
}

method pp_HashDeclarator($node) {
	my $declarator := self.declarator ~ '[ % ]';
	self.declarator($declarator);
}

method pp_Literal($node) {
	self.append($node.value);
}
		
method pp_Namespace($node, :$start?, :$end?) {
	if $start {
		NOTE("Entering namespace ", $node);
		DUMP($node);
		self.append(self.leader, 'namespace ', $node, " {\n");
		self.indent(8);
	}
	elsif $end {
		NOTE("Leaving namespace ", $node);
		self.undent(8);
		self.append(self.leader, "}\n");
	}
	else {
		DIE("Must pass :start(1) or :end(1) to visit.");
	}
}

method pp_PointerDeclarator($node) {
	my $pointer		:= '*';
	
	if $node.has_access_qualifier {
		$pointer := '* ' ~ format_access_qualifiers($node);
	}
	
	my $declarator := $pointer ~ self.declarator;
	
	if $node.nominal.is_declarator && !node.nominal.is_pointer {
		$declarator := '(' ~ $declarator ~ ')';
	}
}

method pp_SymbolDeclaration($node, :$start?, :$end?) {
	NOTE("Declaring symbol.");
	self.declarator($node.name);
	
	# Have to call this explicitly - symbols don't traverse type by default.
	$node.type.accept_visit(self);

	self.append(self.specifier, self.declarator);
	
	if $node.initializer {
		self.append(' = ');
		$node.initializer.accept_visit(self);
	}
	
	self.append(";\n");
}

method pp_TypeSpecifier($node) {
	my $specifier := format_access_qualifiers($node)
		~ $node.typename;
	$specifier := $specifier ~ String::repeat(' ', 8 - (String::length($specifier) % 8));
	self.specifier($specifier);
}
