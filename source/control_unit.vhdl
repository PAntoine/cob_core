-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : control unit
-- Desc  : This entity handles the logic instructions.
--
-- Author: Peter Antoine
-- Date  : 03/03/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.definitions.all;
use work.instructions.all;

entity ControlUnit is
		port(
				enable			: in 	std_logic;			-- are we running?
				da				: out	std_logic;			-- data available - the command has completed.
				sys_bus			: in 	SYSTEM_BUS;			-- the system bus controls
				op_code			: in 	OP_CODE_TYPE;		-- the op code
				flags			: in	CPU_FLAGS;			-- guess what the flags.
				addr_mode_bus	: out	ADDRESS_MODE_BUS;	-- drive the address bus.
				a_op			: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand A
				pc				: in	std_logic_vector(ADDR_WIDTH-1 downto 0);	-- program counter value
				accumulator		: out	std_logic_vector(DATA_WIDTH-1 downto 0)		-- The accumulator  for the results.
		);
end ControlUnit;

architecture synth of ControlUnit is

	signal internal_addr	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal am_value			: CI_AM_TYPE;
begin
	am_value <= op_code(OP_CODE_WIDTH-1 downto OP_CODE_WIDTH-2);

	process (enable, am_value)
	begin
		if enable = '0'
		then
			addr_mode_bus <= FREE_ADDRESS_MODE_BUS;
		else
			case am_value is
				when CI_AM_IMMEDIATE			=> addr_mode_bus <= IMM_21_TO_PC_ADDRESS_MODE_BUS;
				when CI_AM_IMMEDIATE_REL		=> addr_mode_bus <= IMM_21_TO_PC_ADDRESS_MODE_BUS;
				when CI_AM_REGISTER_DIRECT		=> addr_mode_bus <= REGISTER_1_TO_PC_ADDRESS_MODE;
				when CI_AM_REGISTER_INDIRECT	=> addr_mode_bus <= REGISTER_1_INDIRECT_TO_PC_ADDRESS_MODE;
				when others 					=> addr_mode_bus <= INIT_ADDRESS_MODE_BUS;
			end case;
		end if;
	end process;

	-- relative address needs a special case.
	process (enable, sys_bus.execute, am_value, internal_addr, pc)
	begin
		if enable = '0' or (sys_bus.execute = '0' and sys_bus.write = '0')
		then
			accumulator <= (others => 'Z');
		else
			if am_value = CI_AM_IMMEDIATE_REL
			then
				-- immediate addresses need to be 32bit aligned - so don't waste the bottom 2 bits
				-- gives a larger immediate address space. Also less chance of an unaligned address
				-- exception.
				accumulator <= pc + (internal_addr(ADDR_WIDTH-3 downto 0) & "00");
			
			elsif am_value = CI_AM_IMMEDIATE_REL
			then
				-- immediate addresses need to be 32bit aligned - so don't waste the bottom 2 bits
				-- gives a larger immediate address space.
				accumulator <= (internal_addr(ADDR_WIDTH-3 downto 0) & "00");	-- dword aligned.
			else
				accumulator <= internal_addr;
			end if;
		end if;
	end process;

	process (enable, sys_bus.execute, op_code)
	begin
		if enable = '0' or (sys_bus.execute = '0' and sys_bus.write = '0')
		then
			internal_addr <= (others => 'Z');
		else
			case op_code(3 downto 0) is
				when CI_BRANCH		=> internal_addr <= a_op;

				when CI_BRANCH_LE	=> 	if flags.zero_flag = '1' or flags.sign_flag = '1'
										then
											internal_addr <= a_op;
										else
											internal_addr <= pc;
										end if;

				when CI_BRANCH_LT	=> 	if flags.sign_flag = '1'
										then
											internal_addr <= a_op;
										else
											internal_addr <= pc;
										end if;

				when CI_BRANCH_GE	=> 	if flags.zero_flag = '0' or flags.sign_flag = '0'
										then
											internal_addr <= a_op;
										else
											internal_addr <= pc;
										end if;

				when CI_BRANCH_GT	=> 	if flags.zero_flag = '0'
										then
											internal_addr <= a_op;
										else
											internal_addr <= pc;
										end if;

				when CI_BRANCH_EQ	=> 	if flags.zero_flag = '1'
										then
											internal_addr <= a_op;
										else
											internal_addr <= pc;
										end if;

				when CI_BRANCH_NE	=> 	if flags.zero_flag = '0'
										then
											internal_addr <= a_op;
										else
											internal_addr <= pc;
										end if;
				when others			=>	internal_addr <= pc;
			end case;
		end if;
	end process;

end architecture synth;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
