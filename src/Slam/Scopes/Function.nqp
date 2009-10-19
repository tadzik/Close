# $Id: $

module Slam::Scope::Function;
# extends Slam::Scope

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');
	
	my $class_name := 'Slam::Scope::Function';
	NOTE("Declaring subclass ", $class_name);
	Class::SUBCLASS($class_name, 
		'Slam::Scope::Local');
		
	Class::MULTISUB($class_name, 'attach', :starting_with('_attach_'));
}

method _attach_Slam_Scope_Local($scope) {
	NOTE("Attaching body (compound-statement) block");
	self.push($scope);
}

# Not used - code calls init with :parameter_scope instead.
method _attach_Slam_Scope_Parameter($scope) {
	NOTE("Attaching parameter scope");
	self.parameter_scope($scope);
}

method init(@children, %attributes) {
	self.init_(@children, %attributes);
}

method lookup($reference, :&satisfies) {
	my $name := $reference.name;
	NOTE("Looking up ", $name, " in ", self);
	DUMP(self);
	
	my $result := self.contains($reference, :satisfies(&satisfies));
	
	unless $result {
		NOTE("Not found. Looking in parameter scope.");
		if my $params := self.parameter_scope {
			$result := $params.contains($reference, :satisfies(&satisfies));
		}
	}
	
	unless $result {
		NOTE("Not found. Looking in using-namespaces");
		$result := self.lookup_in_using_namespaces($reference, 
			:satisfies(&satisfies));
	}

	NOTE("done");
	DUMP($result);
	return $result;
}

method parameter_scope(*@value)		{ self._ATTR('parameter_scope', @value); }