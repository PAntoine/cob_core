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
	constant	REG_WIDTH		: natural := 32;				-- Supporting 64 general purpose registers.
	constant	REG_ID_WIDTH	: natural := 4;					-- The width of the register id.
	constant	NUM_REGISTERS	: natural := 2 ** REG_ID_WIDTH;	-- Just to labour the point.
	
	------------------------------------------------------------
	--- System Register constants
	------------------------------------------------------------
	constant	NUM_SYSTEM_REGISTERS	:	natural := 8;		-- The number of system registers.

	constant	SR_PROGRAM_COUNTER	:	std_logic_vector(2 downto 0)	:= "001";	-- program counter
	constant	SR_STACK_POINTER	:	std_logic_vector(2 downto 0)	:= "010";	-- stack pointer
	constant	SR_INT_TABLE		:	std_logic_vector(2 downto 0)	:= "011";	-- interrupt jump table

	subtype		SYSTEM_REG	is std_logic_vector(2 downto 0);
	
	------------------------------------------------------------
	--- System BUS Registers
	------------------------------------------------------------
	type SYSTEM_BUS is record
		bus_enable		: std_logic;	-- BUS Enable
		sys_reg_enable	: std_logic;	-- System Registers Enable
		gen_reg_enable	: std_logic;	-- General Registers Enable 
	end record SYSTEM_BUS;  


end package definitions;

--- vi:nocin:sw=4 ts=4:fdm=marker
