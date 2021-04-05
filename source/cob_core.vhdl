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

use work.MemoryInterface;
use work.CPUStateMachine;
use work.ProgramCounter;
use work.OperandRegister;
use work.LoadStoreUnit;
use work.StoreUnit;
use work.GeneralRegisters;
use work.InstructionRegister;

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
	--- Include the registers
	---------------------------------------------------------------
	component ProgramCounter is
		port(
			reset	: in std_logic;
			clock	: in std_logic;
			state	: in CPU_STATE;
			load	: in std_logic;
			address	: in std_logic_vector(ADDR_WIDTH-1 downto 0);

			current	: out std_logic_vector(ADDR_WIDTH-1 downto 0);
			pc		: out std_logic_vector(ADDR_WIDTH-1 downto 0)
		);
	end component ProgramCounter;

	component GeneralRegisters is
		port(
			reset		: in std_logic;
			port_1_bus	: REGISTER_BUS;
			port_2_bus	: REGISTER_BUS;
			data		: inout std_logic_vector(REG_WIDTH-1 downto 0);
			data_2		: out std_logic_vector(REG_WIDTH-1 downto 0)
		);
	end component GeneralRegisters;

	component InstructionRegister is
		port(
			reset			: in std_logic;
			clock			: in std_logic;
			state			: in CPU_STATE;
			pc				: in std_logic_vector(ADDR_WIDTH-1 downto 0);
			data			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			mem_da			: in std_logic;
			mem_bus			: out MEMORY_BUS;								-- memory bus controls
			fetch_complete	: out std_logic;
			unit_sel		: out INSTRUCTION_UNIT_TYPE;
			instruction		: out INSTRUCTION_TYPE
		);
	end component InstructionRegister;
	
	component OperandRegister is
		port (
			reset		: in	std_logic;
			clock		: in	std_logic;
			op_bus		: in	OPERAND_BUS;								-- the control signals.
			cstate		: in	CPU_STATE;
			reg_bus		: out	REGISTER_BUS;								-- the control bus for the register
			reg_data	: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- register data
			reg_da		: in	std_logic;									-- the reg data is available.
			data		: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- data from other sources to load.

			mem_bus		: out	MEMORY_BUS;									-- the memory control bus
			mem_data	: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- memory data
			mem_da		: in	std_logic;									-- mem data available.

			output		: out	std_logic_vector(DATA_WIDTH-1 downto 0);	-- the data from the operand reg.
			complete	: out std_logic										-- execution complete.
		);
	end component OperandRegister;
	
	component StoreUnit is
		port (
			store_bus	: in	STORE_BUS;
			data		: in	std_logic_vector(DATA_WIDTH-1 downto 0);	-- the data to write.

			reg_bus		: out	REGISTER_BUS;								-- the control bus for the register
			reg_data	: out	std_logic_vector(DATA_WIDTH-1 downto 0);	-- register data
			reg_da		: in	std_logic;									-- the reg data is available.

			mem_bus		: out	MEMORY_BUS;									-- the memory control bus
			mem_data	: out	std_logic_vector(DATA_WIDTH-1 downto 0);	-- memory data
			mem_da		: in	std_logic;									-- mem data available.

			complete	: out std_logic										-- execution complete.
		);
	end component StoreUnit;
			
--	component InterruptVectorTable is
--		port(
--				reset			: in std_logic;									-- reset all the registers.
--				load			: in std_logic;									-- load the interrupt.
--				int_id			: INT_ID;										-- the register control bus.
--				data			: inout std_logic_vector(REG_WIDTH-1 downto 0);	-- The data width of the register.
--				data_2			: out std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
--		);
--	end component InterruptVectorTable;

--	component StackRegister is
--		port(
--				reset			: in std_logic;
--				load			: in std_logic;
--				unit_sel		: out INSTRUCTION_UNIT_TYPE;
--				instruction		: out INSTRUCTION_TYPE;
--		);
--	end component StackRegister;

