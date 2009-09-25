# $Id:  $
class Config;

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
	my @info := Dumper::info();
	@info[0] and Dumper::DUMP(@info, @pos, %what);
}

sub NOTE(*@parts) {
	my @info := Dumper::info();
	@info[0] and Dumper::NOTE(@info, @parts);
}

################################################################

our $_Pmc;

sub _get_pmc() {
	unless Scalar::defined($_Pmc) {
		$_Pmc := Q:PIR {
			load_bytecode "config.pbc"
			%r = _config()
		};		
	}
	
	DUMP($_Pmc);
	return $_Pmc;
}

sub query($key) {
	NOTE("Querying for Config setting: '", $key, "'");
	my $result := _get_pmc(){$key};
	DUMP($result);
	return $result;
}