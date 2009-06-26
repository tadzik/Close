=item substr()

=cut

.namespace []

.sub 'substr' :method :multi(_, _)
	.param int start
	.param int len             :optional
	.param int has_len         :opt_flag

	.local int str_len
	$S0 = self
	str_len = length $S0

	if has_len goto have_len
	len = str_len
    have_len:
	if len >= 0 goto len_done
	if start < 0 goto neg_start
	len += str_len
    neg_start:
	len -= start
    len_done:
	push_eh fail
	$S1 = substr $S0, start, len
	pop_eh
	.return ($S1)
    fail:
	.get_results($P0)
	pop_eh
	.tailcall '!FAIL'($P0)
.end

.sub 'split'
	.param string delim
	.param string str

	$P0 = split delim, str
	.return($P0)
.end
