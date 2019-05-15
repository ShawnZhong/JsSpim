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

static void control_c_seen(int /*arg*/);
static void flush_to_newline();
static int get_opt_int();
static bool parse_spim_command(bool redo);
static void print_reg(int reg_no);
static int print_fp_reg(int reg_no);
static int print_reg_from_string(char *reg);
static void print_all_regs(int hex_flag);
static int read_assembly_command();
static int str_prefix(char *s1, char *s2, int min_match);
static void top_level();
static int read_token();


/* Exported Variables: */

/* Not local, but not export so all files don't need setjmp.h */
jmp_buf spim_top_level_env;    /* For ^C */

bool bare_machine;        /* => simulate bare machine */
bool delayed_branches;        /* => simulate delayed branches */
bool delayed_loads;        /* => simulate delayed loads */
bool accept_pseudo_insts = true;    /* => parse pseudo instructions  */
bool quiet;            /* => no warning messages */
bool assemble;            /* => assemble, write to stdout and exit */
char *exception_file_name = DEFAULT_EXCEPTION_HANDLER;
port message_out, console_out, console_in;
bool mapped_io;            /* => activate memory-mapped IO */
int pipe_out;
int spim_return_value;        /* Value returned when spim exits */


/* Local variables: */

/* => load standard exception handler */
static bool load_exception_handler = true;
static int console_state_saved;
static struct termios saved_console_state;
static int program_argc;
static char **program_argv;

int main(int argc, char **argv) {
  console_out.f = stdout;
  message_out.f = stdout;

  /* Input comes directly (not through stdio): */
  console_in.i = 0;

  program_argc = argc - 2;
  program_argv = &argv[2]; /* Everything following is argv */

  initialize_world(load_exception_handler ? exception_file_name : NULL, true);
  initialize_run_stack(program_argc, program_argv);

  read_assembly_file(argv[1]);

  bool continuable;
  initialize_run_stack(program_argc, program_argv);
  if (!setjmp(spim_top_level_env)) {
    char *undefs = undefined_symbol_string();
    if (undefs != NULL) {
      write_output(message_out, "The following symbols are undefined:\n");
      write_output(message_out, undefs);
      write_output(message_out, "\n");
      free(undefs);
    }
    run_program(find_symbol_address(DEFAULT_RUN_LOCATION), DEFAULT_RUN_STEPS, false, false, &continuable);
  }

  //  print_all_regs(false);
  //  dump_text_seg(false);
  //  dump_data_seg(true);
  return (0);
}

static void control_c_seen(int /*arg*/) {
  write_output(message_out, "\nExecution interrupted\n");
  longjmp(spim_top_level_env, 1);
}

/* SPIM commands */

enum {
  UNKNOWN_CMD = 0,
  EXIT_CMD,
  READ_CMD,
  RUN_CMD,
  STEP_CMD,
  PRINT_CMD,
  PRINT_SYM_CMD,
  PRINT_ALL_REGS_CMD,
  REINITIALIZE_CMD,
  ASM_CMD,
  REDO_CMD,
  NOP_CMD,
  HELP_CMD,
  CONTINUE_CMD,
  SET_BKPT_CMD,
  DELETE_BKPT_CMD,
  LIST_BKPT_CMD,
  DUMPNATIVE_TEXT_CMD,
  DUMP_TEXT_CMD
};

