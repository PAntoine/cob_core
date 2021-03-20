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
				enable			: in 	std_logic;			-- are we running?
				da				: out	std_logic;			-- data available - the command has completed.
				sys_bus			: in 	SYSTEM_BUS;			-- the system bus controls
				instruction		: in	INSTRUCTION_TYPE;	-- instruction
				addr_mode_bus	: out	ADDRESS_MODE_BUS;	-- drive the address bus.
				flags			: out	CPU_FLAGS;			-- guess what the flags.
				a_op			: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand A
				b_op			: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand B
				accumulator		: out	std_logic_vector(DATA_WIDTH-1 downto 0)		-- The accumulator  for the results.
		);
end LogicUnit;

architecture synth of LogicUnit is
	
	signal internal_op		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal am_value			: LI_AM_TYPE;
	signal op_code			: LOGIC_OP_CODE_TYPE;
begin

	am_value	<= instruction(LI_AM_CODE);
	op_code		<= instruction(LI_OP_CODE_RANGE);

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
				when LI_AM_RRR	=>	addr_mode_bus	<= REGISTER_1_AND_2_ADDRESS_MODE;
									flags.exception	<= '0';
				when LI_AM_MRR	=>	addr_mode_bus	<= MEMORY_INDIRECT_TO_A_AND_REG_2_ADDRESS_MODE;
									flags.exception	<= '0';
				when LI_AM_RMR	=>	addr_mode_bus	<= MEMORY_INDIRECT_TO_B_AND_REG_2_ADDRESS_MODE;
									flags.exception	<= '0';
				when LI_AM_R_R	=>	addr_mode_bus 	<= REGISTER_1_ADDRESS_MODE;
									flags.exception	<= '0';
				when LI_AM_RIR	=>	addr_mode_bus 	<= REGISTER_1_ADDRESS_MODE;		-- immediate to reg_b
									flags.exception	<= '0';
				when others		=>	addr_mode_bus	<= NONE_ADDRESS_MODE_BUS;
									flags.exception	<= '1';
			end case;
		end if;
	end process;

	internal_addr <= ZERO(DATA_WIDTH-1 downto 8) & instruction(LI_IMM8) when am_value = AM_RIR else b_op;

	------------------------------------------------------------
	--- Logic Instruction
	------------------------------------------------------------
	process (enable, a_op, b_op, op_code) is
	begin
		if enable ='1'
		then
			case op_code is
				when LI_LSL => accumulator <= LogicalShiftLeft(a_op, internal_op(4 downto 0));
				when LI_LSR => accumulator <= LogicalShiftRight(a_op, internal_op(4 downto 0));
				when LI_AND	=> accumulator <= a_op and internal_op;
				when LI_OR	=> accumulator <= a_op or internal_op;
				when LI_XOR	=> accumulator <= a_op xor internal_op;
				when LI_NOT	=> accumulator <= not a_op;
				--when LI_NEG	=> accumulator <= (not a_op) + 1;
				when LI_ROR	=> accumulator <= RotateRight(a_op, internal_op(4 downto 0));
				when LI_ROL	=> accumulator <= RotateLeft(a_op, internal_op(4 downto 0));
				when others	=> accumulator <= (others => '0');
			end case;
		else
			accumulator <= (others => 'Z');
		end if;
	end process;

	-- commands are "nearly" instantaneous - so set DA when execute is set. 
	da <= sys_bus.execute when enable = '1' else 'Z';

	------------------------------------------------------------
	--- Set the flags register.
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
