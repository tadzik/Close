# $Id$

class Array;

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

sub append(@dest, @append) {
	for @append {
		@dest.push($_);
	}
	
	return @dest;
}

sub delete(@array, $index) {
	Q:PIR {
		$P0 = find_lex '@array'
		$P1 = find_lex '$index'
		$I0 = $P1
		delete $P0[$I0]
	};
}

sub _get_function($name) {
	my $sub := Q:PIR {
		$P0 = find_lex '$name'
		$S0 = $P0
		%r = get_global $S0
	};

	return $sub;
}

sub cmp_numeric($a, $b) { return $b - $a; }
sub cmp_numeric_R($a, $b) { return $a - $b; }
sub cmp_string($a, $b) { if $a lt $b { return -1; } else { return 1; } }
sub cmp_string_R($a, $b) { if $b lt $a { return -1; } else { return 1; } }

our %Bsearch_compare_func;
%Bsearch_compare_func{'<=>'}	:= _get_function('cmp_numeric');
%Bsearch_compare_func{'R<=>'}	:= _get_function('cmp_numeric_R');
%Bsearch_compare_func{'cmp'}	:= _get_function('cmp_string');
%Bsearch_compare_func{'Rcmp'}	:= _get_function('cmp_string_R');

=sub bsearch(@array, $value, ...)

Binary searches for C<$value> in C<@array>, using a selectable comparison 
function. 

The adverbs C<:low(#)> and C<:high(#)> may be specified to search within a subset
of C<@array>.

The adverb C<:cmp(val)> may be specified to select a comparison function. A
user-provided function may be passed as the value to C<:cmp()>, or a string may
be given to choose one of the following default comparison functions:

=item C<< <=> >> - numeric ascending order

=item C<< R<=> >> - numeric descending (reversed) order

=item C<cmp> - string ascending order

=item C<Rcmp> - string descending (reversed) order

If a user-provided function is passed in, it must accept two arguments,
and return some value less than zero if the first argument would appear earlier 
in C<@array> than the second argument.

If the C<$value> is found, returns the index corresponding to the 
value. Otherwise, returns a negative value, V, such that (-V) - 1
is the index where C<$value> would be inserted. These shenanigans
are required because there is no "negative zero" to indicate insertion
at the start of the array.

=cut

sub bsearch(@array, $value, *%adverbs) {
	DUMP(:array(@array));
	NOTE("bsearch: for value ", $value);
	my $low := 0 + %adverbs<low>;

	if $low < 0 {
		$low := $low + @array;
	}
	
	NOTE("low end: ", $low);
	
	my $high := +@array + %adverbs<high>;
	
	if $high > +@array {
		$high := %adverbs<high>;
	}

	NOTE("high end: ", $high);
	
	my $top := $high;
	
	my $cmp := '==';
	
	if %adverbs<cmp> {
		$cmp := %adverbs<cmp>;
	}
	
	my &compare := %Bsearch_compare_func{$cmp};
	unless &compare {
		&compare := %adverbs<cmp>;
	}
	
	NOTE("Compare function is: ", &compare);
	
	my $mid;
	while $low < $high {
		# NQP gets this wrong -- floating point math
		#$mid := $low + ($high - $low) / 2;
		$mid := Q:PIR {
			.local int high, low
			$P0 = find_lex '$high'
			high = $P0
			$P0 = find_lex '$low'
			low = $P0
			$I0 = high - low
			$I0 = $I0 / 2
			$I0 = $I0 + low
			%r = box $I0
		};	
		
		if &compare($value, @array[$mid]) < 0 {
			$low := $mid + 1;
		}
		else {
			$high := $mid;
		}
	}
	
	my $result := - ($low + 1);
	
	if $low < $top
		&& &compare(@array[$mid], $value) == 0 {
		$result := $low;
	}
	
	NOTE("Returning ", $result);
	return $result;
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
	return @elements;
}

sub reverse(@original) {
	my @result := empty();
	
	for @original {
		@result.unshift($_);
	}
	
	return @result;
}

sub unique(@original) {
	my @result := Array::empty();
	
	for @original {
		my $o := $_;
		my $found := 0;
		
		for @result {
			if  $o =:= $_ {
				$found := 1;
			}
		}
		
		unless $found {
			@result.push($o);
		}
	}
	
	return @result;
}