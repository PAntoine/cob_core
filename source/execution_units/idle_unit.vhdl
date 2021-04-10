-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : idle_unit
-- Desc  : This is the IDLE unit that does nothing apart from make sure the
--         the bus signals are all in a safe state.
--
-- Author: Peter Antoine
-- Date  : 21/03/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;

entity IdleUnit is
	port (
		en			: in std_logic;		-- enable the idle unit.
		state		: in CPU_STATE;		-- CPU state
		op_a		: out OPERAND_BUS;	-- Operand A bus controls
		op_b		: out OPERAND_BUS;	-- for B
		write		: out STORE_BUS;	-- controls for writing out the data.
		load_comp	: out std_logic;	-- load complete
		store_comp	: out std_logic;	-- store compete
		complete	: out std_logic		-- execution complete.
	);
end IdleUnit;

architecture synth of IdleUnit is

begin
	process (en, state)
	begin
		if en = '0'
		then
			complete	<= 'Z';
			load_comp	<= 'Z';
			store_comp	<= 'Z';
			write		<= FREE_STORE_BUS;
			op_a		<= FREE_OPERAND_BUS;
			op_b		<= FREE_OPERAND_BUS;

		else
			case state is
				when CS_LOAD =>
						complete	<= '0';
						load_comp	<= '1';
						store_comp	<= '0';
				when CS_EXECUTE	=>
						complete	<= '1';
						load_comp	<= '0';
						store_comp	<= '0';
				when CS_STORE =>
						complete	<= '0';
						load_comp	<= '0';
						store_comp	<= '1';
				when others =>
						complete	<= '0';
						load_comp	<= '0';
						store_comp	<= '0';
			end case;

			write	<= INIT_STORE_BUS;
			op_a	<= INIT_OPERAND_BUS;
			op_b	<= INIT_OPERAND_BUS;
		end if;
	end process;

end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker

