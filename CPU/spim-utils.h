/* SPIM S20 MIPS simulator.
   Interface to misc. routines for SPIM.

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


/* Triple containing a string and two integers.	 Used in tables
   mapping from a name to values. */

typedef struct
{
  char *name;
  int value1;
  int value2;
} name_val_val;



/* Exported functions: */

void add_breakpoint (mem_addr addr);
void delete_breakpoint (mem_addr addr);
void format_data_segs (str_stream *ss);
void format_insts (str_stream *ss, mem_addr from, mem_addr to);
void format_mem (str_stream *ss, mem_addr from, mem_addr to);
void format_registers (str_stream *ss, int print_gpr_hex, int print_fpr_hex);
void initialize_registers ();
void initialize_stack (const char *command_line);
void initialize_run_stack (int argc, char **argv);
void initialize_world (char *exception_file_names, bool print_message);
void list_breakpoints ();
name_val_val *map_int_to_name_val_val (name_val_val tbl[], int tbl_len, int num);
name_val_val *map_string_to_name_val_val (name_val_val tbl[], int tbl_len, char *id);
bool read_assembly_file (char *name);
bool run_program (mem_addr pc, int steps, bool display, bool cont_bkpt, bool* continuable);
mem_addr starting_address ();
char *str_copy (char *str);
void write_startup_message ();
void *xmalloc (int);
void *zmalloc (int);
