----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : instructions
-- Desc  : The instructions for the cob core
--
-- Author: Peter Antoine
-- Date  : 22/01/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package instructions is

	------------------------------------------------------------
	--- General Instruction constants
	------------------------------------------------------------
	constant INSTRUCTION_WIDTH	:	natural := 32;


	------------------------------------------------------------
	--- type definitions for the instructions
	---
	---           3         2         1
	---          10987654321098765432109876543210
	---          -+---------+---------+----------
    ---          UUUOOOOOOOOxxxxxxxxxxxxxxxxxxxxx
    ---
    ---          O = Instruction opcde (IO) 8 bits
    ---          U = Instruction Unit (IU) 3 bits
    ---          x = instruction details - 19 bits
	------------------------------------------------------------
	subtype INSTR_UNIT_RANGE	is natural range 31 downto 29;	-- The instruction units
	subtype INSTR_OPCODE_RANGE	is natural range 28 downto 21;	-- The instruction size
	subtype INSTR_SIZE_RANGE	is natural range 20 downto 19;	-- The opcode

	subtype INSTRUCTION_TYPE 	is std_logic_vector(INSTRUCTION_WIDTH-1 downto 0);

	constant	HALT_INSTR		:	INSTRUCTION_TYPE	:= (others => '0');
	constant	NOP_INSTR		:	INSTRUCTION_TYPE	:= (others => '0');
	constant	BR_INIT_INSTR	:	INSTRUCTION_TYPE	:= (others => '0');	-- branch to the initial program address. TODO

	------------------------------------------------------------
	--- Instruction Unit
	------------------------------------------------------------
	constant	IU_IDLE			:	std_logic_vector(2 downto 0)	:= "000";	--- logic uinit
	constant	IU_LOGIC		:	std_logic_vector(2 downto 0)	:= "001";	--- logic uinit
	constant	IU_CONTROL		:	std_logic_vector(2 downto 0)	:= "010";	--- control unit
	constant	IU_ARITH		:	std_logic_vector(2 downto 0)	:= "011";	--- arithmetic unit
	constant	IU_LOAD_STORE	:	std_logic_vector(2 downto 0)	:= "100";	--- load_store unit
	constant	IU_SYSTEM		:	std_logic_vector(2 downto 0)	:= "101";	--- system unit

	type INSTRUCTION_UNIT_TYPE is record
		idle		: std_logic;
		logic		: std_logic;
		control		: std_logic;
		arith		: std_logic;
		load_store	: std_logic;
		system		: std_logic;
	end record INSTRUCTION_UNIT_TYPE;

	constant	IU_IDLE_SEL			:	INSTRUCTION_UNIT_TYPE	:= ('1','0', '0', '0', '0', '0');
	constant	IU_LOGIC_SEL		:	INSTRUCTION_UNIT_TYPE	:= ('0','1', '0', '0', '0', '0');
	constant	IU_CONTROL_SEL		:	INSTRUCTION_UNIT_TYPE	:= ('0','0', '1', '0', '0', '0');
	constant	IU_ARITH_SEL		:	INSTRUCTION_UNIT_TYPE	:= ('0','0', '0', '1', '0', '0');
	constant	IU_LOAD_STORE_SEL	:	INSTRUCTION_UNIT_TYPE	:= ('0','0', '0', '0', '1', '0');
	constant	IU_SYSTEM_SEL		:	INSTRUCTION_UNIT_TYPE	:= ('0','0', '0', '0', '0', '1');

	------------------------------------------------------------
	--- Logic Instructions
	---
	---           3         2         1
	---          10987654321098765432109876543210
	---          -+---------+---------+----------
    ---          UUUOOOOAABBCCaaaaabbbbbcccccxxxx	-- three operand formats (a op b -> c - and a op imm -> c where imm < 32)
    ---          UUUOOOOAABBCCaaaaaiiiiicccccxxxx	-- three operand formats (and a op imm -> c where imm < 32)
    ---          UUUOOOOAABBaaaaaiiiiiiiiiiiiiiii   -- One operand instruction (a op -> a and a op imm -> a)
	---
	---  UUU   = Unit selector
	---  OOOO  = op code
	---  AA    = operand a address mode
	---  BB    = operand b address mode
	---  CC    = operand c address mode
	---  aaaaa = op_id for instruction operand_a
	---  bbbbb = op_id for instruction operand_b
	---  ccccc = op_id for instruction operand_c
	---
	------------------------------------------------------------

	-- TODO: add range to the end of the names.
	subtype LI_OP_CODE_RANGE	is natural range 28 downto 25;	-- the opcode for the logic instructions.
	subtype LI_OPR_A_MODE		is natural range 24 downto 23;
	subtype LI_OPR_B_MODE		is natural range 22 downto 21;
	subtype LI_OPR_DST_MODE		is natural range 20 downto 19;
	subtype LI_SOURCE_A			is natural range 18 downto 14;	-- Source for A
	subtype LI_SOURCE_B			is natural range 13 downto  9;	-- Source for B (or IMM value for shifts)
	subtype LI_DEST				is natural range  8 downto  4;	-- destination

	subtype LI_SINGLE_A			is natural range 22 downto 18;	-- source for A for single instructions.
	subtype LI_SINGLE_IMM		is natural range 15 downto  0;	-- immediate value

	-- op codes
	subtype LOGIC_OP_CODE_TYPE is std_logic_vector(3 downto 0);
	constant	LI_AND		:	LOGIC_OP_CODE_TYPE	:= "0000";	--- logical and
	constant	LI_OR		:	LOGIC_OP_CODE_TYPE	:= "0001";	--- logical or
	constant	LI_XOR		:	LOGIC_OP_CODE_TYPE	:= "0010";	--- logical xor
	constant	LI_NOT		:	LOGIC_OP_CODE_TYPE	:= "0011";	--- logical not
	constant	LI_LSL		:	LOGIC_OP_CODE_TYPE	:= "0100";	--- logical shift left
	constant	LI_LSR		:	LOGIC_OP_CODE_TYPE	:= "0101";	--- logical shift right
	constant	LI_ROR		:	LOGIC_OP_CODE_TYPE	:= "0110";	--- rotate right
	constant	LI_ROL		:	LOGIC_OP_CODE_TYPE	:= "0111";	--- rotate left
	constant	LI_ASL		:	LOGIC_OP_CODE_TYPE	:= "1000";	--- arithmetic shift left
	constant	LI_ASR		:	LOGIC_OP_CODE_TYPE	:= "1001";	--- arithmetic shift right
	constant	LI_SCL		:	LOGIC_OP_CODE_TYPE	:= "1010";	--- shift with carry left
	constant	LI_SCR		:	LOGIC_OP_CODE_TYPE	:= "1011";	--- shift with carry right
	constant	LI_BT		:	LOGIC_OP_CODE_TYPE	:= "1100";	--- bit test
	constant	LI_BTS		:	LOGIC_OP_CODE_TYPE	:= "1101";	--- bit test and set
	constant	LI_TEST		:	LOGIC_OP_CODE_TYPE	:= "1110";	--- compare op a and op b.

	------------------------------------------------------------
	--- Arithmetic Instructions
	---
	---           3         2         1
	---          10987654321098765432109876543210
	---          -+---------+---------+----------
    ---          UUUOOOOAABBCCaaaaabbbbbcccccxxxx	-- three operand formats (a op b -> c - and a op imm -> c where imm < 32)
    ---          UUUOOOOAABBaaaaaiiiiiiiiiiiiiiii   -- One operand instruction (a op -> a and a op imm -> a)
	---
	---  UUU   = Unit selector
	---  OOOO  = op code
	---  AA    = operand a address mode
	---  BB    = operand b address mode
	---  CC    = operand c address mode
	---  aaaaa = op_id for instruction operand_a
	---  bbbbb = op_id for instruction operand_b
	---  ccccc = op_id for instruction operand_c
	------------------------------------------------------------

	subtype AI_OP_CODE_RANGE	is natural range 28 downto 25;	-- the opcode for the logic instructions.
	subtype AI_OPR_A_MODE		is natural range 24 downto 23;
	subtype AI_OPR_B_MODE		is natural range 22 downto 21;
	subtype AI_OPR_DST_MODE		is natural range 20 downto 19;
	subtype AI_SOURCE_A			is natural range 18 downto 14;	-- Source for A
	subtype AI_SOURCE_B			is natural range 13 downto  9;	-- Source for B (or IMM value for shifts)
	subtype AI_DEST				is natural range  8 downto  4;	-- destination

	subtype AI_SINGLE_A			is natural range 22 downto 18;	-- source for A for single instructions.
	subtype AI_SINGLE_IMM		is natural range 15 downto  0;	-- immediate value

	-- op codes
	subtype ARITH_OP_CODE_TYPE is std_logic_vector(3 downto 0);
	constant	AI_INC		: ARITH_OP_CODE_TYPE	:= "0000";	--- add
	constant	AI_DEC		: ARITH_OP_CODE_TYPE	:= "0001";	--- add
	constant	AI_ADD		: ARITH_OP_CODE_TYPE	:= "0010";	--- add
	constant	AI_ADC		: ARITH_OP_CODE_TYPE	:= "0011";	--- add with carry
	constant	AI_SUB		: ARITH_OP_CODE_TYPE	:= "0100";	--- subtract
	constant	AI_SBC		: ARITH_OP_CODE_TYPE	:= "0101";	--- subtract with carry
	constant	AI_MUL		: ARITH_OP_CODE_TYPE	:= "0110";	--- logical not
	constant	AI_DIV		: ARITH_OP_CODE_TYPE	:= "0111";	--- logical neg
	constant	AI_MOD		: ARITH_OP_CODE_TYPE	:= "1000";	--- logical test

	------------------------------------------------------------
	--- Control Instructions
	---
	---           3         2         1
	---          10987654321098765432109876543210
	---          -+---------+---------+----------
    ---          UUUmmOOOOxxxxxxxxxxxxxxxxxxxxxxx
	---
	---    Address Mode |
	---     mm = mode   |  Meaning of X
	---   --------------+--------------------------------------------
	---         00      | Immediate 		 iiiiiiiiiiiiiiiiiiiiiii
	---         01      | Immediate relative siiiiiiiiiiiiiiiiiiiiii
	---         10		| Register Direct	 xxxxxxxxxxxxxxxxxxRRRRR
	---         11		| Register Indirect	 xxxxxxxxxxxxxxxxxxRRRRR
	---
	------------------------------------------------------------
	subtype CI_AM_MODE	is natural range 28 downto 27;	-- Address mode

	subtype CONTROL_OP_CODE_TYPE		is std_logic_vector(3 downto 0);
	subtype CONTROL_AM_RANGE			is natural range 28 downto 27;
	subtype CONTROL_OPCODE_RANGE		is natural range 26 downto 23;
	subtype CONTROL_IMMED_RANGE			is natural range 22 downto 0;
	subtype CONTROL_REG_ID_RANGE		is natural range 4 downto 0;

	constant	CI_NOP			:	CONTROL_OP_CODE_TYPE	:= "0000";	--- do nothing.
	constant	CI_BRANCH		:	CONTROL_OP_CODE_TYPE	:= "0001";	--- branch always
	constant	CI_BRANCH_LE	:	CONTROL_OP_CODE_TYPE	:= "0010";	--- branch if less than or equal
	constant	CI_BRANCH_LT	:	CONTROL_OP_CODE_TYPE	:= "0011";	--- branch if less than
	constant	CI_BRANCH_GE	:	CONTROL_OP_CODE_TYPE	:= "0100";	--- branch if greater than or equal
	constant	CI_BRANCH_GT	:	CONTROL_OP_CODE_TYPE	:= "0101";	--- branch if greater then
	constant	CI_BRANCH_EQ	:	CONTROL_OP_CODE_TYPE	:= "0110";	--- branch if equal
	constant	CI_BRANCH_NE	:	CONTROL_OP_CODE_TYPE	:= "0111";	--- branch if not equal
	constant	CI_CALL			:	CONTROL_OP_CODE_TYPE	:= "1000";	--- jump subroutine
	constant	CI_RETURN		:	CONTROL_OP_CODE_TYPE	:= "1001";	--- return from subroutine.
	constant	CI_INT			:	CONTROL_OP_CODE_TYPE	:= "1010";	--- cause interrupt
	constant	CI_RETI			:	CONTROL_OP_CODE_TYPE	:= "1011";	--- return from interrupt

	------------------------------------------------------------
	--- Load Store Instructions
	---
	---           3         2         1
	---          10987654321098765432109876543210
	---          -+---------+---------+----------
    ---          UUUOOMMMMAAAAABBBBBxxxxxxxxxxxxx	move		-- move
    ---          UUUOOMMMMAAAAAiiiiiiiiiiiiiiiiii	moveimm		-- move immediate
    ---          UUUOOMMMMAAAAASSS000000000000000	movesys		-- move sys to/from system register
    ---          UUUOOMMMMSSSiiiiiiiiiiiiiiiiiiii	movesysimm	-- move sys to/from immediate
	---
	--- Address Mode  | Source            | Destination
	--- --------------+-------------------+-------------------
	---   00 00       | Register          | Register
	---   00 01       | Register          | Register-Indirect
	---   00 10       | Register          | Immediate
	---   01 00       | Register-Indirect | Register
	---   01 10       | Register-Indirect | Register-Indirect
	---   01 01       | Register-Indirect | Immediate
	---   10 00       | Immediate         | Register
	---   10 01       | Immediate         | Register-Indirect
	---
	------------------------------------------------------------
	-- TODO: tidy this up -- sort out the source and destination stuff.

	subtype LOAD_STORE_OPCODE_RANGE			is natural range 28 downto 27;
	subtype LOAD_STORE_ADDR_MODE_SRC_RANGE	is natural range 26 downto 25;
	subtype LOAD_STORE_ADDR_MODE_DST_RANGE	is natural range 24 downto 23;
	subtype	LOAD_STORE_OPERAND_A_RANGE		is natural range 22 downto 18;
	subtype	LOAD_STORE_OPERAND_B_RANGE		is natural range 17 downto 13;
	subtype	LOAD_STORE_OPERAND_C_RANGE		is natural range 12 downto 08;
	subtype	LOAD_STORE_SYSREG_ID_RANGE		is natural range 22 downto 20;
	subtype	LOAD_STORE_IMMED_18_RANGE		is natural range 17 downto 0;
	subtype	LOAD_STORE_IMMED_20_RANGE		is natural range 19 downto 0;

	subtype LOAD_STORE_OPCODE_TYPE is std_logic_vector(1 downto 0);
	constant	LS_MOVE			:	std_logic_vector(1 downto 0)	:= "00";	--- Memory to load_store
	constant	LS_MOVE_IMM		:	std_logic_vector(1 downto 0)	:= "01";	--- Memory to register
	constant	LS_MOVE_SYS		:	std_logic_vector(1 downto 0)	:= "10";	--- Memory to register
	constant	LS_MOVE_SYS_IMM	:	std_logic_vector(1 downto 0)	:= "11";	--- Memory to register

end package instructions;
--- vi:nocin:sw=4 ts=4:fdm=marker
