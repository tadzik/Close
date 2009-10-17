# $Id: $

module Slam::Visitor::PrettyPrintDefault;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	Parrot::IMPORT('Dumper');
	Slam::Visitor::_ONLOAD();
	
	NOTE("Creating Slam::Visitor::PrettyPrint::Default");
	Class::SUBCLASS('Slam::Visitor::PrettyPrint', 
		'Visitor', 'Slam::Visitor');
	
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
	self.elements[0] := Visitor::Combinator::Identity.new();
	self.indent_level(0);
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

method visit($visitable) {
	ASSERT($visitable.isa(Visitor::Visitable),
		'$visitable parameter must be a Visitable object');
	
	self.success(1);
	self.delete_node(0);
	# NB: Return is important for modifying visitors.
	self.result($visitable.accept(self));
	
	self.append(self.result);
	
	return self.result;
}
################################################################
