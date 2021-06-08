----------------------------------------------------------------------------------
--			   _____ ____  ____		_____
--			  / ____/ __ \|  _ \   / ____|
--			 | |   | |	| | |_) | | |	  ___  _ __ ___
--			 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--			 | |___| |__| | |_) | | |___| (_) | | |  __/
--			  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : int_except_tb_defines
-- Desc  : The test defines for the logic and test be defines.
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

package int_except_tb_defines is
	---------------------------------------------------------------
	--- Test cases for testing the stack.
	---------------------------------------------------------------
	-- stack register only.
	constant	TEST_SET_VALUE		:	integer := 0;
	constant	TEST_SR_PUSH		:	integer := 1;
	constant	TEST_SR_POP			:	integer := 2;
	constant	TEST_SR_CALL		:	integer := 3;
	constant	TEST_SR_RET			:	integer := 4;
	constant	TEST_SR_SAVE		:	integer := 5;
	constant	TEST_SR_RESTORE		:	integer := 6;
	
	-- interrupt/exception unit tests.
	constant	TEST_IEU_SET_00		:	integer := 7;
	constant	TEST_IEU_SET_FF		:	integer := 8;
	constant	TEST_IEU_INT_00		:	integer := 9;
	constant	TEST_IEU_IRET_00	:	integer := 10;
	constant	TEST_IEU_INT_FF		:	integer := 15;
	constant	TEST_IEU_IRET_FF	:	integer := 12;
	constant	TEST_FINISH			:	integer := 13;

	---------------------------------------------------------------
	--- Test structures
	---------------------------------------------------------------
	type TEST_ADDRESS_TYPE is array(0 to 1) of std_logic_vector(ADDR_WIDTH-1 downto 0);
	type TEST_VALUES_TYPE  is array(0 to 1) of std_logic_vector(DATA_WIDTH-1 downto 0);

	type TEST_CASE2_TYPE is record
		mode		:	STACK_MODE_TYPE;
		flags		:	CPU_FLAGS;
		flags_after	:	CPU_FLAGS;
		pc			:	std_logic_vector(ADDR_WIDTH-1 downto 0);
		data		:	std_logic_vector(DATA_WIDTH-1 downto 0);
		mem_address	:	TEST_ADDRESS_TYPE;
		values		:	TEST_VALUES_TYPE;
	end record TEST_CASE2_TYPE;
   
	type TEST_CASE_ARRAY is array(integer range <>) of TEST_CASE2_TYPE;

	---------------------------------------------------------------
	--- Test Cases
	---------------------------------------------------------------
	constant A_CPU_FLAGS : CPU_FLAGS :=
	(
		carry_flag				=> '0',
		zero_flag				=> '1',
		sign_flag				=> '0',
		exception_flag			=> '1',
		interrupt_flag			=> '0',
		hardware_interrupt		=> '1',
		interrupt_waiting		=> '0',
		interrupts_masked		=> '1',
		non_masked_interrupt	=> '0',
		interrupt_id			=> (others => '1')
	);
	
	constant B_CPU_FLAGS : CPU_FLAGS :=
	(
		carry_flag				=> '1',
		zero_flag				=> '0',
		sign_flag				=> '1',
		exception_flag			=> '0',
		interrupt_flag			=> '1',
		hardware_interrupt		=> '0',
		interrupt_waiting		=> '1',
		interrupts_masked		=> '0',
		non_masked_interrupt	=> '1',
		interrupt_id			=> (others => '0')
	);

	constant sr_test_cases : TEST_CASE_ARRAY :=
	(
		(SR_SET,	INIT_CPU_FLAGS, INIT_CPU_FLAGS,	x"00001000", x"00010000", (x"00000000", x"00000000"), (x"FFFFFFFF", x"FFFFFFFF")),
		(SR_PUSH,	INIT_CPU_FLAGS, INIT_CPU_FLAGS,	x"FFFFFFFF", x"FF000000", (x"0000FFFC", x"00000000"), (x"FF000000", x"FFFFFFFF")),
		(SR_POP,	INIT_CPU_FLAGS, INIT_CPU_FLAGS,	x"00002000", x"FF000000", (x"0000FFFC", x"00000000"), (x"FF000000", x"FFFFFFFF")),
		(SR_CALL,	INIT_CPU_FLAGS, INIT_CPU_FLAGS,	x"00003000", x"F0F0F0F0", (x"0000FFfC", x"00000000"), (x"00003000", x"FFFFFFFF")),
		(SR_RET,	INIT_CPU_FLAGS, INIT_CPU_FLAGS,	x"0F0F0F0F", x"F0F0F0F0", (x"0000fffc", x"00000000"), (x"00003000", x"FFFFFFFF")),
		(SR_SAVE,	A_CPU_FLAGS,    B_CPU_FLAGS,	x"00004000", x"F0F0F0F0", (x"0000fffc", x"0000FFf8"), (flagsToVector(A_CPU_FLAGS), x"00004000")),
		(SR_RESTORE,B_CPU_FLAGS,    A_CPU_FLAGS,	x"0F0F0F0F", x"F0F0F0F0", (x"0000fff8", x"0000FFfc"), (x"00004000", flagsToVector(A_CPU_FLAGS))),
		
		-- interrupt unit tests.
		(SR_RESTORE,B_CPU_FLAGS,    A_CPU_FLAGS,	x"0F0F0F0F", x"F0F0F0F0", (x"0000fff8", x"0000FFfc"), (x"00004000", flagsToVector(A_CPU_FLAGS))),
		(SR_RESTORE,B_CPU_FLAGS,    A_CPU_FLAGS,	x"0F0F0F0F", x"F0F0F0F0", (x"0000fff8", x"0000FFfc"), (x"00004000", flagsToVector(A_CPU_FLAGS)))
	);
	
	---------------------------------------------------------------
	--- Test Cases
	---------------------------------------------------------------
	function toHNibble(a_in: std_logic_vector(3 downto 0)) return character;
	function toHString(a_in: std_logic_vector(DATA_WIDTH-1 downto 0)) return string;

	function GetTestMode (index : integer) return STACK_MODE_TYPE;
	function GetTestPC (index : integer) return std_logic_vector;
	function GetTestFlagsBefore (index : integer) return CPU_FLAGS;
	function GetTestFlagsAfter	(index : integer) return CPU_FLAGS;
	function GetTestData (index : integer) return std_logic_vector;
	function GetTestValue (index : integer; item : integer) return std_logic_vector;
	function GetTestAddress (index : integer; item : integer) return std_logic_vector;

