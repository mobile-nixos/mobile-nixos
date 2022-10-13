#include <stdlib.h>
#include <string.h>

#include <mruby.h>
#include <mruby/array.h>
#include <mruby/irep.h>
#include <mruby/variable.h>
#include <mruby/string.h>
#include <mruby/error.h>

// Declares main_mrb_state, but more importantly, defines it weakly
// so that if the stub does not provide it (or other mruby build does not)
// this module still builds and links.
mrb_state *main_mrb_state __attribute__ ((weak));

// https://github.com/mruby/mruby/blob/f9d113f7647121f8578742a2a9ac256ece365e3f/src/backtrace.c#L79-L101
static void
print_backtrace(mrb_state *mrb, mrb_value backtrace)
{
  mrb_int i;
  mrb_int n = RARRAY_LEN(backtrace);
  mrb_value *loc/*, mesg*/;
  FILE *stream = stderr;

  if (n != 0) {
    fprintf(stream, "trace (most recent call last):\n");
    for (i=n-1,loc=&RARRAY_PTR(backtrace)[i]; i>0; i--,loc--) {
      if (mrb_string_p(*loc)) {
        fprintf(stream, "\t[%d] %.*s\n",
                (int)i, (int)RSTRING_LEN(*loc), RSTRING_PTR(*loc));
      }
    }
    if (mrb_string_p(*loc)) {
      fprintf(stream, "\t[0] %.*s: ", (int)RSTRING_LEN(*loc), RSTRING_PTR(*loc));
    }
  }
}

void lv_debug_app_assert_handler(void)
{
	if (main_mrb_state != NULL) {
		fprintf(stderr, "\n--[ lv_debug_app_assert_handler() ]--\n");
		fprintf(stderr, "Backtrace:\n");
		print_backtrace(main_mrb_state, mrb_get_backtrace(main_mrb_state));
		mrb_close(main_mrb_state);
		fprintf(stderr, "\n--[===============================]--\n");
	}
	else {
		fprintf(stderr, "\nWarning: Could not get main_mrb_state to inspect mrb state.\n");
		fprintf(stderr, "         This may mean the mruby startup stub did not setup `main_mrb_state`.\n");
	}

	// Assume we always want to
	abort();
}

void
mrb_mruby_lvgui_native_fragment_gem_init(mrb_state *mrb)
{
	if (main_mrb_state != NULL) {
		fprintf(stderr, "Warning: mruby_lvgui_native_fragment_init clobbering previously defined mrb instance.\n");
		fprintf(stderr, "         backtraces from lvgui asserts may not be correct.\n");
	}
	main_mrb_state = mrb;
}

void
mrb_mruby_lvgui_native_fragment_gem_final(mrb_state *mrb)
{
	main_mrb_state = NULL;
}

