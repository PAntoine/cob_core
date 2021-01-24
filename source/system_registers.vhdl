-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--					
--
-- Name  : system_registers
-- Desc  : This entity holds the system registers.
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
use ieee.std_logic_arith.all;

use work.definitions.all;

entity SYS_Registers is
		port(
				reset			: in std_logic;		-- reset all the registers.
				sel				: in std_logic;		-- is the register block selected.
				rw				: in std_logic;		-- are we reading or writing the register.
				reg_address		: in SYSTEM_REG;	-- the address of the register we are writing to.

				data			: inout std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
		);
end SYS_Registers;

architecture synth of SYS_Registers is

		--- Need bus address decoder
		component SYS_Registers) is
			port (
					reset			: in std_logic;									
					sel				: in std_logic;									
					rw				: in std_logic;									
					reg_address		: in SYSTEM_REG;

					data			: inout std_logic_vector(REG_WIDTH-1 downto 0)
				);
		end component;

begin

end architecture;

