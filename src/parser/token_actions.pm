# $Id$

method BAREWORD($/) {
	my $past := make_token($/);	
	DUMP($past);
	make $past;
}

method FLOAT_LIT($/) {
	my $past := make_token($/);
	$past.returns('Num');

	DUMP($past);
	make $past;
}

method IDENTIFIER($/, $key) { PASSTHRU($/, $key); }

method INTEGER_LIT($/) {
	my $past := make_token($/);
	$past.returns('Integer');
	
	if $<bad_octal> {
		add_warning($past, 
			Array::join('', "Integer literals like '", 
				$past.value(),
				"' are *not* interpreted as ",
				"octal. Use the 0o (zero-oh) ",
				"prefix for octal literals."));
	}

	DUMP($past);
	make $past;
}

method QUOTED_LIT($/, $key) {
	my $past := immediate_token($<string_literal>.ast);
	$past.name($<string_literal>.ast);
	$past.node($/);
	$past<quote> := $key;
	DUMP($past);
	make $past;
}

method STRING_LIT($/, $key) { PASSTHRU($/, $key); }

our @Heredocs_waiting := new_array();
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
			
			my @lines := new_array();

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