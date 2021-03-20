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
use work.ControlUnit;
use work.GeneralRegisters;
use work.LoadStoreUnit;

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

			current	: out std_logic_vector(ADDR_WIDTH-1 downto 0);	-- the current address - stable throughout the operation.
			pc		: out std_logic_vector(ADDR_WIDTH-1 downto 0)	-- the value of the program counter.
		);
	end component ProgramCounter;

	component CPUStateMachine is
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
	end component;

	component BusController is
		port(
			sel				: in std_logic;		-- select the bus controller
			sys_bus			: in SYSTEM_BUS;
			addr_mode_bus	: in ADDRESS_MODE_BUS;
			a_address		: in REG_ID;
			b_address		: in REG_ID;
			destination_reg	: in REG_ID;
			pc_reg			: in std_logic_vector(ADDR_WIDTH-1 downto 0);
			a_op			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			b_op			: in std_logic_vector(DATA_WIDTH-1 downto 0);
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
				op_code		: in 	LOGIC_OP_CODE_TYPE;	-- the op code
				flags		: out	CPU_FLAGS;		-- guess what the flags.
				a_op		: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand A
				b_op		: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand B
				accumulator	: out	std_logic_vector(DATA_WIDTH-1 downto 0)		-- The accumulator  for the results.
		);
	end component LogicUnit;

	component ControlUnit is
		port(
				enable			: in 	std_logic;			-- are we running?
				da				: out	std_logic;			-- data available - the command has completed.
				sys_bus			: in 	SYSTEM_BUS;			-- the system bus controls
				instruction		: in	INSTRUCTION_TYPE;	-- the instruction
				flags			: in	CPU_FLAGS;			-- guess what the flags.
				addr_mode_bus	: out	ADDRESS_MODE_BUS;	-- drive the address bus.
				a_op			: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand A
				pc				: in	std_logic_vector(ADDR_WIDTH-1 downto 0);	-- program counter value
				accumulator		: out	std_logic_vector(DATA_WIDTH-1 downto 0)		-- The accumulator  for the results.
		);
	end component ControlUnit;

	component LoadStoreUnit is
		port(
				enable			: in 	std_logic;				-- are we running?
				da				: out	std_logic;				-- data available - the command has completed.
				sys_bus			: in 	SYSTEM_BUS;				-- the system bus controls
				addr_mode_bus	: out	ADDRESS_MODE_BUS;		-- drive the address bus.
				instruction		: in 	INSTRUCTION_TYPE;		-- the op code
				flags			: out	CPU_FLAGS;		-- guess what the flags.
				a_op			: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand A
				b_op			: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- operand B
				accumulator		: out	std_logic_vector(DATA_WIDTH-1 downto 0)		-- The accumulator  for the results.
		);
	end component LoadStoreUnit;

	component GeneralRegisters is
		port(
				reset			: in std_logic;									-- reset all the registers.
				reg_bus			: REGISTER_BUS;									-- the register control bus.
				data			: inout std_logic_vector(REG_WIDTH-1 downto 0);	-- The data width of the register.
				data_2			: out std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
		);
	end component GeneralRegisters;

	---------------------------------------------------------------
	--- now the internal signals.
	---------------------------------------------------------------

	signal instruction_reg	: INSTRUCTION_TYPE	:= HALT_INSTR;

	-- control signal buses
	signal sys_bus			: SYSTEM_BUS;
	signal mem_bus			: MEMORY_BUS 		:= FREE_MEMORY_BUS;
	signal reg_bus			: REGISTER_BUS		:= FREE_REGISTER_BUS;
    signal addr_mode_bus	: ADDRESS_MODE_BUS	:= INIT_ADDRESS_MODE_BUS;
    signal flags        	: CPU_FLAGS;

	-- component interconnect signals
	signal load_pc		: std_logic := '0';				-- load the program counter from somewhere (TODO)

	signal mode_decode	: std_logic := '0';				-- we have and instructions that requires the data mode decoding.

	signal instruction_complete	: std_logic;	-- the instruction has finished - needs to go into the CSM - TODO.

	-- instruction unit selection
	signal instruction_unit_sel	: INSTRUCTION_UNIT_TYPE;

	-- component interconnect registers.
	signal	reg_data	: std_logic_vector(DATA_WIDTH-1 downto 0)	:= (others => '0');
	signal	reg_data_2	: std_logic_vector(DATA_WIDTH-1 downto 0)	:= (others => '0');
	signal	mem_data	: std_logic_vector(DATA_WIDTH-1 downto 0)	:= (others => '0');
	signal	a_op		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal	b_op		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal	accumulator	: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal int_data		: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal	pc_bus		: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- program counter interconnect.
	signal	current_addr: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- program counter interconnect.

	signal reg_read : std_logic;
	signal reg_write : std_logic;
	signal mem_read : std_logic;
