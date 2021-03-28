-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--					
--
-- Name  : registers
-- Desc  : This file defines the registers for the cob project.
--
--         This register block can be read/write to via port 1 (reg_1) and be read
--         on the 
--
-- Author: Peter Antoine
-- Date  : 22/01/2021
-----------------------------------------------------------------------------------
--					   Copyright (c) 2021 Peter Antoine
--							  All rights Reserved.
--					  Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;

	entity GeneralRegisters is
		port(
				reset			: in std_logic;									-- reset all the registers.
				reg_bus			: REGISTER_BUS;									-- the register control bus.

				data			: inout std_logic_vector(REG_WIDTH-1 downto 0);	-- The data width of the register.
				data_2			: out std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
	);
	end GeneralRegisters;

architecture synth of GeneralRegisters is

	---------------------------------------------------------------
	--- define the registers.
	---------------------------------------------------------------
	type REGISTER_ARRAY is array(0 to NUM_REGISTERS) of std_logic_vector(32-1 downto 0);
	signal register_bank : REGISTER_ARRAY := (others => (others => '0'));
	signal data_w_clock : std_logic;
begin

	-- handle the reading the data from the registers.
	data <= register_bank(to_integer(unsigned(reg_bus.reg_1_addr))) when (reg_bus.reg_1_en='1' and reset='0' and reg_bus.reg_1_rw=RW_READ) else (others => 'Z');

	data_2 <= register_bank(to_integer(unsigned(reg_bus.reg_2_addr))) when (reg_bus.reg_2_en='1' and reset='0' and reg_bus.reg_2_rw=RW_READ) else (others => 'Z');
	
	data_w_clock <= '1' when reg_bus.reg_1_en = '1' and reg_bus.reg_1_rw = '1' else '0';
	
	process (reset, data_w_clock, reg_bus, register_bank)
	begin
		if reset = '1'
		then
			register_bank <= (others => (others => '0'));
			
		elsif rising_edge(data_w_clock)
		then
			register_bank(to_integer(unsigned(reg_bus.reg_1_addr))) <= data;
		end if;
	end process;

end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
