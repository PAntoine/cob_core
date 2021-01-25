-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--					
--
-- Name  : control_unit
-- Desc  : This entity is the control unit for the CPU.
--         This unit does the instruction decoding and will control the other
--         units via the bus control signals.
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

entity ControlUnit is
		port(
			reset			: in std_logic;		-- reset all the registers.
			clock			: in std_logic;		-- the clock.

			sys_bus			: out SYSTEM_BUS	-- the system bus control signals.
		);
end ControlUnit;

architecture synth of ControlUnit is
begin
end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
