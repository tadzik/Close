# $Id: $

module Slam::Scope::Local;	
# extends Slam::Scope

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');
	
	NOTE("Declaring subclass Slam::Scope::Local");
	my $class_name := 'Slam::Scope::Local';
	Class::SUBCLASS($class_name,
		'Slam::Scope');
	
	Class::MULTISUB($class_name, 'attach', :starting_with('_attach_'));
}

method _attach_Slam_Statement_UsingNamespace($directive) {
	ASSERT($directive.isa(Slam::Statement::UsingNamespace),
		'$directive parameter must be a UsingNamespace statement');
	
	my $namespace := $directive.using_namespace;
	my $already := 0;
	
	for self.using_namespaces {
		if $_ =:= $namespace {
			$already := 1;
			$directive.add_warning(:message(
				"This directive is redundant. ",
				"Namespace ", $directive.display_name,
				" is already used."),
			);
		}
	}
	
	unless $already {
		self.using_namespaces.unshift($namespace);
	}
	
	NOTE("Now there are ", +self.using_namespaces, " entries");
}

method default_storage_class()		{ return 'register'; }

method lookup($reference, :&satisfies) {
	my $name := $reference.name;
	NOTE("Looking up ", $name, " in ", self);
	DUMP(self);
	
	my $result := self.contains($reference, :satisfies(&satisfies));
	
	unless $result {
		NOTE("Not found. Looking in using-namespaces");
		$result := self.lookup_in_using_namespaces($reference, 
			:satisfies(&satisfies));
	}

	NOTE("done");
	DUMP($result);
	return $result;
}

method lookup_in_using_namespaces($reference, :&satisfies) {
	NOTE("Looking up ", $reference, " in using-namespaces of ", self);
	my @results;
	for self.using_namespaces {
		if my $found := $_.contains($reference, :satisfies(&satisfies)) {
			@results.push($found);
		}
	}
	
	my $result;
	if +@results > 1 {
		$reference.error(:message("Ambiguous reference '",
			$reference, "' matches multiple symbols ",
			"visible from ", self, " - use a namespace ",
			"qualifier to disambiguate."));
		$result := @results.shift;
	}
	elsif +@results {
		$result := @results.shift;
	}
	# else { $result := undef }
	
	return $result;
}

method using_namespaces(*@value)	{ self._ATTR_ARRAY('using_namespaces', @value); }
