.namespace [ 'Slam' ; 'Grammar' ]

.sub '_onload' :anon :init :load
	.return ()
.end

=method ERROR

Inserts an <ERROR> token into the stream, so parser rules can recover from them.

=cut

.sub 'ERROR' :method
	.param string message
	.param pmc options :named :slurpy
	
	.local pmc mob, mfrom, mpos
	.local string target
	.local int pos
	(mob) = self.'new'(self, options :flat :named)
	
	mob.'to'(pos)
	
	# Find the action method for this rule.
	$P0 = options['action']
	if null $P0 goto no_action
	
	$I1 = can $P0, 'ERROR'
	if $I1 == 0 goto no_action
	
	$P0.'ERROR'(mob, message)
	.return (mob)
	
no_action:
	die "Unable find action method 'ERROR'"
.end