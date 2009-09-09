# $Id$

class close::Compiler::Config;

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
	my @info := close::Dumper::info();
	@info[0] and close::Dumper::DUMP(@info, @pos, %what);
}

sub NOTE(*@parts) {
	my @info := close::Dumper::info();
	@info[0] and close::Dumper::NOTE(@info, @parts);
}

################################################################
our %Config_data;

# Bootstrap values, fed to Dumper before we parse the real config file.
%Config_data<Dump><Config><_list_configs>		:= 1;
%Config_data<Dump><Config><_parse_config>	:= 0;
%Config_data<Dump><Config><read>			:= 0;
%Config_data<Dump><Config><value>			:= 0;
%Config_data<Dump><Config><write>			:= 1;


our $Config_file;
our $Line_number;

sub _fetch_container(@path) {
	my %config := %Config_data;
	
	for @path {
		my $part := String::trim($_);
		
		unless String::length($part) {
			say("Warning: ", Array::join("::", @path),
				" - zero-length sub-keys are not allowed");
			$part := 'null';
		}
		
		unless %config{$part}<> {
			#NOTE("Creating sub-hash ", $part);
			%config{$part}<> := 1;
		}
		
		%config := %config{$part};
	}
	
	return %config;
}

sub _list_configs($hash, $prefix) {
	my $result := '';
	
	for $hash {
		my $value := $hash{$_};
		my $is_hash := Q:PIR {
			$P0 = find_lex '$value'
			$I0 = isa $P0, 'Hash'
			%r = box $I0
		};
		
		if $is_hash {
			$result := $result
				~ _list_configs($value, $prefix ~ $_ ~ '::');
		}
		else {
			$result := $result
				~ $prefix ~ $_ ~ " = " ~ $value ~ "\n";
		}
	}
	
	return $result;
}

sub _parse_config($data) {
	my @lines		:= String::split("\n", $data);
	my $line_number	:= 0;
	
	DUMP(@lines);
	for @lines {
		$line_number++;
		my $line := String::trim($_);

		if $line && String::char_at($line, 0) ne '#' {
			my @kv	:= String::split('=', $line);
			my $key	:= @kv.shift();
			my $value	:= String::trim(Array::join('=', @kv));
			#NOTE("Key: ", $key);
			#NOTE("Value: ", $value);
			
			if !@kv {
				say("Warning: ", $Config_file, 
					" line ", $line_number,
					": incorrectly-formed config line: ", $line);
			}
			else {
				my @key_parts := String::split('::', $key);
				my $last	:= String::trim(@key_parts.pop());
				my %hash	:= _fetch_container(@key_parts);
				#NOTE("Last sub-key is '", $last, "'");
				
				unless String::length($last) {
					say("Warning: ", $Config_file,
						" line ", $line_number,
						": zero-length sub-keys are not allowed: ", $line);
					$last := 'null';
				}
				
				%hash{$last} := $value;
			}
		}
	}
	
	DUMP(%Config_data);
}

method read($filename) {
	if %Config_data<> ne '$filename' {
		%Config_data<> := $filename;

		#NOTE("Reading config file: ", $filename);
		
		my $data := Q:PIR {
			$P0 = new 'FileHandle'
			$P1 = find_lex '$filename'
			$S0 = $P0.'readall'($P1)
			%r = box $S0
		};

		#NOTE("Got config data: ", $data);

		_parse_config($data);

		#DUMP(%Config_data);
		say("Read config data from ", $filename);
	}
}

sub time() {
	my $result := Q:PIR {
		$N0 = time
		%r = box $N0
		say %r
	};
	return $result;
}

method value(@path, *@what) {
	#NOTE("key = ", Array::join('::', @path));
	
	my $last := @path.pop();
	my %config := _fetch_container(@path);
	
	if +@what {
		my $value := Array::join('', @what);
		#NOTE("Set value to '", $value, "'");
		%config{$last} := $value;
	}
	
	#NOTE("value = ", %config{$last});
	return %config{$last};
}

method write($filename) {
	my $data := _list_configs(%Config_data, '');
	
	Q:PIR {
		$P0 = new 'FileHandle'
		$P1 = find_lex '$filename'
		$P0.'open'($P1, 'w')
		$P1 = find_lex '$data'
		$P0.'print'($P1)
		$P0.'close'()
	};
}
