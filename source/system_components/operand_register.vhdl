-----------------------------------------------------------------------------------
--			   _____ ____  ____		_____
--			  / ____/ __ \|  _ \   / ____|
--			 | |   | |	| | |_) | | |	  ___  _ __ ___
--			 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--			 | |___| |__| | |_) | | |___| (_) | | |  __/
--			  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : operand_register
-- Desc  : This component loads the operand in for the execution units.
--
-- Author: Peter Antoine
-- Date  : 27/03/2021
-----------------------------------------------------------------------------------
--					   Copyright (c) 2021 Peter Antoine
--							  All rights Reserved.
--					  Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;

entity OperandRegister is
	port (
		reset		: in	std_logic;
		clock		: in	std_logic;	  
		op_bus		: in	OPERAND_BUS;								-- the control signals.
		cstate		: in	CPU_STATE;									-- the cpu state.
		reg_bus		: out	REGISTER_BUS;								-- the control bus for the register
		reg_data	: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- register data
		reg_da		: in	std_logic;									-- the reg data is available.
		data		: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- data from other sources to load.

		mem_bus		: out	MEMORY_BUS;									-- the memory control bus
		mem_data	: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- memory data
		mem_da		: in	std_logic;									-- mem data available.

		output		: out	std_logic_vector(DATA_WIDTH-1 downto 0);	-- the result of the register.
		complete	: out std_logic										-- execution complete.
	);
end OperandRegister;

architecture synth of OperandRegister is

	subtype OP_STATE_TYPE is std_logic_vector(1 downto 0);
	constant OP_START		: OP_STATE_TYPE	:= "00";
	constant OP_LATCH_REG	: OP_STATE_TYPE := "01";
	constant OP_MEM_LATCH	: OP_STATE_TYPE := "10";
	constant OP_FINISHED	: OP_STATE_TYPE := "11";

	constant LATCH_NONE : std_logic_vector(1 downto 0) := "00";
	constant LATCH_IMM	: std_logic_vector(1 downto 0) := "01";
	constant LATCH_REG	: std_logic_vector(1 downto 0) := "10";
	constant LATCH_MEM	: std_logic_vector(1 downto 0) := "11";

	signal latch : std_logic_vector(1 downto 0);
	
	signal state 		: OP_STATE_TYPE;
	signal data_latched	: std_logic;

	signal op_reg	: std_logic_vector(DATA_WIDTH-1 downto 0);
begin

	process (op_bus, cstate, state, mem_da, mem_data, data, reg_da, reg_data)
	begin
		if op_bus.en = '1' and cstate = CS_LOAD
		then
			case state is
				when OP_START	=>	if op_bus.mode = OP_AM_REGISTER_INDIRECT or op_bus.mode = OP_AM_REGISTER
									then
										-- load the register value
										reg_bus.address	<= op_bus.address(4 downto 0);
										reg_bus.rw		<= RW_READ;
										reg_bus.en		<= '1';
										state			<= OP_LATCH_REG;

									elsif op_bus.mode = OP_AM_MEMORY_DIRECT
									then
										-- use the address to directly read memory
										mem_bus.address	<= op_bus.address;
										mem_bus.rw		<= RW_READ;
										mem_bus.en		<= '1';
										state			<= OP_MEM_LATCH;

									else
										-- latch the immediate value
										state			<= OP_FINISHED;
										latch			<= LATCH_IMM;
									end if;

				when OP_LATCH_REG =>
									if reg_da = '1'
									then
										if op_bus.mode = OP_AM_REGISTER_INDIRECT
										then
											mem_bus.address	<= reg_data;
											mem_bus.rw		<= RW_READ;
											mem_bus.en		<= '1';
											state			<= OP_MEM_LATCH;
										else
											latch			<= LATCH_REG;

											if data_latched = '1'
											then
												state			<= OP_FINISHED;
											end if;
										end if;
									end if;

				when OP_MEM_LATCH =>
									if mem_da = '1'
									then
										mem_bus		<= INIT_MEMORY_BUS;
										latch		<= LATCH_MEM;
										state		<= OP_FINISHED;
									end if;

				when OP_FINISHED =>
									mem_bus		<= INIT_MEMORY_BUS;
									reg_bus		<= INIT_REGISTER_BUS;
			
				when others =>
									mem_bus		<= INIT_MEMORY_BUS;
									reg_bus		<= INIT_REGISTER_BUS;
			end case;
		
		else
			reg_bus		<= FREE_REGISTER_BUS;
			mem_bus		<= FREE_MEMORY_BUS;
			state		<= OP_START;
			latch		<= LATCH_NONE;

		end if;
	end process;
	
	process (reset, op_bus.en, clock, latch)
	begin
		if reset = '1'
		then
			op_reg			<= (others => '0');
			complete		<= '0';
			data_latched	<= '0';
		
		elsif op_bus.en = '0'
		then
			complete		<= '0';
			data_latched	<= '0';

		elsif latch /= LATCH_NONE and falling_edge(clock)
		then
			case latch is
				when LATCH_REG => op_reg <= reg_data;
				when LATCH_MEM => op_reg <= mem_data;
				when LATCH_IMM => op_reg <= data;
				when others => null;
			end case;

			complete		<= '1';
			data_latched	<= '0';
		end if;
	end process;

	output <= op_reg when op_bus.en = '1' else (others => 'Z');

end synth;
-- vi:nocin:sw=4 ts=4:fdm=marker
