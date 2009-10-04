# $Id$

class Scalar;

sub ASSERTold($condition, *@message) {
	Dumper::ASSERTold(Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	Dumper::DIE(Dumper::info(), @msg);
}

sub DUMPold(*@pos, *%what) {
	Dumper::DUMPold(Dumper::info(), @pos, %what);
}

sub NOTEold(*@parts) {
	Dumper::NOTEold(Dumper::info(), @parts);
}

################################################################

sub defined($what) {
	NOTEold("Checking if something is defined");
	DUMPold($what);
	
	my $result := Q:PIR {{
		$P0 = find_lex '$what'
		$I0 = defined $P0
		%r = box $I0
	}};
	
	NOTEold("Returning ", $result);
	return $result;
}

sub undef() {
	my $undef;
	
	return $undef;
}