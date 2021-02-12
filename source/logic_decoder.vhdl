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
			instruction_reg	: in INSTRUCTION_TYPE;
			data_available	: out std_logic;
			flags			: out CPU_FLAGS;
			sys_bus			: inout SYSTEM_BUS;
			reg_bus			: inout REGISTER_BUS;
			reg_data		: inout	std_logic_vector(31 downto 0);
			reg_data2		: inout	std_logic_vector(31 downto 0);
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

	signal 		state		: std_logic_vector(1 downto 0);
	constant	LI_IDLE		: std_logic_vector(1 downto 0) := "00";
	constant	LI_EXECUTE	: std_logic_vector(1 downto 0) := "01";
	constant	LI_WRITE	: std_logic_vector(1 downto 0) := "10";
	constant	LI_FINISHED	: std_logic_vector(1 downto 0) := "11";

	signal read		: std_logic;
	signal execute	: std_logic;
	signal write	: std_logic;
			
	signal write_reg_bus	: REGISTER_BUS;
	signal reg_1_addr		: REG_ID;
	signal reg_2_addr		: REG_ID;
	signal reg_1_rw			: std_logic;
	signal reg_2_rw			: std_logic;
	signal reg_1_en			: std_logic;
	signal reg_2_en			: std_logic;

	signal test : std_logic_vector(2 downto 0);

	signal bus_control	: LOGIC_BUS;
