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


#ifndef WIN32
#include <unistd.h>
#endif
#include <stdio.h>
#include <ctype.h>
#include <setjmp.h>
#include <signal.h>
#include <arpa/inet.h>


#ifdef RS
/* This is problem on HP Snakes, which define RS in syscall.h */
#undef RS
#endif

#include <sys/types.h>
#include <sys/select.h>

#ifdef _AIX
#ifndef NBBY
#define NBBY 8
#endif
#endif


#ifndef WIN32
#include <sys/time.h>
#ifdef NEED_TERMIOS
#include <sys/ioctl.h>
#include <sgtty.h>
#else
#include <termios.h>
#endif
#endif

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


/* Internal functions: */

static void console_to_program ();
static void console_to_spim ();
static void control_c_seen (int /*arg*/);
static void flush_to_newline ();
static int get_opt_int ();
static bool parse_spim_command (bool redo);
static void print_reg (int reg_no);
static int print_fp_reg (int reg_no);
static int print_reg_from_string (char *reg);
static void print_all_regs (int hex_flag);
static int read_assembly_command ();
static int str_prefix (char *s1, char *s2, int min_match);
static void top_level ();
static int read_token ();
static bool write_assembled_code(char* program_name);
static void dump_data_seg (bool kernel_also);
static void dump_text_seg (bool kernel_also);


/* Exported Variables: */

/* Not local, but not export so all files don't need setjmp.h */
jmp_buf spim_top_level_env;	/* For ^C */

bool bare_machine;		/* => simulate bare machine */
bool delayed_branches;		/* => simulate delayed branches */
bool delayed_loads;		/* => simulate delayed loads */
bool accept_pseudo_insts;	/* => parse pseudo instructions  */
bool quiet;			/* => no warning messages */
bool assemble;			/* => assemble, write to stdout and exit */
char *exception_file_name = DEFAULT_EXCEPTION_HANDLER;
port message_out, console_out, console_in;
bool mapped_io;			/* => activate memory-mapped IO */
int pipe_out;
int spim_return_value;		/* Value returned when spim exits */


/* Local variables: */

/* => load standard exception handler */
static bool load_exception_handler = true;
static int console_state_saved;
#ifdef NEED_TERMIOS
static struct sgttyb saved_console_state;
#else
static struct termios saved_console_state;
#endif
static int program_argc;
static char** program_argv;
static bool dump_user_segments = false;
static bool dump_all_segments = false;



