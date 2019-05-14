/* SPIM S20 MIPS simulator.
   Description of a SPIM S20 instruction.

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


/* Represenation of the expression that produce a value for an instruction's
   immediate field.  Immediates have the form: label +/- offset. */

typedef struct immexpr
{
  int offset;			/* Offset from symbol */
  struct lab *symbol;		/* Symbolic label */
  short bits;			/* > 0 => 31..16, < 0 => 15..0 */
  bool pc_relative;		/* => offset from label in code */
} imm_expr;


/* Representation of the expression that produce an address for an
   instruction.  Address have the form: label +/- offset (register). */

typedef struct addrexpr
{
  unsigned char reg_no;		/* Register number */
  imm_expr *imm;		/* The immediate part */
} addr_expr;



/* Representation of an instruction. Store the instruction fields in an
   overlapping manner similar to the real encoding (but not identical, to
   speed decoding in C code, as opposed to hardware).. */

typedef struct inst_s
{
  short opcode;

  union
    {
      /* R-type or I-type: */
      struct
	{
	  unsigned char rs;
	  unsigned char rt;

	  union
	    {
	      short imm;

	      struct
		{
		  unsigned char rd;
		  unsigned char shamt;
		} r;
	    } r_i;
	} r_i;

      /* J-type: */
      mem_addr target;
    } r_t;

  int32 encoding;
  imm_expr *expr;
  char *source_line;
} instruction;


#define OPCODE(INST)		(INST)->opcode
#define SET_OPCODE(INST, VAL)	(INST)->opcode = (short)(VAL)


#define RS(INST)		(INST)->r_t.r_i.rs
#define SET_RS(INST, VAL)	(INST)->r_t.r_i.rs = (unsigned char)(VAL)

#define RT(INST)		(INST)->r_t.r_i.rt
#define SET_RT(INST, VAL)	(INST)->r_t.r_i.rt = (unsigned char)(VAL)

#define RD(INST)		(INST)->r_t.r_i.r_i.r.rd
#define SET_RD(INST, VAL)	(INST)->r_t.r_i.r_i.r.rd = (unsigned char)(VAL)


#define FS(INST)		RD(INST)
#define SET_FS(INST, VAL)	SET_RD(INST, VAL)

#define FT(INST)		RT(INST)
#define SET_FT(INST, VAL)	SET_RT(INST, VAL)

#define FD(INST)		SHAMT(INST)
#define SET_FD(INST, VAL)	SET_SHAMT(INST, VAL)


#define SHAMT(INST)		(INST)->r_t.r_i.r_i.r.shamt
#define SET_SHAMT(INST, VAL)	(INST)->r_t.r_i.r_i.r.shamt = (unsigned char)(VAL)

#define IMM(INST)		(INST)->r_t.r_i.r_i.imm
#define SET_IMM(INST, VAL)	(INST)->r_t.r_i.r_i.imm = (short)(VAL)


#define BASE(INST)		RS(INST)
#define SET_BASE(INST, VAL)	SET_RS(INST, VAL)

#define IOFFSET(INST)		IMM(INST)
#define SET_IOFFSET(INST, VAL)	SET_IMM(INST, VAL)
#define IDISP(INST)		(SIGN_EX (IOFFSET (INST) << 2))


#define COND(INST)		RS(INST)
#define SET_COND(INST, VAL)	SET_RS(INST, VAL)

#define CC(INST)		(RT(INST) >> 2)
#define ND(INST)		((RT(INST) & 0x2) >> 1)
#define TF(INST)		(RT(INST) & 0x1)


#define TARGET(INST)		(INST)->r_t.target
#define SET_TARGET(INST, VAL)	(INST)->r_t.target = (mem_addr)(VAL)

#define ENCODING(INST)		(INST)->encoding
#define SET_ENCODING(INST, VAL)	(INST)->encoding = (int32)(VAL)

#define EXPR(INST)		(INST)->expr
#define SET_EXPR(INST, VAL)	(INST)->expr = (imm_expr*)(VAL)

#define SOURCE(INST)		(INST)->source_line
#define SET_SOURCE(INST, VAL)	(INST)->source_line = (char *)(VAL)


#define COND_UN		0x1
#define COND_EQ		0x2
#define COND_LT		0x4
#define COND_IN		0x8

/* Minimum and maximum values that fit in instruction's imm field */
#define IMM_MIN		0xffff8000
#define IMM_MAX 	0x00007fff

#define UIMM_MIN  	(unsigned)0
#define UIMM_MAX  	((unsigned)((1<<16)-1))



/* Raise an exception! */

extern int exception_occurred;

#define RAISE_EXCEPTION(EXCODE, MISC)					\
	{								\
	raise_exception(EXCODE);					\
	MISC;								\
	}								\


