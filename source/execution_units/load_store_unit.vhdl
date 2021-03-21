-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : load_store_unit
-- Desc  : This unit will handle the loading and storing instructions.
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

entity LoadStoreUnit is
	port (
		en			: in std_logic;		-- enable the idle unit.
		state		: in CPU_STATE;		-- CPU state
		complete	: out std_logic		-- execution complete.
	);
end LoadStoreUnit;

architecture synth of LoadStoreUnit is

begin
	complete	<= 'Z' when en = '0' else
				   '1' when state = CS_EXECUTE else
				   '0';

end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
