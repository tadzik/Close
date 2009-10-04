# $Id$
class Slam::Grammar::Actions;

method ADV_ANON($/) {
	my $past := Slam::Adverb.new(:name(~ $/), :node($/));
	make $past;
}

method ADV_FLAT($/) {
	my $past := Slam::Adverb::Flat.new(:name(~ $/), :node($/));
	make $past;
}

method ADV_INIT($/) {
	my $past := Slam::Adverb.new(:name(~ $/), :node($/));
	make $past;
}

method ADV_LOAD($/) {
	my $past := Slam::Adverb.new(:name(~ $/), :node($/));
	make $past;
}

method ADV_MAIN($/) {
	my $past := Slam::Adverb.new(:name(~ $/), :node($/));
	make $past;
}

method ADV_METHOD($/) {
	my $past := Slam::Adverb.new(:name(~ $/), :node($/));
	make $past;
}

method ADV_MULTI($/) {
	my $past := Slam::Adverb.new(:name(~ $/), :node($/),
		:signature($<signature>.ast),
	);
	make $past;
}

method ADV_NAMED($/) {
	my $past := Slam::Adverb.new(:name(~ $/), :node($/));
	
	if $<named> {
		my $named := $<named>[0].ast.value();
		$past.named($named);
	}

	make $past;
}

method ADV_OPTIONAL($/) {
	my $past := Slam::Adverb.new(:name(~ $/), :node($/));
	make $past;
}

method ADV_REG_CLASS($/) {
	my $past := Slam::Adverb::RegisterClass.new(:name(~ $/), :node($/),
		:register_class($<register_class>.ast.value),
	);
	make $past;
}

method ADV_SLURPY($/) {
	my $past := Slam::Adverb::Slurpy.new(:name(~ $/), :node($/));
	make $past;
}

method ADV_VTABLE($/) {
	my $past := Slam::Adverb::Vtable.new(:name(~ $/), :node($/));
	
	if $<vtable> {
		my $vtable := $<vtable>[0].ast.value;
		$past.vtable($vtable);
	}
	
	make $past;
}

method BAREWORD($/) {
	NOTE("Parsed BAREWORD");
	
	my $past := PAST::Val.new(
		:node($/),
		:name(~ $/),
		:value(~ $/),
	);

	MAKE($past);
}

method BASIC_TYPE($/) {
	NOTE("Saw basic type name: ", ~ $/);
	my $past := Slam::Symbol::Reference.new(:name(~$/), :node($/));
	MAKE($past);
}

method CONST($/) {
	my $past := Slam::Type::Specifier(:name(~$/), :node($/), :is_const(1));
	make $past;
}

method FLOAT_LIT($/) {
	NOTE("Parsed FLOAT_LIT");
	
	my $past := Slam::Node::create('float_literal',
		:name(~ $/),
		:node($/),
		:value(~ $/),
	);
	
	DUMP($past);
	make $past;
}

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

method IDENTIFIER($/, $key) { PASSTHRU($/, $key); }

method INTEGER_LIT($/) {
	NOTE("Parsed INTEGER_LIT");
	
	my $past := Slam::Literal::Integer.new(:node($/),
		:value(~ $<value>));
	
	if $<bad_octal> {
		$past.warning(:message("Integer literals like '", 
			$past.value(),
			"' are not interpreted as octal. Use the 0o ",
			"(zero, oh) prefix for octal literals."));
	}
	
	if $<lu_part> {
		$past.warning(:message(
			"Integer suffix '",  ~$<lu_part>, "' ignored"));
	}
	
	MAKE($past);
}

method QUOTED_LIT($/, $key) {
	NOTE("Parsed QUOTED_LIT");
	
	my $past := PAST::Val.new(:name(~$/), :node($/), 
		:value($<string_literal>.ast));
	$past<quote> := $key;
	DUMP($past);
	make $past;
}

method STRING_LIT($/, $key) { PASSTHRU($/, $key); }

method SYSTEM_HEADER($/) {
	NOTE("Parsed system include file token");
	
	my $past := Slam::Node::create('include_file',
		:name(~ $/),
		:node($/),
		:quote('angle'),
		:include_type('system'),
		:path($<string_literal>.ast),
	);
	
	DUMP($past);
	make $past;
}

method USER_HEADER($/) {
	NOTE("Parsed user include file token");
	
	my $past := Slam::Node::create('include_file',
		:name(~ $/),
		:node($/),
		:quote('double'),
		:include_type('user'),
		:path($<string_literal>.ast),
	);
	
	DUMP($past);
	make $past;
}

method VOLATILE($/) {
	my $past := Slam::Type::Specifier(:name(~$/), :node($/), :is_volatile(1));
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