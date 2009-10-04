# $Id: $

module Parrot;

sub _get_parrot() {
	unless our $parrot_compiler {
		$parrot_compiler := Q:PIR {
			load_language 'parrot'
			%r = compreg 'parrot'
		};
	}
	
	return $parrot_compiler;
}

sub IMPORT($namespace, $names?) {
	my $caller_nsp := caller_namespace(2);
	my $from_nsp := get_namespace($namespace);
	
	my @names;
	
	if $names {
		@names := String::split(' ', $names);
	}
	else {
		for $from_nsp {
			my $name := ~$_;
			my $first_char := String::char_at($name, 0);
			my $skip := 0;
			
			if $first_char eq '$' 
				|| $first_char eq '@' 
				|| $first_char eq '%'
				|| $first_char eq '&'
				|| $first_char eq '_' {
				$skip := 1;
			}
			elsif String::substr($name, 0, 6) eq '_block' {
				$skip := 1;
			}
			
			unless $skip {
				@names.push(~$_);
			}
		}
	}
	
	$from_nsp.export_to($caller_nsp, @names);
}

sub caller_namespace($index?) {
	unless $index {
		$index := 1;
	}
	
	my $nsp := Q:PIR {
		.local pmc key
		key = new 'Key'
		key = 'namespace'
		$P0 = find_lex '$index'
		$S0 = $P0
		$P1 = new 'Key'
		$P1 = $S0
		push key, $P1
		
		$P0 = getinterp
		%r = $P0[ key ]
	};
	
	return $nsp;
}

sub compile($string) {
	my $result := Q:PIR {
		.local pmc comp
		comp = compreg 'PIR'
		
		$P0 = find_lex '$string'
		%r = comp($P0)
	};
	
	return $result;
}

sub get_namespace($name) {
	my @namespace := String::split('::', $name);
	
	my $namespace := Q:PIR {
		$P0 = find_lex '@namespace'
		%r = get_hll_namespace $P0
	};
	
	return $namespace;
}
