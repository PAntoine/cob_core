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
				en_1			: in std_logic;									-- is the register block selected.
				en_2			: in std_logic;									-- is the register block selected.
				clock			: in std_logic;									-- the clock.
				addr_data		: in std_logic;									-- output to the address bus or data bus.
				rw				: in std_logic;									-- are we reading or writing the register (reg 1 only).
				reg_address		: in std_logic_vector(REG_ID_WIDTH-1 downto 0);	-- the address of the register we are writing to.
				reg_2_address	: in std_logic_vector(REG_ID_WIDTH-1 downto 0);	-- the address of the register we are writing to.

				data			: inout std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
				data_2			: out std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
		);
	end GeneralRegisters;

architecture synth of GeneralRegisters is

	---------------------------------------------------------------
	--- define the registers.
	---------------------------------------------------------------
	type REGISTER_ARRAY is array(0 to NUM_REGISTERS) of std_logic_vector(32-1 downto 0);
	signal register_bank : REGISTER_ARRAY;
begin

	-- handle the reading the data from the registers.
	data 	<= register_bank(to_integer(unsigned(reg_address)))   when (en_1='1' and reset='0' and rw=RW_READ) else (others => 'Z');
	data_2	<= register_bank(to_integer(unsigned(reg_2_address))) when (en_2='1' and reset='0') else (others => 'Z');
	
	-- latch the data to the registers on write - rising edge of the sel clock
	process (rw, reset, clock, en_1, data, reg_address)
	begin
		if reset = '1'
		then
		  	register_bank(to_integer(unsigned(reg_address))) <= (others => '0');
		
		elsif clock'event and clock = '1' and en_1 = '1' and rw=RW_WRITE
		then
			register_bank(to_integer(unsigned(reg_address))) <= data;
		end if;
	end process;
	
end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
