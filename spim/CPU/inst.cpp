/* SPIM S20 MIPS simulator.
   Code to build assembly instructions and resolve symbolic labels.

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


#include <stdio.h>
#include <string.h>

#include "spim.h"
#include "string-stream.h"
#include "spim-utils.h"
#include "inst.h"
#include "reg.h"
#include "mem.h"
#include "sym-tbl.h"
#include "parser.h"
#include "scanner.h"
#include "parser_yacc.h"
#include "data.h"


/* Local functions: */

static int compare_pair_value (name_val_val *p1, name_val_val *p2);
static void format_imm_expr (str_stream *ss, imm_expr *expr, int base_reg);
static void i_type_inst_full_word (int opcode, int rt, int rs, imm_expr *expr,
				   int value_known, int32 value);
static void inst_cmp (instruction *inst1, instruction *inst2);
static instruction *make_r_type_inst (int opcode, int rd, int rs, int rt);
static instruction *mk_i_inst (int32 value, int opcode, int rs, int rt, int offset);
static instruction *mk_j_inst (int32, int opcode, int target);
static instruction *mk_r_inst (int32, int opcode, int rs, int rt, int rd, int shamt);
static void produce_immediate (imm_expr *expr, int rt, int value_known, int32 value);
static void sort_a_opcode_table ();
static void sort_i_opcode_table ();
static void sort_name_table ();


/* Local variables: */

/* True means store instructions in kernel, not user, text segment */

static bool in_kernel = 0;

/* Instruction used as breakpoint by SPIM: */

static instruction *break_inst = NULL;


/* Locations for next instruction in user and kernel text segments */

static mem_addr next_text_pc;

static mem_addr next_k_text_pc;


#define INST_PC (in_kernel ? next_k_text_pc : next_text_pc)



/* Set ADDRESS at which the next instruction is stored. */

void
text_begins_at_point (mem_addr addr)
{
  next_text_pc = addr;
}


void
k_text_begins_at_point (mem_addr addr)
{
  next_k_text_pc = addr;
}


/* Set the location (in user or kernel text space) for the next instruction. */

void
set_text_pc (mem_addr addr)
{
  if (in_kernel)
    next_k_text_pc = addr;
  else
    next_text_pc = addr;
}


/* Return address for next instruction, in appropriate text segment. */

mem_addr
current_text_pc ()
{
  return (INST_PC);
}


/* Increment the current text segement PC. */

void
increment_text_pc (int delta)
{
  if (in_kernel)
    {
      next_k_text_pc += delta;
      if (k_text_top <= next_k_text_pc)
        run_error("Can't expand kernel text segment\n");
    }
  else
    {
      next_text_pc += delta;
      if (text_top <= next_text_pc)
        run_error("Can't expand text segment\n");
    }
}


/* If FLAG is true, next instruction goes to kernel text segment,
   otherwise it goes to user segment. */

void
user_kernel_text_segment (bool to_kernel)
{
  in_kernel = to_kernel;
}


/* Store an INSTRUCTION in memory at the next location. */

void
store_instruction (instruction *inst)
{
  if (data_dir)
    {
      store_word (inst_encode (inst));
      free_inst (inst);
    }
  else if (text_dir)
    {
      exception_occurred = 0;
      set_mem_inst (INST_PC, inst);
      if (exception_occurred)
	error ("Invalid address (0x%08x) for instruction\n", INST_PC);
      else
	increment_text_pc (BYTES_PER_WORD);
      if (inst != NULL)
	{
	  SET_SOURCE (inst, source_line ());
	  if (ENCODING (inst) == 0)
	    SET_ENCODING (inst, inst_encode (inst));
	}
    }
}



void
i_type_inst_free (int opcode, int rt, int rs, imm_expr *expr)
{
  i_type_inst (opcode, rt, rs, expr);
  free (expr);
}


/* Produce an immediate instruction with the OPCODE, RT, RS, and IMM
   fields.  NB, because the immediate value may not fit in the field,
   this routine may produce more than one instruction.	On the bare
   machine, we resolve symbolic address, but they better produce values
   that fit into instruction's immediate field. */

void
i_type_inst (int opcode, int rt, int rs, imm_expr *expr)
{
  instruction *inst = (instruction *) zmalloc (sizeof (instruction));

  SET_OPCODE (inst, opcode);
  SET_RS (inst, rs);
  SET_RT (inst, rt);
  SET_EXPR (inst, copy_imm_expr (expr));
  if (expr->symbol == NULL || SYMBOL_IS_DEFINED (expr->symbol))
    {
      /* Evaluate the instruction's expression. */
      int32 value = eval_imm_expr (expr);

      if (!bare_machine
	  && (((opcode == Y_ADDI_OP
		|| opcode == Y_ADDIU_OP
		|| opcode == Y_SLTI_OP
		|| opcode == Y_SLTIU_OP
                || opcode == Y_TEQI_OP
                || opcode == Y_TGEI_OP
                || opcode == Y_TGEIU_OP
                || opcode == Y_TLTI_OP
                || opcode == Y_TLTIU_OP
                || opcode == Y_TNEI_OP
                || (opcode_is_load_store (opcode) && expr->bits == 0))
               // Sign-extended immediate values:
	       ? ((value & 0xffff8000) != 0 && (value & 0xffff8000) != 0xffff8000)
               // Not sign-extended:
	       : (value & 0xffff0000) != 0)))
	{
         // Non-immediate value
	  free_inst (inst);
	  i_type_inst_full_word (opcode, rt, rs, expr, 1, value);
	  return;
	}
      else
	resolve_a_label (expr->symbol, inst);
    }
  else if (bare_machine || expr->bits != 0)
    /* Don't know expression's value, but only needed upper/lower 16-bits
       anyways. */
    record_inst_uses_symbol (inst, expr->symbol);
  else
    {
      /* Don't know the expressions's value and want all of its bits,
	 so assume that it will not produce a small result and generate
	 sequence for 32 bit value. */
      free_inst (inst);

      i_type_inst_full_word (opcode, rt, rs, expr, 0, 0);
      return;
    }

  store_instruction (inst);
}


