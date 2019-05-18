/* SPIM S20 MIPS simulator.
   Utilities for displaying machine contents.

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


#include "spim.h"
#include "string-stream.h"
#include "spim-utils.h"
#include "inst.h"
#include "data.h"
#include "reg.h"
#include "mem.h"
#include "run.h"
#include "sym-tbl.h"


char* int_reg_names[32] =
  {"r0", "at", "v0", "v1", "a0", "a1", "a2", "a3",
   "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7",
   "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7",
   "t8", "t9", "k0", "k1", "gp", "sp", "s8", "ra"};


static mem_addr format_partial_line (str_stream *ss, mem_addr addr);


/* Write to the stream the contents of the machine's registers, in a wide
   variety of formats. */

void
format_registers (str_stream *ss, int print_gpr_hex, int print_fpr_hex)
{
  int i;
  char *grstr, *fpstr;
  char *grfill, *fpfill;

  ss_printf (ss, " PC      = %08x   ", PC);
  ss_printf (ss, "EPC     = %08x  ", CP0_EPC);
  ss_printf (ss, " Cause   = %08x  ", CP0_Cause);
  ss_printf (ss, " BadVAddr= %08x\n", CP0_BadVAddr);
  ss_printf (ss, " Status  = %08x   ", CP0_Status);
  ss_printf (ss, "HI      = %08x  ", HI);
  ss_printf (ss, " LO      = %08x\n", LO);

  if (print_gpr_hex)
    grstr = "R%-2d (%2s) = %08x", grfill = "  ";
  else
    grstr = "R%-2d (%2s) = %-10d", grfill = " ";

  ss_printf (ss, "\t\t\t\t General Registers\n");
  for (i = 0; i < 8; i++)
    {
      ss_printf (ss, grstr, i, int_reg_names[i], R[i]);
      ss_printf (ss, grfill);
      ss_printf (ss, grstr, i+8, int_reg_names[i+8], R[i+8]);
      ss_printf (ss, grfill);
      ss_printf (ss, grstr, i+16, int_reg_names[i+16], R[i+16]);
      ss_printf (ss, grfill);
      ss_printf (ss, grstr, i+24, int_reg_names[i+24], R[i+24]);
      ss_printf (ss, "\n");
    }

  ss_printf (ss, "\n FIR    = %08x   ", FIR);
  ss_printf (ss, " FCSR    = %08x   ", FCSR);
  ss_printf (ss, " FCCR   = %08x  ", FCCR);
  ss_printf (ss, " FEXR    = %08x\n", FEXR);
  ss_printf (ss, " FENR   = %08x\n", FENR);

  ss_printf (ss, "\t\t\t      Double Floating Point Registers\n");

  if (print_fpr_hex)
    fpstr = "FP%-2d=%08x,%08x", fpfill = " ";
  else
    fpstr = "FP%-2d = %#-13.6g", fpfill = " ";

  if (print_fpr_hex)
    for (i = 0; i < 4; i += 1)
      {
	int *r1, *r2;

	/* Use pointers to cast to ints without invoking float->int conversion
	   so we can just print the bits. */
	r1 = (int *)&FPR[i]; r2 = r1 + 1;
	ss_printf (ss, fpstr, 2*i, *r1, *r2);
	ss_printf (ss, fpfill);

	r1 = (int *)&FPR[i+4]; r2 = r1 + 1;
	ss_printf (ss, fpstr, 2*i+8, *r1, *r2);
	ss_printf (ss, fpfill);

	r1 = (int *)&FPR[i+8]; r2 = r1 + 1;
	ss_printf (ss, fpstr, 2*i+16, *r1, *r2);
	ss_printf (ss, fpfill);

	r1 = (int *)&FPR[i+12]; r2 = r1 + 1;
	ss_printf (ss, fpstr, 2*i+24, *r1, *r2);
	ss_printf (ss, "\n");
      }
  else for (i = 0; i < 4; i += 1)
    {
      ss_printf (ss, fpstr, 2*i, FPR[i]);
      ss_printf (ss, fpfill);
      ss_printf (ss, fpstr, 2*i+8, FPR[i+4]);
      ss_printf (ss, fpfill);
      ss_printf (ss, fpstr, 2*i+16, FPR[i+8]);
      ss_printf (ss, fpfill);
      ss_printf (ss, fpstr, 2*i+24, FPR[i+12]);
      ss_printf (ss, "\n");
    }

  if (print_fpr_hex)
    fpstr = "FP%-2d=%08x", fpfill = " ";
  else
    fpstr = "FP%-2d = %#-13.6g", fpfill = " ";

  ss_printf (ss, "\t\t\t      Single Floating Point Registers\n");

  if (print_fpr_hex)
    for (i = 0; i < 8; i += 1)
      {
	/* Use pointers to cast to ints without invoking float->int conversion
	   so we can just print the bits. */
	ss_printf (ss, fpstr, i, *(int *)&FPR_S(i));
	ss_printf (ss, fpfill);

	ss_printf (ss, fpstr, i+8, *(int *)&FPR_S(i+8));
	ss_printf (ss, fpfill);

	ss_printf (ss, fpstr, i+16, *(int *)&FPR_S(i+16));
	ss_printf (ss, fpfill);

	ss_printf (ss, fpstr, i+24, *(int *)&FPR_S(i+24));
	ss_printf (ss, "\n");
      }
  else for (i = 0; i < 8; i += 1)
    {
      ss_printf (ss, fpstr, i, FPR_S(i));
      ss_printf (ss, fpfill);
      ss_printf (ss, fpstr, i+8, FPR_S(i+8));
      ss_printf (ss, fpfill);
      ss_printf (ss, fpstr, i+16, FPR_S(i+16));
      ss_printf (ss, fpfill);
      ss_printf (ss, fpstr, i+24, FPR_S(i+24));
      ss_printf (ss, "\n");
    }
}



