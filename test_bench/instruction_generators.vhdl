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
	--- test offsets
	----------------------------------------------------
	subtype TEST_OFFSET is std_logic_vector(2 downto 0);
	constant	TO_LOAD_STORE	:	TEST_OFFSET := "000";
	constant	TO_BRANCH		:	TEST_OFFSET := "001";
	constant	TO_LOGIC		:	TEST_OFFSET := "010";
	constant	TO_NOP			:	TEST_OFFSET := "011";
	constant	TO_HALT			:	TEST_OFFSET := "111";

	----------------------------------------------------
	--- functions
	----------------------------------------------------
	function GetLoadStoreTestInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr:	TEST_OFFSET) return INSTRUCTION_TYPE;
	
	function GetBranchTestInstruction		(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr:	TEST_OFFSET) return INSTRUCTION_TYPE;
	
	function GetNopTestInstruction			(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr:	TEST_OFFSET) return INSTRUCTION_TYPE;
	
	function GetLogicRegisterInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr:	TEST_OFFSET) return INSTRUCTION_TYPE;
	function GetLogicImmediateInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr:	TEST_OFFSET) return INSTRUCTION_TYPE;
	function GetLogicMemoryInstruction		(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr:	TEST_OFFSET) return INSTRUCTION_TYPE;
	
	function GetLogicTestValues				(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0)) return TEST_CASE_TYPE;


end package instruction_generators;

