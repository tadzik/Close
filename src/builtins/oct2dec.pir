# $Id$

=head1 Convert 0777 style literal into decimal value.

=cut
.sub '_oct2dec'
	.param string token
	.local int decimal, pos

	decimal = 0
	pos     = 0

  next_char:

	$S0 = substr token, pos, 1
	$I0 = index '01234567', $S0

	if $I0 < 0 goto done

	decimal *= 8
	decimal += $I0

	goto next_char

  done:
	.return (decimal)
.end
