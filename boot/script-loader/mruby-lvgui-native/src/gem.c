////////////////////////////////////////////////////////////////////////////////
// Header                                                                     //
////////////////////////////////////////////////////////////////////////////////
//

#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <mruby.h>
#include <mruby/data.h>
#include <mruby/hash.h>
#include <mruby/string.h>
#include <mruby/value.h>
#include <mruby/variable.h>
#include <lv_drv_conf.h>
#include <lv_conf.h>
#include <lvgl/lvgl.h>
#include <lv_lib_bmp/lv_bmp.h>
#include <lv_lib_nanosvg/lv_nanosvg.h>
#include <font.h>
#include <hal.h>
#include <introspection.h>
#include <lvgui_struct_accessors.h>
// Workaround those globals only existing with the simulator
#if USE_MONITOR
  extern int monitor_width;
  extern int monitor_height;
#else
  static int monitor_width;
  static int monitor_height;
#endif

extern int mn_hal_default_dpi;
extern void * mn_hal_default_font;


//
////////////////////////////////////////////////////////////////////////////////

#define DONE mrb_gc_arena_restore(mrb, 0);

////////////////////////////////////////////////////////////////////////////////
// Globals                                                                    //
////////////////////////////////////////////////////////////////////////////////
//

struct RClass *mLVGUI__Native;
mrb_value mLVGUI__Native__References;

//
////////////////////////////////////////////////////////////////////////////////

//
// Opaque Pointer
//

struct RClass *mLVGUI__Native__OpaquePointer;

typedef struct mrb_mruby_lvgui_native_native_ref_ {
  void* ptr;
} mrb_mruby_lvgui_native_native_ref;

static void mrb_mruby_lvgui_native_destructor(mrb_state *mrb, void *p_) {
  // No-op by design;
  // We assume all pointers are owned by the C code.
  // If data evades the sight of the garbage collector, it's
  // highly likely still in use in the native implementation.
#ifdef GC_DEBUG
  fprintf(stderr, "[%s] GC is Freeing an Opaque Pointer (We're letting it slip away).\n", "mrb_mruby_lvgui_native");
#endif
};

const struct mrb_data_type mLVGUI__Native__OpaquePointer_type = {
  "mrb_mruby_lvgui_native_data", mrb_mruby_lvgui_native_destructor
};

// TODO wrap/unwrap helpers per distinct pointer types
static inline mrb_value
mrb_mruby_lvgui_native_wrap_pointer(mrb_state * mrb, void * ptr)
{
  mrb_value opaque_pointer;
  mrb_mruby_lvgui_native_native_ref* ref;

  // Put the pointer in a box
  ref = (mrb_mruby_lvgui_native_native_ref*)calloc(1, sizeof(mrb_mruby_lvgui_native_native_ref));
  ref->ptr = ptr;

  // Attach our box to an OpaquePointer instance
  opaque_pointer = mrb_obj_value(
    Data_Wrap_Struct(
      mrb,
      mLVGUI__Native__OpaquePointer,
      &mLVGUI__Native__OpaquePointer_type,
      ref
    )
  );

#ifdef GC_DEBUG
  fprintf(stderr, "[%s] Wrapping: ptr<%p> in OpaquePointer\n", "mrb_mruby_lvgui_native", ptr);
#endif

  return opaque_pointer;
}

// TODO wrap/unwrap helpers per distinct pointer types
static inline void *
mrb_mruby_lvgui_native_unwrap_pointer(mrb_state * mrb, const mrb_value opaque_pointer)
{
  mrb_mruby_lvgui_native_native_ref* ref = NULL;
  void * ptr = NULL;

  if (mrb_nil_p(opaque_pointer)) {
    return NULL;
  }

  // Get our box from the OpaquePointer instance
  Data_Get_Struct(
    mrb,
    opaque_pointer,
    &mLVGUI__Native__OpaquePointer_type,
    ref
  );

  // Pick pointer out from inside the box.
  ptr = ref->ptr;

#ifdef GC_DEBUG
  fprintf(stderr, "[%s] Unwrapping: ptr<%p> from OpaquePointer\n", "mrb_mruby_lvgui_native", ptr);
#endif

  return ptr;
}

////////////////////////////////////////////////////////////////////////////////
// Binding definitions                                                        //
////////////////////////////////////////////////////////////////////////////////
//

////////
// Bindings for: `enum LV_ALIGN;`

void
mrb_mruby_lvgui_native_enum_lv_align(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_ALIGN");

  // CENTER = 0;                                                   
  mrb_define_const(mrb, module, "CENTER", mrb_fixnum_value(0));
  
  // IN_TOP_LEFT = 1;                                                   
  mrb_define_const(mrb, module, "IN_TOP_LEFT", mrb_fixnum_value(1));
  
  // IN_TOP_MID = 2;                                                   
  mrb_define_const(mrb, module, "IN_TOP_MID", mrb_fixnum_value(2));
  
  // IN_TOP_RIGHT = 3;                                                   
  mrb_define_const(mrb, module, "IN_TOP_RIGHT", mrb_fixnum_value(3));
  
  // IN_BOTTOM_LEFT = 4;                                                   
  mrb_define_const(mrb, module, "IN_BOTTOM_LEFT", mrb_fixnum_value(4));
  
  // IN_BOTTOM_MID = 5;                                                   
  mrb_define_const(mrb, module, "IN_BOTTOM_MID", mrb_fixnum_value(5));
  
  // IN_BOTTOM_RIGHT = 6;                                                   
  mrb_define_const(mrb, module, "IN_BOTTOM_RIGHT", mrb_fixnum_value(6));
  
  // IN_LEFT_MID = 7;                                                   
  mrb_define_const(mrb, module, "IN_LEFT_MID", mrb_fixnum_value(7));
  
  // IN_RIGHT_MID = 8;                                                   
  mrb_define_const(mrb, module, "IN_RIGHT_MID", mrb_fixnum_value(8));
  
  // OUT_TOP_LEFT = 9;                                                   
  mrb_define_const(mrb, module, "OUT_TOP_LEFT", mrb_fixnum_value(9));
  
  // OUT_TOP_MID = 10;                                                   
  mrb_define_const(mrb, module, "OUT_TOP_MID", mrb_fixnum_value(10));
  
  // OUT_TOP_RIGHT = 11;                                                   
  mrb_define_const(mrb, module, "OUT_TOP_RIGHT", mrb_fixnum_value(11));
  
  // OUT_BOTTOM_LEFT = 12;                                                   
  mrb_define_const(mrb, module, "OUT_BOTTOM_LEFT", mrb_fixnum_value(12));
  
  // OUT_BOTTOM_MID = 13;                                                   
  mrb_define_const(mrb, module, "OUT_BOTTOM_MID", mrb_fixnum_value(13));
  
  // OUT_BOTTOM_RIGHT = 14;                                                   
  mrb_define_const(mrb, module, "OUT_BOTTOM_RIGHT", mrb_fixnum_value(14));
  
  // OUT_LEFT_TOP = 15;                                                   
  mrb_define_const(mrb, module, "OUT_LEFT_TOP", mrb_fixnum_value(15));
  
  // OUT_LEFT_MID = 16;                                                   
  mrb_define_const(mrb, module, "OUT_LEFT_MID", mrb_fixnum_value(16));
  
  // OUT_LEFT_BOTTOM = 17;                                                   
  mrb_define_const(mrb, module, "OUT_LEFT_BOTTOM", mrb_fixnum_value(17));
  
  // OUT_RIGHT_TOP = 18;                                                   
  mrb_define_const(mrb, module, "OUT_RIGHT_TOP", mrb_fixnum_value(18));
  
  // OUT_RIGHT_MID = 19;                                                   
  mrb_define_const(mrb, module, "OUT_RIGHT_MID", mrb_fixnum_value(19));
  
  // OUT_RIGHT_BOTTOM = 20;                                                   
  mrb_define_const(mrb, module, "OUT_RIGHT_BOTTOM", mrb_fixnum_value(20));
}

//
////////
////////
// Bindings for: `enum LV_ANIM;`

void
mrb_mruby_lvgui_native_enum_lv_anim(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_ANIM");

  // OFF = 0;                                                   
  mrb_define_const(mrb, module, "OFF", mrb_fixnum_value(0));
  
  // ON = 1;                                                   
  mrb_define_const(mrb, module, "ON", mrb_fixnum_value(1));
}

//
////////
////////
// Bindings for: `enum LV_ARC_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_arc_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_ARC_STYLE");

  // MAIN = 0;                                                   
  mrb_define_const(mrb, module, "MAIN", mrb_fixnum_value(0));
}

//
////////
////////
// Bindings for: `enum LV_BAR_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_bar_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_BAR_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // INDIC = 1;                                                   
  mrb_define_const(mrb, module, "INDIC", mrb_fixnum_value(1));
}

//
////////
////////
// Bindings for: `enum LV_BORDER;`

void
mrb_mruby_lvgui_native_enum_lv_border(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_BORDER");

  // NONE = 0;                                                   
  mrb_define_const(mrb, module, "NONE", mrb_fixnum_value(0));
  
  // BOTTOM = 1;                                                   
  mrb_define_const(mrb, module, "BOTTOM", mrb_fixnum_value(1));
  
  // TOP = 2;                                                   
  mrb_define_const(mrb, module, "TOP", mrb_fixnum_value(2));
  
  // LEFT = 4;                                                   
  mrb_define_const(mrb, module, "LEFT", mrb_fixnum_value(4));
  
  // RIGHT = 8;                                                   
  mrb_define_const(mrb, module, "RIGHT", mrb_fixnum_value(8));
  
  // FULL = 15;                                                   
  mrb_define_const(mrb, module, "FULL", mrb_fixnum_value(15));
  
  // INTERNAL = 16;                                                   
  mrb_define_const(mrb, module, "INTERNAL", mrb_fixnum_value(16));
}

//
////////
////////
// Bindings for: `enum LV_BTNM_CTRL;`

void
mrb_mruby_lvgui_native_enum_lv_btnm_ctrl(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_BTNM_CTRL");

  // HIDDEN = 8;                                                   
  mrb_define_const(mrb, module, "HIDDEN", mrb_fixnum_value(8));
  
  // NO_REPEAT = 16;                                                   
  mrb_define_const(mrb, module, "NO_REPEAT", mrb_fixnum_value(16));
  
  // INACTIVE = 32;                                                   
  mrb_define_const(mrb, module, "INACTIVE", mrb_fixnum_value(32));
  
  // TGL_ENABLE = 64;                                                   
  mrb_define_const(mrb, module, "TGL_ENABLE", mrb_fixnum_value(64));
  
  // TGL_STATE = 128;                                                   
  mrb_define_const(mrb, module, "TGL_STATE", mrb_fixnum_value(128));
  
  // CLICK_TRIG = 256;                                                   
  mrb_define_const(mrb, module, "CLICK_TRIG", mrb_fixnum_value(256));
}

//
////////
////////
// Bindings for: `enum LV_BTNM_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_btnm_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_BTNM_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // BTN_REL = 1;                                                   
  mrb_define_const(mrb, module, "BTN_REL", mrb_fixnum_value(1));
  
  // BTN_PR = 2;                                                   
  mrb_define_const(mrb, module, "BTN_PR", mrb_fixnum_value(2));
  
  // BTN_TGL_REL = 3;                                                   
  mrb_define_const(mrb, module, "BTN_TGL_REL", mrb_fixnum_value(3));
  
  // BTN_TGL_PR = 4;                                                   
  mrb_define_const(mrb, module, "BTN_TGL_PR", mrb_fixnum_value(4));
  
  // BTN_INA = 5;                                                   
  mrb_define_const(mrb, module, "BTN_INA", mrb_fixnum_value(5));
}

//
////////
////////
// Bindings for: `enum LV_BTN_STATE;`

void
mrb_mruby_lvgui_native_enum_lv_btn_state(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_BTN_STATE");

  // REL = 0;                                                   
  mrb_define_const(mrb, module, "REL", mrb_fixnum_value(0));
  
  // PR = 1;                                                   
  mrb_define_const(mrb, module, "PR", mrb_fixnum_value(1));
  
  // TGL_REL = 2;                                                   
  mrb_define_const(mrb, module, "TGL_REL", mrb_fixnum_value(2));
  
  // TGL_PR = 3;                                                   
  mrb_define_const(mrb, module, "TGL_PR", mrb_fixnum_value(3));
  
  // INA = 4;                                                   
  mrb_define_const(mrb, module, "INA", mrb_fixnum_value(4));
  
  // NUM = 5;                                                   
  mrb_define_const(mrb, module, "NUM", mrb_fixnum_value(5));
}

//
////////
////////
// Bindings for: `enum LV_BTN_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_btn_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_BTN_STYLE");

  // REL = 0;                                                   
  mrb_define_const(mrb, module, "REL", mrb_fixnum_value(0));
  
  // PR = 1;                                                   
  mrb_define_const(mrb, module, "PR", mrb_fixnum_value(1));
  
  // TGL_REL = 2;                                                   
  mrb_define_const(mrb, module, "TGL_REL", mrb_fixnum_value(2));
  
  // TGL_PR = 3;                                                   
  mrb_define_const(mrb, module, "TGL_PR", mrb_fixnum_value(3));
  
  // INA = 4;                                                   
  mrb_define_const(mrb, module, "INA", mrb_fixnum_value(4));
}

//
////////
////////
// Bindings for: `enum LV_CALENDAR_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_calendar_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_CALENDAR_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // HEADER = 1;                                                   
  mrb_define_const(mrb, module, "HEADER", mrb_fixnum_value(1));
  
  // HEADER_PR = 2;                                                   
  mrb_define_const(mrb, module, "HEADER_PR", mrb_fixnum_value(2));
  
  // DAY_NAMES = 3;                                                   
  mrb_define_const(mrb, module, "DAY_NAMES", mrb_fixnum_value(3));
  
  // HIGHLIGHTED_DAYS = 4;                                                   
  mrb_define_const(mrb, module, "HIGHLIGHTED_DAYS", mrb_fixnum_value(4));
  
  // INACTIVE_DAYS = 5;                                                   
  mrb_define_const(mrb, module, "INACTIVE_DAYS", mrb_fixnum_value(5));
  
  // WEEK_BOX = 6;                                                   
  mrb_define_const(mrb, module, "WEEK_BOX", mrb_fixnum_value(6));
  
  // TODAY_BOX = 7;                                                   
  mrb_define_const(mrb, module, "TODAY_BOX", mrb_fixnum_value(7));
}

//
////////
////////
// Bindings for: `enum LV_CANVAS_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_canvas_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_CANVAS_STYLE");

  // MAIN = 0;                                                   
  mrb_define_const(mrb, module, "MAIN", mrb_fixnum_value(0));
}

//
////////
////////
// Bindings for: `enum LV_CB_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_cb_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_CB_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // BOX_REL = 1;                                                   
  mrb_define_const(mrb, module, "BOX_REL", mrb_fixnum_value(1));
  
  // BOX_PR = 2;                                                   
  mrb_define_const(mrb, module, "BOX_PR", mrb_fixnum_value(2));
  
  // BOX_TGL_REL = 3;                                                   
  mrb_define_const(mrb, module, "BOX_TGL_REL", mrb_fixnum_value(3));
  
  // BOX_TGL_PR = 4;                                                   
  mrb_define_const(mrb, module, "BOX_TGL_PR", mrb_fixnum_value(4));
  
  // BOX_INA = 5;                                                   
  mrb_define_const(mrb, module, "BOX_INA", mrb_fixnum_value(5));
}

//
////////
////////
// Bindings for: `enum LV_CONT_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_cont_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_CONT_STYLE");

  // MAIN = 0;                                                   
  mrb_define_const(mrb, module, "MAIN", mrb_fixnum_value(0));
}

//
////////
////////
// Bindings for: `enum LV_CPICKER_COLOR_MODE;`

void
mrb_mruby_lvgui_native_enum_lv_cpicker_color_mode(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_CPICKER_COLOR_MODE");

  // HUE = 0;                                                   
  mrb_define_const(mrb, module, "HUE", mrb_fixnum_value(0));
  
  // SATURATION = 1;                                                   
  mrb_define_const(mrb, module, "SATURATION", mrb_fixnum_value(1));
  
  // VALUE = 2;                                                   
  mrb_define_const(mrb, module, "VALUE", mrb_fixnum_value(2));
}

//
////////
////////
// Bindings for: `enum LV_CPICKER_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_cpicker_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_CPICKER_STYLE");

  // MAIN = 0;                                                   
  mrb_define_const(mrb, module, "MAIN", mrb_fixnum_value(0));
  
  // INDICATOR = 1;                                                   
  mrb_define_const(mrb, module, "INDICATOR", mrb_fixnum_value(1));
}

//
////////
////////
// Bindings for: `enum LV_CPICKER_TYPE;`

void
mrb_mruby_lvgui_native_enum_lv_cpicker_type(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_CPICKER_TYPE");

  // RECT = 0;                                                   
  mrb_define_const(mrb, module, "RECT", mrb_fixnum_value(0));
  
  // DISC = 1;                                                   
  mrb_define_const(mrb, module, "DISC", mrb_fixnum_value(1));
}

//
////////
////////
// Bindings for: `enum LV_CURSOR;`

void
mrb_mruby_lvgui_native_enum_lv_cursor(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_CURSOR");

  // NONE = 0;                                                   
  mrb_define_const(mrb, module, "NONE", mrb_fixnum_value(0));
  
  // LINE = 1;                                                   
  mrb_define_const(mrb, module, "LINE", mrb_fixnum_value(1));
  
  // BLOCK = 2;                                                   
  mrb_define_const(mrb, module, "BLOCK", mrb_fixnum_value(2));
  
  // OUTLINE = 3;                                                   
  mrb_define_const(mrb, module, "OUTLINE", mrb_fixnum_value(3));
  
  // UNDERLINE = 4;                                                   
  mrb_define_const(mrb, module, "UNDERLINE", mrb_fixnum_value(4));
  
  // HIDDEN = 8;                                                   
  mrb_define_const(mrb, module, "HIDDEN", mrb_fixnum_value(8));
}

//
////////
////////
// Bindings for: `enum LV_DDLIST_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_ddlist_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_DDLIST_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // SEL = 1;                                                   
  mrb_define_const(mrb, module, "SEL", mrb_fixnum_value(1));
  
  // SB = 2;                                                   
  mrb_define_const(mrb, module, "SB", mrb_fixnum_value(2));
}

//
////////
////////
// Bindings for: `enum LV_DESIGN;`

void
mrb_mruby_lvgui_native_enum_lv_design(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_DESIGN");

  // DRAW_MAIN = 0;                                                   
  mrb_define_const(mrb, module, "DRAW_MAIN", mrb_fixnum_value(0));
  
  // DRAW_POST = 1;                                                   
  mrb_define_const(mrb, module, "DRAW_POST", mrb_fixnum_value(1));
  
  // COVER_CHK = 2;                                                   
  mrb_define_const(mrb, module, "COVER_CHK", mrb_fixnum_value(2));
}

//
////////
////////
// Bindings for: `enum LV_DRAG_DIR;`

void
mrb_mruby_lvgui_native_enum_lv_drag_dir(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_DRAG_DIR");

  // HOR = 1;                                                   
  mrb_define_const(mrb, module, "HOR", mrb_fixnum_value(1));
  
  // VER = 2;                                                   
  mrb_define_const(mrb, module, "VER", mrb_fixnum_value(2));
  
  // ALL = 3;                                                   
  mrb_define_const(mrb, module, "ALL", mrb_fixnum_value(3));
}

//
////////
////////
// Bindings for: `enum LV_EVENT;`

void
mrb_mruby_lvgui_native_enum_lv_event(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_EVENT");

  // PRESSED = 0;                                                   
  mrb_define_const(mrb, module, "PRESSED", mrb_fixnum_value(0));
  
  // PRESSING = 1;                                                   
  mrb_define_const(mrb, module, "PRESSING", mrb_fixnum_value(1));
  
  // PRESS_LOST = 2;                                                   
  mrb_define_const(mrb, module, "PRESS_LOST", mrb_fixnum_value(2));
  
  // SHORT_CLICKED = 3;                                                   
  mrb_define_const(mrb, module, "SHORT_CLICKED", mrb_fixnum_value(3));
  
  // LONG_PRESSED = 4;                                                   
  mrb_define_const(mrb, module, "LONG_PRESSED", mrb_fixnum_value(4));
  
  // LONG_PRESSED_REPEAT = 5;                                                   
  mrb_define_const(mrb, module, "LONG_PRESSED_REPEAT", mrb_fixnum_value(5));
  
  // CLICKED = 6;                                                   
  mrb_define_const(mrb, module, "CLICKED", mrb_fixnum_value(6));
  
  // RELEASED = 7;                                                   
  mrb_define_const(mrb, module, "RELEASED", mrb_fixnum_value(7));
  
  // DRAG_BEGIN = 8;                                                   
  mrb_define_const(mrb, module, "DRAG_BEGIN", mrb_fixnum_value(8));
  
  // DRAG_END = 9;                                                   
  mrb_define_const(mrb, module, "DRAG_END", mrb_fixnum_value(9));
  
  // DRAG_THROW_BEGIN = 10;                                                   
  mrb_define_const(mrb, module, "DRAG_THROW_BEGIN", mrb_fixnum_value(10));
  
  // KEY = 11;                                                   
  mrb_define_const(mrb, module, "KEY", mrb_fixnum_value(11));
  
  // FOCUSED = 12;                                                   
  mrb_define_const(mrb, module, "FOCUSED", mrb_fixnum_value(12));
  
  // DEFOCUSED = 13;                                                   
  mrb_define_const(mrb, module, "DEFOCUSED", mrb_fixnum_value(13));
  
  // VALUE_CHANGED = 14;                                                   
  mrb_define_const(mrb, module, "VALUE_CHANGED", mrb_fixnum_value(14));
  
  // INSERT = 15;                                                   
  mrb_define_const(mrb, module, "INSERT", mrb_fixnum_value(15));
  
  // REFRESH = 16;                                                   
  mrb_define_const(mrb, module, "REFRESH", mrb_fixnum_value(16));
  
  // APPLY = 17;                                                   
  mrb_define_const(mrb, module, "APPLY", mrb_fixnum_value(17));
  
  // CANCEL = 18;                                                   
  mrb_define_const(mrb, module, "CANCEL", mrb_fixnum_value(18));
  
  // DELETE = 19;                                                   
  mrb_define_const(mrb, module, "DELETE", mrb_fixnum_value(19));
}

//
////////
////////
// Bindings for: `enum LV_FIT;`

void
mrb_mruby_lvgui_native_enum_lv_fit(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_FIT");

  // NONE = 0;                                                   
  mrb_define_const(mrb, module, "NONE", mrb_fixnum_value(0));
  
  // TIGHT = 1;                                                   
  mrb_define_const(mrb, module, "TIGHT", mrb_fixnum_value(1));
  
  // FLOOD = 2;                                                   
  mrb_define_const(mrb, module, "FLOOD", mrb_fixnum_value(2));
  
  // FILL = 3;                                                   
  mrb_define_const(mrb, module, "FILL", mrb_fixnum_value(3));
  
  // NUM = 4;                                                   
  mrb_define_const(mrb, module, "NUM", mrb_fixnum_value(4));
}

//
////////
////////
// Bindings for: `enum LV_FONT_FMT_TXT_CMAP;`

void
mrb_mruby_lvgui_native_enum_lv_font_fmt_txt_cmap(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_FONT_FMT_TXT_CMAP");

  // FORMAT0_TINY = 0;                                                   
  mrb_define_const(mrb, module, "FORMAT0_TINY", mrb_fixnum_value(0));
  
  // FORMAT0_FULL = 1;                                                   
  mrb_define_const(mrb, module, "FORMAT0_FULL", mrb_fixnum_value(1));
  
  // SPARSE_TINY = 2;                                                   
  mrb_define_const(mrb, module, "SPARSE_TINY", mrb_fixnum_value(2));
  
  // SPARSE_FULL = 3;                                                   
  mrb_define_const(mrb, module, "SPARSE_FULL", mrb_fixnum_value(3));
}

//
////////
////////
// Bindings for: `enum LV_FONT_SUBPX;`

void
mrb_mruby_lvgui_native_enum_lv_font_subpx(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_FONT_SUBPX");

  // NONE = 0;                                                   
  mrb_define_const(mrb, module, "NONE", mrb_fixnum_value(0));
  
  // HOR = 1;                                                   
  mrb_define_const(mrb, module, "HOR", mrb_fixnum_value(1));
  
  // VER = 2;                                                   
  mrb_define_const(mrb, module, "VER", mrb_fixnum_value(2));
  
  // BOTH = 3;                                                   
  mrb_define_const(mrb, module, "BOTH", mrb_fixnum_value(3));
}

//
////////
////////
// Bindings for: `enum LV_FS_MODE;`

void
mrb_mruby_lvgui_native_enum_lv_fs_mode(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_FS_MODE");

  // WR = 1;                                                   
  mrb_define_const(mrb, module, "WR", mrb_fixnum_value(1));
  
  // RD = 2;                                                   
  mrb_define_const(mrb, module, "RD", mrb_fixnum_value(2));
}

//
////////
////////
// Bindings for: `enum LV_FS_RES;`

void
mrb_mruby_lvgui_native_enum_lv_fs_res(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_FS_RES");

  // OK = 0;                                                   
  mrb_define_const(mrb, module, "OK", mrb_fixnum_value(0));
  
  // HW_ERR = 1;                                                   
  mrb_define_const(mrb, module, "HW_ERR", mrb_fixnum_value(1));
  
  // FS_ERR = 2;                                                   
  mrb_define_const(mrb, module, "FS_ERR", mrb_fixnum_value(2));
  
  // NOT_EX = 3;                                                   
  mrb_define_const(mrb, module, "NOT_EX", mrb_fixnum_value(3));
  
  // FULL = 4;                                                   
  mrb_define_const(mrb, module, "FULL", mrb_fixnum_value(4));
  
  // LOCKED = 5;                                                   
  mrb_define_const(mrb, module, "LOCKED", mrb_fixnum_value(5));
  
  // DENIED = 6;                                                   
  mrb_define_const(mrb, module, "DENIED", mrb_fixnum_value(6));
  
  // BUSY = 7;                                                   
  mrb_define_const(mrb, module, "BUSY", mrb_fixnum_value(7));
  
  // TOUT = 8;                                                   
  mrb_define_const(mrb, module, "TOUT", mrb_fixnum_value(8));
  
  // NOT_IMP = 9;                                                   
  mrb_define_const(mrb, module, "NOT_IMP", mrb_fixnum_value(9));
  
  // OUT_OF_MEM = 10;                                                   
  mrb_define_const(mrb, module, "OUT_OF_MEM", mrb_fixnum_value(10));
  
  // INV_PARAM = 11;                                                   
  mrb_define_const(mrb, module, "INV_PARAM", mrb_fixnum_value(11));
  
  // UNKNOWN = 12;                                                   
  mrb_define_const(mrb, module, "UNKNOWN", mrb_fixnum_value(12));
}

