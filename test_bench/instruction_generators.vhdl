----------------------------------------------------------------------------------
--			   _____ ____  ____		_____
--			  / ____/ __ \|  _ \   / ____|
--			 | |   | |	| | |_) | | |	  ___  _ __ ___
--			 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--			 | |___| |__| | |_) | | |___| (_) | | |  __/
--			  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : logic_tb_defines
-- Desc  : The logic test bed defines.
--
-- Author: Peter Antoine
-- Date  : 22/01/2021
-----------------------------------------------------------------------------------
--					   Copyright (c) 2021 Peter Antoine
--							  All rights Reserved.
--					  Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.definitions.all;
use work.instructions.all;
use ieee.numeric_std.all;
use work.logic_tb_defines.all;

package instruction_generators is
	----------------------------------------------------
	--- functions
	----------------------------------------------------
	function GetNopTestInstruction			(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE;
	function GetLogicImmdiateInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE;
	function GetLogicMemoryInstruction		(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE;
	function GetLogicRegisterInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE;
	function GetLogicSingleInstruction		(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE;
	function GetLogicTestValues 			(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return TEST_CASE_TYPE;


end package instruction_generators;

package body instruction_generators is
	function GetNopTestInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE is
		variable dout : INSTRUCTION_TYPE;
	begin
		if unsigned(a_in) < 255
		then
			dout := CI_NOP & IU_CONTROL & ZEROS(20 downto 0);
		else
			dout := CI_BRANCH & IU_CONTROL & ZEROS(20 downto 0);  -- TODO: need to sort out a jump target.
		end if;

		return dout;
	end function;

	function GetLogicImmdiateInstruction (a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE is
		variable tests : TEST_CASE_ARRAY(0 to immed_test_cases'length-1) := immed_test_cases;
		variable index : integer;
		variable dout : INSTRUCTION_TYPE;
	begin
		index := to_integer(unsigned(a_in(ADDR_WIDTH-4 downto 0)));

		if index < immed_test_cases'length-1
		then
			dout := tests(index).opcode & IU_LOGIC & LI_DA_RIR & "00001" & "00011" & tests(index).b_input(7 downto 0);
		else
			dout := CI_BRANCH & IU_CONTROL & ZEROS(20 downto 0);  -- TODO: need to sort out a jump target.
		end if;
		
		return dout;
	end function;

	function GetLogicMemoryInstruction (a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE is
		variable tests : TEST_CASE_ARRAY(0 to immed_test_cases'length-1) := immed_test_cases;
		variable index : integer;
		variable dout : INSTRUCTION_TYPE;
	begin
		index := to_integer(unsigned(a_in(ADDR_WIDTH-4 downto 0)));

		if index < immed_test_cases'length-1
		then
			dout := tests(index).opcode & IU_LOGIC & LI_DA_RIR & "00001" & "00011" & tests(index).b_input(7 downto 0);
		else
			dout := CI_BRANCH & IU_CONTROL & ZEROS(20 downto 0);  -- TODO: need to sort out a jump target.
		end if;
		
		return dout;
	end function;

	function GetLogicRegisterInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE is
		variable tests : TEST_CASE_ARRAY(0 to lsl_test_cases'length-1) := lsl_test_cases;
		variable index : integer;
		variable dout : INSTRUCTION_TYPE;
	begin
		index := to_integer(unsigned(a_in(ADDR_WIDTH-4 downto 0)))/4;

		if index < lsl_test_cases'length-1
		then
			dout := tests(index).opcode & IU_LOGIC & LI_DA_RRR & "00001" & "00010" & "00011" & "000";
		else
			dout := CI_BRANCH & IU_CONTROL & ZEROS(20 downto 0);  -- TODO: need to sort out a jump target.
		end if;

		return dout;
	end function;

	function GetLogicSingleInstruction		(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return INSTRUCTION_TYPE is
		variable tests : TEST_CASE_ARRAY(0 to immed_test_cases'length-1) := immed_test_cases;
		variable index : integer;
		variable dout : INSTRUCTION_TYPE;
	begin
		index := to_integer(unsigned(a_in(ADDR_WIDTH-4 downto 0)))/4;

		if index < immed_test_cases'length-1
		then
			dout := tests(index).opcode & IU_LOGIC & LI_DA_R_R & "00001" & "00010" & "00011" & "000";
		else
			dout := CI_BRANCH & IU_CONTROL & ZEROS(20 downto 0);  -- TODO: need to sort out a jump target.
		end if;
		
		return dout;
	end function;
	
	function GetLogicTestValues (a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return TEST_CASE_TYPE is
			variable tests : TEST_CASE_ARRAY(0 to lsl_test_cases'length-1) := lsl_test_cases;
			variable index : integer;
			variable dout : TEST_CASE_TYPE;
	begin
			index := to_integer(unsigned(a_in(ADDR_WIDTH-4 downto 0)))/4;

			if index < lsl_test_cases'length-1
			then
					dout := tests(index);
			else
					dout := NULL_TEST;
			end if;

			return dout;
	end function;


end instruction_generators;
--- vi:nocin:ai:sw=4 ts=4:fdm=marker
