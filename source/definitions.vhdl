-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : definitions
-- Desc  : This the general definitions that are shared for all components.
--
-- Author: Peter Antoine
-- Date  : 22/01/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package definitions is

	------------------------------------------------------------
	--- General constants
	------------------------------------------------------------
	constant	RW_READ		: std_logic := '0';
	constant	RW_WRITE	: std_logic := '1';
	
	constant	ADDR_WIDTH	: natural := 32;
	constant	DATA_WIDTH	: natural := 32;
	constant 	ADDR_BYTES	: natural := ADDR_WIDTH / 8;

	constant	ZEROS		: std_logic_vector(DATA_WIDTH-1 downto 0)	:= (others => '0');
	constant	ONES		: std_logic_vector(DATA_WIDTH-1 downto 0)	:= (others => '1');

	------------------------------------------------------------
	--- Register constants
	------------------------------------------------------------
	subtype		REG_ID			is std_logic_vector(4 downto 0);
	constant	REG_WIDTH		: natural := 32;				-- 32 bit wide.
	constant	REG_ID_WIDTH	: natural := 5;					-- 32 registers.
	constant	NUM_REGISTERS	: natural := 2 ** REG_ID_WIDTH;	-- Just to labour the point.
	
	------------------------------------------------------------
	--- CPU Pipeline Stages
	------------------------------------------------------------
	subtype		CPU_STATE is std_logic_vector(2 downto 0);
	
	constant	CS_IDLE			: CPU_STATE := "000";
	constant	CS_FETCH_DECODE	: CPU_STATE := "001";
	constant	CS_LOAD			: CPU_STATE := "010";
	constant	CS_EXECUTE		: CPU_STATE := "011";
	constant	CS_STORE		: CPU_STATE := "100";
	constant	CS_EXCEPTION	: CPU_STATE := "101";
	constant	CS_INTERRUPT	: CPU_STATE := "110";
	constant	CS_FINISHED		: CPU_STATE := "111";

	------------------------------------------------------------
	--- System Register constants
	------------------------------------------------------------
	constant	NUM_SYSTEM_REGISTERS	:	natural := 8;		-- The number of system registers.

	constant	SR_PROGRAM_COUNTER	:	std_logic_vector(2 downto 0)	:= "001";	-- program counter
	constant	SR_STACK_POINTER	:	std_logic_vector(2 downto 0)	:= "010";	-- stack pointer
	constant	SR_INT_TABLE		:	std_logic_vector(2 downto 0)	:= "011";	-- interrupt jump table

	constant	SYS_REG_ADDR		:	std_logic	:= '0';		-- system register address mode
	constant	SYS_REG_DATA		:	std_logic	:= '1';		-- system register data mode

	subtype		SYSTEM_REG	is std_logic_vector(2 downto 0);
	
	------------------------------------------------------------
	--- System BUS Registers
	------------------------------------------------------------
	type SYSTEM_BUS is record
		fetch			: std_logic;		-- fetch the next instruction from the bus
		read			: std_logic;		-- register read.
		wait_read		: std_logic;		-- wait state for memory read
		execute			: std_logic;		-- execute the instruction.
		write			: std_logic;		-- register write back.
		wait_write		: std_logic;		-- wait for a memory to finished.
	end record SYSTEM_BUS;  
	
	constant FREE_SYSTEM_BUS: SYSTEM_BUS :=
	(
		fetch			=> 'Z',
		read			=> 'Z',
		wait_read		=> 'Z',
		execute			=> 'Z',
		write			=> 'Z',
		wait_write		=> 'Z'
	);
	
	------------------------------------------------------------
	--- Memory Bus Signals
	------------------------------------------------------------
	type MEMORY_BUS is record
		en			:	std_logic;
		rw			:	std_logic;
		address		:	std_logic_vector(ADDR_WIDTH-1 downto 0);
	end record MEMORY_BUS;  

	constant FREE_MEMORY_BUS : MEMORY_BUS :=
	(
		en			=> 'Z',
		rw			=> 'Z',
		address		=> (others => 'Z')
	);
	
	constant INIT_MEMORY_BUS : MEMORY_BUS :=
	(
		en			=> '0',
		rw			=> '0',
		address		=> (others => '0')
	);
	
	------------------------------------------------------------
	--- Register Bus Signals
	------------------------------------------------------------
	subtype OP_AM_TYPE is std_logic_vector(1 downto 0);
	
	subtype OP_AM_MODE	is natural range 28 downto 27;	-- Address mode
	constant	OP_AM_IMMEDIATE			:	OP_AM_TYPE := "00";
	constant	OP_AM_MEMORY_DIRECT		:	OP_AM_TYPE := "01";
	constant	OP_AM_REGISTER			:	OP_AM_TYPE := "10";
	constant	OP_AM_REGISTER_INDIRECT	:	OP_AM_TYPE := "11";

	type OPERAND_BUS is record
		en			: std_logic;								-- enable the idle unit.
		mode		: OP_AM_TYPE;								-- The type of the address load.
		address		: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- the address to read.
	end record OPERAND_BUS;

	constant FREE_OPERAND_BUS : OPERAND_BUS :=
	(
		en			=> 'Z',
		mode		=> (others => 'Z'),
		address		=> (others => 'Z')
	);
	
	constant INIT_OPERAND_BUS : OPERAND_BUS :=
	(
		en			=> '0',
		mode		=> (others => '0'),
		address		=> (others => '0')
	);
	
	------------------------------------------------------------
	--- Store Unit Bus Signals.
	------------------------------------------------------------
	type STORE_BUS is record
		en		:	std_logic;
		mode	:	OP_AM_TYPE;
		address	:	std_logic_vector(ADDR_WIDTH-1 downto 0);
	end record STORE_BUS;

	constant FREE_STORE_BUS : STORE_BUS :=
	(
		en		=> 'Z',
		mode	=> (others => 'Z'),
		address	=> (others => 'Z')
	);
	
	constant INIT_STORE_BUS : STORE_BUS :=
	(
		en		=> '0',
		mode	=> (others => '0'),
		address	=> (others => '0')
	);

	------------------------------------------------------------
	--- Register Bus Signals
	------------------------------------------------------------
	type REGISTER_BUS is record
		en		:	std_logic;
		rw		:	std_logic;
		address	:	REG_ID;
	end record REGISTER_BUS;  

	constant FREE_REGISTER_BUS : REGISTER_BUS :=
	(
		en		=> 'Z',
		rw		=> 'Z',
		address	=> (others => 'Z')
	);
	
	constant INIT_REGISTER_BUS : REGISTER_BUS :=
	(
		en		=> '0',
		rw		=> '0',
		address	=> (others => '0')
	);

	------------------------------------------------------------
	--- Stack Bus Signals
	------------------------------------------------------------
	subtype		INT_ID_TYPE		is std_logic_vector(3 downto 0);	-- 16 interrupt vectors - 00 and 01.
	subtype		INT_ID_RANGE	is natural range 3 downto 0;
	
	subtype		STACK_MODE_TYPE is std_logic_vector(2 downto 0);
	constant	SR_READ		:	STACK_MODE_TYPE := "000";
	constant	SR_PUSH		:	STACK_MODE_TYPE := "001";
	constant	SR_CALL		:	STACK_MODE_TYPE := "010";
	constant	SR_SAVE		:	STACK_MODE_TYPE := "011";
	constant	SR_POP		:	STACK_MODE_TYPE := "100";
	constant	SR_RET		:	STACK_MODE_TYPE := "101";
	constant	SR_RESTORE	:	STACK_MODE_TYPE := "110";
	constant	SR_SET		:	STACK_MODE_TYPE := "111";

	type STACK_BUS is record
		en		:	std_logic;
		mode	:	STACK_MODE_TYPE;
		id		:	INT_ID_TYPE;
		address	:	std_logic_vector(ADDR_WIDTH-1 downto 0);
	end record STACK_BUS;  

	constant FREE_STACK_BUS : STACK_BUS :=
	(
		en		=> 'Z',
		mode	=> (others => 'Z'),
		id		=> (others => 'Z'),
		address	=> (others => 'Z')
	);
	
	constant INIT_STACK_BUS : STACK_BUS :=
	(
		en		=> '0',
		mode	=> (others => '0'),
		id		=> (others => '0'),
		address	=> (others => '0')
	);

	------------------------------------------------------------
	--- CPU Flags
	------------------------------------------------------------
	type CPU_FLAGS is record
		carry_flag				: std_logic;
		zero_flag				: std_logic;
		sign_flag				: std_logic;
		exception_flag			: std_logic;
		interrupt_flag			: std_logic;
		hardware_interrupt		: std_logic;
		interrupt_waiting		: std_logic;
		interrupts_masked		: std_logic;
		non_masked_interrupt	: std_logic;
		interrupt_id			: INT_ID_TYPE;
	end record CPU_FLAGS;  

	constant INIT_CPU_FLAGS : CPU_FLAGS :=
	(
		carry_flag				=> '0',
		zero_flag				=> '0',
		sign_flag				=> '0',
		exception_flag			=> '0',
		interrupt_flag			=> '0',
		hardware_interrupt		=> '0',
		interrupt_waiting		=> '0',
		interrupts_masked		=> '0',
		non_masked_interrupt	=> '0',
		interrupt_id			=> (others => '0')
	);

	constant FREE_CPU_FLAGS : CPU_FLAGS :=
	(
		carry_flag				=> 'Z',
		zero_flag				=> 'Z',
		sign_flag				=> 'Z',
		exception_flag			=> 'Z',
		interrupt_flag			=> 'Z',
		hardware_interrupt		=> 'Z',
		interrupt_waiting		=> 'Z',
		interrupts_masked		=> 'Z',
		non_masked_interrupt	=> 'Z',
		interrupt_id			=> (others => 'Z')
	);

	function flagsToVector ( flags : CPU_FLAGS ) return std_logic_vector;
	function vectorToFlags ( vector_value : std_logic_vector(DATA_WIDTH-1 downto 0 )) return CPU_FLAGS;

