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
use work.instructions.all;

entity LoadStoreUnit is
	port (
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
end LoadStoreUnit;

architecture synth of LoadStoreUnit is

begin
	-- set load complete after the op is loaded.
	load_comp <= op_a_da when en = '1' else 'Z';

	-- TODO: need to check in the instruction is valid.

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

			-- handle the load store phase of the operation
			case instruction(LOAD_STORE_OPCODE_RANGE) is
				when LS_MOVE			=>	op_a.en			<= '1';
											op_a.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LOAD_STORE_OPERAND_A_RANGE);
											op_a.mode		<= instruction(LOAD_STORE_ADDR_MODE_SRC_RANGE);
												
											-- X -> (reg) : the write needs the contents of REG in op_b
											-- X -> immed : the write needs the value immed in op_b
											-- X -> reg   : the write needs the value of reg in op_b
 											-- *SO* the only time we need to use op_b is when (reg) is being done
											-- else it can be loaded at write time.
											if instruction(LOAD_STORE_ADDR_MODE_DST_RANGE) = OP_AM_REGISTER_INDIRECT
											then
												op_b.en			<= '1';
												op_b.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LOAD_STORE_OPERAND_B_RANGE);
												op_b.mode		<= OP_AM_REGISTER;		-- load the contents of the register
											end if;

				when LS_MOVE_IMM		=>	op_a.en		<= '1';
											op_a.mode	<= instruction(LOAD_STORE_ADDR_MODE_SRC_RANGE);
											
											-- register indirect?
											if instruction(LOAD_STORE_ADDR_MODE_DST_RANGE) = OP_AM_REGISTER_INDIRECT
											then
												op_b.en			<= '1';
												op_b.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LOAD_STORE_OPERAND_B_RANGE);
												op_b.mode		<= OP_AM_REGISTER;		-- load the contents of the register
											end if;
												
											if instruction(LOAD_STORE_ADDR_MODE_SRC_RANGE) = OP_AM_IMMEDIATE
											then
												op_a.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LOAD_STORE_OPERAND_A_RANGE);
												data			<= ZEROS(DATA_WIDTH-1 downto 18) & instruction(LOAD_STORE_IMMED_18_RANGE);
											
											elsif instruction(LOAD_STORE_ADDR_MODE_SRC_RANGE) = OP_AM_REGISTER
											then
												op_a.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LOAD_STORE_OPERAND_A_RANGE);
											end if;

				when LS_MOVE_SYS		=> null;
				when LS_MOVE_SYS_IMM	=> null;
				when others				=> null;
			end case;
			complete <= '0';
		
		elsif state = CS_EXECUTE
		then
			-- handle the execute phase of load store
			complete <= '1';

		elsif state = CS_STORE
		then
			-- finally the storage phase.
			case instruction(LOAD_STORE_OPCODE_RANGE) is
				when LS_MOVE			=>	if instruction(LOAD_STORE_ADDR_MODE_DST_RANGE) = OP_AM_REGISTER_INDIRECT
											then
												write.mode  	<= OP_AM_MEMORY_DIRECT;
												write.address	<= op_b_data;
											else
												write.mode		<= instruction(LOAD_STORE_ADDR_MODE_DST_RANGE);
												write.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LOAD_STORE_OPERAND_B_RANGE);
											end if;

											data		<= op_a_data;
											write.en	<= '1';
				
				when LS_MOVE_IMM		=>	if instruction(LOAD_STORE_ADDR_MODE_DST_RANGE) = OP_AM_REGISTER_INDIRECT
											then
												write.mode  	<= OP_AM_MEMORY_DIRECT;
												write.address	<= op_b_data;

											elsif instruction(LOAD_STORE_ADDR_MODE_DST_RANGE) = OP_AM_MEMORY_DIRECT
											then
												write.mode  	<= OP_AM_MEMORY_DIRECT;
												write.address	<= ZEROS(DATA_WIDTH-1 downto 18) & instruction(LOAD_STORE_IMMED_18_RANGE);
											else
												write.mode		<= instruction(LOAD_STORE_ADDR_MODE_DST_RANGE);
												write.address	<= ZEROS(DATA_WIDTH-1 downto 5) & instruction(LOAD_STORE_OPERAND_A_RANGE);
											end if;

											data		<= op_a_data;
											write.en	<= '1';

				when LS_MOVE_SYS		=> null;
				when LS_MOVE_SYS_IMM	=> null;
				when others				=> null;
			end case;
			complete <= '0';

		else
			op_a 	<= INIT_OPERAND_BUS;
			op_b 	<= INIT_OPERAND_BUS;
			write 	<= INIT_STORE_BUS;

		end if;
	end process;

end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
