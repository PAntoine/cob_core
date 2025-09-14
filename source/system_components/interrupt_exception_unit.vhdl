-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : interrupt_exception_unit
-- Desc  : Interrupt and Exception Unit.
--
--         This component will handle the interrupts and exceptions also handling
--         the transition to the PC state, as well as loading and updating the
--         program counter. It will also cause the stack register to do an update
--         if required.
--
-- Author: Peter Antoine
-- Date  : 13/04/2021
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

entity InterruptExceptionUnit is
	port(
			reset			: in	std_logic;
			enable			: in	std_logic;		--- enable interrupts
			clock			: in	std_logic;
			load_ivect		: in	std_logic;		--- load a interrupt vector.
			int_id			: in	INT_ID_TYPE;	--- the interrupt vector to load.
			interrupt		: in	std_logic;		--- start an exception.
			complete		: out	std_logic;      --- The interrupt is complete.
			sr_bus			: out	STACK_BUS;
			stack_complete	: in	std_logic;      --- The stack has finished doing it's thing.
			set_flags_intid	: out	std_logic;
			pc_load			: out	std_logic;
			data			: inout	std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end entity InterruptExceptionUnit;

architecture synth of InterruptExceptionUnit is

	---------------------------------------------------------------
	--- define the interrupt vector.
	---------------------------------------------------------------
	type INTERRUPT_VECTOR_ARRAY is array(0 to NUM_REGISTERS) of std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal interrupt_vector : INTERRUPT_VECTOR_ARRAY := (others => (others => '0'));

	-- states
	subtype STATES is std_logic_vector(1 downto 0);

	constant	SAVE_STACK				: STATES := "00";
	constant	JUMP_TO_EXCEPTION		: STATES := "01";
	constant	PUSH_PC					: STATES := "10";
	constant	FINISHED				: STATES := "11";

begin
	---------------------------------------------------------------
	--- manage the interrupt vectors.
	---------------------------------------------------------------
	process (reset, clock, load_ivect, data, int_id)
	begin
		if reset = '1'
		then
			interrupt_vector <= (others => (others => '0'));

		elsif load_ivect = '1' and falling_edge(clock)
		then
			interrupt_vector(to_integer(unsigned(int_id))) <= data;
		end if;
	end process;

	---------------------------------------------------------------
	--- handle an exception
	---------------------------------------------------------------
	process (reset, enable, interrupt, interrupt_vector)
		variable state : std_logic_vector(1 downto 0);

	begin
		if enable = '0'
		then
			complete		<= '0';
			pc_load			<= 'Z';
			set_flags_intid	<= '0';
			state			:= SAVE_STACK;			-- this is safe as the bus is free.
			sr_bus			<= FREE_STACK_BUS;
			data			<= (others => 'Z');

		elsif interrupt = '1' and falling_edge(clock)		-- we start handling the interrupt when the int flag goes high.
		then
			case state is
				when SAVE_STACK =>
					pc_load		<= '0';
					complete	<= '0';
					sr_bus.en	<= '1';
					sr_bus.mode	<= SR_INT_CALL;

					if stack_complete = '1'
					then
						state	:= JUMP_TO_EXCEPTION;
						data	<= interrupt_vector(to_integer(unsigned(int_id)));
					end if;

				when JUMP_TO_EXCEPTION =>
					pc_load			<= '1';
					set_flags_intid	<= '1';
					state			:= FINISHED;
											-- TODO: what value are we setting to the flags?
											--       it should have the interrupt id.
											--       what about the return from interrupt?

				when FINISHED =>
					complete		<= '1';
					pc_load			<= '0';
					set_flags_intid	<= '0';

				when others =>	null;
			end case;
		end if;
	end process;

end architecture synth;

-- vi:nocin:sw=4 ts=4:fdm=marker
