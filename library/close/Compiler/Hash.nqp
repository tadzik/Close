# $Id$

class Hash;

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

sub delete(%hash, $key) {
	Q:PIR {{
		$P0 = find_lex '%hash'
		$P1 = find_lex '$key'
		delete $P0[$P1]
	}};
}

sub elements(%hash) {
	my $result := Q:PIR {{
		$P0 = find_lex '%hash'
		$I0 = elements $P0
		%r = box $I0
	}};
	
	return $result;
}

sub exists(%hash, $key) {
	my $result;
	
	if %hash {
		$result := Q:PIR {{
			$P0 = find_lex '%hash'
			$P1 = find_lex '$key'
			$I0 = exists $P0[$P1]
			%r = box $I0
		}};
	}
	else {
		$result := 0;
	}
	
	return $result;	
}

sub new(*%pairs) {
	return %pairs;
}