/* Write to the stream a printable representation of the instructions in
   memory addresses: FROM...TO. */

void
format_insts (str_stream *ss, mem_addr from, mem_addr to)
{
  instruction *inst;
  mem_addr i;

  for (i = from; i < to; i += 4)
    {
      inst = read_mem_inst (i);
      if (inst != NULL)
	{
	  format_an_inst (ss, inst, i);
	}
    }
}


/* Write to the stream a printable representation of the data and stack
   segments. */

void
format_data_segs (str_stream *ss)
{
  ss_printf (ss, "\tDATA\n");
  format_mem (ss, DATA_BOT, data_top);

  ss_printf (ss, "\n\tSTACK\n");
  format_mem (ss, ROUND_DOWN (R[29], BYTES_PER_WORD), STACK_TOP);

  ss_printf (ss, "\n\tKERNEL DATA\n");
  format_mem (ss, K_DATA_BOT, k_data_top);
}


#define BYTES_PER_LINE (4*BYTES_PER_WORD)


/* Write to the stream a printable representation of the data in memory
   address: FROM...TO. */

void
format_mem (str_stream *ss, mem_addr from, mem_addr to)
{
  mem_word val;
  mem_addr i = ROUND_UP (from, BYTES_PER_WORD);
  int j;

  i = format_partial_line (ss, i);

  for ( ; i < to; )
    {
      /* Count consecutive zero words */
      for (j = 0; (i + (uint32) j * BYTES_PER_WORD) < to; j += 1)
	{
	  val = read_mem_word (i + (uint32) j * BYTES_PER_WORD);
	  if (val != 0)
	    {
	      break;
	    }
	}

      if (j >= 4)
	{
	  /* Block of 4 or more zero memory words: */
	  ss_printf (ss, "[0x%08x]...[0x%08x]	0x00000000\n",
		     i,
		     i + (uint32) j * BYTES_PER_WORD);

	  i = i + (uint32) j * BYTES_PER_WORD;
	  i = format_partial_line (ss, i);
	}
      else
	{
	  /* Fewer than 4 zero words, print them on a single line: */
	  ss_printf (ss, "[0x%08x]		      ", i);
	  do
	    {
	      val = read_mem_word (i);
	      ss_printf (ss, "  0x%08x", (unsigned int)val);
	      i += BYTES_PER_WORD;
	    }
	  while (i % BYTES_PER_LINE != 0);

	  ss_printf (ss, "\n");
	}
    }
}


/* Write to the stream a text line containing a fraction of a
   quadword. Return the address after the last one written.  */

static mem_addr
format_partial_line (str_stream *ss, mem_addr addr)
{
  if ((addr % BYTES_PER_LINE) != 0)
    {
      ss_printf (ss, "[0x%08x]		      ", addr);

      for (; (addr % BYTES_PER_LINE) != 0; addr += BYTES_PER_WORD)
	{
	  mem_word val = read_mem_word (addr);
	  ss_printf (ss, "  0x%08x", (unsigned int)val);
	}

      ss_printf (ss, "\n");
    }

  return addr;
}
