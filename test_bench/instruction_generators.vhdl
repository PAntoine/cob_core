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
use ieee.numeric_std.all;

-- temp DEBUG
use STD.textio.all;
use ieee.std_logic_textio.all; 


package instruction_generators is
    ----------------------------------------------------
    --- functions
    ----------------------------------------------------
	function GetNopTestInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE;

end package instruction_generators;

package body instruction_generators is
    ----------------------------------------------------
    --- GetNopTestInstruction
	---
	--- This is just a basic "it's working" test to
	--- run some nops through the the CPU then do a
	--- jump to the next set of tests.
    ----------------------------------------------------
	function GetNopTestInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE is
		variable dout : INSTRUCTION_TYPE;
	begin
		-- report " GNTI (" & unsigned'image(unsigned(a_in(8 downto 0))) & ") failed. expected " & to_hstring(a_in(8 downto 0)) severity warning;

		if unsigned(a_in) < 255
		then
			dout := x"10101010";
		else
			dout := x"20202020";
		end if;
		
		return dout;
	end function;

end instruction_generators;
--- vi:nocin:ai:sw=4 ts=4:fdm=marker
