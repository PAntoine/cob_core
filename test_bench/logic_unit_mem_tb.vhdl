-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : logic_unit_mem_tb
-- Desc  : The Logic Unit test bench (for memory accesses).
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
use work.LogicUnitMemoryTest;

entity Logic_Unit_Memory_Test_Bench is
end Logic_Unit_Memory_Test_Bench;

architecture simulation of Logic_Unit_Memory_Test_Bench is
	component LogicDecoder is
			port(
				sel				: in std_logic;
				clock			: in std_logic;
				instruction_reg	: in INSTRUCTION_TYPE;
				data_available	: out std_logic;
				flags			: out CPU_FLAGS;
				sys_bus			: inout SYSTEM_BUS;
				reg_bus			: inout REGISTER_BUS;
				reg_data		: inout	std_logic_vector(31 downto 0);
				reg_data2		: in	std_logic_vector(31 downto 0);
				mem_bus			: inout MEMORY_BUS;
				mem_bus_data	: inout std_logic_vector(DATA_WIDTH-1 downto 0)
			);
	end component LogicDecoder;

	component LogicUnitMemoryTest is
		port (	signal clock		: in	std_logic;
				signal start		: in	std_logic;
				signal da			: in	std_logic;
				signal test_case	: in	TEST_CASE_TYPE;
				signal address_mode	: in	std_logic_vector(2 downto 0);
				signal mem_en		: in	std_logic;
				signal mem_rw		: in	std_logic;
				signal mem_address	: in	std_logic_vector(DATA_WIDTH-1 downto 0);
				signal mem_complete	: out	std_logic;
				signal mem_data		: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
				signal reg_1_en		: in	std_logic;
				signal reg_1_rw		: in	std_logic;
				signal reg_2_en		: in	std_logic;
				signal reg_1_data	: out	std_logic_vector(DATA_WIDTH-1 downto 0);
				signal reg_2_data	: out	std_logic_vector(DATA_WIDTH-1 downto 0);
				signal sel			: out	std_logic;
				signal instruction	: out	INSTRUCTION_TYPE;
				signal result		: out	std_logic;
				signal complete		: out	std_logic	);
	end component LogicUnitMemoryTest;

	---------------------------------------------------------------
	--- now the internal signals.
	---------------------------------------------------------------
	signal	running			: std_logic := '0';
	signal	sel				: std_logic := '0';
	signal	clock			: std_logic := '0';
	signal	instruction_reg	: INSTRUCTION_TYPE;
	signal	sys_bus			: SYSTEM_BUS := (others => '0');
	signal	reg_bus			: REGISTER_BUS := INIT_REGISTER_BUS;
	signal	mem_bus			: MEMORY_BUS := INIT_MEMORY_BUS;
	signal	data_available	: std_logic := '0';

	signal	init_test		: std_logic := '0';
	signal	data_load		: std_logic := '0';

	signal	data_clock		: std_logic := '0';

	signal	flags			: CPU_FLAGS := INIT_CPU_FLAGS;

	---------------------------------------------------------------
	--- fake registers
	---------------------------------------------------------------
	signal reg_data		: std_logic_vector(31 downto 0);
	signal reg_data2	: std_logic_vector(31 downto 0);
	signal mem_data		: std_logic_vector(31 downto 0);

	signal result		: std_logic := '0';
	signal complete		: std_logic := '0';

	signal mem_test		: TEST_CASE_TYPE;

	signal reg_start	: std_logic := '0';
	signal mem_start	: std_logic := '0';
	
	signal address_mode : std_logic_vector(2 downto 0);

begin
	-- test case
	clock <= not clock after 1 ns when running = '1' else '0';
	running <= '0', '1' after 1 ns;

	process
	 variable tests : TEST_CASE_ARRAY(0 to lsl_test_cases'length-1) := lsl_test_cases;
	 type test_mode is array(0 to 1) of std_logic_vector(2 downto 0);
	 variable modes : test_mode := (AM_MRR, AM_RMR);
	 
	begin
		-- need some setup time.
		wait for 1 ns;

		for mode_index in 0 to modes'length-1
		loop
			address_mode <= modes(mode_index);

			for mem_index in 0 to tests'length-1
			loop
				mem_start <= '1';

				-- set the test case
				mem_test <= tests(mem_index);

				wait until complete = '1';

				if result = '0'
				then
					report "failure: (MEM: " & to_hstring(address_mode) & ") test case(" & integer'image(mem_index) & ") failed. expected " & to_hstring(tests(mem_index).output) & " got " & to_hstring(reg_data) severity warning;
				end if;

				mem_start <= '0';
				wait until sel = '0';
			end loop;
		end loop;
		assert false report "Simulation Finished" severity failure;
	end process;

	rlumt: LogicUnitMemoryTest port map (
				clock			=> clock,
				start			=> mem_start,
				da				=> data_available,
				test_case		=> mem_test,
				address_mode	=> address_mode,
				mem_en			=> mem_bus.en,
				mem_rw			=> mem_bus.rw,
				mem_address		=> mem_bus.addr,
				mem_data		=> mem_data,
				mem_complete	=> mem_bus.complete,
				reg_1_en		=> reg_bus.reg_1_en,
				reg_1_rw		=> reg_bus.reg_1_rw,
				reg_2_en		=> reg_bus.reg_2_en,
				reg_1_data		=> reg_data,
				reg_2_data		=> reg_data2,
				sel				=> sel,
				instruction		=> instruction_reg,
				result			=> result,
				complete		=> complete);

	logic_unit:	LogicDecoder	port map (	sel => sel,
											clock => clock,
											instruction_reg => instruction_reg,
											data_available => data_available,
											flags => flags,
											sys_bus => sys_bus,
											reg_bus => reg_bus,
											reg_data => reg_data,
											reg_data2 => reg_data2,
											mem_bus => mem_bus,
											mem_bus_data => mem_data);

end architecture simulation;

--- vi:nocin:sw=4 ts=4:fdm=marker
