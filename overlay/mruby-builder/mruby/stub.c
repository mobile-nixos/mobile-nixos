#include <mruby.h>
#include <mruby/irep.h>
#include "irep.c"
#include <stdlib.h>

int
main(void)
{
	mrb_state *mrb = mrb_open();
	if (!mrb) {
		/* handle error */
		printf("[FATAL] Could not open mruby.\n");
		exit(1);
	}
	mrb_load_irep(mrb, ruby_irep);

	if (mrb->exc) {
		mrb_print_backtrace(mrb);
		mrb_print_error(mrb);
		mrb_close(mrb);
		exit(1);
	}

	mrb_close(mrb);
	return 0;
}

