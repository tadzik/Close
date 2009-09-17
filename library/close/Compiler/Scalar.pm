# $Id$

class Scalar;

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

################################################################

sub defined($what) {
	my $result := Q:PIR {{
		$I0 = 1
		$P0 = find_lex '$what'
		unless null $P0 goto check_undef
		$I0 = 0
		goto done
	check_undef:
		$I1 = isa $P0, [ 'parrot' ; 'Undef' ]
		unless $I1 goto done
		$I0 = 0
	done:
		%r = box $I0
	}};
	
	NOTE("Returning ", $result);
	return $result;
}

sub undef() {
	my $undef;
	
	return $undef;
}