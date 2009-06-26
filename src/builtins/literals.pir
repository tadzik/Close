# $Id$

=head1

literals.pir -- helper functions for processing literals

=head2

_hex2dec -- Convert 0xDeadBeef -style literal into decimal value.

=cut

.namespace []

.sub '_hex2dec'
	.param string token

	$S0 = substr token, 2
	downcase $S0
	$I0 = '_lit2dec'($S0, '0123456789abcdef')
	.return ($I0)
.end

=head2

_oct2dec -- Convert 0777 style literal into decimal value.

=cut

.sub '_oct2dec'
	.param string token

	$I0 = '_lit2dec'(token, '01234567')
	.return ($I0)
.end

=head2

_lit2dec -- Convert any radix literal to decimal value.

=cut

.sub '_lit2dec'
	.param string token
	.param string radix_chars

	.local string ch
	.local int pos, radix, result

	pos    = 0
	radix  = length radix_chars
	result = 0

  next_ch:
    ch = substr token, pos, 1
	inc pos

	$I0 = index radix_chars, ch
	if $I0 < 0 goto done

	result *= radix
	result += $I0

	goto next_ch

  done:
	.return (result)
.end
