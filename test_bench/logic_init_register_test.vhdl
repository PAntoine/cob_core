-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--					
--
-- Name  : logic_unit_test_func
-- Desc  : These are the test procedures for testing the logic unit.
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

use work.definitions.all;
use work.instructions.all;
use work.logic_tb_defines.all;

entity LogicUnitRegisterTest is
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
end entity LogicUnitRegisterTest;

architecture behv of LogicUnitRegisterTest is
	----------------------------------------------------
	--- LogicUnitRegisterTest
	---
	--- This procedure will run through the test cases
	--- and make sure the logic of the commands matches
	--- what is expected. It will only use the same
	--- registers, this is a pure procedure only test.
	----------------------------------------------------
begin
	-- let make or state item.
	instruction <= test_case.opcode & IU_LOGIC & LI_DA_RRR & "00001" & "00010" & "00011" & "000"; -- when start = '1' else (others => 'Z');

	sel <= '1' when start = '1' else '0';

	-- handle the first register
	-- this one should have the result
	-- TODO: should test for illegal bus
	--       states.
	process (start, reg_1_en, reg_1_rw)
	begin
		if start = '1' and reg_1_en = '1' and reg_1_rw = RW_READ
		then
			reg_1_data <= test_case.a_input;
		else
			reg_1_data <= (others => 'Z');
		end if;
	end process;

	-- just output for bus states.
	process (start, reg_2_en)
	begin
		if start = '1' and reg_2_en = '1'
		then
			reg_2_data <= test_case.b_input;
		else
			reg_2_data <= (others => 'Z');
		end if;
	end process;

	-- now produce the result.
	result <= '1' when da = '1' and reg_1_data = test_case.output else '0';
	complete <= '1' when da = '1' and clock = '0' else '0';

end architecture;

--- vi:nocin:sw=4 ts=4:fdm=marker
