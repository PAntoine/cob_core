-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : load_store_unit
-- Desc  : This unit will handle the loading and storing instructions.
--
-- Author: Peter Antoine
-- Date  : 21/03/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;

entity LoadStoreUnit is
	port (
		en			: in std_logic;			-- enable the idle unit.
		state		: in CPU_STATE;			-- CPU state
		complete	: out std_logic			-- execution complete.
	
		op_a		: out OPERAND_BUS_TYPE;	-- Operand A bus controls
		op_b		: out OPERAND_BUS_TYPE;	-- for B

		op_a_da		: in std_logic;
		op_b_da		: in std_logic;
		op_a_data	: in std_logic_vector(DATA_WIDTH-1 downto 0);
		op_b_data	: in std_logic_vector(DATA_WIDTH-1 downto 0);
	);
end LoadStoreUnit;

architecture synth of LoadStoreUnit is

begin
	-- handle the load state
	process (en, instruction)
	begin
		if en = '0'
		then
			op_a_en		<= 'Z';
			op_b_id		<= 'Z';
			op_a_mode	<= (others => 'Z');
											
			op_b_en		<= 'Z';
			op_b_id		<= 'Z';
			op_b_mode	<= (others => 'Z');

		elsif state = CS_LOAD
		then
			case instruction(LOAD_STORE_OPCODE_RANGE) is
				when LS_MOVE			=>	op_a_en		<= '1';
											op_b_id		<= instruction(LOAD_STORE_OPERAND_A_RANGE);
											op_a_mode	<= instruction(LOAD_STORE_ADDR_MODE_SRC_RANGE);
												
											-- TODO: this is wrong
											-- X -> (reg) : the write needs the contents of REG in op_b
											-- X -> immed : the write needs the value immed in op_b
											-- X -> reg   : the write needs the value of reg in op_b
 											-- *SO* the only time we need to use op_b is when (reg) is being done
											-- else it can be loaded at write time.

											if (instruction(LOAD_STORE_ADDR_MODE_DST_RANGE) = LS_AM_REG_INDIRECT
											then
												op_b_en		<= '1'
												op_b_id		<= instruction(LOAD_STORE_OPERAND_B_RANGE);
												op_b_mode	<= LS_AM_REGISTER;		-- load the contents of the register
											end if;

				when LS_MOVE_IMM		=>	op_a_en		<= '1';
											op_a_mode	<= instruction(LOAD_STORE_ADDR_MODE_SRC_RANGE);
												
											if instruction(LOAD_STORE_ADDR_MODE_SRC_RANGE) = LS_AM_IMMEDIATE
											then
												op_a_id <= instruction(LOAD_STORE_OPERAND_A_RANGE);
											end if;

				when LS_MOVE_SYS		=> null;
				when LS_MOVE_SYS_IMM	=> null;
				when others				=> null;
			end case;

		else
			op_a_en		<= '0';
			op_b_id		<= '0';
			op_a_mode	<= (others => '0');
											
			op_b_en		<= '0';
			op_b_id		<= '0';
			op_b_mode	<= (others => '0');

		end if;
	end process;

	-- handle the store state
	process (en, instruction)
	begin
		if en = '0'
		then
			write_en 	<= 'Z';
			write_mode	<= (others => 'Z');
			write_addr	<= (others => 'Z');

		elsif state = CS_STORE
		then
			case instruction(LOAD_STORE_ADDR_MODE_DST_RANGE) is
				when LS_AM_IMMEDIATE => null;
					-- TODO handle this

				when LS_AM_REGISTER => null;
					-- TODO handle this

				when LS_AM_REGISTER_INDIRECT => null;
					-- TODO handle thos

				when others => null;
			end case;
		
		else
			write_en	<= '0';
			write_mode	<= (others => '0');
			write_addr	<= (others => '0');
		end if;
	end process;

	-- this is a move, so the action is in the store, so just complete the execution.
	complete <= '1' when CS_EXECUTE else '0';

end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
