-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : load store unit
-- Desc  : This entity handles the loading and storing of data.
--
-- Author: Peter Antoine
-- Date  : 08/03/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;
use work.instructions.all;

entity LoadStoreUnit is
		port(
				enable			: in 	std_logic;				-- are we running?
				da				: out	std_logic;				-- data available - the command has completed.
				sys_bus			: in 	SYSTEM_BUS;				-- the system bus controls
				addr_mode_bus	: out	ADDRESS_MODE_BUS;		-- drive the address bus.
				instruction		: in 	INSTRUCTION_TYPE;		-- the op code
				flags			: out	CPU_FLAGS;		-- guess what the flags.
				a_op			: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand A
				b_op			: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand B
				accumulator		: out	std_logic_vector(DATA_WIDTH-1 downto 0)		-- The accumulator  for the results.
		);
end LoadStoreUnit;

architecture synth of LoadStoreUnit is
	signal am_value			: ADDRESSING_MODE;
	signal op_code			: LOAD_STORE_OPCODE_TYPE;
	signal reg_write		: std_logic;
	signal mem_write		: std_logic;

begin

	------------------------------------------------------------
	--- decode the instruction.
	------------------------------------------------------------
	am_value 	<= instruction(LOAD_STORE_ADDR_MODE_RANGE);
	op_code		<= instruction(LOAD_STORE_OPCODE_RANGE);

	------------------------------------------------------------
	--- Decode the Addressing modes.
	------------------------------------------------------------
	process (enable, am_value) is
	begin
		if (enable = '0')
		then
			addr_mode_bus 	<= FREE_ADDRESS_MODE_BUS;
			flags.exception <= 'Z';
		else
			case am_value is
				when S_AM_RegReg	=>	
				when S_AM_RegRegI	=>	
				when S_AM_RegImm	=>	
				when S_AM_RegIReg	=>	
				when S_AM_RegIRegI	=>	
				when S_AM_RegIImm	=>	
				when S_AM_ImmReg	=>	
				when S_AM_ImmRegI	=>	
			end case;
		end if;
	end process;
	
	internal_addr <= ZERO(DATA_WIDTH-1 downto 8) & instruction(LOAD_STORE_IMMED_18_RANGE) when am_value = AM_RIR else a_op;

	------------------------------------------------------------
	--- Execute the instruction.
	------------------------------------------------------------
	process (enable, op_code, sys_bus) is
	begin
		if (enable = '0')
		then
			accumulator			<= (others => 'Z');
			flags.exception 	<= 'Z';
			reg_write			<= 'Z';
			mem_write			<= 'Z';
		else
			case op_code is
				when LS_MOVE_MEM	=>	mem_write	<= '1';
										accumulator <= a_op;
										mem_addr	<= b_op;
			

	flags <= (others => 'Z');
	accumulator <= (others => 'Z');

end architecture synth;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