/* The immediate value for an instruction will (or may) not fit in 16 bits.
   Build the value from its piece with separate instructions. */

static void
i_type_inst_full_word (int opcode, int rt, int rs, imm_expr *expr,
		       int value_known, int32 value)
{
  if (opcode_is_load_store (opcode))
    {
      int32 offset;

      if (expr->symbol != NULL
	  && expr->symbol->gp_flag
	  && rs == 0
	  && (int32)IMM_MIN <= (offset = expr->symbol->addr + expr->offset)
	  && offset <= (int32)IMM_MAX)
	{
	  i_type_inst_free (opcode, rt, REG_GP, make_imm_expr (offset, NULL, false));
	}
      else if (value_known)
	{
	  int low, high;

	  high = (value >> 16) & 0xffff;
	  low = value & 0xffff;

	  if (!(high == 0 && !(low & 0x8000)) &&
	      !(high == 0xffff && (low & 0x8000)))
	    {
	      /* Some of high 16 bits are non-zero */
	      if (low & 0x8000)
		{
		  /* Adjust high 16, since load sign-extends low 16*/
		  high += 1;
		}

	      i_type_inst_free (Y_LUI_OP, 1, 0, const_imm_expr (high));
	      if (rs != 0)	/* Base register */
		{
		r_type_inst (Y_ADDU_OP, 1, 1, rs);
		}
	      i_type_inst_free (opcode, rt, 1, lower_bits_of_expr (const_imm_expr (low)));
	    }
	  else
	    {
	      /* Special case, sign-extension of low 16 bits sets high to 0xffff */
	      i_type_inst_free (opcode, rt, rs, const_imm_expr (low));
	    }
	}
      else
	{
	  /* Use $at */
	  /* Need to adjust if lower bits are negative */
	  i_type_inst_free (Y_LUI_OP, 1, 0, upper_bits_of_expr (expr));
	  if (rs != 0)		/* Base register */
	    {
	    r_type_inst (Y_ADDU_OP, 1, 1, rs);
	    }
	  i_type_inst_free (opcode, rt, 1, lower_bits_of_expr (expr));
	}
    }
  else if (opcode_is_branch (opcode))
    {
      /* This only allows branches +/- 32K, which is not correct! */
      i_type_inst_free (opcode, rt, rs, lower_bits_of_expr (expr));
    }
  else
    /* Computation instruction */
    {
      int offset;

      if (expr->symbol != NULL
	  && expr->symbol->gp_flag && rs == 0
	  && (int32)IMM_MIN <= (offset = expr->symbol->addr + expr->offset)
	  && offset <= (int32)IMM_MAX)
	{
	i_type_inst_free ((opcode == Y_LUI_OP ? Y_ADDIU_OP : opcode),
			  rt, REG_GP, make_imm_expr (offset, NULL, false));
	}
      else
	{
	  /* Use $at */
	  if ((opcode == Y_ORI_OP
	       || opcode == Y_ADDI_OP
	       || opcode == Y_ADDIU_OP
	       || opcode == Y_LUI_OP)
	      && rs == 0)
	    {
	      produce_immediate(expr, rt, value_known, value);
	    }
	  else
	    {
	      produce_immediate(expr, 1, value_known, value);
	      r_type_inst (imm_op_to_op (opcode), rt, rs, 1);
	    }
	}
    }
}


static void
produce_immediate (imm_expr *expr, int rt, int value_known, int32 value)
{
  if (value_known && (value & 0xffff) == 0)
    {
      i_type_inst_free (Y_LUI_OP, rt, 0, upper_bits_of_expr (expr));
    }
  else if (value_known && (value & 0xffff0000) == 0)
    {
      i_type_inst_free (Y_ORI_OP, rt, 0, lower_bits_of_expr (expr));
    }
  else
    {
      i_type_inst_free (Y_LUI_OP, 1, 0, upper_bits_of_expr (expr));
      i_type_inst_free (Y_ORI_OP, rt, 1, lower_bits_of_expr(expr));
    }
}


/* Return a jump-type instruction with the given OPCODE and TARGET
   fields. NB, even the immediate value may not fit in the field, this
   routine will not produce more than one instruction. */

void
j_type_inst (int opcode, imm_expr *target)
{
  instruction *inst = (instruction *) zmalloc (sizeof (instruction));

  SET_OPCODE(inst, opcode);
  target->offset = 0;		/* Not PC relative */
  target->pc_relative = false;
  SET_EXPR (inst, copy_imm_expr (target));
  if (target->symbol == NULL || SYMBOL_IS_DEFINED (target->symbol))
    resolve_a_label (target->symbol, inst);
  else
    record_inst_uses_symbol (inst, target->symbol);
  store_instruction (inst);
}


/* Return a register-type instruction with the given OPCODE, RD, RS, and RT
   fields. */

static instruction *
make_r_type_inst (int opcode, int rd, int rs, int rt)
{
  instruction *inst = (instruction *) zmalloc (sizeof (instruction));

  SET_OPCODE(inst, opcode);
  SET_RS(inst, rs);
  SET_RT(inst, rt);
  SET_RD(inst, rd);
  SHAMT(inst) = 0;
  return (inst);
}


/* Return a register-type instruction with the given OPCODE, RD, RS, and RT
   fields. */

void
r_type_inst (int opcode, int rd, int rs, int rt)
{
  store_instruction (make_r_type_inst (opcode, rd, rs, rt));
}


