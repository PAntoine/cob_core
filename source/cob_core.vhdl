-----------------------------------------------------------------------------------
--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--					
--
-- Name  : cob_core
-- Desc  : The COB Core processor.
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
use work.instructions.all;

use work.MemoryUnit;
use work.BusController;
use work.ProgramCounter;
use work.CPUStateMachine;
use work.LogicUnit;

entity COB_Core is
		port(
				reset			: in std_logic;		-- reset all the registers.
				enable			: in std_logic;		-- enable the processor.
				clock			: in std_logic;		-- the external system clock.
				
				as				: out std_logic;	-- address strobe
				ds				: out std_logic;	-- data strobe
				bus_en			: out std_logic;	-- bus enable.
				bus_rw			: out std_logic;	-- set the read/write flag
				bus_address		: out std_logic_vector(ADDR_WIDTH-1 downto 0);	-- the address selected.
				da				: in std_logic;									-- data acknowledge - when external data is ready.
	-- rtl_synthesis off
				test_port		: out std_logic_vector(DATA_WIDTH-1 downto 0);	-- test port for 
	-- rtl_synthesis on
				data			: inout std_logic_vector(DATA_WIDTH-1 downto 0)	-- The data width of the register.
		);
end COB_Core ;

architecture synth of COB_Core is
	---------------------------------------------------------------
	--- Include the components
	---------------------------------------------------------------
	component ProgramCounter is
		port(
			reset	: in std_logic;									-- reset the program counter to the default address.
			fetch	: in std_logic;									-- the CPU signal that the next instruction is to be fetched.
			load	: in std_logic;									-- the counter is being loaded with an address.
			address	: in std_logic_vector(ADDR_WIDTH-1 downto 0);	-- the address to be loaded in the program counter.

			pc		: out std_logic_vector(ADDR_WIDTH-1 downto 0)	-- the value of the program counter.
		);
	end component ProgramCounter;

	component CPUStateMachine is
		port(
			reset			: in std_logic;
			enable			: in std_logic;
			clock			: in std_logic;
			mem_read		: in std_logic;
			mem_write		: in std_logic;
			mem_complete	: in std_logic;
			sys_bus			: out SYSTEM_BUS
		);
	end component;

	component BusController is
		port(
			sel				: in std_logic;		-- select the bus controller
			sys_bus			: in SYSTEM_BUS;
			reg_1_rw		: in std_logic;
			reg_1_en		: in std_logic;
			reg_2_rw		: in std_logic;
			reg_2_en		: in std_logic;
			mem_read_a		: in std_logic;		-- read into internal reg a or b.
			a_address		: in REG_ID;
			b_address		: in REG_ID;
			destination_reg	: in REG_ID;
			pc_reg			: in std_logic_vector(ADDR_WIDTH-1 downto 0);
			a_reg			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			b_reg			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			accumulator		: in std_logic_vector(DATA_WIDTH-1 downto 0);
			reg_bus			: out REGISTER_BUS;
			mem_bus			: out MEMORY_BUS;
			reg_data		: out std_logic_vector(DATA_WIDTH-1 downto 0);
			mem_bus_data	: out std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component BusController;

	component MemoryUnit is
		port(
			en				: in	std_logic;
			clock			: in	std_logic;
			rw				: in	std_logic;
			complete		: out	std_logic;
			address			: in 	std_logic_vector(ADDR_WIDTH-1 downto 0);
			data			: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
			mem_dev_da		: in	std_logic;
			mem_dev_rw		: out	std_logic;
			mem_dev_en		: out	std_logic;
			mem_dev_addr	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);
			mem_dev_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component MemoryUnit;

	component LogicUnit is
		port(
				enable		: in 	std_logic;		-- are we running?
				da			: out	std_logic;		-- data available - the command has completed.
				sys_bus		: in	SYSTEM_BUS;		-- the system bus controls
				op_code		: in 	OP_CODE_TYPE;	-- the op code
				flags		: out	CPU_FLAGS;		-- guess what the flags.
				a_op		: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand A
				b_op		: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand B
				accumulator	: out	std_logic_vector(DATA_WIDTH-1 downto 0)		-- The accumulator  for the results.
		);
	end component LogicUnit;

	---------------------------------------------------------------
	--- now the internal signals.
	---------------------------------------------------------------
	
	signal instruction_reg	: INSTRUCTION_TYPE	:= HALT_INSTR;
	
	-- control signal buses
	signal sys_bus		: SYSTEM_BUS;
	signal mem_bus		: MEMORY_BUS 	:= FREE_MEMORY_BUS;
	signal reg_bus		: REGISTER_BUS	:= FREE_REGISTER_BUS;
    signal flags        : CPU_FLAGS;

	-- component interconnect signals
	signal reg_1_rw		: std_logic;
	signal reg_1_en		: std_logic;
	signal reg_2_rw		: std_logic;
	signal reg_2_en		: std_logic;
	
	signal mem_read		: std_logic	:= '0';
	signal mem_read_a	: std_logic := '0';
	signal mem_write	: std_logic := '0';

	signal load_pc		: std_logic := '0';		-- load the program counter from somewhere (TODO)
	
	signal instruction_complete	: std_logic;	-- the instruction has finished - needs to go into the CSM - TODO.

	-- instruction unit selection
	signal instruction_unit_sel	: INSTRUCTION_UNIT_TYPE;

	-- component interconnect registers.
	signal	reg_data	: std_logic_vector(DATA_WIDTH-1 downto 0)	:= (others => '0');
	signal	reg_data_2	: std_logic_vector(DATA_WIDTH-1 downto 0)	:= (others => '0');
	signal	mem_data	: std_logic_vector(DATA_WIDTH-1 downto 0)	:= (others => '0');
	signal	a_reg		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal	b_reg		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal	accumulator	: std_logic_vector(DATA_WIDTH-1 downto 0);
	
	signal int_data		: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal	pc_bus		: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- program counter interconnect.
begin
	csm: CPUStateMachine port map ( reset => reset, enable => enable, clock => clock, mem_read => mem_read, mem_write => mem_write, mem_complete => mem_bus.complete, sys_bus => sys_bus);

	bc: BusController port map (
			sel				=> enable,
			sys_bus			=> sys_bus,
			reg_1_rw		=> reg_1_rw,
			reg_1_en		=> reg_1_en,
			reg_2_rw		=> reg_1_rw,
			reg_2_en		=> reg_1_en,
			mem_read_a		=> mem_read_a,
			a_address		=> instruction_reg(LI_SOURCE_A),
			b_address		=> instruction_reg(LI_SOURCE_B),
			destination_reg	=> instruction_reg(LI_DEST),
			pc_reg			=> pc_bus,
			a_reg			=> a_reg,
			b_reg			=> b_reg,
			accumulator		=> accumulator,
			reg_bus			=> reg_bus,
			mem_bus			=> mem_bus,
			reg_data		=> reg_data,
			mem_bus_data	=> mem_data
		);

	pc: ProgramCounter port map (reset => reset, fetch => sys_bus.fetch, load => load_pc, address => mem_bus.addr, pc => pc_bus);
	
	ir: process (sys_bus.fetch, da)
	begin
		if sys_bus.fetch = '1' and da = '1'
		then
			instruction_reg <= data;
		end if;
	end process;

	-- unit selection - which is the active processing unit.
	us: process (instruction_reg, sys_bus.fetch)
	begin
		if sys_bus.fetch = '0' and reset = '0'
		then
			case instruction_reg(INSTR_UNIT_RANGE) is
				when IU_LOGIC	=> instruction_unit_sel <= IU_LOGIC_SEL;
				when IU_CONTROL	=> instruction_unit_sel <= IU_CONTROL_SEL;
				when IU_ARITH	=> instruction_unit_sel <= IU_ARITH_SEL;
				when IU_MEMORY	=> instruction_unit_sel <= IU_MEMORY_SEL;
				when others		=> instruction_unit_sel <= IU_IDLE;
			end case;
		else
			instruction_unit_sel <= IU_IDLE;
		end if;
	end process;

	-- instruction units
	iu_logic:	LogicUnit	port map (	enable=>instruction_unit_sel.logic,
										da=>instruction_complete,
										sys_bus=>sys_bus,
										op_code=>instruction_reg(INSTR_OPCODE_RANGE),
										flags=>flags,
										a_op=>a_reg,
										b_op=>b_reg,
										accumulator=>accumulator);

	-- memory bus control
	mu: MemoryUnit	port map (	en => sys_bus.wait_read or sys_bus.wait_write or sys_bus.fetch, clock => clock, rw => sys_bus.wait_write, complete => mem_bus.complete, address => mem_bus.addr, data => int_data,
								mem_dev_da => da, mem_dev_en => bus_en, mem_dev_rw => bus_rw, mem_dev_addr => bus_address, mem_dev_data => data);

end architecture synth;
--- vi:nocin:sw=4 ts=4:fdm=marker