--	component FlagsRegister is
--		port (
--				reset		: in std_logic;
--				load		: in std_logic;
--   			new_flags	: in CPU_FLAGS;
--				flags		: out CPU_FLAGS;
--		);
--	end component FlagsRegister;

	---------------------------------------------------------------
	--- State machine for the CPU
	---------------------------------------------------------------
	component CPUStateMachine is
		port(
			reset				: in	std_logic;
			clock				: in	std_logic;
			fetch_complete		: in	std_logic;
			load_complete		: in	std_logic;
			write_complete		: in	std_logic;
			execute_complete	: in	std_logic;
			state				: inout	CPU_STATE
		);
	end component CPUStateMachine;

	---------------------------------------------------------------
	--- External Interfaces
	---------------------------------------------------------------
	component MemoryInterface is
		port(
			mem_bus			: in	MEMORY_BUS;
			clock			: in	std_logic;
			complete		: out	std_logic;	-- the data has been read and is available,
			data			: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
			mem_dev_da		: in	std_logic;
			mem_dev_rw		: out	std_logic;
			mem_dev_en		: out	std_logic;
			mem_dev_addr	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);
			mem_dev_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component MemoryInterface;

	---------------------------------------------------------------
	--- Execute Components.
	---------------------------------------------------------------
	component IdleUnit is
		port (
			en			: in std_logic;
			state		: in CPU_STATE;
			op_a		: out OPERAND_BUS;
			op_b		: out OPERAND_BUS;
			write		: out STORE_BUS;
			load_comp	: out std_logic;
			complete	: out std_logic
		);
	end component IdleUnit;

	component LoadStoreUnit is
		port (
			en			: in std_logic;			-- enable the idle unit.
			state		: in CPU_STATE;			-- CPU state
			load_comp	: out std_logic;	-- load complete
			complete	: out std_logic;		-- execution complete.
			instruction	: in INSTRUCTION_TYPE;	-- the instruction

			op_a		: out OPERAND_BUS;	-- Operand A bus controls
			op_b		: out OPERAND_BUS;	-- for B
			data		: out std_logic_vector(DATA_WIDTH-1 downto 0);	-- data that needs to goto the operand reg.
		
			write		: out STORE_BUS;		-- controls for writing out the data.

			op_a_da		: in std_logic;
			op_b_da		: in std_logic;
			op_a_data	: in std_logic_vector(DATA_WIDTH-1 downto 0);
			op_b_data	: in std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component LoadStoreUnit;

	---------------------------------------------------------------
	--- now the internal signals.
	---------------------------------------------------------------
	signal store_data_bus	: std_logic_vector(DATA_WIDTH-1 downto 0);	-- connection to the store unit.
	signal op_a_data_bus	: std_logic_vector(DATA_WIDTH-1 downto 0);	-- internal data base
	signal int_data_bus		: std_logic_vector(DATA_WIDTH-1 downto 0);	-- internal data base
	signal int_addr_bus		: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- internal address bus
	signal current_pc		: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- Program counter - current address of the instruction running.
	signal pc_bus			: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- Program counter bus.
	
	signal op_a_bus			: OPERAND_BUS;
	signal op_b_bus			: OPERAND_BUS;
	signal mem_bus			: MEMORY_BUS;
	signal reg_bus			: REGISTER_BUS;
	signal write_bus		: STORE_BUS;

	signal op_a_da			: std_logic;
	signal op_b_da			: std_logic;

	signal reg_1_bus		: REGISTER_BUS;
	signal reg_2_bus		: REGISTER_BUS;
	signal reg_1_data		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal reg_2_data		: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal op_a_data		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal op_b_data		: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal fc				: std_logic;
	signal lc				: std_logic;
	signal wc				: std_logic;
	signal ec				: std_logic	:= '0';

	signal pc_load			: std_logic := '0';

	signal mem_da			: std_logic;
	signal reg_da			: std_logic := '1';		-- TODO: will need this later for pipelining -- a bit previous. :)

	signal state			: CPU_STATE;

	signal instruction		: INSTRUCTION_TYPE;

	signal unit_sel_bus		: INSTRUCTION_UNIT_TYPE;
