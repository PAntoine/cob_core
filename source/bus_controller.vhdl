-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--					
--
-- Name  : bus_controller
-- Desc  : This entity controls the bus.
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

entity BusController is
		port(
			clock			: in std_logic;		-- the clock.
			sel				: in std_logic;		-- select the bus controller
			
			-- internal bus signals
			rw				: in std_logic;		-- the read request
			mem_address		: in std_logic_vector(ADDR_WIDTH-1 downto 0);		-- the address requested
			data_clock		: out std_logic;	-- when the data is available on the data bus.

			-- external bus signals
			as				: out std_logic;	-- address strobe
			ds				: out std_logic;	-- data strobe
			da				: in std_logic;		-- data acknowledge - when external data is ready.
			bus_rw			: out std_logic;	-- set the read/write flag
			bus_address		: out std_logic_vector(ADDR_WIDTH-1 downto 0)	-- the address selected.
		);
end entity BusController;

architecture synth of BusController is

	-- internal signals
	signal data_latch : std_logic_vector (DATA_WIDTH-1 downto 0);

begin

	-- set the rw signal when the chip is selected.
	bus_rw <= rw when (sel = '1') else 'Z';
	as <= '1' when (sel = '1') else '0';

	-- manage write cycle.
	bus_address <= mem_address when (rw = RW_WRITE and sel = '1') else (others => 'Z');
	ds <= '1' when (rw=RW_WRITE and clock = '0' and sel = '1') else '0';
	
	-- read cycle
	-- put the data on the rising edge
	-- set the data_clock on the falling edge.
	bus_address <= mem_address when (rw = RW_READ and sel = '1') else (others => 'Z');
	data_clock	<= '1' when (rw = RW_READ and da = '1' and sel = '1' and clock = '0') else '0';

end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker

