/* SPIM S20 MIPS simulator.
   Data structures for symbolic addresses.

   Copyright (c) 1990-2010, James R. Larus.
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


typedef struct lab_use
{
  instruction *inst;		/* NULL => Data, not code */
  mem_addr addr;
  struct lab_use *next;
} label_use;


/* Symbol table information on a label. */

typedef struct lab
{
  char *name;			/* Name of label */
  long addr;			/* Address of label or 0 if not yet defined */
  unsigned global_flag : 1;	/* Non-zero => declared global */
  unsigned gp_flag : 1;		/* Non-zero => referenced off gp */
  unsigned const_flag : 1;	/* Non-zero => constant value (in addr) */
  struct lab *next;		/* Hash table link */
  struct lab *next_local;	/* Link in list of local labels */
  label_use *uses;		/* List of instructions that reference */
} label;			/* label that has not yet been defined */


#define SYMBOL_IS_DEFINED(SYM) ((SYM)->addr != 0)



/* Exported functions: */

mem_addr find_symbol_address (char *symbol);
void flush_local_labels (int issue_undef_warnings);
void initialize_symbol_table ();
label *label_is_defined (char *name);
label *lookup_label (char *name);
label *make_label_global (char *name);
void print_symbols ();
void print_undefined_symbols ();
label *record_label (char *name, mem_addr address, int resolve_uses);
void record_data_uses_symbol (mem_addr location, label *sym);
void record_inst_uses_symbol (instruction *inst, label *sym);
char *undefined_symbol_string ();
void resolve_a_label (label *sym, instruction *inst);
void resolve_label_uses (label *sym);