end package int_except_tb_defines;

package body int_except_tb_defines is
	
	function GetTestPC (index : integer) return std_logic_vector is
		variable test_cases : TEST_CASE_ARRAY(0 to sr_test_cases'length-1) := sr_test_cases;
	begin
		return test_cases(index).pc;
	end function;

	function GetTestMode (index : integer) return STACK_MODE_TYPE is
		variable test_cases : TEST_CASE_ARRAY(0 to sr_test_cases'length-1) := sr_test_cases;
	begin
		return test_cases(index).mode;
	end function;
	
	function GetTestFlagsBefore (index : integer) return CPU_FLAGS is
		variable test_cases : TEST_CASE_ARRAY(0 to sr_test_cases'length-1) := sr_test_cases;
	begin
		return test_cases(index).flags;
	end function;

	function GetTestFlagsAfter	(index : integer) return CPU_FLAGS is
		variable test_cases : TEST_CASE_ARRAY(0 to sr_test_cases'length-1) := sr_test_cases;
	begin
		return test_cases(index).flags_after;
	end function;
	
	function GetTestData (index : integer) return std_logic_vector is
		variable test_cases : TEST_CASE_ARRAY(0 to sr_test_cases'length-1) := sr_test_cases;
	begin
		return test_cases(index).data;
	end function;
	
	function GetTestAddress (index : integer; item : integer) return std_logic_vector is
		variable test_cases : TEST_CASE_ARRAY(0 to sr_test_cases'length-1) := sr_test_cases;
	begin
		return test_cases(index).mem_address(item);
	end function;
	
	function GetTestValue (index : integer; item : integer) return std_logic_vector is
		variable test_cases : TEST_CASE_ARRAY(0 to sr_test_cases'length-1) := sr_test_cases;
	begin
		return test_cases(index).values(item);
	end function;
	
	function toHNibble(a_in: std_logic_vector(3 downto 0)) return character is
		variable dout : character;
	begin
		case a_in is
			when "0000"	=> dout := '0';
			when "0001"	=> dout := '1';
			when "0010"	=> dout := '2';
			when "0011"	=> dout := '3';
			when "0100"	=> dout := '4';
			when "0101"	=> dout := '5';
			when "0110"	=> dout := '6';
			when "0111"	=> dout := '7';
			when "1000"	=> dout := '8';
			when "1001"	=> dout := '9';
			when "1010"	=> dout := 'A';
			when "1011"	=> dout := 'B';
			when "1100"	=> dout := 'C';
			when "1101"	=> dout := 'D';
			when "1110"	=> dout := 'E';
			when "1111"	=> dout := 'F';
			when others => dout := 'X';
		end case;

		return dout;
	end function;

	function toHString(a_in: std_logic_vector(DATA_WIDTH-1 downto 0)) return string is
		variable dout : string(0 to 7);
	begin
		dout(0) := toHNibble(a_in(31 downto 28));
		dout(1) := toHNibble(a_in(27 downto 24));
		dout(2) := toHNibble(a_in(23 downto 20));
		dout(3) := toHNibble(a_in(19 downto 16));
		dout(4) := toHNibble(a_in(15 downto 12));
		dout(5) := toHNibble(a_in(11 downto  8));
		dout(6) := toHNibble(a_in( 7 downto  4));
		dout(7) := toHNibble(a_in( 3 downto  0));

		return dout;
	end function;

end int_except_tb_defines;
--- vi:nocin:sw=4 ts=4:fdm=marker
