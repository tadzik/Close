# $Id$

module Slam::Visitor {
	# Done in _onload
	#Parrot::IMPORT('Dumper');
		
	################################################################

	_onload();

	sub _onload() {
		if our $onload_done { return 0; }
		$onload_done := 1;
			
		Parrot::IMPORT('Dumper');
		
		# Mixin defined at bottom of this file.
		NOTE("Creating mixing class Slam::VisitAcceptor");
		Class::NEW_CLASS('Slam::VisitAcceptor');
		
		NOTE("Creating base class Slam::Visitor");
		Class::SUBCLASS('Slam::Visitor', 'Hash');
		
		NOTE("done");
	}

	################################################################

	method ATTR($name, @value) {
		if +@value { self{$name} := @value[0]; }
		return self{$name};
	}

	method already_visited($node, %options, *@value) {
		my $cache	:= self.visit_cache;
		ASSERT(Scalar::defined($cache), 
			'Failed to init <visit_cache> hash.');
			
		my $id	:= $node.id;
		ASSERT($id, "C'est impossible! Node with no id?");

		if %options<start> { $id := $id ~ ':start'; }
		elsif %options<end> { $id := $id ~ ':end'; }
		
		if +@value {
			NOTE("Setting already_visited status for ", $id, 
				" to ", @value[0]);
			$cache{$id} := @value[0];
		}
		
		return $cache{$id};
	}

	method delete($node) {
		ASSERT(Scalar::defined(self<wants_delete>),
			'Failed to init <wants_delete> hash.');

		self<wants_delete>{$node.id} := 1;
	}

	method description()		{ DIE("NOT IMPLEMENTED IN SUBCLASS"); }

	sub dispatch_by_class($object, %dispatch) {
		my &method;
		
		if %dispatch {
			my $classname := dispatch_classname($object);	
			&method := %dispatch{$classname} || %dispatch<DEFAULT>;
		}
		
		return &method;
	}

	sub dispatch_classname($object) {
		my $classname := Class::of($object);
		my @parts	:= String::split(';', $classname);
		$classname	:= Array::join('', @parts);
		return $classname;
	}
	
	method enabled() {
		return ! Registry<CONFIG>.query(Class::name_of(self), 'disabled');
	}
	
	method finish() {
		NOTE(" ***** FINISHED *****");
	}
	
	method init(@children, %attributes) {
		return self.init_(@children, %attributes);
	}
	
	method init_(@children, %attributes) {
		if +@children {
			DIE("Visitor class does not support children");
		}
		
		self<wants_delete>	:= Hash::empty();
		self<visit_cache>	:= Hash::empty();
		
		for %attributes {
			my $attr_name := ~ $_;
			my $value := %attributes{$attr_name};
			my $temp := self;
			
			Q:PIR {
				$P0 = find_lex '$attr_name'
				$P1 = find_lex '$value'
				$P2 = find_lex 'self'
				$S0 = $P0
				$P0 = find_method $P2 , $S0
				$P2.$P0($P1)
			};
		}
		
		return self;
	}
	
	method isa($type) {
		my $result := self.HOW.isa(self, $type);
	}
	
	method method_dispatch(*@value)	{ self.ATTR('method_dispatch', @value); }
	
	method new(*@children, *%attributes) {
		my $new := Q:PIR { 
			.local pmc attributes, children
			attributes = find_lex '%attributes'
			children = find_lex '@children'

			$P0 = self.'HOW'()
			$P0 = getattribute $P0, 'parrotclass'
			%r =  new $P0
		};
		
		$new.init(children, attributes);
		return $new;
	}

	method visit($node, *%options) {
		ASSERT($node.isa(Slam::VisitAcceptor), 
			'Visitor only works with Slam::VisitAcceptor nodes');
		ASSERT(self.method_dispatch, 
			'Slam::Visitor subclass ', Class::of(self), ' failed to set up method_dispatch table');

		my $result := self.already_visited($node, %options);
		
		unless $result {
			# Set this first, in case of a recursive structure.
			self.already_visited($node, %options, 1);

			my &method := dispatch_by_class($node, self.method_dispatch);
		
			if &method {
				NOTE("Visiting ", Class::name_of($node));
				$result := Q:PIR {
					.local pmc self, method, node, options
					self = find_lex 'self'
					method = find_lex '&method'
					node = find_lex '$node'
					options = find_lex '%options'
						
					%r = self.method(node, options :flat :named)
				};
			}
			else {
				NOTE("No method (not even default) for node type ", Class::name_of($node));
			}
		}
		
		return $result;
	}
	
	method visit_cache(*@value)	{ self.ATTR('visit_cache', @value); }

	method wants_delete($node) {
		ASSERT(Scalar::defined(self<wants_delete>),
			'Failed to init <wants_delete> hash.');

		return self<wants_delete>{$node.id};
	}
}

################################################################

module Slam::VisitAcceptor {

	Parrot::IMPORT('Dumper');

	################################################################
	
	method visitor_dispatch(*@value)		{ self.ATTR('visitor_dispatch', @value); }

	method accept_visitor($visitor) {
	say("Default accept_visitor for ", Class::name_of(self));
		my $result;
		my &method := Slam::Visitor::dispatch_by_class($visitor, self.visitor_dispatch);
		
		if &method {
			NOTE("Found dispatch method for ", Class::name_of($visitor));
			$result := &method(self, $visitor);
		}
		else {
			NOTE("Using default dispatch for visitor ", $visitor);
			$result := $visitor.visit(self);
		}

		return $result;
	}
}
