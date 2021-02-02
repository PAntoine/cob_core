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

	constant	ZEROS		: std_logic_vector(DATA_WIDTH-1 downto 0)	:= (others => '0');

	------------------------------------------------------------
	--- Register constants
	------------------------------------------------------------
	constant	REG_WIDTH		: natural := 32;				-- 32 bit wide.
	constant	REG_ID_WIDTH	: natural := 5;					-- 32 registers.
	constant	NUM_REGISTERS	: natural := 2 ** REG_ID_WIDTH;	-- Just to labour the point.
	
	------------------------------------------------------------
	--- CPU Pipeline Stages
	------------------------------------------------------------
	constant	CPUS_RESET		: std_logic_vector(3 downto 0)	:= "0000";
	constant	CPUS_FETCH		: std_logic_vector(3 downto 0)	:= "0001";
	constant	CPUS_DECODE		: std_logic_vector(3 downto 0)	:= "0010";
	constant	CPUS_EXECUTE	: std_logic_vector(3 downto 0)	:= "0100";
	constant	CPUS_WRITE_BACK	: std_logic_vector(3 downto 0)	:= "1000";

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
		bus_enable		: std_logic;	-- BUS Enable
		bus_rw			: std_logic;	-- BUS read/rw
		sys_reg_enable	: std_logic;	-- System Registers Enable
		gen_reg_enable	: std_logic;	-- General Registers Enable 
		addr_data		: std_logic;	-- Indirect addressing - output to the data or address bus.
		busy			: std_logic;	-- An instruction is currently being processed.
	end record SYSTEM_BUS;  

	------------------------------------------------------------
	--- CPU Flags
	------------------------------------------------------------
	type CPU_FLAGS is record
		carry_flag				: std_logic;
		zero_flag				: std_logic;
		sign_flag				: std_logic;
		minus_flag				: std_logic;
		exception_flag			: std_logic;
		interrupt_flag			: std_logic;
		hardware_interrupt		: std_logic;
		interrupt_waiting		: std_logic;
		interrupts_masked		: std_logic;
		non_masked_interrupt	: std_logic;
		not_used				: std_logic_vector(31 downto 10);
	end record CPU_FLAGS;  

end package definitions;

--- vi:nocin:sw=4 ts=4:fdm=marker
