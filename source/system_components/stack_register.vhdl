-----------------------------------------------------------------------------------
--             _____ ____  ____     _____
--            / ____/ __ \|  _ \   / ____|
--           | |   | |  | | |_) | | |     ___  _ __ ___
--           | |   | |  | |  _ <  | |    / _ \| '__/ _ \
--           | |___| |__| | |_) | | |___| (_) | | |  __/
--            \_____\____/|____/   \_____\___/|_|  \___|
--
--
-- Name  : stack_register
-- Desc  : Stack Register.
--
--         The stack register holds the value of the stack, and handles the
--         actions that are performed around the stack.
--
--         For multi-threading the Interrupt can set the SSP register to update
--         the return stack, then do the IRET which will then do the context
--         switch. So the SSP register is loaded when the INT (or EXPT) happens
--         and this value is used when returning. It can be changed when required.
--
--         The Interrupt stack pointer (ISP) is not saved. So the same value that
--         was loaded will be used for every call to the ISP. As these values are
--         transitory anyway. So no need to pop the stack on a IRET.
--
--         Note: the Exception or INT instruction that causes the interrupt will set
--               the flags that include the instruction, after the flags have been
--               adjusted but before handing over control so the interrupt has acess
--               to the values but the user space code does not.
--
--         PUSH:   SP - 4 -> SP
--                 data -> (SP)
--
--         POP:    (SP) -> data
--                 SP + 4 -> SP
--
--         Call:   PUSH(pc)
--
--         Return: POP() -> pc
--
--         IntCall: PUSH(pc)
--                  PUSH(flags)
--                  SaveSP()
--                  LoadISP()
--
--         IntRet: LoadSSP()
--                 POP() -> flags
--                 POP() -> pc
--
--           Call Stack:
--               +-----------------------------------+
--               |         PC (next) Register        |
--               +-----------------------------------+
--
--           Interrupt Stack Frame:
--               +-----------------------------------+
--               |           Flags Register          |   SP
--               +-----------------------------------+
--               |         PC (next) Register        |   SP - 4
--               +-----------------------------------+
--
-- Author: Peter Antoine
-- Date  : 14/04/2021
-----------------------------------------------------------------------------------
--                     Copyright (c) 2021 Peter Antoine
--                            All rights Reserved.
--                    Released Under the Artistic Licence
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.definitions.all;
use work.instructions.all;

entity StackRegister is
	port(
			reset		: in	std_logic;
			clock		: in	std_logic;
			sr_bus		: in	STACK_BUS;
			flags		: in	CPU_FLAGS;
			pc			: in	std_logic_vector(ADDR_WIDTH-1 downto 0);

			mem_bus		: out	MEMORY_BUS;
			mem_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);
			mem_da		: in	std_logic;

			complete	: out	std_logic;
			pc_load		: out	std_logic;
			flags_load	: out	std_logic;
			stack_value	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);
			da			: out	std_logic;
			data		: inout	std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end entity StackRegister;

architecture synth of StackRegister is
	signal st_reg			: std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal isr_reg			: std_logic_vector(ADDR_WIDTH-1 downto 0);	--- Interrupt stack pointer.
	signal ssp_reg			: std_logic_vector(ADDR_WIDTH-1 downto 0);	--- Saved stack pointer.

	-- internal signals
	signal int_da			: std_logic;
	signal int_pc_load		: std_logic;
	signal int_flags_load	: std_logic;

	signal sr_inc		: std_logic;	-- increment the stack register
	signal sr_dec		: std_logic;	-- decrement the stack register
	signal sr_load		: std_logic;	-- load the stack register from data
	signal sr_save_sp	: std_logic;	-- save stack pointer to ssp.
	signal sr_load_ssp	: std_logic;	-- load the stack register from saved stack pointer
	signal sr_load_isr	: std_logic;	-- load the stack register from interrupt stack pointer
	signal load_ssp		: std_logic;	-- load ssr from data
	signal load_isr		: std_logic;	-- load isr from data


	subtype		STACK_STATE_TYPE is std_logic_vector(3 downto 0);
	constant	SR_START		:	STACK_STATE_TYPE := "0000";
	constant	SR_SET_VALUE	:	STACK_STATE_TYPE := "0001";
	constant	SR_DATA_WRITE	:	STACK_STATE_TYPE := "0010";
	constant	SR_FLAGS_WRITE	:	STACK_STATE_TYPE := "0011";
	constant	SR_PC_WRITE		:	STACK_STATE_TYPE := "0100";
	constant	LOAD_SP_FROM_SSP:	STACK_STATE_TYPE := "0101";
	constant	SR_DATA_READ	:	STACK_STATE_TYPE := "0110";
	constant	SR_PC_READ		:	STACK_STATE_TYPE := "0111";
	constant	LOAD_SP_FROM_ISR:	STACK_STATE_TYPE := "1000";
	constant	SR_FLAGS_READ	:	STACK_STATE_TYPE := "1001";
	constant	SR_SSP_VALUE	:	STACK_STATE_TYPE := "1010";
	constant	SR_ISR_VALUE	:	STACK_STATE_TYPE := "1011";
	constant	SR_COMPLETE		:	STACK_STATE_TYPE := "1100";
	constant	SR_FINISHED		:	STACK_STATE_TYPE := "1111";

	signal state : STACK_STATE_TYPE;

	signal st_event : std_logic;

