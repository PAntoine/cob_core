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
		(LI_LSR, x"88888888", x"00000001", x"44444444")
	);

end package logic_tb_defines;
--- vi:nocin:sw=4 ts=4:fdm=marker
