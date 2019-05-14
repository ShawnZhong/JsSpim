/* SPIM S20 MIPS simulator.
   Declarations of registers and code for accessing them.

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


typedef int32 /*@alt unsigned int @*/ reg_word;
typedef uint32 u_reg_word;


/* General purpose registers: */

#define R_LENGTH	32

extern reg_word R[R_LENGTH];

extern reg_word HI, LO;

extern mem_addr PC, nPC;


/* Argument passing registers */

#define REG_V0		2
#define REG_A0		4
#define REG_A1		5
#define REG_A2		6
#define REG_A3		7
#define REG_FA0		12
#define REG_SP		29


/* Result registers */

#define REG_RES		2
#define REG_FRES	0


/* $gp registers */

#define REG_GP		28

extern char *int_reg_names[];



/* Coprocessor registers: */

extern reg_word CCR[4][32], CPR[4][32];



/* Exeception handling registers (Coprocessor 0): */

/* BadVAddr register: */
#define CP0_BadVAddr_Reg 8
#define CP0_BadVAddr	(CPR[0][CP0_BadVAddr_Reg])

/* Count register: */
#define CP0_Count_Reg	9
#define CP0_Count	(CPR[0][CP0_Count_Reg]) /* ToDo */

/* Compare register: */
#define CP0_Compare_Reg	11
#define CP0_Compare	(CPR[0][CP0_Compare_Reg]) /* ToDo */

/* Status register: */
#define CP0_Status_Reg	12
#define CP0_Status	(CPR[0][CP0_Status_Reg])
/* Implemented fields: */
#define CP0_Status_CU	0xf0000000
#define CP0_Status_IM	0x0000ff00
#define CP0_Status_IM7  0x00008000 /* HW Int 5 */
#define CP0_Status_IM6  0x00004000 /* HW Int 4 */
#define CP0_Status_IM5  0x00002000 /* HW Int 3 */
#define CP0_Status_IM4  0x00001000 /* HW Int 2 */
#define CP0_Status_IM3  0x00000800 /* HW Int 1 */
#define CP0_Status_IM2  0x00000400 /* HW Int 0 */
#define CP0_Status_IM1  0x00000200 /* SW Int 1 */
#define CP0_Status_IM0  0x00000100 /* SW Int 0 */
#define CP0_Status_UM	0x00000010
#define CP0_Status_EXL	0x00000002
#define CP0_Status_IE	0x00000001
#define CP0_Status_Mask (CP0_Status_CU		\
			 | CP0_Status_UM	\
			 | CP0_Status_IM	\
			 | CP0_Status_EXL	\
			 | CP0_Status_IE)

/* Cause register: */
#define CP0_Cause_Reg	13
#define CP0_Cause	(CPR[0][CP0_Cause_Reg])
/* Implemented fields: */
#define CP0_Cause_BD	0x80000000
#define CP0_Cause_IP	0x0000ff00
#define CP0_Cause_IP7   0x00008000 /* HW Int 5 */
#define CP0_Cause_IP6   0x00004000 /* HW Int 4 */
#define CP0_Cause_IP5   0x00002000 /* HW Int 3 */
#define CP0_Cause_IP4   0x00001000 /* HW Int 2 */
#define CP0_Cause_IP3   0x00000800 /* HW Int 1 */
#define CP0_Cause_IP2   0x00000400 /* HW Int 0 */
#define CP0_Cause_IP1   0x00000200 /* SW Int 1 */
#define CP0_Cause_IP0   0x00000100 /* SW Int 0 */
#define CP0_Cause_ExcCode 0x0000007c
#define CP0_Cause_Mask	(CP0_Cause_BD		\
			 | CP0_Cause_IP		\
			 | CP0_Cause_IP7	\
			 | CP0_Cause_IP6	\
			 | CP0_Cause_IP5	\
			 | CP0_Cause_IP4	\
			 | CP0_Cause_IP3	\
			 | CP0_Cause_IP2	\
			 | CP0_Cause_ExcCode)
