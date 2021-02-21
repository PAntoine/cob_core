-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--					
--
-- Name  : Logic Unit Memory Test
-- Desc  : This entity handles the to memory tests.
--
-- Author: Peter Antoine
-- Date  : 09/02/2021
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

entity LogicUnitMemoryTest is
	port (	signal clock		: in	std_logic;
			signal start		: in	std_logic;
			signal da			: in	std_logic;
			signal test_case	: in	TEST_CASE_TYPE;
			signal address_mode	: in	std_logic_vector(2 downto 0);
			
			-- memory bus connection
			signal mem_en		: in	std_logic;
			signal mem_rw		: in	std_logic;
			signal mem_address	: in	std_logic_vector(DATA_WIDTH-1 downto 0);
			
			signal mem_complete	: out	std_logic;
			signal mem_data		: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
			
			-- register collection
			signal reg_1_en		: in	std_logic;
			signal reg_1_rw		: in	std_logic;
			signal reg_2_en		: in	std_logic;
			signal reg_1_data	: out	std_logic_vector(DATA_WIDTH-1 downto 0);
			signal reg_2_data	: out	std_logic_vector(DATA_WIDTH-1 downto 0);
			
			-- test connections
			signal sel			: out	std_logic;
			signal instruction	: out	INSTRUCTION_TYPE;
			signal result		: out	std_logic;
			signal complete		: out	std_logic	);
end entity LogicUnitMemoryTest;

architecture behv of LogicUnitMemoryTest is
	----------------------------------------------------
	--- LogicUnitMemoryTest
	---
	--- This procedure will run through the test cases
	--- and make sure the logic of the commands matches
	--- what is expected. It will only use the same
	--- registers, this is a pure procedure only test.
	----------------------------------------------------
begin
	-- let make or state item.
	instruction <= test_case.opcode & IU_LOGIC & address_mode & "00001" & "00010" & "00011" & "000"; -- when start = '1' else (others => 'Z');

	sel <= '1' when start = '1' else '0';

	-- indirect reading of the register for the memory address
	-- so lets simply return known addresses for the memory.
	process (start, reg_1_en, reg_1_rw)
	begin
		if start = '1' and reg_1_en = '1' and reg_1_rw = RW_READ
		then
			reg_1_data <= x"00000001";	-- always return address 1 for register 1.
		else
			reg_1_data <= (others => 'Z');
		end if;
	end process;

	-- reg 2 will always have the same value in it.
	process (start, reg_2_en)
	begin
		if start = '1' and reg_2_en = '1'
		then
			reg_2_data <= test_case.b_input;	-- always return address 2 for register 2.
		else
			reg_2_data <= (others => 'Z');
		end if;
	end process;

	-- handle the first register
	-- this one should have the result
	process (start, mem_rw, mem_en)
	begin
		if start = '1' and mem_en = '1' and mem_rw = RW_READ
		then
			if (mem_address = x"00000001")
			then
				mem_data <= test_case.a_input;		-- memory address 1 is test case a

			elsif mem_address  = x"00000002"
			then
				mem_data <= test_case.b_input;		-- memory address 2 is test case b

			else
				report "failure: invalid memeory address during test - read read from " & to_hstring(mem_address);
				mem_data <= x"01010101";			-- failure case - we may have 3 - but that should be a write.
			end if;

			mem_complete <= '1';
		else
			mem_complete <= '0';
			mem_data <= (others => 'Z');
		end if;
	end process;

	mem_data <= (others => 'Z');

	-- now produce the result.
	-- TODO: this tests mem,reg -> reg and reg,mem -> reg
	process (da, reg_1_data)
	begin
		if da = '0'
		then
			result <= '0';

		elsif rising_edge(da)
		then
			if reg_1_data = test_case.output
			then
				result <= '1';
			else
				result <= '0';
			end if;
		end if;
	end process;

	complete <= '1' when da = '1' and clock = '0' else '0';

end architecture;

--- vi:nocin:sw=4 ts=4:fdm=marker
