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

=sub add_declarator_to_scope($scope, $declaration)

Hooks a declaration in to a scope block. Adds the declaration to the block's 
children -- the declaration is a PAST::VarList. Adds each individual
declarator to the block's symbol table. Returns nothing.

=cut

sub add_declarator($scope, $past) {
	NOTE("Adding name '", $past.name(), "' to ", $scope<lstype>, " scope '", $scope.name(), "'");
	my $name := $past.name();
	my $already := get_object($scope, $name);
	
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
		set_object($scope, $name, $past);
	}
}

sub add_declarator_to_current($past) {
	my $scope := current();
	NOTE("Adding name '", $past.name(), "' to ", $scope<lstype>, " scope '", $scope.name(), "'");
	add_declarator($scope, $past);
}

sub add_varlist_symbols($past) {
	unless $past.isa(PAST::VarList) {
		DUMP($past);
		DIE("Parameter $past must be a PAST::VarList");
	}
	
	my $scope := current();
	
	for @($past) {
		declare_object($scope, $_);
	}
	
	DUMP($scope);
}

sub current() {
	my $scope := get_stack()[0];
	DUMP($scope);
	return $scope;
}

sub declare_object($scope, $object) {
	NOTE("Declaring object '", $object.name(), "' in ", $scope<lstype>, " scope '", $scope.name(), "'");
	my $name	:= $object.name();
	my $already	:= get_object($scope, $name);
	
	if $already {
		# FIXME: Should check for compatible types, like a redeclaration:
		# extern int X; and int X = 1;
		NOTE("Found repeated declaration of object: ", $object.name());
		close::Compiler::Messages::add_error($object, 
			'Repeated declaration of symbol \'' ~ $name ~ '\'');
	}
	else {
		set_object($scope, $name, $object);
	}

	$scope.push($object);
	DUMP($object);
}

sub dump_stack() {
	DUMP(@Scope_stack);
}

=sub fetch_pervasive_scope()

Opens the "magic" pervasive-symbols lexical scope, which serves as the backstop
for all other lexical scopes. Stores the resulting block in the $Pervasive_symbols 
global, for immediate lookup by builtins, etc.

=cut

our $Pervasive_scope;

sub fetch_pervasive_scope() {
	unless $Pervasive_scope {
		$Pervasive_scope := PAST::Block.new(
			:blocktype('immediate'),
			:name("Pervasive Symbols"),
		);
		$Pervasive_scope<lstype> := 'pervasive scope';
		
		close::Compiler::Types::add_builtins($Pervasive_scope);
	
		# FIXME: Move these to be typedefs in a standard namespace. (Then kill 'em.)
		#my $bug := make_alias('num', $psym.symbol('float')<decl>, $psym);
		#$bug := make_alias('str', $psym.symbol('string')<decl>, $psym);
	}
	
	DUMP($Pervasive_scope);
	return $Pervasive_scope;
}

sub fetch_current_hll() {
	my $hll	:= 'close';	
	my $block	:= find_matching('hll');
	
	if $block {
		$hll	:= $block.hll();
	}
	
	return $hll;
}

sub fetch_current_namespace() {
	my $block := find_matching('is_namespace');

	unless $block {
		DIE("INTERNAL ERROR: "
			~ "Unable to locate current namespace block. "
			~ " This should never happen.");
	}
	
	DUMP($block);
	return $block;
}

sub find_matching($attr) {
	for get_search_list() {
		if $_{$attr} {
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

sub get_object($scope, $name) {
	my $object := $scope.symbol($name)<object>;
	DUMP(:name($name), :result($object));
	return $object;
}

sub get_search_list() {
	my @list := Array::clone(get_stack());
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

sub new($lstype) {
	NOTE("Creating new scope block with lstype='", $lstype, "'");
	my $block := PAST::Block.new(:blocktype('immediate'));
	$block<lstype> := $lstype;
	DUMP($block);
	return $block;
}

sub pop($lstype) {
	my $old := get_stack().shift();
	
	unless $lstype eq $old<lstype> {
		DIE("Scope stack mismatch. Popped '"
			~ $old<lstype> ~ "', but expected '"
			~ $lstype);
	}
	
	DUMP($old);
	return $old;
}

sub print_symbol_table($block) {
	NOTE("printing...");
	
	for $block<symtable> {
		close::Compiler::Symbols::print_symbol(get_object($block, $_));
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

=sub void resolve_qualified_identifier($root, @identifier)

Returns a list of candidates that match the components in the given qualified
C<@identifier> relative to C<$root>. 

There are three possible ways to decode 'B' in a scenario like C<B::C>. The 
first is that B might be a namespace. The second is that B might be an aggregate
type -- a class, struct, union, or enum. And the third is that B might be an 
alias for another type.

If B is a namespace, then our options are still open for C -- it could be anything.

If B is an aggregate, then C gets resolved as a member, a method, or a member
type (e.g., C<typedef int C> within the class). In any case, B must have a 
symtable entry for C.

If B is an alias for another type or namespace, see above.

=cut

sub resolve_qualified_identifier($root, @identifier) {
	my @candq := new_array();
	@candq.push($root);
	
	for @identifier {
		my $id_part := $_;
		say("Part: ", $id_part);
		my $num_cands := +@candq;
		say("# candidates at this level: ", $num_cands);
		
		while $num_cands-- {
			my $scope	:= @candq.shift();
			say("Scope: ", $scope.name());
			if ! $scope.isa(PAST::Block) {
				say("Dead end at ", $scope.name());
			}
			else {
				my $sym	:= $scope.symbol($id_part);
		
				# Handle functions, variables, types.
				if $sym && $sym<decl> {
					if $sym<decl><is_alias> {
						say("Found alias");
						@candq.push($sym<decl><alias_for>);
					}
					else {
						say("Found plain symbol");
						@candq.push($sym<decl>);
					}
				}
				
				# Handle namespaces
				if $sym && $sym<namespace> {
					@candq.push($sym<namespace>);
				}
			}
		}
	}

	DUMP(@candq);
	return @candq;
}

sub set_namespace($scope, $name, $namespace) {
	$scope.symbol($name, :namespace($namespace));
}

sub set_object($scope, $name, $object) {
	$scope.symbol($name, :object($object));
}

sub symbol_defined_anywhere($past) {
	if $past.scope() ne 'package' {
		my $name := $past.name();
		my $def;

		for get_stack() {
			$def := $_.symbol($name);

			if $def {
				if $def<decl>.HOW.can($def<decl>, "scope") {
					#say("--- FOUND: ", $def<decl>.scope());
				}
				elsif $def<decl>.isa("PAST::Block") {
					#say("--- FOUND: Block");
				}
				else {
					#say("--- FOUND in unrecognized object:");
					#DUMP($def<decl>, "Declaration");
					DIE("Unexpected data item");
				}

				return $def;
			}
		}
	}

	# Not any kind of local variable, parameter, etc. Try global.
	return get_global_symbol_info($past);
}
