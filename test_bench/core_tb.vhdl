--					   _____ ____  ____		_____
--					  / ____/ __ \|  _ \   / ____|
--					 | |   | |	| | |_) | | |	  ___  _ __ ___
--					 | |   | |	| |  _ <  | |	 / _ \| '__/ _ \
--					 | |___| |__| | |_) | | |___| (_) | | |  __/
--					  \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : core tb
-- Desc  : The Cob Core Test Bed
--
-- Author: Peter Antoine
-- Date  : 25/02/2021
-----------------------------------------------------------------------------------
--					   Copyright (c) 2021 Peter Antoine
--							  All rights Reserved.
--					  Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use STD.textio.all;
use ieee.std_logic_textio.all; 

use work.definitions.all;
use work.instructions.all;
use work.instruction_generators.all;

use work.logic_tb_defines.all;

use work.COB_Core;

entity COB_Core_Test_Bench is
end COB_Core_Test_Bench;

architecture simulation of COB_Core_Test_Bench is
	---------------------------------------------------------------
	--- Include the components
	---------------------------------------------------------------
	component COB_Core is
		port (
				reset			: in std_logic;		-- reset all the registers.
				enable			: in std_logic;		-- enable the processor.
				clock			: in std_logic;		-- the external system clock.
				
				as				: out std_logic;	-- address strobe
				ds				: out std_logic;	-- data strobe
				bus_en			: out std_logic;	-- bus enable
				bus_rw			: out std_logic;	-- set the read/write flag
				bus_address		: out std_logic_vector(ADDR_WIDTH-1 downto 0);	-- the address selected.
				da				: in  std_logic;								-- data acknowledge - when external data is ready.
				data			: inout std_logic_vector(DATA_WIDTH-1 downto 0)	-- The data width of the register.
			);
	end component COB_Core;

	---------------------------------------------------------------
	--- the test signals
	---------------------------------------------------------------
	signal	reset	: std_logic		:= '1';
	signal	enable	: std_logic		:= '0';
	signal	clock	: std_logic		:= '0';

	-- external bus signals - these are to other devices.
	signal	as			: std_logic;
	signal	ds			: std_logic;
	signal	bus_rw		: std_logic;
	signal	bus_en		: std_logic;
	signal	bus_address	: std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal	da			: std_logic	:= '0';
	signal	data		: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal test_a : std_logic_vector(DATA_WIDTH-1 downto 0) := x"FFFFFFFF";
	signal test_b : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000008";

begin
	-- clock signal
	clock <= not clock after 50 ps;

	-- start the test.
	enable <= '1' after 25 ps;
	reset  <= '0' after 10 ps;

	core: COB_Core port map (reset => reset, enable => enable, clock => clock, as => as, ds => ds, bus_rw => bus_rw, bus_en => bus_en, bus_address => bus_address, da => da, data => data);

	process (bus_en, bus_rw)
	begin
		if bus_en = '0'
		then
			data 	<= (others => 'Z');

		elsif bus_en = '1' and bus_rw = RW_READ
		then
			case bus_address(22 downto 20) is
				when "000"	=> data <= GetNopTestInstruction(bus_address);
				when "111"	=> data	<= GetBranchTestInstruction(bus_address);
				when "110"	=> 
								-- TODO: there is a hack that the bus address is trimmed inside to 20 bits, should
								--       should really do it here or it's going to cause me trouble.
								data	<= GetLogicRegisterInstruction(bus_address);
								test_a	<= GetLogicTestValues(bus_address).a_input;
								test_b	<= GetLogicTestValues(bus_address).b_input;
								-- result	<= GetLogicTestValues(bus_address).output;
--				when "101"	=> data <= GetLogicImmdiateInstruction(bus_address);
--				when "100"	=> data <= GetLogicMemoryInstruction(bus_address);
--				when "011"	=> data <= GetLogicSingleInstruction(bus_address);

				when others => data <= x"F0F0F0F0";
			end case;
		end if;
	end process;

	process (bus_en, clock, bus_rw)
	begin
		if bus_en = '0'
		then
			da <= '0';

		elsif bus_en = '1' and bus_rw = RW_READ
		then
			da <= '1';
		end if;
	end process;

end architecture simulation;

--- vi:nocin:sw=4 ts=4:fdm=marker
