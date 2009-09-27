# $Id$

class Scalar;

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

sub defined($what) {
	NOTE("Checking if something is defined");
	DUMP($what);
	
	my $result := Q:PIR {{
		$P0 = find_lex '$what'
		$I0 = defined $P0
		%r = box $I0
	}};
	
	NOTE("Returning ", $result);
	return $result;
}

sub undef() {
	my $undef;
	
	return $undef;
}