----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : Operand Register
-- Desc  : This block handles loading the operand(s) from the source.
--         This block handles the loading of indirect data. So if the operand
--         needs to be loaded from the address from the register that points
--         to memory then this will handle the indirection.
--
-- Author: Peter Antoine
-- Date  : 14/03/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;

entity OperandRegister is
		port(
			enable		: in	std_logic;		-- enable the register.
			mode		: in	OPERAND_MODE;	-- the mode that the operand register works in.
			reg_bus		: inout REGISTER_BUS;	-- the register bus controls.
			mem_bus		: inout MEMORY_BUS;		-- the memory bus controls.
			mem_data	: in	std_logic_vector(DATA_WIDTH-1 downto 0);
			reg_data	: in	std_logic_vector(DATA_WIDTH-1 downto 0);
			da			: out	std_logic;		-- the data is available.
			value		: out	std_logic_vector(DATA_WIDTH-1 downto 0);	-- the operands data
		);
end OperandRegister;

architecture synth of OperandRegister is

	------------------------------------------------------------
	--- Internal operand register states.
	------------------------------------------------------------
	subtype	OP_STATE_TYPE is std_logic_vector(2 downto 0);
	constant	OP_START				: OP_STATE_STATE  := "000";
	constant	OP_LATCH_ADDRESS		: OP_STATE_STATE  := "001";
	constant	OP_WAIT_FOR_MEMORY_DATA	: OP_STATE_STATE  := "010";
	constant	OP_LATCH_DATA			: OP_STATE_STATE  := "011";
	constant	OP_FINISHED				: OP_STATE_STATE  := "100";

	signal state : OP_STATE_TYPE;

begin
	------------------------------------------------------------
	--- State machine.
	------------------------------------------------------------
	process (enable, mode)
	begin
		if (enable = '0')
		then
			state		<= OP_START;
			reg_addr	<= (others => 'Z');
			da			<= '0';
			int_data	<= (others => '0');
		
		else clock'event
			case state is
				when OP_START =>
					if mode = '0'
					then
						state <= OP_LATCH_DATA;
					else
						state <= OP_LATCH_ADDRESS;
					end if;

				when OP_LATCH_ADDRESS =>
					reg_id 	<= reg_data;
					state	<= OP_WAIT_FOR_MEMORY_DATA;

				when OP_WAIT_FOR_MEMORY_DATA =>
					if mem_da = '1'
					then
						int_data	<= mem_data;
						state		<= OP_FINISHED;
					end if;

				when OP_LATCH_DATA =>
					int_data	<= reg_data;
					state		<= OP_FINISHED;
				
				when OP_FINISHED =>
					da <= '1';
				
				when others => null;
			end case;
		end if;
	end process;

	------------------------------------------------------------
	--- Output bus states.
	------------------------------------------------------------
	reg_en 		<= 'Z' when enable = '0' else '1' when state = OP_START else '0';
	reg_rw 		<= 'Z' when enable = '0' else RW_READ;
	reg_addr	<= 'Z' when enable = '0' else reg_id;

	mem_en <= 'Z' when enable = '0' else '1' when state = OP_WAIT_FOR_MEMORY_DATA else '0';
	mem_rw <= 'Z' when enable = '0' else RW_READ;

	mem_addr <= 'Z' when enable = '0' else int_addr when OP_WAIT_FOR_MEMORY_DATA else '0';

	value <= int_data;

end architecture synth;
--- vi:nocin:ai:sw=4 ts=4:fdm=marker
