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
			mode			: in DATA_MODE;			-- the data mode to be decoded.
			reg_1_rw		: out std_logic;		-- register 1 read write status
			reg_1_en		: out std_logic;		-- register 1 enable.
			reg_2_rw		: out std_logic;		-- register 2 read write status
			reg_2_en		: out std_logic;		-- register 2 enable.
			mem_read		: out std_logic;		-- memory read/write status.
			mem_write		: out std_logic;		-- write to memory.
			mem_read_a		: out std_logic;		-- read into register a (or b - if false).
			immediate_8 	: out std_logic;		-- use the immediate 8 bits from the instruction.
			exception_flag	: out std_logic			-- we have an exception.
		);
end AddressModeDecoder;

architecture synth of AddressModeDecoder is
begin
	process (sel, mode) is
	begin
		if (sel = '0')
		then
			reg_1_rw		<= 'Z';
			reg_2_rw		<= 'Z';
			reg_1_en		<= 'Z';
			reg_2_en		<= 'Z';
			mem_read_a		<= 'Z';
			mem_read		<= 'Z';
			mem_write		<= 'Z';
			immediate_8 	<= 'Z';
			exception_flag	<= 'Z';

		else
			case mode is
				when LI_DA_RRR =>
					-- reg in for a and b,
					reg_1_rw		<= RW_READ;
					reg_2_rw		<= RW_READ;
					reg_1_en		<= '1';
					reg_2_en		<= '1';
					mem_read_a		<= '0';
					mem_read		<= '0';
					mem_write		<= '0';
					immediate_8 	<= '0';
					exception_flag	<= '0';
							
				when LI_DA_MRR =>
					-- mem read for a, and reg read for b.
					-- read reg a then use that as the
					-- address for the memory read.
					reg_1_rw		<= RW_READ;
					reg_2_rw		<= RW_READ;
					reg_1_en		<= '1';
					reg_2_en		<= '1';
					mem_read_a		<= '1';
					mem_read		<= '1';
					mem_write		<= '0';
					immediate_8 	<= '0';
					exception_flag	<= '0';
							
				when LI_DA_RMR =>
					-- source a reg, source b mem. 
					reg_1_rw		<= RW_READ;
					reg_2_rw		<= RW_READ;
					reg_1_en		<= '1';
					reg_2_en		<= '1';
					mem_read_a		<= '0';
					mem_read		<= '1';
					mem_write		<= '0';
					immediate_8 	<= '0';
					exception_flag	<= '0';

				when LI_DA_R_R =>
					-- Only reg a.
					reg_1_rw		<= RW_READ;
					reg_2_rw		<= RW_READ;
					reg_1_en		<= '1';
					reg_2_en		<= '0';
					mem_read_a		<= '0';
					mem_read		<= '0';
					mem_write		<= '0';
					immediate_8 	<= '0';
					exception_flag	<= '0';

				when LI_DA_RIR =>
					-- reg read for a, immediate for b.
					reg_1_rw		<= RW_READ;
					reg_2_rw		<= RW_READ;
					reg_1_en		<= '1';
					reg_2_en		<= '0';
					mem_read_a		<= '0';
					mem_read		<= '0';
					mem_write		<= '0';
					immediate_8 	<= '1';
					exception_flag	<= '0';

				when others =>
					--sys_bus.exception	<= '1';		-- This is an illegal instruction.
					exception_flag	<= '1';
					reg_1_rw		<= RW_READ;
					reg_2_rw		<= RW_READ;
					reg_1_en		<= '0';
					reg_2_en		<= '0';
					mem_read_a		<= '0';
					mem_read		<= '0';
					mem_write		<= '0';
					immediate_8 	<= '0';
			end case;
		end if;
	end process;

end architecture synth;

--- vi:nocin:ai:sw=4 ts=4:fdm=marker