#define RAISE_INTERRUPT(LEVEL)						\
	{								\
	/* Set IP (pending) bit for interrupt level. */			\
	CP0_Cause |= (1 << ((LEVEL) + 8));				\
	}								\

#define CLEAR_INTERRUPT(LEVEL)						\
	{								\
	/* Clear IP (pending) bit for interrupt level. */		\
	CP0_Cause &= ~(1 << ((LEVEL) + 8));				\
	}								\

/* Recognized exceptions: */

#define ExcCode_Int	0	/* Interrupt */
#define ExcCode_Mod	1	/* TLB modification (not implemented) */
#define ExcCode_TLBL	2	/* TLB exception (not implemented) */
#define ExcCode_TLBS	3	/* TLB exception (not implemented) */
#define ExcCode_AdEL	4	/* Address error (load/fetch) */
#define ExcCode_AdES	5	/* Address error (store) */
#define ExcCode_IBE	6	/* Bus error, instruction fetch */
#define ExcCode_DBE	7	/* Bus error, data reference */
#define ExcCode_Sys	8	/* Syscall exception */
#define ExcCode_Bp	9	/* Breakpoint exception */
#define ExcCode_RI	10	/* Reserve instruction */
#define ExcCode_CpU	11	/* Coprocessor unusable */
#define ExcCode_Ov	12	/* Arithmetic overflow */
#define ExcCode_Tr	13	/* Trap */
#define ExcCode_FPE	15	/* Floating point */
#define ExcCode_C2E	18	/* Coprocessor 2 (not impelemented) */
#define ExcCode_MDMX	22	/* MDMX unusable (not implemented) */
#define ExcCode_WATCH	23	/* Reference to Watch (not impelemented) */
#define ExcCode_MCheck	24	/* Machine check (not implemented) */
#define ExcCode_CacheErr 30	/* Cache error (not impelemented) */



/* Fields in binary representation of instructions: */

#define BIN_REG(V,O)	(((V) >> O) & 0x1f)
#define BIN_RS(V)	(BIN_REG(V, 21))
#define BIN_RT(V)	(BIN_REG(V, 16))
#define BIN_RD(V)	(BIN_REG(V, 11))
#define BIN_SA(V)	(BIN_REG(V, 6))

#define BIN_BASE(V)	(BIN_REG(V, 21))
#define BIN_FT(V)	(BIN_REG(V, 16))
#define BIN_FS(V)	(BIN_REG(V, 11))
#define BIN_FD(V)	(BIN_REG(V, 6))



/* Exported functions: */

imm_expr *addr_expr_imm (addr_expr *expr);
int addr_expr_reg (addr_expr *expr);
imm_expr *const_imm_expr (int32 value);
imm_expr *copy_imm_expr (imm_expr *old_expr);
instruction *copy_inst (instruction *inst);
mem_addr current_text_pc ();
int32 eval_imm_expr (imm_expr *expr);
void format_an_inst (str_stream *ss, instruction *inst, mem_addr addr);
void free_inst (instruction *inst);
void i_type_inst (int opcode, int rt, int rs, imm_expr *expr);
void i_type_inst_free (int opcode, int rt, int rs, imm_expr *expr);
void increment_text_pc (int delta);
imm_expr *incr_expr_offset (imm_expr *expr, int32 value);
void initialize_inst_tables ();
instruction *inst_decode (int32 value);
int32 inst_encode (instruction *inst);
bool inst_is_breakpoint (mem_addr addr);
void j_type_inst (int opcode, imm_expr *target);
void k_text_begins_at_point (mem_addr addr);
imm_expr *lower_bits_of_expr (imm_expr *old_expr);
addr_expr *make_addr_expr (int offs, char *sym, int reg_no);
imm_expr *make_imm_expr (int offs, char *sym, bool is_pc_relative);
bool opcode_is_branch (int opcode);
bool opcode_is_nullified_branch (int opcode);
bool opcode_is_true_branch (int opcode);
bool opcode_is_jump (int opcode);
bool opcode_is_load_store (int opcode);
void print_inst (mem_addr addr);
char* inst_to_string (mem_addr addr);
void r_co_type_inst (int opcode, int fd, int fs, int ft);
void r_cond_type_inst (int opcode, int fs, int ft, int cc);
void r_sh_type_inst (int opcode, int rd, int rt, int shamt);
void r_type_inst (int opcode, int rd, int rs, int rt);
void raise_exception(int excode);
instruction *set_breakpoint (mem_addr addr);
void store_instruction (instruction *inst);
void text_begins_at_point (mem_addr addr);
imm_expr *upper_bits_of_expr (imm_expr *old_expr);
void user_kernel_text_segment (bool to_kernel);
bool is_zero_imm (imm_expr *expr);
