hll close;
namespace ::;

int _Crt_started = 0;

extern void crt_init();

void _crt_start()
{
	unless (_Crt_started) {
		_Crt_started = 1;
		#tailcall
		crt_init();
	}
}

void _crt_start_init() :init { _crt_start(); }
void _crt_start_load() :load { _crt_start(); }

void load(pmc filename)
{
	pmc fname = filename;
	asm(fname) {{
		push_eh failed
		$S0 = %0
		load_bytecode $S0
		pop_eh
		.return()
	failed:
		pop_eh
		die "image not found"
	}};
}

extern int print();

void crt_init()
{
	asm {{ print "Loading close library\n" }};
	load("close_lib.pir");
	#print("Loading done\n");
}

hll close;  # In case --combine is used.
