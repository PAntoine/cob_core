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

use work.AddressModeDecoder;

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
			mem_bus			: inout MEMORY_BUS;
			mem_bus_data	: inout std_logic_vector(DATA_WIDTH-1 downto 0)
		);
end LogicDecoder;

architecture synth of LogicDecoder is

		---------------------------------------------------------------
	--- Include the components
	---------------------------------------------------------------
	component AddressModeDecoder is
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
	end component;

	---------------------------------------------------------------
	--- The connecting signals
	---------------------------------------------------------------
    signal op_code : std_logic_vector(INSTR_OPCODE_RANGE);

	signal accumulator 	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal a_reg		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal b_reg		: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal 		state			: std_logic_vector(2 downto 0);
	constant	LI_IDLE			: std_logic_vector(2 downto 0) := "000";
	constant	LI_EXECUTE		: std_logic_vector(2 downto 0) := "001";
	constant	LI_WRITE		: std_logic_vector(2 downto 0) := "010";
	constant	LI_FINISHED		: std_logic_vector(2 downto 0) := "011";
	constant	LI_READ_WAIT	: std_logic_vector(2 downto 0) := "100";
	constant	LI_WRITE_WAIT	: std_logic_vector(2 downto 0) := "101";

	signal read		: std_logic;
	signal execute	: std_logic;
	signal write	: std_logic;
			
	signal write_reg_bus	: REGISTER_BUS;
	signal reg_1_rw			: std_logic;
	signal reg_2_rw			: std_logic;
	signal reg_1_en			: std_logic;
	signal reg_2_en			: std_logic;

	signal immediate_8		: std_logic;

	signal wait_read		: std_logic;
	signal wait_write		: std_logic;

	signal mem_read_a		: std_logic;
	signal mem_read			: std_logic;
	signal mem_write		: std_logic;
	signal mem_addr			: std_logic_vector(ADDR_WIDTH-1 downto 0);