#define CP0_ExCode	((CP0_Cause & CP0_Cause_ExcCode) >> 2)

/* EPC register: */
#define CP0_EPC_Reg	14
#define CP0_EPC		(CPR[0][CP0_EPC_Reg])

/* Config register: */
#define CP0_Config_Reg	16
#define CP0_Config	(CPR[0][CP0_Config_Reg])
/* Implemented fields: */
#define CP0_Config_BE	0x000080000
#define CP0_Config_AT	0x000060000
#define CP0_Config_AR	0x00001c000
#define CP0_Config_MT	0x000000380
#define CP0_Config_Mask (CP0_Config_BE		\
			 | CP0_Config_AT	\
			 | CP0_Config_AR	\
			 | CP0_Config_MT)



/* Floating Point Coprocessor (1) registers.

   This is the MIPS32, Revision 1 FPU register set. It contains 32, 32-bit
   registers (either 32 single or 16 double precision), as in the R2010.
   The MIPS32, Revision 2 or MIPS64 register set has 32 of each type of
   register. */

#define FGR_LENGTH	32
#define FPR_LENGTH	16

extern double *FPR;		/* Dynamically allocate so overlay */
extern float *FGR;		/* is possible */
extern int *FWR;		/* is possible */


#define FPR_S(REGNO)	(FGR[REGNO])

#define FPR_D(REGNO)	(((REGNO) & 0x1) \
			 ? (run_error ("Odd FP double register number\n") , 0.0) \
			 : FPR[(REGNO) / 2])

#define FPR_W(REGNO)	(FWR[REGNO])


#define SET_FPR_S(REGNO, VALUE)	{FGR[REGNO] = (float) (VALUE);}

#define SET_FPR_D(REGNO, VALUE) {if ((REGNO) & 0x1) \
				 run_error ("Odd FP double register number\n"); \
				 else FPR[(REGNO) / 2] = (double) (VALUE);}

#define SET_FPR_W(REGNO, VALUE) {FWR[REGNO] = (int32) (VALUE);}


/* Floating point control registers: */

#define FCR		(CPR[1])


#define FIR_REG		0
#define FIR		(FCR[FIR_REG])
/* Implemented fields: */
#define FIR_W		0x0008000
#define FIR_D		0x0001000
#define FIR_S		0x0000800
#define FIR_MASK	(FIR_W | FIR_D | FIR_S)

#define FCCR_REG	25
#define FCCR		(FCR[FCCR_REG])
/* Implemented fields: */
#define FCCR_FCC	0x000000ff
#define FCCR_MASK	(FCCR_FCC)

#define FEXR_REG	26
#define FEXR		(FCR[FEXR_REG])
/* No implemented fields */

#define FENR_REG	28
#define FENR		(FCR[FENR_REG])
/* No implemented fields */

#define FCSR_REG	31
#define FCSR		(FCR[FCSR_REG])
/* Implemented fields: */
#define FCSR_FCC	0xfe800000
#define FCSR_MASK	(FCSR_FCC)
/* Floating point Cause (not implemented): */
#define FCSR_Cause_E	0x00020000
#define FCSR_Cause_V	0x00010000
#define FCSR_Cause_Z	0x00008000
#define FCSR_Cause_O	0x00004000
#define FCSR_Cause_U	0x00002000
#define FCSR_Cause_I	0x00001000
/* Floating point Enables (not implemented): */
#define FCSR_Enable_V	0x00000800
#define FCSR_Enable_Z	0x00000400
#define FCSR_Enable_O	0x00000200
#define FCSR_Enable_U	0x00000100
#define FCSR_Enable_I	0x00000080
/* Floating point Flags (not implemented): */
#define FCSR_Flag_V	0x00000040
#define FCSR_Flag_Z	0x00000020
#define FCSR_Flag_O	0x00000010
#define FCSR_Flag_U	0x00000008
#define FCSR_Flag_I	0x00000004
