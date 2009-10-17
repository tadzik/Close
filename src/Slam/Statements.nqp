# $Id: Statements.nqp 170 2009-09-28 10:53:40Z austin_hastings@yahoo.com $

module Slam::Statement {

	Parrot::IMPORT('Dumper');
		
	################################################################

=sub _onload

This code runs at initload time, creating subclasses.

=cut

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;

		NOTE("Creating base class Slam::Statement");
		my $stmts := Class::NEW_CLASS('Slam::Statement');

		my %statement_classes := Hash::new(
			:Null(			'Slam::Stmts'),
			:Return(		'Slam::Op'),
			:SymbolDeclarationList('Slam::VarList'),
			:UsingNamespace(	'Slam::Stmts'),
		);
		
		for %statement_classes {
			my $class_name := 'Slam::Statement::' ~ $_;
			my $parent_class := %statement_classes{$_};
			
			NOTE("Creating subclass ", $class_name);
			Class::SUBCLASS($class_name, 
				$parent_class, 'Slam::Statement');
		}
	}

	################################################################

	method is_statement()			{ return 1; }
}

################################################################

module Slam::Statement::Null {
}

################################################################

module Slam::Statement::Return {
}

################################################################

module Slam::Statement::SymbolDeclarationList {

	Parrot::IMPORT('Dumper');
		
	################################################################

}

################################################################

module Slam::Statement::UsingNamespace {
	method using_namespace(*@value) { self._ATTR('using_namespace', @value); }
}