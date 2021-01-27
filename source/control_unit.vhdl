-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--					
--
-- Name  : control_unit
-- Desc  : This entity is the control unit for the CPU.
--         This unit does the instruction decoding and will control the other
--         units via the bus control signals.
--
-- Author: Peter Antoine
-- Date  : 24/01/2021
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

entity ControlUnit is
		port(
			reset			: in std_logic;		-- reset all the registers.
			clock			: in std_logic;		-- the clock.
			data_strobe		: in std_logic;		-- the data strobe

			data_bus		: in std_logic_vector(DATA_WIDTH-1 downto 0);
			sys_bus			: out SYSTEM_BUS	-- the system bus control signals.
		);
end ControlUnit;

architecture synth of ControlUnit is
	signal status_register : CPU_FLAGS;
	signal instruction_register : std_logic_vector(DATA_WIDTH-1 downto 0);	-- the instruction register
	signal fetch : std_logic;

begin
	process (reset)
	begin
		if reset = '1'
		then
			-- reset the status register bits.
			status_register.carry_flag				<= '0';
			status_register.zero_flag				<= '0';
			status_register.sign_flag				<= '0';
			status_register.minus_flag				<= '0';
			status_register.exception_flag			<= '0';
			status_register.interrupt_flag			<= '0';
			status_register.hardware_interrupt		<= '0';
			status_register.interrupt_waiting		<= '0';
			status_register.interrupts_masked		<= '0';
			status_register.non_masked_interrupt	<= '0';
		end if;
	end process;

	------------------------------------------------------------
	--- Instruction Fetch
	------------------------------------------------------------
	process (fetch) is
	begin
		case (fetch) is
			when '1' =>
				sys_bus.bus_enable 		<= '1';
				sys_bus.bus_rw			<= RW_READ;
				sys_bus.addr_data 		<= SYS_REG_ADDR;
				sys_bus.sys_reg_enable	<= '1';

			when others =>
				sys_bus.bus_enable 		<= '0';
				sys_bus.bus_rw			<= RW_READ;
				sys_bus.addr_data 		<= SYS_REG_DATA;
				sys_bus.sys_reg_enable	<= '0';
		end case;
	end process;

	process (clock, fetch, data_strobe)
	begin
		if fetch = '1' and data_strobe = '1' and falling_edge(clock)
		then
			instruction_register <= data_bus;
		end if;
	end process;
	

	------------------------------------------------------------
	--- CPU state machine.
	------------------------------------------------------------
	process (int_clock,reset)
	begin
		if (reset = '1')
		then
			state	<= SM_IFETCH;
			execute <= '0';
			fetch 	<= '0';
			
		elsif (rising_edge(clock))
		then
			case state is
				when SM_IFETCH		=>	fetch		<= '1';
										pc			<= next_addr;
										execute		<= '0';
										state		<= SM_OFETCH;

				when SM_OFETCH		=>	fetch 		<= '1';
										pc			<= next_addr;
										execute		<= '0';
										state		<= SM_EXECUTE;
			
				when SM_EXECUTE		=>	fetch		<= '0';
										execute		<= '1';
										state		<= SM_IFETCH;

				when others			=>	null;
			end case;

		end if;
	end process;

end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
