# $Id$

class close::Compiler::Visitor;

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
	close::Dumper::DUMP(close::Dumper::info(), @pos, %what);
}

sub NOTE(*@parts) {
	close::Dumper::NOTE(close::Dumper::info(), @parts);
}

################################################################

sub ADD_ERROR($node, *@msg) {
	close::Compiler::Messages::add_error($node,
		Array::join('', @msg));
}

sub ADD_WARNING($node, *@msg) {
	close::Compiler::Messages::add_warning($node,
		Array::join('', @msg));
}

sub NODE_TYPE($node) {
	return close::Compiler::Node::type($node);
}

################################################################

method already_visited($visitor, $node, $store?) {
	my $name := $visitor.name();
	
	if $store {
		$node<visited_by>{$name} := $store;
	}
	
	return $node<visited_by>{$name};
}


method fetch_visit_method($visitor, $node) {
	our %visit_methods;

	my $prefix		:= $visitor.get_method_prefix();
	my $type		:= NODE_TYPE($node);
	my $sub_name	:= $prefix ~ $type;
	my $unknown_sub	:= $prefix ~ 'UNKNOWN';
	my $sub		:=%visit_methods{$visitor.name()}{$type};
	my $caller_nsp	:= self.get_caller_namespace();
	
	#NOTE("Fetching visit_method: ", $sub_name);
	
	unless $sub {
		#NOTE("Not found in cache. Doing lookup.");
		
		$sub := Q:PIR {
			.local pmc caller_nsp
			caller_nsp = find_lex '$caller_nsp'
			
			$S0 = caller_nsp
			
			.local string sub_name
			$P0 = find_lex '$sub_name'
			sub_name = $P0
			
			$P1 = caller_nsp.'find_sub'(sub_name)
			
			unless null $P1 goto have_sub
			
			$P0 = find_lex '$unknown_sub'
			sub_name = $P0
						
			$P1 = caller_nsp.'find_sub'(sub_name)
			
		have_sub:
		
			%r = $P1
		};

		unless $sub {
			DIE("No visit method available, including UNKNOWN,  ",
				"for Node class: ", $type);
		}

		#NOTE("Got sub: ", $sub);
		#DUMP($sub);
		
		%visit_methods{$visitor.name()}{$type} := $sub;
		#DUMP(%visit_methods);
	}
	
	#NOTE("Returning method '", $sub, "'");
	return $sub;
}

method get_caller_namespace() {
	my $nsp := Q:PIR {
		.local pmc caller_namespace, my_namespace
		.local pmc caller, interp, key
		.local int depth
		
		depth = 0

		key = new 'Key'
		key = 'namespace'
		$P1 = new 'Key'
		$P1 = depth
		push key, $P1
		
		interp = getinterp
		my_namespace = interp[ key ]
		
	find_caller_nsp:
		inc depth
		key = new 'Key'
		key = 'namespace'
		$P1 = new 'Key'
		$P1 = depth
		push key, $P1
		caller_namespace = interp [ key ]

		$I0 = issame caller_namespace, my_namespace
		if $I0 goto find_caller_nsp
		
		%r = caller_namespace
	};
	
	return $nsp;
}

my @Results_placeholder := Array::empty();

method visit($visitor, $node) {
	#NOTE("Visiting ", NODE_TYPE($node), " node on behalf of ", $visitor.name());
	
	my @results;

	if Scalar::defined($node) {
		@results := self.already_visited($visitor, $node);
		#DUMP(@results);
		
		unless Scalar::defined(@results) {
			#NOTE("Not visited yet. Inserting temporary marker.");
			#self.already_visited($visitor, $node, Array::new($node));
			self.already_visited($visitor, $node, @Results_placeholder);
			
			my &method := self.fetch_visit_method($visitor, $node);
			@results	:= &method($visitor, $node);
			
			#NOTE("Visit complete. Storing results.");
			if +@results {
				self.already_visited($visitor, $node, @results);
			}
		}
	}
	else {
		@results := Array::empty();
	}

	#NOTE("done");
	#DUMP(@results);
	return @results;
}

method visit_node_generic_noresults($visitor, $node, @child_attrs) {
	if $node.isa(PAST::Block) {
		NOTE("Pushing this block onto the scope stack");
		close::Compiler::Scopes::push($node);
		self.visit_child_syms($visitor, $node);
	}

	for @child_attrs {
		if $node{$_} {
			self.visit($visitor, $node{$_});
		}
	}
	
	self.visit_children($visitor, $node);
	
	if $node.isa(PAST::Block) {
		close::Compiler::Scopes::pop(NODE_TYPE($node));
	}
	
	return @Results_placeholder;
}

method visit_node_generic_results($visitor, $node, @child_attrs) {
	my @results := Array::empty();
	
	if $node.isa(PAST::Block) {
		NOTE("Pushing this block onto the scope stack");
		close::Compiler::Scopes::push($node);
		Array::append(@results, self.visit_child_syms($visitor, $node));
	}

	for @child_attrs {
		if $node{$_} {
			Array::append(@results, self.visit($visitor, $node{$_}));
		}
	}
	
	Array::append(@results, self.visit_children($visitor, $node));
	
	if $node.isa(PAST::Block) {
		close::Compiler::Scopes::pop(NODE_TYPE($node));
	}
	
	return @results;
}

method visit_children($visitor, $node) {
	my @results := Array::empty();	
	
	if $node {
		for @($node) {
			Array::append(@results, $visitor.visit($_));
		}
	}

	#NOTE("Returning ", +@results, " results");
	#DUMP(@results);
	return @results;
}

method visit_child_syms($visitor, $node) {
	my @results := Array::empty();	
	
	if $node &&  $node<child_sym> {
		for $node<child_sym> {
			my @children := close::Compiler::Scopes::get_symbols($node, $_);
			
			for @children {
				Array::append(@results, $visitor.visit($_));
			}
		}
	}

	#NOTE("Returning ", +@results, " results");
	#DUMP(@results);
	return @results;
}
