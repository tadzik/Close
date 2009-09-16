# $Id$

class close::Compiler::Scopes;

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

sub NODE_TYPE($node) {
	return close::Compiler::Node::type($node);
}

################################################################

=sub add_declarator_to_scope($scope, $declaration)

Insert a single declarator-name into the symtable for a block.

=cut

sub add_declarator_to($past, $scope) {
	NOTE("Adding name '", $past.name(), "' to ", NODE_TYPE($scope), " scope '", $scope.name(), "'");
	my $name := $past.name();
	my $already := get_symbol($scope, $name);
	
	if $already {
		if $already =:= $past {
			NOTE("Name was already added (same declarator)");
		}
		else {
			# FIXME: If declarations are compatible, there is no error.
			# Else, there is a type conflict in redeclaration of $name
			DIE("Symbol ", $name, " already declared in scope ", $scope.name(), ".");
		}
	}
	else {
		unless $past<hll> {
			$past<hll> := $scope<hll>;
			$past.namespace($scope.namespace());
		}
		
		set_symbol($scope, $name, $past);
	}
}

sub add_declarator($past) {
	NOTE("Adding declarator: ", $past.name());
	DUMP($past);
	ASSERT(NODE_TYPE($past) eq 'declarator_name',
		"Only declarators can be added.");
	
	my $current_nsp := close::Compiler::Scopes::fetch_current_namespace();
	my $decl_nsp := close::Compiler::Namespaces::fetch_relative_namespace_of($current_nsp, $past);
	
	add_declarator_to($past, $decl_nsp);
	
}
		
sub add_declarator_to_current($past) {
	my $scope := current();
	NOTE("Adding name '", $past.name(), "' to ", $scope<lstype>, " scope '", $scope.name(), "'");
	add_declarator_to($past, $scope);
}

sub add_using_namespace($scope, $nsp) {
	NOTE("Adding namespace '", $nsp.name(), "' to ", NODE_TYPE($scope), " scope '", $scope.name(), "'");
	
	if $scope<using_namespaces> {
		my $found := 0;
		
		for $scope<using_namespaces> {
			if $_ =:= $nsp {
				$found := 1;
			}
		}
		
		if $found == 0 {
			$scope<using_namespaces>.shift($nsp);
		}
	}
	else {
		$scope<using_namespaces> := Array::new($nsp);
	}
	
	NOTE("Now there are ", +($scope<using_namespaces>), " entries");
}

sub current() {
	my $scope := get_stack()[0];
	DUMP($scope);
	return $scope;
}

sub declare_object($scope, $object) {
	NOTE("Declaring object '", $object.name(), "' in ", $scope<lstype>, " scope '", $scope.name(), "'");
	my $name	:= $object.name();
	my $already	:= get_symbol($scope, $name);
	
	if $already {
		# FIXME: Should check for compatible types, like a redeclaration:
		# extern int X; and int X = 1;
		NOTE("Found repeated declaration of object: ", $object.name());
		close::Compiler::Messages::add_error($object, 
			'Repeated declaration of symbol \'' ~ $name ~ '\'');
	}
	else {
		set_symbol($scope, $name, $object);
	}

	DUMP($object);
}

sub dump_stack() {
	DUMP(@Scope_stack);
}

sub fetch_current_hll() {
	my $hll	:= 'close';	
	my $block	:= query_inmost_scope_with_attr('hll');
	
	if $block {
		$hll	:= $block.hll();
	}
	
	return $hll;
}

sub fetch_current_namespace() {
	my $block := query_inmost_scope_with_attr('is_namespace');

	unless $block {
		dump_stack();
		DIE("INTERNAL ERROR: "
			~ "Unable to locate current namespace block. "
			~ " This should never happen.");
	}
	
	DUMP($block);
	return $block;
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

sub get_namespace($scope, $name) {
	my $namespace := $scope.symbol($name)<namespace>;
	DUMP(:name($name), :result($namespace));
	return $namespace;
}

=sub get_search_list

Returns a copy of the lexical stack - so it can be destroyed - arranged in the 
correct order for searching. The first element of the returned array is the 
top of the lexical stack, the last element is the bottom of the stack, etc.

=cut

sub get_search_list() {
	my @list := Array::empty();
	
	for get_stack() {
		@list.push($_);
		
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

our @Scope_stack;

sub get_stack() {
	unless @Scope_stack {
		@Scope_stack := Array::empty();
	}

	DUMP(@Scope_stack);
	return @Scope_stack;
}

sub get_symbol($scope, $name) {
	my $object := $scope.symbol($name)<symbol>;
	DUMP(:name($name), :result($object));
	return $object;
}

sub pop($type) {
	my $old := get_stack().shift();
	my $old_type := close::Compiler::Node::type($old);
	
	unless $type eq $old_type {
		DIE("Scope stack mismatch. Popped '"
			~ $old_type ~ "', but expected '"
			~ $type);
	}
	
	DUMP($old);
	return $old;
}

sub print_symbol_table($block) {
	NOTE("printing...");
	
	for $block<symtable> {
		close::Compiler::Symbols::print_symbol(get_symbol($block, $_));
		DUMP($block);
	}
	
	NOTE("finished");
}

sub push($scope) {
	unless $scope.isa(PAST::Block) {
		DIE("Attempt to push non-Block on lexical scope stack.");
	}

	get_stack().unshift($scope);
	NOTE("Open ", $scope<lstype>, " scope: ", $scope.name(),
		" Now ", +(get_stack()), " on stack.");
	DUMP($scope);
}

sub push_namespace(@path) {
	my $nsp := close::Compiler::Namespaces::fetch(@path);
	DUMP($nsp);
	push($nsp);
}

sub set_namespace($scope, $name, $namespace) {
	$scope.symbol($name, :namespace($namespace));
}

sub set_symbol($scope, $name, $object) {
	$scope.symbol($name, :symbol($object));
}
