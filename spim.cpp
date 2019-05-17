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
#include <ctype.h>
#include <setjmp.h>
#include <signal.h>
#include <arpa/inet.h>

#include <sys/types.h>
#include <sys/select.h>

#include <termios.h>
#include <stdarg.h>

#include "spim.h"
#include "string-stream.h"
#include "spim-utils.h"
#include "inst.h"
#include "reg.h"
#include "mem.h"
#include "parser.h"
#include "sym-tbl.h"
#include "scanner.h"
#include "parser_yacc.h"
#include "data.h"

/* Exported Variables: */

/* Not local, but not export so all files don't need setjmp.h */
jmp_buf spim_top_level_env;    /* For ^C */

bool bare_machine;        /* => simulate bare machine */
bool delayed_branches;        /* => simulate delayed branches */
bool delayed_loads;        /* => simulate delayed loads */
bool accept_pseudo_insts = true;    /* => parse pseudo instructions  */
bool quiet;            /* => no warning messages */
char *exception_file_name = DEFAULT_EXCEPTION_HANDLER;
port message_out, console_out, console_in;
bool mapped_io;            /* => activate memory-mapped IO */
int spim_return_value;        /* Value returned when spim exits */

static int console_state_saved;

char *get_segment(mem_addr from, mem_addr to) {
  static str_stream ss;
  ss_clear(&ss);
  format_insts(&ss, from, to);
  return ss_to_string(&ss);
}

