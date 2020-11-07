#include <stdlib.h>
#include <string.h>

#include <mruby.h>
#include <mruby/array.h>
#include <mruby/irep.h>
#include <mruby/variable.h>

// Assumes this is produced by builder.nix
#include "irep.c"

int
main(int argc, char **argv)
{
	int i;
	mrb_value ARGV;
	mrb_sym dollar_zero;
	mrb_sym program_name;
	mrb_state *mrb = mrb_open();

	if (!mrb) {
		/* handle error */
		printf("[FATAL] Could not open mruby.\n");
		exit(1);
	}

	ARGV = mrb_ary_new_capa(mrb, argc);
	// Skip the program name here.
	for (i = 1; i < argc; i++) {
		mrb_ary_push(mrb, ARGV, mrb_str_new(mrb, argv[i], strlen(argv[i])));
	}
	mrb_define_global_const(mrb, "ARGV", ARGV);

	// $0
	dollar_zero = mrb_intern_lit(mrb, "$0");
	mrb_gv_set(mrb, dollar_zero, mrb_str_new(mrb, argv[0], strlen(argv[0])));

	// $PROGRAM_NAME
	program_name = mrb_intern_lit(mrb, "$PROGRAM_NAME");
	mrb_gv_set(mrb, program_name, mrb_str_new(mrb, argv[0], strlen(argv[0])));

	mrb_load_irep(mrb, ruby_irep);

	if (mrb->exc) {
		mrb_print_backtrace(mrb);
		mrb_close(mrb);
		exit(1);
	}

	mrb_close(mrb);
	return 0;
}

