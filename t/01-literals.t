// Check basic literals.
namespace close::test01 {

	void plan(int how_many) {
		say("1..", how_many);
	}
	
	void say(string args...) {
		asm(args) {{
			$P0 = iter %0
		loop:
			unless $P0 goto done
			$P1 = shift $P0
			$S0 = $P1
			print $S0
			goto loop
			
		done:
			print "\n"			
		}};
	}

	void test() :main
	{
		plan(20);

		say("ok 1 - string literal");
		say("ok ", "2", " - separate strings");
		say("ok ", '3', " - single-quoted string");
		say("ok ", 4, " - decimal constant");
		say("ok ", 0o5, " - octal constant");
		say("ok ", 0x6, " - hexadecimal");
		say("ok ", 0x07, " - hex, leading 0");
		say("ok ", 0b01000, " - binary");
		say("ok ", 9L, " - long, cap-L");
		say("ok ", 10l, " - long, small-l");
		say("ok ", 0o13U, " - octal, unsigned, cap-U");
		say("ok ", 0xCu, " - hex, unsigned, lower-u");
		say("ok ", 13LU, " - LU");
		say("ok ", 14UL, " - UL");
		say("ok ", 15lu, " - lu");
		say("ok ", 16ul, " - ul");
		say("ok ", 17lU, " - lU");
		say("ok ", 18uL, " - uL");
		say("ok ", 19Lu, " - Lu");
		say("ok ", 20Ul, " - Ul");
	}
}
