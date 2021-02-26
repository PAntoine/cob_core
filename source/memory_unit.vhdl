----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : memory unit
-- Desc  : This block controls access to the memory.
--
--		   This block will handle indirect access to memory and will get the
--		   flags when the data is ready to be returned.
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

entity MemoryUnit is
		port(
			en				: in	std_logic;
			clock			: in	std_logic;
			rw				: in	std_logic;
			complete		: out	std_logic;	-- the data has been read and is available,
			address			: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
			data			: inout	std_logic_vector(DATA_WIDTH-1 downto 0);

			-- external memory device
			mem_dev_da		: in	std_logic;	-- when the external device has the data ready (or written).
			mem_dev_rw		: out	std_logic;
			mem_dev_en		: out	std_logic;
			mem_dev_addr	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);
			mem_dev_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0)
		);
end MemoryUnit;

architecture synth of MemoryUnit is
begin
	-- let's set the memory bus to get the data
	data 		<= (others => 'Z') when en = '0' or rw = RW_WRITE else mem_dev_data;
	complete	<= '0' 			   when en = '0' else mem_dev_da;

	-- lets control the memory bus.
	mem_dev_rw		<= RW_READ			when en = '0' or rw = RW_READ else RW_WRITE;
	mem_dev_data	<= (others => 'Z')	when en = '0' or rw = RW_READ else data;
	mem_dev_addr	<= (others => 'Z')	when en = '0' else address;

	process (en, clock)
	begin
		if en = '0'
		then
			mem_dev_en <= '0';

		elsif rising_edge(clock)
		then
			mem_dev_en		<= '1';
		end if;
	end process;

end architecture synth;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
