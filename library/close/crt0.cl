# hll close;
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
		print "Loading '"
		print %0
		print "'\n"
		push_eh failed
		$S0 = %0
		load_bytecode $S0
		pop_eh
		.return()
	failed:
		get_results "0", $P0
		pop_eh
		$S0 = typeof $P0
		$S1 = $P0
		$S2 = "Bytecode for '"
		$S3 = %0
		concat $S2, $S3
		concat $S2, "' not loaded.\n"
		concat $S2, $S0
		concat $S2, ": "
		concat $S2, $S1
		concat $S2, "\n"
		die $S2
	}};
}

extern int print();

void crt_init()
{
	#asm {{ print "Loading close library\n" }};
	load("close_lib.pir");
	#print("Loading done\n");
}

# hll close;  # In case --combine is used.
