-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : store_unit
-- Desc  : This is the storage unit.
--         It handles the storing of the output value to the given data store.
--         It will manage the different addressing modes that are required buy
--         the different compute units.
--
-- Author: 
-- Date  : 03/04/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;

entity StoreUnit is
	port (
		store_bus	: in	STORE_BUS;
		data		: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- the data to write.

		reg_bus		: out	REGISTER_BUS;								-- the control bus for the register
		reg_data	: out	std_logic_vector(DATA_WIDTH-1 downto 0);	-- register data
		reg_da		: in	std_logic;									-- the reg data is available.

		mem_bus		: out	MEMORY_BUS;									-- the memory control bus
		mem_data	: out	std_logic_vector(DATA_WIDTH-1 downto 0);	-- memory data
		mem_da		: in	std_logic;									-- mem data available.

		complete	: out std_logic										-- execution complete.
	);
end StoreUnit;

architecture synth of StoreUnit is

begin
	
	process (store_bus, data)
	begin
		if (store_bus.en = '0')
		then
			reg_bus		<= FREE_REGISTER_BUS;
			mem_bus		<= FREE_MEMORY_BUS;
			
			reg_data	<= (others => 'Z');
			mem_data	<= (others => 'Z');

			complete	<= 'Z';
		else
			case store_bus.mode is
				when OP_AM_MEMORY_DIRECT	=>
						mem_data		<= data;
						mem_bus.address	<= store_bus.address;
						mem_bus.rw		<= RW_WRITE;
						mem_bus.en		<= '1';

				when OP_AM_REGISTER			=>
						reg_data		<= data;
						reg_bus.address	<= store_bus.address(4 downto 0);
						reg_bus.rw		<= RW_WRITE;
						reg_bus.en		<= '1';
						complete		<= '1';

--				when OP_AM_IMMEDIATE			=>		Can't store immediate -- only data to reg or memory.
--				when OP_AM_REGISTER_INDIRECT	=>		INVALID INSTRUCTION -- the load part should have been handled already.

				when others =>
						reg_bus		<= INIT_REGISTER_BUS;
						mem_bus		<= INIT_MEMORY_BUS;
						complete	<= '0';
			end case;

		end if;
	end process;

end architecture synth;

-- vi:nocin:sw=4 ts=4:fdm=marker