end package definitions;

package body definitions is

	function flagsToVector ( flags : CPU_FLAGS ) return std_logic_vector is
	begin
		return	flags.carry_flag & flags.zero_flag & flags.sign_flag & flags.exception_flag & flags.interrupt_flag & flags.hardware_interrupt &
				flags.interrupt_waiting & flags.interrupts_masked & flags.non_masked_interrupt & flags.interrupt_id & ZEROS(31 downto 13);
	end function;


	function vectorToFlags ( vector_value : std_logic_vector(DATA_WIDTH-1 downto 0) ) return CPU_FLAGS is
		variable dout : CPU_FLAGS;
	begin
		dout.carry_flag				:= vector_value(0);
		dout.zero_flag				:= vector_value(1);
		dout.sign_flag				:= vector_value(2);
		dout.exception_flag			:= vector_value(3);
		dout.interrupt_flag			:= vector_value(4);
		dout.hardware_interrupt		:= vector_value(5);
		dout.interrupt_waiting		:= vector_value(6);
		dout.interrupts_masked		:= vector_value(7);
		dout.non_masked_interrupt	:= vector_value(8);
		dout.interrupt_id			:= vector_value(12 downto 9);

		return dout;
	end function;

end definitions;

--- vi:nocin:sw=4 ts=4:fdm=marker
