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
use work.CPUStateMachine;

entity LogicDecoder is
		port(
			sel				: in std_logic;
			clock           : in std_logic;
			instruction_reg	: in INSTRUCTION_TYPE;
			data_available	: out std_logic;
			flags			: out CPU_FLAGS;
			sys_bus			: inout SYSTEM_BUS;
			reg_bus			: inout REGISTER_BUS;
			reg_data		: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
			reg_data2		: in	std_logic_vector(DATA_WIDTH-1 downto 0);
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

	component CPUStateMachine is
		port(
			reset			: in std_logic;
			enable			: in std_logic;
			clock			: in std_logic;
			mem_read		: in std_logic;
			mem_write		: in std_logic;
			mem_complete	: in std_logic;
			read			: out std_logic;
			wait_read		: out std_logic;
			execute			: out std_logic;
			write			: out std_logic;
			wait_write		: out std_logic
		);
	end component;

	component BusController is
		port(
			sel				: in std_logic;		-- select the bus controller
			read			: in std_logic;		-- 
			write			: in std_logic;
			execute			: in std_logic;
			mem_read		: in std_logic;
			mem_read_a		: in std_logic;
			wait_read		: in std_logic;
			wait_write		: in std_logic;
			reg_1_rw		: in std_logic;
			reg_1_en		: in std_logic;
			reg_2_rw		: in std_logic;
			reg_2_en		: in std_logic;
			a_address		: in REG_ID;
			b_address		: in REG_ID;
			destination_reg	: in REG_ID;
			a_reg			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			b_reg			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			accumulator		: in std_logic_vector(DATA_WIDTH-1 downto 0);
			reg_bus			: out REGISTER_BUS;
			mem_bus			: out MEMORY_BUS;
			reg_data		: out std_logic_vector(DATA_WIDTH-1 downto 0);
			mem_bus_data	: out std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component BusController;

	---------------------------------------------------------------
	--- The connecting signals
	---------------------------------------------------------------
    signal op_code : std_logic_vector(INSTR_OPCODE_RANGE);

	signal accumulator 	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal a_reg		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal b_reg		: std_logic_vector(DATA_WIDTH-1 downto 0);

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
		if sel ='1' and (execute = '1' or write = '1')
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
		else
			accumulator <= (others => 'Z');
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
	--- Output Driver
	------------------------------------------------------------
	process (write, wait_write, clock)
	begin
		if write = '0' and wait_write = '0'
		then
			data_available	<= '0';

		elsif falling_edge(clock)
		then
			data_available <= '1';
		end if;
	end process;

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
	csm: CPUStateMachine port map ( reset			=> '0',
									enable			=> sel,
									clock			=> clock,
									mem_read		=> mem_read,
									mem_write		=> mem_write,
									mem_complete	=> mem_bus.complete,
									read			=> read,
									wait_read		=> wait_read,
									execute			=> execute,
									write			=> write,
									wait_write		=> wait_write);

	------------------------------------------------------------
	--- Bus Control Drivers
	------------------------------------------------------------
	bc: BusController port map (
			sel				=> sel,			-- select the bus controller
			read			=> read,		-- 
			write			=> write,
			execute			=> execute,
			mem_read		=> mem_read,
			mem_read_a		=> mem_read_a,
			wait_read		=> wait_read,
			wait_write		=> wait_write,
			reg_1_rw		=> reg_1_rw,
			reg_1_en		=> reg_1_en,
			reg_2_rw		=> reg_1_rw,
			reg_2_en		=> reg_1_en,
			a_address		=> instruction_reg(LI_SOURCE_A),
			b_address		=> instruction_reg(LI_SOURCE_B),
			destination_reg	=> instruction_reg(LI_DEST),
			a_reg			=> a_reg,
			b_reg			=> b_reg,
			accumulator		=> accumulator,
			reg_bus			=> reg_bus,
			mem_bus			=> mem_bus,
			reg_data		=> reg_data,
			mem_bus_data	=> mem_bus_data
		);
		
	-- load a and b internal registers.
	process (mem_bus, read, mem_bus.complete, mem_read_a, reg_bus, clock, reg_data)
	begin
		if falling_edge(clock)
		then
 			if read = '0' and mem_read = '1' and mem_bus.complete = '1' and mem_read_a = '1'
 			then
				a_reg <= mem_bus_data;
			
			elsif read = '1' and reg_1_en = '1' and reg_1_rw = RW_READ
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
			
			elsif read = '1' and reg_2_en = '1' and reg_2_rw = RW_READ
			then	
				b_reg <= reg_data2;
			end if;
		end if;
	end process;


end architecture synth;

--- vi:nocin:sw=4 ts=4:fdm=marker
