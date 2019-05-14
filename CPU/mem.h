/* SPIM S20 MIPS simulator.
   Macros for accessing memory.

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


/* A note on directions:  "Bottom" of memory is the direction of
   decreasing addresses.  "Top" is the direction of increasing addresses.*/


/* Type of contents of a memory word. */

typedef int32 /*@alt unsigned int @*/ mem_word;


/* The text segment and boundaries. */

extern instruction **text_seg;

extern bool text_modified;	/* => text segment was written */

#define TEXT_BOT ((mem_addr) 0x400000)

extern mem_addr text_top;


/* Amount to grow text segment when we run out of space for instructions. */

#define TEXT_CHUNK_SIZE	4096


/* The data segment and boundaries. */

extern mem_word *data_seg;

extern bool data_modified;	/* => a data segment was written */

extern short *data_seg_h;	/* Points to same vector as DATA_SEG */

#define BYTE_TYPE signed char


extern BYTE_TYPE *data_seg_b;	/* Ditto */

#define DATA_BOT ((mem_addr) 0x10000000)

extern mem_addr data_top;

extern mem_addr gp_midpoint;	/* Middle of $gp area */


/* The stack segment and boundaries. */

extern mem_word *stack_seg;

extern short *stack_seg_h;	/* Points to same vector as STACK_SEG */

extern BYTE_TYPE *stack_seg_b;	/* Ditto */

extern mem_addr stack_bot;

/* Exclusive, but include 4K at top of stack. */

#define STACK_TOP ((mem_addr) 0x80000000)


/* The kernel text segment and boundaries. */

extern instruction **k_text_seg;

#define K_TEXT_BOT ((mem_addr) 0x80000000)

extern mem_addr k_text_top;


/* Kernel data segment and boundaries. */

extern mem_word *k_data_seg;

extern short *k_data_seg_h;

extern BYTE_TYPE *k_data_seg_b;

#define K_DATA_BOT ((mem_addr) 0x90000000)

extern mem_addr k_data_top;


/* Memory-mapped IO area: */
#define MM_IO_BOT		((mem_addr) 0xffff0000)
#define MM_IO_TOP		((mem_addr) 0xffffffff)


/* Read from console: */
#define RECV_CTRL_ADDR		((mem_addr) 0xffff0000)
#define RECV_BUFFER_ADDR	((mem_addr) 0xffff0004)

#define RECV_READY		0x1
#define RECV_INT_ENABLE		0x2

#define RECV_INT_LEVEL		3 /* HW Interrupt 1 */


/* Write to console: */
#define TRANS_CTRL_ADDR		((mem_addr) 0xffff0008)
#define TRANS_BUFFER_ADDR	((mem_addr) 0xffff000c)

#define TRANS_READY		0x1
#define TRANS_INT_ENABLE	0x2

#define TRANS_INT_LEVEL		2 /* HW Interrupt 0 */




/* Exported functions: */

void check_memory_mapped_IO ();
void expand_data (int addl_bytes);
void expand_k_data (int addl_bytes);
void expand_stack (int addl_bytes);
void make_memory (int text_size, int data_size, int data_limit,
		  int stack_size, int stack_limit, int k_text_size,
		  int k_data_size, int k_data_limit);
void* mem_reference(mem_addr addr);
void print_mem (mem_addr addr);
instruction* read_mem_inst(mem_addr addr);
reg_word read_mem_byte(mem_addr addr);
reg_word read_mem_half(mem_addr addr);
reg_word read_mem_word(mem_addr addr);
void set_mem_inst(mem_addr addr, instruction* inst);
void set_mem_byte(mem_addr addr, reg_word value);
void set_mem_half(mem_addr addr, reg_word value);
void set_mem_word(mem_addr addr, reg_word value);
