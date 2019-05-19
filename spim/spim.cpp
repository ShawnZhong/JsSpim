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

#define PRE(text)  "<pre>" text "</pre>"
#define PRE_H(text) "<pre style='background-color: yellow;'>" text "</pre>"

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

static str_stream ss;

bool step() {
  mem_addr addr = PC == 0 ? starting_address() : PC;

  bool continuable;
  if (run_program(addr, 1, false, true, &continuable))
    error("Breakpoint encountered at 0x%08x\n", PC);

  if (!continuable)
    printf("\n");

  return continuable;
}

void run() {
  mem_addr addr = PC == 0 ? starting_address() : PC;
  bool continuable;
  if (run_program(addr, DEFAULT_RUN_STEPS, false, false, &continuable))
    error("Breakpoint encountered at 0x%08x\n", PC);
  printf("\n");
}

void conti() {
  if (PC == 0) return;

  bool continuable;
  if (run_program(PC, DEFAULT_RUN_STEPS, false, true, &continuable))
    error("Breakpoint encountered at 0x%08x\n", PC);
  printf("\n");
}

void init() {
  initialize_world(DEFAULT_EXCEPTION_HANDLER, false);
  initialize_run_stack(0, nullptr);
  read_assembly_file("input.s");
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

char *getUserData() {
  ss_clear(&ss);

  static mem_word *prev_data_seg = (mem_word *) calloc(data_top - DATA_BOT, 1);
  static mem_addr prev_data_top = data_top;
  static bool prev_initialized = false;

  for (mem_addr i = DATA_BOT; i < data_top; i += BYTES_PER_WORD) {
    int index = (i - DATA_BOT) / 4;
    if (data_seg[index] == 0) continue;
    if (prev_initialized && data_seg[index] != prev_data_seg[index])
      ss_printf(&ss, PRE_H("[0x%08x] 0x%08x"), i, data_seg[index]);
    else
      ss_printf(&ss, PRE("[0x%08x] 0x%08x"), i, data_seg[index]);
    prev_data_seg[index] = data_seg[index];
  }

  if (prev_data_top != data_top) {
    prev_data_seg = (mem_word *) malloc(data_top - DATA_BOT);
  }

  prev_data_top = data_top;
  prev_initialized = true;

  return ss_to_string(&ss);
}

char *getUserStack() {
  ss_clear(&ss);

  static mem_addr prev_stack_bottom;
  static mem_word prev_stack_seg[STACK_LIMIT];
  static bool prev_initialized = false;

  mem_addr curr_stack_bottom = ROUND_DOWN(R[29], BYTES_PER_WORD);

  for (mem_addr i = curr_stack_bottom; i < STACK_TOP; i += BYTES_PER_WORD) {
    int index = (i - stack_bot) / 4;
    if (prev_initialized && (i < prev_stack_bottom || stack_seg[index] != prev_stack_seg[index]))
      ss_printf(&ss, PRE_H("0x%08x"), stack_seg[index]);
    else
      ss_printf(&ss, PRE("0x%08x"), stack_seg[index]);

    prev_stack_seg[index] = stack_seg[index];
  }

  prev_stack_bottom = curr_stack_bottom;
  prev_initialized = true;

  return ss_to_string(&ss);
}

char *getGeneralRegVals() {
  ss_clear(&ss);

  static reg_word prev_R[R_LENGTH];
  static bool prev_initialized = false;

  for (int i = 0; i < R_LENGTH; i++) {
    if (prev_initialized && R[i] != prev_R[i])
      ss_printf(&ss, PRE_H("R%-2d (%2s) = %08x"), i, int_reg_names[i], R[i]);
    else
      ss_printf(&ss, PRE("R%-2d (%2s) = %08x"), i, int_reg_names[i], R[i]);
  }

  memcpy(prev_R, R, sizeof(prev_R));
  prev_initialized = true;

  return ss_to_string(&ss);
}

char *getSpecialRegVals() {
  ss_clear(&ss);

  static mem_word prev_values[7];
  static bool prev_initialized = false;

  const char *names[]{"PC", "EPC", "Cause", "BadVAddr", "Status", "HI", "LO"};
  mem_word values[]{(mem_word) PC, CP0_EPC, CP0_Cause, CP0_BadVAddr, CP0_Status, HI, LO};

  for (int i = 0; i < 7; ++i) {
    if (prev_initialized && values[i] != prev_values[i])
      ss_printf(&ss, PRE_H("%-8s = %08x"), names[i], values[i]);
    else
      ss_printf(&ss, PRE("%-8s = %08x"), names[i], values[i]);
  }

  memcpy(prev_values, values, sizeof(prev_values));
  prev_initialized = true;

  return ss_to_string(&ss);
}

int getPC() { return PC; }
void addBreakpoint(mem_addr addr) { add_breakpoint(addr); }
void deleteBreakpoint(mem_addr addr) { delete_breakpoint(addr); }
}

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