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
			sel				: in std_logic;
			sys_bus			: in SYSTEM_BUS;
			addr_mode_bus	: in ADDRESS_MODE_BUS;

			-- data buses
			a_address		: in REG_ID;
			b_address		: in REG_ID;
			destination_reg	: in REG_ID;
			pc_reg			: in std_logic_vector(ADDR_WIDTH-1 downto 0);
			a_op			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			b_op			: in std_logic_vector(DATA_WIDTH-1 downto 0);
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
	process (sys_bus, addr_mode_bus, a_op, b_op, accumulator, destination_reg, a_address, b_address, pc_reg)
	begin
		if sys_bus.fetch = '1'
		then
			reg_bus				<= FREE_REGISTER_BUS;
			reg_data			<= (others => 'Z');
			mem_bus_data		<= (others => 'Z');
			mem_bus.addr		<= pc_reg;
			mem_bus.rw			<= RW_READ;
			mem_bus.en			<= '1';		-- start the memory read.
		
		elsif sys_bus.read = '1' or sys_bus.execute = '1'
		then
			reg_bus.reg_1_addr	<= a_address;
			reg_bus.reg_2_addr	<= b_address;
			reg_bus.reg_1_rw	<= addr_mode_bus.reg_1_rw;
			reg_bus.reg_2_rw	<= addr_mode_bus.reg_2_rw;
			reg_bus.reg_1_en	<= addr_mode_bus.reg_1_en;
			reg_bus.reg_2_en	<= addr_mode_bus.reg_2_en;
			reg_data			<= (others => 'Z');
			mem_bus_data		<= (others => 'Z');
			mem_bus				<= FREE_MEMORY_BUS;

		elsif sys_bus.wait_read = '1'
		then
			reg_bus				<= FREE_REGISTER_BUS;
			mem_bus_data		<= (others => 'Z');
			if addr_mode_bus.mem_read_a = '1'
			then
				mem_bus.addr	<= a_op;
			else
				mem_bus.addr	<= b_op;
			end if;
			mem_bus.rw			<= RW_READ;
			mem_bus.en			<= '1';		-- start the memory read.
			reg_data			<= (others => 'Z');

		elsif sys_bus.write = '1'
		then
			reg_bus.reg_1_addr	<= destination_reg;
			reg_bus.reg_2_addr	<= b_address;
			reg_bus.reg_1_rw	<= RW_WRITE;
			reg_bus.reg_2_rw	<= addr_mode_bus.reg_2_rw;
			reg_bus.reg_1_en	<= addr_mode_bus.reg_1_en;
			reg_bus.reg_2_en	<= addr_mode_bus.reg_2_en;
			reg_data 			<= accumulator;
			mem_bus_data		<= (others => 'Z');
			mem_bus				<= FREE_MEMORY_BUS;
		
		elsif sys_bus.wait_write = '1'
		then
			reg_bus				<= FREE_REGISTER_BUS;
			mem_bus.addr		<= a_op;
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
