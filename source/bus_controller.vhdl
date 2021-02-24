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
			sel				: in std_logic;		-- select the bus controller
			
			-- CPU modes
			read			: in std_logic;		-- 
			write			: in std_logic;
			execute			: in std_logic;
			mem_read		: in std_logic;
			mem_read_a		: in std_logic;
			wait_read		: in std_logic;
			wait_write		: in std_logic;
			
			-- component bus signals
			reg_1_rw		: in std_logic;
			reg_1_en		: in std_logic;
			reg_2_rw		: in std_logic;
			reg_2_en		: in std_logic;

			-- data buses
			a_address		: in REG_ID;
			b_address		: in REG_ID;
			destination_reg	: in REG_ID;
			a_reg			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			b_reg			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			accumulator		: in std_logic_vector(DATA_WIDTH-1 downto 0);
		
			reg_bus			: out REGISTER_BUS;
			mem_bus			: out MEMORY_BUS;
		
			reg_data		: out std_logic_vector(DATA_WIDTH-1 downto 0);
			mem_bus_data	: out std_logic_vector(DATA_WIDTH-1 downto 0)
		);
end entity BusController;

architecture synth of BusController is

begin
	------------------------------------------------------------
	--- Bus Control Drivers
	------------------------------------------------------------
	process (  read, write, mem_read, execute, reg_1_rw, reg_1_en, reg_2_rw, reg_2_en, wait_read,
	           wait_write, mem_read_a, a_reg, b_reg, mem_read, accumulator, destination_reg, a_address, b_address)
	begin
		if read = '1' or execute = '1'
		then
			reg_bus.reg_1_addr	<= a_address;
			reg_bus.reg_2_addr	<= b_address;
			reg_bus.reg_1_rw	<= reg_1_rw;
			reg_bus.reg_2_rw	<= reg_2_rw;
			reg_bus.reg_1_en	<= reg_1_en;
			reg_bus.reg_2_en	<= reg_2_en;
			reg_data			<= (others => 'Z');
			mem_bus_data		<= (others => 'Z');
			mem_bus				<= FREE_MEMORY_BUS;

		elsif wait_read = '1'
		then
			reg_bus				<= FREE_REGISTER_BUS;
			mem_bus_data		<= (others => 'Z');
			if mem_read_a = '1'
			then
				mem_bus.addr	<= a_reg;
			else
				mem_bus.addr	<= b_reg;
			end if;
			mem_bus.rw			<= RW_READ;
			mem_bus.en			<= '1';		-- start the memory read.
			mem_bus_data		<= (others => 'Z');
			reg_data			<= (others => 'Z');

		elsif write = '1'
		then
			reg_bus.reg_1_addr	<= destination_reg;
			reg_bus.reg_2_addr	<= b_address;
			reg_bus.reg_1_rw	<= RW_WRITE;
			reg_bus.reg_2_rw	<= reg_2_rw;
			reg_bus.reg_1_en	<= reg_1_en;
			reg_bus.reg_2_en	<= reg_2_en;
			reg_data 			<= accumulator;
			mem_bus_data		<= (others => 'Z');
			mem_bus				<= FREE_MEMORY_BUS;
		
		elsif wait_write = '1'
		then
			reg_bus				<= FREE_REGISTER_BUS;
			mem_bus.addr		<= a_reg;
			mem_bus_data		<= accumulator;
			mem_bus.rw			<= RW_WRITE;
			mem_bus.en			<= '1';		-- start memory write
			reg_data			<= (others => 'Z');
		
		else
			reg_data 			<= (others => 'Z');
			mem_bus_data		<= (others => 'Z');
			reg_bus				<= FREE_REGISTER_BUS;
			mem_bus				<= FREE_MEMORY_BUS;
		end if;
	end process;
end architecture synth;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
