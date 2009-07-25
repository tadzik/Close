hll close;
namespace ::;

void print(pmc args ...)
{
	foreach (pmc item : args) {
		asm(item) {{ print %0 }};
	}
}

void say(pmc args ...)
{
	push args, "\n";

	foreach (pmc item : args) {
		asm(item) {{ print %0 }};
	}
}
