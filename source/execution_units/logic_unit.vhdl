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

entity LogicUnit is
	port(
		en			: in std_logic;			-- enable the idle unit.
		state		: in CPU_STATE;			-- CPU state
		load_comp	: out std_logic;		-- load phase is complete.
		complete	: out std_logic;		-- execution complete.
		instruction	: in INSTRUCTION_TYPE;	-- the instruction

		op_a		: out OPERAND_BUS;	-- Operand A bus controls
		op_b		: out OPERAND_BUS;	-- for B
		data		: out std_logic_vector(DATA_WIDTH-1 downto 0);	-- data that needs to goto the operand reg.

		write		: out STORE_BUS;		-- controls for writing out the data.

		op_a_da		: in std_logic;
		op_b_da		: in std_logic;
		op_a_data	: in std_logic_vector(DATA_WIDTH-1 downto 0);
		op_b_data	: in std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end LogicUnit;

architecture synth of LogicUnit is

	signal op_code		: LOGIC_OP_CODE_TYPE;

begin
	load_comp <= op_a_da when en = '1' else 'Z';
	op_code <= instruction(LI_OP_CODE_RANGE);

	-- handle the load state
	process (en, state, instruction)
	begin
		if en = '0'
		then
			op_a 		<= FREE_OPERAND_BUS;
			op_b 		<= FREE_OPERAND_BUS;
			data 		<= (others => 'Z');
			write		<= FREE_STORE_BUS;
			complete	<= 'Z';

		elsif state = CS_LOAD
		then
			write 	<= INIT_STORE_BUS;
			
			op_a.mode		<= instruction(LI_OPR_A_MODE);
			op_a.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LI_SOURCE_A);
			op_a.en			<= '1';
			
			if op_code /= LI_NOT	-- don't waste time loading op_b
			then
				op_b.mode		<= instruction(LI_OPR_B_MODE);
				op_b.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LI_SOURCE_B);
				op_b.en			<= '1';
			end if;

		elsif state = CS_EXECUTE
		then
			case op_code is
				when LI_LSL => data <= std_logic_vector(shift_left(unsigned(op_a_data), to_integer(unsigned(op_b_data(4 downto 0)))));
				when LI_LSR => data <= std_logic_vector(shift_right(unsigned(op_a_data), to_integer(unsigned(op_b_data(4 downto 0)))));
				when LI_AND	=> data <= op_a_data and op_b_data;
				when LI_OR	=> data <= op_a_data or  op_b_data;
				when LI_XOR	=> data <= op_a_data xor op_b_data;
				when LI_NOT	=> data <= not op_a_data;
				when LI_ROL	=> data <= std_logic_vector(rotate_left(unsigned(op_a_data), to_integer(unsigned(op_b_data(4 downto 0)))));
				when LI_ROR	=> data <= std_logic_vector(rotate_right(unsigned(op_a_data), to_integer(unsigned(op_b_data(4 downto 0)))));
				when others	=> data <= (others => '0');
			end case;

			complete <= '1';

		elsif state = CS_STORE
		then
			write.mode		<= instruction(LOAD_STORE_ADDR_MODE_DST_RANGE);
			write.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LI_SOURCE_B);
			write.en		<= '1';

		end if;
	end process;

end architecture synth;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
