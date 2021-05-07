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
				data			: in  std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component InterruptExceptionUnit;


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
	signal pc_load		: std_logic		:= '0';
	signal flags_load	: std_logic		:= '0';
	signal stack_value	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal da			: std_logic		:= '0';
	signal data			: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal set_vector	: std_logic		:= '0';
	signal ieu_enable	: std_logic		:= '0';
	signal ieu_int_id	: INT_ID_TYPE	:= (others => '0');
	signal ieu_comp		: std_logic		:= '0';

	signal trigger		: std_logic;

	---------------------------------------------------------------
	--- Test cases for testing the stack.
	---------------------------------------------------------------
	subtype		TEST_ITEM_TYPE is std_logic_vector(3 downto 0);
	constant	TEST_SET_VALUE	:	TEST_ITEM_TYPE := "0000";
	constant	TEST_SR_PUSH	:	TEST_ITEM_TYPE := "0001";
	constant	TEST_SR_SAVE	:	TEST_ITEM_TYPE := "0010";
	constant	TEST_SR_CALL	:	TEST_ITEM_TYPE := "0011";
	constant	TEST_SR_RESTORE	:	TEST_ITEM_TYPE := "0100";
	constant	TEST_IEU_SET_00	:	TEST_ITEM_TYPE := "0101";
	constant	TEST_IEU_SET_FF	:	TEST_ITEM_TYPE := "0110";
	constant	TEST_IEU_INT_00	:	TEST_ITEM_TYPE := "0111";
	constant	TEST_IEU_INT_FF	:	TEST_ITEM_TYPE := "1000";
	constant	TEST_FINISH		:	TEST_ITEM_TYPE := "1111";


	signal test : TEST_ITEM_TYPE;

begin
	-- clock signal
	clock <= not clock after 50 ps;

	-- start the test.
	reset <= '0' after 20 ps;

	trigger <= '1' when (complete = '1' or ieu_comp = '1') else '0';

	-- flags process
	process (reset, flags_load, data)
	begin
		if (reset = '1')
		then
			flags <= INIT_CPU_FLAGS;

		elsif rising_edge(flags_load)
		then
			flags <= vectorToFlags(data);
		end if;
	end process;
	
	-- flags process
	process (reset, pc_load, data)
	begin
		if (reset = '1')
		then
			pc <= (others => '0');

		elsif rising_edge(pc_load)
		then
			pc <= data;
		end if;
	end process;

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
			case test is
				when TEST_SET_VALUE =>
					sr_bus.en		<= '1';
					sr_bus.mode		<= SR_SET;
					sr_bus.id		<= (others => '0');
					sr_bus.address	<= x"00010000";

				when TEST_SR_PUSH =>
					sr_bus.en		<= '1';
					sr_bus.mode		<= SR_PUSH;
					sr_bus.id		<= (others => '0');
					sr_bus.address	<= x"0F0F0F0F";
				
				when TEST_SR_CALL =>
			--		pc				<= x"000000F0";
			--		flags			<= vectorToFlags(x"F0F00FFF");
					sr_bus.en		<= '1';
					sr_bus.mode		<= SR_CALL;
					sr_bus.id		<= (others => '0');
					sr_bus.address	<= x"F0F0F0F0";
				
				when TEST_SR_SAVE =>
			--		pc				<= x"00000F00";
			--		flags			<= vectorToFlags(x"F0F000FF");
					sr_bus.en		<= '1';
					sr_bus.mode		<= SR_SAVE;
					sr_bus.id		<= (others => '0');
					sr_bus.address	<= x"F0F0F0F0";

				when TEST_SR_RESTORE =>
			--		flags			<= FREE_CPU_FLAGS;
					sr_bus.en		<= '1';
					sr_bus.mode		<= SR_RESTORE;
					sr_bus.id		<= (others => '0');
					sr_bus.address	<= x"F0F0F0F0";
				
				when TEST_IEU_SET_00 =>
					-- TODO - set the 00 interrupt vector
				when TEST_IEU_SET_FF =>
					-- TODO - set the FF interrupt vector

				when TEST_IEU_INT_00 =>
					sr_bus			<= INIT_STACK_BUS;
			--		flags			<= vectorToFlags(x"00000000");
					ieu_int_id		<= (others => '0');
					ieu_enable		<= '1';
				
				when TEST_IEU_INT_FF =>
					sr_bus			<= INIT_STACK_BUS;
					ieu_int_id		<= (others => '1');
					ieu_enable		<= '1';
				
				when TEST_FINISH =>
					sr_bus.en		<= '0';
					sr_bus.mode		<= SR_SET;
					sr_bus.id		<= (others => '0');
					sr_bus.address	<= (others => '0');


				when others => null;
			end case;

		elsif rising_edge(trigger)
		then
			case test is
				when TEST_SET_VALUE		=> test <= TEST_SR_PUSH;
				when TEST_SR_PUSH		=> test <= TEST_SR_CALL;
				when TEST_SR_CALL		=> test <= TEST_SR_SAVE;
				when TEST_SR_SAVE		=> test <= TEST_SR_RESTORE;
				when TEST_SR_RESTORE	=> test <= TEST_IEU_SET_00;
				when TEST_IEU_SET_00	=> test <= TEST_IEU_SET_FF;
				when TEST_IEU_SET_FF	=> test <= TEST_IEU_INT_00;
				when TEST_IEU_INT_00	=> test <= TEST_IEU_INT_FF;
				when TEST_IEU_INT_FF	=> test <= TEST_FINISH;
				when others => null;
			end case;

			sr_bus.en <= '0';
			ieu_enable <= '0';
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

	process (mem_bus)
	begin
		if mem_bus.en = '0' or mem_bus.rw = RW_WRITE
		then
			mem_data <= (others => 'Z');

		elsif mem_bus.en = '1'
		then
			case mem_bus.address is
				when x"0000ffec"	=> mem_data <= x"0F0F0F00";
				when x"0F0F0F00"	=> mem_data <= x"00000004";
				when x"0F0F0F04"	=> mem_data <= x"0F0F0F0F";
				when others 		=> mem_data <= x"FFFFFFFF";
			end case;
		end if;
	end process;

	sr: StackRegister port map (reset => reset, clock => clock, sr_bus => sr_bus, flags => flags, pc => pc, mem_bus => mem_bus, mem_data => mem_data, mem_da => mem_da,
								complete => complete, pc_load => pc_load, flags_load => flags_load, stack_value => stack_value, da => da, data => data);
	
	ie: InterruptExceptionUnit port map ( 	reset => reset, enable => ieu_enable, clock => clock, write => set_vector, int_id => ieu_int_id, flags => flags,
											complete => ieu_comp, sr_bus => sr_bus, stack_complete => complete, data => data);

end architecture simulation;

-- vi:nocin:sw=4 ts=4:fdm=marker
