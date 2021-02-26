----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : logic_tb_defines
-- Desc  : The logic test bed defines.
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
use work.definitions.all;
use work.instructions.all;

package logic_tb_defines is
	---------------------------------------------------------------
	--- Test structures
	---------------------------------------------------------------
	type TEST_CASE_TYPE is record
		opcode	:	std_logic_vector(OP_CODE_WIDTH-1 downto 0);
		a_input	:	std_logic_vector(DATA_WIDTH-1 downto 0);
		b_input :	std_logic_vector(DATA_WIDTH-1 downto 0);
		output	:	std_logic_vector(DATA_WIDTH-1 downto 0);
	end record TEST_CASE_TYPE;
	
	type TEST_CASE_ARRAY is array(integer range <>) of TEST_CASE_TYPE;

	---------------------------------------------------------------
	--- Test Cases
	---------------------------------------------------------------
	constant R_R_test_cases : TEST_CASE_ARRAY :=
	(
		(LI_NOT, x"FFFFFFFF", x"00000000", x"00000000"),
		(LI_NOT, x"FFFFFFFF", x"FFFFFFFF", x"00000000"),
		(LI_NOT, x"00000000", x"00000000", x"FFFFFFFF"),
		(LI_NOT, x"00000000", x"FFFFFFFF", x"FFFFFFFF")
	);

	constant lsl_test_cases : TEST_CASE_ARRAY := 
	(
		(LI_LSL, x"FFFFFFFF", x"00000001", x"FFFFFFFE"),
		(LI_LSL, x"FFFFFFFF", x"00000002", x"FFFFFFFC"),
		(LI_LSL, x"FFFFFFFF", x"00000003", x"FFFFFFF8"),
		(LI_LSL, x"FFFFFFFF", x"00000004", x"FFFFFFF0"),
		(LI_LSL, x"FFFFFFFF", x"00000008", x"FFFFFF00"),
		(LI_LSL, x"FFFFFFFF", x"00000010", x"FFFF0000"),
		(LI_LSL, x"FFFFFFFF", x"0000001F", x"80000000"),
		(LI_LSL, x"80000000", x"00000001", x"00000000"),
		(LI_LSL, x"11111111", x"00000001", x"22222222"),
		(LI_LSL, x"88888888", x"00000001", x"11111110"),
		(LI_LSR, x"FFFFFFFF", x"00000001", x"7FFFFFFF"),
		(LI_LSR, x"FFFFFFFF", x"00000002", x"3FFFFFFF"),
		(LI_LSR, x"FFFFFFFF", x"00000003", x"1FFFFFFF"),
		(LI_LSR, x"FFFFFFFF", x"00000004", x"0FFFFFFF"),
		(LI_LSR, x"FFFFFFFF", x"00000010", x"0000FFFF"),
		(LI_LSR, x"FFFFFFFF", x"0000001F", x"00000001"),
		(LI_LSR, x"00000001", x"00000001", x"00000000"),
		(LI_LSR, x"11111111", x"00000001", x"08888888"),
		(LI_LSR, x"88888888", x"00000001", x"44444444"),
		(LI_AND, x"11111111", x"11111111", x"11111111"),
		(LI_AND, x"22222222", x"22222222", x"22222222"),
		(LI_AND, x"44444444", x"44444444", x"44444444"),
		(LI_AND, x"88888888", x"88888888", x"88888888"),
		(LI_AND, x"11111111", x"FFFFFFFF", x"11111111"),
		(LI_AND, x"22222222", x"FFFFFFFF", x"22222222"),
		(LI_AND, x"44444444", x"FFFFFFFF", x"44444444"),
		(LI_AND, x"88888888", x"FFFFFFFF", x"88888888"),
		(LI_AND, x"11111111", x"00000000", x"00000000"),
		(LI_AND, x"22222222", x"00000000", x"00000000"),
		(LI_AND, x"44444444", x"00000000", x"00000000"),
		(LI_AND, x"88888888", x"00000000", x"00000000"),
		(LI_AND, x"00000000", x"11111111", x"00000000"),
		(LI_AND, x"00000000", x"22222222", x"00000000"),
		(LI_AND, x"00000000", x"44444444", x"00000000"),
		(LI_AND, x"00000000", x"88888888", x"00000000"),
		(LI_AND, x"00000000", x"88888888", x"00000000"),
		(LI_AND, x"00000000", x"88888888", x"00000000"),
		(LI_AND, x"FFFFFFFF", x"FFFFFFFF", x"FFFFFFFF"),
		(LI_AND, x"00000000", x"00000000", x"00000000"),
		(LI_OR,	 x"11111111", x"22222222", x"33333333"),
		(LI_OR,	 x"44444444", x"88888888", x"cccccccc"),
		(LI_OR,  x"cccccccc", x"33333333", x"ffffffff"),
		(LI_OR,  x"00000000", x"ffffffff", x"ffffffff"),
		(LI_OR,  x"00000000", x"00000000", x"00000000"),
		(LI_XOR, x"FFFFFFFF", x"00000000", x"FFFFFFFF"),
		(LI_XOR, x"FFFFFFFF", x"FFFFFFFF", x"00000000"),
		(LI_XOR, x"00000000", x"FFFFFFFF", x"FFFFFFFF"),
		(LI_XOR, x"00000000", x"00000000", x"00000000"),
		(LI_NOT, x"FFFFFFFF", x"00000000", x"00000000"),
		(LI_NOT, x"FFFFFFFF", x"FFFFFFFF", x"00000000"),
		(LI_NOT, x"00000000", x"00000000", x"FFFFFFFF"),
		(LI_NOT, x"00000000", x"FFFFFFFF", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000001", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000002", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000003", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000004", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000008", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000010", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"0000001F", x"FFFFFFFF"),
		(LI_ROL, x"00000001", x"00000001", x"00000002"),
		(LI_ROL, x"00000001", x"00000002", x"00000004"),
		(LI_ROL, x"00000001", x"00000003", x"00000008"),
		(LI_ROL, x"00000001", x"00000004", x"00000010"),
		(LI_ROL, x"00000001", x"00000008", x"00000100"),
		(LI_ROL, x"00000001", x"00000010", x"00010000"),
		(LI_ROL, x"00000001", x"0000001F", x"80000000"),
		(LI_ROL, x"80000000", x"00000001", x"00000001"),
		(LI_ROL, x"11111111", x"00000001", x"22222222"),
		(LI_ROL, x"88888888", x"00000001", x"11111111"),
		(LI_ROR, x"FFFFFFFF", x"00000001", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"00000002", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"00000003", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"00000004", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"00000008", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"00000010", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"0000001F", x"FFFFFFFF"),
		(LI_ROR, x"00000001", x"00000001", x"80000000"),
		(LI_ROR, x"00000001", x"00000002", x"40000000"),
		(LI_ROR, x"00000001", x"00000003", x"20000000"),
		(LI_ROR, x"00000001", x"00000004", x"10000000"),
		(LI_ROR, x"00000001", x"00000008", x"01000000"),
		(LI_ROR, x"00000001", x"00000010", x"00010000"),
		(LI_ROR, x"00000001", x"0000001F", x"00000002"),
		(LI_ROR, x"80000000", x"00000001", x"40000000"),
		(LI_ROR, x"11111111", x"00000001", x"88888888"),
		(LI_ROR, x"88888888", x"00000001", x"44444444")
	);

	constant immed_test_cases : TEST_CASE_ARRAY := 
	(
		(LI_LSL, x"FFFFFFFF", x"00000001", x"FFFFFFFE"),
		(LI_LSL, x"FFFFFFFF", x"00000002", x"FFFFFFFC"),
		(LI_LSL, x"FFFFFFFF", x"00000003", x"FFFFFFF8"),
		(LI_LSL, x"FFFFFFFF", x"00000004", x"FFFFFFF0"),
		(LI_LSL, x"FFFFFFFF", x"00000008", x"FFFFFF00"),
		(LI_LSL, x"FFFFFFFF", x"00000010", x"FFFF0000"),
		(LI_LSL, x"FFFFFFFF", x"0000001F", x"80000000"),
		(LI_LSL, x"80000000", x"00000001", x"00000000"),
		(LI_LSL, x"11111111", x"00000001", x"22222222"),
		(LI_LSL, x"88888888", x"00000001", x"11111110"),
		(LI_LSR, x"FFFFFFFF", x"00000001", x"7FFFFFFF"),
		(LI_LSR, x"FFFFFFFF", x"00000002", x"3FFFFFFF"),
		(LI_LSR, x"FFFFFFFF", x"00000003", x"1FFFFFFF"),
		(LI_LSR, x"FFFFFFFF", x"00000004", x"0FFFFFFF"),
		(LI_LSR, x"FFFFFFFF", x"00000010", x"0000FFFF"),
		(LI_LSR, x"FFFFFFFF", x"0000001F", x"00000001"),
		(LI_LSR, x"00000001", x"00000001", x"00000000"),
		(LI_LSR, x"11111111", x"00000001", x"08888888"),
		(LI_LSR, x"88888888", x"00000001", x"44444444"),
		(LI_AND, x"11111111", x"00001111", x"00000011"),
		(LI_AND, x"22222222", x"00002222", x"00000022"),
		(LI_AND, x"44444444", x"00004444", x"00000044"),
		(LI_AND, x"88888888", x"00008888", x"00000088"),
		(LI_AND, x"11111111", x"0000FFFF", x"00000011"),
		(LI_AND, x"22222222", x"0000FFFF", x"00000022"),
		(LI_AND, x"44444444", x"0000FFFF", x"00000044"),
		(LI_AND, x"88888888", x"0000FFFF", x"00000088"),
		(LI_AND, x"11111111", x"00000000", x"00000000"),
		(LI_AND, x"22222222", x"00000000", x"00000000"),
		(LI_AND, x"44444444", x"00000000", x"00000000"),
		(LI_AND, x"88888888", x"00000000", x"00000000"),
		(LI_AND, x"00000000", x"00001111", x"00000000"),
		(LI_AND, x"00000000", x"00002222", x"00000000"),
		(LI_AND, x"00000000", x"00004444", x"00000000"),
		(LI_AND, x"00000000", x"00008888", x"00000000"),
		(LI_AND, x"00000000", x"00008888", x"00000000"),
		(LI_AND, x"00000000", x"00008888", x"00000000"),
		(LI_AND, x"FFFFFFFF", x"0000FFFF", x"000000FF"),
		(LI_AND, x"00000000", x"00000000", x"00000000"),
		(LI_OR,	 x"11111111", x"00002222", x"11111133"),
		(LI_OR,	 x"44444444", x"00008888", x"444444cc"),
		(LI_OR,  x"cccccccc", x"00003333", x"ccccccff"),
		(LI_OR,  x"00000000", x"0000ffff", x"000000ff"),
		(LI_OR,  x"00000000", x"00000000", x"00000000"),
		(LI_XOR, x"FFFFFFFF", x"00000000", x"FFFFFFFF"),
		(LI_XOR, x"FFFFFFFF", x"0000FFFF", x"FFFFFF00"),
		(LI_XOR, x"00000000", x"0000FFFF", x"000000FF"),
		(LI_XOR, x"00000000", x"00000000", x"00000000"),
		(LI_NOT, x"FFFFFFFF", x"00000000", x"00000000"),
		(LI_NOT, x"FFFFFFFF", x"0000FFFF", x"00000000"),
		(LI_NOT, x"00000000", x"00000000", x"FFFFFFFF"),
		(LI_NOT, x"00000000", x"0000FFFF", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000001", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000002", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000003", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000004", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000008", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"00000010", x"FFFFFFFF"),
		(LI_ROL, x"FFFFFFFF", x"0000001F", x"FFFFFFFF"),
		(LI_ROL, x"00000001", x"00000001", x"00000002"),
		(LI_ROL, x"00000001", x"00000002", x"00000004"),
		(LI_ROL, x"00000001", x"00000003", x"00000008"),
		(LI_ROL, x"00000001", x"00000004", x"00000010"),
		(LI_ROL, x"00000001", x"00000008", x"00000100"),
		(LI_ROL, x"00000001", x"00000010", x"00010000"),
		(LI_ROL, x"00000001", x"0000001F", x"80000000"),
		(LI_ROL, x"80000000", x"00000001", x"00000001"),
		(LI_ROL, x"11111111", x"00000001", x"22222222"),
		(LI_ROL, x"88888888", x"00000001", x"11111111"),
		(LI_ROR, x"FFFFFFFF", x"00000001", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"00000002", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"00000003", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"00000004", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"00000008", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"00000010", x"FFFFFFFF"),
		(LI_ROR, x"FFFFFFFF", x"0000001F", x"FFFFFFFF"),
		(LI_ROR, x"00000001", x"00000001", x"80000000"),
		(LI_ROR, x"00000001", x"00000002", x"40000000"),
		(LI_ROR, x"00000001", x"00000003", x"20000000"),
		(LI_ROR, x"00000001", x"00000004", x"10000000"),
		(LI_ROR, x"00000001", x"00000008", x"01000000"),
		(LI_ROR, x"00000001", x"00000010", x"00010000"),
		(LI_ROR, x"00000001", x"0000001F", x"00000002"),
		(LI_ROR, x"80000000", x"00000001", x"40000000"),
		(LI_ROR, x"11111111", x"00000001", x"88888888"),
		(LI_ROR, x"88888888", x"00000001", x"44444444")
	);

end package logic_tb_defines;
--- vi:nocin:sw=4 ts=4:fdm=marker
