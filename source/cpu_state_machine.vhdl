-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : CPU State Machine
-- Desc  : This entity is the state machine that drives the CPU.
--
-- Author: Peter Antoine
-- Date  : 24/01/2021
-----------------------------------------------------------------------------------
--					   Copyright (c) 2021 Peter Antoine
--							  All rights Reserved.
--					  Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;

entity CPUStateMachine is
		port(
			reset				: in	std_logic;
			enable				: in	std_logic;
			clock				: in	std_logic;
			fetch_complete		: in	std_logic;
			load_complete		: in	std_logic;
			write_complete		: in	std_logic;
			execute_complete	: in	std_logic;
			state				: out	CPU_STATE;
		);
end CPUStateMachine;

architecture synth of CPUStateMachine is
	signal 		state			: CPU_STATE;
	
begin
	------------------------------------------------------------
	--- Logic state machine
	------------------------------------------------------------
	process (reset, enable, state, clock)
	begin
		if reset = '1' or enable = '0'
		then
			state <= CS_IDLE;

		elsif clock'event
		then
			case state is
				when CS_IDLE => state <= CS_FETCH_DECODE;
				
				when CS_FETCH_DECODE =>
					if fetch_complete = '0'
					then
						state <= CS_LOAD;
					end if;

				when CS_LOAD =>
					if load_complete = '1'
					then
						state <= CS_EXECUTE;
					end if;
				
				when CS_EXECUTE =>
					if execute_complete = '1'
					then
						-- TODO: check the flags - this is where exceptions should cause a branch or the halt state should happen.
						state <= CS_WRITE;
					end if;

				when CS_WRITE =>
					if write_complete = '1'
					then
						state <= CS_FETCH_DECODE;
					end if;
				
				when others => state <= CS_HALT;
			end case;
		end if;
	end process;

end architecture synth;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
