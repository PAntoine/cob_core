-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : arithmetic_unit
-- Desc  : This is the ALU of the cob core. It is a integer unit for simple
--         mathematics operations.
--
-- Author: Peter Antoine
-- Date  : 10/04/2021
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

entity ArithmeticUnit is
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
		flags		: inout CPU_FLAGS;

		op_a_da		: in std_logic;
		op_b_da		: in std_logic;
		op_a_data	: in std_logic_vector(DATA_WIDTH-1 downto 0);
		op_b_data	: in std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end ArithmeticUnit;

architecture synth of ArithmeticUnit is

	signal op_code		: ARITH_OP_CODE_TYPE;
	signal intermediate	: std_logic_vector(DATA_WIDTH downto 0); -- +1 for the carry flag.
begin
	load_comp <= op_a_da when en = '1' else 'Z';
	op_code <= instruction(LI_OP_CODE_RANGE);

	-- handle the load state
	process (en, state, instruction)
		variable temp : std_logic_vector(63 downto 0);
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
				when AI_INC	=> intermediate	<= '0' & std_logic_vector(unsigned(op_a_data) + 1);
				when AI_DEC	=> intermediate	<= '0' & std_logic_vector(unsigned(op_a_data) - 1);
				when AI_ADD	=> Intermediate	<= std_logic_vector(unsigned('0' & op_a_data) + unsigned('0' & op_b_data));
				when AI_SUB	=> intermediate <= std_logic_vector(unsigned('0' & op_a_data) - unsigned('0' & op_b_data));
				when AI_MOD	=> intermediate <= '0' & std_logic_vector(unsigned(op_a_data) mod unsigned(op_b_data));
				when AI_DIV	=> intermediate <= '0' & std_logic_vector(unsigned(op_a_data) / unsigned(op_b_data));

				when AI_ADC	=>	if flags.carry_flag = '0'
				                then
				                	intermediate <=	std_logic_vector(unsigned('0' & op_a_data) + unsigned('0' & op_b_data));
								else
				                	intermediate <=	std_logic_vector(unsigned('0' & op_a_data) + unsigned('0' & op_b_data) + 1);
								end if;

				when AI_SBC	=>	if flags.carry_flag = '0'
				                then
									intermediate <=	std_logic_vector(unsigned('1' & op_a_data) - unsigned(op_b_data));
								else
									intermediate <=	std_logic_vector(unsigned('1' & op_a_data) - unsigned(op_b_data) + 1);
								end if;
				
				when AI_MUL	=>	temp := std_logic_vector(unsigned(op_a_data) * unsigned(op_b_data));
								intermediate <= '0' & temp(DATA_WIDTH-1 downto 0);

				when others	=> intermediate <= (others => '0');
			end case;

			complete <= '1';

		elsif state = CS_STORE
		then
			write.mode		<= instruction(LOAD_STORE_ADDR_MODE_DST_RANGE);
			write.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LI_SOURCE_B);
			write.en		<= '1';

		end if;
	end process;
	
	process (en, intermediate)
	begin
		if en = '0'
		then
			flags <= FREE_CPU_FLAGS;

		elsif state = CS_EXECUTE
		then
			if intermediate(DATA_WIDTH-1 downto 0) = ZEROS
			then
				flags.zero_flag <= '1';
			end if;

			flags.sign_flag 	<= intermediate(DATA_WIDTH-1);
			flags.carry_flag	<= intermediate(DATA_WIDTH);
		end if;
	end process;

	data <= intermediate(DATA_WIDTH-1 downto 0) when en = '1' else (others => 'Z');

end architecture synth;

-- vi:nocin:sw=4 ts=4:fdm=marker
