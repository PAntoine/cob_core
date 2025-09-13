-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : memory_unit_tb
-- Desc  : This is the test bench for memory unit.
--
-- Author: Peter Antoine
-- Date  : 14/02/2021
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
use work.MemoryUnit;

entity Memory_Unit_test_Bench is
end Memory_Unit_test_Bench;

architecture simulation of Memory_Unit_test_Bench is
	---------------------------------------------------------------
	--- Unit under test.
	---------------------------------------------------------------
	component MemoryUnit is
			port(
				en				: in	std_logic;
				rw				: in	std_logic;
				complete		: out	std_logic;	-- the data has been read and is available,
				address			: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
				data			: inout	std_logic_vector(DATA_WIDTH-1 downto 0);

				-- external memory device
				mem_dev_da		: in	std_logic;	-- when the external device has the data ready.
				mem_dev_rw		: out	std_logic;
				mem_dev_en		: out	std_logic;
				mem_dev_addr	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);
				mem_dev_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0)
			);
	end component MemoryUnit;

	---------------------------------------------------------------
	--- Test signals
	---------------------------------------------------------------
	signal en		: std_logic := '0';
	signal rw		: std_logic := '0';
	signal comp		: std_logic := '0';
	signal address	: std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal data		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal mem_da	: std_logic := '0';
	signal mem_en	: std_logic := '0';
	signal mem_rw	: std_logic := '0';
	signal mem_addr	: std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal mem_data	: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal test_data : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal test_data1 : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal test_data3 : std_logic_vector(DATA_WIDTH-1 downto 0);

	signal ram_clock	: std_logic := '0';
	
	signal trigger_da : std_logic := '0';

begin
	-- the basic test
	process
	begin
		rw 			<= RW_READ;
		address		<= x"00000001";
		data		<= (others => 'Z');
		en			<= '1';

		wait until comp = '1';
		test_data 	<= data;
		en			<= '0';
		wait until comp = '0';
		
		rw 			<= RW_READ;
		address		<= x"00000002";
		data		<= (others => 'Z');
		en			<= '1';
		
		wait until comp = '1';
		test_data1  <= data;
		en			<= '0';
		wait until comp = '0';
		
		rw 			<= RW_WRITE;
		address		<= x"00000003";
		data		<= x"FF11FF11";
		en			<= '1';

		wait until comp = '1';
		en			<= '0';

		wait;
	end process;


	ram_clock <= not ram_clock after 1 ns when mem_en = '1' else '0';

	-- the fake memory registers
	process (mem_en, mem_rw, mem_addr, ram_clock)
		variable counter : natural := 0;
	begin
		if (mem_en = '0')
		then
			mem_data <= (others => 'Z');
			mem_da   <= '0';
			counter  := 0;
			
		elsif mem_rw = RW_READ and rising_edge(ram_clock)
		then
			if counter = 1
			then
				case mem_addr is
					when x"00000001" => mem_data <= x"F0F0F0F0";
					when x"00000002" => mem_data <= x"0F0F0F0F";

					WHEN others		=> mem_data <= x"00000000";
				end case;
				mem_da <= '0';

			elsif counter = 3
			then
				mem_da <= '1';
			else
				mem_da <= '0';
			end if;

			counter := counter + 1;

		elsif mem_rw = RW_WRITE and rising_edge(ram_clock)
		then
			case counter is
				when 8		=> test_data3 <= mem_data; mem_da <= '0';
				when 9		=> mem_da <= '1';
				when others	=> mem_da <= '0';
			end case;

			counter := counter + 1;
		end if;
	end process;

	-- The memory unit to test.
	MU: MemoryUnit	port map (en => en , rw => rw, complete => comp, address => address, data => data, mem_dev_da => mem_da, mem_dev_rw => mem_rw, mem_dev_en => mem_en, mem_dev_addr => mem_addr, mem_dev_data => mem_data);

end architecture simulation;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
