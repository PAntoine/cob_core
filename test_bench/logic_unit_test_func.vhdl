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

package LogicUnitTestProcedures is
	---------------------------------------------------------------
	--- Test structures
	---------------------------------------------------------------
	type TEST_CASE_TYPE is record
		opcode	:	std_logic_vector(OP_CODE_WIDTH-1 downto 0);
		a_input	:	std_logic_vector(DATA_WIDTH-1 downto 0);
		b_input :	std_logic_vector(DATA_WIDTH-1 downto 0);
		output	:	std_logic_vector(DATA_WIDTH-1 downto 0);
		flags	:	CPU_FLAGS;
	end record TEST_CASE_TYPE;

    ----------------------------------------------------
    --- Test Procedures
    ----------------------------------------------------
	procedure RunLogicTestCase( clock		: in	std_logic;
								start		: in	std_logic;
								da          : in    std_logic;
								test_case	: in	TEST_CASE_TYPE;
								reg_bus		: inout	REGISTER_BUS;
								reg_1_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
								reg_2_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
								sel			: out	std_logic;
								result		: out	std_logic;
								complete	: out	std_logic);

	--procedure RunRegIndexTestCase(	a_reg	: in	REG_ID;
	--								b_reg	: in	REG_ID;
	--								output	: in	REG_ID );

end package LogicUnitTestProcedures;

package body LogicUnitTestProcedures is
	----------------------------------------------------
	--- RunLogicTestCase
	---
	--- This procedure will run through the test cases
	--- and make sure the logic of the commands matches
	--- what is expected. It will only use the same
	--- registers, this is a pure procedure only test.
	----------------------------------------------------
	procedure RunLogicTestCase( clock		: in	std_logic;
								start		: in	std_logic;
								da          : in    std_logic;
								test_case	: in	TEST_CASE_TYPE;
								reg_bus		: inout	REGISTER_BUS;
								reg_1_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
								reg_2_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
								sel			: out	std_logic;
								result		: out	std_logic;
								complete	: out	std_logic) is

		--- now lets put an instruction in.
		variable state        : std_logic_vector(5 downto 0);
        variable instruction : INSTRUCTION_TYPE;

	begin

		-- put the instruction on to the command.
		instruction := test_case.opcode & IU_LOGIC & "000" & "00001" & "00010" & "00011" & "000";

		-- let make or state item.
		state := reg_bus.reg_1_rw & reg_bus.reg_2_rw & reg_bus.reg_1_en & reg_bus.reg_2_en & start & da;

		case state is
			when "XX0010" =>		-- lets start the instruction
				sel			:= '1';
				reg_1_data	:= (others => 'Z');
				reg_2_data	:= (others => 'Z');
				complete	:= '0';

			when "001X10" =>		-- start the test
				sel			:= '1';
				reg_1_data	:= test_case.a_input;
				reg_2_data	:= test_case.b_input;
				complete	:= '0';
			
			when "101010" =>		-- we have a write to the output register
				sel			:= '1';
				assert reg_1_data /= test_case.output report "logic command: " & std_logic_vector'image(op_code) & " failed " & std_logic_vector'image(reg_1_data) & " != " & std_logic_vector'(test_case.output);
				complete	:= '0';
			
			when "101011" =>		-- data is available - the command has finished.
				sel			:= '0';
				assert reg_1_data /= test_case.output report "logic command: " & std_logic_vector'image(op_code) & " failed " & std_logic_vector'image(reg_1_data) & " != " & std_logic_vector'(test_case.output);
				complete	:= '1';

			when others => report "bad state in test case (LogicUnitTestProcedures)";
		end case;

	end procedure;

end LogicUnitTestProcedures;

--- vi:nocin:sw=4 ts=4:fdm=marker
