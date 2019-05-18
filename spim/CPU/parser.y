/* SPIM S20 MIPS simulator.
   Parser for instructions and assembler directives.

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

%expect 25           /* Supress warning about 25 shift-reduce conflicts */

%start LINE

%token Y_EOF

%token Y_NL
%token Y_INT
%token Y_ID
%token Y_REG
%token Y_FP_REG
%token Y_STR
%token Y_FP

/* MIPS instructions op codes: */

%token Y_ABS_D_OP
%token Y_ABS_PS_OP
%token Y_ABS_S_OP
%token Y_ADD_D_OP
%token Y_ADD_OP
%token Y_ADD_PS_OP
%token Y_ADD_S_OP
%token Y_ADDI_OP
%token Y_ADDIU_OP
%token Y_ADDU_OP
%token Y_ALNV_PS_OP
%token Y_AND_OP
%token Y_ANDI_OP
%token Y_BC1F_OP
%token Y_BC1FL_OP
%token Y_BC1T_OP
%token Y_BC1TL_OP
%token Y_BC2F_OP
%token Y_BC2FL_OP
%token Y_BC2T_OP
%token Y_BC2TL_OP
%token Y_BEQ_OP
%token Y_BEQL_OP
%token Y_BGEZ_OP
%token Y_BGEZAL_OP
%token Y_BGEZALL_OP
%token Y_BGEZL_OP
%token Y_BGTZ_OP
%token Y_BGTZL_OP
%token Y_BLEZ_OP
%token Y_BLEZL_OP
%token Y_BLTZ_OP
%token Y_BLTZAL_OP
%token Y_BLTZALL_OP
%token Y_BLTZL_OP
%token Y_BNE_OP
%token Y_BNEL_OP
%token Y_BREAK_OP
%token Y_C_EQ_D_OP
%token Y_C_EQ_PS_OP
%token Y_C_EQ_S_OP
%token Y_C_F_D_OP
%token Y_C_F_PS_OP
%token Y_C_F_S_OP
%token Y_C_LE_D_OP
%token Y_C_LE_PS_OP
%token Y_C_LE_S_OP
%token Y_C_LT_D_OP
%token Y_C_LT_PS_OP
%token Y_C_LT_S_OP
%token Y_C_NGE_D_OP
%token Y_C_NGE_PS_OP
%token Y_C_NGE_S_OP
%token Y_C_NGL_D_OP
%token Y_C_NGL_PS_OP
%token Y_C_NGL_S_OP
%token Y_C_NGLE_D_OP
%token Y_C_NGLE_PS_OP
%token Y_C_NGLE_S_OP
%token Y_C_NGT_D_OP
%token Y_C_NGT_PS_OP
%token Y_C_NGT_S_OP
%token Y_C_OLE_D_OP
%token Y_C_OLE_PS_OP
%token Y_C_OLE_S_OP
%token Y_C_OLT_D_OP
%token Y_C_OLT_PS_OP
%token Y_C_OLT_S_OP
%token Y_C_SEQ_D_OP
%token Y_C_SEQ_PS_OP
%token Y_C_SEQ_S_OP
%token Y_C_SF_D_OP
%token Y_C_SF_PS_OP
%token Y_C_SF_S_OP
%token Y_C_UEQ_D_OP
%token Y_C_UEQ_PS_OP
%token Y_C_UEQ_S_OP
%token Y_C_ULE_D_OP
%token Y_C_ULE_PS_OP
%token Y_C_ULE_S_OP
%token Y_C_ULT_D_OP
%token Y_C_ULT_PS_OP
%token Y_C_ULT_S_OP
%token Y_C_UN_D_OP
%token Y_C_UN_PS_OP
%token Y_C_UN_S_OP
%token Y_CACHE_OP
%token Y_CEIL_L_D_OP
%token Y_CEIL_L_S_OP
%token Y_CEIL_W_D_OP
%token Y_CEIL_W_S_OP
%token Y_CFC0_OP
%token Y_CFC1_OP
%token Y_CFC2_OP
%token Y_CLO_OP
%token Y_CLZ_OP
%token Y_COP2_OP
%token Y_CTC0_OP
%token Y_CTC1_OP
%token Y_CTC2_OP
%token Y_CVT_D_L_OP
%token Y_CVT_D_S_OP
%token Y_CVT_D_W_OP
%token Y_CVT_L_D_OP
%token Y_CVT_L_S_OP
%token Y_CVT_PS_S_OP
%token Y_CVT_S_D_OP
%token Y_CVT_S_L_OP
%token Y_CVT_S_PL_OP
%token Y_CVT_S_PU_OP
%token Y_CVT_S_W_OP
%token Y_CVT_W_D_OP
%token Y_CVT_W_S_OP
%token Y_DERET_OP
%token Y_DI_OP
%token Y_DIV_D_OP
%token Y_DIV_OP
%token Y_DIV_S_OP
%token Y_DIVU_OP
%token Y_EHB_OP
%token Y_EI_OP
%token Y_ERET_OP
%token Y_EXT_OP
%token Y_FLOOR_L_D_OP
%token Y_FLOOR_L_S_OP
%token Y_FLOOR_W_D_OP
%token Y_FLOOR_W_S_OP
%token Y_INS_OP
%token Y_J_OP
%token Y_JAL_OP
%token Y_JALR_HB_OP
%token Y_JALR_OP
%token Y_JR_HB_OP
%token Y_JR_OP
%token Y_LB_OP
%token Y_LBU_OP
%token Y_LDC1_OP
%token Y_LDC2_OP
%token Y_LDXC1_OP
%token Y_LH_OP
%token Y_LHU_OP
%token Y_LL_OP
%token Y_LUI_OP
%token Y_LUXC1_OP
%token Y_LW_OP
%token Y_LWC1_OP
%token Y_LWC2_OP
%token Y_LWL_OP
%token Y_LWR_OP
%token Y_LWXC1_OP
%token Y_MADD_D_OP
%token Y_MADD_OP
%token Y_MADD_PS_OP
%token Y_MADD_S_OP
%token Y_MADDU_OP
%token Y_MFC0_OP
%token Y_MFC1_OP
%token Y_MFC2_OP
%token Y_MFHC1_OP
%token Y_MFHC2_OP
%token Y_MFHI_OP
%token Y_MFLO_OP
%token Y_MOV_D_OP
%token Y_MOV_PS_OP
%token Y_MOV_S_OP
%token Y_MOVF_D_OP
%token Y_MOVF_OP
%token Y_MOVF_PS_OP
%token Y_MOVF_S_OP
%token Y_MOVN_D_OP
%token Y_MOVN_OP
%token Y_MOVN_PS_OP
%token Y_MOVN_S_OP
%token Y_MOVT_D_OP
%token Y_MOVT_OP
%token Y_MOVT_PS_OP
%token Y_MOVT_S_OP
%token Y_MOVZ_D_OP
%token Y_MOVZ_OP
%token Y_MOVZ_PS_OP
%token Y_MOVZ_S_OP
%token Y_MSUB_D_OP
%token Y_MSUB_OP
%token Y_MSUB_PS_OP
%token Y_MSUB_S_OP
%token Y_MSUBU_OP
%token Y_MTC0_OP
%token Y_MTC1_OP
%token Y_MTC2_OP
%token Y_MTHC1_OP
%token Y_MTHC2_OP
%token Y_MTHI_OP
%token Y_MTLO_OP
%token Y_MUL_D_OP
%token Y_MUL_PS_OP
%token Y_MUL_S_OP
%token Y_MUL_OP
%token Y_MULT_OP
%token Y_MULTU_OP
%token Y_NEG_D_OP
%token Y_NEG_PS_OP
%token Y_NEG_S_OP
%token Y_NMADD_D_OP
%token Y_NMADD_PS_OP
%token Y_NMADD_S_OP
%token Y_NMSUB_D_OP
%token Y_NMSUB_PS_OP
%token Y_NMSUB_S_OP
%token Y_NOR_OP
%token Y_OR_OP
%token Y_ORI_OP
%token Y_PFW_OP
%token Y_PLL_PS_OP
%token Y_PLU_PS_OP
%token Y_PREF_OP
%token Y_PREFX_OP
%token Y_PUL_PS_OP
%token Y_PUU_PS_OP
%token Y_RDHWR_OP
%token Y_RDPGPR_OP
%token Y_RECIP_D_OP
%token Y_RECIP_S_OP
%token Y_RFE_OP
%token Y_ROTR_OP
%token Y_ROTRV_OP
%token Y_ROUND_L_D_OP
%token Y_ROUND_L_S_OP
%token Y_ROUND_W_D_OP
%token Y_ROUND_W_S_OP
%token Y_RSQRT_D_OP
%token Y_RSQRT_S_OP
%token Y_SB_OP
%token Y_SC_OP
%token Y_SDBBP_OP
%token Y_SDC1_OP
%token Y_SDC2_OP
%token Y_SDXC1_OP
%token Y_SEB_OP
%token Y_SEH_OP
%token Y_SH_OP
%token Y_SLL_OP
%token Y_SLLV_OP
%token Y_SLT_OP
%token Y_SLTI_OP
%token Y_SLTIU_OP
%token Y_SLTU_OP
%token Y_SQRT_D_OP
%token Y_SQRT_S_OP
%token Y_SRA_OP
%token Y_SRAV_OP
%token Y_SRL_OP
%token Y_SRLV_OP
%token Y_SSNOP_OP
%token Y_SUB_D_OP
%token Y_SUB_OP
%token Y_SUB_PS_OP
%token Y_SUB_S_OP
%token Y_SUBU_OP
%token Y_SUXC1_OP
%token Y_SW_OP
%token Y_SWC1_OP
%token Y_SWC2_OP
%token Y_SWL_OP
%token Y_SWR_OP
%token Y_SWXC1_OP
%token Y_SYNC_OP
%token Y_SYNCI_OP
%token Y_SYSCALL_OP
%token Y_TEQ_OP
%token Y_TEQI_OP
%token Y_TGE_OP
%token Y_TGEI_OP
%token Y_TGEIU_OP
%token Y_TGEU_OP
%token Y_TLBP_OP
%token Y_TLBR_OP
%token Y_TLBWI_OP
%token Y_TLBWR_OP
%token Y_TLT_OP
%token Y_TLTI_OP
%token Y_TLTIU_OP
%token Y_TLTU_OP
%token Y_TNE_OP
%token Y_TNEI_OP
%token Y_TRUNC_L_D_OP
%token Y_TRUNC_L_S_OP
%token Y_TRUNC_W_D_OP
%token Y_TRUNC_W_S_OP
%token Y_WRPGPR_OP
%token Y_WSBH_OP
%token Y_XOR_OP
%token Y_XORI_OP


/* Assembler pseudo operations op codes: */

