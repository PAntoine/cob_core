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
			reset		: in std_logic;
			enable		: in std_logic;
			clock		: in std_logic;
			write		: in std_logic;
			int_id		: in INT_ID;									-- the interrupt vector to jump/write to.
			flags		: in CPU_FLAGS;
			complete	: out std_logic;
			pc_load		: out std_logic;
			data		: inout std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end entity InterruptExceptionUnit;
	
architecture synth of InterruptExceptionUnit is

begin
	---------------------------------------------------------------
	--- define the registers.
	---------------------------------------------------------------
	process (reset, clock, write, data, ind_id)
	begin
		if reset = '1'
		then
			register_bank <= (others => (others => '0'));
		
		elsif write = '1' and falling_edge(clock)
		then
			interrupt_vector(to_integer(unsigned(int_id))) <= data;
		end if;
	end process;

	---------------------------------------------------------------
	--- handle an exception 
	---------------------------------------------------------------
	process (reset, pc, mem_da)
		variable state : std_logic_vector(1 downto 0);

	begin
		if enable = '0'
		then
			pc_laod		<= 'Z';
			stach_save	<= 'Z';
			complete	<= 'Z';
			data		<= (others => 'Z');
		
		else
			case state is
				when "00" =>	complete	<= '0';
					   			stach_save	<= '1';
					   			state		<= "001";

				when "01" =>	if stack_complete = '1'
								then
									data		<= interrupt_vector(to_integer(unsigned(flags.interrupt_id)));
									pc_load		<= '1';
									state		<= "010";
									stach_save	<= '0';
								end if;

				when "10" =>	pc_load		<= '0';
								complete	<= '1';
								data		<= (others => 'Z');

				case others =>	null;
			end case;
		end if;
	end process;

end architecture synth;

-- vi:nocin:sw=4 ts=4:fdm=marker