begin

	---------------------------------------------------------------
	--- manage the stack register.
	---------------------------------------------------------------
	st_event <= '1' when (sr_load = '1' or sr_inc = '1' or sr_dec = '1' or sr_load_ssp = '1' or sr_load_isr = '1') and sr_bus.en = '1' else '0';

	process (reset, sr_inc, sr_dec, mem_da, state, sr_bus, st_event, mem_data)
	begin
		if reset = '1'
		then
			st_reg <= ZEROS;

		elsif sr_bus.en = '1' and rising_edge(st_event)
		then
			if sr_load = '1'
			then
				st_reg <= data;

			elsif sr_load_ssp = '1'
			then
				st_reg <= ssp_reg;

			elsif sr_load_isr = '1'
			then
				st_reg <= isr_reg;

			elsif sr_inc = '1'
			then
				st_reg <= std_logic_vector(unsigned(st_reg) + ADDR_BYTES);

			elsif sr_dec = '1'
			then
				st_reg <= std_logic_vector(unsigned(st_reg) - ADDR_BYTES);
			end if;
		end if;
	end process;

	-- interrupt stack pointer
	process (reset, load_isr)
	begin
		if reset = '1'
		then
			isr_reg <= (others => '0');		-- TODO: better initial value!!

		elsif rising_edge(load_isr)
		then
			isr_reg <= data;
		end if;
	end process;

	-- stack save pointer
	process (reset, load_ssp, sr_save_sp, st_reg)
	begin
		if reset = '1'
		then
			ssp_reg <= (others => '0');

		elsif sr_save_sp = '1'
		then
			ssp_reg <= st_reg;

		elsif sr_save_sp = '0' and rising_edge(load_ssp)
		then
			ssp_reg <= data;
		end if;
	end process;

	process (state, sr_bus, clock)
	begin
		if sr_bus.en = '0'
		then
			state		<= SR_START;
			sr_inc		<= '0';
			sr_dec		<= '0';
			sr_load		<= '0';
			load_isr	<= '0';
			load_ssp	<= '0';
			sr_save_sp	<= '0';
			sr_load_ssp	<= '0';
			sr_load_isr	<= '0';
			mem_bus		<= FREE_MEMORY_BUS;

		elsif rising_edge(clock)
		then
			-- latch it at start as it may change during the operation.
			case state is
				when SR_START =>
					case sr_bus.mode is
						when SR_SET			=> state <= SR_SET_VALUE;
						when SR_SSP			=> state <= SR_SSP_VALUE;
						when SR_ISR			=> state <= SR_ISR_VALUE;
						when SR_PUSH		=> state <= SR_DATA_WRITE;
						when SR_CALL		=> state <= SR_PC_WRITE;
						when SR_INT_CALL	=> state <= SR_FLAGS_WRITE;
						when SR_POP			=> state <= SR_DATA_READ;
						when SR_RET			=> state <= SR_PC_READ;
						when SR_INT_RET		=> state <= LOAD_SP_FROM_SSP;
						when others			=> null;
					end case;

				when SR_SET_VALUE =>
					sr_load			<= '1';
					state			<= SR_COMPLETE;

				when SR_SSP_VALUE =>
					load_ssp		<= '1';
					state			<= SR_COMPLETE;

				when SR_ISR_VALUE =>
					load_isr		<= '1';
					state			<= SR_COMPLETE;
				
				when SR_DATA_WRITE =>
					if sr_dec = '0'
					then
						mem_bus.rw		<= '1';
						mem_bus.en		<= '1';
						sr_dec			<= '1';

					elsif mem_da = '1'
					then
						sr_dec		<= '0';
						mem_bus.en	<= '0';
						state		<= SR_COMPLETE;
					end if;

				when SR_FLAGS_WRITE =>
					if sr_dec = '0'
					then
						mem_bus.rw		<= '1';
						mem_bus.en		<= '1';
						sr_dec			<= '1';

					elsif mem_da = '1'
					then
						sr_dec		<= '0';
						mem_bus.en	<= '0';
						state		<= SR_PC_WRITE;
					end if;

				when SR_PC_WRITE =>
					if sr_dec = '0'
					then
						mem_bus.rw		<= '1';
						mem_bus.en		<= '1';
						sr_dec			<= '1';

					elsif mem_da = '1'
					then
						sr_dec		<= '0';
						mem_bus.en	<= '0';

						if sr_bus.mode = SR_CALL
						then
							state <= SR_COMPLETE;
						else
							sr_save_sp	<= '1';
							state		<= LOAD_SP_FROM_ISR;
						end if;
					end if;

				when LOAD_SP_FROM_ISR =>
					sr_save_sp	<= '0';
					sr_load_isr <= '1';

					state <= SR_COMPLETE;

				when LOAD_SP_FROM_SSP =>
					sr_load_ssp	<= '1';

					state <= SR_PC_READ;

				when SR_DATA_READ =>
					mem_bus.rw		<= RW_READ;
					mem_bus.en  	<= '1';

					if mem_da = '1'
					then
						sr_inc  	<= '1';
						mem_bus.en	<= '0';
						state		<= SR_COMPLETE;
					end if;

				when SR_FLAGS_READ =>
					mem_bus.rw		<= RW_READ;
					mem_bus.en  	<= '1';
					sr_inc   		<= '0';

					if mem_da = '1'
					then
						sr_inc		<= '1';
						mem_bus.en	<= '0';
						state		<= SR_COMPLETE;
					end if;

				when SR_PC_READ =>
					mem_bus.rw		<= RW_READ;
					mem_bus.en		<= '1';
					sr_inc   		<= '0';
					sr_load_ssp		<= '0';

					if mem_da = '1'
					then
						sr_inc		<= '1';
						mem_bus.en	<= '0';

						if sr_bus.mode = SR_RET
						then
							state <= SR_COMPLETE;
						else
							state <= SR_FLAGS_READ;
						end if;
					end if;

				when SR_COMPLETE =>
					state		<= SR_FINISHED;

				when SR_FINISHED =>
					sr_inc		<= '0';
					sr_dec		<= '0';
					sr_load		<= '0';
					load_isr	<= '0';
					load_ssp	<= '0';
					sr_save_sp	<= '0';
					sr_load_ssp	<= '0';
					sr_load_isr <= '0';
					mem_bus.en	<= '0';

				when others => null;
			end case;
		end if;

	end process;

	-- memory writes
	mem_bus.address	<= (others => 'Z') when sr_bus.en = '0' else st_reg;

	mem_data <= (others => 'Z')			when sr_bus.en = '0'		else
				pc						when state = SR_PC_WRITE	else
				flagsToVector(flags)	when state = SR_FLAGS_WRITE	else
				data					when state = SR_DATA_WRITE	else
				(others => 'Z');

	-- data available for SR reads (POP's)
	process (sr_bus.en, state, mem_da)
	begin
		if state /= SR_data_READ
		then
			int_da <= '0';

		elsif state = SR_data_READ and rising_edge(mem_da)
		then
			int_da <= '1';
		end if;
	end process;

	-- PC load value
	process (sr_bus.en, state, mem_da)
	begin
		if state /= SR_PC_READ
		then
			int_pc_load <= '0';

		elsif state = SR_PC_READ and rising_edge(mem_da)
		then
			int_pc_load <= '1';
		end if;
	end process;

	-- Flags load value
	process (sr_bus.en, state, mem_da)
	begin
		if state /= SR_FLAGS_READ
		then
			int_flags_load <= '0';

		elsif state = SR_FLAGS_READ and rising_edge(mem_da)
		then
			int_flags_load <= '1';
		end if;
	end process;

	-- output states
	da			<= 'Z' when sr_bus.en = '0' else int_da;
	pc_load		<= 'Z' when sr_bus.en = '0' else int_pc_load;
	flags_load	<= 'Z' when sr_bus.en = '0' else int_flags_load;


	-- complete state
	complete <= '1' when state = SR_FINISHED else '0';

	-- data bus state
	data <= mem_data when state = SR_PC_READ or state = SR_DATA_READ or state = SR_FLAGS_READ else (others => 'Z');

	-- stack value should always be available.
	stack_value <= st_reg;

end architecture synth;

-- vi:nocin:sw=4 ts=4:fdm=marker