%token Y_ABS_POP
%token Y_B_POP
%token Y_BAL_POP
%token Y_BEQZ_POP
%token Y_BGE_POP
%token Y_BGEU_POP
%token Y_BGT_POP
%token Y_BGTU_POP
%token Y_BLE_POP
%token Y_BLEU_POP
%token Y_BLT_POP
%token Y_BLTU_POP
%token Y_BNEZ_POP
%token Y_LA_POP
%token Y_LD_POP
%token Y_L_D_POP
%token Y_L_S_POP
%token Y_LI_D_POP
%token Y_LI_POP
%token Y_LI_S_POP
%token Y_MFC1_D_POP
%token Y_MOVE_POP
%token Y_MTC1_D_POP
%token Y_MULO_POP
%token Y_MULOU_POP
%token Y_NEG_POP
%token Y_NEGU_POP
%token Y_NOP_POP
%token Y_NOT_POP
%token Y_REM_POP
%token Y_REMU_POP
%token Y_ROL_POP
%token Y_ROR_POP
%token Y_S_D_POP
%token Y_S_S_POP
%token Y_SD_POP
%token Y_SEQ_POP
%token Y_SGE_POP
%token Y_SGEU_POP
%token Y_SGT_POP
%token Y_SGTU_POP
%token Y_SLE_POP
%token Y_SLEU_POP
%token Y_SNE_POP
%token Y_ULH_POP
%token Y_ULHU_POP
%token Y_ULW_POP
%token Y_USH_POP
%token Y_USW_POP

/* Assembler directives: */

%token Y_ALIAS_DIR
%token Y_ALIGN_DIR
%token Y_ASCII_DIR
%token Y_ASCIIZ_DIR
%token Y_ASM0_DIR
%token Y_BGNB_DIR
%token Y_BYTE_DIR
%token Y_COMM_DIR
%token Y_DATA_DIR
%token Y_DOUBLE_DIR
%token Y_END_DIR
%token Y_ENDB_DIR
%token Y_ENDR_DIR
%token Y_ENT_DIR
%token Y_ERR_DIR
%token Y_EXTERN_DIR
%token Y_FILE_DIR
%token Y_FLOAT_DIR
%token Y_FMASK_DIR
%token Y_FRAME_DIR
%token Y_GLOBAL_DIR
%token Y_HALF_DIR
%token Y_K_DATA_DIR
%token Y_K_TEXT_DIR
%token Y_LABEL_DIR
%token Y_LCOMM_DIR
%token Y_LIVEREG_DIR
%token Y_LOC_DIR
%token Y_MASK_DIR
%token Y_NOALIAS_DIR
%token Y_OPTIONS_DIR
%token Y_RDATA_DIR
%token Y_REPEAT_DIR
%token Y_SDATA_DIR
%token Y_SET_DIR
%token Y_SPACE_DIR
%token Y_STRUCT_DIR
%token Y_TEXT_DIR
%token Y_VERSTAMP_DIR
%token Y_VREG_DIR
%token Y_WORD_DIR

%{
#include <stdio.h>

#include "spim.h"
#include "string-stream.h"
#include "spim-utils.h"
#include "inst.h"
#include "reg.h"
#include "mem.h"
#include "sym-tbl.h"
#include "data.h"
#include "scanner.h"
#include "parser.h"


/* return (0) */
#define LINE_PARSE_DONE YYACCEPT

/* return (1) */
#define FILE_PARSE_DONE YYABORT

typedef struct ll
{
  label *head;
  struct ll *tail;
} label_list;


/* Exported Variables: */

bool data_dir;                  /* => item in data segment */

bool text_dir;                  /* => item in text segment */

bool parse_error_occurred;      /* => parse resulted in error */


/* Local functions: */

static imm_expr *branch_offset (int n_inst);
static int cc_to_rt (int cc, int nd, int tf);
static void check_imm_range (imm_expr*, int32, int32);
static void check_uimm_range (imm_expr*, uint32, uint32);
static void clear_labels ();
static label_list *cons_label (label *head, label_list *tail);
static void div_inst (int op, int rd, int rs, int rt, int const_divisor);
static void mips32_r2_inst ();
static void mult_inst (int op, int rd, int rs, int rt);
static void nop_inst ();
static void set_eq_inst (int op, int rd, int rs, int rt);
static void set_ge_inst (int op, int rd, int rs, int rt);
static void set_gt_inst (int op, int rd, int rs, int rt);
static void set_le_inst (int op, int rd, int rs, int rt);
static void store_word_data (int value);
static void trap_inst ();
static void yywarn (char*);


/* Local variables: */

static bool null_term;		/* => string terminate by \0 */

static void (*store_op) (void*); /* Function to store items in an EXPR_LST */

static label_list *this_line_labels = NULL; /* List of label for curent line */

static bool noat_flag = 0;	/* => program can use $1 */

static char *input_file_name;	/* Name of file being parsed */

%}



%%

LINE:		{parse_error_occurred = false; scanner_start_line (); } LBL_CMD ;

LBL_CMD:	OPT_LBL CMD
	|	CMD
	;


OPT_LBL: ID ':' {
		  /* Call outside of cons_label, since an error sets that variable to NULL. */
		  label* l = record_label ((char*)$1.p,
					   text_dir ? current_text_pc () : current_data_pc (),
					   0);
		  this_line_labels = cons_label (l, this_line_labels);
		  free ((char*)$1.p);
		}

	|	ID '=' EXPR
		{
		  label *l = record_label ((char*)$1.p, (mem_addr)$3.i, 1);
		  free ((char*)$1.p);

		  l->const_flag = 1;
		  clear_labels ();
		}
	;


CMD:		ASM_CODE
		{
		  clear_labels ();
		}
		TERM

	|	ASM_DIRECTIVE
		{
		  clear_labels ();
		}
		TERM

	|	TERM
    ;


TERM:		Y_NL
		{
			LINE_PARSE_DONE;
		}

	|	Y_EOF
		{
		  clear_labels ();
		  FILE_PARSE_DONE;
		}
	;



