# Check basic literals.
extern int print();
extern void plan();

extern void test_literals()
{
	plan(20);

	print("ok 1 - string literal\n");
	print("ok ", "2", " - separate strings\n");
	print("ok ", '3', " - single-quoted string\n");
	print("ok ", 4, " - decimal constant\n");
	print("ok ", 0o5, " - octal constant\n");
	print("ok ", 0x6, " - hexadecimal\n");
	print("ok ", 0x07, " - hex, leading 0\n");
	print("ok ", 0b01000, " - binary\n");
	print("ok ", 9L, " - long, cap-L\n");
	print("ok ", 10l, " - long, small-l\n");
	print("ok ", 0o13U, " - octal, unsigned, cap-U\n");
	print("ok ", 0xCu, " - hex, unsigned, lower-u\n");
	print("ok ", 13LU, " - LU\n");
	print("ok ", 14UL, " - UL\n");
	print("ok ", 15lu, " - lu\n");
	print("ok ", 16ul, " - ul\n");
	print("ok ", 17lU, " - lU\n");
	print("ok ", 18uL, " - uL\n");
	print("ok ", 19Lu, " - Lu\n");
	print("ok ", 20Ul, " - Ul\n");

}

extern void _runner() :init { test_literals(); }
