# $Id$

module Slam::Scope::Namespace;
#	extends Slam::Scope::Local
#	does Slam::Symbol::Name

#Parrot::IMPORT('Dumper');

################################################################

_onload();

sub _onload() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Slam::Scope::_onload();
	Slam::Scope::Local::_onload();
	
	Parrot::IMPORT('Dumper');
	
	NOTE("Declaring subclass Slam::Scope::Namespace");
	Class::SUBCLASS('Slam::Scope::Namespace', 
		'Slam::Scope::Local');
}

################################################################

method build_display_name() {
	self.rebuild_display_name(0);
	
	my @path := Array::clone(self.namespace);
	# NOTE: Does not add .name right here.
	
	if my $hll := self.hll {
		@path.unshift('hll:' ~ $hll ~ ' ');
	}
	elsif self.is_rooted {
		@path.unshift('');
	}
		
	self.display_name(Array::join('::', @path));
	NOTE("Display name set to: ", self);
	return self.display_name;
}

method child($name, *@value) {
	unless self<child_nsp> {
		self<child_nsp> := Hash::new();
	}
	
	if +@value {
		self<child_nsp>{$name} := @value.shift;
	}
	
	return self<child_nsp>{$name};
}

method default_storage_class()		{ return 'extern'; }

method fetch_child($name, :$path_index?) {
	ASSERT($name.isa(Slam::Symbol::Name),
		'$name parameter must be a subclass of Slam::Symbol::Name');
	NOTE("Namespace '", self, "' looking up child: ", $name);

	unless $path_index { $path_index := 0; }
	
	if +$name.path <= $path_index {
	DUMP($name.path);
		NOTE("This is it.");
		return self;
	}
	
	NOTE("Path index is: ", $path_index);
	DUMP($name.path);
	my $child_name := $name.path[$path_index];
	my $child := self.child($child_name);
	
	unless $child {
		if self.hll {
			$child := Slam::Scope::Namespace.new(:hll(self.hll), 
				:name($child_name),
				:namespace(self.namespace), 
			);
		}
		else {
			$child := Slam::Scope::Namespace.new(:hll($child_name), 
				:namespace(self.namespace),
			);
		}
		
		
		self.child($child_name, $child);
	}

	return $child.fetch_child($name, :path_index($path_index + 1));
}

method init(*@children, *%attributes) {
	unless %attributes<hll> && Scalar::defined(%attributes<namespace>) {
		DIE("Namespaces must be created with :hll() and :namespace()");
	}
	
	return self.init_(@children, %attributes);
}

method is_namespace()		{ return 1; }

method name(*@value) {
	if +@value {
		my $name := @value[0];
		
		if self.name {
			self.namespace.pop();
		}
		
		self.namespace.push($name);
	}
	
	return self.ATTR('name', @value);
}

method query_child($name, :$path_index?) {
	ASSERT($name.isa(Slam::Symbol::Name),
		'$name parameter must be a subclass of Slam::Symbol::Name');
	NOTE("Namespace ", self.display_name, " looking up child: ", $name.display_name);

	if +$name.path <= $path_index {
		return self;
	}
	
	my $child_name	:= $name.path[$path_index];		
	my $child		:= self.child($child_name);
	
	if $child {
		$child := $child.fetch_child($name, :path_index($path_index + 1));
	}
	
	return $child;
}

sub root() {
	unless our $root {
		$root := Slam::Scope::Namespace.new(:hll('root'), :namespace(Array::empty()));
		$root<hll> := Scalar::undef();
		$root.display_name('<NAMESPACE ROOT>');
	}
	
	return $root;
}