//
////////
////////
// Bindings for: `enum LV_GAUGE_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_gauge_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_GAUGE_STYLE");

  // MAIN = 0;                                                   
  mrb_define_const(mrb, module, "MAIN", mrb_fixnum_value(0));
}

//
////////
////////
// Bindings for: `enum LV_GROUP_REFOCUS_POLICY;`

void
mrb_mruby_lvgui_native_enum_lv_group_refocus_policy(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_GROUP_REFOCUS_POLICY");

  // NEXT = 0;                                                   
  mrb_define_const(mrb, module, "NEXT", mrb_fixnum_value(0));
  
  // PREV = 1;                                                   
  mrb_define_const(mrb, module, "PREV", mrb_fixnum_value(1));
}

//
////////
////////
// Bindings for: `enum LV_IMGBTN_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_imgbtn_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_IMGBTN_STYLE");

  // REL = 0;                                                   
  mrb_define_const(mrb, module, "REL", mrb_fixnum_value(0));
  
  // PR = 1;                                                   
  mrb_define_const(mrb, module, "PR", mrb_fixnum_value(1));
  
  // TGL_REL = 2;                                                   
  mrb_define_const(mrb, module, "TGL_REL", mrb_fixnum_value(2));
  
  // TGL_PR = 3;                                                   
  mrb_define_const(mrb, module, "TGL_PR", mrb_fixnum_value(3));
  
  // INA = 4;                                                   
  mrb_define_const(mrb, module, "INA", mrb_fixnum_value(4));
}

//
////////
////////
// Bindings for: `enum LV_IMG_CF;`

void
mrb_mruby_lvgui_native_enum_lv_img_cf(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_IMG_CF");

  // UNKNOWN = 0;                                                   
  mrb_define_const(mrb, module, "UNKNOWN", mrb_fixnum_value(0));
  
  // RAW = 1;                                                   
  mrb_define_const(mrb, module, "RAW", mrb_fixnum_value(1));
  
  // RAW_ALPHA = 2;                                                   
  mrb_define_const(mrb, module, "RAW_ALPHA", mrb_fixnum_value(2));
  
  // RAW_CHROMA_KEYED = 3;                                                   
  mrb_define_const(mrb, module, "RAW_CHROMA_KEYED", mrb_fixnum_value(3));
  
  // TRUE_COLOR = 4;                                                   
  mrb_define_const(mrb, module, "TRUE_COLOR", mrb_fixnum_value(4));
  
  // TRUE_COLOR_ALPHA = 5;                                                   
  mrb_define_const(mrb, module, "TRUE_COLOR_ALPHA", mrb_fixnum_value(5));
  
  // TRUE_COLOR_CHROMA_KEYED = 6;                                                   
  mrb_define_const(mrb, module, "TRUE_COLOR_CHROMA_KEYED", mrb_fixnum_value(6));
  
  // INDEXED_1BIT = 7;                                                   
  mrb_define_const(mrb, module, "INDEXED_1BIT", mrb_fixnum_value(7));
  
  // INDEXED_2BIT = 8;                                                   
  mrb_define_const(mrb, module, "INDEXED_2BIT", mrb_fixnum_value(8));
  
  // INDEXED_4BIT = 9;                                                   
  mrb_define_const(mrb, module, "INDEXED_4BIT", mrb_fixnum_value(9));
  
  // INDEXED_8BIT = 10;                                                   
  mrb_define_const(mrb, module, "INDEXED_8BIT", mrb_fixnum_value(10));
  
  // ALPHA_1BIT = 11;                                                   
  mrb_define_const(mrb, module, "ALPHA_1BIT", mrb_fixnum_value(11));
  
  // ALPHA_2BIT = 12;                                                   
  mrb_define_const(mrb, module, "ALPHA_2BIT", mrb_fixnum_value(12));
  
  // ALPHA_4BIT = 13;                                                   
  mrb_define_const(mrb, module, "ALPHA_4BIT", mrb_fixnum_value(13));
  
  // ALPHA_8BIT = 14;                                                   
  mrb_define_const(mrb, module, "ALPHA_8BIT", mrb_fixnum_value(14));
  
  // RESERVED_15 = 15;                                                   
  mrb_define_const(mrb, module, "RESERVED_15", mrb_fixnum_value(15));
  
  // RESERVED_16 = 16;                                                   
  mrb_define_const(mrb, module, "RESERVED_16", mrb_fixnum_value(16));
  
  // RESERVED_17 = 17;                                                   
  mrb_define_const(mrb, module, "RESERVED_17", mrb_fixnum_value(17));
  
  // RESERVED_18 = 18;                                                   
  mrb_define_const(mrb, module, "RESERVED_18", mrb_fixnum_value(18));
  
  // RESERVED_19 = 19;                                                   
  mrb_define_const(mrb, module, "RESERVED_19", mrb_fixnum_value(19));
  
  // RESERVED_20 = 20;                                                   
  mrb_define_const(mrb, module, "RESERVED_20", mrb_fixnum_value(20));
  
  // RESERVED_21 = 21;                                                   
  mrb_define_const(mrb, module, "RESERVED_21", mrb_fixnum_value(21));
  
  // RESERVED_22 = 22;                                                   
  mrb_define_const(mrb, module, "RESERVED_22", mrb_fixnum_value(22));
  
  // RESERVED_23 = 23;                                                   
  mrb_define_const(mrb, module, "RESERVED_23", mrb_fixnum_value(23));
  
  // USER_ENCODED_0 = 24;                                                   
  mrb_define_const(mrb, module, "USER_ENCODED_0", mrb_fixnum_value(24));
  
  // USER_ENCODED_1 = 25;                                                   
  mrb_define_const(mrb, module, "USER_ENCODED_1", mrb_fixnum_value(25));
  
  // USER_ENCODED_2 = 26;                                                   
  mrb_define_const(mrb, module, "USER_ENCODED_2", mrb_fixnum_value(26));
  
  // USER_ENCODED_3 = 27;                                                   
  mrb_define_const(mrb, module, "USER_ENCODED_3", mrb_fixnum_value(27));
  
  // USER_ENCODED_4 = 28;                                                   
  mrb_define_const(mrb, module, "USER_ENCODED_4", mrb_fixnum_value(28));
  
  // USER_ENCODED_5 = 29;                                                   
  mrb_define_const(mrb, module, "USER_ENCODED_5", mrb_fixnum_value(29));
  
  // USER_ENCODED_6 = 30;                                                   
  mrb_define_const(mrb, module, "USER_ENCODED_6", mrb_fixnum_value(30));
  
  // USER_ENCODED_7 = 31;                                                   
  mrb_define_const(mrb, module, "USER_ENCODED_7", mrb_fixnum_value(31));
}

//
////////
////////
// Bindings for: `enum LV_IMG_SRC;`

void
mrb_mruby_lvgui_native_enum_lv_img_src(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_IMG_SRC");

  // VARIABLE = 0;                                                   
  mrb_define_const(mrb, module, "VARIABLE", mrb_fixnum_value(0));
  
  // FILE = 1;                                                   
  mrb_define_const(mrb, module, "FILE", mrb_fixnum_value(1));
  
  // SYMBOL = 2;                                                   
  mrb_define_const(mrb, module, "SYMBOL", mrb_fixnum_value(2));
  
  // UNKNOWN = 3;                                                   
  mrb_define_const(mrb, module, "UNKNOWN", mrb_fixnum_value(3));
}

//
////////
////////
// Bindings for: `enum LV_IMG_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_img_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_IMG_STYLE");

  // MAIN = 0;                                                   
  mrb_define_const(mrb, module, "MAIN", mrb_fixnum_value(0));
}

//
////////
////////
// Bindings for: `enum LV_INDEV_STATE;`

void
mrb_mruby_lvgui_native_enum_lv_indev_state(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_INDEV_STATE");

  // REL = 0;                                                   
  mrb_define_const(mrb, module, "REL", mrb_fixnum_value(0));
  
  // PR = 1;                                                   
  mrb_define_const(mrb, module, "PR", mrb_fixnum_value(1));
}

//
////////
////////
// Bindings for: `enum LV_INDEV_TYPE;`

void
mrb_mruby_lvgui_native_enum_lv_indev_type(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_INDEV_TYPE");

  // NONE = 0;                                                   
  mrb_define_const(mrb, module, "NONE", mrb_fixnum_value(0));
  
  // POINTER = 2;                                                   
  mrb_define_const(mrb, module, "POINTER", mrb_fixnum_value(2));
  
  // KEYBOARD = 2;                                                   
  mrb_define_const(mrb, module, "KEYBOARD", mrb_fixnum_value(2));
  
  // BUTTON = 2;                                                   
  mrb_define_const(mrb, module, "BUTTON", mrb_fixnum_value(2));
  
  // ENCODER = 2;                                                   
  mrb_define_const(mrb, module, "ENCODER", mrb_fixnum_value(2));
}

//
////////
////////
// Bindings for: `enum LV_KB_MODE;`

void
mrb_mruby_lvgui_native_enum_lv_kb_mode(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_KB_MODE");

  // TEXT = 0;                                                   
  mrb_define_const(mrb, module, "TEXT", mrb_fixnum_value(0));
  
  // NUM = 1;                                                   
  mrb_define_const(mrb, module, "NUM", mrb_fixnum_value(1));
  
  // TEXT_UPPER = 2;                                                   
  mrb_define_const(mrb, module, "TEXT_UPPER", mrb_fixnum_value(2));
}

//
////////
////////
// Bindings for: `enum LV_KB_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_kb_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_KB_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // BTN_REL = 1;                                                   
  mrb_define_const(mrb, module, "BTN_REL", mrb_fixnum_value(1));
  
  // BTN_PR = 2;                                                   
  mrb_define_const(mrb, module, "BTN_PR", mrb_fixnum_value(2));
  
  // BTN_TGL_REL = 3;                                                   
  mrb_define_const(mrb, module, "BTN_TGL_REL", mrb_fixnum_value(3));
  
  // BTN_TGL_PR = 4;                                                   
  mrb_define_const(mrb, module, "BTN_TGL_PR", mrb_fixnum_value(4));
  
  // BTN_INA = 5;                                                   
  mrb_define_const(mrb, module, "BTN_INA", mrb_fixnum_value(5));
}

//
////////
////////
// Bindings for: `enum LV_KEY;`

void
mrb_mruby_lvgui_native_enum_lv_key(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_KEY");

  // UP = 17;                                                   
  mrb_define_const(mrb, module, "UP", mrb_fixnum_value(17));
  
  // DOWN = 18;                                                   
  mrb_define_const(mrb, module, "DOWN", mrb_fixnum_value(18));
  
  // RIGHT = 19;                                                   
  mrb_define_const(mrb, module, "RIGHT", mrb_fixnum_value(19));
  
  // LEFT = 20;                                                   
  mrb_define_const(mrb, module, "LEFT", mrb_fixnum_value(20));
  
  // ESC = 27;                                                   
  mrb_define_const(mrb, module, "ESC", mrb_fixnum_value(27));
  
  // DEL = 127;                                                   
  mrb_define_const(mrb, module, "DEL", mrb_fixnum_value(127));
  
  // BACKSPACE = 8;                                                   
  mrb_define_const(mrb, module, "BACKSPACE", mrb_fixnum_value(8));
  
  // ENTER = 10;                                                   
  mrb_define_const(mrb, module, "ENTER", mrb_fixnum_value(10));
  
  // NEXT = 9;                                                   
  mrb_define_const(mrb, module, "NEXT", mrb_fixnum_value(9));
  
  // PREV = 11;                                                   
  mrb_define_const(mrb, module, "PREV", mrb_fixnum_value(11));
  
  // HOME = 2;                                                   
  mrb_define_const(mrb, module, "HOME", mrb_fixnum_value(2));
  
  // END = 3;                                                   
  mrb_define_const(mrb, module, "END", mrb_fixnum_value(3));
}

//
////////
////////
// Bindings for: `enum LV_LABEL_ALIGN;`

void
mrb_mruby_lvgui_native_enum_lv_label_align(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_LABEL_ALIGN");

  // LEFT = 0;                                                   
  mrb_define_const(mrb, module, "LEFT", mrb_fixnum_value(0));
  
  // CENTER = 1;                                                   
  mrb_define_const(mrb, module, "CENTER", mrb_fixnum_value(1));
  
  // RIGHT = 2;                                                   
  mrb_define_const(mrb, module, "RIGHT", mrb_fixnum_value(2));
  
  // AUTO = 3;                                                   
  mrb_define_const(mrb, module, "AUTO", mrb_fixnum_value(3));
}

//
////////
////////
// Bindings for: `enum LV_LABEL_LONG;`

void
mrb_mruby_lvgui_native_enum_lv_label_long(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_LABEL_LONG");

  // EXPAND = 0;                                                   
  mrb_define_const(mrb, module, "EXPAND", mrb_fixnum_value(0));
  
  // BREAK = 1;                                                   
  mrb_define_const(mrb, module, "BREAK", mrb_fixnum_value(1));
  
  // DOT = 2;                                                   
  mrb_define_const(mrb, module, "DOT", mrb_fixnum_value(2));
  
  // SROLL = 3;                                                   
  mrb_define_const(mrb, module, "SROLL", mrb_fixnum_value(3));
  
  // SROLL_CIRC = 4;                                                   
  mrb_define_const(mrb, module, "SROLL_CIRC", mrb_fixnum_value(4));
  
  // CROP = 5;                                                   
  mrb_define_const(mrb, module, "CROP", mrb_fixnum_value(5));
}

//
////////
////////
// Bindings for: `enum LV_LABEL_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_label_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_LABEL_STYLE");

  // MAIN = 0;                                                   
  mrb_define_const(mrb, module, "MAIN", mrb_fixnum_value(0));
}

//
////////
////////
// Bindings for: `enum LV_LAYOUT;`

void
mrb_mruby_lvgui_native_enum_lv_layout(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_LAYOUT");

  // OFF = 0;                                                   
  mrb_define_const(mrb, module, "OFF", mrb_fixnum_value(0));
  
  // CENTER = 1;                                                   
  mrb_define_const(mrb, module, "CENTER", mrb_fixnum_value(1));
  
  // COL_L = 2;                                                   
  mrb_define_const(mrb, module, "COL_L", mrb_fixnum_value(2));
  
  // COL_M = 3;                                                   
  mrb_define_const(mrb, module, "COL_M", mrb_fixnum_value(3));
  
  // COL_R = 4;                                                   
  mrb_define_const(mrb, module, "COL_R", mrb_fixnum_value(4));
  
  // ROW_T = 5;                                                   
  mrb_define_const(mrb, module, "ROW_T", mrb_fixnum_value(5));
  
  // ROW_M = 6;                                                   
  mrb_define_const(mrb, module, "ROW_M", mrb_fixnum_value(6));
  
  // ROW_B = 7;                                                   
  mrb_define_const(mrb, module, "ROW_B", mrb_fixnum_value(7));
  
  // PRETTY = 8;                                                   
  mrb_define_const(mrb, module, "PRETTY", mrb_fixnum_value(8));
  
  // GRID = 9;                                                   
  mrb_define_const(mrb, module, "GRID", mrb_fixnum_value(9));
  
  // NUM = 10;                                                   
  mrb_define_const(mrb, module, "NUM", mrb_fixnum_value(10));
}

//
////////
////////
// Bindings for: `enum LV_LINE_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_line_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_LINE_STYLE");

  // MAIN = 0;                                                   
  mrb_define_const(mrb, module, "MAIN", mrb_fixnum_value(0));
}

//
////////
////////
// Bindings for: `enum LV_LMETER_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_lmeter_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_LMETER_STYLE");

  // MAIN = 0;                                                   
  mrb_define_const(mrb, module, "MAIN", mrb_fixnum_value(0));
}

//
////////
////////
// Bindings for: `enum LV_OPA;`

void
mrb_mruby_lvgui_native_enum_lv_opa(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_OPA");

  // TRANSP = 0;                                                   
  mrb_define_const(mrb, module, "TRANSP", mrb_fixnum_value(0));
  
  // 0 = 0;                                                   
  mrb_define_const(mrb, module, "0", mrb_fixnum_value(0));
  
  // 10 = 25;                                                   
  mrb_define_const(mrb, module, "10", mrb_fixnum_value(25));
  
  // 20 = 51;                                                   
  mrb_define_const(mrb, module, "20", mrb_fixnum_value(51));
  
  // 30 = 76;                                                   
  mrb_define_const(mrb, module, "30", mrb_fixnum_value(76));
  
  // 40 = 102;                                                   
  mrb_define_const(mrb, module, "40", mrb_fixnum_value(102));
  
  // 50 = 127;                                                   
  mrb_define_const(mrb, module, "50", mrb_fixnum_value(127));
  
  // 60 = 153;                                                   
  mrb_define_const(mrb, module, "60", mrb_fixnum_value(153));
  
  // 70 = 178;                                                   
  mrb_define_const(mrb, module, "70", mrb_fixnum_value(178));
  
  // 80 = 204;                                                   
  mrb_define_const(mrb, module, "80", mrb_fixnum_value(204));
  
  // 90 = 229;                                                   
  mrb_define_const(mrb, module, "90", mrb_fixnum_value(229));
  
  // 100 = 255;                                                   
  mrb_define_const(mrb, module, "100", mrb_fixnum_value(255));
  
  // COVER = 255;                                                   
  mrb_define_const(mrb, module, "COVER", mrb_fixnum_value(255));
}

//
////////
////////
// Bindings for: `enum LV_PAGE_EDGE;`

void
mrb_mruby_lvgui_native_enum_lv_page_edge(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_PAGE_EDGE");

  // LEFT = 1;                                                   
  mrb_define_const(mrb, module, "LEFT", mrb_fixnum_value(1));
  
  // TOP = 2;                                                   
  mrb_define_const(mrb, module, "TOP", mrb_fixnum_value(2));
  
  // RIGHT = 4;                                                   
  mrb_define_const(mrb, module, "RIGHT", mrb_fixnum_value(4));
  
  // BOTTOM = 8;                                                   
  mrb_define_const(mrb, module, "BOTTOM", mrb_fixnum_value(8));
}

//
////////
////////
// Bindings for: `enum LV_PAGE_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_page_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_PAGE_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // SCRL = 1;                                                   
  mrb_define_const(mrb, module, "SCRL", mrb_fixnum_value(1));
  
  // SB = 2;                                                   
  mrb_define_const(mrb, module, "SB", mrb_fixnum_value(2));
  
  // EDGE_FLASH = 3;                                                   
  mrb_define_const(mrb, module, "EDGE_FLASH", mrb_fixnum_value(3));
}

//
////////
////////
// Bindings for: `enum LV_PRELOAD_DIR;`

void
mrb_mruby_lvgui_native_enum_lv_preload_dir(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_PRELOAD_DIR");

  // FORWARD = 0;                                                   
  mrb_define_const(mrb, module, "FORWARD", mrb_fixnum_value(0));
  
  // BACKWARD = 1;                                                   
  mrb_define_const(mrb, module, "BACKWARD", mrb_fixnum_value(1));
}

//
////////
////////
// Bindings for: `enum LV_PRELOAD_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_preload_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_PRELOAD_STYLE");

  // MAIN = 0;                                                   
  mrb_define_const(mrb, module, "MAIN", mrb_fixnum_value(0));
}

//
////////
////////
// Bindings for: `enum LV_PRELOAD_TYPE;`

void
mrb_mruby_lvgui_native_enum_lv_preload_type(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_PRELOAD_TYPE");

  // SPINNING_ARC = 0;                                                   
  mrb_define_const(mrb, module, "SPINNING_ARC", mrb_fixnum_value(0));
  
  // FILLSPIN_ARC = 1;                                                   
  mrb_define_const(mrb, module, "FILLSPIN_ARC", mrb_fixnum_value(1));
  
  // CONSTANT_ARC = 2;                                                   
  mrb_define_const(mrb, module, "CONSTANT_ARC", mrb_fixnum_value(2));
}

//
////////
////////
// Bindings for: `enum LV_PROTECT;`

void
mrb_mruby_lvgui_native_enum_lv_protect(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_PROTECT");

  // NONE = 0;                                                   
  mrb_define_const(mrb, module, "NONE", mrb_fixnum_value(0));
  
  // CHILD_CHG = 1;                                                   
  mrb_define_const(mrb, module, "CHILD_CHG", mrb_fixnum_value(1));
  
  // PARENT = 2;                                                   
  mrb_define_const(mrb, module, "PARENT", mrb_fixnum_value(2));
  
  // POS = 4;                                                   
  mrb_define_const(mrb, module, "POS", mrb_fixnum_value(4));
  
  // FOLLOW = 8;                                                   
  mrb_define_const(mrb, module, "FOLLOW", mrb_fixnum_value(8));
  
  // PRESS_LOST = 16;                                                   
  mrb_define_const(mrb, module, "PRESS_LOST", mrb_fixnum_value(16));
  
  // CLICK_FOCUS = 32;                                                   
  mrb_define_const(mrb, module, "CLICK_FOCUS", mrb_fixnum_value(32));
}

//
////////
////////
// Bindings for: `enum LV_RES;`

void
mrb_mruby_lvgui_native_enum_lv_res(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_RES");

  // INV = 0;                                                   
  mrb_define_const(mrb, module, "INV", mrb_fixnum_value(0));
  
  // OK = 1;                                                   
  mrb_define_const(mrb, module, "OK", mrb_fixnum_value(1));
}

//
////////
////////
// Bindings for: `enum LV_ROLLER_MODE;`

void
mrb_mruby_lvgui_native_enum_lv_roller_mode(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_ROLLER_MODE");

  // NORMAL = 0;                                                   
  mrb_define_const(mrb, module, "NORMAL", mrb_fixnum_value(0));
  
  // INIFINITE = 1;                                                   
  mrb_define_const(mrb, module, "INIFINITE", mrb_fixnum_value(1));
}

//
////////
////////
// Bindings for: `enum LV_ROLLER_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_roller_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_ROLLER_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // SEL = 1;                                                   
  mrb_define_const(mrb, module, "SEL", mrb_fixnum_value(1));
}

//
////////
////////
// Bindings for: `enum LV_SB_MODE;`

void
mrb_mruby_lvgui_native_enum_lv_sb_mode(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_SB_MODE");

  // OFF = 0;                                                   
  mrb_define_const(mrb, module, "OFF", mrb_fixnum_value(0));
  
  // ON = 1;                                                   
  mrb_define_const(mrb, module, "ON", mrb_fixnum_value(1));
  
  // DRAG = 2;                                                   
  mrb_define_const(mrb, module, "DRAG", mrb_fixnum_value(2));
  
  // AUTO = 3;                                                   
  mrb_define_const(mrb, module, "AUTO", mrb_fixnum_value(3));
  
  // HIDE = 4;                                                   
  mrb_define_const(mrb, module, "HIDE", mrb_fixnum_value(4));
  
  // UNHIDE = 5;                                                   
  mrb_define_const(mrb, module, "UNHIDE", mrb_fixnum_value(5));
}

//
////////
////////
// Bindings for: `enum LV_SHADOW;`

void
mrb_mruby_lvgui_native_enum_lv_shadow(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_SHADOW");

  // BOTTOM = 0;                                                   
  mrb_define_const(mrb, module, "BOTTOM", mrb_fixnum_value(0));
  
  // FULL = 1;                                                   
  mrb_define_const(mrb, module, "FULL", mrb_fixnum_value(1));
}

//
////////
////////
// Bindings for: `enum LV_SIGNAL;`

void
mrb_mruby_lvgui_native_enum_lv_signal(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_SIGNAL");

  // CLEANUP = 0;                                                   
  mrb_define_const(mrb, module, "CLEANUP", mrb_fixnum_value(0));
  
  // CHILD_CHG = 1;                                                   
  mrb_define_const(mrb, module, "CHILD_CHG", mrb_fixnum_value(1));
  
  // CORD_CHG = 2;                                                   
  mrb_define_const(mrb, module, "CORD_CHG", mrb_fixnum_value(2));
  
  // PARENT_SIZE_CHG = 3;                                                   
  mrb_define_const(mrb, module, "PARENT_SIZE_CHG", mrb_fixnum_value(3));
  
  // STYLE_CHG = 4;                                                   
  mrb_define_const(mrb, module, "STYLE_CHG", mrb_fixnum_value(4));
  
  // BASE_DIR_CHG = 5;                                                   
  mrb_define_const(mrb, module, "BASE_DIR_CHG", mrb_fixnum_value(5));
  
  // REFR_EXT_DRAW_PAD = 6;                                                   
  mrb_define_const(mrb, module, "REFR_EXT_DRAW_PAD", mrb_fixnum_value(6));
  
  // GET_TYPE = 7;                                                   
  mrb_define_const(mrb, module, "GET_TYPE", mrb_fixnum_value(7));
  
  // PRESSED = 8;                                                   
  mrb_define_const(mrb, module, "PRESSED", mrb_fixnum_value(8));
  
  // PRESSING = 9;                                                   
  mrb_define_const(mrb, module, "PRESSING", mrb_fixnum_value(9));
  
  // PRESS_LOST = 10;                                                   
  mrb_define_const(mrb, module, "PRESS_LOST", mrb_fixnum_value(10));
  
  // RELEASED = 11;                                                   
  mrb_define_const(mrb, module, "RELEASED", mrb_fixnum_value(11));
  
  // LONG_PRESS = 12;                                                   
  mrb_define_const(mrb, module, "LONG_PRESS", mrb_fixnum_value(12));
  
  // LONG_PRESS_REP = 13;                                                   
  mrb_define_const(mrb, module, "LONG_PRESS_REP", mrb_fixnum_value(13));
  
  // DRAG_BEGIN = 14;                                                   
  mrb_define_const(mrb, module, "DRAG_BEGIN", mrb_fixnum_value(14));
  
  // DRAG_END = 15;                                                   
  mrb_define_const(mrb, module, "DRAG_END", mrb_fixnum_value(15));
  
  // FOCUS = 16;                                                   
  mrb_define_const(mrb, module, "FOCUS", mrb_fixnum_value(16));
  
  // DEFOCUS = 17;                                                   
  mrb_define_const(mrb, module, "DEFOCUS", mrb_fixnum_value(17));
  
  // CONTROL = 18;                                                   
  mrb_define_const(mrb, module, "CONTROL", mrb_fixnum_value(18));
  
  // GET_EDITABLE = 19;                                                   
  mrb_define_const(mrb, module, "GET_EDITABLE", mrb_fixnum_value(19));
}

