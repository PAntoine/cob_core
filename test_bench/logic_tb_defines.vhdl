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
		flags	:	CPU_FLAGS;
	end record TEST_CASE_TYPE;

end package logic_tb_defines;
--- vi:nocin:sw=4 ts=4:fdm=marker
