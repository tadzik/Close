# $Id$

=head1

optable.pir -- implementation of operators mentioned in optable

=cut

.namespace []

.sub 'infix:+='
	.param pmc	a
	.param pmc	b
	$P0 = add a, b
	assign a, $P0
	.return (a)
.end

.sub 'infix:,'
	.param pmc	a
	.param pmc	b
	.return (b)
.end