begin
	---------------------------------------------------------------
	--- State Machine.
	---------------------------------------------------------------
	sm: CPUStateMachine	port map ( reset => reset, clock => clock, fetch_complete => fc, load_complete => lc, write_complete => wc, execute_complete => ec, state => state);

	---------------------------------------------------------------
	--- Register Implementations
	---------------------------------------------------------------
	pc: ProgramCounter		port map (reset => reset, state => state, clock => clock, load => pc_load, address => int_data_bus, current => current_pc, pc => pc_bus);
	ir: InstructionRegister port map (reset => reset, state => state, clock => clock, pc => pc_bus, data => int_data_bus, mem_da => mem_da, mem_bus => mem_bus, fetch_complete => fc, unit_sel => unit_sel_bus, instruction => instruction);

--	st: StackRegister		port map (reset => reset  , load => sk_load, address => int_address_bus, stack => stack_bus);
--	fr: FlagsRegister		port map (reset => reset, load => flags_load, data => int_data_bus, flags => flags_bus);
	rb: GeneralRegisters	port map (reset => reset, port_1_bus => reg_1_bus, port_2_bus => reg_2_bus, data => reg_1_data, data_2 => reg_2_data);

	---------------------------------------------------------------
	--- Execute Components.
	---------------------------------------------------------------
	opr_a:	OperandRegister	port map (reset => reset, clock => clock, op_bus => op_a_bus, cstate => state, reg_bus => reg_1_bus, reg_data => reg_1_data, reg_da => reg_da, data => store_data_bus, mem_bus => mem_bus, mem_data => int_data_bus, mem_da => mem_da, complete => op_a_da, output => op_a_data);
	opr_b:	OperandRegister	port map (reset => reset, clock => clock, op_bus => op_b_bus, cstate => state, reg_bus => reg_2_bus, reg_data => reg_2_data, reg_da => reg_da, data => int_data_bus, mem_bus => mem_bus, mem_data => int_data_bus, mem_da => mem_da, complete => op_b_da, output => op_b_data);
	store:	StoreUnit		port map (store_bus => write_bus, complete => wc,  data => store_data_bus, reg_bus => reg_1_bus, reg_data => reg_1_data, reg_da => reg_da, mem_bus => mem_bus, mem_data => int_data_bus, mem_da => mem_da);

	-- don't let the mem_bus float when not in use.
	mem_bus <= FREE_MEMORY_BUS when write_bus.en = '1' or state = CS_FETCH_DECODE else INIT_MEMORY_BUS;

	-- execute the commands
	iu:	IdleUnit			port map (en => unit_sel_bus.idle, 		state => state, complete => ec, load_comp => lc, op_a => op_a_bus, op_b => op_b_bus, write => write_bus);
	ls: LoadStoreUnit		port map (en => unit_sel_bus.load_store,state => state, complete => ec, load_comp => lc, instruction => instruction, write => write_bus, data => store_data_bus,
										op_a => op_a_bus, op_b => op_b_bus, op_a_da => op_a_da, op_b_da => op_b_da, op_a_data => op_a_data, op_b_data => op_b_data); 

	---------------------------------------------------------------
	--- Interface Components.
	---------------------------------------------------------------
	mi: MemoryInterface		port map ( mem_bus => mem_bus, clock => clock, data => int_data_bus, complete => mem_da, mem_dev_da => da, mem_dev_en => bus_en, mem_dev_rw => bus_rw, mem_dev_addr => bus_address, mem_dev_data => data);

end architecture synth;
--- vi:nocin:sw=4 ts=4:fdm=marker
