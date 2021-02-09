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

use work.definitions.all;
use work.instructions.all;
use work.LogicDecoder;

entity Logic_Unit_Test_Bench is
end Logic_Unit_Test_Bench ;

architecture simulation of Logic_Unit_Test_Bench is
	component LogicDecoder is
			port(
				sel				: in std_logic;
				clock           : in std_logic;
				instruction_reg	: in INSTRUCTION_TYPE;
				data_available	: out std_logic;
				sys_bus			: inout SYSTEM_BUS;
				reg_bus			: inout REGISTER_BUS;
				reg_data		: inout	std_logic_vector(31 downto 0);
				reg_data2		: inout	std_logic_vector(31 downto 0);
				mem_bus			: inout MEMORY_BUS
			);
	end component LogicDecoder;

	---------------------------------------------------------------
	--- now the internal signals.
	---------------------------------------------------------------
	signal	running			: std_logic := '0';
	signal	sel				: std_logic := '0';
	signal	clock			: std_logic := '0';
	signal	instruction_reg	: INSTRUCTION_TYPE;
	signal	sys_bus			: SYSTEM_BUS := (others => '0');
	signal	reg_bus			: REGISTER_BUS;
	signal	mem_bus			: MEMORY_BUS;
	signal	data_available	: std_logic := '0';

	signal	init_test		: std_logic := '0';
	signal	data_load		: std_logic := '0';
	
	signal	data_clock		: std_logic := '0';
	

	---------------------------------------------------------------
	--- fake registers
	---------------------------------------------------------------
	type REGISTER_ARRAY is array(0 to NUM_REGISTERS) of std_logic_vector(32-1 downto 0);
	shared variable register_bank : REGISTER_ARRAY := (others => (others => '0'));

	signal reg_data : std_logic_vector(31 downto 0);
	signal reg_data2 : std_logic_vector(31 downto 0);

begin
	--- Clock generation
	clock <= not clock after 1 ns when running = '1' else '0';
    sel <= '1' after 2 ns, '0' after 10 ns;  	
	running <= '1', '0' after 20 ns;

	init_test <= '1' after 1 ns, '0' after 2 ns;

	--- now lets put an instruction in.
	instruction_reg <= LI_LSL & IU_LOGIC & "000" & "00001" & "00010" & "00011" & "000";
	
	-- TODO: Need to write a state machine that sets the data for the writes.
	--- load test data.
	reg_data <= (others => '1') when init_test = '1' else (others => 'Z');
	reg_bus.reg_1_addr <= "00001" when init_test = '1' else (others => 'Z');
	
	reg_data2 <= "00000000000000000000000000000001"  when init_test = '1' else (others => 'Z');
	reg_bus.reg_2_addr <= "00010" when init_test = '1' else (others => 'Z');
	
	data_load <= '1' when init_test = '1' else '0';

	-- register_bank(2) <= "00000000000000000000000000000001" when rising_edge(init_test);

	reg_data  <= register_bank(to_integer(unsigned(reg_bus.reg_1_addr))) when (reg_bus.reg_1_en = '1' and reg_bus.reg_1_rw = RW_READ) else (others => 'Z');
	reg_data2 <= register_bank(to_integer(unsigned(reg_bus.reg_2_addr))) when (reg_bus.reg_2_en = '1' and reg_bus.reg_2_rw = RW_READ) else (others => 'Z');

    process (data_load, reg_bus.reg_1_addr, data_available)
    begin
        if rising_edge(data_load) or rising_edge(data_available)
        then
	       register_bank(to_integer(unsigned(reg_bus.reg_1_addr))) := reg_data;
	    end if;
	end process;
	
	process (data_load, reg_bus.reg_2_addr, data_available)
    begin
        if rising_edge(data_load) or rising_edge(data_available) 
        then
	       register_bank(to_integer(unsigned(reg_bus.reg_2_addr))) := reg_data2;
	    end if;
	end process;
	
	logic_unit:	LogicDecoder	port map (sel, clock, instruction_reg, data_available, sys_bus, reg_bus => reg_bus, reg_data => reg_data, reg_data2 => reg_data2, mem_bus => mem_bus);

end architecture simulation;

--- vi:nocin:sw=4 ts=4:fdm=marker
