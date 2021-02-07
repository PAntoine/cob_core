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
			clock           : in std_logic;
			instruction_reg	: in std_logic_vector(DATA_WIDTH-1 downto 0);
			sys_bus			: inout SYSTEM_BUS;
			reg_bus			: inout REGISTER_BUS;
			mem_bus			: inout MEMORY_BUS
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

	signal a_source		: REG_ID;
	signal b_source		: REG_ID;
	signal dest			: REG_ID;

	signal 		state		: std_logic_vector(1 downto 0);
	constant	LI_IDLE		: std_logic_vector(1 downto 0) := "00";
	constant	LI_EXECUTE	: std_logic_vector(1 downto 0) := "01";
	constant	LI_WRITE	: std_logic_vector(1 downto 0) := "10";
	constant	LI_FINISHED	: std_logic_vector(1 downto 0) := "11";

	signal read		: std_logic;
	signal execute	: std_logic;
	signal write	: std_logic;

	signal bus_control	: LOGIC_BUS;
begin
	------------------------------------------------------------
	--- Logic Instruction Decoder
	------------------------------------------------------------
	op_code <= instruction_reg(INSTR_OPCODE_RANGE);

	process (sel, a_reg, b_reg, op_code) is
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
	a_source	<= instruction_reg(LI_SOURCE_A);
	b_source	<= instruction_reg(LI_SOURCE_B);
	dest		<= instruction_reg(LI_DEST);

	process (instruction_reg, a_reg, b_reg, a_source, b_source, reg_bus) is
	begin
		case instruction_reg(LI_IO_CODE) is
			when "000" =>
						-- reg in for a and b,
						reg_bus.reg_1_addr	<= a_source;
						reg_bus.reg_2_addr	<= b_source;
						reg_bus.reg_1_rw	<= RW_READ;
						reg_bus.reg_2_rw	<= RW_READ;
						reg_bus.reg_1_en	<= '1';
						reg_bus.reg_2_en	<= '1';
						mem_bus.mem_addr	<= (others => 'X');
						mem_bus.mem_rw		<= RW_READ;
						mem_bus.mem_en		<= '0';
						
						a_reg	<= reg_bus.reg_1_data;
						b_reg	<= reg_bus.reg_2_data;

			when "001" =>
						-- mem read for a, and reg red for b.
						reg_bus.reg_1_addr	<= (others => 'X');
						reg_bus.reg_2_addr	<= b_source;
						reg_bus.reg_1_rw	<= RW_READ;
						reg_bus.reg_2_rw	<= RW_READ;
						reg_bus.reg_1_en	<= '1';
						reg_bus.reg_2_en	<= '0';
						mem_bus.mem_addr	<= a_reg;
						mem_bus.mem_rw		<= RW_READ;
						mem_bus.mem_en		<= '1';
						
						a_reg	<= mem_bus.mem_data;
						b_reg	<= reg_bus.reg_2_data;

			when "010" =>
						-- source a reg, source b mem. 
						reg_bus.reg_1_addr	<= a_source;
						reg_bus.reg_2_addr	<= (others => 'X');
						reg_bus.reg_1_rw	<= RW_READ;
						reg_bus.reg_2_rw	<= RW_READ;
						reg_bus.reg_1_en	<= '0';
						reg_bus.reg_2_en	<= '1';
						mem_bus.mem_addr	<= b_reg;
						mem_bus.mem_rw		<= RW_READ;
						mem_bus.mem_en		<= '1';

						a_reg	<= reg_bus.reg_1_data;
						b_reg	<= mem_bus.mem_data;

			when "011" =>
						-- Only reg a.
						reg_bus.reg_1_addr	<= a_source;
						reg_bus.reg_2_addr	<= (others => 'X');
						reg_bus.reg_1_rw	<= RW_READ;
						reg_bus.reg_2_rw	<= RW_READ;
						reg_bus.reg_1_en	<= '1';
						reg_bus.reg_2_en	<= '0';
						mem_bus.mem_addr	<= (others => 'X');
						mem_bus.mem_rw		<= RW_READ;
						mem_bus.mem_en		<= '0';

						a_reg	<= reg_bus.reg_1_data;
						b_reg	<= (others => '0');

			when "100" =>
						-- mem read for a, immediate for b.
						reg_bus.reg_1_addr	<= a_source;
						reg_bus.reg_2_addr	<= (others => 'X');
						reg_bus.reg_1_rw	<= RW_READ;
						reg_bus.reg_2_rw	<= RW_READ;
						reg_bus.reg_1_en	<= '1';
						reg_bus.reg_2_en	<= '0';
						mem_bus.mem_addr	<= (others => 'X');
						mem_bus.mem_rw		<= RW_READ;
						mem_bus.mem_en		<= '0';
						
						a_reg	<= reg_bus.reg_1_data;
						b_reg	<= ZEROS(31 downto 5) & b_source;

			when others =>
						sys_bus.exception	<= '1';		-- This is an illegal instruction.
						reg_bus.reg_1_addr	<= (others => 'X');
						reg_bus.reg_2_addr	<= (others => 'X');
						reg_bus.reg_1_rw	<= RW_READ;
						reg_bus.reg_2_rw	<= RW_READ;
						reg_bus.reg_1_en	<= '0';
						reg_bus.reg_2_en	<= '0';
						mem_bus.mem_addr	<= (others => 'X');
						mem_bus.mem_rw		<= RW_READ;
						mem_bus.mem_en		<= '0';
		end case;
	end process;

	------------------------------------------------------------
	--- Logic state machine
	------------------------------------------------------------
	process (sel, state, instruction_reg)
	begin
		if sel = '0'
		then
			state <= LI_IDLE;

		elsif rising_edge(clock)
		then
			case state is
				when  LI_IDLE	=>
						read 	<= '1';
						execute	<= '0';
						write	<= '0';
						state	<= LI_EXECUTE;

				when LI_EXECUTE =>
						read 	<= '1';
						execute	<= '1';
						write	<= '0';
						state	<= LI_WRITE;

				when LI_WRITE =>
						read 	<= '0';
						execute	<= '0';
						write	<= '1';
						state	<= LI_FINISHED;

				when others =>
						read 	<= '0';
						execute	<= '0';
						write	<= '1';
						state	<= LI_FINISHED;
			end case;
		end if;
	end process;

	------------------------------------------------------------
	--- Bus Control Drivers
	------------------------------------------------------------
--	reg_bus.reg_rw <= reg_rw when read = '1' else '0';
--	mem_bus.mem_rw <= mem_rw when read = '1' else '0';

end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker

