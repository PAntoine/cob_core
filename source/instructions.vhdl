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
	constant INSTRUCTION_WIDTH :	natural := 32;

	------------------------------------------------------------
	--- type definitions for the instructions
	---
	---           3         2         1         
	---          10987654321098765432109876543210
	---          -+---------+---------+----------
    ---          OOOOOOOOUUUxxxxxxxxxxxxxxxxxxxxx
    ---        
    ---          O = Instruction opcde (IO) 8 bits
    ---          U = Instruction Unit (IU) 3 bits
    ---          x = instruction details - 19 bits
	------------------------------------------------------------
	subtype instruction is std_logic_vector(INSTRUCTION_WIDTH-1 downto 0);
	
	subtype INSTR_OPCODE_RANGE	is natural range 31 downto 24;	-- The instruction size
	subtype INSTR_UNIT_RANGE	is natural range 23 downto 21;	-- The instruction units
	subtype INSTR_SIZE_RANGE	is natural range 20 downto 19;	-- The opcode

	------------------------------------------------------------
	--- Instruction Unit
	------------------------------------------------------------
	constant	IU_LOGIC	:	std_logic_vector(2 downto 0)	:= "000";	--- logic uinit
	constant	IU_CONTROL	:	std_logic_vector(2 downto 0)	:= "001";	--- control unit
	constant	IU_ARITH	:	std_logic_vector(2 downto 0)	:= "010";	--- arithmetic unit
	constant	IU_MEMORY	:	std_logic_vector(2 downto 0)	:= "011";	--- memory unit

	------------------------------------------------------------
	--- Logic Instructions
	---
	---           3         2         1         
	---          10987654321098765432109876543210
	---          -+---------+---------+----------
    ---          OOOOOOOOUUURRRxxxxxxxxxxxxxxxxxx
	---
	--- R - Register or Memory
	--- 1 - register Address (5 bits - 32 registers)
	--- 2 - register Address (5 bits - 32 registers)
	--- o - register Address (5 bits - 32 registers)
	--- i - immediate value
	---
	---    Code |  a  |  b  | Meaning of X
	---   ------+--------------------------------------
	---    000  | reg | reg |  1111122222ooooo000
	---    001  | mem | reg |  mmmmm22222ooooo000
	---    010  | reg | mem |  11111mmmmmooooo000
	---    011  | reg |  -  |  111110000000000000
	---    100  | reg |imm8 |  11111iiiiiooooo000
	---
	------------------------------------------------------------
	subtype LI_IO_CODE	is natural range 20 downto 18;	-- The import states
	subtype LI_SOURCE_A	is natural range 17 downto 13;	-- Source for A
	subtype LI_SOURCE_B	is natural range 12 downto 08;	-- Source for B
	subtype LI_DEST		is natural range  7 downto  8;	-- destination

	constant	LI_AND		:	std_logic_vector(7 downto 0)	:= "00000001";	--- logical and
	constant	LI_OR		:	std_logic_vector(7 downto 0)	:= "00000010";	--- logical or
	constant	LI_XOR		:	std_logic_vector(7 downto 0)	:= "00000011";	--- logical xor
	constant	LI_NOT		:	std_logic_vector(7 downto 0)	:= "00000100";	--- logical not
	constant	LI_NEG		:	std_logic_vector(7 downto 0)	:= "00000101";	--- logical neg
	constant	LI_LSL		:	std_logic_vector(7 downto 0)	:= "00000110";	--- logical shift left
	constant	LI_LSR		:	std_logic_vector(7 downto 0)	:= "00000111";	--- logical shift right
	constant	LI_ROT		:	std_logic_vector(7 downto 0)	:= "00001000";	--- rotate right
	constant	LI_ROL		:	std_logic_vector(7 downto 0)	:= "00001001";	--- rotate left
	
	------------------------------------------------------------
	--- Arithmetic Instructions
	------------------------------------------------------------
	constant	AI_ADD		:	std_logic_vector(7 downto 0)	:= "00000001";	--- add
	constant	AI_ADC		:	std_logic_vector(7 downto 0)	:= "00000010";	--- add with carry
	constant	AI_SUB		:	std_logic_vector(7 downto 0)	:= "00000011";	--- subtract
	constant	AI_SBC		:	std_logic_vector(7 downto 0)	:= "00000100";	--- subtract with carry
	constant	AI_MUL		:	std_logic_vector(7 downto 0)	:= "00000101";	--- logical not
	constant	AI_DIV		:	std_logic_vector(7 downto 0)	:= "00000110";	--- logical neg
	constant	AI_TEST		:	std_logic_vector(7 downto 0)	:= "00000111";	--- logical test
	
	------------------------------------------------------------
	--- Control Instructions
	------------------------------------------------------------
	constant	CI_BRANCH		:	std_logic_vector(7 downto 0)	:= "00000001";	--- branch always
	constant	CI_BRANCH_LE	:	std_logic_vector(7 downto 0)	:= "00000010";	--- branch if less than or equal
	constant	CI_BRANCH_LT	:	std_logic_vector(7 downto 0)	:= "00000011";	--- branch if less than
	constant	CI_BRANCH_GE	:	std_logic_vector(7 downto 0)	:= "00000100";	--- branch if greater than or equal
	constant	CI_BRANCH_GT	:	std_logic_vector(7 downto 0)	:= "00000101";	--- branch if greater then
	constant	CI_BRANCH_EQ	:	std_logic_vector(7 downto 0)	:= "00000110";	--- branch if equal
	constant	CI_BRANCH_NE	:	std_logic_vector(7 downto 0)	:= "00000111";	--- branch if not equal
	constant	CI_CALL			:	std_logic_vector(7 downto 0)	:= "00001000";	--- jump subroutine
	constant	CI_RETURN		:	std_logic_vector(7 downto 0)	:= "00001001";	--- return from subroutine.
	constant	CI_INT			:	std_logic_vector(7 downto 0)	:= "00001010";	--- cause interrupt
	constant	CI_RETI			:	std_logic_vector(7 downto 0)	:= "00001011";	--- return from interrupt

	------------------------------------------------------------
	--- Memory Instructions
	------------------------------------------------------------
	constant	MI_MOVE_MEM		:	std_logic_vector(7 downto 0)	:= "00000001";	--- Memory to memory
	constant	MI_MOVE_REG		:	std_logic_vector(7 downto 0)	:= "00000010";	--- Memory to register
	constant	MI_MOVE_SYS		:	std_logic_vector(7 downto 0)	:= "00000011";	--- Memory to system register
	constant	MI_LOAD			:	std_logic_vector(7 downto 0)	:= "00000100";	--- move memory to register
	constant	MI_STORE		:	std_logic_vector(7 downto 0)	:= "00000101";	--- move register to memory

end package instructions;
--- vi:nocin:sw=4 ts=4:fdm=marker