static bool parse_spim_command(bool redo) {
  static int prev_cmd = NOP_CMD; /* Default redo */
  static int prev_token;
  int cmd;

  switch (cmd = (redo ? prev_cmd : read_assembly_command())) {
    case RUN_CMD: {
      static mem_addr addr;
      bool continuable;

      addr = (redo ? addr : get_opt_int());
      if (addr == 0) addr = starting_address();

      initialize_run_stack(program_argc, program_argv);
      if (addr != 0) {
        char *undefs = undefined_symbol_string();
        if (undefs != NULL) {
          write_output(message_out, "The following symbols are undefined:\n");
          write_output(message_out, undefs);
          write_output(message_out, "\n");
          free(undefs);
        }

        if (run_program(addr, DEFAULT_RUN_STEPS, false, false, &continuable))
          write_output(message_out, "Breakpoint encountered at 0x%08x\n", PC);
      }

      prev_cmd = RUN_CMD;
      return (0);
    }

    case CONTINUE_CMD: {
      if (PC != 0) {
        bool continuable;
        if (run_program(PC, DEFAULT_RUN_STEPS, false, true, &continuable))
          write_output(message_out, "Breakpoint encountered at 0x%08x\n", PC);
      }
      prev_cmd = CONTINUE_CMD;
      return (0);
    }

    case STEP_CMD: {
      static int steps;
      mem_addr addr;

      steps = (redo ? steps : get_opt_int());
      addr = PC == 0 ? starting_address() : PC;

      if (steps == 0) steps = 1;
      if (addr != 0) {
        bool continuable;
        if (run_program(addr, steps, true, true, &continuable))
          write_output(message_out, "Breakpoint encountered at 0x%08x\n", PC);
      }

      prev_cmd = STEP_CMD;
      return (0);
    }

    case PRINT_CMD: {
      int token = (redo ? prev_token : read_token());
      static int loc;

      if (token == Y_REG) {
        if (redo)
          loc += 1;
        else
          loc = yylval.i;
        print_reg(loc);
      } else if (token == Y_FP_REG) {
        if (redo)
          loc += 2;
        else
          loc = yylval.i;
        print_fp_reg(loc);
      } else if (token == Y_INT) {
        if (redo)
          loc += 4;
        else
          loc = yylval.i;
        print_mem(loc);
      } else if (token == Y_ID) {
        if (!print_reg_from_string((char *) yylval.p)) {
          if (redo)
            loc += 4;
          else
            loc = find_symbol_address((char *) yylval.p);

          if (loc != 0)
            print_mem(loc);
          else
            error("Unknown label: %s\n", yylval.p);
        }
      } else
        error("Print what?\n");
      if (!redo) flush_to_newline();
      prev_cmd = PRINT_CMD;
      prev_token = token;
      return (0);
    }

    case PRINT_SYM_CMD:print_symbols();
      if (!redo) flush_to_newline();
      prev_cmd = NOP_CMD;
      return (0);

    case PRINT_ALL_REGS_CMD: {
      int hex_flag = 0;
      int token = (redo ? prev_token : read_token());
      if (token == Y_ID && streq((char *) yylval.p, "hex")) hex_flag = 1;
      print_all_regs(hex_flag);
      if (!redo) flush_to_newline();
      prev_cmd = NOP_CMD;
      return (0);
    }

    case REINITIALIZE_CMD:flush_to_newline();
      initialize_world(load_exception_handler ? exception_file_name : NULL,
                       true);
      initialize_run_stack(program_argc, program_argv);
      write_startup_message();
      prev_cmd = NOP_CMD;
      return (0);

    case ASM_CMD:yyparse();
      prev_cmd = ASM_CMD;
      return (0);

    case SET_BKPT_CMD:
    case DELETE_BKPT_CMD: {
      int token = (redo ? prev_token : read_token());
      static mem_addr addr;

      if (!redo) flush_to_newline();
      if (token == Y_INT)
        addr = redo ? addr + 4 : (mem_addr) yylval.i;
      else if (token == Y_ID)
        addr = redo ? addr + 4 : find_symbol_address((char *) yylval.p);
      else
        error("Must supply an address for breakpoint\n");
      if (cmd == SET_BKPT_CMD)
        add_breakpoint(addr);
      else
        delete_breakpoint(addr);
      prev_cmd = cmd;

      return (0);
    }

    case LIST_BKPT_CMD:if (!redo) flush_to_newline();
      list_breakpoints();
      prev_cmd = LIST_BKPT_CMD;
      return (0);

    case DUMPNATIVE_TEXT_CMD:
    case DUMP_TEXT_CMD: {
      int token = (redo ? prev_token : read_token());

      FILE *fp = NULL;
      char *filename = NULL;

      int words = 0;
      mem_addr addr;
      mem_addr dump_start;
      mem_addr dump_end;

      if (token == Y_STR)
        filename = (char *) yylval.p;
      else if (token == Y_NL)
        filename = "spim.dump";
      else {
        fprintf(stderr, "usage: %s [ \"filename\" ]\n",
                (cmd == DUMP_TEXT_CMD ? "dump" : "dumpnative"));
        return (0);
      }

      fp = fopen(filename, "wbt");
      if (fp == NULL) {
        perror(filename);
        return (0);
      }

      user_kernel_text_segment(false);
      dump_start = find_symbol_address(END_OF_TRAP_HANDLER_SYMBOL);
      dump_end = current_text_pc();

      for (addr = dump_start; addr < dump_end; addr += BYTES_PER_WORD) {
        int32 code = inst_encode(read_mem_inst(addr));
        if (cmd == DUMP_TEXT_CMD)
          code = (int32) htonl(
              (unsigned long) code); /* dump in network byte order */
        (void) fwrite(&code, 1, sizeof(code), fp);
        words += 1;
      }

      fclose(fp);
      fprintf(stderr, "Dumped %d words starting at 0x%08x to file %s\n", words,
              (unsigned int) dump_start, filename);

      prev_cmd = cmd;
      return (0);
    }
  }
}

