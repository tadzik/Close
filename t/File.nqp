# $Id$
class File;

sub ASSERTold($condition, *@message) {
	Dumper::ASSERTold(Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	Dumper::DIE(Dumper::info(), @msg);
}

sub DUMPold(*@pos, *%what) {
	my @info := Dumper::info();
	@info[0] and Dumper::DUMPold(@info, @pos, %what);
}

sub NOTEold(*@parts) {
	my @info := Dumper::info();
	@info[0] and Dumper::NOTEold(@info, @parts);
}

################################################################

our $_Pmc;

sub _get_pmc() {
	unless Scalar::defined($_Pmc) {
		$_Pmc := Q:PIR {
			%r = root_new [ 'parrot' ; 'File' ]
		};
	}
	
	return $_Pmc;
}

sub copy($from, $to) {
	_get_pmc().copy($from, $to);
}

sub exists($path) {
	return _get_pmc().exists($path);
}

sub find_all($path, @search_list) {
	NOTEold("Finding all paths matching '", $path, "' in ", +@search_list, " directories");
	my @results := Array::empty();
	
	if String::char_at($path, 0) eq '/' {
		NOTEold("Path is rooted - not using search paths");
		@search_list := Array::new('');
	}
	else {
		$path := '/' ~ $path;
	}
	
	for @search_list {
		my $name := $_ ~ $path;
		NOTEold("Trying ", $name);
		
		if exists($name) {
			NOTEold("Success! it's a match");
			@results.push($name);
		}
	}
	
	NOTEold("Found ", +@results, " results");
	DUMPold(@results);
	return @results;
}
			
sub find_first($path, @search_list) {
	return find_all($path, @search_list)[0];
}

sub is_dir($path) {
	return _get_pmc().is_dir($path);
}

sub is_file($path) {
	return _get_pmc().is_file($path);
}

sub is_link($path) {
	return _get_pmc().is_link($path);
}

sub rename($from, $to) {
	_get_pmc().rename($from, $to);
}

sub slurp($path) {
	NOTEold("Slurping contents of file: ", $path);
	
	my $data := Q:PIR {
		$P0 = new 'FileHandle'
		$P1 = find_lex '$path'
		$S0 = $P0.'readall'($P1)
		%r = box $S0
	};
	
	NOTEold("done");
	DUMPold($data);
	return $data;
}
