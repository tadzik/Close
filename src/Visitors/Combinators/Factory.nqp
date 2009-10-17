# $Id: $

module Visitor::Combinator::Factory;

_ONLOAD();

sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
}

sub All(*@children, *%opts) {
	my $result := Class::call_method_(
		Visitor::Combinator::All, 'new', @children, %opts);
	return $result;
}

sub Choice(*@children, *%opts) {
	my $result := Class::call_method_(
		Visitor::Combinator::Choice, 'new', @children, %opts);
	return $result;
}

sub Defined($definition) {
	my $result := Visitor::Combinator::Defined.new($definition);
	return $result;
}

sub Fail() {
	my $result := Visitor::Combinator::Fail.new();
	return $result;
}

sub Identity() {
	my $result := Visitor::Combinator::Identity.new();
	return $result;
}

sub Sequence(*@children, *%opts) {
	my $result := Class::call_method_(
		Visitor::Combinator::Sequence, 'new', @children, %opts);	
	return $result;
}

sub TopDown($v) {
	my $result := Visitor::Combinator::TopDown.new($v);
	return $result;
}

sub TopDownUntil($v) {
	my $result := Visitor::Combinator::TopDownUntil.new($v);
	return $result;
}

sub VisitOnce($v) {
	my $result := Visitor::Combinator::VisitOnce.new($v);
	return $result;
}

