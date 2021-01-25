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
use ieee.numeric_std.all;

use work.definitions.all;

entity SystemRegisters is
		port(
				reset			: in std_logic;		-- reset all the registers.
				sel				: in std_logic;		-- is the register block selected.
				clock			: in std_logic;		-- the clock.
				rw				: in std_logic;		-- are we reading or writing the register.
				reg_address		: in SYSTEM_REG;	-- the address of the register we are writing to.

				data			: inout std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
		);
end SystemRegisters;

architecture synth of SystemRegisters is

		---------------------------------------------------------------
		--- define the registers.
		---------------------------------------------------------------
		type REGISTER_ARRAY is array(0 to NUM_SYSTEM_REGISTERS-1) of std_logic_vector(REG_WIDTH-1 downto 0);
		signal register_bank : REGISTER_ARRAY;
begin

	-- handle the reading an writing of data from the registers.
	data <= register_bank(to_integer(unsigned(reg_address))) when sel='1' and rw=RW_READ and reset='0' else (others => 'Z');
	
	-- latch the data to the registers on write - rising edge of the sel clock
	process (rw, reset, clock, sel, data, reg_address)
	begin
		if reset = '1'
		then
			register_bank(to_integer(unsigned(SR_PROGRAM_COUNTER)))	<= x"00000000";
			register_bank(to_integer(unsigned(SR_STACK_POINTER)))	<= x"0000FFFF";
			register_bank(to_integer(unsigned(SR_INT_TABLE)))		<= x"00000000";
		
		elsif clock'event and clock = '1' and sel = '1' and rw=RW_WRITE
		then
			register_bank(to_integer(unsigned(reg_address))) <= data;
		end if;
	end process;
	
end architecture synth;