begin
	------------------------------------------------------------
	--- Logic Instruction Decoder
	------------------------------------------------------------
	process (sel, clock, execute, a_reg, b_reg, instruction_reg) is
	begin
		if sel = '0'
		then
			accumulator <= (others => '0');

		elsif sel ='1' and (execute = '1' or write = '1')
		then
			case instruction_reg(INSTR_OPCODE_RANGE) is
				when LI_LSL => accumulator <= LogicalShiftLeft(a_reg, b_reg(4 downto 0));
				when LI_LSR => accumulator <= LogicalShiftRight(a_reg, b_reg(4 downto 0));
				when LI_AND	=> accumulator <= a_reg and b_reg;
				when LI_OR	=> accumulator <= a_reg or b_reg;
				when LI_XOR	=> accumulator <= a_reg xor b_reg;
				when LI_NOT	=> accumulator <= not a_reg;
				--when LI_NEG	=> accumulator <= (not a_reg) + 1;
				when LI_ROR	=> accumulator <= LogicalShiftRight(a_reg, b_reg(4 downto 0));
				when LI_ROL	=> accumulator <= LogicalShiftRight(a_reg, b_reg(4 downto 0));
				when others	=> accumulator <= (others => '0');
			end case;
		end if;
	end process;

	------------------------------------------------------------
	--- Decode Instruction Input
	---
	--- This handles the read (load) part of the logical
	--- instructions.
	------------------------------------------------------------
	a_source	<= instruction_reg(LI_SOURCE_A);
	b_source	<= instruction_reg(LI_SOURCE_B);
	
	test <= instruction_reg(LI_IO_CODE);

	process (sel, instruction_reg, a_reg, b_reg, a_source, b_source) is
	begin
		if (sel = '0')
		then
			reg_1_addr	<= (others => 'Z');
			reg_2_addr	<= (others => 'Z');
			reg_1_rw	<= 'Z';
			reg_2_rw	<= 'Z';
			reg_1_en	<= 'Z';
			reg_2_en	<= 'Z';
			mem_bus.mem_addr	<= (others => 'Z');
			mem_bus.mem_rw		<= 'Z';
			mem_bus.mem_en		<= 'Z';

		else
			case instruction_reg(LI_IO_CODE) is
				when "000" =>
							-- reg in for a and b,
							reg_1_addr	<= a_source;
							reg_2_addr	<= b_source;
							reg_1_rw	<= RW_READ;
							reg_2_rw	<= RW_READ;
							reg_1_en	<= '1';
							reg_2_en	<= '1';
							mem_bus.mem_addr	<= (others => 'X');
							mem_bus.mem_rw		<= RW_READ;
							mem_bus.mem_en		<= '0';
							
				when "001" =>
							-- mem read for a, and reg red for b.
							reg_1_addr	<= (others => 'X');
							reg_2_addr	<= b_source;
							reg_1_rw	<= RW_READ;
							reg_2_rw	<= RW_READ;
							reg_1_en	<= '1';
							reg_2_en	<= '0';
							mem_bus.mem_addr	<= a_reg;
							mem_bus.mem_rw		<= RW_READ;
							mem_bus.mem_en		<= '1';
							
				when "010" =>
							-- source a reg, source b mem. 
							reg_1_addr	<= a_source;
							reg_2_addr	<= (others => 'X');
							reg_1_rw	<= RW_READ;
							reg_2_rw	<= RW_READ;
							reg_1_en	<= '0';
							reg_2_en	<= '1';
							mem_bus.mem_addr	<= b_reg;
							mem_bus.mem_rw		<= RW_READ;
							mem_bus.mem_en		<= '1';

				when "011" =>
							-- Only reg a.
							reg_1_addr	<= a_source;
							reg_2_addr	<= (others => 'X');
							reg_1_rw	<= RW_READ;
							reg_2_rw	<= RW_READ;
							reg_1_en	<= '1';
							reg_2_en	<= '0';
							mem_bus.mem_addr	<= (others => 'X');
							mem_bus.mem_rw		<= RW_READ;
							mem_bus.mem_en		<= '0';

				when "100" =>
							-- mem read for a, immediate for b.
							reg_1_addr	<= a_source;
							reg_2_addr	<= (others => 'X');
							reg_1_rw	<= RW_READ;
							reg_2_rw	<= RW_READ;
							reg_1_en	<= '1';
							reg_2_en	<= '0';
							mem_bus.mem_addr	<= (others => 'X');
							mem_bus.mem_rw		<= RW_READ;
							mem_bus.mem_en		<= '0';

				when others =>
							--sys_bus.exception	<= '1';		-- This is an illegal instruction.
							flags.exception_flag		<= '1';
							mem_bus.mem_addr	<= (others => 'X');
							mem_bus.mem_rw		<= RW_READ;
							mem_bus.mem_en		<= '0';
			end case;
		end if;
	end process;

	------------------------------------------------------------
	--- Logic state machine
	------------------------------------------------------------
	process (sel, state, clock)
	begin
		if sel = '0'
		then
			state <= LI_IDLE;
			read 	<= '0';
			execute	<= '0';
			write	<= '0';

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
						write	<= '0';
						state	<= LI_FINISHED;
			end case;
		end if;
	end process;
	
	------------------------------------------------------------
	--- Output Driver
	------------------------------------------------------------
	process (write, clock)
	begin
		if write = '0'
		then
			data_available	<= '0';

		elsif falling_edge(clock) and write = '1'
		then
			data_available <= '1';
		end if;
	end process;

	------------------------------------------------------------
	--- Bus Control Drivers
	------------------------------------------------------------
	process (read, execute)
	begin
		if read = '1' or execute = '1'
		then
			reg_bus.reg_1_addr	<= reg_1_addr;
			reg_bus.reg_2_addr	<= reg_2_addr;
			reg_bus.reg_1_rw	<= reg_1_rw;
			reg_bus.reg_2_rw	<= reg_2_rw;
			reg_bus.reg_1_en	<= reg_1_en;
			reg_bus.reg_2_en	<= reg_2_en;
			reg_data			<= (others => 'Z');
			reg_data2			<= (others => 'Z');

		elsif write = '1'
		then
			reg_bus.reg_1_addr	<= instruction_reg(LI_DEST);
			reg_bus.reg_2_addr	<= reg_2_addr;
			reg_bus.reg_1_rw	<= RW_WRITE;		-- TODO: hack - the state machine is wrong.
			reg_bus.reg_2_rw	<= reg_2_rw;
			reg_bus.reg_1_en	<= reg_1_en;
			reg_bus.reg_2_en	<= reg_2_en;
			reg_data 			<= accumulator;
			reg_data2 			<= (others => 'Z');
		else

			reg_bus.reg_1_addr	<= (others => 'Z');
			reg_bus.reg_2_addr	<= (others => 'Z');
			reg_bus.reg_1_rw	<= 'Z';
			reg_bus.reg_2_rw	<= 'Z';
			reg_bus.reg_1_en	<= 'Z';
			reg_bus.reg_2_en	<= 'Z';
			reg_data 			<= (others => 'Z');
			reg_data2 			<= (others => 'Z');
		end if;
	end process;
		
	-- read in register a
	process (reg_bus, clock, read, reg_data)
	begin
		if falling_edge(clock) and read = '1' and reg_bus.reg_1_rw = '0' and reg_bus.reg_1_en = '1'
		then
			a_reg <= reg_data;
		end if;
	end process;
	
	-- read in register b
	process (reg_bus, clock, read, reg_data2)
	begin
		if falling_edge(clock) and read = '1' and reg_bus.reg_2_rw = '0' and reg_bus.reg_2_en = '1'
		then
			b_reg <= reg_data2;
		end if;
	end process;

end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
