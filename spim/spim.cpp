/* SPIM S20 MIPS simulator.
   Terminal interface for SPIM simulator.

   Copyright (c) 1990-2015, James R. Larus.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without modification,
   are permitted provided that the following conditions are met:

   Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

   Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation and/or
   other materials provided with the distribution.

   Neither the name of the James R. Larus nor the names of its contributors may be
   used to endorse or promote products derived from this software without specific
   prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
   GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
   LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
   OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "emscripten/bind.h"
#include "emscripten/val.h"

#include <unistd.h>
#include <stdio.h>
#include <stdarg.h>
#include <sstream>

#include "spim.h"
#include "string-stream.h"
#include "spim-utils.h"
#include "inst.h"
#include "reg.h"
#include "mem.h"
#include "data.h"

#define PRE(text)  "<div>" text "</pre>"
#define PRE_H(text) "<div style='background-color: yellow;'>" text "</pre>"

using namespace emscripten;

bool bare_machine;        /* => simulate bare machine */
bool delayed_branches;        /* => simulate delayed branches */
bool delayed_loads;        /* => simulate delayed loads */
bool accept_pseudo_insts = true;    /* => parse pseudo instructions  */
bool quiet;            /* => no warning messages */
char *exception_file_name;
port message_out, console_out, console_in;
bool mapped_io;            /* => activate memory-mapped IO */
int spim_return_value;        /* Value returned when spim exits */

extern "C" {

str_stream ss;

void init() {
  initialize_world(DEFAULT_EXCEPTION_HANDLER, false);
  initialize_run_stack(0, nullptr);
  read_assembly_file("input.s");
  PC = starting_address();
}

int step(int step_size, bool cont_bkpt) {
  mem_addr addr = PC == 0 ? starting_address() : PC;
  if (step_size == 0) step_size = DEFAULT_RUN_STEPS;

  bool continuable, bp_encountered;
  bp_encountered = run_program(addr, step_size, false, cont_bkpt, &continuable);

  if (!continuable) { // finished
    printf("\n");
    return 0;
  }

  if (bp_encountered) {
    error("Breakpoint encountered at 0x%08x\n", PC);
    return -1;
  }

  return 1;
}

char *getText(mem_addr from, mem_addr to) {
  ss_clear(&ss);
  format_insts(&ss, from, to);
  return ss_to_string(&ss);
}

char *getKernelText() { return getText(K_TEXT_BOT, k_text_top); }

char *getUserText() { return getText(TEXT_BOT, text_top); }

char *getKernelData() {
  ss_clear(&ss);
  return ss_to_string(&ss);
}

mem_word *prev_data_seg;
mem_addr prev_data_top;

bool isUserDataChanged() {
  if (prev_data_top != data_top)
    return true;

  for (int i = 0; i < (data_top - DATA_BOT) / 4; ++i)
    if (data_seg[i] != prev_data_seg[i])
      return true;

  return false;
}

char *getUserData(bool compute_diff) {
  ss_clear(&ss);

  for (mem_addr addr = DATA_BOT; addr < data_top; addr += BYTES_PER_WORD * 4) {

    int i = (addr - DATA_BOT) / 4;
    // skip empty
    if (data_seg[i] == 0 && data_seg[i + 1] == 0 && data_seg[i + 2] == 0 && data_seg[i + 3] == 0)
      continue;

    // open tag
    ss_printf(&ss, "<div>[<span class='hljs-attr'>%08x</span>] ", addr);

    // print hex
    for (int j = 0; j < 4; ++j) {
      if (compute_diff && (data_seg[i + j] != prev_data_seg[i + j] || addr > prev_data_top))
        ss_printf(&ss, "<span class='hljs-number' style='background-color: yellow;'>%08x</span> ", data_seg[i + j]);
      else
        ss_printf(&ss, "<span class='hljs-number'>%08x</span> ", data_seg[i + j]);
    }

    // print ascii
    char *start = (char *) &data_seg[i];
    for (int k = 0; k < 16; ++k) {
      if (start[k] >= 32 && start[k] < 127)
        ss_printf(&ss, "%c", start[k]);
      else
        ss_printf(&ss, "�");
    }

    // close tag
    ss_printf(&ss, "</pre>", addr);
  }

  if (prev_data_top != data_top) {
    free(prev_data_seg);
    prev_data_seg = (mem_word *) malloc(data_top - DATA_BOT);
  }

  memcpy(prev_data_seg, data_seg, data_top - DATA_BOT);
  prev_data_top = data_top;

  return ss_to_string(&ss);
}

}

EMSCRIPTEN_BINDINGS(delete_breakpoint) { function("deleteBreakpoint", &delete_breakpoint); }
EMSCRIPTEN_BINDINGS(add_breakpoint) { function("addBreakpoint", &add_breakpoint); }

val getStack() { return val(typed_memory_view(STACK_LIMIT / 16, (unsigned int *) stack_seg)); }
EMSCRIPTEN_BINDINGS(getStack) { function("getStack", &getStack); }

unsigned int getPC() { return PC; }
EMSCRIPTEN_BINDINGS(getPC) { function("getPC", &getPC); }

val getGeneralRegVals() { return val(typed_memory_view(32, (unsigned int *) R)); }
EMSCRIPTEN_BINDINGS(getGeneralRegVals) { function("getGeneralRegVals", &getGeneralRegVals); }

val getFloatRegVals() { return val(typed_memory_view(32, (float *) FPR)); }
EMSCRIPTEN_BINDINGS(getFloatRegVals) { function("getFloatRegVals", &getFloatRegVals); }

val getDoubleRegVals() { return val(typed_memory_view(16, (double *) FPR)); }
EMSCRIPTEN_BINDINGS(getDoubleRegVals) { function("getDoubleRegVals", &getDoubleRegVals); }

val getSpecialRegVals() {
  static unsigned int specialRegs[12];
  specialRegs[0] = PC;
  specialRegs[1] = CP0_EPC;
  specialRegs[2] = CP0_Cause;
  specialRegs[3] = CP0_BadVAddr;
  specialRegs[4] = CP0_Status;
  specialRegs[5] = HI;
  specialRegs[6] = LO;
  specialRegs[7] = FIR;
  specialRegs[8] = FCSR;
  specialRegs[9] = FCCR;
  specialRegs[10] = FEXR;
  specialRegs[11] = FENR;

  return val(typed_memory_view(12, specialRegs));
}
EMSCRIPTEN_BINDINGS(getSpecialRegVals) { function("getSpecialRegVals", &getSpecialRegVals); }

/* Print an error message. */

void error(char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  vfprintf(stderr, fmt, args);
  va_end(args);
}

/* Print the error message then exit. */

void fatal_error(char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  fmt = va_arg(args, char *);
  vfprintf(stderr, fmt, args);
  exit(-1);
}

/* Print an error message and return to top level. */

void run_error(char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  vfprintf(stderr, fmt, args);
  va_end(args);
}

/* IO facilities: */

void write_output(port fp, char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  vfprintf(stdout, fmt, args);
  fflush(stdout);
  va_end(args);
}

/* Simulate the semantics of fgets (not gets) on Unix file. */

void read_input(char *str, int str_size) {
  char *ptr;
  ptr = str;
  while (1 < str_size) /* Reserve space for null */
  {
    char buf[1];
    if (read((int) console_in.i, buf, 1) <= 0) /* Not in raw mode! */
      break;

    *ptr++ = buf[0];
    str_size -= 1;

    if (buf[0] == '\n') break;
  }

  if (0 < str_size) *ptr = '\0'; /* Null terminate input */
}

int console_input_available() {
  return 0;
}

char get_console_char() {
  char buf;
  read(0, &buf, 1);
  return (buf);
}

void put_console_char(char c) {
  putc(c, stdout);
  fflush(stdout);
}