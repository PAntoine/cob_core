# COB Core #
## Architecture ##

This processor is a 32 bit processor. It may extend to 64bit at some point.
It is highly influenced by the Motorola processors (68k posse represent!)
and the assembler will be definitely recognisable to 68k lot.

The register set will be 64 registers long.

It will BigEndian - as nature intended.

## Instruction Format ##

 The processor is 32 bits wide.

 As all good CPU's should be it's big-endian as this makes assembly
 programming and debugging easier.

                The format of an instruction is:
               
                 3       2       1       0      0
                 1.......3.......5.......8......0
                 UUUIIOOOOOOOOxxxxxxxxxxxxxxxxxxx
               
                 O = Instruction opcde (IO) 8 bits
                 U = Instruction Unit (IU) 3 bits
                 I = Instruction size (IS) 2 bits
                 x = instruction details - 19 bits

## Addressing Modes ##

ImmOp		Immediate in Opcode - The immediate value is loaded from the op code.

Imm			Immediate - the immediate value is loaded from the code, but follows
			the op code.

(ImmOp)		Immediate in Opcode indirect - the value is from/to the address pointed
			at by the immdiate in opcode value.

Reg			Register - the value is from/to the register.

(Reg)		Register indirect - the value is from/to the address pointed to by the
			register value.

Note: There will be others - I do intend to use a form or hardware segmentation 
      to aid in memory safety - so that will be added. It might not be part of the
	  instruction set, i.e. the segment registers may just work for all instructions
	  without being specifically referenced by the instructions. Kind of like TLD
	  but being a little better (TLDs will also be used - makes sense).

## Flag Register ##

