# $Id$

module Slam::Message {

=sub _onload

This code runs at initload, and explicitly creates this class as a subclass of
Node.

=cut

	# Don't run - dependency order conflict. Copied to Node.
	_onload();

	sub _onload() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		say("Slam::Message::_onload");
		
		my $meta := Q:PIR {
			%r = new 'P6metaclass'
		};

		my $base := $meta.new_class('Slam::Message', 
			:parent('Slam::Val'),
		);
		$meta.new_class('Slam::Type::Error', :parent($base));
		$meta.new_class('Slam::Type::Warning', :parent($base));
	}

	################################################################

	sub ASSERT($condition, *@message) {
		Dumper::ASSERT(Dumper::info(), $condition, @message);
	}

	sub BACKTRACE() {
		Q:PIR {{
			backtrace
		}};
	}

	sub DIE(*@msg) {
		Dumper::DIE(Dumper::info(), @msg);
	}

	sub DUMP(*@pos, *%what) {
		Dumper::DUMP(Dumper::info(), @pos, %what);
	}

	sub NOTE(*@parts) {
		Dumper::NOTE(Dumper::info(), @parts);
	}

	################################################################

	method format() {
		my $result := '' ~ self.file ~ ':' 
			~ self<pos_line> ~ ':' ~ self<pos_char> ~ ', ' 
			~ self.severity ~ ': '
			~ self.message;
		return $result;
	}

	method message(*@value)	{ self.ATTR('message', Array::join('', @value)); }

	method node($node) {
		ASSERT($node.isa(Slam::Node), 
			'Messages can only attach to Slam::Nodes');
		
		self.position($node<source>, $node<pos>);
		self.file($node.file);
	}
	
	method severity(*@value)	{ self.ATTR('severity', @value); }
	
	method position($str, $offset) {
		self<pos_line> := String::line_number_of($str, 
			:offset($offset));
		self<pos_char> := String::character_offset_of($str, 
			:line(self<pos_line>),
			:offset($offset));
	}
	
	method init(*@children, *%attrs) {
		self.severity('message');
		return self.INIT(@children, %attrs);
	}
}

module Slam::Error {
	method init(*@children, *%attrs) {
		self.severity('error');
		return self.INIT(@children, %attrs);
	}
}

module Slam::Warning {
	method init(*@children, *%attrs) {
		self.severity('warning');
		return self.INIT(@children, %attrs);
	}
}