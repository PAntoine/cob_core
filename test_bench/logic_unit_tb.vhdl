-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : logic_unit_tb
-- Desc  : The Logic Unit test bench.
--
-- Author: Peter Antoine
-- Date  : 24/01/2021
-----------------------------------------------------------------------------------
--					   Copyright (c) 2021 Peter Antoine
--							  All rights Reserved.
--					  Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use STD.textio.all;
use ieee.std_logic_textio.all; 

use work.definitions.all;
use work.instructions.all;

use work.logic_tb_defines.all;

use work.LogicDecoder;
use work.RunLogicTestCase;

entity Logic_Unit_Test_Bench is
end Logic_Unit_Test_Bench;

architecture simulation of Logic_Unit_Test_Bench is
	component LogicDecoder is
			port(
				sel				: in std_logic;
				clock           : in std_logic;
				instruction_reg	: in INSTRUCTION_TYPE;
				data_available	: out std_logic;
				flags			: out CPU_FLAGS;
				sys_bus			: inout SYSTEM_BUS;
				reg_bus			: inout REGISTER_BUS;
				reg_data		: inout	std_logic_vector(31 downto 0);
				reg_data2		: inout	std_logic_vector(31 downto 0);
				mem_bus			: inout MEMORY_BUS
			);
	end component LogicDecoder;

	component RunLogicTestCase is
	port (	signal clock		: in	std_logic;
			signal start		: in	std_logic;
			signal da			: in	std_logic;
			signal test_case	: in	TEST_CASE_TYPE;
			signal reg_1_en		: in	std_logic;
			signal reg_2_en		: in	std_logic;
			signal reg_1_rw		: in	std_logic;
			signal reg_1_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
			signal reg_2_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
			signal sel			: out	std_logic;
			signal instruction	: out	INSTRUCTION_TYPE;
			signal result		: out	std_logic;
			signal complete		: out	std_logic	);
	end component RunLogicTestCase;

	---------------------------------------------------------------
	--- now the internal signals.
	---------------------------------------------------------------
	signal	running			: std_logic := '0';
	signal	sel				: std_logic := '0';
	signal	clock			: std_logic := '0';
	signal	instruction_reg	: INSTRUCTION_TYPE;
	signal	sys_bus			: SYSTEM_BUS := (others => '0');
	signal	reg_bus			: REGISTER_BUS := INIT_REGISTER_BUS;
	signal	mem_bus			: MEMORY_BUS;
	signal	data_available	: std_logic := '0';

	signal	init_test		: std_logic := '0';
	signal	data_load		: std_logic := '0';

	signal	data_clock		: std_logic := '0';

	signal	flags			: CPU_FLAGS := INIT_CPU_FLAGS;

	---------------------------------------------------------------
	--- fake registers
	---------------------------------------------------------------
	type REGISTER_ARRAY is array(0 to NUM_REGISTERS) of std_logic_vector(32-1 downto 0);
	shared variable register_bank : REGISTER_ARRAY := (others => (others => '0'));

	signal reg_data : std_logic_vector(31 downto 0);
	signal reg_data2 : std_logic_vector(31 downto 0);

	signal result : std_logic := '0';
	signal complete : std_logic := '0';

	signal test_case1 : TEST_CASE_TYPE;

	signal start : std_logic := '1';
		

begin
	-- test case
	clock <= not clock after 1 ns when running = '1' else '0';
	start <= '0', '1' after 1 ns;
	-- running <= '1', '0' after 20 ns;

	--reg_bus.reg_1_en <= 'L';
	--reg_bus.reg_2_en <= 'L';
	--sel <= 'L';

	process
	 variable tests :   TEST_CASE_ARRAY(0 to lsl_test_cases'length-1) := lsl_test_cases;
	begin
		running <= '1';
		for index in 0 to tests'length-1
		loop
			start <= '1';

			-- set the test case
			test_case1 <= tests(index);

			wait until complete = '1';

			if result = '0'
			then
				report "failure: test case(" & integer'image(index) & ") failed. expected " & to_hstring(tests(index).output) & " got " & to_hstring(reg_data)  severity warning;
			end if;

			start <= '0';
			wait until sel = '0';
		end loop;
		running <= '0';
		wait;
	end process;


	rtl: RunLogicTestCase port map (
						clock		=> clock,
						start		=> start,
						da			=> data_available,
						test_case	=> test_case1,
						reg_1_en	=> reg_bus.reg_1_en,
						reg_2_en	=> reg_bus.reg_2_en,
						reg_1_rw	=> reg_bus.reg_1_rw,
						reg_1_data	=> reg_data,
						reg_2_data	=> reg_data2,
						sel			=> sel,
						instruction	=> instruction_reg,
						result		=> result,
						complete	=> complete);

	--- Clock generation
	logic_unit:	LogicDecoder	port map (	sel => sel,
											clock => clock,
											instruction_reg => instruction_reg,
											data_available => data_available,
											flags => flags,
											sys_bus => sys_bus,
											reg_bus => reg_bus,
											reg_data => reg_data,
											reg_data2 => reg_data2,
											mem_bus => mem_bus);

end architecture simulation;

--- vi:nocin:sw=4 ts=4:fdm=marker