/* Return a register-type instruction with the given OPCODE, FD, FS, and FT
   fields. */

void
r_co_type_inst (int opcode, int fd, int fs, int ft)
{
  instruction *inst = make_r_type_inst (opcode, fs, 0, ft);
  SET_FD (inst, fd);
  store_instruction (inst);
}


/* Return a register-shift instruction with the given OPCODE, RD, RT, and
   SHAMT fields.*/

void
r_sh_type_inst (int opcode, int rd, int rt, int shamt)
{
  instruction *inst = make_r_type_inst (opcode, rd, 0, rt);
  SET_SHAMT(inst, shamt & 0x1f);
  store_instruction (inst);
}


/* Return a floating-point compare instruction with the given OPCODE,
   FS, FT, and CC fields.*/

void
r_cond_type_inst (int opcode, int fs, int ft, int cc)
{
  instruction *inst = make_r_type_inst (opcode, fs, 0, ft);
  SET_FD(inst, cc << 2);
  switch (opcode)
    {
    case Y_C_EQ_D_OP:
    case Y_C_EQ_S_OP:
      {
	SET_COND(inst, COND_EQ);
	break;
      }

    case Y_C_LE_D_OP:
    case Y_C_LE_S_OP:
      {
	SET_COND(inst, COND_IN | COND_LT | COND_EQ);
	break;
      }

    case Y_C_LT_D_OP:
    case Y_C_LT_S_OP:
      {
	SET_COND(inst, COND_IN | COND_LT);
	break;
      }

    case Y_C_NGE_D_OP:
    case Y_C_NGE_S_OP:
      {
	SET_COND(inst, COND_IN | COND_LT | COND_UN);
	break;
      }

    case Y_C_NGLE_D_OP:
    case Y_C_NGLE_S_OP:
      {
	SET_COND(inst, COND_IN | COND_UN);
	break;
      }

    case Y_C_NGL_D_OP:
    case Y_C_NGL_S_OP:
      {
	SET_COND(inst, COND_IN | COND_EQ | COND_UN);
	break;
      }

    case Y_C_NGT_D_OP:
    case Y_C_NGT_S_OP:
      {
	SET_COND(inst, COND_IN | COND_LT | COND_EQ | COND_UN);
	break;
      }

    case Y_C_OLT_D_OP:
    case Y_C_OLT_S_OP:
      {
	SET_COND(inst, COND_LT);
	break;
      }

    case Y_C_OLE_D_OP:
    case Y_C_OLE_S_OP:
      {
	SET_COND(inst, COND_LT | COND_EQ);
	break;
      }

    case Y_C_SEQ_D_OP:
    case Y_C_SEQ_S_OP:
      {
	SET_COND(inst, COND_IN | COND_EQ);
	break;
      }

    case Y_C_SF_D_OP:
    case Y_C_SF_S_OP:
      {
	SET_COND(inst, COND_IN);
	break;
      }

    case Y_C_F_D_OP:
    case Y_C_F_S_OP:
      {
	SET_COND(inst, 0);
	break;
      }

    case Y_C_UEQ_D_OP:
    case Y_C_UEQ_S_OP:
      {
	SET_COND(inst, COND_EQ | COND_UN);
	break;
      }

    case Y_C_ULT_D_OP:
    case Y_C_ULT_S_OP:
      {
	SET_COND(inst, COND_LT | COND_UN);
	break;
      }

    case Y_C_ULE_D_OP:
    case Y_C_ULE_S_OP:
      {
	SET_COND(inst, COND_LT | COND_EQ | COND_UN);
	break;
      }

    case Y_C_UN_D_OP:
    case Y_C_UN_S_OP:
      {
	SET_COND(inst, COND_UN);
	break;
      }
    }
  store_instruction (inst);
}


/* Make and return a deep copy of INST. */

instruction *
copy_inst (instruction *inst)
{
  instruction *new_inst = (instruction *) xmalloc (sizeof (instruction));

  *new_inst = *inst;
  /*memcpy ((void*)new_inst, (void*)inst , sizeof (instruction));*/
  SET_EXPR (new_inst, copy_imm_expr (EXPR (inst)));
  return (new_inst);
}


void
free_inst (instruction *inst)
{
  if (inst != break_inst)
    /* Don't free the breakpoint insructions since we only have one. */
    {
      if (EXPR (inst))
	free (EXPR (inst));
      free (inst);
    }
}



/* Maintain a table mapping from opcode to instruction name and
   instruction type.

   Table must be sorted before first use since its entries are
   alphabetical on name, not ordered by opcode. */


/* Sort all instruction table before first use. */

void
initialize_inst_tables ()
{
	sort_name_table ();
	sort_i_opcode_table ();
	sort_a_opcode_table ();
}


/* Map from opcode -> name/type. */

static name_val_val name_tbl [] = {
#undef OP
#define OP(NAME, OPCODE, TYPE, R_OPCODE) {NAME, OPCODE, TYPE},
#include "op.h"
};


/* Sort the opcode table on their key (the opcode value). */

static void
sort_name_table ()
{
  qsort (name_tbl,
	 sizeof (name_tbl) / sizeof (name_val_val),
	 sizeof (name_val_val),
	 (QSORT_FUNC) compare_pair_value);
}


/* Compare the VALUE1 field of two NAME_VAL_VAL entries in the format
   required by qsort. */

static int
compare_pair_value (name_val_val *p1, name_val_val *p2)
{
  if (p1->value1 < p2->value1)
    return (-1);
  else if (p1->value1 > p2->value1)
    return (1);
  else
    return (0);
}


/* Print the instruction stored at the memory ADDRESS. */

void
print_inst (mem_addr addr)
{
  char* inst_str = inst_to_string (addr);
  write_output (message_out, inst_str);
  free (inst_str);
}


