# $Id$

module Slam::Message {

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		NOTE("Creating Slam::Message");
		Class::SUBCLASS('Slam::Message', 'Slam::Var');
	}

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
		self._ATTR('message', Array::new(@value.join)); 
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

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;

		Parrot::IMPORT('Dumper');
		
		NOTE("Creating Slam::Error");
		Class::SUBCLASS('Slam::Error', 'Slam::Message');
	}

	method severity()			{ return 'error'; }
}

module Slam::Warning {

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;

		Parrot::IMPORT('Dumper');
		
		NOTE("Creating Slam::Warning");
		Class::SUBCLASS('Slam::Warning', 'Slam::Message');
	}

	method severity()			{ return 'warning'; }
}