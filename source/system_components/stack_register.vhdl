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
			reset		: in std_logic;
			enable		: in std_logic;
			clock		: in std_logic;
			write		: in std_logic;
			int_id		: in INT_ID;									-- the interrupt vector to jump/write to.
			flags		: in CPU_FLAGS;
			pc			: in std_logic_vector(ADDR_WIDTH-1 downto 0);

			mem_bus		: out MEMORY_BUS;
			mem_data	: out std_logic_vector(DATA_WIDTH-1 downto 0);
			mem_da		: in  std_logic;

			complete	: out std_logic;
			pc_load		: out std_logic;
			data		: inout std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end entity StackRegister;
	
architecture synth of StackRegister is

	signal st_reg	: std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal sr_inc	: std_logic;
	signal sr_dec	: std_logic;

begin

	-- manage the stack register.
	process (reset, sr_inc, sr_dec, mem_da)
	begin
		if reset = '1'
		then
			st_reg <= ZEROS;
		
		elsif enable = '1' and falling_edge(clock)
		then
			if sr_inc = '1'
			then
				st_reg <= std_logic_vector(unsigned(st_reg) + ADDR_BYTES);
			
			elsif sr_dec = '1'
			then
				st_reg <= std_logic_vector(unsigned(st_reg) - ADDR_BYTES);
			end if;
		end if;
	end process;

	process (enable, state)
	begin
		if enable = '0'
		then
			state  <= SR_START;
			sr_inc <= '0';
			sr_dec <= '0';

		else rising_edge(clock)
			case state is
				when SR_START => 	case mode is
										when SR_PUSH 	=> state <= SR_DATA_WRITE;
										when SR_CALL 	=> state <= SR_PC_WRITE;
										when SR_SAVE 	=> state <= SR_FLAGS_WRITE;
										when SR_POP		=> state <= SR_DATA_READ;
										when SR_RET		=> state <= SR_PC_READ;
										when SR_LOAD	=> state <= SR_FLAGS_READ;
										when others		=> null;
									end case;

				when SR_DATA_WRITE =>
						mem_data		<= data;
						mem_bus.addr	<= sr_value;
						mem_bus.rw		<= '1';
						mem_bus.en		<= '1';
						sr_dec			<= '1';

						if mem_da = '1'
						then
							sr_dec		<= '0';
							mem_bus.en	<= '0';
							state		<= SR_FINISHED;
						end if;

				when SR_FLAGS_WRITE =>
						mem_data		<= flags;
						mem_bus.addr	<= sr_value;
						mem_bus.rw		<= '1';
						mem_bus.en		<= '1';
						sr_dec			<= '1';

						if mem_da = '1'
						then
							sr_dec		<= '0';
							mem_bus.en	<= '0';
							state		<= SR_PC_WRITE;
						end if;

				when SR_PC_WRITE =>
						mem_data		<= pc;
						mem_bus.addr	<= sr_value;
						mem_bus.rw		<= '1';
						mem_bus.en		<= '1';
						sr_dec			<= '1';

						if mem_da = '1'
						then
							sr_dec		<= '0';
							mem_bus.en	<= '0';
							
							if mode = SR_CALL
							then
								state <= SR_FINISHED;
							else
								state <= SR_STACK_WRITE;
							end if;
						end if;
				
				when SR_STACK_WRITE =>
						mem_data		<= flags;
						mem_bus.addr	<= sr_value;
						mem_bus.rw		<= '1';
						mem_bus.en		<= '1';
						sr_dec			<= '1';

						if mem_da = '1'
						then
							sr_dec		<= '0';
							mem_bus.en	<= '0';
							state		<= SR_FINISHED;
						end if;

				when SR_DATA_READ =>
						mem_data		<= (others => 'Z');
						mem_bus.addr	<= sr_value;
						mem_bus.rw		<= RW_READ;
						mem_bus.en  	<= '1';
						sr_inc   		<= '1';

						if mem_da = '1'
						then
							sr_inc		<= '0';
							data		<= mem_data;
							da			<= '1';		-- the data is available to when it is needed.
							mem_bus.en	<= '0';
							state		<= SR_FINISHED;
						end if;

				when SR_PC_DATA =>
						mem_data	 <= (others => 'Z');
						mem_bus.addr <= sr_value;
						mem_bus.rw   <= RW_READ;
						mem_bus.en   <= '1';
						sr_inc   <= '1';

						if mem_da = '1'
						then
							sr_inc	<= '0';
							pc_data	<= mem_data;
							pc_load	<= '1';
							mem_bus.en	<= '0';

							if mode = SR_CALL
							then
								state <= SR_FINISHED;
							else
								state <= SR_STACK_READ;
							end if;
						end if;
								
				when SR_STACK_READ =>
						mem_data <= (others => 'Z');
						mem_bus.addr <= sr_value;
						mem_bus.rw   <= RW_READ;
						mem_bus.en   <= '1';
						sr_inc   <= '1';

						if mem_da = '1'
						then
							sr_inc		<= '0';
							st_data		<= mem_data;
							st_loads	<= '1';		-- the data is available to when it is needed.
							mem_bus.en	<= '0';
							state		<= SR_FINISHED;
						end if;

				when SR_FINISHED =>
					sr_inc		<= '0';
					sr_dec		<= '0;
					mem_bus.en	<= '0';

				when others => null;
			end case;
		end if;

	end process;


end architecture synth;

-- vi:nocin:sw=4 ts=4:fdm=marker