/* Read and return an integer from the current line of input.  If the
   line doesn't contain an integer, return 0.  In either case, flush the
   rest of the line, including the newline. */

static int get_opt_int() {
  int token;

  if ((token = read_token()) == Y_INT) {
    flush_to_newline();
    return (yylval.i);
  } else if (token == Y_NL)
    return (0);
  else {
    flush_to_newline();
    return (0);
  }
}

/* Flush the rest of the input line up to and including the next newline. */

static void flush_to_newline() {
  while (read_token() != Y_NL);
}

/* Print register number N. */

static void print_reg(int reg_no) {
  write_output(message_out, "Reg %d = 0x%08x (%d)\n", reg_no, R[reg_no],
               R[reg_no]);
}

static int print_fp_reg(int reg_no) {
  if ((reg_no & 1) == 0)
    write_output(message_out, "FP reg %d = %g (double)\n", reg_no,
                 FPR_D(reg_no));
  write_output(message_out, "FP reg %d = %g (single)\n", reg_no, FPR_S(reg_no));
  return (1);
}

static int print_reg_from_string(char *reg_num) {
  char s[100];
  char *s1 = s;

  /* Conver to lower case */
  while (*reg_num != '\0' && s1 - s < 100) *s1++ = tolower(*reg_num++);
  *s1 = '\0';
  /* Drop leading $ */
  if (s[0] == '$')
    s1 = s + 1;
  else
    s1 = s;

  if (streq(s1, "pc"))
    write_output(message_out, "PC = 0x%08x (%d)\n", PC, PC);
  else if (streq(s1, "hi"))
    write_output(message_out, "HI = 0x%08x (%d)\n", HI, HI);
  else if (streq(s1, "lo"))
    write_output(message_out, "LO = 0x%08x (%d)\n", LO, LO);
  else if (streq(s1, "fpcond"))
    write_output(message_out, "FCSR = 0x%08x (%d)\n", FCSR, FCSR);
  else if (streq(s1, "cause"))
    write_output(message_out, "Cause = 0x%08x (%d)\n", CP0_Cause, CP0_Cause);
  else if (streq(s1, "epc"))
    write_output(message_out, "EPC = 0x%08x (%d)\n", CP0_EPC, CP0_EPC);
  else if (streq(s1, "status"))
    write_output(message_out, "Status = 0x%08x (%d)\n", CP0_Status, CP0_Status);
  else if (streq(s1, "badvaddr"))
    write_output(message_out, "BadVAddr = 0x%08x (%d)\n", CP0_BadVAddr,
                 CP0_BadVAddr);
  else
    return (0);

  return (1);
}

static void print_all_regs(int hex_flag) {
  static str_stream ss;

  ss_clear(&ss);
  format_registers(&ss, hex_flag, hex_flag);
  write_output(message_out, "%s\n", ss_to_string(&ss));
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
  FILE *f;
  int restore_console_to_program = 0;

  va_start(args, fmt);
  f = fp.f;

  if (console_state_saved) {
    restore_console_to_program = 1;
  }

  if (f != 0) {
    vfprintf(f, fmt, args);
    fflush(f);
  } else {
    vfprintf(stdout, fmt, args);
    fflush(stdout);
  }
  va_end(args);

  if (restore_console_to_program) {
  }
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
  fd_set fdset;
  struct timeval timeout;

  if (mapped_io) {
    timeout.tv_sec = 0;
    timeout.tv_usec = 0;
    FD_ZERO(&fdset);
    FD_SET((int) console_in.i, &fdset);
    return (select(sizeof(fdset) * 8, &fdset, NULL, NULL, &timeout));
  } else
    return (0);
}

char get_console_char() {
  char buf;

  read((int) console_in.i, &buf, 1);

  if (buf == 3) /* ^C */
    control_c_seen(0);
  return (buf);
}

void put_console_char(char c) {
  putc(c, console_out.f);
  fflush(console_out.f);
}

static int read_token() {
  int token = yylex();

  if (token == 0) /* End of file */
  {
    exit(0);
  } else {
    return (token);
  }
}

/*
 * Writes the contents of the (user and optionally kernel) text segment in
 * text.asm file. If data.asm already exists, it's replaced.
 */

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

}