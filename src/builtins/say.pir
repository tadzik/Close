# $Id$

=head1

say.pir -- simple implementation of a say function

=cut

.namespace []

.sub 'print'
    .param pmc args            :slurpy
    .local pmc it
    it = iter args
  iter_loop:
    unless it goto iter_end
    $P0 = shift it
    print $P0
    goto iter_loop
  iter_end:
    .return ()
.end

.sub 'say'
	.param pmc args				:slurpy
	.tailcall 'print'(args :flat, "\n")
.end
