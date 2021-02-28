-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : logic unit
-- Desc  : This entity handles the logic instructions.
--
-- Author: Peter Antoine
-- Date  : 24/01/2021
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
use work.LogicFunctions.all;

entity LogicUnit is
		port(
				enable		: in 	std_logic;		-- are we running?
				da			: out	std_logic;		-- data available - the command has completed.
				sys_bus		: in 	SYSTEM_BUS;		-- the system bus controls
				op_code		: in 	OP_CODE_TYPE;	-- the op code
				flags		: out	CPU_FLAGS;		-- guess what the flags.
				a_op		: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand A
				b_op		: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand B
				accumulator	: out	std_logic_vector(DATA_WIDTH-1 downto 0)		-- The accumulator  for the results.
		);
end LogicUnit;

architecture synth of LogicUnit is

begin
	------------------------------------------------------------
	--- Logic Instruction
	------------------------------------------------------------
	process (enable, a_op, b_op, op_code) is
	begin
		if enable ='1'
		then
			case op_code is
				when LI_LSL => accumulator <= LogicalShiftLeft(a_op, b_op(4 downto 0));
				when LI_LSR => accumulator <= LogicalShiftRight(a_op, b_op(4 downto 0));
				when LI_AND	=> accumulator <= a_op and b_op;
				when LI_OR	=> accumulator <= a_op or b_op;
				when LI_XOR	=> accumulator <= a_op xor b_op;
				when LI_NOT	=> accumulator <= not a_op;
				--when LI_NEG	=> accumulator <= (not a_op) + 1;
				when LI_ROR	=> accumulator <= RotateRight(a_op, b_op(4 downto 0));
				when LI_ROL	=> accumulator <= RotateLeft(a_op, b_op(4 downto 0));
				when others	=> accumulator <= (others => '0');
			end case;
		else
			accumulator <= (others => 'Z');
		end if;
	end process;

	-- commands are "nearly" instantaneous - so set DA when execute is set. 
	da <= sys_bus.execute when enable = '1' else 'Z';

	------------------------------------------------------------
	--- Set he flags register.
	------------------------------------------------------------
	flags.zero_flag <= 'Z' when enable = '0' else '1' when accumulator = ZEROS else '0';
    flags.sign_flag <= 'Z' when enable = '0' else '1' when accumulator(DATA_WIDTH-1) = '1' else '0';
	
	-- don't use this, but should be set. TODO: this is wrong - should set the carry on rotate - or ASL (we need to add this).
	flags.carry_flag <= '0' when enable = '1' else 'Z';

	-- non of these flags are set in this block.
	flags.interrupt_flag		<= 'Z';
	flags.hardware_interrupt	<= 'Z';
	flags.interrupt_waiting		<= 'Z';
	flags.interrupts_masked		<= 'Z';
	flags.non_masked_interrupt	<= 'Z';

end architecture synth;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
