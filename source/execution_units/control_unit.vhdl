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
--					   Copyright (c) 2021 Peter Antoine
--							  All rights Reserved.
--					  Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.definitions.all;
use work.instructions.all;

entity ControlUnit is
	port(
		en			: in std_logic;			-- enable the idle unit.
		state		: in CPU_STATE;			-- CPU state
		load_comp	: out std_logic;		-- load phase is complete.
		store_comp	: out std_logic;		-- store complete.
		complete	: out std_logic;		-- execution complete.
		instruction	: in INSTRUCTION_TYPE;	-- the instruction

		op_a		: out OPERAND_BUS;		-- Operand A bus controls
		op_b		: out OPERAND_BUS;		-- Operand e bus controls
		data		: out std_logic_vector(DATA_WIDTH-1 downto 0);	-- data that needs to goto the operand reg.

		write		: out STORE_BUS;		-- controls for writing out the data.

		flags		: in CPU_FLAGS;

		pc_load		: out std_logic;
		pc			: in std_logic_vector(DATA_WIDTH-1 downto 0);
		op_a_da		: in std_logic;
		op_a_data	: in std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end ControlUnit;

architecture synth of ControlUnit is

	signal op_code	: CONTROL_OP_CODE_TYPE;
	signal immed	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal n_addr	: std_logic_vector(DATA_WIDTH-1 downto 0);

begin
	write	<= INIT_STORE_BUS	when en = '1' else FREE_STORE_BUS;		-- unused.
	op_b	<= INIT_OPERAND_BUS	when en = '1' else FREE_OPERAND_BUS;	-- unused.

	load_comp <= op_a_da when en = '1' else 'Z';

	op_code	<= instruction(CONTROL_OPCODE_RANGE);
	immed	<= (ZEROS(ADDR_WIDTH-3 downto 23) & instruction(CONTROL_IMMED_RANGE) & "00");

	data <= (others => 'Z') when en = '0' else
			immed			when state = CS_LOAD else
			n_addr			when state = CS_STORE else
			(others => 'Z');

	process (en, state, instruction, pc, op_a_data, flags)
	begin
		if en = '0'
		then
			op_a		<= FREE_OPERAND_BUS;
			pc_load		<= '0';
			store_comp	<= 'Z';
			complete	<= 'Z';
			n_addr		<= (others => '0');

		elsif state = CS_LOAD
		then
			complete	<= '0';
			store_comp	<= '0';
				
			op_a.mode		<= instruction(CONTROL_AM_RANGE);
			op_a.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LI_SOURCE_A);
			op_a.en			<= '1';

		elsif state = CS_EXECUTE
		then
			complete <= '1';
			case op_code is
				when CI_BRANCH		=> n_addr <= op_a_data;
				when CI_BRANCH_LE	=> if flags.zero_flag = '1' or flags.sign_flag = '1'	then n_addr <= op_a_data; else n_addr <= pc; end if;
				when CI_BRANCH_LT	=> if flags.sign_flag = '1'								then n_addr <= op_a_data; else n_addr <= pc; end if;
				when CI_BRANCH_GE	=> if flags.zero_flag = '0' or flags.sign_flag = '0'	then n_addr <= op_a_data; else n_addr <= pc; end if;
				when CI_BRANCH_GT	=> if flags.zero_flag = '0'								then n_addr <= op_a_data; else n_addr <= pc; end if;
				when CI_BRANCH_EQ	=> if flags.zero_flag = '1'								then n_addr <= op_a_data; else n_addr <= pc; end if;
				when CI_BRANCH_NE	=> if flags.zero_flag = '0'								then n_addr <= op_a_data; else n_addr <= pc; end if;
				when others			=> n_addr <= pc;
			end case;
			
		elsif state = CS_STORE
		then
			complete	<= '0';
			pc_load		<= '1';
			store_comp	<= '1';

		else
			op_a		<= INIT_OPERAND_BUS;
			pc_load		<= '0';
			store_comp	<= '0';

		end if;
	end process;

end architecture synth;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