//
////////
////////
// Bindings for: `enum LV_SLIDER_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_slider_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_SLIDER_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // INDIC = 1;                                                   
  mrb_define_const(mrb, module, "INDIC", mrb_fixnum_value(1));
  
  // KNOB = 2;                                                   
  mrb_define_const(mrb, module, "KNOB", mrb_fixnum_value(2));
}

//
////////
////////
// Bindings for: `enum LV_SPINBOX_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_spinbox_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_SPINBOX_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // SB = 1;                                                   
  mrb_define_const(mrb, module, "SB", mrb_fixnum_value(1));
  
  // CURSOR = 2;                                                   
  mrb_define_const(mrb, module, "CURSOR", mrb_fixnum_value(2));
}

//
////////
////////
// Bindings for: `enum LV_STR_SYMBOL;`

void
mrb_mruby_lvgui_native_enum_lv_str_symbol(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_STR_SYMBOL");

  // AUDIO = 0;                                                   
  mrb_define_const(mrb, module, "AUDIO", mrb_fixnum_value(0));
  
  // VIDEO = 1;                                                   
  mrb_define_const(mrb, module, "VIDEO", mrb_fixnum_value(1));
  
  // LIST = 2;                                                   
  mrb_define_const(mrb, module, "LIST", mrb_fixnum_value(2));
  
  // OK = 3;                                                   
  mrb_define_const(mrb, module, "OK", mrb_fixnum_value(3));
  
  // CLOSE = 4;                                                   
  mrb_define_const(mrb, module, "CLOSE", mrb_fixnum_value(4));
  
  // POWER = 5;                                                   
  mrb_define_const(mrb, module, "POWER", mrb_fixnum_value(5));
  
  // SETTINGS = 6;                                                   
  mrb_define_const(mrb, module, "SETTINGS", mrb_fixnum_value(6));
  
  // HOME = 7;                                                   
  mrb_define_const(mrb, module, "HOME", mrb_fixnum_value(7));
  
  // DOWNLOAD = 8;                                                   
  mrb_define_const(mrb, module, "DOWNLOAD", mrb_fixnum_value(8));
  
  // DRIVE = 9;                                                   
  mrb_define_const(mrb, module, "DRIVE", mrb_fixnum_value(9));
  
  // REFRESH = 10;                                                   
  mrb_define_const(mrb, module, "REFRESH", mrb_fixnum_value(10));
  
  // MUTE = 11;                                                   
  mrb_define_const(mrb, module, "MUTE", mrb_fixnum_value(11));
  
  // VOLUME_MID = 12;                                                   
  mrb_define_const(mrb, module, "VOLUME_MID", mrb_fixnum_value(12));
  
  // VOLUME_MAX = 13;                                                   
  mrb_define_const(mrb, module, "VOLUME_MAX", mrb_fixnum_value(13));
  
  // IMAGE = 14;                                                   
  mrb_define_const(mrb, module, "IMAGE", mrb_fixnum_value(14));
  
  // EDIT = 15;                                                   
  mrb_define_const(mrb, module, "EDIT", mrb_fixnum_value(15));
  
  // PREV = 16;                                                   
  mrb_define_const(mrb, module, "PREV", mrb_fixnum_value(16));
  
  // PLAY = 17;                                                   
  mrb_define_const(mrb, module, "PLAY", mrb_fixnum_value(17));
  
  // PAUSE = 18;                                                   
  mrb_define_const(mrb, module, "PAUSE", mrb_fixnum_value(18));
  
  // STOP = 19;                                                   
  mrb_define_const(mrb, module, "STOP", mrb_fixnum_value(19));
  
  // NEXT = 20;                                                   
  mrb_define_const(mrb, module, "NEXT", mrb_fixnum_value(20));
  
  // EJECT = 21;                                                   
  mrb_define_const(mrb, module, "EJECT", mrb_fixnum_value(21));
  
  // LEFT = 22;                                                   
  mrb_define_const(mrb, module, "LEFT", mrb_fixnum_value(22));
  
  // RIGHT = 23;                                                   
  mrb_define_const(mrb, module, "RIGHT", mrb_fixnum_value(23));
  
  // PLUS = 24;                                                   
  mrb_define_const(mrb, module, "PLUS", mrb_fixnum_value(24));
  
  // MINUS = 25;                                                   
  mrb_define_const(mrb, module, "MINUS", mrb_fixnum_value(25));
  
  // EYE_OPEN = 26;                                                   
  mrb_define_const(mrb, module, "EYE_OPEN", mrb_fixnum_value(26));
  
  // EYE_CLOSE = 27;                                                   
  mrb_define_const(mrb, module, "EYE_CLOSE", mrb_fixnum_value(27));
  
  // WARNING = 28;                                                   
  mrb_define_const(mrb, module, "WARNING", mrb_fixnum_value(28));
  
  // SHUFFLE = 29;                                                   
  mrb_define_const(mrb, module, "SHUFFLE", mrb_fixnum_value(29));
  
  // UP = 30;                                                   
  mrb_define_const(mrb, module, "UP", mrb_fixnum_value(30));
  
  // DOWN = 31;                                                   
  mrb_define_const(mrb, module, "DOWN", mrb_fixnum_value(31));
  
  // LOOP = 32;                                                   
  mrb_define_const(mrb, module, "LOOP", mrb_fixnum_value(32));
  
  // DIRECTORY = 33;                                                   
  mrb_define_const(mrb, module, "DIRECTORY", mrb_fixnum_value(33));
  
  // UPLOAD = 34;                                                   
  mrb_define_const(mrb, module, "UPLOAD", mrb_fixnum_value(34));
  
  // CALL = 35;                                                   
  mrb_define_const(mrb, module, "CALL", mrb_fixnum_value(35));
  
  // CUT = 36;                                                   
  mrb_define_const(mrb, module, "CUT", mrb_fixnum_value(36));
  
  // COPY = 37;                                                   
  mrb_define_const(mrb, module, "COPY", mrb_fixnum_value(37));
  
  // SAVE = 38;                                                   
  mrb_define_const(mrb, module, "SAVE", mrb_fixnum_value(38));
  
  // CHARGE = 39;                                                   
  mrb_define_const(mrb, module, "CHARGE", mrb_fixnum_value(39));
  
  // PASTE = 40;                                                   
  mrb_define_const(mrb, module, "PASTE", mrb_fixnum_value(40));
  
  // BELL = 41;                                                   
  mrb_define_const(mrb, module, "BELL", mrb_fixnum_value(41));
  
  // KEYBOARD = 42;                                                   
  mrb_define_const(mrb, module, "KEYBOARD", mrb_fixnum_value(42));
  
  // GPS = 43;                                                   
  mrb_define_const(mrb, module, "GPS", mrb_fixnum_value(43));
  
  // FILE = 44;                                                   
  mrb_define_const(mrb, module, "FILE", mrb_fixnum_value(44));
  
  // WIFI = 45;                                                   
  mrb_define_const(mrb, module, "WIFI", mrb_fixnum_value(45));
  
  // BATTERY_FULL = 46;                                                   
  mrb_define_const(mrb, module, "BATTERY_FULL", mrb_fixnum_value(46));
  
  // BATTERY_3 = 47;                                                   
  mrb_define_const(mrb, module, "BATTERY_3", mrb_fixnum_value(47));
  
  // BATTERY_2 = 48;                                                   
  mrb_define_const(mrb, module, "BATTERY_2", mrb_fixnum_value(48));
  
  // BATTERY_1 = 49;                                                   
  mrb_define_const(mrb, module, "BATTERY_1", mrb_fixnum_value(49));
  
  // BATTERY_EMPTY = 50;                                                   
  mrb_define_const(mrb, module, "BATTERY_EMPTY", mrb_fixnum_value(50));
  
  // USB = 51;                                                   
  mrb_define_const(mrb, module, "USB", mrb_fixnum_value(51));
  
  // BLUETOOTH = 52;                                                   
  mrb_define_const(mrb, module, "BLUETOOTH", mrb_fixnum_value(52));
  
  // TRASH = 53;                                                   
  mrb_define_const(mrb, module, "TRASH", mrb_fixnum_value(53));
  
  // BACKSPACE = 54;                                                   
  mrb_define_const(mrb, module, "BACKSPACE", mrb_fixnum_value(54));
  
  // SD_CARD = 55;                                                   
  mrb_define_const(mrb, module, "SD_CARD", mrb_fixnum_value(55));
  
  // NEW_LINE = 56;                                                   
  mrb_define_const(mrb, module, "NEW_LINE", mrb_fixnum_value(56));
  
  // DUMMY = 57;                                                   
  mrb_define_const(mrb, module, "DUMMY", mrb_fixnum_value(57));
}

//
////////
////////
// Bindings for: `enum LV_SW_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_sw_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_SW_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // INDIC = 1;                                                   
  mrb_define_const(mrb, module, "INDIC", mrb_fixnum_value(1));
  
  // KNOB_OFF = 2;                                                   
  mrb_define_const(mrb, module, "KNOB_OFF", mrb_fixnum_value(2));
  
  // KNOB_ON = 3;                                                   
  mrb_define_const(mrb, module, "KNOB_ON", mrb_fixnum_value(3));
}

//
////////
////////
// Bindings for: `enum LV_TABLE_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_table_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_TABLE_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // CELL1 = 1;                                                   
  mrb_define_const(mrb, module, "CELL1", mrb_fixnum_value(1));
  
  // CELL2 = 2;                                                   
  mrb_define_const(mrb, module, "CELL2", mrb_fixnum_value(2));
  
  // CELL3 = 3;                                                   
  mrb_define_const(mrb, module, "CELL3", mrb_fixnum_value(3));
  
  // CELL4 = 4;                                                   
  mrb_define_const(mrb, module, "CELL4", mrb_fixnum_value(4));
}

//
////////
////////
// Bindings for: `enum LV_TASK_PRIO;`

void
mrb_mruby_lvgui_native_enum_lv_task_prio(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_TASK_PRIO");

  // OFF = 0;                                                   
  mrb_define_const(mrb, module, "OFF", mrb_fixnum_value(0));
  
  // LOWEST = 1;                                                   
  mrb_define_const(mrb, module, "LOWEST", mrb_fixnum_value(1));
  
  // LOW = 2;                                                   
  mrb_define_const(mrb, module, "LOW", mrb_fixnum_value(2));
  
  // MID = 3;                                                   
  mrb_define_const(mrb, module, "MID", mrb_fixnum_value(3));
  
  // HIGH = 4;                                                   
  mrb_define_const(mrb, module, "HIGH", mrb_fixnum_value(4));
  
  // HIGHEST = 5;                                                   
  mrb_define_const(mrb, module, "HIGHEST", mrb_fixnum_value(5));
  
  // NUM = 6;                                                   
  mrb_define_const(mrb, module, "NUM", mrb_fixnum_value(6));
}

//
////////
////////
// Bindings for: `enum LV_TA_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_ta_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_TA_STYLE");

  // BG = 0;                                                   
  mrb_define_const(mrb, module, "BG", mrb_fixnum_value(0));
  
  // SB = 1;                                                   
  mrb_define_const(mrb, module, "SB", mrb_fixnum_value(1));
  
  // CURSOR = 2;                                                   
  mrb_define_const(mrb, module, "CURSOR", mrb_fixnum_value(2));
  
  // EDGE_FLASH = 3;                                                   
  mrb_define_const(mrb, module, "EDGE_FLASH", mrb_fixnum_value(3));
  
  // PLACEHOLDER = 4;                                                   
  mrb_define_const(mrb, module, "PLACEHOLDER", mrb_fixnum_value(4));
}

//
////////
////////
// Bindings for: `enum LV_TILEVIEW_STYLE;`

void
mrb_mruby_lvgui_native_enum_lv_tileview_style(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_TILEVIEW_STYLE");

  // MAIN = 0;                                                   
  mrb_define_const(mrb, module, "MAIN", mrb_fixnum_value(0));
}

//
////////
////////
// Bindings for: `enum LV_TXT_CMD_STATE;`

void
mrb_mruby_lvgui_native_enum_lv_txt_cmd_state(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_TXT_CMD_STATE");

  // WAIT = 0;                                                   
  mrb_define_const(mrb, module, "WAIT", mrb_fixnum_value(0));
  
  // PAR = 1;                                                   
  mrb_define_const(mrb, module, "PAR", mrb_fixnum_value(1));
  
  // IN = 2;                                                   
  mrb_define_const(mrb, module, "IN", mrb_fixnum_value(2));
}

//
////////
////////
// Bindings for: `enum LV_TXT_FLAG;`

void
mrb_mruby_lvgui_native_enum_lv_txt_flag(mrb_state *mrb, struct RClass * parent_module)
{
  struct RClass * module = mrb_define_module_under(mrb, parent_module, "LV_TXT_FLAG");

  // NONE = 0;                                                   
  mrb_define_const(mrb, module, "NONE", mrb_fixnum_value(0));
  
  // RECOLOR = 1;                                                   
  mrb_define_const(mrb, module, "RECOLOR", mrb_fixnum_value(1));
  
  // EXPAND = 2;                                                   
  mrb_define_const(mrb, module, "EXPAND", mrb_fixnum_value(2));
  
  // CENTER = 4;                                                   
  mrb_define_const(mrb, module, "CENTER", mrb_fixnum_value(4));
  
  // RIGHT = 8;                                                   
  mrb_define_const(mrb, module, "RIGHT", mrb_fixnum_value(8));
}

//
////////
////////
// Bindings for: global `int monitor_width`

static mrb_value
mrb_mruby_lvgui_native_monitor_width__get(mrb_state *mrb, mrb_value self)
{
  return mrb_fixnum_value((mrb_int)monitor_width);
}

static mrb_value
mrb_mruby_lvgui_native_monitor_width__set(mrb_state *mrb, mrb_value self)
{
  mrb_get_args(mrb, "i", &(monitor_width));
  
  return mrb_fixnum_value((mrb_int)monitor_width);
}

//
////////
////////
// Bindings for: global `int monitor_height`

static mrb_value
mrb_mruby_lvgui_native_monitor_height__get(mrb_state *mrb, mrb_value self)
{
  return mrb_fixnum_value((mrb_int)monitor_height);
}

static mrb_value
mrb_mruby_lvgui_native_monitor_height__set(mrb_state *mrb, mrb_value self)
{
  mrb_get_args(mrb, "i", &(monitor_height));
  
  return mrb_fixnum_value((mrb_int)monitor_height);
}

//
////////
////////
// Bindings for: global `int mn_hal_default_dpi`

static mrb_value
mrb_mruby_lvgui_native_mn_hal_default_dpi__get(mrb_state *mrb, mrb_value self)
{
  return mrb_fixnum_value((mrb_int)mn_hal_default_dpi);
}

static mrb_value
mrb_mruby_lvgui_native_mn_hal_default_dpi__set(mrb_state *mrb, mrb_value self)
{
  mrb_get_args(mrb, "i", &(mn_hal_default_dpi));
  
  return mrb_fixnum_value((mrb_int)mn_hal_default_dpi);
}

//
////////
////////
// Bindings for: global `void * mn_hal_default_font`

static mrb_value
mrb_mruby_lvgui_native_mn_hal_default_font__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) mn_hal_default_font);
}

static mrb_value
mrb_mruby_lvgui_native_mn_hal_default_font__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (void *) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_scr`

static mrb_value
mrb_mruby_lvgui_native_lv_style_scr__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_scr);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_scr__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_transp`

static mrb_value
mrb_mruby_lvgui_native_lv_style_transp__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_transp);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_transp__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_transp_tight`

static mrb_value
mrb_mruby_lvgui_native_lv_style_transp_tight__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_transp_tight);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_transp_tight__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_transp_fit`

static mrb_value
mrb_mruby_lvgui_native_lv_style_transp_fit__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_transp_fit);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_transp_fit__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_plain`

static mrb_value
mrb_mruby_lvgui_native_lv_style_plain__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_plain);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_plain__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_plain_color`

static mrb_value
mrb_mruby_lvgui_native_lv_style_plain_color__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_plain_color);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_plain_color__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_pretty`

static mrb_value
mrb_mruby_lvgui_native_lv_style_pretty__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_pretty);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_pretty__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_pretty_color`

static mrb_value
mrb_mruby_lvgui_native_lv_style_pretty_color__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_pretty_color);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_pretty_color__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_btn_rel`

static mrb_value
mrb_mruby_lvgui_native_lv_style_btn_rel__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_btn_rel);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_btn_rel__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_btn_pr`

static mrb_value
mrb_mruby_lvgui_native_lv_style_btn_pr__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_btn_pr);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_btn_pr__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_btn_tgl_rel`

static mrb_value
mrb_mruby_lvgui_native_lv_style_btn_tgl_rel__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_btn_tgl_rel);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_btn_tgl_rel__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_btn_tgl_pr`

