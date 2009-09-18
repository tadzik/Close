# $Id$

method BAREWORD($/) {
	NOTE("Parsed BAREWORD");
	
	my $past := close::Compiler::Node::create('bareword',
		:node($/),
		:name(~ $/),
		:value(~ $/),
	);
	
	DUMP($past);
	make $past;
}

method FLOAT_LIT($/) {
	NOTE("Parsed FLOAT_LIT");
	
	my $past := close::Compiler::Node::create('float_literal',
		:name(~ $/),
		:node($/),
		:value(~ $/),
	);
	
	DUMP($past);
	make $past;
}

method IDENTIFIER($/, $key) { PASSTHRU($/, $key); }

method INTEGER_LIT($/) {
	NOTE("Parsed INTEGER_LIT");
	
	my $past := close::Compiler::Node::create('integer_literal',
		:name(~ $/),
		:node($/),
		:value(~ $/),
	);
	
	if $<bad_octal> {
		ADD_WARNING($past, 
			"Integer literals like '", $past.value(),
			"' are not interpreted as octal. Use the 0o ",
			"(zero, oh) prefix for octal literals.");
	}
	
	if $<lu_part> {
		my $token := $past.value();
		
		ADD_WARNING($past,
			"Integer literals like '", $past.value(),
			"' accept the U (unsigned) and L (long) suffixes ",
			" from C, but they are presently ignored.");
		
		$past.value(String::substr($token, 0, String::length($token) - String::length(~$<lu_part>)));
	}
	
	DUMP($past);
	make $past;
}

method QUOTED_LIT($/, $key) {
	NOTE("Parsed QUOTED_LIT");
	
	my $past := close::Compiler::Node::create('quoted_literal',
		:name(~ $/),
		:node($/),
		:quote($key),
		:value($<string_literal>.ast),
	);
	
	DUMP($past);
	make $past;
}

method STRING_LIT($/, $key) { PASSTHRU($/, $key); }

our @Heredocs_waiting := Array::new();
our $Heredocs_open := 0;

method HERE_DOC_LIT($/) {
	my $past := $<QUOTED_LIT>.ast;
	
	$past<heredoc_pos> := $past<pos>;	# <pos> updated by $past.node()
	my $i := +@Heredocs_waiting;
	my $inserted := 0;
	
	while $i-- > 0 {
		if !$inserted
			&& @Heredocs_waiting[$i]<heredoc_pos> eq $past<heredoc_pos>
			&& @Heredocs_waiting[$i].name() eq $past.name()
		{
			# Overwrite the old node because it was part
			# of a failed parse.
			@Heredocs_waiting[$i] := $past;
			$inserted := 1;
		}
	}
	
	unless $inserted {
		@Heredocs_waiting.push($past);
	}
	
	DUMP(@Heredocs_waiting);
	make $past;
}

method WS_ALL($/, $key) {
	if $key eq 'check_for_end' {
		my $ident := ~ $<ident>.shift();
		
		if $ident eq @Heredocs_waiting[0].name() {
			my $past := @Heredocs_waiting.shift();
			$Heredocs_open := +@Heredocs_waiting;
			
			my @lines := Array::new();

			while $<lines> {
				@lines.push(~ $<lines>.shift());
			}
			clean_up_heredoc($past, @lines);
			DUMP($past);
		}		
	}
	elsif $key eq 'start_heredoc' {
		$Heredocs_open := +@Heredocs_waiting;
	}
}