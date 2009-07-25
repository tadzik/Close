extern int print();

void test()
{
	print("1..4\n");

	asm {{
	print "ok 1 - print from asm\n"
	}};

	print("ok 2 - print continuous strings\n");
	print("ok", " 3", " - ", "print separate pieces", "\n");
	print("ok ", 4, " - print numbers, too\n");
}

void _runner() :init :load { test(); }