static mrb_value
mrb_mruby_lvgui_native_lv_style_btn_tgl_pr__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_btn_tgl_pr);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_btn_tgl_pr__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_style_t* lv_style_btn_ina`

static mrb_value
mrb_mruby_lvgui_native_lv_style_btn_ina__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_style_btn_ina);
}

static mrb_value
mrb_mruby_lvgui_native_lv_style_btn_ina__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_style_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_anim_path_cb_t* lv_anim_path_linear`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_linear__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_anim_path_linear);
}

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_linear__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_anim_path_cb_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_anim_path_cb_t* lv_anim_path_step`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_step__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_anim_path_step);
}

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_step__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_anim_path_cb_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_anim_path_cb_t* lv_anim_path_ease_in`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_ease_in__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_anim_path_ease_in);
}

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_ease_in__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_anim_path_cb_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_anim_path_cb_t* lv_anim_path_ease_out`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_ease_out__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_anim_path_ease_out);
}

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_ease_out__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_anim_path_cb_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_anim_path_cb_t* lv_anim_path_ease_in_out`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_ease_in_out__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_anim_path_ease_in_out);
}

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_ease_in_out__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_anim_path_cb_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_anim_path_cb_t* lv_anim_path_overshoot`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_overshoot__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_anim_path_overshoot);
}

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_overshoot__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_anim_path_cb_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: global `lv_anim_path_cb_t* lv_anim_path_bounce`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_bounce__get(mrb_state *mrb, mrb_value self)
{
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) &lv_anim_path_bounce);
}

static mrb_value
mrb_mruby_lvgui_native_lv_anim_path_bounce__set(mrb_state *mrb, mrb_value self)
{
  mrb_raisef(mrb, E_RUNTIME_ERROR, "error: can't set complex types (lv_anim_path_cb_t*) with current generated bindings.");
  
  return mrb_nil_value();
}

//
////////
////////
// Bindings for: `lv_style_t * lvgui_allocate_lv_style()`

static mrb_value
mrb_mruby_lvgui_native_lvgui_allocate_lv_style(mrb_state *mrb, mrb_value self)
{
    lv_style_t * ret;
  
  
  
  
    // Calling native function
    ret = lvgui_allocate_lv_style();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `uint8_t lvgui_get_lv_style__glass(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__glass(mrb_state *mrb, mrb_value self)
{
    uint8_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__glass(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__glass(lv_style_t * unnamed_parameter_0, uint8_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__glass(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint8_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint8_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint8_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__glass(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_color_t lvgui_get_lv_style__body_main_color(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_main_color(mrb_state *mrb, mrb_value self)
{
    lv_color_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_main_color(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)(ret.full));
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_main_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_main_color(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_color_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_color_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1.full = (uint32_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_main_color(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_color_t lvgui_get_lv_style__body_grad_color(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_grad_color(mrb_state *mrb, mrb_value self)
{
    lv_color_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_grad_color(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)(ret.full));
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_grad_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_grad_color(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_color_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_color_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1.full = (uint32_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_grad_color(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lvgui_get_lv_style__body_radius(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_radius(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_radius(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_radius(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_radius(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_radius(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_opa_t lvgui_get_lv_style__body_opa(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_opa(mrb_state *mrb, mrb_value self)
{
    lv_opa_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_opa(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_opa(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_opa(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_opa_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_opa_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_opa_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_opa(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_color_t lvgui_get_lv_style__body_border_color(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_border_color(mrb_state *mrb, mrb_value self)
{
    lv_color_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_border_color(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)(ret.full));
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_border_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_border_color(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_color_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_color_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1.full = (uint32_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_border_color(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lvgui_get_lv_style__body_border_width(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_border_width(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_border_width(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_border_width(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_border_width(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_border_width(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_border_part_t lvgui_get_lv_style__body_border_part(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_border_part(mrb_state *mrb, mrb_value self)
{
    lv_border_part_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_border_part(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_border_part(lv_style_t * unnamed_parameter_0, lv_border_part_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_border_part(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_border_part_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_border_part_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_border_part_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_border_part(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_opa_t lvgui_get_lv_style__body_border_opa(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_border_opa(mrb_state *mrb, mrb_value self)
{
    lv_opa_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_border_opa(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_border_opa(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_border_opa(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_opa_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_opa_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_opa_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_border_opa(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_color_t lvgui_get_lv_style__body_shadow_color(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_shadow_color(mrb_state *mrb, mrb_value self)
{
    lv_color_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_shadow_color(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)(ret.full));
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_shadow_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_shadow_color(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_color_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_color_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1.full = (uint32_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_shadow_color(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lvgui_get_lv_style__body_shadow_width(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_shadow_width(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_shadow_width(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_shadow_width(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_shadow_width(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_shadow_width(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_shadow_type_t lvgui_get_lv_style__body_shadow_type(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_shadow_type(mrb_state *mrb, mrb_value self)
{
    lv_shadow_type_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_shadow_type(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_shadow_type(lv_style_t * unnamed_parameter_0, lv_shadow_type_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_shadow_type(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_shadow_type_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_shadow_type_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_shadow_type_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_shadow_type(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lvgui_get_lv_style__body_padding_top(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_padding_top(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_padding_top(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_padding_top(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_padding_top(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_padding_top(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lvgui_get_lv_style__body_padding_bottom(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_padding_bottom(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_padding_bottom(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_padding_bottom(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_padding_bottom(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_padding_bottom(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lvgui_get_lv_style__body_padding_left(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_padding_left(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_padding_left(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_padding_left(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_padding_left(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_padding_left(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lvgui_get_lv_style__body_padding_right(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_padding_right(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_padding_right(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_padding_right(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_padding_right(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_padding_right(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lvgui_get_lv_style__body_padding_inner(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__body_padding_inner(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__body_padding_inner(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__body_padding_inner(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__body_padding_inner(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__body_padding_inner(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_color_t lvgui_get_lv_style__text_color(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__text_color(mrb_state *mrb, mrb_value self)
{
    lv_color_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__text_color(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)(ret.full));
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__text_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__text_color(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_color_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_color_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1.full = (uint32_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__text_color(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_color_t lvgui_get_lv_style__text_sel_color(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__text_sel_color(mrb_state *mrb, mrb_value self)
{
    lv_color_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__text_sel_color(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)(ret.full));
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__text_sel_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__text_sel_color(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_color_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_color_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1.full = (uint32_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__text_sel_color(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_font_t * lvgui_get_lv_style__text_font(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__text_font(mrb_state *mrb, mrb_value self)
{
    const lv_font_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__text_font(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__text_font(lv_style_t * unnamed_parameter_0, lv_font_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__text_font(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_font_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    lv_font_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    lvgui_set_lv_style__text_font(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lvgui_get_lv_style__text_letter_space(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__text_letter_space(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__text_letter_space(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__text_letter_space(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__text_letter_space(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__text_letter_space(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lvgui_get_lv_style__text_line_space(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__text_line_space(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__text_line_space(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__text_line_space(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__text_line_space(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__text_line_space(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_opa_t lvgui_get_lv_style__text_opa(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__text_opa(mrb_state *mrb, mrb_value self)
{
    lv_opa_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__text_opa(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__text_opa(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__text_opa(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_opa_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_opa_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_opa_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__text_opa(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_color_t lvgui_get_lv_style__image_color(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__image_color(mrb_state *mrb, mrb_value self)
{
    lv_color_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__image_color(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)(ret.full));
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__image_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__image_color(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_color_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_color_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1.full = (uint32_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__image_color(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_opa_t lvgui_get_lv_style__image_intense(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__image_intense(mrb_state *mrb, mrb_value self)
{
    lv_opa_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__image_intense(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__image_intense(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__image_intense(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_opa_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_opa_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_opa_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__image_intense(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_opa_t lvgui_get_lv_style__image_opa(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__image_opa(mrb_state *mrb, mrb_value self)
{
    lv_opa_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__image_opa(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__image_opa(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__image_opa(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_opa_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_opa_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_opa_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__image_opa(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_color_t lvgui_get_lv_style__line_color(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__line_color(mrb_state *mrb, mrb_value self)
{
    lv_color_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__line_color(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)(ret.full));
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__line_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__line_color(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_color_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_color_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1.full = (uint32_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__line_color(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lvgui_get_lv_style__line_width(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__line_width(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__line_width(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__line_width(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__line_width(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__line_width(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_opa_t lvgui_get_lv_style__line_opa(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__line_opa(mrb_state *mrb, mrb_value self)
{
    lv_opa_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__line_opa(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__line_opa(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__line_opa(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_opa_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_opa_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_opa_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__line_opa(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `uint8_t lvgui_get_lv_style__line_rounded(lv_style_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_lv_style__line_rounded(mrb_state *mrb, mrb_value self)
{
    uint8_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lvgui_get_lv_style__line_rounded(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lvgui_set_lv_style__line_rounded(lv_style_t * unnamed_parameter_0, uint8_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_set_lv_style__line_rounded(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint8_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint8_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint8_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lvgui_set_lv_style__line_rounded(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void hal_init(const char * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_hal_init(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const char * unnamed_parameter_0`
    const char * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "z",
      &param_unnamed_parameter_0
    );
  
  
    // Calling native function
    hal_init(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_bmp_init()`

static mrb_value
mrb_mruby_lvgui_native_lv_bmp_init(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
  
  
  
    // Calling native function
    lv_bmp_init();
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_nanosvg_init()`

static mrb_value
mrb_mruby_lvgui_native_lv_nanosvg_init(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
  
  
  
    // Calling native function
    lv_nanosvg_init();
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_anim_t * lvgui_allocate_lv_anim()`

static mrb_value
mrb_mruby_lvgui_native_lvgui_allocate_lv_anim(mrb_state *mrb, mrb_value self)
{
    lv_anim_t * ret;
  
  
  
  
    // Calling native function
    ret = lvgui_allocate_lv_anim();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `bool lv_introspection_is_simulator()`

static mrb_value
mrb_mruby_lvgui_native_lv_introspection_is_simulator(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
  
  
  
    // Calling native function
    ret = lv_introspection_is_simulator();
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `bool lv_introspection_is_debug()`

static mrb_value
mrb_mruby_lvgui_native_lv_introspection_is_debug(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
  
  
  
    // Calling native function
    ret = lv_introspection_is_debug();
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `bool lv_introspection_use_assert_style()`

static mrb_value
mrb_mruby_lvgui_native_lv_introspection_use_assert_style(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
  
  
  
    // Calling native function
    ret = lv_introspection_use_assert_style();
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `const char * lv_introspection_display_driver()`

static mrb_value
mrb_mruby_lvgui_native_lv_introspection_display_driver(mrb_state *mrb, mrb_value self)
{
    const char * ret;
  
  
  
  
    // Calling native function
    ret = lv_introspection_display_driver();
  
    // Converts return value back to a valid mruby value
    return mrb_str_new_cstr(mrb, ret);
}

//
////////

////////
// Bindings for: `void lv_theme_set_current(lv_theme_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_theme_set_current(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_theme_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_theme_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_theme_set_current(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_theme_t * lv_theme_get_current()`

static mrb_value
mrb_mruby_lvgui_native_lv_theme_get_current(mrb_state *mrb, mrb_value self)
{
    lv_theme_t * ret;
  
  
  
  
    // Calling native function
    ret = lv_theme_get_current();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_theme_t * lv_theme_mono_init(uint16_t unnamed_parameter_0, lv_font_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_theme_mono_init(mrb_state *mrb, mrb_value self)
{
    lv_theme_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `uint16_t unnamed_parameter_0`
    mrb_int param_unnamed_parameter_0_int;
    uint16_t param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_font_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    lv_font_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "io",
      &param_unnamed_parameter_0_int,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = (uint16_t)param_unnamed_parameter_0_int;
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_theme_mono_init(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_theme_t * lv_theme_get_mono()`

static mrb_value
mrb_mruby_lvgui_native_lv_theme_get_mono(mrb_state *mrb, mrb_value self)
{
    lv_theme_t * ret;
  
  
  
  
    // Calling native function
    ret = lv_theme_get_mono();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_theme_t * lv_theme_night_init(uint16_t unnamed_parameter_0, lv_font_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_theme_night_init(mrb_state *mrb, mrb_value self)
{
    lv_theme_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `uint16_t unnamed_parameter_0`
    mrb_int param_unnamed_parameter_0_int;
    uint16_t param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_font_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    lv_font_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "io",
      &param_unnamed_parameter_0_int,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = (uint16_t)param_unnamed_parameter_0_int;
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_theme_night_init(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_theme_t * lv_theme_get_night()`

static mrb_value
mrb_mruby_lvgui_native_lv_theme_get_night(mrb_state *mrb, mrb_value self)
{
    lv_theme_t * ret;
  
  
  
  
    // Calling native function
    ret = lv_theme_get_night();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_theme_t * lv_theme_nixos_init(lv_font_t * unnamed_parameter_0, lv_font_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_theme_nixos_init(mrb_state *mrb, mrb_value self)
{
    lv_theme_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_font_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_font_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_font_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    lv_font_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_theme_nixos_init(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_theme_t * lv_theme_get_nixos()`

static mrb_value
mrb_mruby_lvgui_native_lv_theme_get_nixos(mrb_state *mrb, mrb_value self)
{
    lv_theme_t * ret;
  
  
  
  
    // Calling native function
    ret = lv_theme_get_nixos();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_obj_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_create(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_obj_create(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `const lv_style_t * lv_obj_get_style(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_get_style(mrb_state *mrb, mrb_value self)
{
    const lv_style_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_obj_get_style(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_obj_set_style(lv_obj_t * unnamed_parameter_0, const lv_style_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_style(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_style_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_style_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    lv_obj_set_style(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_obj_refresh_style(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_refresh_style(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_obj_refresh_style(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lv_obj_get_width(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_get_width(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_obj_get_width(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `lv_coord_t lv_obj_get_height(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_get_height(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_obj_get_height(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `lv_coord_t lv_obj_get_width_fit(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_get_width_fit(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_obj_get_width_fit(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `lv_coord_t lv_obj_get_height_fit(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_get_height_fit(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_obj_get_height_fit(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lv_obj_set_width(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_width(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_obj_set_width(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_obj_set_height(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_height(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_obj_set_height(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lv_obj_get_x(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_get_x(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_obj_get_x(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `lv_coord_t lv_obj_get_y(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_get_y(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_obj_get_y(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `const void * lv_event_get_data()`

static mrb_value
mrb_mruby_lvgui_native_lv_event_get_data(mrb_state *mrb, mrb_value self)
{
    const void * ret;
  
  
  
  
    // Calling native function
    ret = lv_event_get_data();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_obj_set_opa_scale(lv_obj_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_opa_scale(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_opa_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_opa_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_opa_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_obj_set_opa_scale(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_opa_t lv_obj_get_opa_scale(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_get_opa_scale(mrb_state *mrb, mrb_value self)
{
    lv_opa_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_obj_get_opa_scale(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lv_obj_move_foreground(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_move_foreground(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_obj_move_foreground(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_obj_set_pos(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1, lv_coord_t unnamed_parameter_2)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_pos(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_2`
    mrb_int param_unnamed_parameter_2_int;
    lv_coord_t param_unnamed_parameter_2;
    
    mrb_get_args(
      mrb,
      "oii",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int,
      &param_unnamed_parameter_2_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
    param_unnamed_parameter_2 = (lv_coord_t)param_unnamed_parameter_2_int;
  
    // Calling native function
    lv_obj_set_pos(param_unnamed_parameter_0, param_unnamed_parameter_1, param_unnamed_parameter_2);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_obj_set_x(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_x(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_obj_set_x(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_obj_set_y(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_y(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_obj_set_y(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_obj_set_parent(lv_obj_t * unnamed_parameter_0, lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_parent(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    lv_obj_set_parent(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_obj_set_hidden(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_hidden(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_obj_set_hidden(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_obj_set_click(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_click(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_obj_set_click(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_obj_set_top(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_top(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_obj_set_top(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_obj_set_opa_scale_enable(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_opa_scale_enable(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_obj_set_opa_scale_enable(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_obj_set_protect(lv_obj_t * unnamed_parameter_0, lv_protect_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_protect(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_protect_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_protect_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_protect_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_obj_set_protect(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_opa_t lv_obj_get_opa_scale_enable(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_get_opa_scale_enable(mrb_state *mrb, mrb_value self)
{
    lv_opa_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_obj_get_opa_scale_enable(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lv_obj_clean(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_clean(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_obj_clean(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_res_t lv_obj_del(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_del(mrb_state *mrb, mrb_value self)
{
    lv_res_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_obj_del(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lv_obj_del_async(struct _lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_del_async(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `struct _lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    struct _lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_obj_del_async(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_obj_get_parent(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_get_parent(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_obj_get_parent(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `bool lv_obj_is_children(const lv_obj_t * obj, const lv_obj_t * target)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_is_children(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * obj`
    mrb_value param_obj_instance;
    const lv_obj_t * param_obj;
    // Parameter handling for native parameter `const lv_obj_t * target`
    mrb_value param_target_instance;
    const lv_obj_t * param_target;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_obj_instance,
      &param_target_instance
    );
    param_obj = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_obj_instance
    );
    param_target = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_target_instance
    );
  
    // Calling native function
    ret = lv_obj_is_children(param_obj, param_target);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_btn_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_btn_create(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_btn_create(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_btn_set_ink_in_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_btn_set_ink_in_time(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint16_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint16_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_btn_set_ink_in_time(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_btn_set_ink_wait_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_btn_set_ink_wait_time(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint16_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint16_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_btn_set_ink_wait_time(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_btn_set_ink_out_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_btn_set_ink_out_time(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint16_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint16_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_btn_set_ink_out_time(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_btn_set_style(lv_obj_t * unnamed_parameter_0, lv_btn_style_t unnamed_parameter_1, const lv_style_t * unnamed_parameter_2)`

static mrb_value
mrb_mruby_lvgui_native_lv_btn_set_style(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_btn_style_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_btn_style_t param_unnamed_parameter_1;
    // Parameter handling for native parameter `const lv_style_t * unnamed_parameter_2`
    mrb_value param_unnamed_parameter_2_instance;
    const lv_style_t * param_unnamed_parameter_2;
    
    mrb_get_args(
      mrb,
      "oio",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int,
      &param_unnamed_parameter_2_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_btn_style_t)param_unnamed_parameter_1_int;
    param_unnamed_parameter_2 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_2_instance
    );
  
    // Calling native function
    lv_btn_set_style(param_unnamed_parameter_0, param_unnamed_parameter_1, param_unnamed_parameter_2);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `const lv_style_t * lv_btn_get_style(const lv_obj_t * unnamed_parameter_0, lv_btn_style_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_btn_get_style(mrb_state *mrb, mrb_value self)
{
    const lv_style_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_btn_style_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_btn_style_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_btn_style_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    ret = lv_btn_get_style(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_cont_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_cont_create(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_cont_create(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_cont_set_layout(lv_obj_t * unnamed_parameter_0, lv_layout_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_cont_set_layout(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_layout_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_layout_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_layout_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_cont_set_layout(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_cont_set_fit4(lv_obj_t * unnamed_parameter_0, lv_fit_t unnamed_parameter_1, lv_fit_t unnamed_parameter_2, lv_fit_t unnamed_parameter_3, lv_fit_t unnamed_parameter_4)`

static mrb_value
mrb_mruby_lvgui_native_lv_cont_set_fit4(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_fit_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_fit_t param_unnamed_parameter_1;
    // Parameter handling for native parameter `lv_fit_t unnamed_parameter_2`
    mrb_int param_unnamed_parameter_2_int;
    lv_fit_t param_unnamed_parameter_2;
    // Parameter handling for native parameter `lv_fit_t unnamed_parameter_3`
    mrb_int param_unnamed_parameter_3_int;
    lv_fit_t param_unnamed_parameter_3;
    // Parameter handling for native parameter `lv_fit_t unnamed_parameter_4`
    mrb_int param_unnamed_parameter_4_int;
    lv_fit_t param_unnamed_parameter_4;
    
    mrb_get_args(
      mrb,
      "oiiii",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int,
      &param_unnamed_parameter_2_int,
      &param_unnamed_parameter_3_int,
      &param_unnamed_parameter_4_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_fit_t)param_unnamed_parameter_1_int;
    param_unnamed_parameter_2 = (lv_fit_t)param_unnamed_parameter_2_int;
    param_unnamed_parameter_3 = (lv_fit_t)param_unnamed_parameter_3_int;
    param_unnamed_parameter_4 = (lv_fit_t)param_unnamed_parameter_4_int;
  
    // Calling native function
    lv_cont_set_fit4(param_unnamed_parameter_0, param_unnamed_parameter_1, param_unnamed_parameter_2, param_unnamed_parameter_3, param_unnamed_parameter_4);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_cont_set_fit2(lv_obj_t * unnamed_parameter_0, lv_fit_t unnamed_parameter_1, lv_fit_t unnamed_parameter_2)`

static mrb_value
mrb_mruby_lvgui_native_lv_cont_set_fit2(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_fit_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_fit_t param_unnamed_parameter_1;
    // Parameter handling for native parameter `lv_fit_t unnamed_parameter_2`
    mrb_int param_unnamed_parameter_2_int;
    lv_fit_t param_unnamed_parameter_2;
    
    mrb_get_args(
      mrb,
      "oii",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int,
      &param_unnamed_parameter_2_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_fit_t)param_unnamed_parameter_1_int;
    param_unnamed_parameter_2 = (lv_fit_t)param_unnamed_parameter_2_int;
  
    // Calling native function
    lv_cont_set_fit2(param_unnamed_parameter_0, param_unnamed_parameter_1, param_unnamed_parameter_2);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_cont_set_fit(lv_obj_t * unnamed_parameter_0, lv_fit_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_cont_set_fit(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_fit_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_fit_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_fit_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_cont_set_fit(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_disp_get_scr_act(lv_disp_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_disp_get_scr_act(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_disp_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_disp_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_disp_get_scr_act(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_disp_load_scr(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_disp_load_scr(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_disp_load_scr(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_disp_t * lv_disp_get_default()`

static mrb_value
mrb_mruby_lvgui_native_lv_disp_get_default(mrb_state *mrb, mrb_value self)
{
    lv_disp_t * ret;
  
  
  
  
    // Calling native function
    ret = lv_disp_get_default();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_scr_act()`

static mrb_value
mrb_mruby_lvgui_native_lv_scr_act(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
  
  
  
    // Calling native function
    ret = lv_scr_act();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_layer_top()`

static mrb_value
mrb_mruby_lvgui_native_lv_layer_top(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
  
  
  
    // Calling native function
    ret = lv_layer_top();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_layer_sys()`

static mrb_value
mrb_mruby_lvgui_native_lv_layer_sys(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
  
  
  
    // Calling native function
    ret = lv_layer_sys();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_img_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_img_create(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_img_create(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_img_set_src(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_img_set_src(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const char * unnamed_parameter_1`
    const char * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oz",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_img_set_src(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_img_dsc_t * lv_img_buf_alloc(lv_coord_t w, lv_coord_t h, lv_img_cf_t cf)`

static mrb_value
mrb_mruby_lvgui_native_lv_img_buf_alloc(mrb_state *mrb, mrb_value self)
{
    lv_img_dsc_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_coord_t w`
    mrb_int param_w_int;
    lv_coord_t param_w;
    // Parameter handling for native parameter `lv_coord_t h`
    mrb_int param_h_int;
    lv_coord_t param_h;
    // Parameter handling for native parameter `lv_img_cf_t cf`
    mrb_int param_cf_int;
    lv_img_cf_t param_cf;
    
    mrb_get_args(
      mrb,
      "iii",
      &param_w_int,
      &param_h_int,
      &param_cf_int
    );
    param_w = (lv_coord_t)param_w_int;
    param_h = (lv_coord_t)param_h_int;
    param_cf = (lv_img_cf_t)param_cf_int;
  
    // Calling native function
    ret = lv_img_buf_alloc(param_w, param_h, param_cf);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_img_buf_free(lv_img_dsc_t * dsc)`

static mrb_value
mrb_mruby_lvgui_native_lv_img_buf_free(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_img_dsc_t * dsc`
    mrb_value param_dsc_instance;
    lv_img_dsc_t * param_dsc;
    
    mrb_get_args(
      mrb,
      "o",
      &param_dsc_instance
    );
    param_dsc = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_dsc_instance
    );
  
    // Calling native function
    lv_img_buf_free(param_dsc);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_sw_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_sw_create(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_sw_create(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_sw_on(lv_obj_t * unnamed_parameter_0, lv_anim_enable_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_sw_on(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_anim_enable_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_anim_enable_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_anim_enable_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_sw_on(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_sw_off(lv_obj_t * unnamed_parameter_0, lv_anim_enable_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_sw_off(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_anim_enable_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_anim_enable_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_anim_enable_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_sw_off(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_sw_toggle(lv_obj_t * unnamed_parameter_0, lv_anim_enable_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_sw_toggle(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_anim_enable_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_anim_enable_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_anim_enable_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_sw_toggle(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_sw_set_style(lv_obj_t * unnamed_parameter_0, lv_sw_style_t unnamed_parameter_1, const lv_style_t * unnamed_parameter_2)`

static mrb_value
mrb_mruby_lvgui_native_lv_sw_set_style(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_sw_style_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_sw_style_t param_unnamed_parameter_1;
    // Parameter handling for native parameter `const lv_style_t * unnamed_parameter_2`
    mrb_value param_unnamed_parameter_2_instance;
    const lv_style_t * param_unnamed_parameter_2;
    
    mrb_get_args(
      mrb,
      "oio",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int,
      &param_unnamed_parameter_2_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_sw_style_t)param_unnamed_parameter_1_int;
    param_unnamed_parameter_2 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_2_instance
    );
  
    // Calling native function
    lv_sw_set_style(param_unnamed_parameter_0, param_unnamed_parameter_1, param_unnamed_parameter_2);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_sw_set_anim_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_sw_set_anim_time(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint16_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint16_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_sw_set_anim_time(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `bool lv_sw_get_state(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_sw_get_state(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_sw_get_state(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `uint16_t lv_sw_get_anim_time(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_sw_get_anim_time(mrb_state *mrb, mrb_value self)
{
    uint16_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_sw_get_anim_time(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_label_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_label_create(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_label_create(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_label_set_text(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_label_set_text(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const char * unnamed_parameter_1`
    const char * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oz",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_label_set_text(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_label_set_long_mode(lv_obj_t * unnamed_parameter_0, lv_label_long_mode_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_label_set_long_mode(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_label_long_mode_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_label_long_mode_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_label_long_mode_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_label_set_long_mode(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_label_set_align(lv_obj_t * unnamed_parameter_0, lv_label_align_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_label_set_align(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_label_align_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_label_align_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_label_align_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_label_set_align(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_page_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_create(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_page_create(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_page_clean(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_clean(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_page_clean(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_page_get_scrl(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_get_scrl(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_page_get_scrl(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_page_set_scrl_layout(lv_obj_t * unnamed_parameter_0, lv_layout_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_set_scrl_layout(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_layout_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_layout_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_layout_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_page_set_scrl_layout(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_page_glue_obj(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_glue_obj(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_page_glue_obj(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `const lv_style_t * lv_page_get_style(const lv_obj_t * unnamed_parameter_0, lv_page_style_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_get_style(mrb_state *mrb, mrb_value self)
{
    const lv_style_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_page_style_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_page_style_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_page_style_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    ret = lv_page_get_style(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_page_set_style(lv_obj_t * unnamed_parameter_0, lv_page_style_t unnamed_parameter_1, const lv_style_t * unnamed_parameter_2)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_set_style(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_page_style_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_page_style_t param_unnamed_parameter_1;
    // Parameter handling for native parameter `const lv_style_t * unnamed_parameter_2`
    mrb_value param_unnamed_parameter_2_instance;
    const lv_style_t * param_unnamed_parameter_2;
    
    mrb_get_args(
      mrb,
      "oio",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int,
      &param_unnamed_parameter_2_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_page_style_t)param_unnamed_parameter_1_int;
    param_unnamed_parameter_2 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_2_instance
    );
  
    // Calling native function
    lv_page_set_style(param_unnamed_parameter_0, param_unnamed_parameter_1, param_unnamed_parameter_2);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_page_focus(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1, lv_anim_enable_t unnamed_parameter_2)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_focus(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_obj_t * param_unnamed_parameter_1;
    // Parameter handling for native parameter `lv_anim_enable_t unnamed_parameter_2`
    mrb_int param_unnamed_parameter_2_int;
    lv_anim_enable_t param_unnamed_parameter_2;
    
    mrb_get_args(
      mrb,
      "ooi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance,
      &param_unnamed_parameter_2_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_2 = (lv_anim_enable_t)param_unnamed_parameter_2_int;
  
    // Calling native function
    lv_page_focus(param_unnamed_parameter_0, param_unnamed_parameter_1, param_unnamed_parameter_2);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_page_set_scrl_width(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_set_scrl_width(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_page_set_scrl_width(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_page_set_scrl_height(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_set_scrl_height(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_coord_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_coord_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_coord_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_page_set_scrl_height(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_coord_t lv_page_get_scrl_width(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_get_scrl_width(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_page_get_scrl_width(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `lv_coord_t lv_page_get_scrl_height(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_page_get_scrl_height(mrb_state *mrb, mrb_value self)
{
    lv_coord_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_page_get_scrl_height(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_kb_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_kb_create(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_kb_create(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_kb_set_ta(lv_obj_t * unnamed_parameter_0, lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_kb_set_ta(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    lv_kb_set_ta(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_kb_set_mode(lv_obj_t * unnamed_parameter_0, lv_kb_mode_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_kb_set_mode(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_kb_mode_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_kb_mode_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_kb_mode_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_kb_set_mode(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_kb_set_cursor_manage(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_kb_set_cursor_manage(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_kb_set_cursor_manage(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_kb_set_style(lv_obj_t * unnamed_parameter_0, lv_kb_style_t unnamed_parameter_1, const lv_style_t * unnamed_parameter_2)`

static mrb_value
mrb_mruby_lvgui_native_lv_kb_set_style(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_kb_style_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_kb_style_t param_unnamed_parameter_1;
    // Parameter handling for native parameter `const lv_style_t * unnamed_parameter_2`
    mrb_value param_unnamed_parameter_2_instance;
    const lv_style_t * param_unnamed_parameter_2;
    
    mrb_get_args(
      mrb,
      "oio",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int,
      &param_unnamed_parameter_2_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_kb_style_t)param_unnamed_parameter_1_int;
    param_unnamed_parameter_2 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_2_instance
    );
  
    // Calling native function
    lv_kb_set_style(param_unnamed_parameter_0, param_unnamed_parameter_1, param_unnamed_parameter_2);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_kb_get_ta(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_kb_get_ta(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_kb_get_ta(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_kb_mode_t lv_kb_get_mode(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_kb_get_mode(mrb_state *mrb, mrb_value self)
{
    lv_kb_mode_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_kb_get_mode(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `bool lv_kb_get_cursor_manage(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_kb_get_cursor_manage(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_kb_get_cursor_manage(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `const char ** lv_kb_get_map_array(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_kb_get_map_array(mrb_state *mrb, mrb_value self)
{
    const char ** ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_kb_get_map_array(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `const lv_style_t * lv_kb_get_style(const lv_obj_t * unnamed_parameter_0, lv_kb_style_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_kb_get_style(mrb_state *mrb, mrb_value self)
{
    const lv_style_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_kb_style_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_kb_style_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_kb_style_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    ret = lv_kb_get_style(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_kb_def_event_cb(lv_obj_t * unnamed_parameter_0, lv_event_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_kb_def_event_cb(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_event_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_event_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_event_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_kb_def_event_cb(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_ta_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_create(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    ret = lv_ta_create(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_ta_add_char(lv_obj_t * unnamed_parameter_0, uint32_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_add_char(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint32_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint32_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint32_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_add_char(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_add_text(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_add_text(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const char * unnamed_parameter_1`
    const char * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oz",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_add_text(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_del_char(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_del_char(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_del_char(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_del_char_forward(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_del_char_forward(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_del_char_forward(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_text(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_text(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const char * unnamed_parameter_1`
    const char * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oz",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_set_text(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_placeholder_text(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_placeholder_text(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const char * unnamed_parameter_1`
    const char * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oz",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_set_placeholder_text(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_cursor_pos(lv_obj_t * unnamed_parameter_0, int16_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_cursor_pos(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `int16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    int16_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (int16_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_cursor_pos(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_cursor_type(lv_obj_t * unnamed_parameter_0, lv_cursor_type_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_cursor_type(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_cursor_type_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_cursor_type_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_cursor_type_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_cursor_type(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_cursor_click_pos(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_cursor_click_pos(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_cursor_click_pos(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_pwd_mode(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_pwd_mode(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_pwd_mode(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_one_line(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_one_line(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_one_line(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_text_align(lv_obj_t * unnamed_parameter_0, lv_label_align_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_text_align(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_label_align_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_label_align_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_label_align_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_text_align(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_accepted_chars(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_accepted_chars(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const char * unnamed_parameter_1`
    const char * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oz",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_set_accepted_chars(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_max_length(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_max_length(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint16_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint16_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_max_length(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_insert_replace(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_insert_replace(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const char * unnamed_parameter_1`
    const char * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oz",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_set_insert_replace(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_sb_mode(lv_obj_t * unnamed_parameter_0, lv_sb_mode_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_sb_mode(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_sb_mode_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_sb_mode_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_sb_mode_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_sb_mode(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_scroll_propagation(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_scroll_propagation(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_scroll_propagation(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_edge_flash(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_edge_flash(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_edge_flash(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_style(lv_obj_t * unnamed_parameter_0, lv_ta_style_t unnamed_parameter_1, const lv_style_t * unnamed_parameter_2)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_style(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_ta_style_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_ta_style_t param_unnamed_parameter_1;
    // Parameter handling for native parameter `const lv_style_t * unnamed_parameter_2`
    mrb_value param_unnamed_parameter_2_instance;
    const lv_style_t * param_unnamed_parameter_2;
    
    mrb_get_args(
      mrb,
      "oio",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int,
      &param_unnamed_parameter_2_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_ta_style_t)param_unnamed_parameter_1_int;
    param_unnamed_parameter_2 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_2_instance
    );
  
    // Calling native function
    lv_ta_set_style(param_unnamed_parameter_0, param_unnamed_parameter_1, param_unnamed_parameter_2);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_text_sel(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_text_sel(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_text_sel(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_pwd_show_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_pwd_show_time(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint16_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint16_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_pwd_show_time(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_set_cursor_blink_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_set_cursor_blink_time(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint16_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint16_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_ta_set_cursor_blink_time(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `const char * lv_ta_get_text(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_text(mrb_state *mrb, mrb_value self)
{
    const char * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_text(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_str_new_cstr(mrb, ret);
}

//
////////

////////
// Bindings for: `const char * lv_ta_get_placeholder_text(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_placeholder_text(mrb_state *mrb, mrb_value self)
{
    const char * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_placeholder_text(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_str_new_cstr(mrb, ret);
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_ta_get_label(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_label(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_label(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `uint16_t lv_ta_get_cursor_pos(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_cursor_pos(mrb_state *mrb, mrb_value self)
{
    uint16_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_cursor_pos(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `lv_cursor_type_t lv_ta_get_cursor_type(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_cursor_type(mrb_state *mrb, mrb_value self)
{
    lv_cursor_type_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_cursor_type(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `bool lv_ta_get_cursor_click_pos(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_cursor_click_pos(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_cursor_click_pos(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `bool lv_ta_get_pwd_mode(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_pwd_mode(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_pwd_mode(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `bool lv_ta_get_one_line(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_one_line(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_one_line(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `const char * lv_ta_get_accepted_chars(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_accepted_chars(mrb_state *mrb, mrb_value self)
{
    const char * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_accepted_chars(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_str_new_cstr(mrb, ret);
}

//
////////

////////
// Bindings for: `uint16_t lv_ta_get_max_length(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_max_length(mrb_state *mrb, mrb_value self)
{
    uint16_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_max_length(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `lv_sb_mode_t lv_ta_get_sb_mode(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_sb_mode(mrb_state *mrb, mrb_value self)
{
    lv_sb_mode_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_sb_mode(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `bool lv_ta_get_scroll_propagation(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_scroll_propagation(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_scroll_propagation(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `bool lv_ta_get_edge_flash(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_edge_flash(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_edge_flash(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `const lv_style_t * lv_ta_get_style(const lv_obj_t * unnamed_parameter_0, lv_ta_style_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_style(mrb_state *mrb, mrb_value self)
{
    const lv_style_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_ta_style_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_ta_style_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_ta_style_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    ret = lv_ta_get_style(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `bool lv_ta_text_is_selected(const lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_text_is_selected(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_text_is_selected(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `bool lv_ta_get_text_sel_en(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_text_sel_en(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_text_sel_en(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `uint16_t lv_ta_get_pwd_show_time(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_pwd_show_time(mrb_state *mrb, mrb_value self)
{
    uint16_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_pwd_show_time(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `uint16_t lv_ta_get_cursor_blink_time(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_get_cursor_blink_time(mrb_state *mrb, mrb_value self)
{
    uint16_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_ta_get_cursor_blink_time(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lv_ta_clear_selection(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_clear_selection(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_clear_selection(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_cursor_right(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_cursor_right(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_cursor_right(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_cursor_left(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_cursor_left(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_cursor_left(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_cursor_down(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_cursor_down(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_cursor_down(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_ta_cursor_up(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_ta_cursor_up(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_ta_cursor_up(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_style_copy(lv_style_t * unnamed_parameter_0, const lv_style_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_style_copy(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_style_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_style_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `const lv_style_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    const lv_style_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    lv_style_copy(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_anim_init(lv_anim_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_init(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_anim_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_anim_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_anim_init(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_anim_create(lv_anim_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_create(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_anim_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_anim_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_anim_create(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_anim_clear_repeat(lv_anim_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_clear_repeat(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_anim_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_anim_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_anim_clear_repeat(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_anim_set_repeat(lv_anim_t * unnamed_parameter_0, uint16_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_set_repeat(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_anim_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_anim_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint16_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint16_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_anim_set_repeat(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_anim_set_playback(lv_anim_t * unnamed_parameter_0, uint16_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_set_playback(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_anim_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_anim_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint16_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (uint16_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_anim_set_playback(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_anim_set_time(lv_anim_t * unnamed_parameter_0, int16_t unnamed_parameter_1, int16_t unnamed_parameter_2)`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_set_time(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_anim_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_anim_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `int16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    int16_t param_unnamed_parameter_1;
    // Parameter handling for native parameter `int16_t unnamed_parameter_2`
    mrb_int param_unnamed_parameter_2_int;
    int16_t param_unnamed_parameter_2;
    
    mrb_get_args(
      mrb,
      "oii",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int,
      &param_unnamed_parameter_2_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (int16_t)param_unnamed_parameter_1_int;
    param_unnamed_parameter_2 = (int16_t)param_unnamed_parameter_2_int;
  
    // Calling native function
    lv_anim_set_time(param_unnamed_parameter_0, param_unnamed_parameter_1, param_unnamed_parameter_2);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_anim_set_values(lv_anim_t * unnamed_parameter_0, lv_anim_value_t unnamed_parameter_1, lv_anim_value_t unnamed_parameter_2)`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_set_values(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_anim_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_anim_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_anim_value_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    lv_anim_value_t param_unnamed_parameter_1;
    // Parameter handling for native parameter `lv_anim_value_t unnamed_parameter_2`
    mrb_int param_unnamed_parameter_2_int;
    lv_anim_value_t param_unnamed_parameter_2;
    
    mrb_get_args(
      mrb,
      "oii",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int,
      &param_unnamed_parameter_2_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (lv_anim_value_t)param_unnamed_parameter_1_int;
    param_unnamed_parameter_2 = (lv_anim_value_t)param_unnamed_parameter_2_int;
  
    // Calling native function
    lv_anim_set_values(param_unnamed_parameter_0, param_unnamed_parameter_1, param_unnamed_parameter_2);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_color_t lv_color_mix(lv_color_t c1, lv_color_t c2, uint8_t mix)`

static mrb_value
mrb_mruby_lvgui_native_lv_color_mix(mrb_state *mrb, mrb_value self)
{
    lv_color_t ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_color_t c1`
    mrb_int param_c1_int;
    lv_color_t param_c1;
    // Parameter handling for native parameter `lv_color_t c2`
    mrb_int param_c2_int;
    lv_color_t param_c2;
    // Parameter handling for native parameter `uint8_t mix`
    mrb_int param_mix_int;
    uint8_t param_mix;
    
    mrb_get_args(
      mrb,
      "iii",
      &param_c1_int,
      &param_c2_int,
      &param_mix_int
    );
    param_c1.full = (uint32_t)param_c1_int;
    param_c2.full = (uint32_t)param_c2_int;
    param_mix = (uint8_t)param_mix_int;
  
    // Calling native function
    ret = lv_color_mix(param_c1, param_c2, param_mix);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)(ret.full));
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_canvas_create(lv_obj_t * par, const lv_obj_t * copy)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_create(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * par`
    mrb_value param_par_instance;
    lv_obj_t * param_par;
    // Parameter handling for native parameter `const lv_obj_t * copy`
    mrb_value param_copy_instance;
    const lv_obj_t * param_copy;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_par_instance,
      &param_copy_instance
    );
    param_par = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_par_instance
    );
    param_copy = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_copy_instance
    );
  
    // Calling native function
    ret = lv_canvas_create(param_par, param_copy);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_canvas_set_buffer(lv_obj_t * canvas, lv_img_dsc_t * buf, lv_coord_t w, lv_coord_t h, lv_img_cf_t cf)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_set_buffer(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * canvas`
    mrb_value param_canvas_instance;
    lv_obj_t * param_canvas;
    // Parameter handling for native parameter `lv_img_dsc_t * buf`
    mrb_value param_buf_instance;
    lv_img_dsc_t * param_buf;
    // Parameter handling for native parameter `lv_coord_t w`
    mrb_int param_w_int;
    lv_coord_t param_w;
    // Parameter handling for native parameter `lv_coord_t h`
    mrb_int param_h_int;
    lv_coord_t param_h;
    // Parameter handling for native parameter `lv_img_cf_t cf`
    mrb_int param_cf_int;
    lv_img_cf_t param_cf;
    
    mrb_get_args(
      mrb,
      "ooiii",
      &param_canvas_instance,
      &param_buf_instance,
      &param_w_int,
      &param_h_int,
      &param_cf_int
    );
    param_canvas = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_canvas_instance
    );
    param_buf = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_buf_instance
    );
    param_w = (lv_coord_t)param_w_int;
    param_h = (lv_coord_t)param_h_int;
    param_cf = (lv_img_cf_t)param_cf_int;
  
    // Calling native function
    lv_canvas_set_buffer(param_canvas, param_buf, param_w, param_h, param_cf);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_img_dsc_t * lv_canvas_get_img(lv_obj_t * canvas)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_get_img(mrb_state *mrb, mrb_value self)
{
    lv_img_dsc_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * canvas`
    mrb_value param_canvas_instance;
    lv_obj_t * param_canvas;
    
    mrb_get_args(
      mrb,
      "o",
      &param_canvas_instance
    );
    param_canvas = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_canvas_instance
    );
  
    // Calling native function
    ret = lv_canvas_get_img(param_canvas);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lv_canvas_copy_buf(lv_obj_t * canvas, const void * to_copy, lv_coord_t x, lv_coord_t y, lv_coord_t w, lv_coord_t h)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_copy_buf(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * canvas`
    mrb_value param_canvas_instance;
    lv_obj_t * param_canvas;
    // Parameter handling for native parameter `const void * to_copy`
    mrb_value param_to_copy_instance;
    const void * param_to_copy;
    // Parameter handling for native parameter `lv_coord_t x`
    mrb_int param_x_int;
    lv_coord_t param_x;
    // Parameter handling for native parameter `lv_coord_t y`
    mrb_int param_y_int;
    lv_coord_t param_y;
    // Parameter handling for native parameter `lv_coord_t w`
    mrb_int param_w_int;
    lv_coord_t param_w;
    // Parameter handling for native parameter `lv_coord_t h`
    mrb_int param_h_int;
    lv_coord_t param_h;
    
    mrb_get_args(
      mrb,
      "ooiiii",
      &param_canvas_instance,
      &param_to_copy_instance,
      &param_x_int,
      &param_y_int,
      &param_w_int,
      &param_h_int
    );
    param_canvas = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_canvas_instance
    );
    param_to_copy = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_to_copy_instance
    );
    param_x = (lv_coord_t)param_x_int;
    param_y = (lv_coord_t)param_y_int;
    param_w = (lv_coord_t)param_w_int;
    param_h = (lv_coord_t)param_h_int;
  
    // Calling native function
    lv_canvas_copy_buf(param_canvas, param_to_copy, param_x, param_y, param_w, param_h);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_canvas_rotate(lv_obj_t * canvas, lv_img_dsc_t * img, int16_t angle, lv_coord_t offset_x, lv_coord_t offset_y, int32_t pivot_x, int32_t pivot_y)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_rotate(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * canvas`
    mrb_value param_canvas_instance;
    lv_obj_t * param_canvas;
    // Parameter handling for native parameter `lv_img_dsc_t * img`
    mrb_value param_img_instance;
    lv_img_dsc_t * param_img;
    // Parameter handling for native parameter `int16_t angle`
    mrb_int param_angle_int;
    int16_t param_angle;
    // Parameter handling for native parameter `lv_coord_t offset_x`
    mrb_int param_offset_x_int;
    lv_coord_t param_offset_x;
    // Parameter handling for native parameter `lv_coord_t offset_y`
    mrb_int param_offset_y_int;
    lv_coord_t param_offset_y;
    // Parameter handling for native parameter `int32_t pivot_x`
    mrb_int param_pivot_x_int;
    int32_t param_pivot_x;
    // Parameter handling for native parameter `int32_t pivot_y`
    mrb_int param_pivot_y_int;
    int32_t param_pivot_y;
    
    mrb_get_args(
      mrb,
      "ooiiiii",
      &param_canvas_instance,
      &param_img_instance,
      &param_angle_int,
      &param_offset_x_int,
      &param_offset_y_int,
      &param_pivot_x_int,
      &param_pivot_y_int
    );
    param_canvas = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_canvas_instance
    );
    param_img = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_img_instance
    );
    param_angle = (int16_t)param_angle_int;
    param_offset_x = (lv_coord_t)param_offset_x_int;
    param_offset_y = (lv_coord_t)param_offset_y_int;
    param_pivot_x = (int32_t)param_pivot_x_int;
    param_pivot_y = (int32_t)param_pivot_y_int;
  
    // Calling native function
    lv_canvas_rotate(param_canvas, param_img, param_angle, param_offset_x, param_offset_y, param_pivot_x, param_pivot_y);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_canvas_fill_bg(lv_obj_t * canvas, lv_color_t color)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_fill_bg(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * canvas`
    mrb_value param_canvas_instance;
    lv_obj_t * param_canvas;
    // Parameter handling for native parameter `lv_color_t color`
    mrb_int param_color_int;
    lv_color_t param_color;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_canvas_instance,
      &param_color_int
    );
    param_canvas = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_canvas_instance
    );
    param_color.full = (uint32_t)param_color_int;
  
    // Calling native function
    lv_canvas_fill_bg(param_canvas, param_color);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_canvas_draw_rect(lv_obj_t * canvas, lv_coord_t x, lv_coord_t y, lv_coord_t w, lv_coord_t h, const lv_style_t * style)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_draw_rect(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * canvas`
    mrb_value param_canvas_instance;
    lv_obj_t * param_canvas;
    // Parameter handling for native parameter `lv_coord_t x`
    mrb_int param_x_int;
    lv_coord_t param_x;
    // Parameter handling for native parameter `lv_coord_t y`
    mrb_int param_y_int;
    lv_coord_t param_y;
    // Parameter handling for native parameter `lv_coord_t w`
    mrb_int param_w_int;
    lv_coord_t param_w;
    // Parameter handling for native parameter `lv_coord_t h`
    mrb_int param_h_int;
    lv_coord_t param_h;
    // Parameter handling for native parameter `const lv_style_t * style`
    mrb_value param_style_instance;
    const lv_style_t * param_style;
    
    mrb_get_args(
      mrb,
      "oiiiio",
      &param_canvas_instance,
      &param_x_int,
      &param_y_int,
      &param_w_int,
      &param_h_int,
      &param_style_instance
    );
    param_canvas = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_canvas_instance
    );
    param_x = (lv_coord_t)param_x_int;
    param_y = (lv_coord_t)param_y_int;
    param_w = (lv_coord_t)param_w_int;
    param_h = (lv_coord_t)param_h_int;
    param_style = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_style_instance
    );
  
    // Calling native function
    lv_canvas_draw_rect(param_canvas, param_x, param_y, param_w, param_h, param_style);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_canvas_draw_text(lv_obj_t * canvas, lv_coord_t x, lv_coord_t y, lv_coord_t max_w, const lv_style_t * style, const char * txt, lv_label_align_t align)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_draw_text(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * canvas`
    mrb_value param_canvas_instance;
    lv_obj_t * param_canvas;
    // Parameter handling for native parameter `lv_coord_t x`
    mrb_int param_x_int;
    lv_coord_t param_x;
    // Parameter handling for native parameter `lv_coord_t y`
    mrb_int param_y_int;
    lv_coord_t param_y;
    // Parameter handling for native parameter `lv_coord_t max_w`
    mrb_int param_max_w_int;
    lv_coord_t param_max_w;
    // Parameter handling for native parameter `const lv_style_t * style`
    mrb_value param_style_instance;
    const lv_style_t * param_style;
    // Parameter handling for native parameter `const char * txt`
    const char * param_txt;
    // Parameter handling for native parameter `lv_label_align_t align`
    mrb_int param_align_int;
    lv_label_align_t param_align;
    
    mrb_get_args(
      mrb,
      "oiiiozi",
      &param_canvas_instance,
      &param_x_int,
      &param_y_int,
      &param_max_w_int,
      &param_style_instance,
      &param_txt,
      &param_align_int
    );
    param_canvas = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_canvas_instance
    );
    param_x = (lv_coord_t)param_x_int;
    param_y = (lv_coord_t)param_y_int;
    param_max_w = (lv_coord_t)param_max_w_int;
    param_style = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_style_instance
    );
    
    param_align = (lv_label_align_t)param_align_int;
  
    // Calling native function
    lv_canvas_draw_text(param_canvas, param_x, param_y, param_max_w, param_style, param_txt, param_align);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_canvas_draw_img(lv_obj_t * canvas, lv_coord_t x, lv_coord_t y, const char * src, const lv_style_t * style)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_draw_img(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * canvas`
    mrb_value param_canvas_instance;
    lv_obj_t * param_canvas;
    // Parameter handling for native parameter `lv_coord_t x`
    mrb_int param_x_int;
    lv_coord_t param_x;
    // Parameter handling for native parameter `lv_coord_t y`
    mrb_int param_y_int;
    lv_coord_t param_y;
    // Parameter handling for native parameter `const char * src`
    const char * param_src;
    // Parameter handling for native parameter `const lv_style_t * style`
    mrb_value param_style_instance;
    const lv_style_t * param_style;
    
    mrb_get_args(
      mrb,
      "oiizo",
      &param_canvas_instance,
      &param_x_int,
      &param_y_int,
      &param_src,
      &param_style_instance
    );
    param_canvas = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_canvas_instance
    );
    param_x = (lv_coord_t)param_x_int;
    param_y = (lv_coord_t)param_y_int;
    
    param_style = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_style_instance
    );
  
    // Calling native function
    lv_canvas_draw_img(param_canvas, param_x, param_y, param_src, param_style);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_canvas_draw_line(lv_obj_t * canvas, const lv_point_t * points, uint32_t point_cnt, const lv_style_t * style)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_draw_line(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * canvas`
    mrb_value param_canvas_instance;
    lv_obj_t * param_canvas;
    // Parameter handling for native parameter `const lv_point_t * points`
    mrb_value param_points_instance;
    const lv_point_t * param_points;
    // Parameter handling for native parameter `uint32_t point_cnt`
    mrb_int param_point_cnt_int;
    uint32_t param_point_cnt;
    // Parameter handling for native parameter `const lv_style_t * style`
    mrb_value param_style_instance;
    const lv_style_t * param_style;
    
    mrb_get_args(
      mrb,
      "ooio",
      &param_canvas_instance,
      &param_points_instance,
      &param_point_cnt_int,
      &param_style_instance
    );
    param_canvas = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_canvas_instance
    );
    param_points = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_points_instance
    );
    param_point_cnt = (uint32_t)param_point_cnt_int;
    param_style = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_style_instance
    );
  
    // Calling native function
    lv_canvas_draw_line(param_canvas, param_points, param_point_cnt, param_style);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_canvas_draw_polygon(lv_obj_t * canvas, const lv_point_t * points, uint32_t point_cnt, const lv_style_t * style)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_draw_polygon(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * canvas`
    mrb_value param_canvas_instance;
    lv_obj_t * param_canvas;
    // Parameter handling for native parameter `const lv_point_t * points`
    mrb_value param_points_instance;
    const lv_point_t * param_points;
    // Parameter handling for native parameter `uint32_t point_cnt`
    mrb_int param_point_cnt_int;
    uint32_t param_point_cnt;
    // Parameter handling for native parameter `const lv_style_t * style`
    mrb_value param_style_instance;
    const lv_style_t * param_style;
    
    mrb_get_args(
      mrb,
      "ooio",
      &param_canvas_instance,
      &param_points_instance,
      &param_point_cnt_int,
      &param_style_instance
    );
    param_canvas = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_canvas_instance
    );
    param_points = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_points_instance
    );
    param_point_cnt = (uint32_t)param_point_cnt_int;
    param_style = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_style_instance
    );
  
    // Calling native function
    lv_canvas_draw_polygon(param_canvas, param_points, param_point_cnt, param_style);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_canvas_draw_arc(lv_obj_t * canvas, lv_coord_t x, lv_coord_t y, lv_coord_t r, int32_t start_angle, int32_t end_angle, const lv_style_t * style)`

static mrb_value
mrb_mruby_lvgui_native_lv_canvas_draw_arc(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * canvas`
    mrb_value param_canvas_instance;
    lv_obj_t * param_canvas;
    // Parameter handling for native parameter `lv_coord_t x`
    mrb_int param_x_int;
    lv_coord_t param_x;
    // Parameter handling for native parameter `lv_coord_t y`
    mrb_int param_y_int;
    lv_coord_t param_y;
    // Parameter handling for native parameter `lv_coord_t r`
    mrb_int param_r_int;
    lv_coord_t param_r;
    // Parameter handling for native parameter `int32_t start_angle`
    mrb_int param_start_angle_int;
    int32_t param_start_angle;
    // Parameter handling for native parameter `int32_t end_angle`
    mrb_int param_end_angle_int;
    int32_t param_end_angle;
    // Parameter handling for native parameter `const lv_style_t * style`
    mrb_value param_style_instance;
    const lv_style_t * param_style;
    
    mrb_get_args(
      mrb,
      "oiiiiio",
      &param_canvas_instance,
      &param_x_int,
      &param_y_int,
      &param_r_int,
      &param_start_angle_int,
      &param_end_angle_int,
      &param_style_instance
    );
    param_canvas = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_canvas_instance
    );
    param_x = (lv_coord_t)param_x_int;
    param_y = (lv_coord_t)param_y_int;
    param_r = (lv_coord_t)param_r_int;
    param_start_angle = (int32_t)param_start_angle_int;
    param_end_angle = (int32_t)param_end_angle_int;
    param_style = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_style_instance
    );
  
    // Calling native function
    lv_canvas_draw_arc(param_canvas, param_x, param_y, param_r, param_start_angle, param_end_angle, param_style);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_task_handler()`

static mrb_value
mrb_mruby_lvgui_native_lv_task_handler(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
  
  
  
    // Calling native function
    lv_task_handler();
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_anim_core_init()`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_core_init(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
  
  
  
    // Calling native function
    lv_anim_core_init();
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_group_t * lvgui_get_focus_group()`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_focus_group(mrb_state *mrb, mrb_value self)
{
    lv_group_t * ret;
  
  
  
  
    // Calling native function
    ret = lvgui_get_focus_group();
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `void lvgui_focus_ring_disable()`

static mrb_value
mrb_mruby_lvgui_native_lvgui_focus_ring_disable(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
  
  
  
    // Calling native function
    lvgui_focus_ring_disable();
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `hal_panel_orientation_t hal_get_panel_orientation()`

static mrb_value
mrb_mruby_lvgui_native_hal_get_panel_orientation(mrb_state *mrb, mrb_value self)
{
    hal_panel_orientation_t ret;
  
  
  
  
    // Calling native function
    ret = hal_get_panel_orientation();
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lv_group_add_obj(lv_group_t * unnamed_parameter_0, lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_add_obj(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_group_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_group_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    lv_obj_t * param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    lv_group_add_obj(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_group_remove_obj(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_remove_obj(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_group_remove_obj(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_group_remove_all_objs(lv_group_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_remove_all_objs(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_group_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_group_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_group_remove_all_objs(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_group_focus_obj(lv_obj_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_focus_obj(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_group_focus_obj(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_group_focus_next(lv_group_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_focus_next(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_group_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_group_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_group_focus_next(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_group_focus_prev(lv_group_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_focus_prev(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_group_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_group_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    lv_group_focus_prev(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_group_focus_freeze(lv_group_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_focus_freeze(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_group_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_group_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_group_focus_freeze(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_group_set_click_focus(lv_group_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_set_click_focus(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_group_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_group_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_group_set_click_focus(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_group_set_wrap(lv_group_t * unnamed_parameter_0, bool unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_set_wrap(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_group_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_group_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `bool unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    bool param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oi",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_int
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = (bool)param_unnamed_parameter_1_int;
  
    // Calling native function
    lv_group_set_wrap(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_group_get_focused(const lv_group_t * unnamed_parameter_0)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_get_focused(mrb_state *mrb, mrb_value self)
{
    lv_obj_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `const lv_group_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    const lv_group_t * param_unnamed_parameter_0;
    
    mrb_get_args(
      mrb,
      "o",
      &param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
  
    // Calling native function
    ret = lv_group_get_focused(param_unnamed_parameter_0);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_font_t * lvgui_get_font(char * unnamed_parameter_0, uint16_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lvgui_get_font(mrb_state *mrb, mrb_value self)
{
    lv_font_t * ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `char * unnamed_parameter_0`
    char * param_unnamed_parameter_0;
    // Parameter handling for native parameter `uint16_t unnamed_parameter_1`
    mrb_int param_unnamed_parameter_1_int;
    uint16_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "zi",
      &param_unnamed_parameter_0,
      &param_unnamed_parameter_1_int
    );
    
    param_unnamed_parameter_1 = (uint16_t)param_unnamed_parameter_1_int;
  
    // Calling native function
    ret = lvgui_get_font(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

////////
// Bindings for: `lv_obj_t * lv_obj_get_child_back(const lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_get_child_back(mrb_state *mrb, mrb_value self)
{
  lv_obj_t * ret;
  
  //
  // Parameters handling
  //
  
  // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_0`
  mrb_value param_unnamed_parameter_0_instance;
  const lv_obj_t * param_unnamed_parameter_0;
  // Parameter handling for native parameter `const lv_obj_t * unnamed_parameter_1`
  mrb_value param_unnamed_parameter_1_instance;
  const lv_obj_t * param_unnamed_parameter_1;
  
  mrb_get_args(
    mrb,
    "oo",
    &param_unnamed_parameter_0_instance,
    &param_unnamed_parameter_1_instance
  );
  param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
    mrb,
    param_unnamed_parameter_0_instance
  );
  param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
    mrb,
    param_unnamed_parameter_1_instance
  );
  
  // Calling native function
  ret = lv_obj_get_child_back(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
  if (ret == NULL) {
    return mrb_nil_value();
  }
  
  // Converts return value back to a valid mruby value
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) ret);
}

//
////////

typedef struct mrb_mruby_lvgui_native_user_data_ref_ {
  mrb_state * mrb;
  mrb_value value;
} mrb_mruby_lvgui_native_user_data_ref;
////////
// Bindings for: `void lv_obj_set_user_data(lv_obj_t * unnamed_parameter_0, lv_obj_user_data_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_user_data(mrb_state *mrb, mrb_value self)
{
  mrb_value obj_instance;
  lv_obj_t * obj;
  mrb_value value;
  mrb_mruby_lvgui_native_user_data_ref * userdata;
  
  mrb_get_args(
    mrb,
    "oo",
    &obj_instance,
    &value
  );
  
  obj = mrb_mruby_lvgui_native_unwrap_pointer(
    mrb,
    obj_instance
  );
  
  // This will leak, if we unset user_data.
  mrb_gc_register(mrb, value);
  
  userdata = calloc(sizeof (mrb_mruby_lvgui_native_user_data_ref), 1);
  userdata->mrb = mrb;
  userdata->value = value;
  
  lv_obj_set_user_data(obj, userdata);
  
  return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_group_set_user_data(lv_group_t * unnamed_parameter_0, lv_group_user_data_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_set_user_data(mrb_state *mrb, mrb_value self)
{
  mrb_value group_instance;
  lv_group_t * group;
  mrb_value value;
  mrb_mruby_lvgui_native_user_data_ref * userdata;
  
  mrb_get_args(
    mrb,
    "oo",
    &group_instance,
    &value
  );
  
  group = mrb_mruby_lvgui_native_unwrap_pointer(
    mrb,
    group_instance
  );
  
  // This will leak, if we unset user_data.
  mrb_gc_register(mrb, value);
  
  userdata = calloc(sizeof (mrb_mruby_lvgui_native_user_data_ref), 1);
  userdata->mrb = mrb;
  userdata->value = value;
  
  lv_group_set_user_data(group, userdata);
  
  return mrb_nil_value();
}

//
////////

////////
// Bindings for: `lv_task_t * lv_task_create(lv_task_cb_t task_xcb, uint32_t period, lv_task_prio_t prio, void * task_proc)`

static mrb_value
mrb_mruby_lvgui_native_lv_task_create(mrb_state *mrb, mrb_value self)
{
  lv_task_t * task;
  mrb_value task_proc;
  mrb_mruby_lvgui_native_user_data_ref * task_proc_userdata;
  
  //
  // Parameters handling
  //
  
  // Parameter handling for native parameter `lv_task_cb_t task_xcb`
  mrb_value param_task_xcb_instance;
  lv_task_cb_t param_task_xcb;
  
  // Parameter handling for native parameter `uint32_t period`
  uint32_t param_period;
  
  // Parameter handling for native parameter `lv_task_prio_t prio`
  lv_task_prio_t param_prio;
  
  mrb_get_args(
    mrb,
    "oiio",
    &param_task_xcb_instance,
    &param_period,
    &param_prio,
    &task_proc
  );
  
  param_task_xcb = mrb_mruby_lvgui_native_unwrap_pointer(
    mrb,
    param_task_xcb_instance
  );
  
  // This will leak, if we unset user_data.
  mrb_gc_register(mrb, task_proc);
  
  task_proc_userdata = calloc(sizeof (mrb_mruby_lvgui_native_user_data_ref), 1);
  task_proc_userdata->mrb = mrb;
  task_proc_userdata->value = task_proc;
  
  // Calling native function
  task = lv_task_create(param_task_xcb, param_period, param_prio, task_proc_userdata);
  
  // Converts return value back to a valid mruby value
  return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) task);
}

//
////////

////////
// Bindings for: `void lv_task_del(lv_task_t * task)`

static mrb_value
mrb_mruby_lvgui_native_lv_task_del(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_task_t * task`
    mrb_value param_task_instance;
    lv_task_t * param_task;
    
    mrb_get_args(
      mrb,
      "o",
      &param_task_instance
    );
    param_task = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_task_instance
    );
  
    // Calling native function
    lv_task_del(param_task);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `void lv_task_once(lv_task_t * task)`

static mrb_value
mrb_mruby_lvgui_native_lv_task_once(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_task_t * task`
    mrb_value param_task_instance;
    lv_task_t * param_task;
    
    mrb_get_args(
      mrb,
      "o",
      &param_task_instance
    );
    param_task = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_task_instance
    );
  
    // Calling native function
    lv_task_once(param_task);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
//

void lvgui_handle_lv_task_callback(lv_task_t *task)
{
  mrb_mruby_lvgui_native_user_data_ref * userdata;
  mrb_state * mrb;
  mrb_value proc;

  userdata = task->user_data;

  if (userdata == NULL) {
    fprintf(stderr, "FATAL: Unexpected NULL userdata when handling LVTask callback.");
    abort();

    return;
  }

  mrb = userdata->mrb;
  proc = userdata->value;

  if (userdata->mrb == NULL) {
    fprintf(stderr, "FATAL: bogus mrb ref in userdata (NULL).");
    abort();

    return;
  }

  mrb_funcall(
    mrb,
    proc,
    "call",
    0 // argc
  );
}

//
////////
////////
// Bindings for: `void lv_obj_set_event_cb(lv_obj_t * unnamed_parameter_0, lv_event_cb_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_obj_set_event_cb(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_obj_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_obj_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_event_cb_t unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    lv_event_cb_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    lv_obj_set_event_cb(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
//

void lvgui_handle_lv_event_callback(lv_obj_t * obj, lv_event_t event)
{
  mrb_mruby_lvgui_native_user_data_ref * userdata;
  mrb_state * mrb;
  mrb_value value;

  userdata = lv_obj_get_user_data(obj);

  if (userdata == NULL) {
    fprintf(stderr, "FATAL: Unexpected NULL userdata when handling LVObject event callback.");
    abort();

    return;
  }

  mrb = userdata->mrb;
  value = userdata->value;

  if (userdata->mrb == NULL) {
    fprintf(stderr, "FATAL: bogus mrb ref in userdata (NULL).");
    abort();

    return;
  }

  mrb_funcall(
    mrb,
    value,
    "handle_lv_event",
    1, // argc
    mrb_fixnum_value(event)
  );
}

//
////////
////////
// Bindings for: `void lv_group_set_focus_cb(lv_group_t * unnamed_parameter_0, lv_group_focus_cb_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_group_set_focus_cb(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_group_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_group_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_group_focus_cb_t unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    lv_group_focus_cb_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    lv_group_set_focus_cb(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
//

void lvgui_handle_lv_focus_callback(lv_group_t * group)
{
  mrb_mruby_lvgui_native_user_data_ref * userdata;
  mrb_state * mrb;
  mrb_value value;

  userdata = lv_group_get_user_data(group);

  if (userdata == NULL) {
    fprintf(stderr, "FATAL: Unexpected NULL userdata when handling LVGroup callback.");
    abort();

    return;
  }

  mrb = userdata->mrb;
  value = userdata->value;

  if (userdata->mrb == NULL) {
    fprintf(stderr, "FATAL: bogus mrb ref in userdata (NULL).");
    abort();

    return;
  }

  mrb_funcall(
    mrb,
    value,
    "handle_lv_focus",
    0 // argc
  );
}

//
////////
////////
// Bindings for: `void lv_anim_set_path_cb(lv_anim_t * unnamed_parameter_0, lv_anim_path_cb_t unnamed_parameter_1)`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_set_path_cb(mrb_state *mrb, mrb_value self)
{
    /* No return value */
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `lv_anim_t * unnamed_parameter_0`
    mrb_value param_unnamed_parameter_0_instance;
    lv_anim_t * param_unnamed_parameter_0;
    // Parameter handling for native parameter `lv_anim_path_cb_t unnamed_parameter_1`
    mrb_value param_unnamed_parameter_1_instance;
    lv_anim_path_cb_t param_unnamed_parameter_1;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_unnamed_parameter_0_instance,
      &param_unnamed_parameter_1_instance
    );
    param_unnamed_parameter_0 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_0_instance
    );
    param_unnamed_parameter_1 = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_unnamed_parameter_1_instance
    );
  
    // Calling native function
    lv_anim_set_path_cb(param_unnamed_parameter_0, param_unnamed_parameter_1);
  
    // Converts return value back to a valid mruby value
    return mrb_nil_value();
}

//
////////

////////
// Bindings for: `bool lv_anim_del(void * var, lv_anim_exec_xcb_t exec_cb)`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_del(mrb_state *mrb, mrb_value self)
{
    bool ret;
  
    //
    // Parameters handling
    //
    
    // Parameter handling for native parameter `void * var`
    mrb_value param_var_instance;
    void * param_var;
    // Parameter handling for native parameter `lv_anim_exec_xcb_t exec_cb`
    mrb_value param_exec_cb_instance;
    lv_anim_exec_xcb_t param_exec_cb;
    
    mrb_get_args(
      mrb,
      "oo",
      &param_var_instance,
      &param_exec_cb_instance
    );
    param_var = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_var_instance
    );
    param_exec_cb = mrb_mruby_lvgui_native_unwrap_pointer(
      mrb,
      param_exec_cb_instance
    );
  
    // Calling native function
    ret = lv_anim_del(param_var, param_exec_cb);
  
    // Converts return value back to a valid mruby value
    return mrb_fixnum_value((mrb_int)ret);
}

//
////////

////////
// Bindings for: `void lv_anim_set_exec_cb(lv_anim_t * anim, void * var, lv_anim_exec_xcb_t exec_cb)`

static mrb_value
mrb_mruby_lvgui_native_lv_anim_set_exec_cb(mrb_state *mrb, mrb_value self)
{
  
  // Parameter handling
  mrb_value anim_instance;
  lv_anim_t * anim;            // lv_anim_t instance that manages the animation
  mrb_value var_instance;
  void * var;                  // lv_obj_t instance on which `exec_cb` will be called
  mrb_value exec_cb_instance;
  lv_anim_exec_xcb_t exec_cb;  // LVGL built-in function to call on `var`
  
  mrb_get_args(
    mrb,
    "ooo",
    &anim_instance,
    &var_instance,
    &exec_cb_instance
  );
  
  anim = mrb_mruby_lvgui_native_unwrap_pointer(
    mrb,
    anim_instance
  );
  
  var = mrb_mruby_lvgui_native_unwrap_pointer(
    mrb,
    var_instance
  );
  
  exec_cb = mrb_mruby_lvgui_native_unwrap_pointer(
    mrb,
    exec_cb_instance
  );
  
  // Calling native function
  lv_anim_set_exec_cb(anim, var, exec_cb);
  
  return mrb_nil_value();
}

//
////////


static mrb_value
mrb_mruby_lvgui_native_opaque_pointer__to_i(mrb_state *mrb, mrb_value self)
{
  void * ptr;

  ptr = mrb_mruby_lvgui_native_unwrap_pointer(
    mrb,
    self
  );

  return mrb_fixnum_value((intptr_t)ptr);
}

static mrb_value
mrb_mruby_lvgui_native_opaque_pointer__cast_to_string(mrb_state *mrb, mrb_value self)
{
  void * ptr;

  ptr = mrb_mruby_lvgui_native_unwrap_pointer(
    mrb,
    self
  );

  return mrb_str_new_cstr(mrb, (char *)ptr);
}

static mrb_value
mrb_mruby_lvgui_native_opaque_pointer__ref_to_char(mrb_state *mrb, mrb_value self)
{
  void * ptr;

  ptr = mrb_mruby_lvgui_native_unwrap_pointer(
    mrb,
    self
  );

  return mrb_str_new(mrb, (char *)(ptr), 1);
}

static mrb_value
mrb_mruby_lvgui_native_opaque_pointer__equals(mrb_state *mrb, mrb_value self)
{
    mrb_value other;
    void *ptr1, *ptr2;

    mrb_get_args(mrb, "o", &other);

    if (!mrb_obj_is_kind_of(mrb, other, mLVGUI__Native__OpaquePointer)) {
      return mrb_false_value();
    }

    ptr1 = mrb_mruby_lvgui_native_unwrap_pointer(mrb, self);
    ptr2 = mrb_mruby_lvgui_native_unwrap_pointer(mrb, other);

    if (ptr1 == ptr2) {
      return mrb_true_value();
    }

    return mrb_false_value();
}

/**
 * Wraps an mruby value into a new Opaque Pointer.
 * Can be unwrapped into mruby value later.
 */
static mrb_value
mrb_mruby_lvgui_native_opaque_pointer__brackets(mrb_state *mrb, mrb_value self)
{
    mrb_value *obj = calloc(sizeof (mrb_value), 1);

    mrb_get_args(mrb, "o", obj);

    // FIXME: this will leak objects.
    // We need to *somehow* keep track of the lifetime of OpaquePointers,
    // and keep track of who needs to register/unregister GC refs.
    mrb_gc_register(mrb, *obj);

    return mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) obj);
}

/**
 * Unwraps an OpaquePointer to the original mruby value.
 */
static mrb_value
mrb_mruby_lvgui_native_opaque_pointer_instance__to_value(mrb_state *mrb, mrb_value self)
{
    mrb_value *instance = mrb_mruby_lvgui_native_unwrap_pointer(mrb, self);

    return *instance;
}

//
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// Gem initialization / finalization                                          //
////////////////////////////////////////////////////////////////////////////////
//

void
mrb_mruby_lvgui_native_gem_init(mrb_state* mrb)
{

  // Define the hierarchy.
  // This mrbgem is generated and **strictly** uses one namespace, even if
  // it is defined more deeply.
  // TODO: check if parts of the hierarchy exists before defining it.
  mLVGUI__Native = mrb_define_module(mrb, "LVGUI");
  mLVGUI__Native = mrb_define_module_under(mrb, mLVGUI__Native, "Native");

  mLVGUI__Native__References = mrb_hash_new(mrb);
  mrb_define_const(mrb, mLVGUI__Native, "References", mLVGUI__Native__References);

  // Opaque pointer type
  mLVGUI__Native__OpaquePointer = mrb_define_class_under(
    mrb,
    mLVGUI__Native,
    "OpaquePointer",
    mrb->object_class
  );

  mrb_define_module_function(
    mrb,
    mLVGUI__Native__OpaquePointer,
    "to_i",
    mrb_mruby_lvgui_native_opaque_pointer__to_i,
    MRB_ARGS_REQ(0)
  );

  mrb_define_module_function(
    mrb,
    mLVGUI__Native__OpaquePointer,
    "cast_to_string",
    mrb_mruby_lvgui_native_opaque_pointer__cast_to_string,
    MRB_ARGS_REQ(0)
  );

  mrb_define_module_function(
    mrb,
    mLVGUI__Native__OpaquePointer,
    "ref_to_char",
    mrb_mruby_lvgui_native_opaque_pointer__ref_to_char,
    MRB_ARGS_REQ(0)
  );

  mrb_define_module_function(
    mrb,
    mLVGUI__Native__OpaquePointer,
    "==",
    mrb_mruby_lvgui_native_opaque_pointer__equals,
    MRB_ARGS_REQ(1)
  );

  mrb_define_module_function(
    mrb,
    mLVGUI__Native__OpaquePointer,
    "[]",
    mrb_mruby_lvgui_native_opaque_pointer__brackets,
    MRB_ARGS_REQ(1)
  );

  mrb_define_method(
    mrb,
    mLVGUI__Native__OpaquePointer,
    "to_value",
    mrb_mruby_lvgui_native_opaque_pointer_instance__to_value,
    MRB_ARGS_REQ(0)
  );

  // ```enum LV_ALIGN;```
  mrb_mruby_lvgui_native_enum_lv_align(mrb, mLVGUI__Native);

  // ```enum LV_ANIM;```
  mrb_mruby_lvgui_native_enum_lv_anim(mrb, mLVGUI__Native);

  // ```enum LV_ARC_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_arc_style(mrb, mLVGUI__Native);

  // ```enum LV_BAR_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_bar_style(mrb, mLVGUI__Native);

  // ```enum LV_BORDER;```
  mrb_mruby_lvgui_native_enum_lv_border(mrb, mLVGUI__Native);

  // ```enum LV_BTNM_CTRL;```
  mrb_mruby_lvgui_native_enum_lv_btnm_ctrl(mrb, mLVGUI__Native);

  // ```enum LV_BTNM_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_btnm_style(mrb, mLVGUI__Native);

  // ```enum LV_BTN_STATE;```
  mrb_mruby_lvgui_native_enum_lv_btn_state(mrb, mLVGUI__Native);

  // ```enum LV_BTN_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_btn_style(mrb, mLVGUI__Native);

  // ```enum LV_CALENDAR_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_calendar_style(mrb, mLVGUI__Native);

  // ```enum LV_CANVAS_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_canvas_style(mrb, mLVGUI__Native);

  // ```enum LV_CB_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_cb_style(mrb, mLVGUI__Native);

  // ```enum LV_CONT_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_cont_style(mrb, mLVGUI__Native);

  // ```enum LV_CPICKER_COLOR_MODE;```
  mrb_mruby_lvgui_native_enum_lv_cpicker_color_mode(mrb, mLVGUI__Native);

  // ```enum LV_CPICKER_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_cpicker_style(mrb, mLVGUI__Native);

  // ```enum LV_CPICKER_TYPE;```
  mrb_mruby_lvgui_native_enum_lv_cpicker_type(mrb, mLVGUI__Native);

  // ```enum LV_CURSOR;```
  mrb_mruby_lvgui_native_enum_lv_cursor(mrb, mLVGUI__Native);

  // ```enum LV_DDLIST_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_ddlist_style(mrb, mLVGUI__Native);

  // ```enum LV_DESIGN;```
  mrb_mruby_lvgui_native_enum_lv_design(mrb, mLVGUI__Native);

  // ```enum LV_DRAG_DIR;```
  mrb_mruby_lvgui_native_enum_lv_drag_dir(mrb, mLVGUI__Native);

  // ```enum LV_EVENT;```
  mrb_mruby_lvgui_native_enum_lv_event(mrb, mLVGUI__Native);

  // ```enum LV_FIT;```
  mrb_mruby_lvgui_native_enum_lv_fit(mrb, mLVGUI__Native);

  // ```enum LV_FONT_FMT_TXT_CMAP;```
  mrb_mruby_lvgui_native_enum_lv_font_fmt_txt_cmap(mrb, mLVGUI__Native);

  // ```enum LV_FONT_SUBPX;```
  mrb_mruby_lvgui_native_enum_lv_font_subpx(mrb, mLVGUI__Native);

  // ```enum LV_FS_MODE;```
  mrb_mruby_lvgui_native_enum_lv_fs_mode(mrb, mLVGUI__Native);

  // ```enum LV_FS_RES;```
  mrb_mruby_lvgui_native_enum_lv_fs_res(mrb, mLVGUI__Native);

  // ```enum LV_GAUGE_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_gauge_style(mrb, mLVGUI__Native);

  // ```enum LV_GROUP_REFOCUS_POLICY;```
  mrb_mruby_lvgui_native_enum_lv_group_refocus_policy(mrb, mLVGUI__Native);

  // ```enum LV_IMGBTN_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_imgbtn_style(mrb, mLVGUI__Native);

  // ```enum LV_IMG_CF;```
  mrb_mruby_lvgui_native_enum_lv_img_cf(mrb, mLVGUI__Native);

  // ```enum LV_IMG_SRC;```
  mrb_mruby_lvgui_native_enum_lv_img_src(mrb, mLVGUI__Native);

  // ```enum LV_IMG_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_img_style(mrb, mLVGUI__Native);

  // ```enum LV_INDEV_STATE;```
  mrb_mruby_lvgui_native_enum_lv_indev_state(mrb, mLVGUI__Native);

  // ```enum LV_INDEV_TYPE;```
  mrb_mruby_lvgui_native_enum_lv_indev_type(mrb, mLVGUI__Native);

  // ```enum LV_KB_MODE;```
  mrb_mruby_lvgui_native_enum_lv_kb_mode(mrb, mLVGUI__Native);

  // ```enum LV_KB_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_kb_style(mrb, mLVGUI__Native);

  // ```enum LV_KEY;```
  mrb_mruby_lvgui_native_enum_lv_key(mrb, mLVGUI__Native);

  // ```enum LV_LABEL_ALIGN;```
  mrb_mruby_lvgui_native_enum_lv_label_align(mrb, mLVGUI__Native);

  // ```enum LV_LABEL_LONG;```
  mrb_mruby_lvgui_native_enum_lv_label_long(mrb, mLVGUI__Native);

  // ```enum LV_LABEL_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_label_style(mrb, mLVGUI__Native);

  // ```enum LV_LAYOUT;```
  mrb_mruby_lvgui_native_enum_lv_layout(mrb, mLVGUI__Native);

  // ```enum LV_LINE_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_line_style(mrb, mLVGUI__Native);

  // ```enum LV_LMETER_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_lmeter_style(mrb, mLVGUI__Native);

  // ```enum LV_OPA;```
  mrb_mruby_lvgui_native_enum_lv_opa(mrb, mLVGUI__Native);

  // ```enum LV_PAGE_EDGE;```
  mrb_mruby_lvgui_native_enum_lv_page_edge(mrb, mLVGUI__Native);

  // ```enum LV_PAGE_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_page_style(mrb, mLVGUI__Native);

  // ```enum LV_PRELOAD_DIR;```
  mrb_mruby_lvgui_native_enum_lv_preload_dir(mrb, mLVGUI__Native);

  // ```enum LV_PRELOAD_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_preload_style(mrb, mLVGUI__Native);

  // ```enum LV_PRELOAD_TYPE;```
  mrb_mruby_lvgui_native_enum_lv_preload_type(mrb, mLVGUI__Native);

  // ```enum LV_PROTECT;```
  mrb_mruby_lvgui_native_enum_lv_protect(mrb, mLVGUI__Native);

  // ```enum LV_RES;```
  mrb_mruby_lvgui_native_enum_lv_res(mrb, mLVGUI__Native);

  // ```enum LV_ROLLER_MODE;```
  mrb_mruby_lvgui_native_enum_lv_roller_mode(mrb, mLVGUI__Native);

  // ```enum LV_ROLLER_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_roller_style(mrb, mLVGUI__Native);

  // ```enum LV_SB_MODE;```
  mrb_mruby_lvgui_native_enum_lv_sb_mode(mrb, mLVGUI__Native);

  // ```enum LV_SHADOW;```
  mrb_mruby_lvgui_native_enum_lv_shadow(mrb, mLVGUI__Native);

  // ```enum LV_SIGNAL;```
  mrb_mruby_lvgui_native_enum_lv_signal(mrb, mLVGUI__Native);

  // ```enum LV_SLIDER_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_slider_style(mrb, mLVGUI__Native);

  // ```enum LV_SPINBOX_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_spinbox_style(mrb, mLVGUI__Native);

  // ```enum LV_STR_SYMBOL;```
  mrb_mruby_lvgui_native_enum_lv_str_symbol(mrb, mLVGUI__Native);

  // ```enum LV_SW_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_sw_style(mrb, mLVGUI__Native);

  // ```enum LV_TABLE_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_table_style(mrb, mLVGUI__Native);

  // ```enum LV_TASK_PRIO;```
  mrb_mruby_lvgui_native_enum_lv_task_prio(mrb, mLVGUI__Native);

  // ```enum LV_TA_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_ta_style(mrb, mLVGUI__Native);

  // ```enum LV_TILEVIEW_STYLE;```
  mrb_mruby_lvgui_native_enum_lv_tileview_style(mrb, mLVGUI__Native);

  // ```enum LV_TXT_CMD_STATE;```
  mrb_mruby_lvgui_native_enum_lv_txt_cmd_state(mrb, mLVGUI__Native);

  // ```enum LV_TXT_FLAG;```
  mrb_mruby_lvgui_native_enum_lv_txt_flag(mrb, mLVGUI__Native);

  // global `int monitor_width`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "monitor_width",
    mrb_mruby_lvgui_native_monitor_width__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "monitor_width=",
    mrb_mruby_lvgui_native_monitor_width__set,
    MRB_ARGS_REQ(1)
  );

  // global `int monitor_height`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "monitor_height",
    mrb_mruby_lvgui_native_monitor_height__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "monitor_height=",
    mrb_mruby_lvgui_native_monitor_height__set,
    MRB_ARGS_REQ(1)
  );

  // global `int mn_hal_default_dpi`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "mn_hal_default_dpi",
    mrb_mruby_lvgui_native_mn_hal_default_dpi__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "mn_hal_default_dpi=",
    mrb_mruby_lvgui_native_mn_hal_default_dpi__set,
    MRB_ARGS_REQ(1)
  );

  // global `void * mn_hal_default_font`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "mn_hal_default_font",
    mrb_mruby_lvgui_native_mn_hal_default_font__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "mn_hal_default_font=",
    mrb_mruby_lvgui_native_mn_hal_default_font__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_scr`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_scr",
    mrb_mruby_lvgui_native_lv_style_scr__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_scr=",
    mrb_mruby_lvgui_native_lv_style_scr__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_transp`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_transp",
    mrb_mruby_lvgui_native_lv_style_transp__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_transp=",
    mrb_mruby_lvgui_native_lv_style_transp__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_transp_tight`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_transp_tight",
    mrb_mruby_lvgui_native_lv_style_transp_tight__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_transp_tight=",
    mrb_mruby_lvgui_native_lv_style_transp_tight__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_transp_fit`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_transp_fit",
    mrb_mruby_lvgui_native_lv_style_transp_fit__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_transp_fit=",
    mrb_mruby_lvgui_native_lv_style_transp_fit__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_plain`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_plain",
    mrb_mruby_lvgui_native_lv_style_plain__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_plain=",
    mrb_mruby_lvgui_native_lv_style_plain__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_plain_color`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_plain_color",
    mrb_mruby_lvgui_native_lv_style_plain_color__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_plain_color=",
    mrb_mruby_lvgui_native_lv_style_plain_color__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_pretty`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_pretty",
    mrb_mruby_lvgui_native_lv_style_pretty__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_pretty=",
    mrb_mruby_lvgui_native_lv_style_pretty__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_pretty_color`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_pretty_color",
    mrb_mruby_lvgui_native_lv_style_pretty_color__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_pretty_color=",
    mrb_mruby_lvgui_native_lv_style_pretty_color__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_btn_rel`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_btn_rel",
    mrb_mruby_lvgui_native_lv_style_btn_rel__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_btn_rel=",
    mrb_mruby_lvgui_native_lv_style_btn_rel__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_btn_pr`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_btn_pr",
    mrb_mruby_lvgui_native_lv_style_btn_pr__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_btn_pr=",
    mrb_mruby_lvgui_native_lv_style_btn_pr__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_btn_tgl_rel`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_btn_tgl_rel",
    mrb_mruby_lvgui_native_lv_style_btn_tgl_rel__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_btn_tgl_rel=",
    mrb_mruby_lvgui_native_lv_style_btn_tgl_rel__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_btn_tgl_pr`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_btn_tgl_pr",
    mrb_mruby_lvgui_native_lv_style_btn_tgl_pr__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_btn_tgl_pr=",
    mrb_mruby_lvgui_native_lv_style_btn_tgl_pr__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_style_t* lv_style_btn_ina`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_btn_ina",
    mrb_mruby_lvgui_native_lv_style_btn_ina__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_btn_ina=",
    mrb_mruby_lvgui_native_lv_style_btn_ina__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_anim_path_cb_t* lv_anim_path_linear`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_linear",
    mrb_mruby_lvgui_native_lv_anim_path_linear__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_linear=",
    mrb_mruby_lvgui_native_lv_anim_path_linear__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_anim_path_cb_t* lv_anim_path_step`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_step",
    mrb_mruby_lvgui_native_lv_anim_path_step__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_step=",
    mrb_mruby_lvgui_native_lv_anim_path_step__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_anim_path_cb_t* lv_anim_path_ease_in`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_ease_in",
    mrb_mruby_lvgui_native_lv_anim_path_ease_in__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_ease_in=",
    mrb_mruby_lvgui_native_lv_anim_path_ease_in__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_anim_path_cb_t* lv_anim_path_ease_out`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_ease_out",
    mrb_mruby_lvgui_native_lv_anim_path_ease_out__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_ease_out=",
    mrb_mruby_lvgui_native_lv_anim_path_ease_out__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_anim_path_cb_t* lv_anim_path_ease_in_out`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_ease_in_out",
    mrb_mruby_lvgui_native_lv_anim_path_ease_in_out__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_ease_in_out=",
    mrb_mruby_lvgui_native_lv_anim_path_ease_in_out__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_anim_path_cb_t* lv_anim_path_overshoot`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_overshoot",
    mrb_mruby_lvgui_native_lv_anim_path_overshoot__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_overshoot=",
    mrb_mruby_lvgui_native_lv_anim_path_overshoot__set,
    MRB_ARGS_REQ(1)
  );

  // global `lv_anim_path_cb_t* lv_anim_path_bounce`
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_bounce",
    mrb_mruby_lvgui_native_lv_anim_path_bounce__get,
    MRB_ARGS_REQ(0)
  );
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_path_bounce=",
    mrb_mruby_lvgui_native_lv_anim_path_bounce__set,
    MRB_ARGS_REQ(1)
  );

  // ```lv_style_t * lvgui_allocate_lv_style();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_allocate_lv_style",
    mrb_mruby_lvgui_native_lvgui_allocate_lv_style,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_allocate_lv_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_allocate_lv_style)
  );

  // ```uint8_t lvgui_get_lv_style__glass(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__glass",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__glass,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__glass")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__glass)
  );

  // ```void lvgui_set_lv_style__glass(lv_style_t * unnamed_parameter_0, uint8_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__glass",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__glass,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__glass")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__glass)
  );

  // ```lv_color_t lvgui_get_lv_style__body_main_color(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_main_color",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_main_color,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_main_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_main_color)
  );

  // ```void lvgui_set_lv_style__body_main_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_main_color",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_main_color,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_main_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_main_color)
  );

  // ```lv_color_t lvgui_get_lv_style__body_grad_color(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_grad_color",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_grad_color,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_grad_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_grad_color)
  );

  // ```void lvgui_set_lv_style__body_grad_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_grad_color",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_grad_color,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_grad_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_grad_color)
  );

  // ```lv_coord_t lvgui_get_lv_style__body_radius(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_radius",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_radius,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_radius")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_radius)
  );

  // ```void lvgui_set_lv_style__body_radius(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_radius",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_radius,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_radius")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_radius)
  );

  // ```lv_opa_t lvgui_get_lv_style__body_opa(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_opa",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_opa,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_opa")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_opa)
  );

  // ```void lvgui_set_lv_style__body_opa(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_opa",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_opa,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_opa")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_opa)
  );

  // ```lv_color_t lvgui_get_lv_style__body_border_color(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_border_color",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_border_color,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_border_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_border_color)
  );

  // ```void lvgui_set_lv_style__body_border_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_border_color",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_border_color,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_border_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_border_color)
  );

  // ```lv_coord_t lvgui_get_lv_style__body_border_width(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_border_width",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_border_width,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_border_width")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_border_width)
  );

  // ```void lvgui_set_lv_style__body_border_width(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_border_width",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_border_width,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_border_width")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_border_width)
  );

  // ```lv_border_part_t lvgui_get_lv_style__body_border_part(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_border_part",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_border_part,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_border_part")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_border_part)
  );

  // ```void lvgui_set_lv_style__body_border_part(lv_style_t * unnamed_parameter_0, lv_border_part_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_border_part",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_border_part,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_border_part")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_border_part)
  );

  // ```lv_opa_t lvgui_get_lv_style__body_border_opa(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_border_opa",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_border_opa,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_border_opa")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_border_opa)
  );

  // ```void lvgui_set_lv_style__body_border_opa(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_border_opa",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_border_opa,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_border_opa")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_border_opa)
  );

  // ```lv_color_t lvgui_get_lv_style__body_shadow_color(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_shadow_color",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_shadow_color,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_shadow_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_shadow_color)
  );

  // ```void lvgui_set_lv_style__body_shadow_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_shadow_color",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_shadow_color,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_shadow_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_shadow_color)
  );

  // ```lv_coord_t lvgui_get_lv_style__body_shadow_width(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_shadow_width",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_shadow_width,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_shadow_width")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_shadow_width)
  );

  // ```void lvgui_set_lv_style__body_shadow_width(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_shadow_width",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_shadow_width,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_shadow_width")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_shadow_width)
  );

  // ```lv_shadow_type_t lvgui_get_lv_style__body_shadow_type(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_shadow_type",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_shadow_type,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_shadow_type")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_shadow_type)
  );

  // ```void lvgui_set_lv_style__body_shadow_type(lv_style_t * unnamed_parameter_0, lv_shadow_type_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_shadow_type",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_shadow_type,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_shadow_type")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_shadow_type)
  );

  // ```lv_coord_t lvgui_get_lv_style__body_padding_top(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_padding_top",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_padding_top,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_padding_top")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_padding_top)
  );

  // ```void lvgui_set_lv_style__body_padding_top(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_padding_top",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_padding_top,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_padding_top")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_padding_top)
  );

  // ```lv_coord_t lvgui_get_lv_style__body_padding_bottom(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_padding_bottom",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_padding_bottom,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_padding_bottom")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_padding_bottom)
  );

  // ```void lvgui_set_lv_style__body_padding_bottom(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_padding_bottom",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_padding_bottom,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_padding_bottom")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_padding_bottom)
  );

  // ```lv_coord_t lvgui_get_lv_style__body_padding_left(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_padding_left",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_padding_left,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_padding_left")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_padding_left)
  );

  // ```void lvgui_set_lv_style__body_padding_left(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_padding_left",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_padding_left,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_padding_left")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_padding_left)
  );

  // ```lv_coord_t lvgui_get_lv_style__body_padding_right(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_padding_right",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_padding_right,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_padding_right")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_padding_right)
  );

  // ```void lvgui_set_lv_style__body_padding_right(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_padding_right",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_padding_right,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_padding_right")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_padding_right)
  );

  // ```lv_coord_t lvgui_get_lv_style__body_padding_inner(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__body_padding_inner",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__body_padding_inner,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__body_padding_inner")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__body_padding_inner)
  );

  // ```void lvgui_set_lv_style__body_padding_inner(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__body_padding_inner",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__body_padding_inner,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__body_padding_inner")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__body_padding_inner)
  );

  // ```lv_color_t lvgui_get_lv_style__text_color(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__text_color",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__text_color,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__text_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__text_color)
  );

  // ```void lvgui_set_lv_style__text_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__text_color",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__text_color,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__text_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__text_color)
  );

  // ```lv_color_t lvgui_get_lv_style__text_sel_color(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__text_sel_color",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__text_sel_color,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__text_sel_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__text_sel_color)
  );

  // ```void lvgui_set_lv_style__text_sel_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__text_sel_color",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__text_sel_color,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__text_sel_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__text_sel_color)
  );

  // ```lv_font_t * lvgui_get_lv_style__text_font(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__text_font",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__text_font,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__text_font")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__text_font)
  );

  // ```void lvgui_set_lv_style__text_font(lv_style_t * unnamed_parameter_0, lv_font_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__text_font",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__text_font,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__text_font")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__text_font)
  );

  // ```lv_coord_t lvgui_get_lv_style__text_letter_space(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__text_letter_space",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__text_letter_space,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__text_letter_space")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__text_letter_space)
  );

  // ```void lvgui_set_lv_style__text_letter_space(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__text_letter_space",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__text_letter_space,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__text_letter_space")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__text_letter_space)
  );

  // ```lv_coord_t lvgui_get_lv_style__text_line_space(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__text_line_space",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__text_line_space,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__text_line_space")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__text_line_space)
  );

  // ```void lvgui_set_lv_style__text_line_space(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__text_line_space",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__text_line_space,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__text_line_space")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__text_line_space)
  );

  // ```lv_opa_t lvgui_get_lv_style__text_opa(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__text_opa",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__text_opa,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__text_opa")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__text_opa)
  );

  // ```void lvgui_set_lv_style__text_opa(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__text_opa",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__text_opa,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__text_opa")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__text_opa)
  );

  // ```lv_color_t lvgui_get_lv_style__image_color(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__image_color",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__image_color,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__image_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__image_color)
  );

  // ```void lvgui_set_lv_style__image_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__image_color",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__image_color,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__image_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__image_color)
  );

  // ```lv_opa_t lvgui_get_lv_style__image_intense(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__image_intense",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__image_intense,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__image_intense")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__image_intense)
  );

  // ```void lvgui_set_lv_style__image_intense(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__image_intense",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__image_intense,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__image_intense")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__image_intense)
  );

  // ```lv_opa_t lvgui_get_lv_style__image_opa(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__image_opa",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__image_opa,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__image_opa")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__image_opa)
  );

  // ```void lvgui_set_lv_style__image_opa(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__image_opa",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__image_opa,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__image_opa")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__image_opa)
  );

  // ```lv_color_t lvgui_get_lv_style__line_color(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__line_color",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__line_color,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__line_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__line_color)
  );

  // ```void lvgui_set_lv_style__line_color(lv_style_t * unnamed_parameter_0, lv_color_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__line_color",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__line_color,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__line_color")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__line_color)
  );

  // ```lv_coord_t lvgui_get_lv_style__line_width(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__line_width",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__line_width,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__line_width")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__line_width)
  );

  // ```void lvgui_set_lv_style__line_width(lv_style_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__line_width",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__line_width,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__line_width")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__line_width)
  );

  // ```lv_opa_t lvgui_get_lv_style__line_opa(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__line_opa",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__line_opa,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__line_opa")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__line_opa)
  );

  // ```void lvgui_set_lv_style__line_opa(lv_style_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__line_opa",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__line_opa,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__line_opa")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__line_opa)
  );

  // ```uint8_t lvgui_get_lv_style__line_rounded(lv_style_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_lv_style__line_rounded",
    mrb_mruby_lvgui_native_lvgui_get_lv_style__line_rounded,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_lv_style__line_rounded")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_lv_style__line_rounded)
  );

  // ```void lvgui_set_lv_style__line_rounded(lv_style_t * unnamed_parameter_0, uint8_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_set_lv_style__line_rounded",
    mrb_mruby_lvgui_native_lvgui_set_lv_style__line_rounded,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_set_lv_style__line_rounded")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_set_lv_style__line_rounded)
  );

  // ```void hal_init(const char * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "hal_init",
    mrb_mruby_lvgui_native_hal_init,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "hal_init")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) hal_init)
  );

  // ```void lv_bmp_init();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_bmp_init",
    mrb_mruby_lvgui_native_lv_bmp_init,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_bmp_init")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_bmp_init)
  );

  // ```void lv_nanosvg_init();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_nanosvg_init",
    mrb_mruby_lvgui_native_lv_nanosvg_init,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_nanosvg_init")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_nanosvg_init)
  );

  // ```lv_anim_t * lvgui_allocate_lv_anim();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_allocate_lv_anim",
    mrb_mruby_lvgui_native_lvgui_allocate_lv_anim,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_allocate_lv_anim")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_allocate_lv_anim)
  );

  // ```bool lv_introspection_is_simulator();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_introspection_is_simulator",
    mrb_mruby_lvgui_native_lv_introspection_is_simulator,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_introspection_is_simulator")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_introspection_is_simulator)
  );

  // ```bool lv_introspection_is_debug();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_introspection_is_debug",
    mrb_mruby_lvgui_native_lv_introspection_is_debug,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_introspection_is_debug")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_introspection_is_debug)
  );

  // ```bool lv_introspection_use_assert_style();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_introspection_use_assert_style",
    mrb_mruby_lvgui_native_lv_introspection_use_assert_style,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_introspection_use_assert_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_introspection_use_assert_style)
  );

  // ```const char * lv_introspection_display_driver();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_introspection_display_driver",
    mrb_mruby_lvgui_native_lv_introspection_display_driver,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_introspection_display_driver")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_introspection_display_driver)
  );

  // ```void lv_theme_set_current(lv_theme_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_theme_set_current",
    mrb_mruby_lvgui_native_lv_theme_set_current,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_theme_set_current")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_theme_set_current)
  );

  // ```lv_theme_t * lv_theme_get_current();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_theme_get_current",
    mrb_mruby_lvgui_native_lv_theme_get_current,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_theme_get_current")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_theme_get_current)
  );

  // ```lv_theme_t * lv_theme_mono_init(uint16_t unnamed_parameter_0, lv_font_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_theme_mono_init",
    mrb_mruby_lvgui_native_lv_theme_mono_init,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_theme_mono_init")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_theme_mono_init)
  );

  // ```lv_theme_t * lv_theme_get_mono();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_theme_get_mono",
    mrb_mruby_lvgui_native_lv_theme_get_mono,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_theme_get_mono")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_theme_get_mono)
  );

  // ```lv_theme_t * lv_theme_night_init(uint16_t unnamed_parameter_0, lv_font_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_theme_night_init",
    mrb_mruby_lvgui_native_lv_theme_night_init,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_theme_night_init")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_theme_night_init)
  );

  // ```lv_theme_t * lv_theme_get_night();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_theme_get_night",
    mrb_mruby_lvgui_native_lv_theme_get_night,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_theme_get_night")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_theme_get_night)
  );

  // ```lv_theme_t * lv_theme_nixos_init(lv_font_t * unnamed_parameter_0, lv_font_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_theme_nixos_init",
    mrb_mruby_lvgui_native_lv_theme_nixos_init,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_theme_nixos_init")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_theme_nixos_init)
  );

  // ```lv_theme_t * lv_theme_get_nixos();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_theme_get_nixos",
    mrb_mruby_lvgui_native_lv_theme_get_nixos,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_theme_get_nixos")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_theme_get_nixos)
  );

  // ```lv_obj_t * lv_obj_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_create",
    mrb_mruby_lvgui_native_lv_obj_create,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_create)
  );

  // ```const lv_style_t * lv_obj_get_style(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_get_style",
    mrb_mruby_lvgui_native_lv_obj_get_style,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_get_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_get_style)
  );

  // ```void lv_obj_set_style(lv_obj_t * unnamed_parameter_0, const lv_style_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_style",
    mrb_mruby_lvgui_native_lv_obj_set_style,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_style)
  );

  // ```void lv_obj_refresh_style(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_refresh_style",
    mrb_mruby_lvgui_native_lv_obj_refresh_style,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_refresh_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_refresh_style)
  );

  // ```lv_coord_t lv_obj_get_width(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_get_width",
    mrb_mruby_lvgui_native_lv_obj_get_width,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_get_width")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_get_width)
  );

  // ```lv_coord_t lv_obj_get_height(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_get_height",
    mrb_mruby_lvgui_native_lv_obj_get_height,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_get_height")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_get_height)
  );

  // ```lv_coord_t lv_obj_get_width_fit(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_get_width_fit",
    mrb_mruby_lvgui_native_lv_obj_get_width_fit,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_get_width_fit")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_get_width_fit)
  );

  // ```lv_coord_t lv_obj_get_height_fit(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_get_height_fit",
    mrb_mruby_lvgui_native_lv_obj_get_height_fit,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_get_height_fit")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_get_height_fit)
  );

  // ```void lv_obj_set_width(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_width",
    mrb_mruby_lvgui_native_lv_obj_set_width,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_width")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_width)
  );

  // ```void lv_obj_set_height(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_height",
    mrb_mruby_lvgui_native_lv_obj_set_height,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_height")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_height)
  );

  // ```lv_coord_t lv_obj_get_x(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_get_x",
    mrb_mruby_lvgui_native_lv_obj_get_x,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_get_x")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_get_x)
  );

  // ```lv_coord_t lv_obj_get_y(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_get_y",
    mrb_mruby_lvgui_native_lv_obj_get_y,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_get_y")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_get_y)
  );

  // ```const void * lv_event_get_data();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_event_get_data",
    mrb_mruby_lvgui_native_lv_event_get_data,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_event_get_data")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_event_get_data)
  );

  // ```void lv_obj_set_opa_scale(lv_obj_t * unnamed_parameter_0, lv_opa_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_opa_scale",
    mrb_mruby_lvgui_native_lv_obj_set_opa_scale,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_opa_scale")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_opa_scale)
  );

  // ```lv_opa_t lv_obj_get_opa_scale(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_get_opa_scale",
    mrb_mruby_lvgui_native_lv_obj_get_opa_scale,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_get_opa_scale")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_get_opa_scale)
  );

  // ```void lv_obj_move_foreground(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_move_foreground",
    mrb_mruby_lvgui_native_lv_obj_move_foreground,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_move_foreground")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_move_foreground)
  );

  // ```void lv_obj_set_pos(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1, lv_coord_t unnamed_parameter_2);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_pos",
    mrb_mruby_lvgui_native_lv_obj_set_pos,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_pos")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_pos)
  );

  // ```void lv_obj_set_x(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_x",
    mrb_mruby_lvgui_native_lv_obj_set_x,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_x")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_x)
  );

  // ```void lv_obj_set_y(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_y",
    mrb_mruby_lvgui_native_lv_obj_set_y,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_y")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_y)
  );

  // ```void lv_obj_set_parent(lv_obj_t * unnamed_parameter_0, lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_parent",
    mrb_mruby_lvgui_native_lv_obj_set_parent,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_parent")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_parent)
  );

  // ```void lv_obj_set_hidden(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_hidden",
    mrb_mruby_lvgui_native_lv_obj_set_hidden,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_hidden")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_hidden)
  );

  // ```void lv_obj_set_click(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_click",
    mrb_mruby_lvgui_native_lv_obj_set_click,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_click")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_click)
  );

  // ```void lv_obj_set_top(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_top",
    mrb_mruby_lvgui_native_lv_obj_set_top,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_top")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_top)
  );

  // ```void lv_obj_set_opa_scale_enable(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_opa_scale_enable",
    mrb_mruby_lvgui_native_lv_obj_set_opa_scale_enable,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_opa_scale_enable")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_opa_scale_enable)
  );

  // ```void lv_obj_set_protect(lv_obj_t * unnamed_parameter_0, lv_protect_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_protect",
    mrb_mruby_lvgui_native_lv_obj_set_protect,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_protect")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_protect)
  );

  // ```lv_opa_t lv_obj_get_opa_scale_enable(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_get_opa_scale_enable",
    mrb_mruby_lvgui_native_lv_obj_get_opa_scale_enable,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_get_opa_scale_enable")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_get_opa_scale_enable)
  );

  // ```void lv_obj_clean(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_clean",
    mrb_mruby_lvgui_native_lv_obj_clean,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_clean")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_clean)
  );

  // ```lv_res_t lv_obj_del(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_del",
    mrb_mruby_lvgui_native_lv_obj_del,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_del")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_del)
  );

  // ```void lv_obj_del_async(struct _lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_del_async",
    mrb_mruby_lvgui_native_lv_obj_del_async,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_del_async")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_del_async)
  );

  // ```lv_obj_t * lv_obj_get_parent(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_get_parent",
    mrb_mruby_lvgui_native_lv_obj_get_parent,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_get_parent")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_get_parent)
  );

  // ```bool lv_obj_is_children(const lv_obj_t * obj, const lv_obj_t * target);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_is_children",
    mrb_mruby_lvgui_native_lv_obj_is_children,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_is_children")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_is_children)
  );

  // ```lv_obj_t * lv_btn_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_btn_create",
    mrb_mruby_lvgui_native_lv_btn_create,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_btn_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_btn_create)
  );

  // ```void lv_btn_set_ink_in_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_btn_set_ink_in_time",
    mrb_mruby_lvgui_native_lv_btn_set_ink_in_time,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_btn_set_ink_in_time")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_btn_set_ink_in_time)
  );

  // ```void lv_btn_set_ink_wait_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_btn_set_ink_wait_time",
    mrb_mruby_lvgui_native_lv_btn_set_ink_wait_time,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_btn_set_ink_wait_time")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_btn_set_ink_wait_time)
  );

  // ```void lv_btn_set_ink_out_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_btn_set_ink_out_time",
    mrb_mruby_lvgui_native_lv_btn_set_ink_out_time,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_btn_set_ink_out_time")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_btn_set_ink_out_time)
  );

  // ```void lv_btn_set_style(lv_obj_t * unnamed_parameter_0, lv_btn_style_t unnamed_parameter_1, const lv_style_t * unnamed_parameter_2);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_btn_set_style",
    mrb_mruby_lvgui_native_lv_btn_set_style,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_btn_set_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_btn_set_style)
  );

  // ```const lv_style_t * lv_btn_get_style(const lv_obj_t * unnamed_parameter_0, lv_btn_style_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_btn_get_style",
    mrb_mruby_lvgui_native_lv_btn_get_style,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_btn_get_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_btn_get_style)
  );

  // ```lv_obj_t * lv_cont_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_cont_create",
    mrb_mruby_lvgui_native_lv_cont_create,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_cont_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_cont_create)
  );

  // ```void lv_cont_set_layout(lv_obj_t * unnamed_parameter_0, lv_layout_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_cont_set_layout",
    mrb_mruby_lvgui_native_lv_cont_set_layout,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_cont_set_layout")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_cont_set_layout)
  );

  // ```void lv_cont_set_fit4(lv_obj_t * unnamed_parameter_0, lv_fit_t unnamed_parameter_1, lv_fit_t unnamed_parameter_2, lv_fit_t unnamed_parameter_3, lv_fit_t unnamed_parameter_4);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_cont_set_fit4",
    mrb_mruby_lvgui_native_lv_cont_set_fit4,
    MRB_ARGS_REQ(5)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_cont_set_fit4")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_cont_set_fit4)
  );

  // ```void lv_cont_set_fit2(lv_obj_t * unnamed_parameter_0, lv_fit_t unnamed_parameter_1, lv_fit_t unnamed_parameter_2);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_cont_set_fit2",
    mrb_mruby_lvgui_native_lv_cont_set_fit2,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_cont_set_fit2")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_cont_set_fit2)
  );

  // ```void lv_cont_set_fit(lv_obj_t * unnamed_parameter_0, lv_fit_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_cont_set_fit",
    mrb_mruby_lvgui_native_lv_cont_set_fit,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_cont_set_fit")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_cont_set_fit)
  );

  // ```lv_obj_t * lv_disp_get_scr_act(lv_disp_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_disp_get_scr_act",
    mrb_mruby_lvgui_native_lv_disp_get_scr_act,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_disp_get_scr_act")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_disp_get_scr_act)
  );

  // ```void lv_disp_load_scr(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_disp_load_scr",
    mrb_mruby_lvgui_native_lv_disp_load_scr,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_disp_load_scr")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_disp_load_scr)
  );

  // ```lv_disp_t * lv_disp_get_default();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_disp_get_default",
    mrb_mruby_lvgui_native_lv_disp_get_default,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_disp_get_default")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_disp_get_default)
  );

  // ```lv_obj_t * lv_scr_act();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_scr_act",
    mrb_mruby_lvgui_native_lv_scr_act,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_scr_act")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_scr_act)
  );

  // ```lv_obj_t * lv_layer_top();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_layer_top",
    mrb_mruby_lvgui_native_lv_layer_top,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_layer_top")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_layer_top)
  );

  // ```lv_obj_t * lv_layer_sys();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_layer_sys",
    mrb_mruby_lvgui_native_lv_layer_sys,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_layer_sys")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_layer_sys)
  );

  // ```lv_obj_t * lv_img_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_img_create",
    mrb_mruby_lvgui_native_lv_img_create,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_img_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_img_create)
  );

  // ```void lv_img_set_src(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_img_set_src",
    mrb_mruby_lvgui_native_lv_img_set_src,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_img_set_src")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_img_set_src)
  );

  // ```lv_img_dsc_t * lv_img_buf_alloc(lv_coord_t w, lv_coord_t h, lv_img_cf_t cf);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_img_buf_alloc",
    mrb_mruby_lvgui_native_lv_img_buf_alloc,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_img_buf_alloc")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_img_buf_alloc)
  );

  // ```void lv_img_buf_free(lv_img_dsc_t * dsc);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_img_buf_free",
    mrb_mruby_lvgui_native_lv_img_buf_free,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_img_buf_free")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_img_buf_free)
  );

  // ```lv_obj_t * lv_sw_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_sw_create",
    mrb_mruby_lvgui_native_lv_sw_create,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_sw_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_sw_create)
  );

  // ```void lv_sw_on(lv_obj_t * unnamed_parameter_0, lv_anim_enable_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_sw_on",
    mrb_mruby_lvgui_native_lv_sw_on,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_sw_on")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_sw_on)
  );

  // ```void lv_sw_off(lv_obj_t * unnamed_parameter_0, lv_anim_enable_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_sw_off",
    mrb_mruby_lvgui_native_lv_sw_off,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_sw_off")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_sw_off)
  );

  // ```void lv_sw_toggle(lv_obj_t * unnamed_parameter_0, lv_anim_enable_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_sw_toggle",
    mrb_mruby_lvgui_native_lv_sw_toggle,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_sw_toggle")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_sw_toggle)
  );

  // ```void lv_sw_set_style(lv_obj_t * unnamed_parameter_0, lv_sw_style_t unnamed_parameter_1, const lv_style_t * unnamed_parameter_2);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_sw_set_style",
    mrb_mruby_lvgui_native_lv_sw_set_style,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_sw_set_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_sw_set_style)
  );

  // ```void lv_sw_set_anim_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_sw_set_anim_time",
    mrb_mruby_lvgui_native_lv_sw_set_anim_time,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_sw_set_anim_time")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_sw_set_anim_time)
  );

  // ```bool lv_sw_get_state(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_sw_get_state",
    mrb_mruby_lvgui_native_lv_sw_get_state,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_sw_get_state")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_sw_get_state)
  );

  // ```uint16_t lv_sw_get_anim_time(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_sw_get_anim_time",
    mrb_mruby_lvgui_native_lv_sw_get_anim_time,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_sw_get_anim_time")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_sw_get_anim_time)
  );

  // ```lv_obj_t * lv_label_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_label_create",
    mrb_mruby_lvgui_native_lv_label_create,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_label_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_label_create)
  );

  // ```void lv_label_set_text(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_label_set_text",
    mrb_mruby_lvgui_native_lv_label_set_text,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_label_set_text")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_label_set_text)
  );

  // ```void lv_label_set_long_mode(lv_obj_t * unnamed_parameter_0, lv_label_long_mode_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_label_set_long_mode",
    mrb_mruby_lvgui_native_lv_label_set_long_mode,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_label_set_long_mode")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_label_set_long_mode)
  );

  // ```void lv_label_set_align(lv_obj_t * unnamed_parameter_0, lv_label_align_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_label_set_align",
    mrb_mruby_lvgui_native_lv_label_set_align,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_label_set_align")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_label_set_align)
  );

  // ```lv_obj_t * lv_page_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_create",
    mrb_mruby_lvgui_native_lv_page_create,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_create)
  );

  // ```void lv_page_clean(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_clean",
    mrb_mruby_lvgui_native_lv_page_clean,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_clean")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_clean)
  );

  // ```lv_obj_t * lv_page_get_scrl(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_get_scrl",
    mrb_mruby_lvgui_native_lv_page_get_scrl,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_get_scrl")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_get_scrl)
  );

  // ```void lv_page_set_scrl_layout(lv_obj_t * unnamed_parameter_0, lv_layout_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_set_scrl_layout",
    mrb_mruby_lvgui_native_lv_page_set_scrl_layout,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_set_scrl_layout")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_set_scrl_layout)
  );

  // ```void lv_page_glue_obj(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_glue_obj",
    mrb_mruby_lvgui_native_lv_page_glue_obj,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_glue_obj")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_glue_obj)
  );

  // ```const lv_style_t * lv_page_get_style(const lv_obj_t * unnamed_parameter_0, lv_page_style_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_get_style",
    mrb_mruby_lvgui_native_lv_page_get_style,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_get_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_get_style)
  );

  // ```void lv_page_set_style(lv_obj_t * unnamed_parameter_0, lv_page_style_t unnamed_parameter_1, const lv_style_t * unnamed_parameter_2);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_set_style",
    mrb_mruby_lvgui_native_lv_page_set_style,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_set_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_set_style)
  );

  // ```void lv_page_focus(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1, lv_anim_enable_t unnamed_parameter_2);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_focus",
    mrb_mruby_lvgui_native_lv_page_focus,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_focus")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_focus)
  );

  // ```void lv_page_set_scrl_width(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_set_scrl_width",
    mrb_mruby_lvgui_native_lv_page_set_scrl_width,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_set_scrl_width")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_set_scrl_width)
  );

  // ```void lv_page_set_scrl_height(lv_obj_t * unnamed_parameter_0, lv_coord_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_set_scrl_height",
    mrb_mruby_lvgui_native_lv_page_set_scrl_height,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_set_scrl_height")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_set_scrl_height)
  );

  // ```lv_coord_t lv_page_get_scrl_width(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_get_scrl_width",
    mrb_mruby_lvgui_native_lv_page_get_scrl_width,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_get_scrl_width")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_get_scrl_width)
  );

  // ```lv_coord_t lv_page_get_scrl_height(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_page_get_scrl_height",
    mrb_mruby_lvgui_native_lv_page_get_scrl_height,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_page_get_scrl_height")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_page_get_scrl_height)
  );

  // ```lv_obj_t * lv_kb_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_kb_create",
    mrb_mruby_lvgui_native_lv_kb_create,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_kb_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_kb_create)
  );

  // ```void lv_kb_set_ta(lv_obj_t * unnamed_parameter_0, lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_kb_set_ta",
    mrb_mruby_lvgui_native_lv_kb_set_ta,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_kb_set_ta")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_kb_set_ta)
  );

  // ```void lv_kb_set_mode(lv_obj_t * unnamed_parameter_0, lv_kb_mode_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_kb_set_mode",
    mrb_mruby_lvgui_native_lv_kb_set_mode,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_kb_set_mode")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_kb_set_mode)
  );

  // ```void lv_kb_set_cursor_manage(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_kb_set_cursor_manage",
    mrb_mruby_lvgui_native_lv_kb_set_cursor_manage,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_kb_set_cursor_manage")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_kb_set_cursor_manage)
  );

  // ```void lv_kb_set_style(lv_obj_t * unnamed_parameter_0, lv_kb_style_t unnamed_parameter_1, const lv_style_t * unnamed_parameter_2);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_kb_set_style",
    mrb_mruby_lvgui_native_lv_kb_set_style,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_kb_set_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_kb_set_style)
  );

  // ```lv_obj_t * lv_kb_get_ta(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_kb_get_ta",
    mrb_mruby_lvgui_native_lv_kb_get_ta,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_kb_get_ta")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_kb_get_ta)
  );

  // ```lv_kb_mode_t lv_kb_get_mode(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_kb_get_mode",
    mrb_mruby_lvgui_native_lv_kb_get_mode,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_kb_get_mode")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_kb_get_mode)
  );

  // ```bool lv_kb_get_cursor_manage(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_kb_get_cursor_manage",
    mrb_mruby_lvgui_native_lv_kb_get_cursor_manage,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_kb_get_cursor_manage")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_kb_get_cursor_manage)
  );

  // ```const char ** lv_kb_get_map_array(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_kb_get_map_array",
    mrb_mruby_lvgui_native_lv_kb_get_map_array,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_kb_get_map_array")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_kb_get_map_array)
  );

  // ```const lv_style_t * lv_kb_get_style(const lv_obj_t * unnamed_parameter_0, lv_kb_style_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_kb_get_style",
    mrb_mruby_lvgui_native_lv_kb_get_style,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_kb_get_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_kb_get_style)
  );

  // ```void lv_kb_def_event_cb(lv_obj_t * unnamed_parameter_0, lv_event_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_kb_def_event_cb",
    mrb_mruby_lvgui_native_lv_kb_def_event_cb,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_kb_def_event_cb")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_kb_def_event_cb)
  );

  // ```lv_obj_t * lv_ta_create(lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_create",
    mrb_mruby_lvgui_native_lv_ta_create,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_create)
  );

  // ```void lv_ta_add_char(lv_obj_t * unnamed_parameter_0, uint32_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_add_char",
    mrb_mruby_lvgui_native_lv_ta_add_char,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_add_char")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_add_char)
  );

  // ```void lv_ta_add_text(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_add_text",
    mrb_mruby_lvgui_native_lv_ta_add_text,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_add_text")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_add_text)
  );

  // ```void lv_ta_del_char(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_del_char",
    mrb_mruby_lvgui_native_lv_ta_del_char,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_del_char")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_del_char)
  );

  // ```void lv_ta_del_char_forward(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_del_char_forward",
    mrb_mruby_lvgui_native_lv_ta_del_char_forward,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_del_char_forward")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_del_char_forward)
  );

  // ```void lv_ta_set_text(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_text",
    mrb_mruby_lvgui_native_lv_ta_set_text,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_text")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_text)
  );

  // ```void lv_ta_set_placeholder_text(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_placeholder_text",
    mrb_mruby_lvgui_native_lv_ta_set_placeholder_text,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_placeholder_text")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_placeholder_text)
  );

  // ```void lv_ta_set_cursor_pos(lv_obj_t * unnamed_parameter_0, int16_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_cursor_pos",
    mrb_mruby_lvgui_native_lv_ta_set_cursor_pos,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_cursor_pos")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_cursor_pos)
  );

  // ```void lv_ta_set_cursor_type(lv_obj_t * unnamed_parameter_0, lv_cursor_type_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_cursor_type",
    mrb_mruby_lvgui_native_lv_ta_set_cursor_type,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_cursor_type")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_cursor_type)
  );

  // ```void lv_ta_set_cursor_click_pos(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_cursor_click_pos",
    mrb_mruby_lvgui_native_lv_ta_set_cursor_click_pos,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_cursor_click_pos")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_cursor_click_pos)
  );

  // ```void lv_ta_set_pwd_mode(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_pwd_mode",
    mrb_mruby_lvgui_native_lv_ta_set_pwd_mode,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_pwd_mode")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_pwd_mode)
  );

  // ```void lv_ta_set_one_line(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_one_line",
    mrb_mruby_lvgui_native_lv_ta_set_one_line,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_one_line")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_one_line)
  );

  // ```void lv_ta_set_text_align(lv_obj_t * unnamed_parameter_0, lv_label_align_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_text_align",
    mrb_mruby_lvgui_native_lv_ta_set_text_align,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_text_align")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_text_align)
  );

  // ```void lv_ta_set_accepted_chars(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_accepted_chars",
    mrb_mruby_lvgui_native_lv_ta_set_accepted_chars,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_accepted_chars")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_accepted_chars)
  );

  // ```void lv_ta_set_max_length(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_max_length",
    mrb_mruby_lvgui_native_lv_ta_set_max_length,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_max_length")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_max_length)
  );

  // ```void lv_ta_set_insert_replace(lv_obj_t * unnamed_parameter_0, const char * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_insert_replace",
    mrb_mruby_lvgui_native_lv_ta_set_insert_replace,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_insert_replace")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_insert_replace)
  );

  // ```void lv_ta_set_sb_mode(lv_obj_t * unnamed_parameter_0, lv_sb_mode_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_sb_mode",
    mrb_mruby_lvgui_native_lv_ta_set_sb_mode,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_sb_mode")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_sb_mode)
  );

  // ```void lv_ta_set_scroll_propagation(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_scroll_propagation",
    mrb_mruby_lvgui_native_lv_ta_set_scroll_propagation,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_scroll_propagation")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_scroll_propagation)
  );

  // ```void lv_ta_set_edge_flash(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_edge_flash",
    mrb_mruby_lvgui_native_lv_ta_set_edge_flash,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_edge_flash")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_edge_flash)
  );

  // ```void lv_ta_set_style(lv_obj_t * unnamed_parameter_0, lv_ta_style_t unnamed_parameter_1, const lv_style_t * unnamed_parameter_2);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_style",
    mrb_mruby_lvgui_native_lv_ta_set_style,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_style)
  );

  // ```void lv_ta_set_text_sel(lv_obj_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_text_sel",
    mrb_mruby_lvgui_native_lv_ta_set_text_sel,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_text_sel")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_text_sel)
  );

  // ```void lv_ta_set_pwd_show_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_pwd_show_time",
    mrb_mruby_lvgui_native_lv_ta_set_pwd_show_time,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_pwd_show_time")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_pwd_show_time)
  );

  // ```void lv_ta_set_cursor_blink_time(lv_obj_t * unnamed_parameter_0, uint16_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_set_cursor_blink_time",
    mrb_mruby_lvgui_native_lv_ta_set_cursor_blink_time,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_set_cursor_blink_time")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_set_cursor_blink_time)
  );

  // ```const char * lv_ta_get_text(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_text",
    mrb_mruby_lvgui_native_lv_ta_get_text,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_text")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_text)
  );

  // ```const char * lv_ta_get_placeholder_text(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_placeholder_text",
    mrb_mruby_lvgui_native_lv_ta_get_placeholder_text,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_placeholder_text")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_placeholder_text)
  );

  // ```lv_obj_t * lv_ta_get_label(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_label",
    mrb_mruby_lvgui_native_lv_ta_get_label,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_label")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_label)
  );

  // ```uint16_t lv_ta_get_cursor_pos(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_cursor_pos",
    mrb_mruby_lvgui_native_lv_ta_get_cursor_pos,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_cursor_pos")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_cursor_pos)
  );

  // ```lv_cursor_type_t lv_ta_get_cursor_type(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_cursor_type",
    mrb_mruby_lvgui_native_lv_ta_get_cursor_type,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_cursor_type")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_cursor_type)
  );

  // ```bool lv_ta_get_cursor_click_pos(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_cursor_click_pos",
    mrb_mruby_lvgui_native_lv_ta_get_cursor_click_pos,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_cursor_click_pos")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_cursor_click_pos)
  );

  // ```bool lv_ta_get_pwd_mode(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_pwd_mode",
    mrb_mruby_lvgui_native_lv_ta_get_pwd_mode,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_pwd_mode")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_pwd_mode)
  );

  // ```bool lv_ta_get_one_line(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_one_line",
    mrb_mruby_lvgui_native_lv_ta_get_one_line,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_one_line")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_one_line)
  );

  // ```const char * lv_ta_get_accepted_chars(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_accepted_chars",
    mrb_mruby_lvgui_native_lv_ta_get_accepted_chars,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_accepted_chars")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_accepted_chars)
  );

  // ```uint16_t lv_ta_get_max_length(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_max_length",
    mrb_mruby_lvgui_native_lv_ta_get_max_length,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_max_length")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_max_length)
  );

  // ```lv_sb_mode_t lv_ta_get_sb_mode(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_sb_mode",
    mrb_mruby_lvgui_native_lv_ta_get_sb_mode,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_sb_mode")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_sb_mode)
  );

  // ```bool lv_ta_get_scroll_propagation(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_scroll_propagation",
    mrb_mruby_lvgui_native_lv_ta_get_scroll_propagation,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_scroll_propagation")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_scroll_propagation)
  );

  // ```bool lv_ta_get_edge_flash(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_edge_flash",
    mrb_mruby_lvgui_native_lv_ta_get_edge_flash,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_edge_flash")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_edge_flash)
  );

  // ```const lv_style_t * lv_ta_get_style(const lv_obj_t * unnamed_parameter_0, lv_ta_style_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_style",
    mrb_mruby_lvgui_native_lv_ta_get_style,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_style")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_style)
  );

  // ```bool lv_ta_text_is_selected(const lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_text_is_selected",
    mrb_mruby_lvgui_native_lv_ta_text_is_selected,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_text_is_selected")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_text_is_selected)
  );

  // ```bool lv_ta_get_text_sel_en(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_text_sel_en",
    mrb_mruby_lvgui_native_lv_ta_get_text_sel_en,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_text_sel_en")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_text_sel_en)
  );

  // ```uint16_t lv_ta_get_pwd_show_time(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_pwd_show_time",
    mrb_mruby_lvgui_native_lv_ta_get_pwd_show_time,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_pwd_show_time")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_pwd_show_time)
  );

  // ```uint16_t lv_ta_get_cursor_blink_time(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_get_cursor_blink_time",
    mrb_mruby_lvgui_native_lv_ta_get_cursor_blink_time,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_get_cursor_blink_time")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_get_cursor_blink_time)
  );

  // ```void lv_ta_clear_selection(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_clear_selection",
    mrb_mruby_lvgui_native_lv_ta_clear_selection,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_clear_selection")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_clear_selection)
  );

  // ```void lv_ta_cursor_right(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_cursor_right",
    mrb_mruby_lvgui_native_lv_ta_cursor_right,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_cursor_right")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_cursor_right)
  );

  // ```void lv_ta_cursor_left(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_cursor_left",
    mrb_mruby_lvgui_native_lv_ta_cursor_left,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_cursor_left")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_cursor_left)
  );

  // ```void lv_ta_cursor_down(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_cursor_down",
    mrb_mruby_lvgui_native_lv_ta_cursor_down,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_cursor_down")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_cursor_down)
  );

  // ```void lv_ta_cursor_up(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_ta_cursor_up",
    mrb_mruby_lvgui_native_lv_ta_cursor_up,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_ta_cursor_up")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_ta_cursor_up)
  );

  // ```void lv_style_copy(lv_style_t * unnamed_parameter_0, const lv_style_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_style_copy",
    mrb_mruby_lvgui_native_lv_style_copy,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_style_copy")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_style_copy)
  );

  // ```void lv_anim_init(lv_anim_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_init",
    mrb_mruby_lvgui_native_lv_anim_init,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_anim_init")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_anim_init)
  );

  // ```void lv_anim_create(lv_anim_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_create",
    mrb_mruby_lvgui_native_lv_anim_create,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_anim_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_anim_create)
  );

  // ```void lv_anim_clear_repeat(lv_anim_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_clear_repeat",
    mrb_mruby_lvgui_native_lv_anim_clear_repeat,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_anim_clear_repeat")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_anim_clear_repeat)
  );

  // ```void lv_anim_set_repeat(lv_anim_t * unnamed_parameter_0, uint16_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_set_repeat",
    mrb_mruby_lvgui_native_lv_anim_set_repeat,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_anim_set_repeat")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_anim_set_repeat)
  );

  // ```void lv_anim_set_playback(lv_anim_t * unnamed_parameter_0, uint16_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_set_playback",
    mrb_mruby_lvgui_native_lv_anim_set_playback,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_anim_set_playback")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_anim_set_playback)
  );

  // ```void lv_anim_set_time(lv_anim_t * unnamed_parameter_0, int16_t unnamed_parameter_1, int16_t unnamed_parameter_2);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_set_time",
    mrb_mruby_lvgui_native_lv_anim_set_time,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_anim_set_time")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_anim_set_time)
  );

  // ```void lv_anim_set_values(lv_anim_t * unnamed_parameter_0, lv_anim_value_t unnamed_parameter_1, lv_anim_value_t unnamed_parameter_2);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_set_values",
    mrb_mruby_lvgui_native_lv_anim_set_values,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_anim_set_values")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_anim_set_values)
  );

  // ```lv_color_t lv_color_mix(lv_color_t c1, lv_color_t c2, uint8_t mix);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_color_mix",
    mrb_mruby_lvgui_native_lv_color_mix,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_color_mix")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_color_mix)
  );

  // ```lv_obj_t * lv_canvas_create(lv_obj_t * par, const lv_obj_t * copy);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_create",
    mrb_mruby_lvgui_native_lv_canvas_create,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_create)
  );

  // ```void lv_canvas_set_buffer(lv_obj_t * canvas, lv_img_dsc_t * buf, lv_coord_t w, lv_coord_t h, lv_img_cf_t cf);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_set_buffer",
    mrb_mruby_lvgui_native_lv_canvas_set_buffer,
    MRB_ARGS_REQ(5)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_set_buffer")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_set_buffer)
  );

  // ```lv_img_dsc_t * lv_canvas_get_img(lv_obj_t * canvas);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_get_img",
    mrb_mruby_lvgui_native_lv_canvas_get_img,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_get_img")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_get_img)
  );

  // ```void lv_canvas_copy_buf(lv_obj_t * canvas, const void * to_copy, lv_coord_t x, lv_coord_t y, lv_coord_t w, lv_coord_t h);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_copy_buf",
    mrb_mruby_lvgui_native_lv_canvas_copy_buf,
    MRB_ARGS_REQ(6)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_copy_buf")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_copy_buf)
  );

  // ```void lv_canvas_rotate(lv_obj_t * canvas, lv_img_dsc_t * img, int16_t angle, lv_coord_t offset_x, lv_coord_t offset_y, int32_t pivot_x, int32_t pivot_y);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_rotate",
    mrb_mruby_lvgui_native_lv_canvas_rotate,
    MRB_ARGS_REQ(7)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_rotate")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_rotate)
  );

  // ```void lv_canvas_fill_bg(lv_obj_t * canvas, lv_color_t color);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_fill_bg",
    mrb_mruby_lvgui_native_lv_canvas_fill_bg,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_fill_bg")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_fill_bg)
  );

  // ```void lv_canvas_draw_rect(lv_obj_t * canvas, lv_coord_t x, lv_coord_t y, lv_coord_t w, lv_coord_t h, const lv_style_t * style);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_draw_rect",
    mrb_mruby_lvgui_native_lv_canvas_draw_rect,
    MRB_ARGS_REQ(6)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_draw_rect")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_draw_rect)
  );

  // ```void lv_canvas_draw_text(lv_obj_t * canvas, lv_coord_t x, lv_coord_t y, lv_coord_t max_w, const lv_style_t * style, const char * txt, lv_label_align_t align);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_draw_text",
    mrb_mruby_lvgui_native_lv_canvas_draw_text,
    MRB_ARGS_REQ(7)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_draw_text")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_draw_text)
  );

  // ```void lv_canvas_draw_img(lv_obj_t * canvas, lv_coord_t x, lv_coord_t y, const char * src, const lv_style_t * style);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_draw_img",
    mrb_mruby_lvgui_native_lv_canvas_draw_img,
    MRB_ARGS_REQ(5)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_draw_img")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_draw_img)
  );

  // ```void lv_canvas_draw_line(lv_obj_t * canvas, const lv_point_t * points, uint32_t point_cnt, const lv_style_t * style);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_draw_line",
    mrb_mruby_lvgui_native_lv_canvas_draw_line,
    MRB_ARGS_REQ(4)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_draw_line")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_draw_line)
  );

  // ```void lv_canvas_draw_polygon(lv_obj_t * canvas, const lv_point_t * points, uint32_t point_cnt, const lv_style_t * style);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_draw_polygon",
    mrb_mruby_lvgui_native_lv_canvas_draw_polygon,
    MRB_ARGS_REQ(4)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_draw_polygon")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_draw_polygon)
  );

  // ```void lv_canvas_draw_arc(lv_obj_t * canvas, lv_coord_t x, lv_coord_t y, lv_coord_t r, int32_t start_angle, int32_t end_angle, const lv_style_t * style);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_canvas_draw_arc",
    mrb_mruby_lvgui_native_lv_canvas_draw_arc,
    MRB_ARGS_REQ(7)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_canvas_draw_arc")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_canvas_draw_arc)
  );

  // ```void lv_task_handler();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_task_handler",
    mrb_mruby_lvgui_native_lv_task_handler,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_task_handler")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_task_handler)
  );

  // ```void lv_anim_core_init();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_core_init",
    mrb_mruby_lvgui_native_lv_anim_core_init,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_anim_core_init")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_anim_core_init)
  );

  // ```lv_group_t * lvgui_get_focus_group();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_focus_group",
    mrb_mruby_lvgui_native_lvgui_get_focus_group,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_focus_group")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_focus_group)
  );

  // ```void lvgui_focus_ring_disable();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_focus_ring_disable",
    mrb_mruby_lvgui_native_lvgui_focus_ring_disable,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_focus_ring_disable")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_focus_ring_disable)
  );

  // ```hal_panel_orientation_t hal_get_panel_orientation();```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "hal_get_panel_orientation",
    mrb_mruby_lvgui_native_hal_get_panel_orientation,
    MRB_ARGS_REQ(0)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "hal_get_panel_orientation")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) hal_get_panel_orientation)
  );

  // ```void lv_group_add_obj(lv_group_t * unnamed_parameter_0, lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_add_obj",
    mrb_mruby_lvgui_native_lv_group_add_obj,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_add_obj")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_add_obj)
  );

  // ```void lv_group_remove_obj(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_remove_obj",
    mrb_mruby_lvgui_native_lv_group_remove_obj,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_remove_obj")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_remove_obj)
  );

  // ```void lv_group_remove_all_objs(lv_group_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_remove_all_objs",
    mrb_mruby_lvgui_native_lv_group_remove_all_objs,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_remove_all_objs")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_remove_all_objs)
  );

  // ```void lv_group_focus_obj(lv_obj_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_focus_obj",
    mrb_mruby_lvgui_native_lv_group_focus_obj,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_focus_obj")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_focus_obj)
  );

  // ```void lv_group_focus_next(lv_group_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_focus_next",
    mrb_mruby_lvgui_native_lv_group_focus_next,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_focus_next")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_focus_next)
  );

  // ```void lv_group_focus_prev(lv_group_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_focus_prev",
    mrb_mruby_lvgui_native_lv_group_focus_prev,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_focus_prev")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_focus_prev)
  );

  // ```void lv_group_focus_freeze(lv_group_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_focus_freeze",
    mrb_mruby_lvgui_native_lv_group_focus_freeze,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_focus_freeze")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_focus_freeze)
  );

  // ```void lv_group_set_click_focus(lv_group_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_set_click_focus",
    mrb_mruby_lvgui_native_lv_group_set_click_focus,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_set_click_focus")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_set_click_focus)
  );

  // ```void lv_group_set_wrap(lv_group_t * unnamed_parameter_0, bool unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_set_wrap",
    mrb_mruby_lvgui_native_lv_group_set_wrap,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_set_wrap")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_set_wrap)
  );

  // ```lv_obj_t * lv_group_get_focused(const lv_group_t * unnamed_parameter_0);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_get_focused",
    mrb_mruby_lvgui_native_lv_group_get_focused,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_get_focused")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_get_focused)
  );

  // ```lv_font_t * lvgui_get_font(char * unnamed_parameter_0, uint16_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lvgui_get_font",
    mrb_mruby_lvgui_native_lvgui_get_font,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_get_font")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_get_font)
  );

  // ```lv_obj_t * lv_obj_get_child_back(const lv_obj_t * unnamed_parameter_0, const lv_obj_t * unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_get_child_back",
    mrb_mruby_lvgui_native_lv_obj_get_child_back,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_get_child_back")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_get_child_back)
  );

  // ```void lv_obj_set_user_data(lv_obj_t * unnamed_parameter_0, lv_obj_user_data_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_user_data",
    mrb_mruby_lvgui_native_lv_obj_set_user_data,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_user_data")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_user_data)
  );

  // ```void lv_group_set_user_data(lv_group_t * unnamed_parameter_0, lv_group_user_data_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_set_user_data",
    mrb_mruby_lvgui_native_lv_group_set_user_data,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_set_user_data")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_set_user_data)
  );

  // ```lv_task_t * lv_task_create(lv_task_cb_t task_xcb, uint32_t period, lv_task_prio_t prio, void * task_proc);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_task_create",
    mrb_mruby_lvgui_native_lv_task_create,
    MRB_ARGS_REQ(4)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_task_create")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_task_create)
  );

  // ```void lv_task_del(lv_task_t * task);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_task_del",
    mrb_mruby_lvgui_native_lv_task_del,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_task_del")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_task_del)
  );

  // ```void lv_task_once(lv_task_t * task);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_task_once",
    mrb_mruby_lvgui_native_lv_task_once,
    MRB_ARGS_REQ(1)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_task_once")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_task_once)
  );

  // Custom handler for tasks callbacks
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_handle_lv_task_callback")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_handle_lv_task_callback)
  );

  // ```void lv_obj_set_event_cb(lv_obj_t * unnamed_parameter_0, lv_event_cb_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_obj_set_event_cb",
    mrb_mruby_lvgui_native_lv_obj_set_event_cb,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_obj_set_event_cb")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_obj_set_event_cb)
  );

  // Custom handler for events callbacks
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_handle_lv_event_callback")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_handle_lv_event_callback)
  );

  // ```void lv_group_set_focus_cb(lv_group_t * unnamed_parameter_0, lv_group_focus_cb_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_group_set_focus_cb",
    mrb_mruby_lvgui_native_lv_group_set_focus_cb,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_group_set_focus_cb")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_group_set_focus_cb)
  );

  // Custom handler for focus callbacks
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lvgui_handle_lv_focus_callback")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lvgui_handle_lv_focus_callback)
  );

  // ```void lv_anim_set_path_cb(lv_anim_t * unnamed_parameter_0, lv_anim_path_cb_t unnamed_parameter_1);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_set_path_cb",
    mrb_mruby_lvgui_native_lv_anim_set_path_cb,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_anim_set_path_cb")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_anim_set_path_cb)
  );

  // ```bool lv_anim_del(void * var, lv_anim_exec_xcb_t exec_cb);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_del",
    mrb_mruby_lvgui_native_lv_anim_del,
    MRB_ARGS_REQ(2)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_anim_del")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_anim_del)
  );

  // ```void lv_anim_set_exec_cb(lv_anim_t * anim, void * var, lv_anim_exec_xcb_t exec_cb);```
  mrb_define_module_function(
    mrb,
    mLVGUI__Native,
    "lv_anim_set_exec_cb",
    mrb_mruby_lvgui_native_lv_anim_set_exec_cb,
    MRB_ARGS_REQ(3)
  );
  
  mrb_hash_set(
    mrb,
    mLVGUI__Native__References,
    mrb_symbol_value(mrb_intern_lit(mrb, "lv_anim_set_exec_cb")),
    mrb_mruby_lvgui_native_wrap_pointer(mrb, (void *) lv_anim_set_exec_cb)
  );

  DONE;

}

void
mrb_mruby_lvgui_native_gem_final(mrb_state* mrb)
{
}

//
////////////////////////////////////////////////////////////////////////////////

