# $Id: Scopes.nqp 155 2009-09-25 04:42:21Z austin_hastings@yahoo.com $

class Slam::IncludeFile;

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

sub ADD_ERROR($node, *@msg) {
	Slam::Messages::add_error($node,
		Array::join('', @msg));
}

sub ADD_WARNING($node, *@msg) {
	Slam::Messages::add_warning($node,
		Array::join('', @msg));
}

sub NODE_TYPE($node) {
	return Slam::Node::type($node);
}

################################################################

sub current() {
	my $current := get_stack()[0];
	DUMP($current);
	return $current;
}

sub dump_stack() {
	DUMP(get_stack());
}

sub get_FILES() {
	NOTE("Getting open file info from $?FILES");
	
	my $filename := Q:PIR {
		%r = find_dynamic_lex '$?FILES'
	};
	
	my $info := Array::new($filename);
	
	Q:PIR {
		$P0 = get_hll_global '$!ws'
		$P1 = find_lex '$info'
		push $P1, $P0
	};

	NOTE("Got $!ws");
	DUMP($info);
	return $info;
}

sub get_file_contents($file) {
	my @search_path := include_type_search_path($file<include_type>);
	my $path := File::find_first($file<path>, @search_path);
	NOTE("Found path: ", $path);
	
	my $success;
	if $path {
		NOTE("Reading file contents into node");
		$file<contents> := File::slurp($path);
		$success := 1;
	}
	else {
		NOTE("Bogus include file - not found");
		ADD_ERROR($file, "Include file ", $file.name(), " not found.");
		$success := 0;
	}
	
	DUMP($file);
	return $success;
}

sub get_stack() {
	our @stack;
	our $init_done;
	
	unless $init_done {
		$init_done := 1;
		@stack := Array::empty();
	}

	DUMP(@stack);
	return @stack;
}

sub in_include_file() {
	return get_stack() > 0;
}

our %Include_search_paths;
%Include_search_paths<system> := Array::new(
	'include',
);

%Include_search_paths<user> := Array::new('.');

sub include_type_search_path($type) {
	return %Include_search_paths{$type};
}

sub parse_text($text) {
	my $result := Q:PIR {
		.local pmc parser
		parser = compreg 'close'
		
		.local string source
		$P0 = find_lex '$text'
		source = $P0
		
		%r = parser.'compile'(source, 'target' => 'past')
	};

	DUMP($result);
	return $result;
}

sub parse_include_file($node) {
	get_file_contents($node);
	my $contents := $node<contents>;

	if Scalar::defined($contents) {
		push($node.name());
		Slam::Scopes::push($node);
		
		# Don't worry about the result of this. The grammar 
		# updates the current scope, etc.
		parse_text($contents);
		
		Slam::Scopes::pop('include_file');
		pop_include_file();
	}
	
	return $node;
}

sub parse_internal_file($path) {
	my @search_path := include_type_search_path('system');
	my $full_path := File::find_first($path, @search_path);
	NOTE("Found path: ", $full_path);
	
	unless $path {
		DIE("Could not locate internal file: <", $full_path, ">");
	}
	
	NOTE("Reading file contents");
	my $contents := File::slurp($full_path);
	DUMP($contents);
	
	NOTE("Parsing contents");
	push($path);
	parse_text($contents);
	pop();
}

sub parse_internal_string($string, $desc) {
	NOTE("Parsing internal string: ", $desc);
	DUMP($string);
	
	if $string {
		push('<internal string: ' ~ $desc ~ '>');
		parse_text($string);
		pop();
	}
}

sub pop() {
	NOTE("Popping include file stack");
	my @stack := get_stack();
	my $old := @stack.shift();
	NOTE("Popped '", $old[0], "', now ", +@stack, " on stack.");
	set_FILES($old);
	return $old;
}

sub push($filename) {
	NOTE("Opening file: '", $filename, "'");
	my $current := get_FILES();
	DUMP($current);
	
	my @stack := get_stack();
	@stack.unshift($current);
	NOTE("Pushed '", $current[0], "', to stack, now ", +@stack, " on stack.");
	
	my $info := Array::new($filename, null);
	set_FILES($info);
	return $filename;
}

sub set_FILES($value) {
	Q:PIR {
		$P0 = find_lex '$value'
		$P1 = shift $P0
		store_dynamic_lex '$?FILES', $P1

		$P1 = shift $P0
		set_hll_global '$!ws', $P1
	};
}
