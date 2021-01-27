-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--					
--
-- Name  : instruction_decoder
-- Desc  : This entity decodes the instructions.
--
-- Author: Peter Antoine
-- Date  : 24/01/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;
use work.instructions.all;

entity InstructionDecoder is
		port(
			clock			: in std_logic;		-- the clock.
			sel				: in std_logic;		-- select the bus controller
			
			instruction_reg	: in std_logic_vector(DATA_WIDTH-1 downto 0);
			sys_bus			: out SYSTEM_BUS	-- the system bus control signals.

		);
end entity InstructionDecoder;

architecture synth of InstructionDecoder is

begin

	process (sel, instruction_reg)
	begin
		if (sel = '1')
		then
			sys_bus <= (others => '0')
		else
			case instruction_reg is
				when XXX 		=> sys_bus <= X;

				when others		=> sys_bus (others => 'Z')	;
			end case;
		end if;
	end process;

end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
