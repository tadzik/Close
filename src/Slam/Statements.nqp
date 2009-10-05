# $Id: Statements.nqp 170 2009-09-28 10:53:40Z austin_hastings@yahoo.com $

module Slam::Statement {

	Parrot::IMPORT('Dumper');
		
	################################################################

=sub _onload

This code runs at initload time, creating subclasses.

=cut

	_onload();

	sub _onload() {
		if our $onload_done { return 0; }
		$onload_done := 1;

		NOTE("Creating base class Slam::Statement");
		my $stmts := Class::NEW_CLASS('Slam::Statement');

		NOTE("Creating subclass Slam::Statement::Block");
		Class::SUBCLASS('Slam::Statement::Block', 
			'Slam::Block', 'Slam::Statement');

		NOTE("Creating subclass Slam::Statement::Null");
		Class::SUBCLASS('Slam::Statement::Null',
			'Slam::Stmts', 'Slam::Statement');
		
		NOTE("Creating class Slam::Statement::SymbolDeclarationList");
		Class::SUBCLASS('Slam::Statement::SymbolDeclarationList', 
			'Slam::VarList', 'Slam::Statement');
			
		NOTE("Creating subclass Slam::Statement::UsingNamespace");
		Class::SUBCLASS('Slam::Statement::UsingNamespace', 
			'Slam::Stmts', 'Slam::Statement');
	}

	################################################################

	method is_statement()			{ return 1; }
}

################################################################

module Slam::Statement::Block {
}

################################################################

module Slam::Statement::Null {
}

################################################################

module Slam::Statement::SymbolDeclarationList {

	Parrot::IMPORT('Dumper');
		
	################################################################

	method attach_to($parent) {
		ASSERT($parent.isa(Slam::Scope), 
			'Declarations must attach to a scope.');
		ASSERT($parent =:= Registry<SYMTAB>.current_scope,
			'Parent scope should still be current. Why not?');
		
		$parent.push(self);
		
		NOTE("Declaring symbols in ", $parent);
		DUMP($parent);
		
		for @(self) {
			Registry<SYMTAB>.declare($_);
		}
	}
}

################################################################

module Slam::Statement::UsingNamespace {
	method attach_to($parent) {
		ASSERT($parent.is_scope, 
			'UsingNamespace statements may only attach to a scope.');
		$parent.add_using_namespace(self);
		$parent.push(self);
	}
	
	method using_namespace(*@value) { self.ATTR('using_namespace', @value); }
}