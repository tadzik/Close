# $Id: $

module Slam::Adverb {

	Parrot::IMPORT('Dumper');
		
	################################################################

=sub _onload

This code runs at initload, and explicitly creates this class as a subclass of
Slam::Val.

=cut

	_onload();

	sub _onload() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		my $base_name := 'Slam::Adverb';
		NOTE("Creating base class ", $base_name);		
		my $base := Class::SUBCLASS($base_name, 'Slam::Val');

		my %subclasses := Hash::new(
			:Flat(		'Slam::Adverb'),
			:Multi(	'Slam::Adverb'),
			:Named(	'Slam::Adverb'),
			:Optional(	'Slam::Adverb'),
			:RegisterClass('Slam::Adverb'),
			:Slurpy(	'Slam::Adverb'),
			:Vtable(	'Slam::Adverb'),
		);

		for %subclasses {
			my $sub_name := 'Slam::Adverb::' ~ $_;
			my $parent := %subclasses{$_};
			NOTE("Creating subclass ", $sub_name, " with parent ", $parent);
			Class::SUBCLASS($sub_name, $parent);
		}
	}
	
	################################################################

	method modify($node) {
		ASSERT($node.isa(Slam::Node), 
			'Adverbs can only modify Slam::Nodes');
			
		my $pirflag := self.pirflag();
		
		if $pirflag {
			NOTE("Appending pirflag '", $pirflag, "' to node's pirflags");
			my $oldflags := $node.pirflags;
			$node.pirflags($oldflags ~ ' ' ~ $pirflag);
		}
	}

	method name(*@value) {
		if +@value {
			my $name := @value.shift;
			if String::char_at($name, 0) eq ':' {
				$name := String::substr($name, 1);
			}
			
			return Slam::Node::name(self, $name);
		}
		
		return Slam::Node::name(self);
	}
	
	method pirflag() {
		my $pirflag := ':' ~ self.name;
		return $pirflag;
	}
}

module Slam::Adverb::Flat {

	Parrot::IMPORT('Dumper');
		
	################################################################

	method modify($node) {
		$node.flat(1);
	}
}

module Slam::Adverb::Multi {

	Parrot::IMPORT('Dumper');
		
	################################################################

	method pirflag() {
		my $pirflags := ':multi(' ~ self.signature ~ ')';
	}

	# TODO: Eventually, take apart the signatures so we can do call type checking.
	method signature(*@value)		{ self.ATTR('signature', @value); }
}

module Slam::Adverb::Named {

	Parrot::IMPORT('Dumper');
		
	################################################################

	method named(*@value) {
		return self.ATTR('named', @value) 
			|| 1;
	}

	method modify($node) {
		$node.named(self.named);
	}
}

module Slam::Adverb::Optional {

	Parrot::IMPORT('Dumper');
		
	################################################################

	# NB: This coerces name='?' into flag=':optional'.
	method pirflag() {
		return ':optional';
	}
}

module Slam::Adverb::RegisterClass {

	Parrot::IMPORT('Dumper');
		
	################################################################

	# NB: There is no flag for this - internal only.
	method pirflag() {
		return '';
	}
	
	method register_class(*@value)	{ self.ATTR('register_class', @value); }
}

module Slam::Adverb::Slurpy {

	Parrot::IMPORT('Dumper');
		
	################################################################

	method modify($node) {
		$node.slurpy(1);
	}
	
	# NB: This coerces name='...' into flag=':slurpy'.
	method pirflag() {
		return ':slurpy';
	}
}

module Slam::Adverb::Vtable {

	Parrot::IMPORT('Dumper');
		
	################################################################

	method pirflag() {
		if self.vtable {
			return ':vtable(' ~ self.vtable ~ ')';
		}
		
		# TODO: Is this the right form for "use the same name as the sub"?
		# Else maybe write .modify(node) to pull node.name and put it here?
		return ':vtable';
	}
}