package body instruction_generators is

	function GetNopTestInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr: TEST_OFFSET) return INSTRUCTION_TYPE is
		variable dout : INSTRUCTION_TYPE;
	begin
		if unsigned(a_in) < 255
		then
			dout := CI_NOP & "0000" & IU_CONTROL & ZEROS(20 downto 0);
		else
			dout := IU_CONTROL & OP_AM_IMMEDIATE & CI_BRANCH & n_addr & "00000000000000000000";
		end if;

		return dout;
	end function;

	function GetLoadStoreTestInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr: TEST_OFFSET) return INSTRUCTION_TYPE is
		variable dout : INSTRUCTION_TYPE;
	begin
		case a_in(10 downto 7) is
			when "0000" =>	-- immediate load register tests (load register from immediate data).
				dout := IU_LOAD_STORE & LS_MOVE_IMM & OP_AM_IMMEDIATE & OP_AM_REGISTER & a_in(6 downto 2) & "0000000000000" & a_in(6 downto 2);

			when "0001" =>	-- Register indirect.
				dout := IU_LOAD_STORE & LS_MOVE_IMM & OP_AM_IMMEDIATE & OP_AM_REGISTER_INDIRECT & a_in(6 downto 2) & "1111111111000" & a_in(6 downto 2);
			
			when "0010" =>	-- Register to memory (immediate address).
				dout := IU_LOAD_STORE & LS_MOVE_IMM & OP_AM_REGISTER  & OP_AM_MEMORY_DIRECT & a_in(6 downto 2) & "1111000011110" & a_in(6 downto 2);

			when "0011" =>	-- register indirect to register indirect.
				dout := IU_LOAD_STORE & LS_MOVE & OP_AM_REGISTER_INDIRECT & OP_AM_REGISTER_INDIRECT & a_in(6 downto 2) & "00001" & "0000000000000";

			when "0100" =>	-- register to register indirect.
				dout := IU_LOAD_STORE & LS_MOVE & OP_AM_REGISTER & OP_AM_REGISTER_INDIRECT & a_in(6 downto 2) & "00001" & "0000000000000";

			when "0101" =>	-- Register to memory (immediate address).
				dout := IU_LOAD_STORE & LS_MOVE & OP_AM_REGISTER_INDIRECT & OP_AM_MEMORY_DIRECT & a_in(6 downto 2) & "000000000000000000";

			-- this should be the last one - now goto next instruction (at the end).
			when "0110" =>	-- Register to register moves.
				case a_in(7 downto 0) is
					-- register to register tests.
					when x"00" =>	dout := IU_LOAD_STORE & LS_MOVE & OP_AM_REGISTER & OP_AM_REGISTER & "00000" & "00001" & "0000000000000";
					when x"04" =>	dout := IU_LOAD_STORE & LS_MOVE & OP_AM_REGISTER & OP_AM_REGISTER & "00001" & "00010" & "0000000000000";
					when x"08" =>	dout := IU_LOAD_STORE & LS_MOVE & OP_AM_REGISTER & OP_AM_REGISTER & "00000" & "00000" & "0000000000000";
					when x"0c" =>	dout := IU_LOAD_STORE & LS_MOVE & OP_AM_REGISTER & OP_AM_REGISTER & "10000" & "00000" & "0000000000000";
					when x"10" =>	dout := IU_LOAD_STORE & LS_MOVE & OP_AM_REGISTER & OP_AM_REGISTER & "11111" & "10101" & "0000000000000";
					when others =>
						dout := IU_CONTROL & OP_AM_IMMEDIATE & CI_BRANCH & n_addr & "00000000000000000000";
				end case;
			
			when others	 => dout := IU_CONTROL & OP_AM_IMMEDIATE & CI_BRANCH & n_addr & "00000000000000000000";
		end case;

		return dout;
	end function;

	function GetBranchTestInstruction	(a_in: in std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr: in TEST_OFFSET) return INSTRUCTION_TYPE is
		variable dout : INSTRUCTION_TYPE;
	begin
		
		if a_in = x"00400800"
		then
			dout := OP_AM_MEMORY_DIRECT & "00" & CI_BRANCH & IU_CONTROL & "000000000001000000000";
		else
			dout := IU_CONTROL & OP_AM_IMMEDIATE & CI_BRANCH & n_addr & "00000000000000000000";
		end if;

		return dout;
	end function;
	
	function GetLogicRegisterInstruction	(a_in: std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr: TEST_OFFSET) return INSTRUCTION_TYPE is
		variable tests : TEST_CASE_ARRAY(0 to lsl_test_cases'length-1) := lsl_test_cases;
		variable index : integer;
		variable dout : INSTRUCTION_TYPE;
	begin
		index := to_integer(unsigned(a_in(19 downto 0)))/4;

		if index < lsl_test_cases'length-1
		then
			dout := IU_LOGIC & tests(index).opcode & OP_AM_REGISTER & OP_AM_REGISTER & OP_AM_REGISTER & "00001" & "00010" & "00011" & "0000";
		else
			dout := IU_CONTROL & "00" & CI_BRANCH & n_addr & "00000000000000000000";
		end if;

		return dout;
	end function;

	function GetLogicImmediateInstruction (a_in: std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr: TEST_OFFSET) return INSTRUCTION_TYPE is
		variable tests : TEST_CASE_ARRAY(0 to immed_test_cases'length-1) := immed_test_cases;
		variable index : integer;
		variable dout : INSTRUCTION_TYPE;
	begin
		index := to_integer(unsigned(a_in(19 downto 0)))/4;

		if index < immed_test_cases'length-1
		then
			dout := IU_LOGIC & tests(index).opcode & OP_AM_REGISTER & OP_AM_IMMEDIATE & OP_AM_REGISTER & "00001" & tests(index).b_input(4 downto 0) & "00011" & "0000";
		else
			dout := OP_AM_IMMEDIATE & "00" & CI_BRANCH & IU_CONTROL & "100000000000000000000";
		end if;
		
		return dout;
	end function;

	function GetLogicMemoryInstruction (a_in: std_logic_vector(ADDR_WIDTH-1 downto 0); n_addr: TEST_OFFSET) return INSTRUCTION_TYPE is
		variable tests : TEST_CASE_ARRAY(0 to lsl_test_cases'length-1) := lsl_test_cases;
		variable index : integer;
		variable dout : INSTRUCTION_TYPE;
	begin
		index := to_integer(unsigned(a_in(19 downto 0)))/4;

		if index < lsl_test_cases'length-1
		then
			dout := IU_LOGIC & tests(index).opcode & OP_AM_REGISTER_INDIRECT & OP_AM_REGISTER_INDIRECT & OP_AM_REGISTER & "00001" & "00010" & "00011" & "0000";
		else
			dout := IU_CONTROL & "00" & CI_BRANCH & n_addr & "00000000000000000000";
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
