# $Id: Scopes.nqp 155 2009-09-25 04:42:21Z austin_hastings@yahoo.com $

module Slam::IncludeFile;

#Parrot::IMPORT('Dumper');

################################################################

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');
	
	NOTE("done");
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
		$file.error("Include file ", $file.name(), " not found.");
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

sub include_type_search_path($type) {
	unless our %include_search_paths {
		%include_search_paths := Hash::new(
			:system(	Array::new('include')),
			:user(	Array::new('.')),
		);
	}
	
	return %include_search_paths{$type};
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

	if Parrot::defined($contents) {
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
		$P0 = find_dynamic_lex '$?FILES'
		if null $P0 goto skip
			
		$P0 = find_lex '$value'
		$P1 = shift $P0
		store_dynamic_lex '$?FILES', $P1

		$P1 = shift $P0
		set_hll_global '$!ws', $P1
	skip:
	};
}
