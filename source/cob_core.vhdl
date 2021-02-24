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

use work.SystemRegisters;
use work.GeneralRegisters;
use work.BusController;
use work.AddressModeDecoder;
use work.CPUStateMachine;
use work.LogicDecoder;

entity COB_Core is
		port(
				reset			: in std_logic;		-- reset all the registers.
				clock			: in std_logic;		-- the external system clock.
				
				as				: out std_logic;	-- address strobe
				ds				: out std_logic;	-- data strobe
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
	component GeneralRegisters is
		port(
				reset			: in std_logic;									-- reset all the registers.
				en_1			: in std_logic;									-- is the register block selected.
				en_2			: in std_logic;									-- is the register block selected.
				clock			: in std_logic;									-- the clock.
				addr_data		: in std_logic;									-- output to the address bus or data bus.
				rw				: in std_logic;									-- are we reading or writing the register (reg 1 only).
				reg_address		: in std_logic_vector(REG_ID_WIDTH-1 downto 0);	-- the address of the register we are writing to.
				reg_2_address	: in std_logic_vector(REG_ID_WIDTH-1 downto 0);	-- the address of the register we are writing to.

				data			: inout std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
				data_2			: out std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
		);
	end component;

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

	component LogicDecoder is
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
	end component LogicDecoder;

	---------------------------------------------------------------
	--- now the internal signals.
	---------------------------------------------------------------

begin
	
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

	csm: CPUStateMachine port map ( reset			=> '0',
									enable			=> sel,
									clock			=> clock,
									fetch			=> fetch,
									mem_read		=> mem_read,
									mem_write		=> mem_write,
									mem_complete	=> mem_bus.complete,
									read			=> read,
									wait_read		=> wait_read,
									execute			=> execute,
									write			=> write,
									wait_write		=> wait_write);

	bc: BusController port map (
			sel				=> sel,
			read			=> read,
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

end architecture synth;
--- vi:nocin:sw=4 ts=4:fdm=marker

