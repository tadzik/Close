# $Id$

class Scalar;
	Parrot::IMPORT('Dumper');
	
################################################################

sub defined($what) {
	#NOTEold("Checking if something is defined");
	#DUMPold($what);
	
	my $result := Q:PIR {{
		$P0 = find_lex '$what'
		$I0 = defined $P0
		%r = box $I0
	}};
	
	#NOTEold("Returning ", $result);
	return $result;
}

sub undef() {
	my $undef;
	
	return $undef;
}