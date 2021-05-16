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
use work.int_except_tb_defines.all;

use work.StackRegister;
use work.InterruptExceptionUnit;

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
				flags_load	: out	std_logic;
				stack_value	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);
				da			: out	std_logic;
				data		: inout std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component StackRegister;

	component InterruptExceptionUnit is
		port(
				reset			: in std_logic;
				enable			: in std_logic;
				clock			: in std_logic;
				write			: in std_logic;
				int_id			: in INT_ID_TYPE;									-- the interrupt vector to jump/write to.
				flags			: in CPU_FLAGS;
				complete		: out std_logic;
				sr_bus			: out STACK_BUS;
				stack_complete	: in  std_logic;
				data			: inout  std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component InterruptExceptionUnit;


	---------------------------------------------------------------
	--- the test signals
	---------------------------------------------------------------
	signal	reset			: std_logic		:= '1';
	signal	clock			: std_logic		:= '0';
	signal	clock_running	: std_logic		:= '1';

	-- external bus signals - these are to other devices.
	signal sr_bus		: STACK_BUS;
	signal flags		: CPU_FLAGS									:= INIT_CPU_FLAGS;
	signal pc			: std_logic_vector(ADDR_WIDTH-1 downto 0)	:= x"00000001";

	signal mem_bus		: MEMORY_BUS								:= FREE_MEMORY_BUS;
	signal mem_data		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal mem_da		: std_logic;

	signal complete		: std_logic;
	signal pc_load		: std_logic		:= '0';
	signal flags_load	: std_logic		:= '0';
	signal stack_value	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal da			: std_logic		:= '0';
	signal data			: std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

	signal set_vector	: std_logic		:= '0';
	signal ieu_enable	: std_logic		:= '0';
	signal ieu_int_id	: INT_ID_TYPE	:= (others => '0');
	signal ieu_comp		: std_logic		:= '0';

	signal trigger		: std_logic;

	signal test : integer;
		
begin
	-- clock signal
	clock <= not clock and clock_running after 50 ps;

	-- start the test.
	reset <= '0' after 20 ps;

	trigger <= '1' when (complete = '1' or ieu_comp = '1') else '0';


	-- main test process
	process (reset, test, trigger)
	begin
		if reset = '1'
		then
			sr_bus		<= INIT_STACK_BUS;
 			test		<= TEST_SET_VALUE;
			ieu_int_id	<= (others => '0');
			ieu_enable	<= '0';
	
		elsif trigger = '0'
		then
			sr_bus.en	<= '1';
			sr_bus.mode <= GetTestMode(test);
			
			if GetTestMode(test) = SR_SET or GetTestMode(test) = SR_PUSH
			then
				data <= GetTestData(test);
			else
				data <= (others => 'Z');
			end if;

		elsif rising_edge(trigger)
		then
			--if test < TEST_FINISH
			if test < TEST_SR_RESTORE
			then
				test <= test + 1;
			else
				clock_running <= '0';
			end if;

			sr_bus.en <= '0';
			ieu_enable <= '0';
		end if;
	end process;

	-- flags process
	process (reset, flags_load, data, test)
		variable test_value : std_logic_vector(DATA_WIDTH-1 downto 0);
	begin
		if (reset = '1')
		then
			flags <= INIT_CPU_FLAGS;
		
		elsif trigger = '1'
		then
			flags <= GetTestFlagsBefore(test);

		elsif rising_edge(flags_load)
		then
			test_value := flagsToVector(GetTestFlagsAfter(test));
			if data /= test_value
			then
				report "failure: test number " & integer'image(test) & " - failed flags mismatch has " & toHString(data) & " and expected " & toHString(test_value);
			end if;
		end if;
	end process;
	
	-- program counter process
	pc <= (others => '0') when reset = '1' else GetTestPC(test);
	
	process (reset, data)
		variable test_value : std_logic_vector(DATA_WIDTH-1 downto 0);
	begin
		if rising_edge(pc_load)
		then
			test_value := GetTestPC(test);
			
			if data /= test_value
			then
				report "failure: test number " & integer'image(test) & " - failed PC mismatch has " & toHString(data) & " and expected " & toHString(test_value);
			end if;

		end if;
	end process;
	
	process (mem_bus, clock)
	begin
		if reset = '1' or mem_bus.en = '0'
		then
			mem_da <= '0';

		elsif mem_bus.en = '1' and falling_edge(clock)
		then
			mem_da <= '1';
		end if;
	end process;

	process (da, data)
		variable test_value : std_logic_vector(DATA_WIDTH-1 downto 0);
	begin
		if rising_edge(da)
		then
			test_value := GetTestData(test);
			if data /= test_value
			then
				report "failure: test number " & integer'image(test) & " - failed data mismatch has " & toHString(data) & " and expected " & toHString(test_value);
			end if;
		end if;
	end process;

	process (mem_bus)
	begin
		if mem_bus.en = '0' or mem_bus.rw = RW_WRITE
		then
			mem_data <= (others => 'Z');

		elsif mem_bus.en = '1'
		then
			if mem_bus.address = GetTestAddress(test, 0)
			then
				mem_data <= GetTestValue(test, 0);

			elsif mem_bus.address = GetTestAddress(test, 1)
			then
				mem_data <= GetTestValue(test, 1);

			else
				mem_data <= x"FFFFFFFF";
			end if;
		end if;
	end process;

	process (mem_bus, mem_data, test, mem_da)
		variable test_value : std_logic_vector(ADDR_WIDTH-1 downto 0);
	begin
		if mem_bus.en = '1' and mem_bus.rw = '1' and rising_edge(mem_da)
		then
			if mem_bus.address = GetTestAddress(test, 0)
			then
				test_value := GetTestValue(test, 0);
				if mem_data /= test_value
				then
					report "failure: test number " & integer'image(test) & " ["& toHString(mem_bus.address) & "] - failed memory write mismatch has " & toHString(mem_data) & " and expected " & toHString(test_value);
				end if;

			elsif mem_bus.address = GetTestAddress(test, 1)
			then
				test_value := GetTestValue(test, 1);
				if mem_data /= test_value
				then
					report "failure: test number " & integer'image(test) & " ["& toHString(mem_bus.address) & "] - failed memory write mismatch has " & toHString(mem_data) & " and expected " & toHString(test_value);
				end if;

			else
				report "failure: test number " & integer'image(test) & " - unexpected address " & toHString(mem_bus.address) & " " & toHString(GetTestAddress(test, 0)) & " " & toHString(test_value);
			end if;
		end if;
	end process;

	sr: StackRegister port map (reset => reset, clock => clock, sr_bus => sr_bus, flags => flags, pc => pc, mem_bus => mem_bus, mem_data => mem_data, mem_da => mem_da,
								complete => complete, pc_load => pc_load, flags_load => flags_load, stack_value => stack_value, da => da, data => data);
	
	ie: InterruptExceptionUnit port map ( 	reset => reset, enable => ieu_enable, clock => clock, write => set_vector, int_id => ieu_int_id, flags => flags,
											complete => ieu_comp, sr_bus => sr_bus, stack_complete => complete, data => data);

end architecture simulation;

-- vi:nocin:sw=4 ts=4:fdm=marker
