namespace close::test00 {
	void say(string what) {
		asm(what) {{	say %0 }};
	}
	
	void say2(string args...) {
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
	
	void test()
		:main
	{
		asm {{ say "1..5" }};
		
		asm {{ say "ok 1 - say from asm" }};
		asm {{ print "ok 2 - print from asm\n" }};
		
		say("ok 3 - local function, continuous string");
		
		say2("ok ", "4 - ", "local function, separate strings");
		
		say2("ok ", 5, " - local function, numbers, too.");
	}
}
