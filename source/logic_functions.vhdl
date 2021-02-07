-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : Logic Functions
-- Desc  : This file defines the functions for the logic unit.:w
--
-- Author: Peter Antoine
-- Date  : 03/02/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.definitions.all;

package LogicFunctions is

    ----------------------------------------------------
    --- functions
    ----------------------------------------------------
	function LogicalShiftLeft	( 	a_in: std_logic_vector(DATA_WIDTH-1 downto 0);
									b_in: std_logic_vector(4 downto 0)) return std_logic_vector;
	
	function LogicalShiftRight	( 	a_in: std_logic_vector(DATA_WIDTH-1 downto 0);
									b_in: std_logic_vector(4 downto 0)) return std_logic_vector;

end package LogicFunctions;

package body LogicFunctions is
	----------------------------------------------------
	--- LogicalShiftLeft
	---
	--- This function will shift the content of 
	----------------------------------------------------
	function LogicalShiftLeft(	a_in: std_logic_vector(DATA_WIDTH-1 downto 0);
								b_in: std_logic_vector(4 downto 0)) return std_logic_vector is

	variable shft16 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable shft08 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable shft04 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable shft02 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable dout	: std_logic_vector (DATA_WIDTH-1 downto 0);

	begin
        if b_in(4) = '1' then
            shft16	:= a_in(15 downto 0) & "0000000000000000";
        end if;
        
        if b_in(3) = '1'
        then
			shft08	:= shft16(23 downto 0) & "00000000";
		end if;
		
		if b_in(2) = '1'
		then
			shft04	:= shft08(27 downto 0) & "0000";
		else
			shft04  := shft08;
		end if;
		
		if b_in(1) = '1'
		then
			shft02	:= shft04(29 downto 0) & "00";
		else
            shft02  := shft04;
		end if;
		
		if b_in(0) = '1'
		then
			dout	:= shft02(30 downto 0) & "0";
		else
			dout := shft02;
        end if;

	return dout;

	end function;

	function LogicalShiftRight( a_in: std_logic_vector(DATA_WIDTH-1 downto 0);
								b_in: std_logic_vector(4 downto 0)) return std_logic_vector is

	variable shft16 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable shft08 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable shft04 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable shft02 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable dout	: std_logic_vector (DATA_WIDTH-1 downto 0);

	begin
        if b_in(4) = '1' then
            shft16	:= "0000000000000000" & a_in(15 downto 0);
        end if;
        
        if b_in(3) = '1'
        then
			shft08	:= "00000000" & shft16(23 downto 0);
		end if;
		
		if b_in(2) = '1'
		then
			shft04	:= "0000" & shft08(27 downto 0);
		else
			shft04  := shft08;
		end if;
		
		if b_in(1) = '1'
		then
			shft02	:= "00" & shft04(29 downto 0);
		else
            shft02  := shft04;
		end if;
		
		if b_in(0) = '1'
		then
			dout	:= "0" & shft02(30 downto 0);
		else
			dout	:= shft02;
        end if;

		return dout;

	end function;

end LogicFunctions;

--- vi:nocin:sw=4 ts=4:fdm=marker