char*
inst_to_string(mem_addr addr)
{
  str_stream ss;
  instruction *inst;

  exception_occurred = 0;
  inst = read_mem_inst (addr);

  if (exception_occurred)
    {
      error ("Can't print instruction not in text segment (0x%08x)\n", addr);
      return "";
    }

  ss_init (&ss);
  format_an_inst (&ss, inst, addr);
  return ss_to_string (&ss);
}


void
format_an_inst (str_stream *ss, instruction *inst, mem_addr addr)
{
  name_val_val *entry;
  int line_start = ss_length (ss);

  if (inst_is_breakpoint (addr))
    {
      delete_breakpoint (addr);
      ss_printf (ss, "*");
      format_an_inst (ss, read_mem_inst (addr), addr);
      add_breakpoint (addr);
      return;
    }

  ss_printf (ss, "[0x%08x]\t", addr);
  if (inst == NULL)
    {
      ss_printf (ss, "<none>\n");
      return;
    }

  entry = map_int_to_name_val_val (name_tbl,
				   sizeof (name_tbl) / sizeof (name_val_val),
				   OPCODE (inst));
  if (entry == NULL)
    {
      ss_printf (ss, "<unknown instruction %d>\n", OPCODE (inst));
      return;
    }

  ss_printf (ss, "0x%08x  %s", (uint32)ENCODING (inst), entry->name);
  switch (entry->value2)
    {
    case BC_TYPE_INST:
      ss_printf (ss, "%d %d", CC (inst), IDISP (inst));
      break;

    case B1_TYPE_INST:
      ss_printf (ss, " $%d %d", RS (inst), IDISP (inst));
      break;

    case I1s_TYPE_INST:
      ss_printf (ss, " $%d, %d", RS (inst), IMM (inst));
      break;

    case I1t_TYPE_INST:
      ss_printf (ss, " $%d, %d", RT (inst), IMM (inst));
      break;

    case I2_TYPE_INST:
      ss_printf (ss, " $%d, $%d, %d", RT (inst), RS (inst), IMM (inst));
      break;

    case B2_TYPE_INST:
      ss_printf (ss, " $%d, $%d, %d", RS (inst), RT (inst), IDISP (inst));
      break;

    case I2a_TYPE_INST:
      ss_printf (ss, " $%d, %d($%d)", RT (inst), IMM (inst), BASE (inst));
      break;

    case R1s_TYPE_INST:
      ss_printf (ss, " $%d", RS (inst));
      break;

    case R1d_TYPE_INST:
      ss_printf (ss, " $%d", RD (inst));
      break;

    case R2td_TYPE_INST:
      ss_printf (ss, " $%d, $%d", RT (inst), RD (inst));
      break;

    case R2st_TYPE_INST:
      ss_printf (ss, " $%d, $%d", RS (inst), RT (inst));
      break;

    case R2ds_TYPE_INST:
      ss_printf (ss, " $%d, $%d", RD (inst), RS (inst));
      break;

    case R2sh_TYPE_INST:
      if (ENCODING (inst) == 0)
	{
	  ss_erase (ss, 3);	/* zap sll */
	  ss_printf (ss, "nop");
	}
      else
	ss_printf (ss, " $%d, $%d, %d", RD (inst), RT (inst), SHAMT (inst));
      break;

    case R3_TYPE_INST:
      ss_printf (ss, " $%d, $%d, $%d", RD (inst), RS (inst), RT (inst));
      break;

    case R3sh_TYPE_INST:
      ss_printf (ss, " $%d, $%d, $%d", RD (inst), RT (inst), RS (inst));
      break;

    case FP_I2a_TYPE_INST:
      ss_printf (ss, " $f%d, %d($%d)", FT (inst), IMM (inst), BASE (inst));
      break;

    case FP_R2ds_TYPE_INST:
      ss_printf (ss, " $f%d, $f%d", FD (inst), FS (inst));
      break;

    case FP_R2ts_TYPE_INST:
      ss_printf (ss, " $%d, $f%d", RT (inst), FS (inst));
      break;

    case FP_CMP_TYPE_INST:
      if (FD (inst) == 0)
        ss_printf (ss, " $f%d, $f%d", FS (inst), FT (inst));
      else
        ss_printf (ss, " %d, $f%d, $f%d", FD (inst) >> 2, FS (inst), FT (inst));
      break;

    case FP_R3_TYPE_INST:
      ss_printf (ss, " $f%d, $f%d, $f%d", FD (inst), FS (inst), FT (inst));
      break;

    case MOVC_TYPE_INST:
	ss_printf (ss, " $%d, $%d, %d", RD (inst), RS (inst), RT (inst) >> 2);
      break;

    case FP_MOVC_TYPE_INST:
	ss_printf (ss, " $f%d, $f%d, %d", FD (inst), FS (inst), CC (inst));
      break;

    case J_TYPE_INST:
      ss_printf (ss, " 0x%08x", TARGET (inst) << 2);
      break;

    case NOARG_TYPE_INST:
      break;

    default:
      fatal_error ("Unknown instruction type in print_inst\n");
    }

  if (EXPR (inst) != NULL && EXPR (inst)->symbol != NULL)
    {
      ss_printf (ss, " [");
      if (opcode_is_load_store (OPCODE (inst)))
	format_imm_expr (ss, EXPR (inst), BASE (inst));
      else
	format_imm_expr (ss, EXPR (inst), -1);
      ss_printf (ss, "]");
    }

  if (SOURCE (inst) != NULL)
    {
      /* Comment is source line text of current line. */
      int gap_length = 57 - (ss_length (ss) - line_start);
      for ( ; 0 < gap_length; gap_length -= 1)
	{
	  ss_printf (ss, " ");
	}

      ss_printf (ss, "; ");
      ss_printf (ss, "%s", SOURCE (inst));
    }

  ss_printf (ss, "\n");
}



