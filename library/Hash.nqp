# $Id$

class Hash;

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

sub delete(%hash, $key) {
	Q:PIR {{
		$P0 = find_lex '%hash'
		$P1 = find_lex '$key'
		delete $P0[$P1]
	}};
}

sub elements(%hash) {
	my %results := Q:PIR {{
		$P0 = find_lex '%hash'
		$I0 = elements $P0
		%r = box $I0
	}};
	
	return %results;
}

sub exists(%hash, $key) {
	my %results;
	
	if %hash {
		%results := Q:PIR {{
			$P0 = find_lex '%hash'
			$P1 = find_lex '$key'
			$I0 = exists $P0[$P1]
			%r = box $I0
		}};
	}
	else {
		%results := 0;
	}
	
	return %results;	
}

sub _yes() {
	return 1;
}

sub merge(*@hashes, *%adverbs) {
	my %results;

	if %adverbs<into> {
		%results := %adverbs<into>;
	}
	elsif +@hashes {
		%results := @hashes.shift();
	}
	else {
		%results := Hash::new();
	}

	my %stored := %results;
	
	if %adverbs<use_last> {
		@hashes := Array::reverse(@hashes);
		%stored := Hash::new();
	}

	for @hashes {
		my $hash := $_;
		for $hash {
			unless Hash::exists(%stored, $_) {
				# Order matters, %stored may alias %results.
				%stored{$_} := _yes;
				%results{$_} := $hash{$_};
			}
		}
	}
	
	return %results;
}

sub new(*%pairs) {
	return %pairs;
}
