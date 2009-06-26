# $Id$

=head1

say.pir -- simple implementation of a say function

=cut

.namespace []

.sub 'print'
    .param pmc args            :slurpy
    .local pmc iter
    iter = new 'Iterator', args
  iter_loop:
    unless iter goto iter_end
    $P0 = shift iter
    print $P0
    goto iter_loop
  iter_end:
    .return ()
.end

.sub 'say'
	.param pmc args				:slurpy
	.tailcall 'print'(args :flat, "\n")
.end
