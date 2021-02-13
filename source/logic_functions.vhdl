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
	
	function RotateRight	( 	a_in: std_logic_vector(DATA_WIDTH-1 downto 0);
								b_in: std_logic_vector(4 downto 0)) return std_logic_vector;
	
	function RotateLeft		( 	a_in: std_logic_vector(DATA_WIDTH-1 downto 0);
								b_in: std_logic_vector(4 downto 0)) return std_logic_vector;

end package LogicFunctions;

package body LogicFunctions is
	----------------------------------------------------
	--- LogicalShiftLeft
	---
	--- This function will shift the content of a by
	--- b and fill the area with 0's.
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
		else
			shft16  := a_in;
        end if;
        
        if b_in(3) = '1'
        then
			shft08	:= shft16(23 downto 0) & "00000000";
		else
			shft08  := shft16;
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

	----------------------------------------------------
	--- LogicalShiftRight
	---
	--- This function will shift the content of a by
	--- b and fill the area with 0's.
	----------------------------------------------------
	function LogicalShiftRight( a_in: std_logic_vector(DATA_WIDTH-1 downto 0);
								b_in: std_logic_vector(4 downto 0)) return std_logic_vector is

	variable shft16 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable shft08 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable shft04 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable shft02 : std_logic_vector (DATA_WIDTH-1 downto 0);
	variable dout	: std_logic_vector (DATA_WIDTH-1 downto 0);

	begin
        if b_in(4) = '1' then
            shft16	:= "0000000000000000" & a_in(31 downto 16);
		else
			shft16  := a_in;
        end if;
        
        if b_in(3) = '1'
        then
			shft08	:= "00000000" & shft16(31 downto 8);
		else
			shft08  := shft16;
		end if;
		
		if b_in(2) = '1'
		then
			shft04	:= "0000" & shft08(31 downto 4);
		else
			shft04  := shft08;
		end if;
		
		if b_in(1) = '1'
		then
			shft02	:= "00" & shft04(31 downto 2);
		else
            shft02  := shft04;
		end if;
		
		if b_in(0) = '1'
		then
			dout	:= "0" & shft02(31 downto 1);
		else
			dout	:= shft02;
        end if;

		return dout;

	end function;

	----------------------------------------------------
	--- RotateLeft
	---
	--- This function will shift the content of a by
	--- b and move the bits rotated out the top is
	--- added on the bottom.
	----------------------------------------------------
	function RotateLeft	( 	a_in: std_logic_vector(DATA_WIDTH-1 downto 0);
							b_in: std_logic_vector(4 downto 0)) return std_logic_vector is
	
	variable rot16	: std_logic_vector (DATA_WIDTH-1 downto 0);
	variable rot08	: std_logic_vector (DATA_WIDTH-1 downto 0);
	variable rot04	: std_logic_vector (DATA_WIDTH-1 downto 0);
	variable rot02	: std_logic_vector (DATA_WIDTH-1 downto 0);
	variable dout	: std_logic_vector (DATA_WIDTH-1 downto 0);

	begin
        if b_in(4) = '1' then
            rot16	:= a_in(15 downto 0) & a_in(31 downto 16);
		else
			rot16  := a_in;
        end if;
        
        if b_in(3) = '1'
        then
			rot08	:= rot16(23 downto 0) & rot16(31 downto 24);
		else
			rot08  := rot16;
		end if;
		
		if b_in(2) = '1'
		then
			rot04	:= rot08(27 downto 0) & rot08(31 downto 28);
		else
			rot04  := rot08;
		end if;
		
		if b_in(1) = '1'
		then
			rot02	:= rot04(29 downto 0) & rot04(31 downto 30);
		else
            rot02  := rot04;
		end if;
		
		if b_in(0) = '1'
		then
			dout	:= rot02(30 downto 0) & rot02(31);
		else
			dout	:= rot02;
        end if;

		return dout;

	end function;
	
	----------------------------------------------------
	--- RotateRight
	---
	--- This function will shift the content of a by
	--- b and move the bits rotated out the bottom is
	--- added on the top.
	---
	--- This runs the barrel shifter from smallest
	--- to largest (all the rest above to it the other
	--- way around) this means that if the bit at the
	--- bottom rotates off the bottom they will miss the
	--- large rotates.
	----------------------------------------------------
	function RotateRight	( 	a_in: std_logic_vector(DATA_WIDTH-1 downto 0);
								b_in: std_logic_vector(4 downto 0)) return std_logic_vector is
	
	variable rot16	: std_logic_vector (DATA_WIDTH-1 downto 0);
	variable rot08	: std_logic_vector (DATA_WIDTH-1 downto 0);
	variable rot04	: std_logic_vector (DATA_WIDTH-1 downto 0);
	variable rot02	: std_logic_vector (DATA_WIDTH-1 downto 0);
	variable rot01	: std_logic_vector (DATA_WIDTH-1 downto 0);
	variable dout	: std_logic_vector (DATA_WIDTH-1 downto 0);

	begin
		if b_in(0) = '1'
		then
			rot01	:= a_in(0) & a_in(31 downto 1);
		else
			rot01	:= a_in;
        end if;
        
		if b_in(1) = '1'
		then
			rot02	:= rot01(1 downto 0) & rot01(31 downto 2);
		else
            rot02  := rot01;
		end if;
		
		if b_in(2) = '1'
		then
			rot04	:= rot02(3 downto 0) & rot02(31 downto 4);
		else
			rot04  := rot02;
		end if;
		
        if b_in(3) = '1'
        then
			rot08	:= rot04(7 downto 0) & rot04(31 downto 8);
		else
			rot08  := rot04;
		end if;
		
        if b_in(4) = '1' then
            dout	:= rot08(15 downto 0) & rot08(31 downto 16);
		else
			dout	:= rot08;
        end if;

		return dout;

	end function;

end LogicFunctions;

--- vi:nocin:sw=4 ts=4:fdm=marker