int
main (int argc, char **argv)
{
  int i;
  bool assembly_file_loaded = false;
  int print_usage_msg = 0;

  console_out.f = stdout;
  message_out.f = stdout;

  bare_machine = false;
  delayed_branches = false;
  delayed_loads = false;
  accept_pseudo_insts = true;
  quiet = false;
  assemble = false;
  spim_return_value = 0;

  /* Input comes directly (not through stdio): */
  console_in.i = 0;
  mapped_io = false;

  // write_startup_message ();

  if (getenv ("SPIM_EXCEPTION_HANDLER") != NULL)
    exception_file_name = getenv ("SPIM_EXCEPTION_HANDLER");

  for (i = 1; i < argc; i++)
    {
#ifdef WIN32
      if (argv [i][0] == '/') { argv [i][0] = '-'; }
#endif
      if (streq (argv [i], "-asm")
	  || streq (argv [i], "-a"))
	{
	  bare_machine = false;
	  delayed_branches = false;
	  delayed_loads = false;
	}
      else if (streq (argv [i], "-bare")
	       || streq (argv [i], "-b"))
	{
	  bare_machine = true;
	  delayed_branches = true;
	  delayed_loads = true;
	  quiet = true;
	}
      else if (streq (argv [i], "-delayed_branches")
	       || streq (argv [i], "-db"))
	{
	  delayed_branches = true;
	}
      else if (streq (argv [i], "-delayed_loads")
	       || streq (argv [i], "-dl"))
	{
	  delayed_loads = true;
	}
      else if (streq (argv [i], "-exception")
	       || streq (argv [i], "-e"))
	{ load_exception_handler = true; }
      else if (streq (argv [i], "-noexception")
	       || streq (argv [i], "-ne"))
	{ load_exception_handler = false; }
      else if (streq (argv [i], "-exception_file")
	       || streq (argv [i], "-ef"))
	{
	  exception_file_name = argv[++i];
	  load_exception_handler = true;
	}
      else if (streq (argv [i], "-mapped_io")
	       || streq (argv [i], "-mio"))
	{ mapped_io = true; }
      else if (streq (argv [i], "-nomapped_io")
	       || streq (argv [i], "-nmio"))
	{ mapped_io = false; }
      else if (streq (argv [i], "-pseudo")
	       || streq (argv [i], "-p"))
	{ accept_pseudo_insts = true; }
      else if (streq (argv [i], "-nopseudo")
	       || streq (argv [i], "-np"))
	{ accept_pseudo_insts = false; }
      else if (streq (argv [i], "-quiet")
	       || streq (argv [i], "-q"))
	{ quiet = true; }
      else if (streq (argv [i], "-noquiet")
	       || streq (argv [i], "-nq"))
	{ quiet = false; }
      else if (streq (argv [i], "-trap")
	       || streq (argv [i], "-t"))
	{ load_exception_handler = true; }
      else if (streq (argv [i], "-notrap")
	       || streq (argv [i], "-nt"))
	{ load_exception_handler = false; }
      else if (streq (argv [i], "-trap_file")
	       || streq (argv [i], "-tf"))
	{
	  exception_file_name = argv[++i];
	  load_exception_handler = true;
	}
      else if (streq (argv [i], "-stext")
	       || streq (argv [i], "-st"))
	{ initial_text_size = atoi (argv[++i]); }
      else if (streq (argv [i], "-sdata")
	       || streq (argv [i], "-sd"))
	{ initial_data_size = atoi (argv[++i]); }
      else if (streq (argv [i], "-ldata")
	       || streq (argv [i], "-ld"))
	{ initial_data_limit = atoi (argv[++i]); }
      else if (streq (argv [i], "-sstack")
	       || streq (argv [i], "-ss"))
	{ initial_stack_size = atoi (argv[++i]); }
      else if (streq (argv [i], "-lstack")
	       || streq (argv [i], "-ls"))
	{ initial_stack_limit = atoi (argv[++i]); }
      else if (streq (argv [i], "-sktext")
	       || streq (argv [i], "-skt"))
	{ initial_k_text_size = atoi (argv[++i]); }
      else if (streq (argv [i], "-skdata")
	       || streq (argv [i], "-skd"))
	{ initial_k_data_size = atoi (argv[++i]); }
      else if (streq (argv [i], "-lkdata")
	       || streq (argv [i], "-lkd"))
	{ initial_k_data_limit = atoi (argv[++i]); }
      else if (((streq (argv [i], "-file")
                 || streq (argv [i], "-f"))
                && (i + 1 < argc))
               /* Assume this argument is a file name and everything following are
                  arguments for program */
               || (argv [i][0] != '-'))
	{
	  program_argc = argc - (i + 1);
	  program_argv = &argv[i + 1]; /* Everything following is argv */

	  if (!assembly_file_loaded)
	    {
          initialize_world (load_exception_handler ? exception_file_name : NULL, true);
          initialize_run_stack (program_argc, program_argv);
	    }
	  assembly_file_loaded = read_assembly_file (argv[++i]) || assembly_file_loaded;
	  break;
	}
      else if (streq (argv [i], "-assemble"))
	{ assemble = true; }
      else if (streq (argv [i], "-dump"))
        { dump_user_segments = true; }
      else if (streq (argv [i], "-full_dump"))
        { dump_all_segments = true; }
      else
	{
	  error ("\nUnknown argument: %s (ignored)\n", argv[i]);
	  print_usage_msg = 1;
	}
    }

  if (print_usage_msg)
    {
      error ("Usage: spim\n\
	-bare			Bare machine (no pseudo-ops, delayed branches and loads)\n\
	-asm			Extended machine (pseudo-ops, no delayed branches and loads) (default)\n\
	-delayed_branches	Execute delayed branches\n\
	-delayed_loads		Execute delayed loads\n\
	-exception		Load exception handler (default)\n\
	-noexception		Do not load exception handler\n\
	-exception_file <file>	Specify exception handler in place of default\n\
	-quiet			Do not print warnings\n\
	-noquiet		Print warnings (default)\n\
	-mapped_io		Enable memory-mapped IO\n\
	-nomapped_io		Do not enable memory-mapped IO (default)\n\
	-file <file> <args>	Assembly code file and arguments to program\n\
	-assemble		Write assembled code to standard output\n\
	-dump			Write user data and text segments into files\n\
	-full_dump		Write user and kernel data and text into files.\n");
    }


  if (!assembly_file_loaded)
    {
      initialize_world (load_exception_handler ? exception_file_name : NULL, true);
      initialize_run_stack (program_argc, program_argv);
      top_level ();
    }
  else /* assembly_file_loaded */
    {
     if (assemble)
       {
         return write_assembled_code (program_argv[0]);
       }
     else if (dump_user_segments)
       {
         dump_data_seg (false);
         dump_text_seg (false);
       }
      else if (dump_all_segments)
       {
         dump_data_seg (true);
         dump_text_seg (true);
       }
     else
       {
         bool continuable;
         console_to_program ();
         initialize_run_stack (program_argc, program_argv);
         if (!setjmp (spim_top_level_env))
           {
             char *undefs = undefined_symbol_string ();
             if (undefs != NULL)
               {
                 write_output (message_out, "The following symbols are undefined:\n");
                 write_output (message_out, undefs);
                 write_output (message_out, "\n");
                 free (undefs);
               }
             run_program (find_symbol_address (DEFAULT_RUN_LOCATION), DEFAULT_RUN_STEPS, false, false, &continuable);
           }
         console_to_spim ();
       }
    }

  return (spim_return_value);
}



