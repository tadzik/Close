# $Id:  $

module Class;

Parrot::IMPORT('Dumper');
	
################################################################

=sub NEW_CLASS($name)

Create a class.

=cut

sub NEW_CLASS($name) {
	my $meta		:= get_meta();	
	my $new_class	:= $meta.new_class($name);
	return $new_class;
}

=sub SUBCLASS($name, *@parents) 

Creates a subclass, and attaches the 1 or more parents to it.

=cut

sub SUBCLASS($name, *@parents) {
	NOTE("Creating subclass ", $name, " with ", +@parents, " parents.");
	my $meta := get_meta();
	
	unless +@parents {
		NOTE("Adding parent class 'Hash'");
		@parents.push('Hash');
	}
	
	my $class := $meta.new_class($name, 
		:parent(@parents.shift));
	
	while @parents {
		$meta.add_parent($class, @parents.shift);
	}
	
	return $class;
}

sub get_meta() {
	our $meta;
	
	unless Scalar::defined($meta) {
		$meta := Q:PIR { %r = new 'P6metaclass' };
	}

	return $meta;
}

sub name_of($object) {
	my $class := Class::of($object);
	my @parts := String::split(';', $class);
	$class := Array::join('::', @parts);
	return $class;
}

sub of($object) {
	my $class := Q:PIR {
		$P0 = find_lex '$object'
		%r = typeof $P0
	};
	
	return $class;
}