/* Return true if SPIM OPCODE (e.g. Y_...) represents a conditional
   branch. */

bool
opcode_is_branch (int opcode)
{
  switch (opcode)
    {
    case Y_BC1F_OP:
    case Y_BC1FL_OP:
    case Y_BC1T_OP:
    case Y_BC1TL_OP:
    case Y_BC2F_OP:
    case Y_BC2FL_OP:
    case Y_BC2T_OP:
    case Y_BC2TL_OP:
    case Y_BEQ_OP:
    case Y_BEQL_OP:
    case Y_BEQZ_POP:
    case Y_BGE_POP:
    case Y_BGEU_POP:
    case Y_BGEZ_OP:
    case Y_BGEZAL_OP:
    case Y_BGEZALL_OP:
    case Y_BGEZL_OP:
    case Y_BGT_POP:
    case Y_BGTU_POP:
    case Y_BGTZ_OP:
    case Y_BGTZL_OP:
    case Y_BLE_POP:
    case Y_BLEU_POP:
    case Y_BLEZ_OP:
    case Y_BLEZL_OP:
    case Y_BLT_POP:
    case Y_BLTU_POP:
    case Y_BLTZ_OP:
    case Y_BLTZAL_OP:
    case Y_BLTZALL_OP:
    case Y_BLTZL_OP:
    case Y_BNE_OP:
    case Y_BNEL_OP:
    case Y_BNEZ_POP:
      return true;

    default:
      return false;
    }
}


/* Return true if SPIM OPCODE represents a nullified (e.g., Y_...L_OP)
   conditional branch. */

bool
opcode_is_nullified_branch (int opcode)
{
  switch (opcode)
    {
    case Y_BC1FL_OP:
    case Y_BC1TL_OP:
    case Y_BC2FL_OP:
    case Y_BC2TL_OP:
    case Y_BEQL_OP:
    case Y_BGEZALL_OP:
    case Y_BGEZL_OP:
    case Y_BGTZL_OP:
    case Y_BLEZL_OP:
    case Y_BLTZALL_OP:
    case Y_BLTZL_OP:
    case Y_BNEL_OP:
      return true;

    default:
      return false;
    }
}


/* Return true if SPIM OPCODE (e.g. Y_...) represents a conditional
   branch on a true condition. */

bool
opcode_is_true_branch (int opcode)
{
  switch (opcode)
    {
    case Y_BC1T_OP:
    case Y_BC1TL_OP:
    case Y_BC2T_OP:
    case Y_BC2TL_OP:
      return true;

    default:
      return false;
    }
}


/* Return true if SPIM OPCODE (e.g. Y_...) is a direct unconditional
   branch (jump). */

bool
opcode_is_jump (int opcode)
{
  switch (opcode)
    {
    case Y_J_OP:
    case Y_JAL_OP:
      return true;

    default:
      return false;
    }
}

/* Return true if SPIM OPCODE (e.g. Y_...) is a load or store. */

bool
opcode_is_load_store (int opcode)
{
  switch (opcode)
    {
    case Y_LB_OP:
    case Y_LBU_OP:
    case Y_LH_OP:
    case Y_LHU_OP:
    case Y_LL_OP:
    case Y_LDC1_OP:
    case Y_LDC2_OP:
    case Y_LW_OP:
    case Y_LWC1_OP:
    case Y_LWC2_OP:
    case Y_LWL_OP:
    case Y_LWR_OP:
    case Y_SB_OP:
    case Y_SC_OP:
    case Y_SH_OP:
    case Y_SDC1_OP:
    case Y_SDC2_OP:
    case Y_SW_OP:
    case Y_SWC1_OP:
    case Y_SWC2_OP:
    case Y_SWL_OP:
    case Y_SWR_OP:
      return true;

    default:
      return false;
    }
}


/* Return true if a breakpoint is set at ADDR. */

bool
inst_is_breakpoint (mem_addr addr)
{
  if (break_inst == NULL)
    break_inst = make_r_type_inst (Y_BREAK_OP, 1, 0, 0);

  return (read_mem_inst (addr) == break_inst);
}


/* Set a breakpoint at ADDR and return the old instruction.  If the
   breakpoint cannot be set, return NULL. */

instruction *
set_breakpoint (mem_addr addr)
{
  instruction *old_inst;

  if (break_inst == NULL)
    break_inst = make_r_type_inst (Y_BREAK_OP, 1, 0, 0);

  exception_occurred = 0;
  old_inst = read_mem_inst (addr);
  if (old_inst == break_inst)
    return (NULL);

  set_mem_inst (addr, break_inst);
  if (exception_occurred)
    return (NULL);
  else
    return (old_inst);
}



/* An immediate expression has the form: SYMBOL +/- IOFFSET, where either
   part may be omitted. */

/* Make and return a new immediate expression */

imm_expr *
make_imm_expr (int offs, char *sym, bool is_pc_relative)
{
  imm_expr *expr = (imm_expr *) xmalloc (sizeof (imm_expr));

  expr->offset = offs;
  expr->bits = 0;
  expr->pc_relative = is_pc_relative;
  if (sym != NULL)
    expr->symbol = lookup_label (sym);
  else
    expr->symbol = NULL;
  return (expr);
}


/* Return a shallow copy of the EXPRESSION. */

imm_expr *
copy_imm_expr (imm_expr *old_expr)
{
  imm_expr *expr = (imm_expr *) xmalloc (sizeof (imm_expr));

  *expr = *old_expr;
  /*memcpy ((void*)expr, (void*)old_expr, sizeof (imm_expr));*/
  return (expr);
}


