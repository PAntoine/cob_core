-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : stack_register
-- Desc  : Stack Register.
--
--         The stack register holds the value of the stack, and handles the
--         actions that are performed around the stack.
--
--         PUSH:   SP - 1 -> SP
--                 data -> (SP)
--
--         POP:    (SP) -> data
--                 SP + 1 -> SP
--
--         Call:   PUSH(pc)
--
--         Return: POP() -> pc
--
--         Save:   PUSH(stack)
--                 PUSH(pc)
--                 PUSH(flags)
--
--         Load:   POP() -> flags
--                 POP() -> pc
--                 POP() -> stack
--
--           Call Stack:
--               +-----------------------------------+
--               |         PC (next) Register        |
--               +-----------------------------------+
--
--           Interrupt Stack Frame:
--               +-----------------------------------+
--               |           Flags Register          |   SP
--               +-----------------------------------+
--               |         PC (next) Register        |   SP - 4
--               +-----------------------------------+
--               |           Stack Register          |   SP - 8
--               +-----------------------------------+
--
-- Author: Peter Antoine
-- Date  : 14/04/2021
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

entity StackRegister is
	port(
			reset		: in	std_logic;
			clock		: in	std_logic;
			sr_bus		: in	STACK_BUS;
			flags		: in	CPU_FLAGS;
			pc			: in	std_logic_vector(ADDR_WIDTH-1 downto 0);

			mem_bus		: out	MEMORY_BUS;
			mem_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
			mem_da		: in	std_logic;

			complete	: out	std_logic;
			pc_load		: out	std_logic;
			stack_value	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);
			da			: out	std_logic;
			data		: out	std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end entity StackRegister;

architecture synth of StackRegister is
	signal st_reg	: std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal sr_inc	: std_logic;
	signal sr_dec	: std_logic;
	signal sr_load	: std_logic;
	signal sr_loads	: std_logic;

	subtype		STACK_STATE_TYPE is std_logic_vector(3 downto 0);
	constant	SR_START		:	STACK_STATE_TYPE := "0000";
	constant	SR_SET_VALUE	:	STACK_STATE_TYPE := "0001";
	constant	SR_DATA_WRITE	:	STACK_STATE_TYPE := "0010";
	constant	SR_FLAGS_WRITE	:	STACK_STATE_TYPE := "0011";
	constant	SR_PC_WRITE		:	STACK_STATE_TYPE := "0100";
	constant	SR_STACK_WRITE	:	STACK_STATE_TYPE := "0101";
	constant	SR_DATA_READ	:	STACK_STATE_TYPE := "0110";
	constant	SR_PC_READ		:	STACK_STATE_TYPE := "0111";
	constant	SR_STACK_READ	:	STACK_STATE_TYPE := "1000";
	constant	SR_FLAGS_READ	:	STACK_STATE_TYPE := "1001";
	constant	SR_FINISHED		:	STACK_STATE_TYPE := "1111";

	signal state : STACK_STATE_TYPE;

	signal st_event : std_logic;

