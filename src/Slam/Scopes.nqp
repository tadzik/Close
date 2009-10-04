# $Id$

module Slam::Scope {

	#Parrot::IMPORT('Dumper');
		
	################################################################

=sub _onload

This code runs at initload, and explicitly creates this class as a subclass of
Node.

=cut

	_onload();

	sub _onload() {
		if our $onload_done { return 0; }
		$onload_done := 1;

		Parrot::IMPORT('Dumper');
	
		NOTE("Slam::Scope::_onload");
	
		my $base := Class::SUBCLASS('Slam::Scope', 'Slam::Block');
	}

	################################################################

	method add_using_namespace($directive) {
		ASSERT($directive.isa(Slam::Statement::UsingNamespace),
			'$directive parameter must be a UsingNamespace statement');
		
		my $namespace	:= $directive.using_namespace;
		my $already	:= 0;
		
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

=method declare($symbol)

Declares a Slam::Symbol in the scope. If two symbol declarations with the same name 
collide in the same scope, the following rules apply:

=item # If the symbols are both marked as multi, they are merged.

=item # If the types are declaration-compatible (see L<Slam::Type>), then the collision 
is considered a re-declaration of a single symbol. The two declarations are unified, and
a re-declaration warning may be issued.

=item # In any other case, the collision is an error.  TODO: I think there may be an 
argument made for lexical/package coexistence, when the package symbol is a nested 
function. That is:

	void foo() {
		void bar() {...}
		pmc bar;
		...
	}

Because the nested function is "really" outside, in the namespace, with a local presence
in the symtable because if the declaration. (Trumping any using-namespace directives,
for example.) But I'm not smart enough to develop a story about why that's a good idea,
so ixnay.

=cut

	method declare($symbol) {
		ASSERT($symbol.isa(Slam::Symbol::Declaration),
			'Only symbol declarations can be added to scopes');
		NOTE("Adding symbol ", $symbol, " to ", self.node_type, " block ", self);
		
		if $symbol.has_qualified_name {
			DIE("Don't know how to handle q-name declarations");
		}
		
		my $name := $symbol.name;
		my $prior := self.symbol($name);
		
		if $prior {
			if $prior.can_merge($symbol) {
				$prior.merge_declarations($symbol);
			}
			else {
				$symbol.error(:message(
					"Redeclaration of '", $name,
					"' not compatible with current declaration."));
			}
		}
		else {
			self.symbol($name, :declaration($symbol));
			self.push($symbol);
		}
	}
	
	method lookup($reference) {
		my $name := $reference.name;
		NOTE("Scope '", self, "' looking up ", $name);
		DUMP(self);
		DUMP($reference);
		
		my $result := self.symbol($name) && self.symbol($name)<declaration>;

		NOTE("Done. Found: ", $result);
		DUMP($result);
		return $result;
	}
	
	method using_namespaces() {
		unless self<using_namespaces> {
			self<using_namespaces> := Array::empty();
		}
		
		return self<using_namespaces>;
	}
}

class Slam::Scopes;

	Parrot::IMPORT('Dumper');
		
	################################################################

sub add_declarator_to($past, $scope) {
	NOTE("Adding name '", $past.name(), "' to ", $scope.node_type, " block '", $scope<display_name>, "'");
	my $name := $past.name();
	my @already := get_symbols($scope, $name);

	my $duplicate;
	my $severity;
	
	for @already {
		if !$duplicate && Slam::Type::same_type($past<type>, $_<type>) {
			$duplicate := $_;
			$severity := Slam::Type::update_redefined_symbol(
				:original($_), :redefinition($duplicate));
		}
	}
	
	if $duplicate {
		if $duplicate<etype><scope> eq 'package' {
			NOTE("Adding conflicting declaration error");
			ADD_ERROR($past,
				"Conflicting declaration of symbol '",
				$past.name(), "' in scope '",
				$scope<display_name>, "'.  ",
				"Only :multi() subs or redeclarations of the same symbol are allowed to duplicate names."
			);
		}
	}
	
	$scope.symbol($name, $past);
}

sub add_declarator($past) {
	NOTE("Adding declarator: ", $past.name());
	DUMP($past);
	
	my $decl_nsp := Slam::Namespace::fetch_namespace_of($past);
	my $current_nsp := Slam::Scopes::fetch_current_namespace();
	
	# If we're declaring it locally, it goes into the current lexical 
	# block. If non-local, it goes into the namespace block.
	# (Non-external symbols go inside functions, etc.)
	# (This is probably wrong - there should be a better way to know what goes where than by namespace.)
	if $decl_nsp =:= $current_nsp {
		NOTE("Using current scope");
		$decl_nsp := Slam::Scopes::current();
	}
	
	add_declarator_to($past, $decl_nsp);
}
		
# FIXME: Don't know how to deal with ?value
sub query_inmost_scope_with_attr($attr, $value?) {
	for get_search_list() {
		if $_{$attr} {
			NOTE("Found matching ", $_<node_type>);
			DUMP($_);
			return $_;
		}
	}
	
	return undef;
}

=sub get_search_list

Returns a copy of the lexical stack - so it can be destroyed - arranged in the 
correct order for searching. The first element of the returned array is the 
top of the lexical stack, the last element is the bottom of the stack, etc.

=cut

sub get_search_list() {
	my @list := Array::empty();
	
	for get_stack() {
		my $block := $_;
		
		@list.push($block);
		
		if $_<using_namespaces> {
			for $_<using_namespaces> {
				@list.push($_);
			}
		}
	}

	@list := Array::unique(@list);
	
	NOTE("Got ", +@list, " scopes to search");
	return @list;
}

sub get_stack() {
	our @scope_stack;
	our $init_done;
	
	unless $init_done {
	say("Create scope stack");
		NOTE("Creating scope stack");
		$init_done := 1;
		@scope_stack := Array::empty();
		NOTE("Stack exists. Now pushing pervasive scope.");
		@scope_stack.push(
			Slam::Scope::Pervasive::get_instance()
		);
	}

	NOTE("Scope stack has ", +@scope_stack, " elements");
	DUMP(@scope_stack);
	return @scope_stack;
}

sub get_symbols($scope, $name) {
	NOTE("Looking up '", $name, "' in scope: ", $scope<display_name>);
	
	my @symbols := $scope<child_sym>{$name};
	
	NOTE("Found ", +@symbols, " results");
	DUMP(@symbols);
	return @symbols;
}
