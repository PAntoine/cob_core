-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : operand_register
-- Desc  : This component loads the operand in for the execution units.
--
-- Author: Peter Antoine
-- Date  : 27/03/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;

entity OperandRegister is
	port (
		op_bus		: in	OPERAND_BUS:								-- the control signals.

		reg_bus		: out	REGISTER_BUS;								-- the control bus for the register
		reg_data	: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- register data

		mem_bus		: out	MEMORY_BUS;									-- the memory control bus
		mem_data	: out	std_logic_vector(DATA_WIDTH-1 downto 0);	-- memory data

		complete	: out std_logic										-- execution complete.
	);
end OperandRegister;

architecture synth of OperandRegister is

	subtype OP_STATE_TYPE is std_logic_vector(1 downto 0);
	constant OP_START		: OP_STATE_TYPE	:= "00";
	constant OP_LATCH_REG	: OP_STATE_TYPE := "01";
	constant OP_MEM_LATCH	: OP_STATE_TYPE := "10";
	constant OP_FINISHED	: OP_STATE_TYPE := "11";

	signal op_reg	: std_logic_vector(DATA_WIDTH-1 downto 0);
begin

	process (op_bus)
	begin
		if op_bus.en = '0'
		then
			reg_bus		<= FREE_REGISTER_BUS;
			mem_bus		<= FREE_REGISTER_BUS;
			complete	<= '0';
			state		<= OP_START;

		else
			case state is
				when OP_START	=>	if op_bus.mode = LS_AM_REG_INDIRECT or op_bus.mode = LS_AM_REGISTER
									then
										-- load the register value
										reg_bus.reg_addr	<= op_bus.address(4 downto 0);
										reg_bus.reg_rw		<= RW_READ;
										reg_bus.reg_en		<= '1';
										state				<= OP_LATCH_REG;

									elsif mode = LS_AM_MEMORY_DIRECT
									then
										-- use the address to directly read memory
										mem_bus.address	<= op_bus.address;
										mem_bus.rw		<= RW_READ;
										mem_bus.en		<= '1';
										state			<= OP_MEM_LATCH;

									else
										-- latch the immediate value
										op_reg				<= op_bus.address;
										state				<= OP_FINISHED;
									end if;

				when OP_LATCH_REG =>
									if op_bus.mode = LS_AM_REG_INDIRECT and reg_bus.da = '1'
									then
										mem_bus.address	<= reg_data;
										mem_bus.rw		<= RW_READ;
										mem_bus.en		<= '1';
										state			<= OP_MEM_LATCH;
									end if;

				when OP_MEM_LATCH =>
									if mem_bus.da = '1'
									then
										mem_bus.en	<= '0';
										op_reg		<= mem_data;
										state		<= OP_FINISHED;
									end if;

				when OP_FINISHED =>
									mem_bus.en	<= '0';
									reg_bus.en	<= '0';
									complete	<= '1';
			end case;
	end process;

	output <= op_reg when en = '1' else 'Z';

end synth;
-- vi:nocin:sw=4 ts=4:fdm=marker
