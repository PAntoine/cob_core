-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : logic_decoder
-- Desc  : This entity handles the logic
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
use work.LogicFunctions.all;

entity LogicDecoder is
		port(
			sel				: in std_logic;
			instruction_reg	: in std_logic_vector(DATA_WIDTH-1 downto 0);
			sys_bus			: inout SYSTEM_BUS
		);
end LogicDecoder;

architecture synth of LogicDecoder is
	type LOGIC_BUS is record
		and_enabled	:	std_logic;	-- the command is and
		or_enabled	:	std_logic;	-- the command is or
		lsl_enabled :	std_logic;	-- the logical shift left command
		lsr_enabled :	std_logic;	-- the logical shift right command
	end record LOGIC_BUS;

    signal op_code : std_logic_vector(INSTR_OPCODE_RANGE);

	signal accumulator 	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal a_reg		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal b_reg		: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal bus_contro	: LOGIC_BUS;
begin
	------------------------------------------------------------
	--- Logic Instruction Decoder
	------------------------------------------------------------
	op_code <= instruction_reg(INSTR_OPCODE_RANGE);

	process (sel, op_code) is
	begin
		if sel = '1'
		then
			case op_code is
				when LI_LSL => accumulator <= LogicalShiftLeft(a_reg, b_reg(4 downto 0));
				when LI_LSR => accumulator <= LogicalShiftRight(a_reg, b_reg(4 downto 0));
				when others	=> accumulator <= (others => '0');
			end case;
		end if;
	end process;

	------------------------------------------------------------
	--- Decode Instruction Input
	------------------------------------------------------------
	io_code		<= instruction_reg(LI_IO_CODE);
	a_source	<= instruction_reg(LI_SOURCE_A);
	b_source	<= instruction_reg(LI_SOURCE_B);
	dest		<= instruction_reg(LI_DEST);

	process (io_code) is
	begin
		case io_code is
			when "000" =>
						-- reg in for a and b,
						reg_1_addr			<= a_source;
						reg_2_addr			<= b_source;
						mem_addr			<= (others => 'X');
						sys_bus.mem_rw		<= RW_READ;
						sys_bus.reg_rw		<= RW_READ;
						sys_bus.reg_1_en	<= '1';
						sys_bus.reg_2_en	<= '1';
						sys_bus.mem_en		<= '0';
						
						a_reg	<= reg_1_data;
						b_reg	<= reg_2_data;

			when "001" =>
						-- mem read for a, and reg red for b.
						reg_1_addr			<= (others => 'X');
						reg_2_addr			<= b_source;
						mem_addr			<= a_source;
						sys_bus.reg_rw		<= RW_READ;
						sys_bus.mem_rw		<= RW_READ;
						sys_bus.reg_1_en	<= '1';
						sys_bus.reg_2_en	<= '0';
						sys_bus.mem_en		<= '1';
						
						a_reg	<= mem_data;
						b_reg	<= reg_2_data;

			when "010" =>
						-- source a reg, source b mem. 
						reg_1_addr			<= a_source;
						reg_2_addr			<= (others => 'X');
						mem_addr			<= b_source;
						sys_bus.reg_rw		<= RW_READ;
						sys_bus.mem_rw		<= RW_READ;
						sys_bus.reg_1_en	<= '0';
						sys_bus.reg_2_en	<= '1';
						sys_bus.mem_en		<= '1';

						a_reg	<= reg_1_data;
						b_reg	<= mem_data;

			when "011" =>
						-- Only reg a.
						reg_1_addr			<= a_source;
						reg_2_addr			<= (others => 'X');
						mem_addr			<= (others => 'X');
						sys_bus.reg_rw		<= RW_READ;
						sys_bus.mem_rw		<= RW_READ;
						sys_bus.reg_1_en	<= '1';
						sys_bus.reg_2_en	<= '0';
						sys_bus.mem_en		<= '0';

						a_reg	<= reg_1_data;
						b_reg	<= (others => '0');

			when "100" =>
						-- mem read for a, immidate for b.
						reg_1_addr			<= a_source;
						reg_2_addr			<= (others => 'X');
						mem_addr			<= (others => 'X');
						sys_bus.reg_rw		<= RW_READ;
						sys_bus.mem_rw		<= RW_READ;
						sys_bus.reg_1_en	<= '1';
						sys_bus.reg_2_en	<= '0';
						sys_bus.mem_en		<= '0';
						
						a_reg	<= reg_1_data;
						b_reg	<= ZEROS(31 downto 5) & b_source;

			when others =>
						sys_bus.exception	<= '1';		-- This is an illegal instruction.
						reg_1_addr			<= (others => 'X');
						reg_2_addr			<= (others => 'X');
						mem_addr			<= (others => 'X');
						sys_bus.reg_rw		<= RW_READ;
						sys_bus.mem_rw		<= RW_READ;
						sys_bus.reg_1_en	<= '0';
						sys_bus.reg_2_en	<= '0';
						sys_bus.mem_en		<= '0';
		end case;
	end process;

	------------------------------------------------------------
	--- Logic state machine
	------------------------------------------------------------
	process (sel, state, instruction_reg)
	begin
		if sel = '0'
		then

		else
			case state =>
				when  X 	=> bus_logic <= "00000000";

				when others => u <= "00000000";

			end case;

	end process;

	------------------------------------------------------------
	--- Logic unit
	------------------------------------------------------------


end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker

