-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : component_tb
-- Desc  : This file is the test bed for the cob core discrete components.
--
-- Author: Peter Antoine
-- Date  : 03/05/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all; 

use work.definitions.all;

use work.StackRegister;

entity Components_Test_Bench is
end Components_Test_Bench;

architecture simulation of Components_Test_Bench is
	---------------------------------------------------------------
	--- Include the components
	---------------------------------------------------------------
	component StackRegister is
		port(
				reset		: in	std_logic;
				clock		: in	std_logic;
				sr_bus		: in	STACK_BUS;
				flags		: in	CPU_FLAGS;
				pc			: in	std_logic_vector(ADDR_WIDTH-1 downto 0);

				mem_bus		: out	MEMORY_BUS;
				mem_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
				mem_da		: in	std_logic;

				complete	: out	std_logic;
				pc_load		: out	std_logic;
				stack_value	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);
				da			: out	std_logic;
				data		: inout std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component StackRegister;

	---------------------------------------------------------------
	--- the test signals
	---------------------------------------------------------------
	signal	reset		: std_logic		:= '1';
	signal	clock		: std_logic		:= '0';

	-- external bus signals - these are to other devices.
	signal sr_bus		: STACK_BUS;
	signal flags		: CPU_FLAGS									:= INIT_CPU_FLAGS;
	signal pc			: std_logic_vector(ADDR_WIDTH-1 downto 0)	:= x"00000001";

	signal mem_bus		: MEMORY_BUS								:= FREE_MEMORY_BUS;
	signal mem_data		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal mem_da		: std_logic;

	signal complete		: std_logic;
	signal pc_load		: std_logic;
	signal stack_value	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal da			: std_logic;
	signal data			: std_logic_vector(DATA_WIDTH-1 downto 0);

	---------------------------------------------------------------
	--- Test cases for testing the stack.
	---------------------------------------------------------------
	subtype		TEST_ITEM_TYPE is std_logic_vector(2 downto 0);
	constant	TEST_SET_VALUE	:	TEST_ITEM_TYPE := "000";
	constant	TEST_SR_PUSH	:	TEST_ITEM_TYPE := "001";
	constant	TEST_SR_SAVE	:	TEST_ITEM_TYPE := "010";
	constant	TEST_SR_CALL	:	TEST_ITEM_TYPE := "011";
	constant	TEST_FINISH		:	TEST_ITEM_TYPE := "111";


	signal test : TEST_ITEM_TYPE;

begin
	-- clock signal
	clock <= not clock after 50 ps;

	-- start the test.
	reset <= '0' after 20 ps;

	process (reset, test, complete)
	begin
		if reset = '1'
		then
			sr_bus	<= INIT_STACK_BUS;
 			test	<= TEST_SET_VALUE;

		elsif complete = '0'
		then
			case test is
				when TEST_SET_VALUE =>
					sr_bus.en		<= '1';
					sr_bus.mode		<= SR_SET;
					sr_bus.id		<= (others => '0');
					sr_bus.address	<= x"0000FFFF";

				when TEST_SR_PUSH =>
					sr_bus.en		<= '1';
					sr_bus.mode		<= SR_PUSH;
					sr_bus.id		<= (others => '0');
					sr_bus.address	<= x"0F0F0F0F";
				
				when TEST_SR_SAVE =>
					pc				<= x"00000F00";
					flags			<= vectorToFlags(x"F0F000FF");
					sr_bus.en		<= '1';
					sr_bus.mode		<= SR_SAVE;
					sr_bus.id		<= (others => '0');
					sr_bus.address	<= x"F0F0F0F0";

				when TEST_SR_CALL =>
					pc				<= x"000000F0";
					flags			<= vectorToFlags(x"F0F00FFF");
					sr_bus.en		<= '1';
					sr_bus.mode		<= SR_CALL;
					sr_bus.id		<= (others => '0');
					sr_bus.address	<= x"F0F0F0F0";
				
				when TEST_FINISH =>
					sr_bus.en		<= '0';
					sr_bus.mode		<= SR_SET;
					sr_bus.id		<= (others => '0');
					sr_bus.address	<= (others => '0');


				when others => null;
			end case;

		elsif rising_edge(complete)
		then
			case test is
				when TEST_SET_VALUE	=> test <= TEST_SR_PUSH;
				when TEST_SR_PUSH	=> test <= TEST_SR_CALL;
				when TEST_SR_CALL	=> test <= TEST_SR_SAVE;
				when TEST_SR_SAVE	=> test <= TEST_FINISH;
				when others => null;
			end case;

			sr_bus.en <= '0';
		end if;
	end process;

	process (mem_bus, clock)
	begin
		if reset = '1' or mem_bus.en = '0'
		then
			mem_da <= '0';

		elsif falling_edge(clock)
		then
			if mem_bus.rw = '1'
			then
				mem_da <= '1';
			end if;
		end if;

	end process;

	

	sr: StackRegister port map (reset => reset, clock => clock, sr_bus => sr_bus, flags => flags, pc => pc, mem_bus => mem_bus, mem_data => mem_data, mem_da => mem_da, complete => complete, pc_load => pc_load, stack_value => stack_value, da => da, data => data);

end architecture simulation;

-- vi:nocin:sw=4 ts=4:fdm=marker