begin

	stack_value <= st_reg;

	st_event <= '1' when (sr_load = '1' or sr_loads = '1' or sr_inc = '1' or sr_dec = '1') and sr_bus.en = '1' else '0';

	-- manage the stack register.
	process (reset, sr_inc, sr_dec, mem_da, sr_bus, st_event, mem_data)
	begin
		if reset = '1'
		then
			st_reg <= ZEROS;

		elsif sr_bus.en = '1' and mem_da = '1' and sr_loads = '1'
		then
			st_reg <= mem_data;

		elsif sr_bus.en = '1' and rising_edge(st_event)
		then
			if sr_load = '1'
			then
				st_reg <= sr_bus.address;

			elsif sr_inc = '1'
			then
				st_reg <= std_logic_vector(unsigned(st_reg) + ADDR_BYTES);

			elsif sr_dec = '1'
			then
				st_reg <= std_logic_vector(unsigned(st_reg) - ADDR_BYTES);
			end if;
		end if;
	end process;

	process (state, sr_bus, clock)
	begin
		if sr_bus.en = '0'
		then
			state		<= SR_START;
			sr_inc		<= '0';
			sr_dec		<= '0';
			sr_load		<= '0';
			sr_loads	<= '0';
			complete	<= '0';
			pc_load		<= 'Z';
			da			<= '0';
			data		<= (others => 'Z');
			mem_bus		<= FREE_MEMORY_BUS;
			mem_data	<= (others => 'Z');

		elsif rising_edge(clock)
		then
			case state is
				when SR_START =>
					case sr_bus.mode is
						when SR_SET		=> state <= SR_SET_VALUE;
						when SR_PUSH 	=> state <= SR_DATA_WRITE;
						when SR_CALL 	=> state <= SR_PC_WRITE;
						when SR_SAVE 	=> state <= SR_FLAGS_WRITE;
						when SR_POP		=> state <= SR_DATA_READ;
						when SR_RET		=> state <= SR_PC_READ;
						when SR_RESTORE	=> state <= SR_STACK_READ;
						when others		=> null;
					end case;

				when SR_SET_VALUE =>
					sr_load			<= '1';
					state			<= SR_FINISHED;

				when SR_DATA_WRITE =>
					if sr_dec = '0'
					then
						mem_data		<= sr_bus.address;
						mem_bus.address	<= st_reg;
						mem_bus.rw		<= '1';
						mem_bus.en		<= '1';
						sr_dec			<= '1';

					elsif mem_da = '1'
					then
						sr_dec		<= '0';
						mem_bus		<= INIT_MEMORY_BUS;
						state		<= SR_FINISHED;
					end if;

				when SR_FLAGS_WRITE =>
					mem_data		<= flagsToVector(flags);
					mem_bus.address	<= st_reg;
					mem_bus.rw		<= '1';
					mem_bus.en		<= '1';
					sr_dec			<= '1';

					if mem_da = '1'
					then
						sr_dec		<= '0';
						mem_bus		<= INIT_MEMORY_BUS;
						state		<= SR_PC_WRITE;
					end if;

				when SR_PC_WRITE =>
					mem_data		<= pc;
					mem_bus.address	<= st_reg;
					mem_bus.rw		<= '1';
					mem_bus.en		<= '1';
					sr_dec			<= '1';

					if mem_da = '1'
					then
						sr_dec		<= '0';
						mem_bus		<= INIT_MEMORY_BUS;

						if sr_bus.mode = SR_CALL
						then
							state <= SR_FINISHED;
						else
							state <= SR_STACK_WRITE;
						end if;
					end if;

				when SR_STACK_WRITE =>
					mem_data		<= st_reg;
					mem_bus.address	<= st_reg;
					mem_bus.rw		<= '1';
					mem_bus.en		<= '1';
					sr_dec			<= '1';

					if mem_da = '1'
					then
						sr_dec		<= '0';
						mem_bus		<= INIT_MEMORY_BUS;
						state		<= SR_FINISHED;
					end if;

				when SR_DATA_READ =>
					mem_data		<= (others => 'Z');
					mem_bus.address	<= st_reg;
					mem_bus.rw		<= RW_READ;
					mem_bus.en  	<= '1';
					sr_inc   		<= '1';

					if mem_da = '1'
					then
						sr_inc		<= '0';
						data		<= mem_data;
						da			<= '1';		-- the data is available to when it is needed.
						mem_bus		<= INIT_MEMORY_BUS;
						state		<= SR_FINISHED;
					end if;

				when SR_FLAGS_READ =>
					mem_data		<= (others => 'Z');
					mem_bus.address	<= st_reg;
					mem_bus.rw		<= RW_READ;
					mem_bus.en  	<= '1';
					sr_inc   		<= '1';

					if mem_da = '1'
					then
						sr_inc		<= '0';
						data		<= mem_data;
						da			<= '1';		-- the data is available to when it is needed.
						mem_bus		<= INIT_MEMORY_BUS;
						state		<= SR_FINISHED;
					end if;

				when SR_PC_READ =>
					mem_data		<= (others => 'Z');
					mem_bus.address	<= st_reg;
					mem_bus.rw		<= RW_READ;
					mem_bus.en		<= '1';
					sr_inc   		<= '1';

					if mem_da = '1'
					then
						sr_inc		<= '0';
						data		<= mem_data;
						pc_load		<= '1';
						mem_bus		<= INIT_MEMORY_BUS;

						if sr_bus.mode = SR_CALL
						then
							state <= SR_FINISHED;
						else
							state <= SR_FLAGS_READ;
						end if;
					end if;

				when SR_STACK_READ =>
					mem_data		<= (others => 'Z');
					mem_bus.address	<= st_reg;
					mem_bus.rw		<= RW_READ;
					mem_bus.en		<= '1';
					sr_inc			<= '1';

					if mem_da = '1'
					then
						sr_inc		<= '0';
						sr_loads	<= '1';		-- the data is available to when it is needed.
						mem_bus		<= INIT_MEMORY_BUS;
						state		<= SR_PC_READ;
					end if;

				when SR_FINISHED =>
					sr_inc		<= '0';
					sr_dec		<= '0';
					sr_load		<= '0';
					sr_loads	<= '0';
					mem_bus		<= INIT_MEMORY_BUS;
					complete	<= '1';

				when others => null;
			end case;
		end if;

	end process;

	-- stack value should always be available.
	stack_value <= st_reg;

end architecture synth;

-- vi:nocin:sw=4 ts=4:fdm=marker
