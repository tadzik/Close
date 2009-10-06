# $Id: $

module Slam::Scope::Local;	
# extends Slam::Scope

#Parrot::IMPORT('Dumper');
	
################################################################

_onload();

sub _onload() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Slam::Scope::_onload();
	
	Parrot::IMPORT('Dumper');
	
	NOTE("Declaring subclass Slam::Scope::Local");
	Class::SUBCLASS('Slam::Scope::Local', 
		'Slam::Scope');
}

################################################################

method add_using_namespace($directive) {
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
	
	my $result := self.contains($reference, :satisfies(&satisfies));
	
	unless $result {
		NOTE("Not found. Looking in using-namespaces");
		$result := self.lookup_in_using_namespaces($reference, 
			:satisfies(&satisfies));
	}

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

# TODO: Add init method, set this value there, stop checking each time.
method using_namespaces() {
	unless self<using_namespaces> {
		self<using_namespaces> := Array::empty();
	}
	
	return self<using_namespaces>;
}
