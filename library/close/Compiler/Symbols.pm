# $Id$

class close::Compiler::Symbols;

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

our @Symbol_predicates := (
	'is_alias', 
	'is_duplicate',
	'is_implicit',
);

sub new($name, $type, $block) {
	my $symbol := PAST::Var.new(:name($name));

	for @Symbol_predicates {
		$symbol{$_} := 0;
	}
	
	$symbol<pir_name>	:= $name;
	$symbol<block>		:= $block;
	#$symbol<searchpath>	:= clone_current_scope();
	
	if $type {
		my $etype		:= $type;
		
		while $etype<is_declarator> {
			$etype		:= $etype<type>;
		}
		
		$symbol<type>	:= $type;
		$symbol<etype>	:= $etype;
	}

	close::Compiler::Scopes::declare_object($block, $symbol);
	DUMP(:symbol($symbol));
	return $symbol;
}

sub print_aggregate($agg) {
	say(substr($agg<kind> ~ "        ", 0, 8),
		substr($agg<tag> ~ "                  ", 0, 18));
	
	for $agg<symtable> {
		print_symbol($agg.symbol($_)<decl>);
	}
}

sub print_symbol($sym) {
DUMP($sym);
	if $sym<is_alias> {
		say(substr($sym.name() ~ "                  ", 0, 18),
			" ",
			substr("is an alias for: " ~ "                  ", 0, 18),
			" ",
			substr($sym<alias_for><block>.name() ~ '::' 
				~ $sym<alias_for>.name() ~ "                              ", 0, 30));
	}
	else {
		say(substr($sym.name() ~ "                  ", 0, 18),
			" ",
			substr($sym<pir_name> ~ "                  ", 0, 18),
			" ",
			$sym<block>.name(), 
			" ",
			close::Compiler::Types::type_to_string($sym<type>));
	}
}
