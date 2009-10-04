# $Id$

module Slam::Message {

	Parrot::IMPORT('Dumper');
		
	################################################################

=sub _onload

This code runs at initload, and explicitly creates this class as a subclass of
Node.

=cut

	# Don't run - dependency order conflict. Copied to Node.
	_onload();

	sub _onload() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		my $base_name := 'Slam::Message';
		
		NOTE("Creating class ", $base_name);
		my $base := Class::SUBCLASS($base_name, 'Slam::Var');

		for ('Error', 'Warning') {
			my $subclass := 'Slam::' ~ $_;
			NOTE("Creating subclass ", $subclass);
			Class::SUBCLASS($subclass, $base);
		}
	}

	################################################################

	method format() {
		my $result := '' ~ self.file ~ ':' 
			~ self<pos_line> ~ ':' ~ self<pos_char> ~ ', ' 
			~ self.severity ~ ': '
			~ self.message;
		return $result;
	}
	
	method init(*@children, *%attributes) {
		Slam::Node::init_(self, @children, %attributes);
		self.position(self<source>, self<pos>);
		return self;
	}

	method message(*@value) {
		# TODO: I don't know if I'm getting an array-in-an-array, or what.
		# Need to know what :message(a,b,c) does on .new()
		self.ATTR('message', Array::new(Array::join('', @value))); 
	}

	method position($str, $offset) {
		self<pos_line> := String::line_number_of($str, 
			:offset($offset));
		self<pos_char> := String::character_offset_of($str, 
			:line(self<pos_line>),
			:offset($offset));
	}

	method severity()			{ return 'message'; }
}

module Slam::Error {
	method severity()			{ return 'error'; }
}

module Slam::Warning {
	method severity()			{ return 'warning'; }
}