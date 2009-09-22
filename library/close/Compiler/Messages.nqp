# $Id$

class close::Compiler::Messages;

sub ASSERT($condition, *@message) {
	close::Dumper::ASSERT(close::Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	close::Dumper::DIE(close::Dumper::info(), @msg);
}

sub DUMP(*@pos, *%what) {
	close::Dumper::DUMP(close::Dumper::info(), @pos, %what);
}

sub NOTE(*@parts) {
	close::Dumper::NOTE(close::Dumper::info(), @parts);
}

sub add_error($past, $msg) {
	unless $past<messages> {
		$past<messages> := Array::empty();
	}
	
	$past<messages>.push(new_error($msg));
	DUMP($past);
	return $past;
}

sub add_warning($past, $msg) {
	unless $past<messages> {
		$past<messages> := Array::empty();
	}
	
	$past<messages>.push(new_warning($msg));
	DUMP($past);
	return $past;
}

sub format_node_message($node, $message) {
	my $from_line := String::line_number_of($node<source>, :offset($node<pos>));
	my $from_char := String::character_offset_of($node<source>, :line($from_line), :offset($node<pos>));

	my $result := '' ~ close::Compiler::Scopes::current_file()
		~ ':' ~ $from_line
		~ ':' ~ $from_char
		~ ', ' ~ $message<kind>
		~ ': ' ~ $message.value();
	
	NOTE($result);
	return $result;
}

sub get_messages($past) {
	my @messages := Array::clone($past<messages>);
	
	return @messages;
}

sub new_error($msg) {
	my $error := new_message('error', $msg);
	DUMP($error);
	return $error;
}

sub new_warning($msg) {
	my $warning := new_message('warning', $msg);
	DUMP($warning);
	return $warning;
}

sub new_message($kind, $msg) {
	my $past := PAST::Val.new(:returns('String'), :value($msg));
	$past<kind> := $kind;
	DUMP($past);
	return $past;
}
