# $Id$

class Hash;

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

sub empty() {
	my %empty;
	return %empty;
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

sub merge(%first, *@hashes, :%into?, :$use_last?) {
	
	@hashes.unshift(%first);	# Ensure at least one element.

	unless Scalar::defined(%into) {
		%into := @hashes.shift();
		
		unless Scalar::defined(%into) {
			%into := Hash::new();
		}
	}
	
	my %stored := %into;
	
	if $use_last {
		@hashes := Array::reverse(@hashes);
		%stored := Hash::empty();
	}

	for @hashes {
		my $hash := $_;
		for $hash {
			unless Hash::exists(%stored, $_) {
				# Order matters, %stored may alias %into
				%into{$_} := 
				%stored{$_} := $hash{$_};
			}
		}
	}
	
	return %into;
}

sub merge_keys(%first, *@hashes, :@keys!, :%into?, :$use_last?) {
	@hashes.unshift(%first);
	
	unless Scalar::defined(%into) {
		%into := @hashes.shift();
		
		unless Scalar::defined(%into) {
			%into := Hash::new();
		}
	}
	
	my %stored := %into;
	
	if $use_last {
		@hashes := Array::reverse(@hashes);
		%stored := Hash::empty();
	}
	
	for @hashes {
		my $hash := $_;
		
		for @keys {
			if ! Hash::exists(%stored, $_) && Hash::exists($hash, $_) {
				%into{$_} := 
				%stored{$_} := $hash{$_};
			}
		}
	}
	
	return %into;
}

sub new(*%pairs) {
	return %pairs;
}