begin
	------------------------------------------------------------
	--- Logic Instruction Decoder
	------------------------------------------------------------
	process (sel, clock, execute, write, a_reg, b_reg, instruction_reg) is
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
				when LI_ROR	=> accumulator <= RotateRight(a_reg, b_reg(4 downto 0));
				when LI_ROL	=> accumulator <= RotateLeft(a_reg, b_reg(4 downto 0));
				when others	=> accumulator <= (others => '0');
			end case;
		end if;
	end process;
	
	------------------------------------------------------------
	--- Set he flags register.
	------------------------------------------------------------
	flags.zero_flag <= 'Z' when sel = '0' else
	                   '1' when accumulator = ZEROS
	                   else '0';

    flags.sign_flag <=  'Z' when sel = '0' else
                        '1' when accumulator(31) = '1'
                        else '0';
	
	-- don't user this, but should be set.
	flags.carry_flag <= '0' when sel = '1' else 'Z';

	-- non of these flags are set in this block.
	flags.interrupt_flag		<= 'Z';
	flags.hardware_interrupt	<= 'Z';
	flags.interrupt_waiting		<= 'Z';
	flags.interrupts_masked		<= 'Z';
	flags.non_masked_interrupt	<= 'Z';

	------------------------------------------------------------
	--- Decode Instruction Input
	---
	--- This handles the read (load) part of the logical
	--- instructions.
	------------------------------------------------------------
	amd: AddressModeDecoder port map (	sel				=> sel,
										mode			=> instruction_reg(LI_IO_CODE),
										reg_1_rw		=> reg_1_rw,
										reg_1_en		=> reg_1_en,
										reg_2_rw		=> reg_2_rw,
										reg_2_en		=> reg_2_en,
										mem_read		=> mem_read,
										mem_write		=> mem_write,
										mem_read_a		=> mem_read_a,
										immediate_8 	=> immediate_8,
										exception_flag	=> flags.exception_flag);

	------------------------------------------------------------
	--- Logic state machine
	------------------------------------------------------------
	process (sel, state, clock)
	begin
		if sel = '0'
		then
			state 		<= LI_IDLE;
			read 		<= '0';
			wait_read	<= '0';
			execute		<= '0';
			write		<= '0';
			wait_write	<= '0';

		elsif rising_edge(clock)
		then
			case state is
				when  LI_IDLE	=>
						read		<= '1';
						execute		<= '0';
						write		<= '0';
						wait_read	<= '0';

						if mem_read = '0'
						then
							state	<= LI_EXECUTE;
						else
							state	<= LI_READ_WAIT;		-- wait state while waiting for the memory device to do it's work.
						end if;

				when LI_READ_WAIT =>
						read		<= '0';
						execute		<= '0';
						write		<= '0';
						wait_read	<= '1';
						if mem_bus.complete = '1'
						then
							state	<= LI_EXECUTE;
						end if;

				when LI_EXECUTE =>
						read		<= '0';
						execute		<= '1';
						write		<= '0';
						wait_read	<= '0';
						state	<= LI_WRITE;

				when LI_WRITE =>
						read		<= '0';
						execute		<= '0';
						write		<= '1';
						wait_read	<= '0';
						if mem_write = '0'
						then
							state	<= LI_WRITE_WAIT;		-- wait until the memory device completes it's write.
						else
							state	<= LI_FINISHED;
						end if;
				
				when LI_WRITE_WAIT =>
						read		<= '0';
						execute		<= '0';
						write		<= '0';
						wait_read	<= '1';
						if mem_bus.complete = '1'
						then
							state	<= LI_FINISHED;
						end if;
				
				when others =>
						read		<= '0';
						execute		<= '0';
						write		<= '0';
						wait_read	<= '0';
						state		<= LI_FINISHED;
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
	process (read, write, mem_read, execute, reg_1_rw, reg_1_en, reg_2_rw, reg_2_en, wait_read, wait_write, mem_read_a, a_reg, b_reg, mem_read, accumulator)
	begin
		if read = '1' or execute = '1'
		then
			reg_bus.reg_1_addr	<= instruction_reg(LI_SOURCE_A);
			reg_bus.reg_2_addr	<= instruction_reg(LI_SOURCE_B);
			reg_bus.reg_1_rw	<= reg_1_rw;
			reg_bus.reg_2_rw	<= reg_2_rw;
			reg_bus.reg_1_en	<= reg_1_en;
			reg_bus.reg_2_en	<= reg_2_en;
			reg_data			<= (others => 'Z');
			reg_data2			<= (others => 'Z');
			mem_bus				<= FREE_MEMORY_BUS;

		elsif wait_read = '1'
		then
			reg_bus				<= FREE_REGISTER_BUS;
			mem_bus_data		<= (others => 'Z');
			if mem_read_a = '1'
			then
				mem_bus.addr	<= a_reg;
			else
				mem_bus.addr	<= b_reg;
			end if;
			mem_bus.rw			<= RW_READ;
			mem_bus.en			<= '1';		-- start the memory read.

		elsif write = '1'
		then
			reg_bus.reg_1_addr	<= instruction_reg(LI_DEST);
			reg_bus.reg_2_addr	<= instruction_reg(LI_SOURCE_B);
			reg_bus.reg_1_rw	<= RW_WRITE;		-- TODO: hack - the state machine is wrong.
			reg_bus.reg_2_rw	<= reg_2_rw;
			reg_bus.reg_1_en	<= reg_1_en;
			reg_bus.reg_2_en	<= reg_2_en;
			reg_data 			<= accumulator;
			reg_data2 			<= (others => 'Z');
			mem_bus				<= FREE_MEMORY_BUS;
		
		elsif wait_write = '1'
		then
			reg_bus				<= FREE_REGISTER_BUS;
			mem_bus.addr		<= mem_addr;
			mem_bus_data		<= accumulator;
			mem_bus.rw			<= RW_WRITE;
			mem_bus.en			<= '1';		-- start memory write
		
		else
			reg_data 			<= (others => 'Z');
			reg_data2 			<= (others => 'Z');
			reg_bus				<= FREE_REGISTER_BUS;
			mem_bus				<= FREE_MEMORY_BUS;
		end if;
	end process;
		
	-- load a and b internal registers.
	process (mem_bus, read, mem_bus.complete, mem_read_a, reg_bus, clock, reg_data)
	begin
		if falling_edge(clock)
		then
 			if read = '0' and mem_read = '1' and mem_bus.complete = '1' and mem_read_a = '1'
 			then
				a_reg <= mem_bus_data;
			
			elsif read = '1' and reg_bus.reg_1_en = '1' and reg_bus.reg_1_rw = RW_READ
			then
				a_reg <= reg_data;
			end if;
		end if;
	end process;
	
	process (mem_bus, read, mem_bus.complete, mem_read_a, reg_bus, clock, reg_data2)
	begin
		if falling_edge(clock)
		then
			if immediate_8 = '1'
			then
				b_reg <= ZEROS(DATA_WIDTH-1 downto 8) & instruction_reg(LI_IMM8);
				
 			elsif read = '0' and mem_read = '1' and mem_bus.complete = '1' and mem_read_a = '0'
			then
				b_reg <= mem_bus_data;
			
			elsif read = '1' and reg_bus.reg_2_en = '1' and reg_bus.reg_2_rw = RW_READ
			then	
				b_reg <= reg_data2;
			end if;
		end if;
	end process;


end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