/* Return a shallow copy of an EXPRESSION that only uses the upper
   sixteen bits of the expression's value. */

imm_expr *
upper_bits_of_expr (imm_expr *old_expr)
{
  imm_expr *expr = copy_imm_expr (old_expr);

  expr->bits = 1;
  return (expr);
}


/* Return a shallow copy of the EXPRESSION that only uses the lower
   sixteen bits of the expression's value. */

imm_expr *
lower_bits_of_expr (imm_expr *old_expr)
{
  imm_expr *expr = copy_imm_expr (old_expr);

  expr->bits = -1;
  return (expr);
}


/* Return an instruction expression for a constant VALUE. */

imm_expr *
const_imm_expr (int32 value)
{
  return (make_imm_expr (value, NULL, false));
}


/* Return a shallow copy of the EXPRESSION with the offset field
   incremented by the given amount. */

imm_expr *
incr_expr_offset (imm_expr *expr, int32 value)
{
  imm_expr *new_expr = copy_imm_expr (expr);

  new_expr->offset += value;
  return (new_expr);
}


/* Return the value of the EXPRESSION. */

int32
eval_imm_expr (imm_expr *expr)
{
  int32 value;

  if (expr->symbol == NULL)
    value = expr->offset;
  else if (SYMBOL_IS_DEFINED (expr->symbol))
    {
      value = expr->offset + expr->symbol->addr;
    }
  else
    {
      error ("Evaluated undefined symbol: %s\n", expr->symbol->name);
      value = 0;
    }
  if (expr->bits > 0)
    return ((value >> 16) & 0xffff);  /* Use upper bits of result */
  else if (expr->bits < 0)
    return (value & 0xffff);	      /* Use lower bits */
  else
    return (value);
}


/* Print the EXPRESSION. */

static void
format_imm_expr (str_stream *ss, imm_expr *expr, int base_reg)
{
  if (expr->symbol != NULL)
    {
      ss_printf (ss, "%s", expr->symbol->name);
    }

  if (expr->pc_relative)
    ss_printf (ss, "-0x%08x", (unsigned int)-expr->offset);
  else if (expr->offset < -10)
    ss_printf (ss, "-%d (-0x%08x)", -expr->offset, (unsigned int)-expr->offset);
  else if (expr->offset > 10)
    ss_printf (ss, "+%d (0x%08x)", expr->offset, (unsigned int)expr->offset);

  if (base_reg != -1 && expr->symbol != NULL &&
      (expr->offset > 10 || expr->offset < -10))
    {
      if (expr->offset == 0 && base_reg != 0)
	ss_printf (ss, "+0");

      if (expr->offset != 0 || base_reg != 0)
	ss_printf (ss, "($%d)", base_reg);
    }
}


/* Return true if the EXPRESSION is a constant 0. */

bool
is_zero_imm (imm_expr *expr)
{
  return (expr->offset == 0 && expr->symbol == NULL);
}



/* Return an address expression of the form SYMBOL +/- IOFFSET (REGISTER).
   Any of the three parts may be omitted. */

addr_expr *
make_addr_expr (int offs, char *sym, int reg_no)
{
  addr_expr *expr = (addr_expr *) xmalloc (sizeof (addr_expr));
  label *lab;

  if (reg_no == 0 && sym != NULL && (lab = lookup_label (sym))->gp_flag)
    {
      expr->reg_no = REG_GP;
      expr->imm = make_imm_expr (offs + lab->addr - gp_midpoint, NULL, false);
    }
  else
    {
      expr->reg_no = (unsigned char)reg_no;
      expr->imm = make_imm_expr (offs, (sym ? str_copy (sym) : sym), false);
    }
  return (expr);
}


imm_expr *
addr_expr_imm (addr_expr *expr)
{
  return (expr->imm);
}


int
addr_expr_reg (addr_expr *expr)
{
  return (expr->reg_no);
}



/* Map between a SPIM instruction and the binary representation of the
   instruction. */


/* Maintain a table mapping from internal opcode (i_opcode) to actual
   opcode (a_opcode).  Table must be sorted before first use since its
   entries are alphabetical on name, not ordered by opcode. */


/* Map from internal opcode -> real opcode */

static name_val_val i_opcode_tbl [] = {
#undef OP
#define OP(NAME, I_OPCODE, TYPE, A_OPCODE) {NAME, I_OPCODE, (int)A_OPCODE},
#include "op.h"
};


/* Sort the opcode table on their key (the interal opcode value). */

static void
sort_i_opcode_table ()
{
  qsort (i_opcode_tbl,
	 sizeof (i_opcode_tbl) / sizeof (name_val_val),
	 sizeof (name_val_val),
	 (QSORT_FUNC) compare_pair_value);
}


#define REGS(R,O) (((R) & 0x1f) << O)


