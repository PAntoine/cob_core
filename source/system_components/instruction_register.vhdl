-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : instruction_register
-- Desc  : This component is the instruction register and it manages the loading
--         and top level decoding of the instruction.
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

entity InstructionRegister is
	port(
			reset			: in std_logic;
			clock			: in std_logic;
			state			: in CPU_STATE;
			pc				: in std_logic_vector(ADDR_WIDTH-1 downto 0);
			data			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			mem_da			: in std_logic;

			mem_bus			: out MEMORY_BUS;								-- memory bus controls
			fetch_complete	: out std_logic;								-- assert that the instruction register has been updated.
			unit_sel		: out INSTRUCTION_UNIT_TYPE;					-- partial decode, select the execution unit.
			instruction		: out INSTRUCTION_TYPE							-- output the captured instruction.
	);
end entity InstructionRegister;
	
architecture synth of InstructionRegister is

	signal int_instr_reg : INSTRUCTION_TYPE;

begin
	-- control the memory read.
	process (reset, state, pc)
	begin 
		if reset = '0' and state = CS_FETCH_DECODE
		then
			mem_bus.en			<= '1';			-- we want to read the next instruction from the memory bus.
			mem_bus.rw			<= RW_READ;
			mem_bus.address		<= pc;
		else
			mem_bus.en			<= 'Z';
			mem_bus.rw			<= 'Z';
			mem_bus.address		<= (others => 'Z');
		end if;
	end process;

	-- latch the instruction
	process (reset, state, mem_da, data, clock)
	begin
		if (reset = '1')
		then
			int_instr_reg <= BR_INIT_INSTR;

		elsif state = CS_FETCH_DECODE and mem_da = '1'
		then
			int_instr_reg <= data;
		end if;
	end process;

	-- decode the unit sel
	process (reset, state, int_instr_reg)
	begin
		if state = CS_FETCH_DECODE
		then
			unit_sel <= IU_IDLE_SEL;

		elsif state = CS_INTERRUPT or state = CS_EXCEPTION
		then
			unit_sel <= IU_INT_EXCPT_SEL;

		else
			case int_instr_reg(INSTR_UNIT_RANGE) is
				when IU_LOGIC		=> unit_sel <= IU_LOGIC_SEL;
				when IU_CONTROL		=> unit_sel <= IU_CONTROL_SEL;
				when IU_ARITH		=> unit_sel <= IU_ARITH_SEL;
				when IU_LOAD_STORE	=> unit_sel <= IU_LOAD_STORE_SEL;
				when IU_SYSTEM		=> unit_sel <= IU_SYSTEM_SEL;
				when others			=> unit_sel <= IU_IDLE_SEL;
			end case;
		end if;
	end process;

	fetch_complete	<= '1' when state = CS_FETCH_DECODE and mem_da = '1' else '0';
	instruction		<= int_instr_reg;

end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