begin

	reg_read  <= (addr_mode_bus.reg_1_en or addr_mode_bus.reg_2_en) when (addr_mode_bus.reg_1_rw = RW_READ and addr_mode_bus.reg_2_rw = RW_READ) else '0';
	reg_write <= (addr_mode_bus.reg_1_en or addr_mode_bus.reg_2_en) when (addr_mode_bus.reg_1_rw = RW_WRITE or addr_mode_bus.reg_2_rw = RW_WRITE)
					else '1' when addr_mode_bus.pc_update = '1'
					else '0';
	mem_read  <= '1' when addr_mode_bus.mem_read = '1' else '0';

	csm: CPUStateMachine port map ( reset => reset, enable => enable, clock => clock, mem_read => mem_read, reg_read => reg_read, reg_write => reg_write, mem_write => addr_mode_bus.mem_write, mem_complete => mem_bus.complete, sys_bus => sys_bus);

	bc: BusController port map (
			sel				=> enable,
			sys_bus			=> sys_bus,
			addr_mode_bus	=> addr_mode_bus,
			a_address		=> instruction_reg(LI_SOURCE_A),
			b_address		=> instruction_reg(LI_SOURCE_B),
			destination_reg	=> instruction_reg(LI_DEST),
			pc_reg			=> pc_bus,
			a_op			=> a_op,
			b_op			=> b_op,
			accumulator		=> accumulator,
			reg_bus			=> reg_bus,
			mem_bus			=> mem_bus,
			reg_data		=> reg_data,
			mem_bus_data	=> mem_data
		);

	load_pc <= '1' when addr_mode_bus.pc_update = '1' and sys_bus.write = '1' else '0';

	pc: ProgramCounter port map (reset => reset, fetch => sys_bus.fetch, load => load_pc, address => accumulator, current => current_addr, pc => pc_bus);

	-- internal registers.
	ir: process (sys_bus.fetch, da, data)
	begin
		if sys_bus.fetch = '1' and da = '1'
		then
			instruction_reg <= data;
		end if;
	end process;

	opra:	OperandRegister port map (enable => opra_enable, mode => opr_mode, reg_bus => reg_bus, mem_bus => mem_bus, reg_data => reg_data, mem_data => mem_data, da => opra_da, value => opra_data);
	oprb:	OperandRegister port map (enable => oprb_enable, mode => opr_mode, reg_bus => reg_bus, mem_bus => mem_bus, reg_data => reg_data, mem_data => mem_data, da => oprb_da, value => oprb_data);

	-- unit selection - which is the active processing unit.
	us: process (reset, instruction_reg, sys_bus.fetch)
	begin
		if sys_bus.fetch = '0' and reset = '0'
		then
			case instruction_reg(INSTR_UNIT_RANGE) is
				when IU_LOGIC		=> instruction_unit_sel <= IU_LOGIC_SEL;
				when IU_CONTROL		=> instruction_unit_sel	<= IU_CONTROL_SEL;
				when IU_ARITH		=> instruction_unit_sel	<= IU_ARITH_SEL;
				when IU_LOAD_STORE	=> instruction_unit_sel <= IU_LOAD_STORE_SEL;
				when IU_SYSTEM 		=> instruction_unit_sel <= IU_SYSTEM_SEL;
				when others			=> instruction_unit_sel <= IU_IDLE;
			end case;
		else
			instruction_unit_sel <= IU_IDLE;
		end if;
	end process;

	-- general register bank.
	rb: GeneralRegisters port map (reset => reset, reg_bus => reg_bus, data => reg_data, data_2 => reg_data_2);

	-- instruction units
	iu_logic:	LogicUnit		port map (enable=>instruction_unit_sel.logic,   da=>instruction_complete, sys_bus=>sys_bus, instruction=>instruction_reg, flags=>flags, addr_mode_bus=>addr_mode_bus, a_op=>a_op, b_op=>b_op,
											accumulator=>accumulator);

	cu: 		ControlUnit 	port map (enable=>instruction_unit_sel.control, da=>instruction_complete, sys_bus=>sys_bus, instruction=>instruction_reg, flags=>flags, addr_mode_bus=>addr_mode_bus, a_op=>a_op, pc=>current_addr,
											accumulator=>accumulator);

	ls: 		LoadStoreUnit 	port map (enable=>instruction_unit_sel.control, da=>instruction_complete, sys_bus=>sys_bus, instruction=>instruction_reg, flags=>flags, addr_mode_bus=>addr_mode_bus, a_op=>a_op, b_op=>b_op, 
											accumulator=>accumulator);

	-- memory bus control
	mu: MemoryUnit	port map (	en => sys_bus.wait_read or sys_bus.wait_write or sys_bus.fetch, clock => clock, rw => sys_bus.wait_write, complete => mem_bus.complete, address => mem_bus.addr, data => int_data,
								mem_dev_da => da, mem_dev_en => bus_en, mem_dev_rw => bus_rw, mem_dev_addr => bus_address, mem_dev_data => data);

end architecture synth;
--- vi:nocin:sw=4 ts=4:fdm=marker