int32
inst_encode (instruction *inst)
{
  int32 a_opcode = 0;
  name_val_val *entry;

  if (inst == NULL)
    return (0);

  entry = map_int_to_name_val_val (i_opcode_tbl,
				sizeof (i_opcode_tbl) / sizeof (name_val_val),
				OPCODE (inst));
  if (entry == NULL)
    return 0;

  a_opcode = entry->value2;
  entry = map_int_to_name_val_val (name_tbl,
				sizeof (name_tbl) / sizeof (name_val_val),
				OPCODE (inst));

  switch (entry->value2)
    {
    case BC_TYPE_INST:
      return (a_opcode
	      | REGS (CC (inst) << 2, 16)
	      | (IOFFSET (inst) & 0xffff));

    case B1_TYPE_INST:
      return (a_opcode
	      | REGS (RS (inst), 21)
	      | (IOFFSET (inst) & 0xffff));

    case I1s_TYPE_INST:
      return (a_opcode
	      | REGS (RS (inst), 21)
	      | (IMM (inst) & 0xffff));

    case I1t_TYPE_INST:
      return (a_opcode
	      | REGS (RS (inst), 21)
	      | REGS (RT (inst), 16)
	      | (IMM (inst) & 0xffff));

    case I2_TYPE_INST:
    case B2_TYPE_INST:
      return (a_opcode
	      | REGS (RS (inst), 21)
	      | REGS (RT (inst), 16)
	      | (IMM (inst) & 0xffff));

    case I2a_TYPE_INST:
      return (a_opcode
	      | REGS (BASE (inst), 21)
	      | REGS (RT (inst), 16)
	      | (IOFFSET (inst) & 0xffff));

    case R1s_TYPE_INST:
      return (a_opcode
	      | REGS (RS (inst), 21));

    case R1d_TYPE_INST:
      return (a_opcode
	      | REGS (RD (inst), 11));

    case R2td_TYPE_INST:
      return (a_opcode
	      | REGS (RT (inst), 16)
	      | REGS (RD (inst), 11));

    case R2st_TYPE_INST:
      return (a_opcode
	      | REGS (RS (inst), 21)
	      | REGS (RT (inst), 16));

    case R2ds_TYPE_INST:
      return (a_opcode
	      | REGS (RS (inst), 21)
	      | REGS (RD (inst), 11));

    case R2sh_TYPE_INST:
      return (a_opcode
	      | REGS (RT (inst), 16)
	      | REGS (RD (inst), 11)
	      | REGS (SHAMT (inst), 6));

    case R3_TYPE_INST:
      return (a_opcode
	      | REGS (RS (inst), 21)
	      | REGS (RT (inst), 16)
	      | REGS (RD (inst), 11));

    case R3sh_TYPE_INST:
      return (a_opcode
	      | REGS (RS (inst), 21)
	      | REGS (RT (inst), 16)
	      | REGS (RD (inst), 11));

    case FP_I2a_TYPE_INST:
      return (a_opcode
	      | REGS (BASE (inst), 21)
	      | REGS (RT (inst), 16)
	      | (IOFFSET (inst) & 0xffff));

    case FP_R2ds_TYPE_INST:
      return (a_opcode
	      | REGS (FS (inst), 11)
	      | REGS (FD (inst), 6));

    case FP_R2ts_TYPE_INST:
      return (a_opcode
	      | REGS (RT (inst), 16)
	      | REGS (FS (inst), 11));

    case FP_CMP_TYPE_INST:
      return (a_opcode
	      | REGS (FT (inst), 16)
	      | REGS (FS (inst), 11)
              | REGS (FD (inst), 6)
	      | COND (inst));

    case FP_R3_TYPE_INST:
      return (a_opcode
	      | REGS (FT (inst), 16)
	      | REGS (FS (inst), 11)
	      | REGS (FD (inst), 6));

    case MOVC_TYPE_INST:
      return (a_opcode
	      | REGS (RS (inst), 21)
	      | REGS (RT (inst), 16)
	      | REGS (RD (inst), 11));

    case FP_MOVC_TYPE_INST:
      return (a_opcode
	      | REGS (CC (inst), 18)
	      | REGS (FS (inst), 11)
	      | REGS (FD (inst), 6));

    case J_TYPE_INST:
      return (a_opcode
	      | TARGET (inst));

    case NOARG_TYPE_INST:
      return (a_opcode);

    default:
      fatal_error ("Unknown instruction type in inst_encoding\n");
      return (0);		/* Not reached */
    }
}


/* Maintain a table mapping from actual opcode to interal opcode.
   Table must be sorted before first use since its entries are
   alphabetical on name, not ordered by opcode. */


/* Map from internal opcode -> real opcode */

static name_val_val a_opcode_tbl [] = {
#undef OP
#define OP(NAME, I_OPCODE, TYPE, A_OPCODE) {NAME, (int)A_OPCODE, (int)I_OPCODE},
#include "op.h"
};


/* Sort the opcode table on their key (the interal opcode value). */

static void
sort_a_opcode_table ()
{
  qsort (a_opcode_tbl,
	 sizeof (a_opcode_tbl) / sizeof (name_val_val),
	 sizeof (name_val_val),
	 (QSORT_FUNC) compare_pair_value);
}