CF	- Carry Flag			The result of an arithmetic operation.
ZF	- Zero Flag				The last operation resulted in a zero op.
SF	- Sign Flag				The last operation had the high bit set.
MF	- Minus Flag			If the result is negative then this is set (CF status depends on it's initial status).
EX	- Exception Flag		There has been an exception.
IF	- Interrupt Flag		There has been an interrupt.
HI	- Hardware Interrupt	The interrupt was an external interrupt.
IW	- Interrupt waiting		There is an interrupt waiting and the interrupts are masked.
IM	- Interrupts Masked		The interrupts are masked (except the NMI).
NI	- Non-masked Interrupt	The interrupt is the non-maskable interrupt.

## Status Register ##

HWI	- HW interrupt vector	This is the interrupt that was triggered.
EV	- exception vector		This is the ID of the exception that occurred.
PL	- Privilege level		The current privilege level.

## Exceptions ##

DZ	- Divide by Zero		This is thrown when a division by zero occurs.
GP	- General protection	This is a security issue.
DF	- Double fault			This occurs when an exception causes an exception.
II	- Invalid Instruction	The instruction that was to be decoded was invalid

## Instruction Set ##

This is the first version of the instruction set, this will be extended in
later versions but this is the minimum required to get a working OS off the
ground.

### ADC		(add with Carry) ###

#### Description: ####

This function will add the data to the specified register. The result will
be left in the target register and the flags set. The carry bit will be added
in as well.

#### Flags: ####

	SF	- The negative bit set if the register underflows.
	ZF	- The zero bit is set if the target register is set to zero.
	CF	- The carry bit is set if the register underflows.

#### Addressing Modes: ####

Source:
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

Target:
	Reg		- The content of the specified register is updated.

#### Exceptions: ####
None

### ADD		(add without Carry) ###

#### Description: ####

This function will add the data to the specified register. The result will
be left in the target register and the flags set.

#### Flags: ####

	SF	- The negative bit set if the register underflows.
	ZF	- The zero bit is set if the target register is set to zero.
	CF	- The carry bit is set if the register underflows.

#### Addressing Modes: ####

Source:
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

Target:
	Reg		- The content of the specified register is updated.

#### Exceptions: ####
None.

### AND		(logical bitwise and ) ###

#### Description: ####

This operation will do a logical and of the source with the destination.

            Truth Table:

			| source | destination |  result |
			|--------|-------------|---------|
			|   0    |      0      |    0    |
			|   0    |      1      |    0    |
			|   1    |      0      |    0    |
			|   1    |      1      |    1    |
			

#### Flags: ####

	SF	- The flag is set if the top bit is 1.
	ZF	- The flag is set if all the bits are zero.

#### Addressing Modes: ####

Source:
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

Target:
	Reg		- The content of the specified register is updated.

#### Exceptions: ####
None

### branch    (branch always) ###

#### Description: ####

This operation will set the program counter to the new address and continue
running code from that location.

#### Flags: ####

None.

#### Addressing Modes: ####

Source:
	Imm		- The immidate value is loaded into the PC.
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None

### branch\_eq    (branch if equal) ###

#### Description: ####

This operation will set the program counter to the new address and continue
running code from that location, if the ZF is set.

#### Flags: ####

None.

#### Addressing Modes: ####

Source:
	Imm		- The immidate value is loaded into the PC.
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None

### branch\_ge    (branch greater then or equal) ###

#### Description: ####

This operation will set the program counter to the new address and continue
running code from that location, if either the ZF or SF is set.

#### Flags: ####

None.

#### Addressing Modes: ####

Source:
	Imm		- The immidate value is loaded into the PC.
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None

### branch\_gt    (branch greater then or equal) ###

#### Description: ####

This operation will set the program counter to the new address and continue
running code from that location, if the CF, MF, ZF and SF are not set.

#### Flags: ####

None.

#### Addressing Modes: ####

Source:
	Imm		- The immidate value is loaded into the PC.
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None

### branch\_le    (branch less than or equal) ###

#### Description: ####

This operation will set the program counter to the new address and continue
running code from that location, if the MF, ZF or SF are set.

#### Flags: ####

None.

#### Addressing Modes: ####

Source:
	Imm		- The immidate value is loaded into the PC.
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None

### branch\_le    (branch less than or equal) ###

#### Description: ####

This operation will set the program counter to the new address and continue
running code from that location, if the MF, ZF or SF are set.

#### Flags: ####

None.

#### Addressing Modes: ####

Source:
	Imm		- The immidate value is loaded into the PC.
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None

### branch\_lt    (branch less than) ###

#### Description: ####

This operation will set the program counter to the new address and continue
running code from that location, if SF is set.

#### Flags: ####

None.

#### Addressing Modes: ####

Source:
	Imm		- The immidate value is loaded into the PC.
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None

### branch\_ne    (branch not equal) ###

#### Description: ####

This operation will set the program counter to the new address and continue
running code from that location, if ZF is clear.

#### Flags: ####

None.

#### Addressing Modes: ####

Source:
	Imm		- The immidate value is loaded into the PC.
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None

### CALL		(call subroutine) ###

#### Description: ####

This operation will push the current flags, stack and the next value of
the program counter onto the stack.

#### Flags: ####

None.

#### Addressing Modes: ####

Source:
	Imm		- The immidate value is loaded into the PC.
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None

### DEC		(decrement) ###

#### Description: ####

The operation decrements the source.

#### Flags: ####

	SF	- The negative bit set if the register underflows.
	ZF	- The zero bit is set if the target register is set to zero.
	CF	- The carry bit is set if the register underflows.

#### Addressing Modes: ####

Source:
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.


#### Exceptions: ####
None

### DIV		(divide) ###

#### Description: ####

The operation will divide the target by the source.

#### Flags: ####

	SF	- The negative bit set if the register underflows.
	ZF	- The zero bit is set if the target register is set to zero.
	CF	- The carry bit is set if the register underflows.

#### Addressing Modes: ####

Source:
	ImmOp	- The source value.
	Reg		- The source value.
	(Reg)	- The pointer to the source value.

Target:
	Reg		- The content of the specified register is updated.
	(Reg)	- The content of the address pointed to by the register will be updated.

#### Exceptions: ####
DZ	- divide by zero, if the source is zero.

### INC		(increment) ###

#### Description: ####

The operation increments the source.

#### Flags: ####

	SF	- The negative bit set if the top bit is set.
	ZF	- The zero bit is set if the target register is set to zero.
	CF	- The carry bit is set if the register underflows.

#### Addressing Modes: ####

Source:
	Reg		- The value of the specified register to be updated.
	(Reg)	- The value pointed to be the register to be updated.


#### Exceptions: ####
None

### LOAD	(mov to registers) ###

#### Description: ####

The operation will move the source to the target register.

#### Flags: ####

	SF	- The negative bit set if the register underflows.
	ZF	- The zero bit is set if the target register is set to zero.

#### Addressing Modes: ####

Source:
	ImmOp	- The source value.
	Imm		- The source value to load in the register.
	(Imm)	- The indirect value to load in the register.
	Reg		- The source value.
	(Reg)	- The pointer to the source value.

Target:
	Reg		- The content of the specified register is updated.


### MODULO		(divide and store the remainder) ###

#### Description: ####

The operation will divide the target by the source and store the remainder
in the target.

#### Flags: ####

	SF	- The negative bit set if the register underflows.
	ZF	- The zero bit is set if the target register is set to zero.
	CF	- The carry bit is set if the register underflows.

#### Addressing Modes: ####

Source:
	ImmOp	- The source value.
	Reg		- The source value.
	(Reg)	- The pointer to the source value.

Target:
	Reg		- The content of the specified register is updated.
	(Reg)	- The content of the address pointed to by the register will be updated.


#### Exceptions: ####
DZ	- divide by zero, if the source is zero.

### MOVE	(move memory) ###

#### Description: ####

The operation will move the source to the target memory location.

#### Flags: ####

	SF	- The negative bit set if the register underflows.
	ZF	- The zero bit is set if the target register is set to zero.

#### Addressing Modes: ####

Source:
	ImmOp	- The source value.
	Imm		- The source value to load in the register.
	(Imm)	- The indirect value to load in the register.
	(Reg)	- The pointer to the source value.

Target:
	(Imm)	- The indirect value to load in the register.
	(Reg)	- The pointer to the source value.

### MULTIPLY	(multiply) ###

#### Description: ####

The operation will multiple the target by the source, and store the result in the source.

#### Flags: ####

	SF	- The negative bit set if the register underflows.
	ZF	- The zero bit is set if the target register is set to zero.
	CF	- The carry bit is set if the value overflows.

#### Addressing Modes: ####

Source:
	ImmOp	- The source value.
	Reg		- The source value.
	(Reg)	- The pointer to the source value.

Target:
	(Imm)	- The taerget memory location to store the value in.
	Reg		- The content of the specified register is updated.
	(Reg)	- The content of the address pointed to by the register will be updated.

#### Exceptions: ####
None

### NEG		(2's complement negation) ###

#### Description: ####

This operation will do a NOT operation and add 1.


#### Flags: ####

	SF	- The flag is set if the top bit is 1.
	ZF	- The flag is set if all the bits are zero.

#### Addressing Modes: ####

Source:
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

Target:
	Reg		- The content of the specified register is updated.
	(Imm)	- The taerget memory location to store the value in.
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None

### NOP		(do nothing) ###

#### Description: ####

The operation will do nothing.

#### Flags: ####

None

#### Addressing Modes: ####

None

#### Exceptions: ####
None
	
### NOT		(logical bitwise not ) ###

#### Description: ####

This operation will do a logical not of the source with the destination.

            Truth Table:

			| source |  result |
			|--------|---------|
			|   0    |    1    |
			|   1    |    0    |
			

#### Flags: ####

	SF	- The flag is set if the top bit is 1.
	ZF	- The flag is set if all the bits are zero.

#### Addressing Modes: ####

Source:
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

Target:
	Reg		- The content of the specified register is updated.
	(Imm)	- The taerget memory location to store the value in.
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None

### OR		(logical bitwise OR ) ###

#### Description: ####

This operation will do a logical OR of the source with the destination.

            Truth Table:

			| source | destination |  result |
			|--------|-------------|---------|
			|   0    |      0      |    0    |
			|   0    |      1      |    1    |
			|   1    |      0      |    1    |
			|   1    |      1      |    1    |
			

#### Flags: ####

	SF	- The flag is set if the top bit is 1.
	ZF	- The flag is set if all the bits are zero.

#### Addressing Modes: ####

Source:
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

Target:
	Reg		- The content of the specified register is updated.
	(Imm)	- The taerget memory location to store the value in.
	Reg		- The content of the specified register is updated.

#### Exceptions: ####
None

### POP		(POP the top value off the stack) ###

#### Description: ####

This function will pop the top value off the stack and put it in the target.
It will adjust the stack pointer to the new value.

#### Flags: ####

	SF	- The flag is set if the top bit is 1.
	ZF	- The flag is set if all the bits are zero.

#### Addressing Modes: ####

Target:
	Reg		- The content of the specified register is updated.
	(Imm)	- The taerget memory location to store the value in.
	Reg		- The content of the specified register is updated.

#### Exceptions: ####
None

### PUSH	(PUSH the source value onto the stack) ###

#### Description: ####

This operation will push a value onto the stack. If the value width is
less then the bus size then the value will be zero extended before it
is pushed on the stack. The stack pointer will be adjusted before the
value has been pushed.

#### Flags: ####

	SF	- The flag is set if the top bit is 1.
	ZF	- The flag is set if all the bits are zero.

#### Addressing Modes: ####

Source:
	ImmOp	- The value to be pushed.
	Imm		- The value to be pushed.
	(Imm)	- The reference to the value to be pushed.
	Reg		- The content of the specified register is updated.
	(Imm)	- The taerget memory location to store the value in.
	Reg		- The content of the specified register is updated.

#### Exceptions: ####
None

### RETURN	(return from subroutine) ###

#### Description: ####

The operation will return the PC to the contents of the stack.

TBD: define the stack frame for the call stack.

#### Flags: ####

None.

#### Addressing Modes: ####

None.

#### Exceptions: ####
None.

### SUB		(add without Carry) ###

#### Description: ####

This function will substract the data to the specified register. The result will
be left in the target register and the flags set.

#### Flags: ####

	SF	- The negative bit set if the register underflows.
	ZF	- The zero bit is set if the target register is set to zero.
	CF	- The carry bit is set if the register underflows.

#### Addressing Modes: ####

Source:
	ImmOp	- The Immediate value is added to the target.
	Imm		- The immidate value.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

Target:
	Reg		- The content of the specified register is updated.

#### Exceptions: ####
None.

### TEST	(compare the values) ###

#### Description: ####

This function will substract the data to the specified register. The result will
be trown away, but the flags will be updated.

#### Flags: ####

	SF	- The negative bit set if the register underflows.
	ZF	- The zero bit is set if the target register is set to zero.
	CF	- The carry bit is set if the register underflows.

#### Addressing Modes: ####

Source:
	ImmOp	- The Immediate value is added to the target.
	Imm		- The immidate value.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

Target:
	ImmOp	- The Immediate value is added to the target.
	Imm		- The immidate value.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

#### Exceptions: ####
None.

### XOR		(logical bitwise Exclusive OR ) ###

#### Description: ####

This operation will do a logical OR of the source with the destination.

            Truth Table:

			| source | destination |  result |
			|--------|-------------|---------|
			|   0    |      0      |    0    |
			|   0    |      1      |    1    |
			|   1    |      0      |    1    |
			|   1    |      1      |    0    |
			

#### Flags: ####

	SF	- The flag is set if the top bit is 1.
	ZF	- The flag is set if all the bits are zero.

#### Addressing Modes: ####

Source:
	ImmOp	- The Immediate value is added to the target.
	Reg		- The value of the specified register is added to the target
	(Reg)	- The value pointed to be the register is added to the target.

Target:
	Reg		- The content of the specified register is updated.
	(Imm)	- The taerget memory location to store the value in.
	Reg		- The content of the specified register is updated.

#### Exceptions: ####
None