ASM_CODE:	LOAD_OPS	DEST	ADDRESS
		{
		  i_type_inst ($1.i == Y_LD_POP ? Y_LW_OP : $1.i,
			       $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
		  if ($1.i == Y_LD_POP)
		    i_type_inst_free (Y_LW_OP,
				      $2.i + 1,
				      addr_expr_reg ((addr_expr *)$3.p),
				      incr_expr_offset (addr_expr_imm ((addr_expr *)$3.p),
							4));
		  free (((addr_expr *)$3.p)->imm);
		  free ((addr_expr *)$3.p);
		}

	|	LOADC_OPS	COP_REG	ADDRESS
		{
		  i_type_inst ($1.i,
			       $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
		  free (((addr_expr *)$3.p)->imm);
		  free ((addr_expr *)$3.p);
		}

	|	LOADFP_OPS	F_SRC1	ADDRESS
		{
		  i_type_inst ($1.i,
			       $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
		  free (((addr_expr *)$3.p)->imm);
		  free ((addr_expr *)$3.p);
		}

	|	LOADI_OPS	DEST	UIMM16
		{
		  i_type_inst_free ($1.i, $2.i, 0, (imm_expr *)$3.p);
		}


	|	Y_LA_POP	DEST	ADDRESS
		{
		  if (addr_expr_reg ((addr_expr *)$3.p))
		    i_type_inst (Y_ADDI_OP, $2.i,
				 addr_expr_reg ((addr_expr *)$3.p),
				 addr_expr_imm ((addr_expr *)$3.p));
		  else
		    i_type_inst (Y_ORI_OP, $2.i, 0,
				 addr_expr_imm ((addr_expr *)$3.p));
		  free (((addr_expr *)$3.p)->imm);
		  free ((addr_expr *)$3.p);
		}


	|	Y_LI_POP	DEST	IMM32
		{
		  i_type_inst_free (Y_ORI_OP, $2.i, 0, (imm_expr *)$3.p);
		}


	|	Y_LI_D_POP	F_DEST	Y_FP
		{
		  int *x = (int *) $3.p;

		  i_type_inst (Y_ORI_OP, 1, 0, const_imm_expr (*x));
		  r_co_type_inst (Y_MTC1_OP, 0, $2.i, 1);
		  i_type_inst (Y_ORI_OP, 1, 0, const_imm_expr (*(x+1)));
		  r_co_type_inst (Y_MTC1_OP, 0, $2.i + 1, 1);
		}


	|	Y_LI_S_POP	F_DEST	Y_FP
		{
		  float x = (float) *((double *) $3.p);
		  int *y = (int *) &x;

		  i_type_inst (Y_ORI_OP, 1, 0, const_imm_expr (*y));
		  r_co_type_inst (Y_MTC1_OP, 0, $2.i, 1);
		}


	|	Y_ULW_POP	DEST	ADDRESS
		{
#ifdef SPIM_BIGENDIAN
		  i_type_inst (Y_LWL_OP, $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
		  i_type_inst_free (Y_LWR_OP, $2.i,
				    addr_expr_reg ((addr_expr *)$3.p),
				    incr_expr_offset (addr_expr_imm ((addr_expr *)$3.p),
						      3));
#else
		  i_type_inst_free (Y_LWL_OP, $2.i,
				    addr_expr_reg ((addr_expr *)$3.p),
				    incr_expr_offset (addr_expr_imm ((addr_expr *)$3.p),
						      3));
		  i_type_inst (Y_LWR_OP, $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
#endif
		  free (((addr_expr *)$3.p)->imm);
		  free ((addr_expr *)$3.p);
		}


	|	ULOADH_POPS	DEST	ADDRESS
		{
#ifdef SPIM_BIGENDIAN
		  i_type_inst (($1.i == Y_ULH_POP ? Y_LB_OP : Y_LBU_OP),
			       $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
		  i_type_inst_free (Y_LBU_OP, 1,
				    addr_expr_reg ((addr_expr *)$3.p),
				    incr_expr_offset (addr_expr_imm ((addr_expr *)$3.p),
						      1));
#else
		  i_type_inst_free (($1.i == Y_ULH_POP ? Y_LB_OP : Y_LBU_OP),
				    $2.i,
				    addr_expr_reg ((addr_expr *)$3.p),
				    incr_expr_offset (addr_expr_imm ((addr_expr *)$3.p),
						      1));
		  i_type_inst (Y_LBU_OP, 1,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
#endif
		  r_sh_type_inst (Y_SLL_OP, $2.i, $2.i, 8);
		  r_type_inst (Y_OR_OP, $2.i, $2.i, 1);
		  free (((addr_expr *)$3.p)->imm);
		  free ((addr_expr *)$3.p);
		}


	|	LOADFP_INDEX_OPS F_DEST	ADDRESS
		{
		  mips32_r2_inst ();
		}


	|	STORE_OPS	SRC1	ADDRESS
		{
		  i_type_inst ($1.i == Y_SD_POP ? Y_SW_OP : $1.i,
			       $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
		  if ($1.i == Y_SD_POP)
		    i_type_inst_free (Y_SW_OP, $2.i + 1,
				      addr_expr_reg ((addr_expr *)$3.p),
				      incr_expr_offset (addr_expr_imm ((addr_expr *)$3.p),
							4));
		  free (((addr_expr *)$3.p)->imm);
		  free ((addr_expr *)$3.p);
		}


	|	STOREC_OPS	COP_REG	ADDRESS
		{
		  i_type_inst ($1.i,
			       $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
		  free (((addr_expr *)$3.p)->imm);
		  free ((addr_expr *)$3.p);
		}


	|	Y_USW_POP	SRC1	ADDRESS
		{
#ifdef SPIM_BIGENDIAN
		  i_type_inst (Y_SWL_OP, $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
		  i_type_inst_free (Y_SWR_OP, $2.i,
				    addr_expr_reg ((addr_expr *)$3.p),
				    incr_expr_offset (addr_expr_imm ((addr_expr *)$3.p),
						      3));
#else
		  i_type_inst_free (Y_SWL_OP, $2.i,
				    addr_expr_reg ((addr_expr *)$3.p),
				    incr_expr_offset (addr_expr_imm ((addr_expr *)$3.p),
						      3));
		  i_type_inst (Y_SWR_OP, $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
#endif
		  free (((addr_expr *)$3.p)->imm);
		  free ((addr_expr *)$3.p);
		}


	|	Y_USH_POP	SRC1	ADDRESS
		{
		  i_type_inst (Y_SB_OP, $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));

		  /* ROL SRC, SRC, 8 */
		  r_sh_type_inst (Y_SLL_OP, 1, $2.i, 24);
		  r_sh_type_inst (Y_SRL_OP, $2.i, $2.i, 8);
		  r_type_inst (Y_OR_OP, $2.i, $2.i, 1);

		  i_type_inst_free (Y_SB_OP, $2.i,
				    addr_expr_reg ((addr_expr *)$3.p),
				    incr_expr_offset (addr_expr_imm ((addr_expr *)$3.p),
						      1));
		  /* ROR SRC, SRC, 8 */
		  r_sh_type_inst (Y_SRL_OP, 1, $2.i, 24);
		  r_sh_type_inst (Y_SLL_OP, $2.i, $2.i, 8);
		  r_type_inst (Y_OR_OP, $2.i, $2.i, 1);

		  free (((addr_expr *)$3.p)->imm);
		  free ((addr_expr *)$3.p);
		}


	|	STOREFP_OPS	F_SRC1	ADDRESS
		{
		  i_type_inst ($1.i,
			       $2.i,
			       addr_expr_reg ((addr_expr *)$3.p),
			       addr_expr_imm ((addr_expr *)$3.p));
		  free (((addr_expr *)$3.p)->imm);
		  free ((addr_expr *)$3.p);
		}


	|	STOREFP_INDEX_OPS F_DEST	ADDRESS
		{
		  mips32_r2_inst ();
		}


	|	SYS_OPS
		{
		  r_type_inst ($1.i, 0, 0, 0);
		}


	|	PREFETCH_OPS	ADDRESS
		{
		  mips32_r2_inst ();
		}


	|	CACHE_OPS	Y_INT	ADDRESS
		{
		  i_type_inst_free ($1.i, $2.i, 0, (imm_expr *)$3.p);
		}


	|	TLB_OPS
		{
		  r_type_inst ($1.i, 0, 0, 0);
		}


	|	Y_SYNC_OP
		{
		  r_type_inst ($1.i, 0, 0, 0);
		}

	|	Y_SYNC_OP	Y_INT
		{
		  r_type_inst ($1.i, $2.i, 0, 0);
		}


	|	Y_BREAK_OP	Y_INT
		{
		  if ($2.i == 1)
		    yyerror ("Breakpoint 1 is reserved for debugger");
		  r_type_inst ($1.i, $2.i, 0, 0);
		}


	|	Y_NOP_POP
		{
		  nop_inst ();
		}


	|	Y_SSNOP_OP
		{
		  r_sh_type_inst (Y_SLL_OP, 0, 0, 1); /* SLL r0 r0 1 */
		}


	|	Y_ABS_POP	DEST	SRC1
		{
		  if ($2.i != $3.i)
		    r_type_inst (Y_ADDU_OP, $2.i, 0, $3.i);

		  i_type_inst_free (Y_BGEZ_OP, 0, $3.i, branch_offset (2));
		  r_type_inst (Y_SUB_OP, $2.i, 0, $3.i);
		}


	|	Y_NEG_POP	DEST	SRC1
		{
		  r_type_inst (Y_SUB_OP, $2.i, 0, $3.i);
		}


	|	Y_NEGU_POP	DEST	SRC1
		{
		  r_type_inst (Y_SUBU_OP, $2.i, 0, $3.i);
		}


	|	Y_NOT_POP	DEST	SRC1
		{
		  r_type_inst (Y_NOR_OP, $2.i, $3.i, 0);
		}


	|	Y_MOVE_POP	DEST	SRC1
		{
		  r_type_inst (Y_ADDU_OP, $2.i, 0, $3.i);
		}


	|	NULLARY_OPS
		{
		  r_type_inst ($1.i, 0, 0, 0);
		}


	|	NULLARY_OPS_REV2
		{
		  mips32_r2_inst ();
		}


	|	COUNT_LEADING_OPS DEST	SRC1
		{
		  /* RT must be equal to RD */
		  r_type_inst ($1.i, $2.i, $3.i, $2.i);
		}


	|	UNARY_OPS_REV2	DEST
		{
		  mips32_r2_inst ();
		}


	|	BINARYI_OPS	DEST	SRC1	SRC2
		{
		  r_type_inst ($1.i, $2.i, $3.i, $4.i);
		}

	|	BINARYI_OPS	DEST	SRC1	IMM32
		{
		  i_type_inst_free (op_to_imm_op ($1.i), $2.i, $3.i,
				    (imm_expr *)$4.p);
		}

	|	BINARYI_OPS	DEST	IMM32
		{
		  i_type_inst_free (op_to_imm_op ($1.i), $2.i, $2.i,
				    (imm_expr *)$3.p);
		}


	|	BINARYIR_OPS	DEST	SRC1	SRC2
		{
		  r_type_inst ($1.i, $2.i, $4.i, $3.i);
		}

	|	BINARYIR_OPS	DEST	SRC1	Y_INT
		{
		  r_sh_type_inst (op_to_imm_op ($1.i), $2.i, $3.i, $4.i);
		}

	|	BINARYIR_OPS	DEST	Y_INT
		{
		  r_sh_type_inst (op_to_imm_op ($1.i), $2.i, $2.i, $3.i);
		}


	|	BINARY_ARITHI_OPS DEST	SRC1	IMM16
		{
		  i_type_inst_free ($1.i, $2.i, $3.i, (imm_expr *)$4.p);
		}

	|	BINARY_ARITHI_OPS DEST	IMM16
		{
		  i_type_inst_free ($1.i, $2.i, $2.i, (imm_expr *)$3.p);
		}


	|	BINARY_LOGICALI_OPS DEST	SRC1	UIMM16
		{
		  i_type_inst_free ($1.i, $2.i, $3.i, (imm_expr *)$4.p);
		}

	|	BINARY_LOGICALI_OPS DEST	UIMM16
		{
		  i_type_inst_free ($1.i, $2.i, $2.i, (imm_expr *)$3.p);
		}


	|	SHIFT_OPS	DEST	SRC1	Y_INT
		{
		  if (($4.i < 0) || (31 < $4.i))
		    yywarn ("Shift distance can only be in the range 0..31");
		  r_sh_type_inst ($1.i, $2.i, $3.i, $4.i);
		}

	|	SHIFT_OPS	DEST	SRC1	SRC2
		{
		  r_type_inst (imm_op_to_op ($1.i), $2.i, $4.i, $3.i);
		}


	|	SHIFT_OPS_REV2	DEST	SRC1	Y_INT
		{
		  mips32_r2_inst ();
		}

	|	SHIFTV_OPS_REV2	DEST	SRC1	SRC2
		{
		  mips32_r2_inst ();
		}


	|	BINARY_OPS	DEST	SRC1	SRC2
		{
		  r_type_inst ($1.i, $2.i, $3.i, $4.i);
		}

	|	BINARY_OPS	DEST	SRC1	IMM32
		{
		  if (bare_machine && !accept_pseudo_insts)
		    yyerror ("Immediate form not allowed in bare machine");
		  else
		    {
		      if (!is_zero_imm ((imm_expr *)$4.p))
			/* Use $at */
			i_type_inst (Y_ORI_OP, 1, 0, (imm_expr *)$4.p);
		      r_type_inst ($1.i,
				   $2.i,
				   $3.i,
				   (is_zero_imm ((imm_expr *)$4.p) ? 0 : 1));
		    }
		  free ((imm_expr *)$4.p);
		}

	|	BINARY_OPS	DEST	IMM32
		{
		  check_uimm_range ((imm_expr *)$3.p, UIMM_MIN, UIMM_MAX);
		  if (bare_machine && !accept_pseudo_insts)
		    yyerror ("Immediate form not allowed in bare machine");
		  else
		    {
		      if (!is_zero_imm ((imm_expr *)$3.p))
			/* Use $at */
			i_type_inst (Y_ORI_OP, 1, 0, (imm_expr *)$3.p);
		      r_type_inst ($1.i,
				   $2.i,
				   $2.i,
				   (is_zero_imm ((imm_expr *)$3.p) ? 0 : 1));
		    }
		  free ((imm_expr *)$3.p);
		}


	|	BINARY_OPS_REV2	DEST	SRC1
		{
		  mips32_r2_inst ();
		}


	|	SUB_OPS		DEST	SRC1	SRC2
		{
		  r_type_inst ($1.i, $2.i, $3.i, $4.i);
		}

	|	SUB_OPS		DEST	SRC1	IMM32
		{
		  int val = eval_imm_expr ((imm_expr *)$4.p);

		  if (bare_machine && !accept_pseudo_insts)
		    yyerror ("Immediate form not allowed in bare machine");
		  else
		    i_type_inst ($1.i == Y_SUB_OP ? Y_ADDI_OP
				 : $1.i == Y_SUBU_OP ? Y_ADDIU_OP
				 : (fatal_error ("Bad SUB_OP\n"), 0),
				 $2.i,
				 $3.i,
				 make_imm_expr (-val, NULL, false));
		  free ((imm_expr *)$4.p);
		}

	|	SUB_OPS		DEST	IMM32
		{
		  int val = eval_imm_expr ((imm_expr *)$3.p);

		  if (bare_machine && !accept_pseudo_insts)
		    yyerror ("Immediate form not allowed in bare machine");
		  else
		    i_type_inst ($1.i == Y_SUB_OP ? Y_ADDI_OP
				 : $1.i == Y_SUBU_OP ? Y_ADDIU_OP
				 : (fatal_error ("Bad SUB_OP\n"), 0),
				 $2.i,
				 $2.i,
				 make_imm_expr (-val, NULL, false));
		  free ((imm_expr *)$3.p);
		}


	|	DIV_POPS	DEST	SRC1
		{
		  /* The hardware divide operation (ignore 1st arg) */
		  if ($1.i != Y_DIV_OP && $1.i != Y_DIVU_OP)
		    yyerror ("REM requires 3 arguments");
		  else
		    r_type_inst ($1.i, 0, $2.i, $3.i);
		}

	|	DIV_POPS	DEST	SRC1	SRC2
		{
		  /* Pseudo divide operations */
		  div_inst ($1.i, $2.i, $3.i, $4.i, 0);
		}

	|	DIV_POPS	DEST	SRC1	IMM32
		{
		  if (is_zero_imm ((imm_expr *)$4.p))
		    yyerror ("Divide by zero");
		  else
		    {
		      /* Use $at */
		      i_type_inst_free (Y_ORI_OP, 1, 0, (imm_expr *)$4.p);
		      div_inst ($1.i, $2.i, $3.i, 1, 1);
		    }
		}


	|	MUL_POPS	DEST	SRC1	SRC2
		{
		  mult_inst ($1.i, $2.i, $3.i, $4.i);
		}

	|	MUL_POPS	DEST	SRC1	IMM32
		{
		  if (is_zero_imm ((imm_expr *)$4.p))
		    /* Optimize: n * 0 == 0 */
		    i_type_inst_free (Y_ORI_OP, $2.i, 0, (imm_expr *)$4.p);
		  else
		    {
		      /* Use $at */
		      i_type_inst_free (Y_ORI_OP, 1, 0, (imm_expr *)$4.p);
		      mult_inst ($1.i, $2.i, $3.i, 1);
		    }
		}


	|	MULT_OPS	SRC1	SRC2
		{
		  r_type_inst ($1.i, 0, $2.i, $3.i);
		}


	|	MULT_OPS3	DEST	SRC1	SRC2
		{
		  r_type_inst ($1.i, $2.i, $3.i, $4.i);
		}

	|	MULT_OPS3	DEST	SRC1	IMM32
		{
		  /* Special case, for backward compatibility with pseudo-op
		     MULT instruction */
		  i_type_inst_free (Y_ORI_OP, 1, 0, (imm_expr *)$4.p); /* Use $at */
		  r_type_inst ($1.i, $2.i, $3.i, 1);
		}


	|	Y_ROR_POP	DEST	SRC1	SRC2
		{
		  r_type_inst (Y_SUBU_OP, 1, 0, $4.i);
		  r_type_inst (Y_SLLV_OP, 1, 1, $3.i);
		  r_type_inst (Y_SRLV_OP, $2.i, $4.i, $3.i);
		  r_type_inst (Y_OR_OP, $2.i, $2.i, 1);
		}


	|	Y_ROL_POP	DEST	SRC1	SRC2
		{
		  r_type_inst (Y_SUBU_OP, 1, 0, $4.i);
		  r_type_inst (Y_SRLV_OP, 1, 1, $3.i);
		  r_type_inst (Y_SLLV_OP, $2.i, $4.i, $3.i);
		  r_type_inst (Y_OR_OP, $2.i, $2.i, 1);
		}


	|	Y_ROR_POP	DEST	SRC1	IMM32
		{
		  long dist = eval_imm_expr ((imm_expr *)$4.p);

		  check_imm_range ((imm_expr *)$4.p, 0, 31);
		  r_sh_type_inst (Y_SLL_OP, 1, $3.i, -dist);
		  r_sh_type_inst (Y_SRL_OP, $2.i, $3.i, dist);
		  r_type_inst (Y_OR_OP, $2.i, $2.i, 1);
		  free ((imm_expr *)$4.p);
		}


	|	Y_ROL_POP	DEST	SRC1	IMM32
		{
		  long dist = eval_imm_expr ((imm_expr *)$4.p);

		  check_imm_range ((imm_expr *)$4.p, 0, 31);
		  r_sh_type_inst (Y_SRL_OP, 1, $3.i, -dist);
		  r_sh_type_inst (Y_SLL_OP, $2.i, $3.i, dist);
		  r_type_inst (Y_OR_OP, $2.i, $2.i, 1);
		  free ((imm_expr *)$4.p);
		}


	|	BF_OPS_REV2	F_DEST	F_SRC2	Y_INT	Y_INT
		{
		  mips32_r2_inst ();
		}


	|	SET_LE_POPS	DEST	SRC1	SRC2
		{
		  set_le_inst ($1.i, $2.i, $3.i, $4.i);
		}

	|	SET_LE_POPS	DEST	SRC1	IMM32
		{
		  if (!is_zero_imm ((imm_expr *)$4.p))
		    /* Use $at */
		    i_type_inst (Y_ORI_OP, 1, 0, (imm_expr *)$4.p);
		  set_le_inst ($1.i, $2.i, $3.i,
			       (is_zero_imm ((imm_expr *)$4.p) ? 0 : 1));
		  free ((imm_expr *)$4.p);
		}


	|	SET_GT_POPS	DEST	SRC1	SRC2
		{
		  set_gt_inst ($1.i, $2.i, $3.i, $4.i);
		}

	|	SET_GT_POPS	DEST	SRC1	IMM32
		{
		  if (!is_zero_imm ((imm_expr *)$4.p))
		    /* Use $at */
		    i_type_inst (Y_ORI_OP, 1, 0, (imm_expr *)$4.p);
		  set_gt_inst ($1.i, $2.i, $3.i,
			       (is_zero_imm ((imm_expr *)$4.p) ? 0 : 1));
		  free ((imm_expr *)$4.p);
		}



	|	SET_GE_POPS	DEST	SRC1	SRC2
		{
		  set_ge_inst ($1.i, $2.i, $3.i, $4.i);
		}

	|	SET_GE_POPS	DEST	SRC1	IMM32
		{
		  if (!is_zero_imm ((imm_expr *)$4.p))
		    /* Use $at */
		    i_type_inst (Y_ORI_OP, 1, 0, (imm_expr *)$4.p);
		  set_ge_inst ($1.i, $2.i, $3.i,
			       (is_zero_imm ((imm_expr *)$4.p) ? 0 : 1));
		  free ((imm_expr *)$4.p);
		}


	|	SET_EQ_POPS	DEST	SRC1	SRC2
		{
		  set_eq_inst ($1.i, $2.i, $3.i, $4.i);
		}

	|	SET_EQ_POPS	DEST	SRC1	IMM32
		{
		  if (!is_zero_imm ((imm_expr *)$4.p))
		    /* Use $at */
		    i_type_inst (Y_ORI_OP, 1, 0, (imm_expr *)$4.p);
		  set_eq_inst ($1.i, $2.i, $3.i,
			       (is_zero_imm ((imm_expr *)$4.p) ? 0 : 1));
		  free ((imm_expr *)$4.p);
		}


	|	BR_COP_OPS	LABEL
		{
		  /* RS and RT fields contain information on test */
                  int nd = opcode_is_nullified_branch ($1.i) ? 1 : 0;
                  int tf = opcode_is_true_branch ($1.i) ? 1 : 0;
		  i_type_inst_free ($1.i,
				    cc_to_rt (0, nd, tf),
				    BIN_RS ($1.i),
				    (imm_expr *)$2.p);
		}

	|	BR_COP_OPS	CC_REG	LABEL
		{
		  /* RS and RT fields contain information on test */
                  int nd = opcode_is_nullified_branch ($1.i) ? 1 : 0;
                  int tf = opcode_is_true_branch ($1.i) ? 1 : 0;
		  i_type_inst_free ($1.i,
				    cc_to_rt ($2.i, nd, tf),
				    BIN_RS ($1.i),
				    (imm_expr *)$3.p);
		}


	|	UNARY_BR_OPS	SRC1	LABEL
		{
		  i_type_inst_free ($1.i, 0, $2.i, (imm_expr *)$3.p);
		}


	|	UNARY_BR_POPS	SRC1	LABEL
		{
		  i_type_inst_free ($1.i == Y_BEQZ_POP ? Y_BEQ_OP : Y_BNE_OP,
			       0, $2.i, (imm_expr *)$3.p);
		}


	|	BINARY_BR_OPS	SRC1	SRC2	LABEL
		{
		  i_type_inst_free ($1.i, $3.i, $2.i, (imm_expr *)$4.p);
		}

	|	BINARY_BR_OPS	SRC1	BR_IMM32	LABEL
		{
		  if (bare_machine && !accept_pseudo_insts)
		    yyerror ("Immediate form not allowed in bare machine");
		  else
		    {
		      if (is_zero_imm ((imm_expr *)$3.p))
			i_type_inst ($1.i, $2.i,
				     (is_zero_imm ((imm_expr *)$3.p) ? 0 : 1),
				     (imm_expr *)$4.p);
		      else
			{
			  /* Use $at */
			  i_type_inst (Y_ORI_OP, 1, 0, (imm_expr *)$3.p);
			  i_type_inst ($1.i, $2.i,
				       (is_zero_imm ((imm_expr *)$3.p) ? 0 : 1),
				       (imm_expr *)$4.p);
			}
		    }
		  free ((imm_expr *)$3.p);
		  free ((imm_expr *)$4.p);
		}


	|	BR_GT_POPS	SRC1	SRC2	LABEL
		{
		  r_type_inst ($1.i == Y_BGT_POP ? Y_SLT_OP : Y_SLTU_OP,
			       1, $3.i, $2.i); /* Use $at */
		  i_type_inst_free (Y_BNE_OP, 0, 1, (imm_expr *)$4.p);
		}

	|	BR_GT_POPS	SRC1	BR_IMM32	LABEL
		{
		  if ($1.i == Y_BGT_POP)
		    {
		      /* Use $at */
		      i_type_inst_free (Y_SLTI_OP, 1, $2.i,
					incr_expr_offset ((imm_expr *)$3.p, 1));
		      i_type_inst (Y_BEQ_OP, 0, 1, (imm_expr *)$4.p);
		    }
		  else
		    {
		      /* Use $at */
		      /* Can't add 1 to immediate since 0xffffffff+1 = 0 < 1 */
		      i_type_inst (Y_ORI_OP, 1, 0, (imm_expr *)$3.p);
		      i_type_inst_free (Y_BEQ_OP, $2.i, 1, branch_offset (3));
		      r_type_inst (Y_SLTU_OP, 1, $2.i, 1);
		      i_type_inst (Y_BEQ_OP, 0, 1, (imm_expr *)$4.p);
		    }
		  free ((imm_expr *)$3.p);
		  free ((imm_expr *)$4.p);
		}


	|	BR_GE_POPS	SRC1	SRC2	LABEL
		{
		  r_type_inst ($1.i == Y_BGE_POP ? Y_SLT_OP : Y_SLTU_OP,
			       1, $2.i, $3.i); /* Use $at */
		  i_type_inst_free (Y_BEQ_OP, 0, 1, (imm_expr *)$4.p);
		}

	|	BR_GE_POPS	SRC1	BR_IMM32	LABEL
		{
		  i_type_inst ($1.i == Y_BGE_POP ? Y_SLTI_OP : Y_SLTIU_OP,
			       1, $2.i, (imm_expr *)$3.p); /* Use $at */
		  i_type_inst_free (Y_BEQ_OP, 0, 1, (imm_expr *)$4.p);
		  free ((imm_expr *)$3.p);
		}


	|	BR_LT_POPS	SRC1	SRC2	LABEL
		{
		  r_type_inst ($1.i == Y_BLT_POP ? Y_SLT_OP : Y_SLTU_OP,
			       1, $2.i, $3.i); /* Use $at */
		  i_type_inst_free (Y_BNE_OP, 0, 1, (imm_expr *)$4.p);
		}

	|	BR_LT_POPS	SRC1	BR_IMM32	LABEL
		{
		  i_type_inst ($1.i == Y_BLT_POP ? Y_SLTI_OP : Y_SLTIU_OP,
			       1, $2.i, (imm_expr *)$3.p); /* Use $at */
		  i_type_inst_free (Y_BNE_OP, 0, 1, (imm_expr *)$4.p);
		  free ((imm_expr *)$3.p);
		}


	|	BR_LE_POPS	SRC1	SRC2	LABEL
		{
		  r_type_inst ($1.i == Y_BLE_POP ? Y_SLT_OP : Y_SLTU_OP,
			       1, $3.i, $2.i); /* Use $at */
		  i_type_inst_free (Y_BEQ_OP, 0, 1, (imm_expr *)$4.p);
		}

	|	BR_LE_POPS	SRC1	BR_IMM32	LABEL
		{
		  if ($1.i == Y_BLE_POP)
		    {
		      /* Use $at */
		      i_type_inst_free (Y_SLTI_OP, 1, $2.i,
					incr_expr_offset ((imm_expr *)$3.p, 1));
		      i_type_inst (Y_BNE_OP, 0, 1, (imm_expr *)$4.p);
		    }
		  else
		    {
		      /* Use $at */
		      /* Can't add 1 to immediate since 0xffffffff+1 = 0 < 1 */
		      i_type_inst (Y_ORI_OP, 1, 0, (imm_expr *)$3.p);
		      i_type_inst (Y_BEQ_OP, $2.i, 1, (imm_expr *)$4.p);
		      r_type_inst (Y_SLTU_OP, 1, $2.i, 1);
		      i_type_inst (Y_BNE_OP, 0, 1, (imm_expr *)$4.p);
		    }
		  free ((imm_expr *)$3.p);
		  free ((imm_expr *)$4.p);
		}


	|	J_OPS		LABEL
		{
		  if (($1.i == Y_J_OP) || ($1.i == Y_JR_OP))
		    j_type_inst (Y_J_OP, (imm_expr *)$2.p);
		  else if (($1.i == Y_JAL_OP) || ($1.i == Y_JALR_OP))
		    j_type_inst (Y_JAL_OP, (imm_expr *)$2.p);
		  free ((imm_expr *)$2.p);
		}

	|	J_OPS		SRC1
		{
		  if (($1.i == Y_J_OP) || ($1.i == Y_JR_OP))
		    r_type_inst (Y_JR_OP, 0, $2.i, 0);
		  else if (($1.i == Y_JAL_OP) || ($1.i == Y_JALR_OP))
		    r_type_inst (Y_JALR_OP, 31, $2.i, 0);
		}

	|	J_OPS		DEST	SRC1
		{
		  if (($1.i == Y_J_OP) || ($1.i == Y_JR_OP))
		    r_type_inst (Y_JR_OP, 0, $3.i, 0);
		  else if (($1.i == Y_JAL_OP) || ($1.i == Y_JALR_OP))
		    r_type_inst (Y_JALR_OP, $2.i, $3.i, 0);
		}


	|	B_OPS		LABEL
		{
		  i_type_inst_free (($1.i == Y_BAL_POP ? Y_BGEZAL_OP : Y_BGEZ_OP),
				    0, 0, (imm_expr *)$2.p);
		}


	|	BINARYI_TRAP_OPS	SRC1	IMM16
		{
		  i_type_inst_free ($1.i, 0, $2.i, (imm_expr *)$3.p);
		}


	|	BINARY_TRAP_OPS	SRC1	SRC2
		{
		  r_type_inst ($1.i, 0, $2.i, $3.i);
		}


	|	FP_MOVE_OPS	F_DEST	F_SRC1
		{
		  r_co_type_inst ($1.i, $2.i, $3.i, 0);
		}


	|	FP_MOVE_OPS_REV2 F_DEST	F_SRC1
		{
		  mips32_r2_inst ();
		}


	|	MOVEC_OPS	DEST	SRC1	REG
		{
		  r_type_inst ($1.i, $2.i, $3.i, $4.i);
		}


	|	MOVECC_OPS	DEST	SRC1	Y_INT
		{
                    r_type_inst ($1.i,
                                 $2.i,
                                 $3.i,
                                 (($4.i & 0x7) << 2));
		}


	|	FP_MOVEC_OPS	F_DEST	F_SRC1	REG
		{
		  r_co_type_inst ($1.i, $2.i, $3.i, $4.i);
		}


	|	FP_MOVEC_OPS_REV2 F_DEST	F_SRC1	REG
		{
		  mips32_r2_inst ();
		}


	|	FP_MOVECC_OPS	F_DEST	F_SRC1
		{
		  r_co_type_inst ($1.i, $2.i, $3.i, cc_to_rt (0, 0, 0));
		}


	|	FP_MOVECC_OPS	F_DEST	F_SRC1	CC_REG
		{
		  r_co_type_inst ($1.i, $2.i, $3.i, cc_to_rt ($4.i, 0, 0));
		}


	|	FP_MOVECC_OPS_REV2 F_DEST	F_SRC1	CC_REG
		{
		  mips32_r2_inst ();
		}


	|	MOVE_FROM_HILO_OPS REG
		{
		  r_type_inst ($1.i, $2.i, 0, 0);
		}


	|	MOVE_TO_HILO_OPS REG
		{
		  r_type_inst ($1.i, 0, $2.i, 0);
		}



	|	MOVE_COP_OPS	REG	COP_REG
		{
		  if ($1.i == Y_MFC1_D_POP)
		    {
		      r_co_type_inst (Y_MFC1_OP, 0, $3.i, $2.i);
		      r_co_type_inst (Y_MFC1_OP, 0, $3.i + 1, $2.i + 1);
		    }
		  else if ($1.i == Y_MTC1_D_POP)
		    {
		      r_co_type_inst (Y_MTC1_OP, 0, $3.i, $2.i);
		      r_co_type_inst (Y_MTC1_OP, 0, $3.i + 1, $2.i + 1);
		    }
		  else
		    r_co_type_inst ($1.i, 0, $3.i, $2.i);
		}


	|	MOVE_COP_OPS_REV2 REG	COP_REG
		{
		  mips32_r2_inst ();
		}


	|	CTL_COP_OPS	REG	COP_REG
		{
		  r_co_type_inst ($1.i, 0, $3.i, $2.i);
		}


	|	FP_UNARY_OPS	F_DEST	F_SRC2
		{
		  r_co_type_inst ($1.i, $2.i, $3.i, 0);
		}


	|	FP_UNARY_OPS_REV2 F_DEST	F_SRC2
		{
		  mips32_r2_inst ();
		}


	|	FP_BINARY_OPS	F_DEST	F_SRC1	F_SRC2
		{
		  r_co_type_inst ($1.i, $2.i, $3.i, $4.i);
		}


	|	FP_BINARY_OPS_REV2 F_DEST	F_SRC1	F_SRC2
		{
		  mips32_r2_inst ();
		}


	|	FP_TERNARY_OPS_REV2 F_DEST	F_SRC1	F_SRC2	FP_REGISTER
		{
		  mips32_r2_inst ();
		}


	|	FP_CMP_OPS	F_SRC1	F_SRC2
		{
		  r_cond_type_inst ($1.i, $2.i, $3.i, 0);
		}


	|	FP_CMP_OPS	CC_REG	F_SRC1	F_SRC2
		{
		  r_cond_type_inst ($1.i, $3.i, $4.i, $2.i);
		}


	|	FP_CMP_OPS_REV2	F_SRC1	F_SRC2
		{
		  mips32_r2_inst ();
		}


	|	Y_COP2_OP	IMM32
		{
		  i_type_inst_free ($1.i, 0, 0, (imm_expr *)$2.p);
		}
	;



LOAD_OPS:	Y_LB_OP
	|	Y_LBU_OP
	|	Y_LH_OP
	|	Y_LHU_OP
	|	Y_LL_OP
	|	Y_LW_OP
	|	Y_LWL_OP
	|	Y_LWR_OP
	|	Y_PFW_OP
	|	Y_LD_POP
	;

LOADI_OPS:	Y_LUI_OP
	;

ULOADH_POPS:	Y_ULH_POP
	|	Y_ULHU_POP
	;

LOADC_OPS:	Y_LDC2_OP
	|	Y_LWC2_OP
	;

LOADFP_OPS:	Y_LDC1_OP
	|	Y_LWC1_OP
	|	Y_L_D_POP { $$.i = Y_LDC1_OP; }
	|	Y_L_S_POP { $$.i = Y_LWC1_OP; }
	;

LOADFP_INDEX_OPS:	Y_LDXC1_OP
	|	Y_LUXC1_OP
	|	Y_LWXC1_OP
	;

STORE_OPS:	Y_SB_OP
	|	Y_SC_OP
	|	Y_SH_OP
	|	Y_SW_OP
	|	Y_SWL_OP
	|	Y_SWR_OP
	|	Y_SD_POP
	;

STOREC_OPS:	Y_SWC2_OP
	|	Y_SDC2_OP
	|	Y_S_D_POP { $$.i = Y_SDC1_OP; }
	|	Y_S_S_POP { $$.i = Y_SWC1_OP; }
	;

STOREFP_OPS:	Y_SWC1_OP
	|	Y_SDC1_OP
	;

STOREFP_INDEX_OPS:	Y_SDXC1_OP
	|	Y_SUXC1_OP
	|	Y_SWXC1_OP
	;

SYS_OPS:	Y_RFE_OP
		{
#ifdef MIPS1
			yywarn ("RFE should only be used when SPIM is compiled as a MIPS-I processor");
#endif
		}
	|	Y_SYSCALL_OP
	;

PREFETCH_OPS:	Y_PREFX_OP
	|	Y_SYNCI_OP
	;

CACHE_OPS:	Y_CACHE_OP
	|	Y_PREF_OP
	;

TLB_OPS:	Y_TLBP_OP
	|	Y_TLBR_OP
	|	Y_TLBWI_OP
	|	Y_TLBWR_OP
	;

NULLARY_OPS:	Y_ERET_OP
		{
#ifdef MIPS1
			yywarn ("ERET should only be used when SPIM is compiled as a MIPS32 processor");
#endif
		}
	;

NULLARY_OPS_REV2:	Y_DERET_OP
	|	Y_EHB_OP
	|	Y_SDBBP_OP
	;

COUNT_LEADING_OPS:	Y_CLO_OP
	|	Y_CLZ_OP
	;

UNARY_OPS_REV2:	Y_DI_OP
	|	Y_EI_OP
	;

/* These binary operations have immediate analogues. */

BINARYI_OPS:	Y_ADD_OP
	|	Y_ADDU_OP
	|	Y_AND_OP
	|	Y_XOR_OP
	|	Y_OR_OP
	|	Y_SLT_OP
	|	Y_SLTU_OP
	;

BINARYIR_OPS:	Y_SLLV_OP
	|	Y_SRAV_OP
	|	Y_SRLV_OP
	;

BINARY_ARITHI_OPS:	Y_ADDI_OP
	|	Y_ADDIU_OP
	|	Y_SLTI_OP
	|	Y_SLTIU_OP
	;

BINARY_LOGICALI_OPS:	Y_ANDI_OP
	|	Y_ORI_OP
	|	Y_XORI_OP
	;

SHIFT_OPS:	Y_SLL_OP
	|	Y_SRA_OP
	|	Y_SRL_OP
	;

SHIFT_OPS_REV2:	Y_ROTR_OP
	;

SHIFTV_OPS_REV2:	Y_ROTRV_OP
	;


/* These binary operations do not have immediate analogues. */

BINARY_OPS:	Y_NOR_OP
	;

BINARY_OPS_REV2:	Y_RDHWR_OP
	|	Y_RDPGPR_OP
	|	Y_SEB_OP
	|	Y_SEH_OP
	|	Y_WRPGPR_OP
	|	Y_WSBH_OP
	;

SUB_OPS:	Y_SUB_OP
	|	Y_SUBU_OP
	;

DIV_POPS:	Y_DIV_OP
	|	Y_DIVU_OP
	|	Y_REM_POP
	|	Y_REMU_POP
	;

MUL_POPS:	Y_MULO_POP
	|	Y_MULOU_POP
	;

SET_LE_POPS:	Y_SLE_POP
	|	Y_SLEU_POP
	;

SET_GT_POPS:	Y_SGT_POP
	|	Y_SGTU_POP
	;

SET_GE_POPS:	Y_SGE_POP
	|	Y_SGEU_POP
	;

SET_EQ_POPS:	Y_SEQ_POP
	|	Y_SNE_POP
	;

MULT_OPS:	Y_MULT_OP
	|	Y_MULTU_OP
	|	Y_MADD_OP
	|	Y_MADDU_OP
	|	Y_MSUB_OP
	|	Y_MSUBU_OP
	;

MULT_OPS3: Y_MUL_OP
	;

BF_OPS_REV2:	Y_EXT_OP
	|	Y_INS_OP
	;

BR_COP_OPS:	Y_BC1F_OP
	|	Y_BC1FL_OP
	|	Y_BC1T_OP
	|	Y_BC1TL_OP
	|	Y_BC2F_OP
	|	Y_BC2FL_OP
	|	Y_BC2T_OP
	|	Y_BC2TL_OP
	;

UNARY_BR_OPS:	Y_BGEZ_OP
	|	Y_BGEZL_OP
	|	Y_BGEZAL_OP
	|	Y_BGEZALL_OP
	|	Y_BGTZ_OP
	|	Y_BGTZL_OP
	|	Y_BLEZ_OP
	|	Y_BLEZL_OP
	|	Y_BLTZ_OP
	|	Y_BLTZL_OP
	|	Y_BLTZAL_OP
	|	Y_BLTZALL_OP
	;

UNARY_BR_POPS:	Y_BEQZ_POP
	|	Y_BNEZ_POP
	;

BINARY_BR_OPS:	Y_BEQ_OP
	|	Y_BEQL_OP
	|	Y_BNE_OP
	|	Y_BNEL_OP
	;

BR_GT_POPS:	Y_BGT_POP
	|	Y_BGTU_POP

BR_GE_POPS:	Y_BGE_POP
	|	Y_BGEU_POP

BR_LT_POPS:	Y_BLT_POP
	|	Y_BLTU_POP

BR_LE_POPS:	Y_BLE_POP
	|	Y_BLEU_POP
	;

J_OPS:	Y_J_OP
	|	Y_JR_OP
	|	Y_JR_HB_OP { yywarn ("Warning:IPS32 Rev 2 '.HB' extension is not implemented and is ignored"); }
	|	Y_JAL_OP
	|	Y_JALR_OP
	|	Y_JALR_HB_OP { yywarn ("Warning:IPS32 Rev 2 '.HB' extension is not implemented and is ignored"); }
	;

B_OPS:	Y_B_POP
	|	Y_BAL_POP
	;


BINARYI_TRAP_OPS:	Y_TEQI_OP
	|	Y_TGEI_OP
	|	Y_TGEIU_OP
	|	Y_TLTI_OP
	|	Y_TLTIU_OP
	|	Y_TNEI_OP
	;

BINARY_TRAP_OPS:	Y_TEQ_OP
	|	Y_TGE_OP
	|	Y_TGEU_OP
	|	Y_TLT_OP
	|	Y_TLTU_OP
	|	Y_TNE_OP
	;


MOVE_FROM_HILO_OPS:	Y_MFHI_OP
	|	Y_MFLO_OP
	;

MOVE_TO_HILO_OPS:	Y_MTHI_OP
	|	Y_MTLO_OP
	;

MOVEC_OPS:	Y_MOVN_OP
	|	Y_MOVZ_OP
	;

MOVE_COP_OPS:	Y_MFC0_OP
	|	Y_MFC1_OP
	|	Y_MFC1_D_POP
	|	Y_MFC2_OP
	|	Y_MTC0_OP
	|	Y_MTC1_OP
	|	Y_MTC1_D_POP
	|	Y_MTC2_OP
	;

MOVE_COP_OPS_REV2:	Y_MFHC1_OP
	|	Y_MFHC2_OP
	|	Y_MTHC1_OP
	|	Y_MTHC2_OP
	;

CTL_COP_OPS:	Y_CFC0_OP
	|	Y_CFC1_OP
	|	Y_CFC2_OP
	|	Y_CTC0_OP
	|	Y_CTC1_OP
	|	Y_CTC2_OP
	;

/* Floating point operations */

FP_MOVE_OPS:	Y_MOV_S_OP
	|	Y_MOV_D_OP
	;

FP_MOVE_OPS_REV2:	Y_MOV_PS_OP
	;


MOVECC_OPS:	Y_MOVF_OP
	|	Y_MOVT_OP
	;


FP_MOVEC_OPS:	Y_MOVN_D_OP
	|	Y_MOVN_S_OP
	|	Y_MOVZ_D_OP
	|	Y_MOVZ_S_OP
	;

FP_MOVEC_OPS_REV2:	Y_MOVN_PS_OP
	|	Y_MOVZ_PS_OP
	;


FP_MOVECC_OPS:	Y_MOVF_D_OP
	|	Y_MOVF_S_OP
	|	Y_MOVT_D_OP
	|	Y_MOVT_S_OP
	;

FP_MOVECC_OPS_REV2:	Y_MOVF_PS_OP
	|	Y_MOVT_PS_OP
	;

FP_UNARY_OPS:		Y_ABS_S_OP
	|	Y_ABS_D_OP
	|	Y_CEIL_W_D_OP
	|	Y_CEIL_W_S_OP
	|	Y_CVT_D_S_OP
	|	Y_CVT_D_W_OP
	|	Y_CVT_S_D_OP
	|	Y_CVT_S_W_OP
	|	Y_CVT_W_D_OP
	|	Y_CVT_W_S_OP
	|	Y_FLOOR_W_D_OP
	|	Y_FLOOR_W_S_OP
	|	Y_NEG_S_OP
	|	Y_NEG_D_OP
	|	Y_ROUND_W_D_OP
	|	Y_ROUND_W_S_OP
	|	Y_SQRT_D_OP
	|	Y_SQRT_S_OP
	|	Y_TRUNC_W_D_OP
	|	Y_TRUNC_W_S_OP
	;

FP_UNARY_OPS_REV2:	Y_ABS_PS_OP
	|	Y_CEIL_L_D_OP
	|	Y_CEIL_L_S_OP
	|	Y_CVT_D_L_OP
	|	Y_CVT_L_D_OP
	|	Y_CVT_L_S_OP
	|	Y_CVT_PS_S_OP
	|	Y_CVT_S_L_OP
	|	Y_CVT_S_PL_OP
	|	Y_CVT_S_PU_OP
	|	Y_FLOOR_L_D_OP
	|	Y_FLOOR_L_S_OP
	|	Y_NEG_PS_OP
	|	Y_RECIP_D_OP
	|	Y_RECIP_S_OP
	|	Y_ROUND_L_D_OP
	|	Y_ROUND_L_S_OP
	|	Y_RSQRT_D_OP
	|	Y_RSQRT_S_OP
	|	Y_TRUNC_L_D_OP
	|	Y_TRUNC_L_S_OP
	;

FP_BINARY_OPS:	Y_ADD_S_OP
	|	Y_ADD_D_OP
	|	Y_DIV_S_OP
	|	Y_DIV_D_OP
	|	Y_MUL_S_OP
	|	Y_MUL_D_OP
	|	Y_SUB_S_OP
	|	Y_SUB_D_OP
	;

FP_BINARY_OPS_REV2:	Y_ADD_PS_OP
	|	Y_MUL_PS_OP
	|	Y_PLL_PS_OP
	|	Y_PLU_PS_OP
	|	Y_PUL_PS_OP
	|	Y_PUU_PS_OP
	;

FP_TERNARY_OPS_REV2:	Y_ALNV_PS_OP
	|	Y_MADD_D_OP
	|	Y_MADD_PS_OP
	|	Y_MADD_S_OP
	|	Y_MSUB_D_OP
	|	Y_MSUB_PS_OP
	|	Y_MSUB_S_OP
	|	Y_NMADD_D_OP
	|	Y_NMADD_PS_OP
	|	Y_NMADD_S_OP
	|	Y_NMSUB_D_OP
	|	Y_NMSUB_PS_OP
	|	Y_NMSUB_S_OP
	;

FP_CMP_OPS:	Y_C_F_S_OP
	|	Y_C_UN_S_OP
	|	Y_C_EQ_S_OP
	|	Y_C_UEQ_S_OP
	|	Y_C_OLT_S_OP
	|	Y_C_OLE_S_OP
	|	Y_C_ULT_S_OP
	|	Y_C_ULE_S_OP
	|	Y_C_SF_S_OP
	|	Y_C_NGLE_S_OP
	|	Y_C_SEQ_S_OP
	|	Y_C_NGL_S_OP
	|	Y_C_LT_S_OP
	|	Y_C_NGE_S_OP
	|	Y_C_LE_S_OP
	|	Y_C_NGT_S_OP
	|	Y_C_F_D_OP
	|	Y_C_UN_D_OP
	|	Y_C_EQ_D_OP
	|	Y_C_UEQ_D_OP
	|	Y_C_OLT_D_OP
	|	Y_C_OLE_D_OP
	|	Y_C_ULT_D_OP
	|	Y_C_ULE_D_OP
	|	Y_C_SF_D_OP
	|	Y_C_NGLE_D_OP
	|	Y_C_SEQ_D_OP
	|	Y_C_NGL_D_OP
	|	Y_C_LT_D_OP
	|	Y_C_NGE_D_OP
	|	Y_C_LE_D_OP
	|	Y_C_NGT_D_OP
	;

FP_CMP_OPS_REV2:	Y_C_EQ_PS_OP
	|	Y_C_F_PS_OP
	|	Y_C_LT_PS_OP
	|	Y_C_LE_PS_OP
	|	Y_C_NGE_PS_OP
	|	Y_C_NGL_PS_OP
	|	Y_C_NGLE_PS_OP
	|	Y_C_NGT_PS_OP
	|	Y_C_OLE_PS_OP
	|	Y_C_OLT_PS_OP
	|	Y_C_SEQ_PS_OP
	|	Y_C_SF_PS_OP
	|	Y_C_UEQ_PS_OP
	|	Y_C_ULE_PS_OP
	|	Y_C_ULT_PS_OP
	|	Y_C_UN_PS_OP
	;



ASM_DIRECTIVE:	Y_ALIAS_DIR	Y_REG	Y_REG

	|	Y_ALIGN_DIR	EXPR
		{
		  align_data ($2.i);
		}

	|	Y_ASCII_DIR {null_term = false;}	STR_LST
		{
		  if (text_dir)
		    yyerror ("Can't put data in text segment");
		}

	|	Y_ASCIIZ_DIR {null_term = true;}	STR_LST
		{
		  if (text_dir)
		    yyerror ("Can't put data in text segment");
		}


	|	Y_ASM0_DIR

	|	Y_BGNB_DIR	Y_INT


	|	Y_BYTE_DIR
		{store_op = (void(*)(void*))store_byte;}
		EXPR_LST
		{
		  if (text_dir)
		    yyerror ("Can't put data in text segment");
		}


	|	Y_COMM_DIR	ID	EXPR
		{
		  align_data (2);
		  if (lookup_label ((char*)$2.p)->addr == 0)
		  {
		    (void)record_label ((char*)$2.p, current_data_pc (), 1);
		    free ((char*)$2.p);
		  }
		  increment_data_pc ($3.i);
		}


	|	Y_DATA_DIR
		{user_kernel_data_segment (false);
		  data_dir = true; text_dir = false;
		  enable_data_alignment ();
		}

	|	Y_DATA_DIR	Y_INT
		{
		  user_kernel_data_segment (false);
		  data_dir = true; text_dir = false;
		  enable_data_alignment ();
		  set_data_pc ($2.i);
		}


	|	Y_K_DATA_DIR
		{
                    user_kernel_data_segment (true);
		  data_dir = true; text_dir = false;
		  enable_data_alignment ();
		}

	|	Y_K_DATA_DIR	Y_INT
		{
                    user_kernel_data_segment (true);
		  data_dir = true; text_dir = false;
		  enable_data_alignment ();
		  set_data_pc ($2.i);
		}


	|	Y_DOUBLE_DIR
		{
		  store_op = (void(*)(void*))store_double;
		  if (data_dir) set_data_alignment (3);
		}
		FP_EXPR_LST
		{
		  if (text_dir)
		    yyerror ("Can't put data in text segment");
		}


	|	Y_END_DIR	OPTIONAL_ID

	|	Y_ENDB_DIR	Y_INT

	|	Y_ENDR_DIR

	|	Y_ENT_DIR	ID

	|	Y_ENT_DIR	ID	Y_INT


	|	Y_EXTERN_DIR	ID	EXPR
		{
		  extern_directive ((char*)$2.p, $3.i);
		}


	|	Y_ERR_DIR
		{
		  fatal_error ("File contains an .err directive\n");
		}


	|	Y_FILE_DIR	Y_INT	Y_STR


	|	Y_FLOAT_DIR
		{
		  store_op = (void(*)(void*))store_float;
		  if (data_dir) set_data_alignment (2);
		}
		FP_EXPR_LST
		{
		  if (text_dir)
		    yyerror ("Can't put data in text segment");
		}


	|	Y_FMASK_DIR	Y_INT	Y_INT

	|	Y_FRAME_DIR	REGISTER	Y_INT	REGISTER


	|	Y_GLOBAL_DIR	ID
		{
		  (void)make_label_global ((char*)$2.p);
		  free ((char*)$2.p);
		}


	|	Y_HALF_DIR
		{
		  store_op = (void(*)(void*))store_half;
		  if (data_dir) set_data_alignment (1);
		}
		EXPR_LST
		{
		  if (text_dir)
		    yyerror ("Can't put data in text segment");
		}


	|	Y_LABEL_DIR	ID
		{
		  (void)record_label ((char*)$2.p,
				      text_dir ? current_text_pc () : current_data_pc (),
				      1);
		  free ((char*)$2.p);
		}


	|	Y_LCOMM_DIR	ID	EXPR
		{
		  lcomm_directive ((char*)$2.p, $3.i);
		}


		/* Produced by cc 2.10 */
	|	Y_LIVEREG_DIR	Y_INT	Y_INT


	|	Y_LOC_DIR	Y_INT	Y_INT

	|	Y_MASK_DIR	Y_INT	Y_INT

	|	Y_NOALIAS_DIR	Y_REG	Y_REG

	|	Y_OPTIONS_DIR	ID

	|	Y_REPEAT_DIR	EXPR
		{
		  yyerror ("Warning: repeat directive ignored");
		}


	|	Y_RDATA_DIR
		{
		  user_kernel_data_segment (false);
		  data_dir = true; text_dir = false;
		  enable_data_alignment ();
		}

	|	Y_RDATA_DIR	Y_INT
		{
		  user_kernel_data_segment (false);
		  data_dir = true; text_dir = false;
		  enable_data_alignment ();
		  set_data_pc ($2.i);
		}


	|	Y_SDATA_DIR
		{
		  user_kernel_data_segment (false);
		  data_dir = true; text_dir = false;
		  enable_data_alignment ();
		}

	|	Y_SDATA_DIR	Y_INT
		{
		  user_kernel_data_segment (false);
		  data_dir = true; text_dir = false;
		  enable_data_alignment ();
		  set_data_pc ($2.i);
		}


	|	Y_SET_DIR	ID
		{
		  if (streq ((char*)$2.p, "noat"))
		    noat_flag = true;
		  else if (streq ((char*)$2.p, "at"))
		    noat_flag = false;
		}


	|	Y_SPACE_DIR	EXPR
		{
		  if (data_dir)
		    increment_data_pc ($2.i);
		  else if (text_dir)
		    increment_text_pc ($2.i);
		}


	|	Y_STRUCT_DIR	EXPR
		{
		  yyerror ("Warning: struct directive ignored");
		}


	|	Y_TEXT_DIR
		{
		  user_kernel_text_segment (false);
		  data_dir = false; text_dir = true;
		  enable_data_alignment ();
		}

	|	Y_TEXT_DIR	Y_INT
		{
		  user_kernel_text_segment (false);
		  data_dir = false; text_dir = true;
		  enable_data_alignment ();
		  set_text_pc ($2.i);
		}


	|	Y_K_TEXT_DIR
		{
		  user_kernel_text_segment (true);
		  data_dir = false; text_dir = true;
		  enable_data_alignment ();
		}

	|	Y_K_TEXT_DIR	Y_INT
		{
		  user_kernel_text_segment (true);
		  data_dir = false; text_dir = true;
		  enable_data_alignment ();
		  set_text_pc ($2.i);
		}


	|	Y_VERSTAMP_DIR	Y_INT	Y_INT

	|	Y_VREG_DIR	REGISTER	Y_INT	Y_INT


	|	Y_WORD_DIR
		{
		  store_op = (void(*)(void*))store_word_data;
		  if (data_dir) set_data_alignment (2);
		}
		EXPR_LST

	;



ADDRESS:	{only_id = 1;} ADDR {only_id = 0; $$ = $2;}

ADDR:		'(' REGISTER ')'
		{
		  $$.p = make_addr_expr (0, NULL, $2.i);
		}

	|	ABS_ADDR
		{
		  $$.p = make_addr_expr ($1.i, NULL, 0);
		}

	|	ABS_ADDR '(' REGISTER ')'
		{
		  $$.p = make_addr_expr ($1.i, NULL, $3.i);
		}

	|	Y_ID
		{
		  $$.p = make_addr_expr (0, (char*)$1.p, 0);
		  free ((char*)$1.p);
		}

	|	Y_ID '(' REGISTER ')'
		{
		  $$.p = make_addr_expr (0, (char*)$1.p, $3.i);
		  free ((char*)$1.p);
		}

	|	Y_ID '+' ABS_ADDR
		{
		  $$.p = make_addr_expr ($3.i, (char*)$1.p, 0);
		  free ((char*)$1.p);
		}

	|	ABS_ADDR '+' ID
		{
		  $$.p = make_addr_expr ($1.i, (char*)$3.p, 0);
		}

	|	Y_ID '-' ABS_ADDR
		{
		  $$.p = make_addr_expr (- $3.i, (char*)$1.p, 0);
		  free ((char*)$1.p);
		}

	|	Y_ID '+' ABS_ADDR '(' REGISTER ')'
		{
		  $$.p = make_addr_expr ($3.i, (char*)$1.p, $5.i);
		  free ((char*)$1.p);
		}

	|	Y_ID '-' ABS_ADDR '(' REGISTER ')'
		{
		  $$.p = make_addr_expr (- $3.i, (char*)$1.p, $5.i);
		  free ((char*)$1.p);
		}
	;


BR_IMM32:	{only_id = 1;} IMM32 {only_id = 0; $$ = $2;}

IMM16:	IMM32
		{
                  check_imm_range ((imm_expr*)$1.p, IMM_MIN, IMM_MAX);
		  $$ = $1;
		}

UIMM16:	IMM32
		{
                  check_uimm_range ((imm_expr*)$1.p, UIMM_MIN, UIMM_MAX);
		  $$ = $1;
		}


IMM32:		ABS_ADDR
		{
		  $$.p = make_imm_expr ($1.i, NULL, false);
		}

	|	'(' ABS_ADDR ')' '>' '>' Y_INT
		{
		  $$.p = make_imm_expr ($2.i >> $6.i, NULL, false);
		}

	|	ID
		{
		  $$.p = make_imm_expr (0, (char*)$1.p, false);
		}

	|	Y_ID '+' ABS_ADDR
		{
		  $$.p = make_imm_expr ($3.i, (char*)$1.p, false);
		  free ((char*)$1.p);
		}

	|	Y_ID '-' ABS_ADDR
		{
		  $$.p = make_imm_expr (- $3.i, (char*)$1.p, false);
		  free ((char*)$1.p);
		}
	;


ABS_ADDR:	Y_INT

	|	Y_INT '+' Y_INT
		{$$.i = $1.i + $3.i;}

	|	Y_INT Y_INT
		{
		  /* This is actually: Y_INT '-' Y_INT, since the binary
		     subtract operator gets scanned as a unary negation
		     operator. */
		  if ($2.i >= 0) yyerror ("Syntax error");
		  $$.i = $1.i - -$2.i;
		}
	;

SRC1:		REGISTER ;

SRC2:		REGISTER ;

DEST:		REGISTER ;

REG:		REGISTER ;

REGISTER:	Y_REG
		{
		  if ($1.i < 0 || $1.i > 31)
		    yyerror ("Register number out of range");
		  if ($1.i == 1 && !bare_machine && !noat_flag)
		    yyerror ("Register 1 is reserved for assembler");
		  $$ = $1;
		}

F_DEST:		FP_REGISTER ;

F_SRC1:		FP_REGISTER ;

F_SRC2:		FP_REGISTER ;

FP_REGISTER:	Y_FP_REG
		{
		  if ($1.i < 0 || $1.i > 31)
		    yyerror ("FP register number out of range");
		  $$ = $1;
		}


CC_REG:	       Y_INT
		{
		  if ($1.i < 0 || $1.i > 7)
		    yyerror ("CC register number out of range");
		  $$ = $1;
		}


COP_REG:	Y_REG

	|	Y_FP_REG

	;


LABEL:		ID
		{
		  $$.p = make_imm_expr (-(int)current_text_pc (), (char*)$1.p, true);
		}


STR_LST:	STR_LST STR
	|	STR
	;


STR:		Y_STR
		{
		  store_string ((char*)$1.p, strlen((char*)$1.p), null_term);
		  free ((char*)$1.p);
		}
	|	Y_STR ':' Y_INT
		{
		  int i;

		  for (i = 0; i < $3.i; i ++)
		    store_string ((char*)$1.p, strlen((char*)$1.p), null_term);
		  free ((char*)$1.p);
		}
	;


EXPRESSION:	{only_id = 1;} EXPR {only_id = 0; $$ = $2;}

EXPR:
                TRM
        |
                EXPR '+' TRM
                { $$.i =  $1.i + $3.i; }
        |
                EXPR '-' TRM
                { $$.i =  $1.i - $3.i; }
        ;

TRM:
                FACTOR
        |
                TRM '*' FACTOR
                { $$.i = $1.i * $3.i; }
        |
                TRM '/' FACTOR
                { $$.i = $1.i / $3.i; }
        ;

FACTOR:         Y_INT

        |       '(' EXPR ')'
                { $$.i = $2.i; }

	|	ID
		{
		  label *l = lookup_label ((char*)$1.p);
  		  if (l->addr == 0)
                    {
                      record_data_uses_symbol (current_data_pc (), l);
                      $$.p = NULL;
                    }
                  else
                    $$.i = l->addr;
		}


EXPR_LST:	EXPR_LST	EXPRESSION
		{
		  store_op ($2.p);
		}
	|	EXPRESSION
		{
		  store_op ($1.p);
		}
	|	EXPRESSION ':' EXPR
		{
		  int i;

		  for (i = 0; i < $3.i; i ++)
		    store_op ($1.p);
		}
	;


FP_EXPR_LST:	FP_EXPR_LST Y_FP
		{
		  store_op ($2.p);
		}
	|	Y_FP
		{
		  store_op ($1.p);
		}
	;


OPTIONAL_ID:	{only_id = 1;} OPT_ID {only_id = 0; $$ = $2;}

OPT_ID:		ID
	|	{$$.p = (void*)NULL;}
	;


ID:		{only_id = 1;} Y_ID {only_id = 0; $$ = $2;}


%%

/* Maintain and update the address of labels for the current line. */

void
fix_current_label_address (mem_addr new_addr)
{
  label_list *l;

  for (l = this_line_labels; l != NULL; l = l->tail)
    {
      l->head->addr = new_addr;
    }
  clear_labels ();
}


static label_list *
cons_label (label *head, label_list *tail)
{
  label_list *c = (label_list *) malloc (sizeof (label_list));

  c->head = head;
  c->tail = tail;
  return (c);
}


static void
clear_labels ()
{
  label_list *n;

  for ( ; this_line_labels != NULL; this_line_labels = n)
    {
      resolve_label_uses (this_line_labels->head);
      n = this_line_labels->tail;
      free (this_line_labels);
    }
    this_line_labels = NULL;
}


/* Operations on op codes. */

int
op_to_imm_op (int opcode)
{
  switch (opcode)
    {
    case Y_ADD_OP: return (Y_ADDI_OP);
    case Y_ADDU_OP: return (Y_ADDIU_OP);
    case Y_AND_OP: return (Y_ANDI_OP);
    case Y_OR_OP: return (Y_ORI_OP);
    case Y_XOR_OP: return (Y_XORI_OP);
    case Y_SLT_OP: return (Y_SLTI_OP);
    case Y_SLTU_OP: return (Y_SLTIU_OP);
    case Y_SLLV_OP: return (Y_SLL_OP);
    case Y_SRAV_OP: return (Y_SRA_OP);
    case Y_SRLV_OP: return (Y_SRL_OP);
    default: fatal_error ("Can't convert op to immediate op\n"); return (0);
    }
}


int
imm_op_to_op (int opcode)
{
  switch (opcode)
    {
    case Y_ADDI_OP: return (Y_ADD_OP);
    case Y_ADDIU_OP: return (Y_ADDU_OP);
    case Y_ANDI_OP: return (Y_AND_OP);
    case Y_ORI_OP: return (Y_OR_OP);
    case Y_XORI_OP: return (Y_XOR_OP);
    case Y_SLTI_OP: return (Y_SLT_OP);
    case Y_SLTIU_OP: return (Y_SLTU_OP);
    case Y_J_OP: return (Y_JR_OP);
    case Y_LUI_OP: return (Y_ADDU_OP);
    case Y_SLL_OP: return (Y_SLLV_OP);
    case Y_SRA_OP: return (Y_SRAV_OP);
    case Y_SRL_OP: return (Y_SRLV_OP);
    default: fatal_error ("Can't convert immediate op to op\n"); return (0);
    }
}


static void
nop_inst ()
{
  r_type_inst (Y_SLL_OP, 0, 0, 0); /* = 0 */
}


static void
trap_inst ()
{
  r_type_inst (Y_BREAK_OP, 0, 0, 0);
}


static imm_expr *
branch_offset (int n_inst)
{
  return (const_imm_expr (n_inst << 2)); /* Later shifted right 2 places */
}


static void
div_inst (int op, int rd, int rs, int rt, int const_divisor)
{
  if (rd != 0 && !const_divisor)
    {
      i_type_inst_free (Y_BNE_OP, 0, rt, branch_offset (2));
      trap_inst ();
    }

  if (op == Y_DIV_OP || op == Y_REM_POP)
    r_type_inst (Y_DIV_OP, 0, rs, rt);
  else
    r_type_inst (Y_DIVU_OP, 0, rs, rt);

  if (rd != 0)
    {
      if (op == Y_DIV_OP || op == Y_DIVU_OP)
	/* Quotient */
	r_type_inst (Y_MFLO_OP, rd, 0, 0);
      else
	/* Remainder */
	r_type_inst (Y_MFHI_OP, rd, 0, 0);
    }
}


static void
mult_inst (int op, int rd, int rs, int rt)
{
  if (op == Y_MULOU_POP)
    r_type_inst (Y_MULTU_OP, 0, rs, rt);
  else
    r_type_inst (Y_MULT_OP, 0, rs, rt);
  if (op == Y_MULOU_POP && rd != 0)
    {
      r_type_inst (Y_MFHI_OP, 1, 0, 0);	/* Use $at */
      i_type_inst_free (Y_BEQ_OP, 0, 1, branch_offset (2));
      trap_inst ();
    }
  else if (op == Y_MULO_POP && rd != 0)
    {
      r_type_inst (Y_MFHI_OP, 1, 0, 0); /* use $at */
      r_type_inst (Y_MFLO_OP, rd, 0, 0);
      r_sh_type_inst (Y_SRA_OP, rd, rd, 31);
      i_type_inst_free (Y_BEQ_OP, rd, 1, branch_offset (2));
      trap_inst ();
    }
  if (rd != 0)
    r_type_inst (Y_MFLO_OP, rd, 0, 0);
}


static void
set_le_inst (int op, int rd, int rs, int rt)
{
  i_type_inst_free (Y_BNE_OP, rs, rt, branch_offset (3));
  i_type_inst_free (Y_ORI_OP, rd, 0, const_imm_expr (1));
  i_type_inst_free (Y_BEQ_OP, 0, 0, branch_offset (2));
  r_type_inst ((op == Y_SLE_POP ? Y_SLT_OP : Y_SLTU_OP), rd, rs, rt);
}


static void
set_gt_inst (int op, int rd, int rs, int rt)
{
  r_type_inst (op == Y_SGT_POP ? Y_SLT_OP : Y_SLTU_OP, rd, rt, rs);
}


static void
set_ge_inst (int op, int rd, int rs, int rt)
{
  i_type_inst_free (Y_BNE_OP, rs, rt, branch_offset (3));
  i_type_inst_free (Y_ORI_OP, rd, 0, const_imm_expr (1));
  i_type_inst_free (Y_BEQ_OP, 0, 0, branch_offset (2));
  r_type_inst (op == Y_SGE_POP ? Y_SLT_OP : Y_SLTU_OP, rd, rt, rs);
}


static void
set_eq_inst (int op, int rd, int rs, int rt)
{
  imm_expr *if_eq, *if_neq;

  if (op == Y_SEQ_POP)
    if_eq = const_imm_expr (1), if_neq = const_imm_expr (0);
  else
    if_eq = const_imm_expr (0), if_neq = const_imm_expr (1);

  i_type_inst_free (Y_BEQ_OP, rs, rt, branch_offset (3));
  /* RD <- 0 (if not equal) */
  i_type_inst_free (Y_ORI_OP, rd, 0, if_neq);
  i_type_inst_free (Y_BEQ_OP, 0, 0, branch_offset (2)); /* Branch always */
  /* RD <- 1 */
  i_type_inst_free (Y_ORI_OP, rd, 0, if_eq);
}


/* Store the value either as a datum or instruction. */

static void
store_word_data (int value)
{
  if (data_dir)
    store_word (value);
  else if (text_dir)
    store_instruction (inst_decode (value));
}



void
initialize_parser (char *file_name)
{
  input_file_name = file_name;
  only_id = 0;
  data_dir = false;
  text_dir = true;
}


static void
check_imm_range (imm_expr* expr, int32 min, int32 max)
{
  if (expr->symbol == NULL || SYMBOL_IS_DEFINED (expr->symbol))
    {
      /* If expression can be evaluated, compare its value against the limits
	 and complain if the value is out of bounds. */
      int32 value = eval_imm_expr (expr);

      if (value < min || max < value)
	{
	  char str[200];
	  sprintf (str, "immediate value (%d) out of range (%d .. %d)",
		   value, min, max);
	  yywarn (str);
	}
    }
}


static void
check_uimm_range (imm_expr* expr, uint32 min, uint32 max)
{
  if (expr->symbol == NULL || SYMBOL_IS_DEFINED (expr->symbol))
    {
      /* If expression can be evaluated, compare its value against the limits
	     and complain if the value is out of bounds. */
      uint32 value = (uint32)eval_imm_expr (expr);

      if (value < min || max < value)
	{
	  char str[200];
	  sprintf (str, "immediate value (%d) out of range (%d .. %d)",
		   (int32)value, (int32)min, (int32)max);
	  yywarn (str);
	}
    }
}

void
yyerror (char *s)
{
  parse_error_occurred = true;
  clear_labels ();
  yywarn (s);
}


void
yywarn (char *s)
{
  error ("spim: (parser) %s on line %d of file %s\n%s", s, line_no, input_file_name, erroneous_line ());
}


static void
mips32_r2_inst ()
{
	yyerror ("Warning: MIPS32 Rev 2 instruction is not implemented. Instruction ignored.");
}


static int
cc_to_rt (int cc, int nd, int tf)
{
  return (cc << 2) | (nd << 1) | tf;
}