instruction *
inst_decode (int32 val)
{
  int32 a_opcode = val & 0xfc000000;
  name_val_val *entry;
  int32 i_opcode;

  /* Field classes: (opcode is continued in other part of instruction): */
  if (a_opcode == 0 || a_opcode == 0x70000000) /* SPECIAL or SPECIAL2 */
    a_opcode |= (val & 0x3f);
  else if (a_opcode == 0x04000000)		/* REGIMM */
    a_opcode |= (val & 0x001f0000);
  else if (a_opcode == 0x40000000)		/* COP0 */
    a_opcode |= (val & 0x03e00000) | (val & 0x1f);
  else if (a_opcode == 0x44000000)		/* COP1 */
    {
      a_opcode |= (val & 0x03e00000);
      if ((val & 0xff000000) == 0x45000000)
	a_opcode |= (val & 0x00010000);		/* BC1f/t */
      else
	a_opcode |= (val & 0x3f);
    }
  else if (a_opcode == 0x48000000		/* COPz */
	   || a_opcode == 0x4c000000)
    a_opcode |= (val & 0x03e00000);


  entry = map_int_to_name_val_val (a_opcode_tbl,
				sizeof (a_opcode_tbl) / sizeof (name_val_val),
				a_opcode);
  if (entry == NULL)
    return (mk_r_inst (val, 0, 0, 0, 0, 0)); /* Invalid inst */

  i_opcode = entry->value2;

  switch (map_int_to_name_val_val (name_tbl,
				sizeof (name_tbl) / sizeof (name_val_val),
				i_opcode)->value2)
    {
    case BC_TYPE_INST:
      return (mk_i_inst (val, i_opcode, BIN_RS(val), BIN_RT(val),
			 val & 0xffff));

    case B1_TYPE_INST:
      return (mk_i_inst (val, i_opcode, BIN_RS(val), 0, val & 0xffff));

    case I1s_TYPE_INST:
      return (mk_i_inst (val, i_opcode, BIN_RS(val), 0, val & 0xffff));

    case I1t_TYPE_INST:
      return (mk_i_inst (val, i_opcode, BIN_RS(val), BIN_RT(val),
			 val & 0xffff));

    case I2_TYPE_INST:
    case B2_TYPE_INST:
      return (mk_i_inst (val, i_opcode, BIN_RS(val), BIN_RT(val),
			 val & 0xffff));

    case I2a_TYPE_INST:
      return (mk_i_inst (val, i_opcode, BIN_RS(val), BIN_RT(val),
			 val & 0xffff));

    case R1s_TYPE_INST:
      return (mk_r_inst (val, i_opcode, BIN_RS(val), 0, 0, 0));

    case R1d_TYPE_INST:
      return (mk_r_inst (val, i_opcode, 0, 0, BIN_RD(val), 0));

    case R2td_TYPE_INST:
      return (mk_r_inst (val, i_opcode, 0, BIN_RT(val), BIN_RD(val), 0));

    case R2st_TYPE_INST:
      return (mk_r_inst (val, i_opcode, BIN_RS(val), BIN_RT(val), 0, 0));

    case R2ds_TYPE_INST:
      return (mk_r_inst (val, i_opcode, BIN_RS(val), 0, BIN_RD(val), 0));

    case R2sh_TYPE_INST:
      return (mk_r_inst (val, i_opcode, 0, BIN_RT(val), BIN_RD(val), BIN_SA(val)));

    case R3_TYPE_INST:
      return (mk_r_inst (val, i_opcode, BIN_RS(val), BIN_RT(val), BIN_RD(val), 0));

    case R3sh_TYPE_INST:
      return(mk_r_inst (val, i_opcode, BIN_RS(val), BIN_RT(val), BIN_RD(val), 0));

    case FP_I2a_TYPE_INST:
      return (mk_i_inst (val, i_opcode, BIN_BASE(val), BIN_FT(val), val & 0xffff));

    case FP_R2ds_TYPE_INST:
      return (mk_r_inst (val, i_opcode, BIN_FS(val), 0, BIN_FD(val), 0));

    case FP_R2ts_TYPE_INST:
      return (mk_r_inst (val, i_opcode, 0, BIN_RT(val), BIN_FS(val), 0));

    case FP_CMP_TYPE_INST:
      {
	instruction *inst = mk_r_inst (val, i_opcode, BIN_FS (val), BIN_FT (val), BIN_FD(val), 0);
	SET_COND (inst, val & 0xf);
	return (inst);
      }

    case FP_R3_TYPE_INST:
      return (mk_r_inst (val, i_opcode, BIN_FS(val), BIN_FT(val), BIN_FD(val), 0));

    case MOVC_TYPE_INST:
      return (mk_r_inst (val, i_opcode, BIN_RS(val), BIN_RT(val), BIN_RD(val), 0));

    case FP_MOVC_TYPE_INST:
      return (mk_r_inst (val, i_opcode, BIN_FS(val), BIN_RT(val), BIN_FD(val), 0));

    case J_TYPE_INST:
      return (mk_j_inst (val, i_opcode, val & 0x2ffffff));


    case NOARG_TYPE_INST:
      return (mk_r_inst (val, i_opcode, 0, 0, 0, 0));

    default:
      return (mk_r_inst (val, 0, 0, 0, 0, 0)); /* Invalid inst */
    }
}


static instruction *
mk_r_inst (int32 val, int opcode, int rs, int rt, int rd, int shamt)
{
  instruction *inst = (instruction *) zmalloc (sizeof (instruction));

  SET_OPCODE (inst, opcode);
  SET_RS (inst, rs);
  SET_RT (inst, rt);
  SET_RD (inst, rd);
  SET_SHAMT (inst, shamt);
  SET_ENCODING (inst, val);
  SET_EXPR (inst, NULL);
  return (inst);
}


static instruction *
mk_i_inst (int32 val, int opcode, int rs, int rt, int offset)
{
  instruction *inst = (instruction *) zmalloc (sizeof (instruction));

  SET_OPCODE (inst, opcode);
  SET_RS (inst, rs);
  SET_RT (inst, rt);
  SET_IOFFSET (inst, offset);
  SET_ENCODING (inst, val);
  SET_EXPR (inst, NULL);
  return (inst);
}

static instruction *
mk_j_inst (int32 val, int opcode, int target)
{
  instruction *inst = (instruction *) zmalloc (sizeof (instruction));

  SET_OPCODE (inst, opcode);
  SET_TARGET (inst, target);
  SET_ENCODING (inst, val);
  SET_EXPR (inst, NULL);
  return (inst);
}



/* Code to test encode/decode of instructions. */

void
test_assembly (instruction *inst)
{
  instruction *new_inst = inst_decode (inst_encode (inst));

  inst_cmp (inst, new_inst);
  free_inst (new_inst);
}


static void
inst_cmp (instruction *inst1, instruction *inst2)
{
  static str_stream ss;

  ss_clear (&ss);
  if (memcmp (inst1, inst2, sizeof (instruction) - 4) != 0)
    {
      ss_printf (&ss, "=================== Not Equal ===================\n");
      format_an_inst (&ss, inst1, 0);
      format_an_inst (&ss, inst2, 0);
      ss_printf (&ss, "=================== Not Equal ===================\n");
    }
}
