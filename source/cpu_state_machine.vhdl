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
			reset			: in std_logic;
			enable			: in std_logic;
			clock			: in std_logic;
			reg_read		: in std_logic;
			reg_write		: in std_logic;
			mem_read		: in std_logic;
			mem_write		: in std_logic;
			mem_complete	: in std_logic;
			sys_bus			: out SYSTEM_BUS
		);
end CPUStateMachine;

architecture synth of CPUStateMachine is
	signal 		state			: CPU_STATE;
	
begin
	------------------------------------------------------------
	--- Logic state machine
	------------------------------------------------------------
	--  TODO: should separate the sys bus settings from the state machine. So they do not have to
	-- wait for the next clock to change will make the thing quicker - change that later.

	process (reset, enable, state, clock)
	begin
		if reset = '1' or enable = '0'
		then
			state		<= CS_FETCH;
			sys_bus.fetch		<= '0';
			sys_bus.read		<= '0';
			sys_bus.wait_read	<= '0';
			sys_bus.execute		<= '0';
			sys_bus.write		<= '0';
			sys_bus.wait_write	<= '0';

		elsif rising_edge(clock)
		then
			case state is
				when CS_FETCH =>
						sys_bus.fetch		<= '1';
						sys_bus.read		<= '0';
						sys_bus.execute		<= '0';
						sys_bus.write		<= '0';
						sys_bus.wait_read	<= '0';
						sys_bus.wait_write	<= '0';

						if mem_complete = '0'
						then
							state	<= CS_DECODE;
						end if;

				when CS_DECODE	=>
						sys_bus.fetch		<= '0';
						sys_bus.execute		<= '0';
						sys_bus.write		<= '0';
						sys_bus.wait_read	<= '0';
						sys_bus.wait_write	<= '0';

						if reg_read = '1'
						then
							sys_bus.read	<= '1';
						else
							sys_bus.read	<= '0';
						end if;

						if mem_read = '1'
						then
							state	<= CS_READ_WAIT;		-- wait state while waiting for the memory device to do it's work.
						else	
							state	<= CS_EXECUTE;
						end if;

				when CS_READ_WAIT =>
						sys_bus.fetch		<= '0';
						sys_bus.read		<= '0';
						sys_bus.execute		<= '0';
						sys_bus.write		<= '0';
						sys_bus.wait_read	<= '1';
						sys_bus.wait_write	<= '0';
						
						if mem_complete = '1'
						then
							state	<= CS_EXECUTE;
						end if;

				when CS_EXECUTE =>
						sys_bus.fetch		<= '0';
						sys_bus.read		<= '0';
						sys_bus.execute		<= '1';
						sys_bus.write		<= '0';
						sys_bus.wait_read	<= '0';
						sys_bus.wait_write	<= '0';
						-- double wrong TODO: this should select what write state to goto and it
						-- it should wait for the execution to complete.

						if mem_write = '1'
						then
							state	<= CS_WRITE_WAIT;
						elsif reg_write = '1'
						then
							state	<= CS_WRITE;
						else
							state	<= CS_FETCH;
						end if;

				when CS_WRITE =>
						sys_bus.fetch		<= '0';
						sys_bus.read		<= '0';
						sys_bus.execute		<= '0';
						sys_bus.write		<= '1';
						sys_bus.wait_read	<= '0';
						sys_bus.wait_write	<= '0';
						
						if mem_write = '1'
						then
							state	<= CS_WRITE_WAIT;		-- wait until the memory device completes it's write.
						else
							state	<= CS_FETCH;
						end if;
				
				when CS_WRITE_WAIT =>
						sys_bus.fetch		<= '0';
						sys_bus.read		<= '0';
						sys_bus.execute		<= '0';
						sys_bus.write		<= '0';
						sys_bus.wait_read	<= '0';
						sys_bus.wait_write	<= '1';
						
						if mem_complete = '1'
						then
							state	<= CS_FETCH;
						end if;
				
				when others =>
						sys_bus.fetch		<= '0';
						sys_bus.read		<= '0';
						sys_bus.execute		<= '0';
						sys_bus.write		<= '0';
						sys_bus.wait_read	<= '0';
						sys_bus.wait_write	<= '0';
						state				<= CS_HALT;
			end case;
		end if;
	end process;

end architecture synth;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
