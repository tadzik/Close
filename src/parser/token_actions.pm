# $Id$

method BAREWORD($/) {
	my $past := make_token($/);	
	DUMP($past, "BAREWORD");
	make $past;
}

method FLOAT_LIT($/) {
	my $past := make_token($/);
	$past.returns('Num');

	DUMP($past, "FLOAT_LIT");
	make $past;
}

our @Here_docs_waiting;

method HERE_DOC_LIT($/) {
	my $past := make_token($/);

	@Here_docs_waiting.push($past);
	
	DUMP($past, "HERE_DOC_LIT");
	make $past;
}

method IDENTIFIER($/, $key) { PASSTHRU($/, $key, "IDENTIFIER"); }

method INTEGER_LIT($/) {
	my $past := make_token($/);
	$past.returns('Integer');
	
	if $<bad_octal> {
		add_warning($past, 
			join('', "Integer literals like '", 
				$past.value(),
				"' are *not* interpreted as ",
				"octal. Use the 0o (zero-oh) ",
				"prefix for octal literals."));
	}

	DUMP($past, "INTEGER_LIT");
	make $past;
}

method QUOTED_LIT($/) {
	my $past := immediate_token($<string_literal>.ast);
	$past.node($/);
	DUMP($past, "QUOTED_LIT");
	make $past;
}

method STRING_LIT($/, $key) { PASSTHRU($/, $key, 'STRING_LIT'); }