/* Top-level read-eval-print loop for SPIM. */

static void
top_level ()
{
  bool redo = false;            /* => reexecute last command */

  (void)signal (SIGINT, control_c_seen);
  initialize_scanner (stdin);
  initialize_parser ("<standard input>");
  while (1)
    {
      if (!redo)
	write_output (message_out, "(spim) ");
      if (!setjmp (spim_top_level_env))
	redo = parse_spim_command (redo);
      else
	redo = false;
      fflush (stdout);
      fflush (stderr);
    }
}


static void
control_c_seen (int /*arg*/)
{
  console_to_spim ();
  write_output (message_out, "\nExecution interrupted\n");
  longjmp (spim_top_level_env, 1);
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


/* Parse a SPIM command from the currently open file and execute it.
   If REDO is true, don't read a new command; just rexecute the
   previous one.  Return true if the command was to redo the previous
   command. */

static bool
parse_spim_command (bool redo)
{
  static int prev_cmd = NOP_CMD; /* Default redo */
  static int prev_token;
  int cmd;

  switch (cmd = (redo ? prev_cmd : read_assembly_command ()))
    {
    case EXIT_CMD:
      console_to_spim ();
      exit (0);

    case READ_CMD:
      {
	int token = (redo ? prev_token : read_token ());

	if (!redo) flush_to_newline ();
	if (token == Y_STR)
	  {
	    read_assembly_file ((char *) yylval.p);
        pop_scanner();
	  }
	else
	  error ("Must supply a filename to read\n");
	prev_cmd = READ_CMD;
	return (0);
      }

    case RUN_CMD:
      {
	static mem_addr addr;
        bool continuable;

	addr = (redo ? addr : get_opt_int ());
	if (addr == 0)
	  addr = starting_address ();

	initialize_run_stack (program_argc, program_argv);
	console_to_program ();
	if (addr != 0)
	{
	  char *undefs = undefined_symbol_string ();
	  if (undefs != NULL)
	    {
	      write_output (message_out, "The following symbols are undefined:\n");
	      write_output (message_out, undefs);
	      write_output (message_out, "\n");
	      free (undefs);
	    }

	  if (run_program (addr, DEFAULT_RUN_STEPS, false, false, &continuable))
	    write_output (message_out, "Breakpoint encountered at 0x%08x\n", PC);
	}
	console_to_spim ();

	prev_cmd = RUN_CMD;
	return (0);
      }

    case CONTINUE_CMD:
      {
	if (PC != 0)
	  {
            bool continuable;
	    console_to_program ();
	    if (run_program (PC, DEFAULT_RUN_STEPS, false, true, &continuable))
	      write_output (message_out, "Breakpoint encountered at 0x%08x\n", PC);
	    console_to_spim ();
	  }
	prev_cmd = CONTINUE_CMD;
	return (0);
      }

    case STEP_CMD:
      {
	static int steps;
	mem_addr addr;

	steps = (redo ? steps : get_opt_int ());
	addr = PC == 0 ? starting_address () : PC;

	if (steps == 0)
	  steps = 1;
	if (addr != 0)
	  {
            bool continuable;
	    console_to_program ();
	    if (run_program (addr, steps, true, true, &continuable))
	      write_output (message_out, "Breakpoint encountered at 0x%08x\n", PC);
	    console_to_spim ();
	  }

	prev_cmd = STEP_CMD;
	return (0);
      }

    case PRINT_CMD:
      {
	int token = (redo ? prev_token : read_token ());
	static int loc;

	if (token == Y_REG)
	  {
	    if (redo) loc += 1;
	    else loc = yylval.i;
	    print_reg (loc);
	  }
	else if (token == Y_FP_REG)
	  {
	    if (redo) loc += 2;
	    else loc = yylval.i;
	    print_fp_reg (loc);
	  }
	else if (token == Y_INT)
	  {
	    if (redo) loc += 4;
	    else loc = yylval.i;
	    print_mem (loc);
	  }
	else if (token == Y_ID)
	  {
	    if (!print_reg_from_string ((char *) yylval.p))
	      {
		if (redo) loc += 4;
		else loc = find_symbol_address ((char *) yylval.p);

		if (loc != 0)
		  print_mem (loc);
		else
		  error ("Unknown label: %s\n", yylval.p);
	      }
	  }
	else
	  error ("Print what?\n");
	if (!redo) flush_to_newline ();
	prev_cmd = PRINT_CMD;
	prev_token = token;
	return (0);
      }

    case PRINT_SYM_CMD:
      print_symbols ();
      if (!redo) flush_to_newline ();
      prev_cmd = NOP_CMD;
      return (0);

    case PRINT_ALL_REGS_CMD:
      {
	int hex_flag = 0;
	int token = (redo ? prev_token : read_token ());
	if (token == Y_ID && streq((char*)yylval.p, "hex"))
	  hex_flag = 1;
	print_all_regs (hex_flag);
	if (!redo) flush_to_newline ();
	prev_cmd = NOP_CMD;
	return (0);
      }

    case REINITIALIZE_CMD:
      flush_to_newline ();
      initialize_world (load_exception_handler ? exception_file_name : NULL, true);
      initialize_run_stack (program_argc, program_argv);
      write_startup_message ();
      prev_cmd = NOP_CMD;
      return (0);

    case ASM_CMD:
      yyparse ();
      prev_cmd = ASM_CMD;
      return (0);

    case REDO_CMD:
      return (1);

    case NOP_CMD:
      prev_cmd = NOP_CMD;
      return (0);

    case HELP_CMD:
      if (!redo) flush_to_newline ();
      write_output (message_out, "\nSPIM is a MIPS32 simulator.\n");
      write_output (message_out, "Its top-level commands are:\n");
      write_output (message_out, "exit  -- Exit the simulator\n");
      write_output (message_out, "quit  -- Exit the simulator\n");
      write_output (message_out,
		    "read \"FILE\" -- Read FILE containing assembly code into memory\n");
      write_output (message_out,
		    "load \"FILE\" -- Same as read\n");
      write_output (message_out,
		    "run <ADDR> -- Start the program at (optional) ADDRESS\n");
      write_output (message_out,
		    "step <N> -- Step the program for N instructions (default 1)\n");
      write_output (message_out,
		    "continue -- Continue program execution without stepping\n");
      write_output (message_out, "print $N -- Print register N\n");
      write_output (message_out,
		    "print $fN -- Print floating point register N\n");
      write_output (message_out,
		    "print ADDR -- Print contents of memory at ADDRESS\n");
      write_output (message_out,
		    "print_symbols -- Print all global symbols\n");
      write_output (message_out,
		    "print_all_regs -- Print all MIPS registers\n");
      write_output (message_out,
		    "print_all_regs hex -- Print all MIPS registers in hex\n");
      write_output (message_out,
		    "reinitialize -- Clear the memory and registers\n");
      write_output (message_out,
		    "breakpoint <ADDR> -- Set a breakpoint at address ADDR\n");
      write_output (message_out,
		    "delete <ADDR> -- Delete breakpoint at address ADDR\n");
      write_output (message_out, "list -- List all breakpoints\n");
      write_output (message_out, "dump [ \"FILE\" ] -- Dump binary code to spim.dump or FILE in network byte order\n");
      write_output (message_out, "dumpnative [ \"FILE\" ] -- Dump binary code to spim.dump or FILE in host byte order\n");
      write_output (message_out,
		    ". -- Rest of line is assembly instruction to execute\n");
      write_output (message_out, "<cr> -- Newline reexecutes previous command\n");
      write_output (message_out, "? -- Print this message\n");

      write_output (message_out,
		    "\nMost commands can be abbreviated to their unique prefix\n");
      write_output (message_out, "e.g., ex(it), re(ad), l(oad), ru(n), s(tep), p(rint)\n\n");
      prev_cmd = HELP_CMD;
      return (0);

    case SET_BKPT_CMD:
    case DELETE_BKPT_CMD:
      {
	int token = (redo ? prev_token : read_token ());
	static mem_addr addr;

	if (!redo) flush_to_newline ();
	if (token == Y_INT)
	  addr = redo ? addr + 4 : (mem_addr)yylval.i;
	else if (token == Y_ID)
	  addr = redo ? addr + 4 : find_symbol_address ((char *) yylval.p);
	else
	  error ("Must supply an address for breakpoint\n");
	if (cmd == SET_BKPT_CMD)
	  add_breakpoint (addr);
	else
	  delete_breakpoint (addr);
	prev_cmd = cmd;

	return (0);
      }

    case LIST_BKPT_CMD:
      if (!redo) flush_to_newline ();
      list_breakpoints ();
      prev_cmd = LIST_BKPT_CMD;
      return (0);

    case DUMPNATIVE_TEXT_CMD:
    case DUMP_TEXT_CMD:
      {
	int token = (redo ? prev_token : read_token ());

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
        else
          {
            fprintf (stderr, "usage: %s [ \"filename\" ]\n",
                     (cmd == DUMP_TEXT_CMD ? "dump" : "dumpnative"));
            return (0);
          }

        fp = fopen (filename, "wbt");
        if (fp == NULL)
          {
            perror (filename);
            return (0);
          }

	user_kernel_text_segment (false);
	dump_start = find_symbol_address (END_OF_TRAP_HANDLER_SYMBOL);
	dump_end = current_text_pc ();

        for (addr = dump_start; addr < dump_end; addr += BYTES_PER_WORD)
          {
            int32 code = inst_encode (read_mem_inst (addr));
            if (cmd == DUMP_TEXT_CMD)
	      code = (int32)htonl ((unsigned long)code);    /* dump in network byte order */
            (void)fwrite (&code, 1, sizeof(code), fp);
            words += 1;
          }

        fclose (fp);
        fprintf (stderr, "Dumped %d words starting at 0x%08x to file %s\n",
                 words, (unsigned int)dump_start, filename);

        prev_cmd = cmd;
        return (0);
      }

    default:
      while (read_token () != Y_NL) ;
      error ("Unknown spim command\n");
      return (0);
    }
}


/* Read a SPIM command with the scanner and return its ennuemerated
   value. */

static int
read_assembly_command ()
{
  int token = read_token ();

  if (token == Y_NL)		/* Blank line means redo */
    return (REDO_CMD);
  else if (token != Y_ID)	/* Better be a string */
    return (UNKNOWN_CMD);
  else if (str_prefix ((char *) yylval.p, "exit", 2))
    return (EXIT_CMD);
  else if (str_prefix ((char *) yylval.p, "quit", 2))
    return (EXIT_CMD);
  else if (str_prefix ((char *) yylval.p, "print", 1))
    return (PRINT_CMD);
  else if (str_prefix ((char *) yylval.p, "print_symbols", 7))
    return (PRINT_SYM_CMD);
  else if (str_prefix ((char *) yylval.p, "print_all_regs", 7))
    return (PRINT_ALL_REGS_CMD);
  else if (str_prefix ((char *) yylval.p, "run", 2))
    return (RUN_CMD);
  else if (str_prefix ((char *) yylval.p, "read", 2))
    return (READ_CMD);
  else if (str_prefix ((char *) yylval.p, "load", 2))
    return (READ_CMD);
  else if (str_prefix ((char *) yylval.p, "reinitialize", 6))
    return (REINITIALIZE_CMD);
  else if (str_prefix ((char *) yylval.p, "step", 1))
    return (STEP_CMD);
  else if (str_prefix ((char *) yylval.p, "help", 1))
    return (HELP_CMD);
  else if (str_prefix ((char *) yylval.p, "continue", 1))
    return (CONTINUE_CMD);
  else if (str_prefix ((char *) yylval.p, "breakpoint", 2))
    return (SET_BKPT_CMD);
  else if (str_prefix ((char *) yylval.p, "delete", 1))
    return (DELETE_BKPT_CMD);
  else if (str_prefix ((char *) yylval.p, "list", 2))
    return (LIST_BKPT_CMD);
  else if (str_prefix ((char *) yylval.p, "dumpnative", 5))
    return (DUMPNATIVE_TEXT_CMD);
  else if (str_prefix ((char *) yylval.p, "dump", 4))
    return (DUMP_TEXT_CMD);
  else if (*(char *) yylval.p == '?')
    return (HELP_CMD);
  else if (*(char *) yylval.p == '.')
    return (ASM_CMD);
  else
    return (UNKNOWN_CMD);
}


/* Return non-nil if STRING1 is a (proper) prefix of STRING2. */

static int
str_prefix (char *s1, char *s2, int min_match)
{
  for ( ; *s1 == *s2 && *s1 != '\0'; s1 ++, s2 ++) min_match --;
  return (*s1 == '\0' && min_match <= 0);
}


/* Read and return an integer from the current line of input.  If the
   line doesn't contain an integer, return 0.  In either case, flush the
   rest of the line, including the newline. */

static int
get_opt_int ()
{
  int token;

  if ((token = read_token ()) == Y_INT)
    {
      flush_to_newline ();
      return (yylval.i);
    }
  else if (token == Y_NL)
    return (0);
  else
    {
      flush_to_newline ();
      return (0);
    }
}


/* Flush the rest of the input line up to and including the next newline. */

static void
flush_to_newline ()
{
  while (read_token () != Y_NL) ;
}


/* Print register number N. */

static void
print_reg (int reg_no)
{
  write_output (message_out, "Reg %d = 0x%08x (%d)\n", reg_no, R[reg_no], R[reg_no]);
}


static int
print_fp_reg (int reg_no)
{
  if ((reg_no & 1) == 0)
    write_output (message_out, "FP reg %d = %g (double)\n", reg_no, FPR_D (reg_no));
  write_output (message_out, "FP reg %d = %g (single)\n", reg_no, FPR_S (reg_no));
  return (1);
}


static int
print_reg_from_string (char* reg_num)
{
  char s[100];
  char *s1 = s;

  /* Conver to lower case */
  while (*reg_num != '\0' && s1 - s < 100)
    *s1++ = tolower (*reg_num++);
  *s1 = '\0';
  /* Drop leading $ */
  if (s[0] == '$')
    s1 = s + 1;
  else
    s1 = s;

  if (streq (s1, "pc"))
    write_output (message_out, "PC = 0x%08x (%d)\n", PC, PC);
  else if (streq (s1, "hi"))
    write_output (message_out, "HI = 0x%08x (%d)\n", HI, HI);
  else if (streq (s1, "lo"))
    write_output (message_out, "LO = 0x%08x (%d)\n", LO, LO);
  else if (streq (s1, "fpcond"))
    write_output (message_out, "FCSR = 0x%08x (%d)\n", FCSR, FCSR);
  else if (streq (s1, "cause"))
    write_output (message_out, "Cause = 0x%08x (%d)\n", CP0_Cause, CP0_Cause);
  else if (streq (s1, "epc"))
    write_output (message_out, "EPC = 0x%08x (%d)\n", CP0_EPC, CP0_EPC);
  else if (streq (s1, "status"))
    write_output (message_out, "Status = 0x%08x (%d)\n", CP0_Status, CP0_Status);
  else if (streq (s1, "badvaddr"))
    write_output (message_out, "BadVAddr = 0x%08x (%d)\n", CP0_BadVAddr, CP0_BadVAddr);
  else
    return (0);

  return (1);
}


static void
print_all_regs (int hex_flag)
{
  static str_stream ss;

  ss_clear (&ss);
  format_registers (&ss, hex_flag, hex_flag);
  write_output (message_out, "%s\n", ss_to_string (&ss));
}


static bool
write_assembled_code(char* program_name)
{
  if (parse_error_occurred)
    {
      return (parse_error_occurred);
    }

  FILE *fp = NULL;
  char *filename = NULL;

  mem_addr addr;
  mem_addr dump_start;
  mem_addr dump_end;

  filename = (char*) xmalloc(strlen(program_name) + 5);
  strcpy(filename, program_name);
  strcat(filename, ".out");

  fp = fopen (filename, "wt");
  if (fp == NULL)
    {
      perror (filename);
      return (true);
    }

  /* dump text segment */
  user_kernel_text_segment (false);
  dump_start = find_symbol_address (END_OF_TRAP_HANDLER_SYMBOL);
  dump_end = current_text_pc ();

  (void)fprintf (fp, ".text # 0x%x .. 0x%x\n.word ", dump_start, dump_end);
  for (addr = dump_start; addr < dump_end; addr += BYTES_PER_WORD)
    {
      int32 code = inst_encode (read_mem_inst (addr));
      (void)fprintf (fp, "0x%x%s", code, addr != (dump_end - BYTES_PER_WORD) ? ", " : "");
    }
  (void)fprintf (fp, "\n");

  /* dump data segment */
  user_kernel_data_segment (false);
  if (bare_machine)
    {
      dump_start = 0;
    }
    else
    {
        dump_start = DATA_BOT;
    }
  dump_end = current_data_pc ();

  if (dump_end > dump_start)
    {
      (void)fprintf (fp, ".data # 0x%x .. 0x%x\n.word ", dump_start, dump_end);
      for (addr = dump_start; addr < dump_end; addr += BYTES_PER_WORD)
        {
          int32 code = read_mem_word (addr);
          (void)fprintf (fp, "0x%x%s", code, addr != (dump_end - BYTES_PER_WORD) ? ", " : "");
        }
      (void)fprintf (fp, "\n");
    }

  fclose (fp);
  return (false);
}



/* Print an error message. */

void
error (char *fmt, ...)
{
  va_list args;

  va_start (args, fmt);

#ifdef NEED_VFPRINTF
  _doprnt (fmt, args, stderr);
#else
  vfprintf (stderr, fmt, args);
#endif
  va_end (args);
}


/* Print the error message then exit. */

void
fatal_error (char *fmt, ...)
{
  va_list args;
  va_start (args, fmt);
  fmt = va_arg (args, char *);

#ifdef NEED_VFPRINTF
  _doprnt (fmt, args, stderr);
#else
  vfprintf (stderr, fmt, args);
#endif
  exit (-1);
}


/* Print an error message and return to top level. */

void
run_error (char *fmt, ...)
{
  va_list args;

  va_start (args, fmt);

  console_to_spim ();

#ifdef NEED_VFPRINTF
  _doprnt (fmt, args, stderr);
#else
  vfprintf (stderr, fmt, args);
#endif
  va_end (args);
  longjmp (spim_top_level_env, 1);
}



/* IO facilities: */

void
write_output (port fp, char *fmt, ...)
{
  va_list args;
  FILE *f;
  int restore_console_to_program = 0;

  va_start (args, fmt);
  f = fp.f;

  if (console_state_saved)
    {
      restore_console_to_program = 1;
      console_to_spim ();
    }

  if (f != 0)
    {
#ifdef NEED_VFPRINTF
      _doprnt (fmt, args, f);
#else
      vfprintf (f, fmt, args);
#endif
      fflush (f);
    }
  else
    {
#ifdef NEED_VFPRINTF
      _doprnt (fmt, args, stdout);
#else
      vfprintf (stdout, fmt, args);
#endif
      fflush (stdout);
    }
  va_end (args);

  if (restore_console_to_program)
    console_to_program ();
}


/* Simulate the semantics of fgets (not gets) on Unix file. */

void
read_input (char *str, int str_size)
{
  char *ptr;
  int restore_console_to_program = 0;

  if (console_state_saved)
    {
      restore_console_to_program = 1;
      console_to_spim ();
    }

  ptr = str;

  while (1 < str_size)		/* Reserve space for null */
    {
      char buf[1];
      if (read ((int) console_in.i, buf, 1) <= 0) /* Not in raw mode! */
        break;

      *ptr ++ = buf[0];
      str_size -= 1;

      if (buf[0] == '\n')
	break;
    }

  if (0 < str_size)
    *ptr = '\0';		/* Null terminate input */

  if (restore_console_to_program)
    console_to_program ();
}


/* Give the console to the program for IO. */

static void
console_to_program ()
{
  if (mapped_io && !console_state_saved)
    {
#ifdef NEED_TERMIOS
      int flags;
      ioctl ((int) console_in.i, TIOCGETP, (char *) &saved_console_state);
      flags = saved_console_state.sg_flags;
      saved_console_state.sg_flags = (flags | RAW) & ~(CRMOD|ECHO);
      ioctl ((int) console_in.i, TIOCSETP, (char *) &saved_console_state);
      saved_console_state.sg_flags = flags;
#else
      struct termios params;

      tcgetattr (console_in.i, &saved_console_state);
      params = saved_console_state;
      params.c_iflag &= ~(ISTRIP|INLCR|ICRNL|IGNCR|IXON|IXOFF|INPCK|BRKINT|PARMRK);

      /* Translate CR -> NL to canonicalize input. */
      params.c_iflag |= IGNBRK|IGNPAR|ICRNL;
      params.c_oflag = OPOST|ONLCR;
      params.c_cflag &= ~PARENB;
      params.c_cflag |= CREAD|CS8;
      params.c_lflag = 0;
      params.c_cc[VMIN] = 1;
      params.c_cc[VTIME] = 1;

      tcsetattr (console_in.i, TCSANOW, &params);
#endif
      console_state_saved = 1;
    }
}


/* Return the console to SPIM. */

static void
console_to_spim ()
{
  if (mapped_io && console_state_saved)
#ifdef NEED_TERMIOS
    ioctl ((int) console_in.i, TIOCSETP, (char *) &saved_console_state);
#else
    tcsetattr (console_in.i, TCSANOW, &saved_console_state);
#endif
  console_state_saved = 0;
}


int
console_input_available ()
{
  fd_set fdset;
  struct timeval timeout;

  if (mapped_io)
    {
      timeout.tv_sec = 0;
      timeout.tv_usec = 0;
      FD_ZERO (&fdset);
      FD_SET ((int) console_in.i, &fdset);
      return (select (sizeof (fdset) * 8, &fdset, NULL, NULL, &timeout));
    }
  else
    return (0);
}


char
get_console_char ()
{
  char buf;

  read ((int) console_in.i, &buf, 1);

  if (buf == 3)			/* ^C */
    control_c_seen (0);
  return (buf);
}


void
put_console_char (char c)
{
  putc (c, console_out.f);
  fflush (console_out.f);
}


static int
read_token ()
{
  int token = yylex ();

  if (token == 0)		/* End of file */
    {
      console_to_spim ();
      exit (0);
    }
  else
    {
      return (token);
    }
}


/* 
 * Writes the contents of the (user and optionally kernel) data segment into data.asm file. 
 * If data.asm already exists, it's replaced.
 */

static void
dump_data_seg(bool kernel_also)
{
  static str_stream ss;
  ss_clear (&ss);

  if (kernel_also) 
    {
      format_data_segs (&ss);
    }
  else
    {
      ss_printf (&ss, "\tDATA\n");
      format_mem (&ss, DATA_BOT, data_top);
    }
  
  FILE *fp;
  fp = fopen ("data.asm", "w");
  fprintf (fp, "%s", ss_to_string (&ss));
  fclose (fp);
}


/* 
 * Writes the contents of the (user and optionally kernel) text segment in text.asm file. 
 * If data.asm already exists, it's replaced.
 */

static void
dump_text_seg(bool kernel_also)
{
  static str_stream ss;
  ss_clear (&ss);

  if (kernel_also)
    {
      format_insts (&ss, TEXT_BOT, text_top);
      ss_printf (&ss, "\n\tKERNEL\n");
      format_insts (&ss, K_TEXT_BOT, k_text_top);
    }
  else
    {
      ss_printf (&ss, "\n\tUSER TEXT SEGMENT\n");
      format_insts (&ss, TEXT_BOT, text_top);
    }
  
  FILE *fp;
  fp = fopen ("text.asm", "w");
  fprintf (fp, "%s", ss_to_string (&ss));
  fclose (fp);
}
