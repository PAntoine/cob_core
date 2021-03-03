-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : address mode decoder.
-- Desc  : This entity decodes the address modes.
--
-- Author: Peter Antoine
-- Date  : 23/02/2021
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

entity AddressModeDecoder is
		port(
			sel				: in std_logic;			-- enable the address mode decoding.
			mode			: in ADDRESSING_MODE;	-- the data mode to be decoded.
			addr_mode_bus	: out ADDRESS_MODE_BUS;	-- the address mode bus signals.
			exception_flag	: out std_logic			-- we have an exception.
		);
end AddressModeDecoder;

architecture synth of AddressModeDecoder is
begin
	process (sel, mode) is
	begin
		if (sel = '0')
		then
			addr_mode_bus <= FREE_ADDRESS_MODE_BUS;
			exception_flag	<= 'Z';

		else
			case mode is
				when AM_RRR =>
					-- reg in for a and b,
					addr_mode_bus.reg_1_rw		<= RW_READ;
					addr_mode_bus.reg_2_rw		<= RW_READ;
					addr_mode_bus.reg_1_en		<= '1';
					addr_mode_bus.reg_2_en		<= '1';
					addr_mode_bus.mem_read_a	<= '0';
					addr_mode_bus.mem_read		<= '0';
					addr_mode_bus.mem_write		<= '0';
					addr_mode_bus.immediate_8 	<= '0';
					exception_flag	<= '0';
							
				when AM_MRR =>
					-- mem read for a, and reg read for b.
					-- read reg a then use that as the
					-- address for the memory read.
					addr_mode_bus.reg_1_rw		<= RW_READ;
					addr_mode_bus.reg_2_rw		<= RW_READ;
					addr_mode_bus.reg_1_en		<= '1';
					addr_mode_bus.reg_2_en		<= '1';
					addr_mode_bus.mem_read_a	<= '1';
					addr_mode_bus.mem_read		<= '1';
					addr_mode_bus.mem_write		<= '0';
					addr_mode_bus.immediate_8 	<= '0';
					exception_flag	<= '0';
							
				when AM_RMR =>
					-- source a reg, source b mem. 
					addr_mode_bus.reg_1_rw		<= RW_READ;
					addr_mode_bus.reg_2_rw		<= RW_READ;
					addr_mode_bus.reg_1_en		<= '1';
					addr_mode_bus.reg_2_en		<= '1';
					addr_mode_bus.mem_read_a	<= '0';
					addr_mode_bus.mem_read		<= '1';
					addr_mode_bus.mem_write		<= '0';
					addr_mode_bus.immediate_8 	<= '0';
					exception_flag	<= '0';

				when AM_R_R =>
					-- Only reg a.
					addr_mode_bus.reg_1_rw		<= RW_READ;
					addr_mode_bus.reg_2_rw		<= RW_READ;
					addr_mode_bus.reg_1_en		<= '1';
					addr_mode_bus.reg_2_en		<= '0';
					addr_mode_bus.mem_read_a	<= '0';
					addr_mode_bus.mem_read		<= '0';
					addr_mode_bus.mem_write		<= '0';
					addr_mode_bus.immediate_8 	<= '0';
					exception_flag	<= '0';

				when AM_RIR =>
					-- reg read for a, immediate for b.
					addr_mode_bus.reg_1_rw		<= RW_READ;
					addr_mode_bus.reg_2_rw		<= RW_READ;
					addr_mode_bus.reg_1_en		<= '1';
					addr_mode_bus.reg_2_en		<= '0';
					addr_mode_bus.mem_read_a	<= '0';
					addr_mode_bus.mem_read		<= '0';
					addr_mode_bus.mem_write		<= '0';
					addr_mode_bus.immediate_8 	<= '1';
					exception_flag	<= '0';

				when others =>
					--sys_bus.exception	<= '1';		-- This is an illegal instruction.
					exception_flag	<= '1';
					addr_mode_bus.reg_1_rw		<= RW_READ;
					addr_mode_bus.reg_2_rw		<= RW_READ;
					addr_mode_bus.reg_1_en		<= '0';
					addr_mode_bus.reg_2_en		<= '0';
					addr_mode_bus.mem_read_a	<= '0';
					addr_mode_bus.mem_read		<= '0';
					addr_mode_bus.mem_write		<= '0';
					addr_mode_bus.immediate_8 	<= '0';
			end case;
		end if;
	end process;

end architecture synth;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