extern "C" {
char *get_user_text() {
  return get_segment(TEXT_BOT, text_top);
}

char *get_user_data() {
  return get_segment(DATA_BOT, data_top);
}

char *get_user_stack() {
  return get_segment(ROUND_DOWN (R[29], BYTES_PER_WORD), STACK_TOP);
}

char *get_kernel_text() {
  return get_segment(K_TEXT_BOT, k_text_top);
}

char *get_kernel_data() {
  return get_segment(K_DATA_BOT, k_data_top);
}

char *get_all_regs(int hex_flag) {
  static str_stream ss;
  ss_clear(&ss);

  int print_gpr_hex = hex_flag;
  int print_fpr_hex = hex_flag;

  int i;
  char *grstr, *fpstr;
  char *grfill, *fpfill;

  ss_printf(&ss, "PC=%08x\t", PC);
  ss_printf(&ss, "EPC=%08x\t", CP0_EPC);
  ss_printf(&ss, "Cause=%08x\t", CP0_Cause);
  ss_printf(&ss, "BadVAddr=%08x\t", CP0_BadVAddr);
  ss_printf(&ss, "Status=%08x\t", CP0_Status);
  ss_printf(&ss, "HI=%08x\t", HI);
  ss_printf(&ss, "LO=%08x\t", LO);

  if (print_gpr_hex)
    grstr = "R%-2d (%2s)=%08x", grfill = "\t";
  else
    grstr = "R%-2d (%2s)=%-10d", grfill = "\t";

  ss_printf(&ss, "\n\nGeneral Registers\n");
  for (i = 0; i < 8; i++) {
    ss_printf(&ss, grstr, i, int_reg_names[i], R[i]);
    ss_printf(&ss, grfill);
    ss_printf(&ss, grstr, i + 8, int_reg_names[i + 8], R[i + 8]);
    ss_printf(&ss, grfill);
    ss_printf(&ss, grstr, i + 16, int_reg_names[i + 16], R[i + 16]);
    ss_printf(&ss, grfill);
    ss_printf(&ss, grstr, i + 24, int_reg_names[i + 24], R[i + 24]);
    ss_printf(&ss, "\t");
  }

  ss_printf(&ss, "FIR=%08x\t", FIR);
  ss_printf(&ss, "FCSR=%08x\t", FCSR);
  ss_printf(&ss, "FCCR=%08x\t", FCCR);
  ss_printf(&ss, "FEXR=%08x\t", FEXR);
  ss_printf(&ss, "FENR=%08x\t", FENR);

  ss_printf(&ss, "\n\nDouble Floating Point Registers\n");

  if (print_fpr_hex)
    fpstr = "FP%-2d=%08x,%08x", fpfill = "\t";
  else
    fpstr = "FP%-2d=%#-13.6g", fpfill = "\t";

  if (print_fpr_hex)
    for (i = 0; i < 4; i += 1) {
      int *r1, *r2;

      /* Use pointers to cast to ints without invoking float->int conversion
         so we can just print the bits. */
      r1 = (int *) &FPR[i];
      r2 = r1 + 1;
      ss_printf(&ss, fpstr, 2 * i, *r1, *r2);
      ss_printf(&ss, fpfill);

      r1 = (int *) &FPR[i + 4];
      r2 = r1 + 1;
      ss_printf(&ss, fpstr, 2 * i + 8, *r1, *r2);
      ss_printf(&ss, fpfill);

      r1 = (int *) &FPR[i + 8];
      r2 = r1 + 1;
      ss_printf(&ss, fpstr, 2 * i + 16, *r1, *r2);
      ss_printf(&ss, fpfill);

      r1 = (int *) &FPR[i + 12];
      r2 = r1 + 1;
      ss_printf(&ss, fpstr, 2 * i + 24, *r1, *r2);
      ss_printf(&ss, "\t");
    }
  else
    for (i = 0; i < 4; i += 1) {
      ss_printf(&ss, fpstr, 2 * i, FPR[i]);
      ss_printf(&ss, fpfill);
      ss_printf(&ss, fpstr, 2 * i + 8, FPR[i + 4]);
      ss_printf(&ss, fpfill);
      ss_printf(&ss, fpstr, 2 * i + 16, FPR[i + 8]);
      ss_printf(&ss, fpfill);
      ss_printf(&ss, fpstr, 2 * i + 24, FPR[i + 12]);
      ss_printf(&ss, "\t");
    }

  if (print_fpr_hex)
    fpstr = "FP%-2d=%08x", fpfill = "\t";
  else
    fpstr = "FP%-2d=%#-13.6g", fpfill = "\t";

  ss_printf(&ss, "\n\nSingle Floating Point Registers\n");

  if (print_fpr_hex)
    for (i = 0; i < 8; i += 1) {
      /* Use pointers to cast to ints without invoking float->int conversion
         so we can just print the bits. */
      ss_printf(&ss, fpstr, i, *(int *) &FPR_S(i));
      ss_printf(&ss, fpfill);

      ss_printf(&ss, fpstr, i + 8, *(int *) &FPR_S(i + 8));
      ss_printf(&ss, fpfill);

      ss_printf(&ss, fpstr, i + 16, *(int *) &FPR_S(i + 16));
      ss_printf(&ss, fpfill);

      ss_printf(&ss, fpstr, i + 24, *(int *) &FPR_S(i + 24));
      ss_printf(&ss, "\t");
    }
  else
    for (i = 0; i < 8; i += 1) {
      ss_printf(&ss, fpstr, i, FPR_S(i));
      ss_printf(&ss, fpfill);
      ss_printf(&ss, fpstr, i + 8, FPR_S(i + 8));
      ss_printf(&ss, fpfill);
      ss_printf(&ss, fpstr, i + 16, FPR_S(i + 16));
      ss_printf(&ss, fpfill);
      ss_printf(&ss, fpstr, i + 24, FPR_S(i + 24));
      ss_printf(&ss, "\t");
    }

  return ss_to_string(&ss);
}

char *print_fp_reg(int reg_no) {
  if ((reg_no & 1) == 0)
    write_output(message_out, "FP reg %d=%g (double)\n", reg_no, FPR_D(reg_no));
  write_output(message_out, "FP reg %d=%g (single)\n", reg_no, FPR_S(reg_no));
}

int get_reg(int reg_no) {
  return R[reg_no];
}

void init(char *filename) {
  console_out.f = stdout;
  message_out.f = stdout;

  console_in.i = 0;

  initialize_world(exception_file_name, false);
  initialize_run_stack(0, NULL);
  read_assembly_file(filename);
}

void run() {
  bool continuable;
  if (run_program(starting_address(), DEFAULT_RUN_STEPS, false, false, &continuable))
    write_output(message_out, "Breakpoint encountered at 0x%08x\n", PC);
  write_output(message_out, "\n");
}

void step() {
  mem_addr addr = PC == 0 ? starting_address() : PC;
  if (addr == 0) return;

  bool continuable;
  if (run_program(addr, 1, true, true, &continuable))
    write_output(message_out, "Breakpoint encountered at 0x%08x\n", PC);
  write_output(message_out, "\n");
}

void conti() {
  if (PC == 0) return;

  bool continuable;
  if (run_program(PC, DEFAULT_RUN_STEPS, false, true, &continuable))
    write_output(message_out, "Breakpoint encountered at 0x%08x\n", PC);
  write_output(message_out, "\n");
}

void add_bp(int addr) {
  add_breakpoint(addr);
}

void delete_bp(int addr) {
  delete_breakpoint(addr);
}

void print_symbol() {
  print_symbols();
}
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
  longjmp(spim_top_level_env, 1);
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
  int restore_console_to_program = 0;

  if (console_state_saved) {
    restore_console_to_program = 1;
  }

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

  if (restore_console_to_program) {
  }
}

int console_input_available() {
  return 0;
}

char get_console_char() {
  char buf;
  read((int) console_in.i, &buf, 1);
  return (buf);
}

void put_console_char(char c) {
  putc(c, console_out.f);
  fflush(console_out.f);
}