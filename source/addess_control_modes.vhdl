-----------------------------------------------------------------------------------
--           _____ ____  ____     _____
--          / ____/ __ \|  _ \   / ____|
--         | |   | |  | | |_) | | |     ___  _ __ ___
--         | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--         | |___| |__| | |_) | | |___| (_) | | |  __/
--          \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name: address control modes
-- Desc: This this file defines the bus control modes for the address control
--       bus.
--
-- Author: Peter Antoine
-- Date: 22/01/2021
-----------------------------------------------------------------------------------
--                   Copyright (c) 2021 Peter Antoine
--                          All rights Reserved.
--                  Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package address_control_modes is
	------------------------------------------------------------
	--- Address Mode Bus
	------------------------------------------------------------
	type ADDRESS_MODE_BUS is record
		reg_1_read 		: std_logic;
		reg_2_read 		: std_logic;
		mem_read 		: std_logic;
		reg_write		: std_logic;
		mem_write		: std_logic;
		mem_read_a 		: std_logic;
		pc_update		: std_logic; 
	end record ADDRESS_MODE_BUS;

	------------------------------------------------------------
	--- Pre-baked definitions for the above mode.
	------------------------------------------------------------
	constant FREE_ADDRESS_MODE_BUS : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> 'Z',
		reg_2_read 		=> 'Z',
		mem_read 		=> 'Z',
		mem_write		=> 'Z',
		mem_read_a 		=> 'Z',
		pc_update		=> 'Z'
	);

	constant INIT_ADDRESS_MODE_BUS : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '0',
		reg_2_read 		=> '0',
		mem_read 		=> '0',
		mem_write		=> '0',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);
	
	-- this is the same as INIT - but names matter - this is for instructions that done
	-- read or write memory or registers.`
	constant NONE_ADDRESS_MODE_BUS : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '0',
		reg_2_read 		=> '0',
		mem_read 		=> '0',
		mem_write		=> '0',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);
	
	constant REGISTER_1_AND_2_ADDRESS_MODE : address_mode_bus :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '1',
		mem_read 		=> '0',
		mem_write		=> '0',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);

	constant REGISTER_INDIRECT_TO_A_AND_REG_2_ADDRESS_MODE : address_mode_bus :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '1',
		mem_read 		=> '1',
		mem_write		=> '1',
		mem_read_a 		=> '1',
		pc_update		=> '0'
	);

	constant REGISTER_INDIRECT_TO_B_AND_REG_2_ADDRESS_MODE : address_mode_bus :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '1',
		mem_read 		=> '1',
		mem_write		=> '1',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);

	constant REGISTER_1_ADDRESS_MODE : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '0',
		mem_read 		=> '0',
		mem_write		=> '0',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);

	constant REGISTER_1_ADDRESS_MODE : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '0',
		mem_read 		=> '0',
		mem_write		=> '0',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);

	constant REGISTER_1_INDIRECT_ADDRESS_MODE : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '0',
		mem_read 		=> '1',
		mem_write		=> '0',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);

	constant REGISTER_1_TO_PC_ADDRESS_MODE : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '0',
		mem_read 		=> '0',
		mem_write		=> '0',
		mem_read_a 		=> '0',
		pc_update		=> '1'
	);

	constant REGISTER_1_INDIRECT_TO_PC_ADDRESS_MODE : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '0',
		mem_read 		=> '1',
		mem_write		=> '0',
		mem_read_a 		=> '0',
		pc_update		=> '1'
	);

	constant REGISTER_1_TO_MEMORY_MODE : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '0',
		mem_read 		=> '0',
		mem_write		=> '1',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);

	constant REGISTER_2_TO_MEMORY_MODE : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '0',
		mem_read 		=> '0',
		mem_write		=> '1',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);

	constant REGISTER_1_TO_REGISTER_MODE : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '0',
		reg_write		=> '1',
		mem_read 		=> '0',
		mem_write		=> '1',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);

	constant REGISTER_2_TO_REGISTER_MODE : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '0',
		reg_write		=> '1',
		mem_read 		=> '0',
		mem_write		=> '1',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);

	constant REGISTER_1_INDIRECT_TO_MEMORY_MODE : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '0',
		mem_read 		=> '1',
		mem_write		=> '1',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);

	constant REGISTER_2_INDIRECT_TO_MEMORY_MODE : ADDRESS_MODE_BUS :=
	(
		reg_1_read 		=> '1',
		reg_2_read 		=> '0',
		mem_read 		=> '1',
		mem_write		=> '1',
		mem_read_a 		=> '0',
		pc_update		=> '0'
	);

end package address_control_modes;
--- vi:nocin:sw=4 ts=4:fdm=marker
