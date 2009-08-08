# $Id$

class Array;

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

sub append(@dest, @append) {
	for @append {
		@dest.push($_);
	}
	
	return @append;
}

sub clone(@original) {
	my @clone := empty();
	
	for @original {
		@clone.push($_);
	}
	
	return @clone;
}

sub concat(*@sources) {
	my @result := empty();
	
	for @sources {
		for $_ {
			@result.push($_);
		}
	}
	
	return @result;
}
	
sub empty() {
	my @empty := Q:PIR { %r = new 'ResizablePMCArray' };
	return @empty;
}

sub join($_delim, @parts) {
	my $result := '';
	my $delim := '';

	for @parts {
		$result := $result ~ $delim ~ $_;
		$delim := $_delim;
	}

	return $result;
}

sub new(*@elements) {
	my @array := empty();
	
	for @elements {
		@array.push($_);
	}
	
	return @array;
}

sub reverse(@original) {
	my @result := empty();
	
	for @original {
		@result.unshift($_);
	}
	
	return @result;
}