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
-- use work.GeneralRegisters;
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

--	component GeneralRegisters is
--		port(
--			reset	: in std_logic;
--			reg_bus	: REGISTER_BUS;
--			data	: inout std_logic_vector(REG_WIDTH-1 downto 0);
--			data_2	: out std_logic_vector(REG_WIDTH-1 downto 0)
--		);
--	end component GeneralRegisters;

	component InstructionRegister is
		port(
			reset			: in std_logic;
			state			: in CPU_STATE;
			pc				: in std_logic_vector(ADDR_WIDTH-1 downto 0);
			data			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			mem_da			: in std_logic;

			mem_en			: out std_logic;
			mem_rw			: out std_logic;
			address			: out std_logic_vector(ADDR_WIDTH-1 downto 0);
			fetch_complete	: out std_logic;
			unit_sel		: out INSTRUCTION_UNIT_TYPE;
			instruction		: out INSTRUCTION_TYPE
		);
	end component InstructionRegister;

--	component InterruptVectorTable is
--		port(
--				reset			: in std_logic;									-- reset all the registers.
--				load			: in std_logic;									-- load the interrupt.
--				int_id			: INT_ID;										-- the register control bus.
--				data			: inout std_logic_vector(REG_WIDTH-1 downto 0);	-- The data width of the register.
--				data_2			: out std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
--		);
--	end component GeneralRegisters;

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
			state				: out	CPU_STATE
		);
	end component CPUStateMachine;

	---------------------------------------------------------------
	--- External Interfaces
	---------------------------------------------------------------
	component MemoryInterface is
		port(
			en				: in	std_logic;
			clock			: in	std_logic;
			rw				: in	std_logic;
			complete		: out	std_logic;
			address			: in	std_logic_vector(ADDR_WIDTH-1 downto 0);
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
			complete	: out std_logic
		);
	end component IdleUnit;

	---------------------------------------------------------------
	--- now the internal signals.
	---------------------------------------------------------------
	signal int_data_bus	: std_logic_vector(DATA_WIDTH-1 downto 0);	-- internal data base
	signal int_addr_bus	: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- internal address bus
	signal current_pc	: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- Program counter - current address of the instruction running.
	signal pc_bus		: std_logic_vector(ADDR_WIDTH-1 downto 0);	-- Program counter bus.
	
	signal mem_en		: std_logic;
	signal mem_rw		: std_logic;
	signal mem_da		: std_logic;

	signal fc			: std_logic;
	signal lc			: std_logic;
	signal wc			: std_logic	:= '0';
	signal ec			: std_logic	:= '0';

	signal pc_load		: std_logic;

	signal state		: CPU_STATE;

	signal instruction	: INSTRUCTION_TYPE;

	signal unit_sel_bus	: INSTRUCTION_UNIT_TYPE;
begin
	---------------------------------------------------------------
	--- State Machine.
	---------------------------------------------------------------
	sm: CPUStateMachine	port map ( reset => reset, clock => clock, fetch_complete => fc, load_complete => lc, write_complete => wc, execute_complete => ec, state => state);

	---------------------------------------------------------------
	--- Register Implementations
	---------------------------------------------------------------
	pc: ProgramCounter		port map (reset => reset, state => state, clock => clock, load => pc_load, address => int_data_bus, current => current_pc, pc => pc_bus);
	ir: InstructionRegister port map (reset => reset, state => state, pc => pc_bus, data => int_data_bus, mem_da => mem_da, mem_en => mem_en, mem_rw => mem_rw, address => int_addr_bus, fetch_complete => fc, unit_sel => unit_sel_bus, instruction => instruction);

--	st: StackRegister		port map (reset => reset, load => sk_load, address => int_address_bus, stack => stack_bus);
--	fr: FlagsRegister		port map (reset => reset, load => flags_load, data => int_data_bus, flags => flags_bus);
--	rb: GeneralRegisters	port map (reset => reset, rw => rw, port_1_bus => reg_1_bus, port_2_bus => reg_2_bus, port_1_data => reg_1_data, port_2_data => reg_2_data);

	---------------------------------------------------------------
	--- Execute Components.
	---------------------------------------------------------------
	iu:	IdleUnit			port map (en => unit_sel_bus.idle, state => state, complete => ec);

	---------------------------------------------------------------
	--- Interface Components.
	---------------------------------------------------------------
	mi: MemoryInterface		port map ( en => mem_en, clock => clock, rw => mem_rw, address => int_addr_bus, data => int_data_bus, complete => mem_da,
										mem_dev_da => da, mem_dev_en => bus_en, mem_dev_rw => bus_rw, mem_dev_addr => bus_address, mem_dev_data => data);

end architecture synth;
--- vi:nocin:sw=4 ts=4:fdm=marker
