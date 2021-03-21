----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : Program Counter
-- Desc  : This block handles the program counter.
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
use ieee.numeric_std.all;

use work.definitions.all;

entity ProgramCounter is
		port(
			reset	: in std_logic;									-- reset the program counter to the default address.
			clock	: in std_logic;									-- the clock event
			state	: in CPU_STATE;									-- the CPU signal that the next instruction is to be fetched.
			load	: in std_logic;									-- the counter is being loaded with an address.
			address	: in std_logic_vector(ADDR_WIDTH-1 downto 0);	-- the address to be loaded in the program counter.

			current	: out std_logic_vector(ADDR_WIDTH-1 downto 0);	-- the current address - stable throughout the operation.
			pc		: out std_logic_vector(ADDR_WIDTH-1 downto 0)	-- the value of the program counter.
		);
end ProgramCounter;

architecture synth of ProgramCounter is
	signal counter		: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- the program counter.
	signal current_addr	: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- the program counter - of the current instruction.
	signal load_addr	: std_logic;
begin

	process (reset, load, clock, state, address, counter)
	begin
		if reset = '1'
		then
			counter <= (others => '0');

		elsif clock'event
		then
	   		if load = '1'
			then
				counter <= address;
			
			elsif state = CS_FETCH_DECODE
			then
				counter <= std_logic_vector(unsigned(counter) + ADDR_BYTES);
			end if;
		end if;
	end process;

	process (reset, clock, state)
	begin
		if reset = '1'
		then
			current_addr <= (others => 'Z');
		
		elsif clock'event and state = CS_LOAD
		then
			current_addr <= counter;
		end if;
	end process;

	current <= current_addr;
	pc <= counter;

end architecture synth;
--- vi:nocin:ai:sw=4 ts=4:fdm=marker
