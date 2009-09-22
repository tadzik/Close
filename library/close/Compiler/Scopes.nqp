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

=sub add_declarator_to_scope($scope, $declaration)

Insert a single declarator-name into the symbol table for a block.

=cut

sub add_declarator_to($past, $scope) {
	NOTE("Adding name '", $past.name(), "' to ", NODE_TYPE($scope), " scope '", $scope.name(), "'");
	my $name := $past.name();
	my @already := get_symbols($scope, $name);
	
	#unless $past<hll> {
	#	$past<hll> := $scope<hll>;
	#	$past.namespace($scope.namespace());
	#}
		
	if +@already {
		# This is not a problem if declaring two multi- functions.
		my $all_multi := 1;
		
		for @already {
			unless Hash::exists($_<adverbs>, 'multi') {
				$all_multi := 0;
			}
		}
		
		# FIXME: Need to check for redeclaration of same (compatible) 
		# symbol, too. extern int x; and int x = 1; for example.
		# Don't know how to do that yet. See Types.pm.
		
		unless $all_multi {
			ADD_ERROR($past,
				"Conflicting declaration of symbol '",
				$past.name(), "' in scope '",
				$scope<display_name>, "'.  ",
				"Only :multi() subs or redeclarations of the same symbol are allowed to duplicate names."
			);
		}
	}
	
	put_symbol($scope, $name, $past);
}

sub add_declarator($past) {
	NOTE("Adding declarator: ", $past.name());
	DUMP($past);
	ASSERT(NODE_TYPE($past) eq 'declarator_name',
		"Only declarators can be added.");
	
	my $decl_nsp := close::Compiler::Namespaces::fetch_namespace_of($past);
	my $current_nsp := close::Compiler::Scopes::fetch_current_namespace();
	
	if $decl_nsp =:= $current_nsp {
		$decl_nsp := close::Compiler::Scopes::current();
	}
	
	add_declarator_to($past, $decl_nsp);
}
		
sub add_declarator_to_current($past) {
	my $scope := current();
	NOTE("Adding name '", $past.name(), "' to ", $scope<lstype>, " scope '", $scope.name(), "'");
	add_declarator_to($past, $scope);
}

sub add_using_namespace($scope, $using_nsp) {
	ASSERT(NODE_TYPE($using_nsp) eq 'using_directive',
		'This is only valid for using_directives');
		
	my $nsp := $using_nsp<using_namespace>;
	NOTE("Adding namespace '", $nsp<display_name>, "' to ", NODE_TYPE($scope), 
		" scope '", $scope.name(), "'");
	
	if $scope<using_namespaces> {
		my $found := 0;
		
		for $scope<using_namespaces> {
			if $_ =:= $nsp {
				$found := 1;
				NOTE("Already present");
				ADD_WARNING($using_nsp,
					"Using namespace directive is redundant.");
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
	add_declarator_to($object, $scope);
}

sub dump_stack() {
	DUMP(get_stack());
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

sub current_file() {
	my $filename := Q:PIR {
		%r = find_dynamic_lex '$?FILES'
	};
	
	return $filename;
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
	my $namespace := $scope<child_nsp>{$name};
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
		my $block := $_;
		
		if $block<is_namespace>{
			my @path := close::Compiler::Namespaces::path_of($block);
			$block := close::Compiler::Namespaces::fetch(@path);
		}
		
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
	
	unless Scalar::defined($init_done) {
		$init_done := 1;
		my $pervasive := PAST::Block.new(
			:blocktype('immediate'),
			:name('pervasive types'),
			:hll('close'),
			:namespace(Scalar::undef()),
		);
		$pervasive<node_type> := 'pervasive scope';
		@scope_stack := Array::new($pervasive);
		close::Compiler::Types::add_builtins($pervasive);
		
		NOTE("Creating (implicit) root namespace_definition block");
		my $root_nsp	:= close::Compiler::Node::create('namespace_definition',
			:path(Array::empty()),
		);
		close::Compiler::Scopes::push($root_nsp);
	}

	DUMP(@scope_stack);
	return @scope_stack;
}

sub get_symbols($scope, $name) {
	my @symbols := $scope<child_sym>{$name};
	DUMP(:name($name), :result(@symbols));
	return @symbols;
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
	
	for $block<child_sym> {
		for get_symbols($block, $_) {
			close::Compiler::Symbols::print_symbol($_) ;
		}
		
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

sub put_symbol($scope, $name, $object) {
	NOTE("Adding symbol ", $name, " to scope ", $scope.name());
	
	unless Hash::exists($scope<child_sym>, $name) {
		$scope<child_sym>{$name} := Array::empty();
	}
	
	my $found := 0;
	
	for $scope<child_sym>{$name} {
		if $_ =:= $object {
			NOTE("This object is already present. Skipping.");
			$found := 1;
		}
	}
	
	unless $found {
		$scope<child_sym>{$name}.push($object);
	}
	
	DUMP($scope<child_sym>{$name});
}

sub set_namespace($scope, $name, $namespace) {
	$scope<child_nsp>{$name} := $namespace;
}
