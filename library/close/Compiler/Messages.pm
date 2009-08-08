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

sub new_error($msg) {
	my $error := new_message('error', $msg);
	DUMP($error);
	return $error;
}

sub new_message($kind, $msg) {
	my $past := PAST::Val.new(:returns('String'), :value($msg));
	$past<kind> := $kind;
	DUMP($past);
	return $past;
}