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
use work.ControlUnit;

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
		component SystemRegisters is
			port (
					reset			: in std_logic;		-- reset all the registers.
					sel				: in std_logic;		-- is the register block selected.
					clock			: in std_logic;		-- the clock.
					addr_data		: in std_logic;		-- output to the address bus or data bus.
					rw				: in std_logic;		-- are we reading or writing the register.
					reg_address		: in SYSTEM_REG;	-- the address of the register we are writing to.

					addr			: out std_logic_vector(REG_WIDTH-1 downto 0);	-- The data width of the register.
					data			: inout std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
				);
		end component;

		component GeneralRegisters is
			port(
					reset			: in std_logic;									-- reset all the registers.
					sel				: in std_logic;									-- is the register block selected.
					clock			: in std_logic;									-- the clock.
					addr_data		: in std_logic;		-- output to the address bus or data bus.
					rw				: in std_logic;									-- are we reading or writing the register.
					reg_address		: in std_logic_vector(REG_ID_WIDTH-1 downto 0);	-- the address of the register we are writing to.

					addr			: out std_logic_vector(REG_WIDTH-1 downto 0);	-- The data width of the register.
					data			: inout std_logic_vector(REG_WIDTH-1 downto 0)	-- The data width of the register.
			);
		end component;

		component BusController is
			port(
					clock			: in std_logic;		-- the clock.
					sel				: in std_logic;		-- select the bus controller
					
					-- internal bus signals
					rw				: in std_logic;		-- the read request
					mem_address		: in std_logic_vector(ADDR_WIDTH-1 downto 0);		-- the address requested
					int_data		: inout std_logic_vector(DATA_WIDTH-1 downto 0);	-- the data to be written internally

					-- external bus signals
					as				: out std_logic;	-- address strobe
					ds				: out std_logic;	-- data strobe
					bus_rw			: out std_logic;	-- set the read/write flag
					bus_address		: out std_logic_vector(ADDR_WIDTH-1 downto 0);	-- the address selected.
					da				: in std_logic;									-- data acknowledge - when external data is ready.
					data			: inout std_logic_vector(DATA_WIDTH-1 downto 0)	-- The data width of the register.
			);
		end component;

		component ControlUnit is
			port(
				reset			: in std_logic;		-- reset all the registers.
				clock			: in std_logic;		-- the clock.

				sys_bus			: out SYSTEM_BUS	-- the system bus control signals.
			);
		end component ControlUnit;
		
		---------------------------------------------------------------
		--- now the internal signals.
		---------------------------------------------------------------
		signal rw :				std_logic;
	
		signal system_bus	:	SYSTEM_BUS;
		signal int_address	:	std_logic_vector(ADDR_WIDTH-1 downto 0);
		signal int_data		:	std_logic_vector(DATA_WIDTH-1 downto 0);
					
begin

	ctrl_unit:	ControlUnit			port map (reset => reset, clock => clock, sys_bus => system_bus);
	sys_regs:	SystemRegisters		port map (	reset => reset, sel => system_bus.sys_reg_enable, clock => clock,
												addr_data => system_bus.addr_data, rw => rw, reg_address => int_address(2 downto 0), addr => int_address, data => int_data);

	gen_regs:	GeneralRegisters	port map (	reset => reset, sel => system_bus.gen_reg_enable, clock => clock,
												addr_data => system_bus.addr_data, rw => rw, reg_address => int_address(REG_ID_WIDTH-1 downto 0), data => int_data);
	bus_ctrl:	BusController		port map (	sel => system_bus.bus_enable,
												clock => clock,
												rw => rw,
												mem_address => int_address,
												as => as,
												ds => ds,
												bus_rw => bus_rw,
												bus_address => bus_address,
												da => da,
												data => data);
end architecture synth;
--- vi:nocin:sw=4 ts=4:fdm=marker

